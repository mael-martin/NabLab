/*******************************************************************************
 * Copyright (c) 2020 CEA
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 * Contributors: see AUTHORS file
 *******************************************************************************/
package fr.cea.nabla.ir.generator.cpp

import fr.cea.nabla.ir.ir.BaseType
import fr.cea.nabla.ir.ir.ConnectivityType
import fr.cea.nabla.ir.ir.ExecuteTimeLoopJob
import fr.cea.nabla.ir.ir.InstructionJob
import fr.cea.nabla.ir.ir.Interval
import fr.cea.nabla.ir.ir.IrModule
import fr.cea.nabla.ir.ir.Iterator
import fr.cea.nabla.ir.ir.Job
import fr.cea.nabla.ir.ir.LinearAlgebraType
import fr.cea.nabla.ir.ir.TimeLoopCopy
import fr.cea.nabla.ir.ir.TimeLoopJob
import fr.cea.nabla.ir.ir.Variable
import fr.cea.nabla.ir.transformers.TARGET_TAG
import java.util.ArrayList
import java.util.HashMap
import java.util.List
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.EcoreUtil2

import static extension fr.cea.nabla.ir.ContainerExtensions.*
import static extension fr.cea.nabla.ir.IrModuleExtensions.*
import static extension fr.cea.nabla.ir.JobCallerExtensions.*
import static extension fr.cea.nabla.ir.JobExtensions.*
import static extension fr.cea.nabla.ir.Utils.*
import static extension fr.cea.nabla.ir.generator.Utils.*
import static extension fr.cea.nabla.ir.generator.cpp.CppGeneratorUtils.*
import static extension fr.cea.nabla.ir.transformers.JobMergeFromCost.*
import fr.cea.nabla.ir.ir.IterableInstruction
import fr.cea.nabla.ir.ir.Loop

@Data
abstract class JobContentProvider
{
	protected val TraceContentProvider traceContentProvider
	protected val extension ExpressionContentProvider
	protected val extension InstructionContentProvider instructionContentProvider
	protected val extension JobCallerContentProvider

	protected def abstract CharSequence
	copyConnectivityType(String leftName, String rightName, int dimension, List<CharSequence> indexNames)

	val OpenMPTargetProvider target = new OpenMPTargetProvider()
	static public var task_mode     = false

	def getDeclarationContent(Job it)
	'''
		void «codeName»() noexcept;'''

	protected def dispatch getNbElems(Iterator it) { container.nbElemsVar }
	protected def dispatch getNbElems(Interval it) { nbElems.content }

	def CharSequence
	getDefinitionContent(Job it)
	{
		IsInsideGPUJob       = GPUJob
		var CharSequence ret = null
		val instruction_job  = it instanceof InstructionJob

		/* GPU Job! */
		if (IsInsideGPUJob && instruction_job && task_mode) {
			println("Define content of GPU job " + name + ": Retrieve dataflow things...")

			/* Get the MININ, OUT, READ, WRITE and take into account the ALREADY_ON_GPU */
			val MinIns = minimalInVars.filter[ !isOption ].map[ name ]
			val Outs   = outVars.map[ name ]
			val WRITE  = outVars.map[ name ].toList
			val READ   = inVars.filter[ !isOption ].map[ name ].toList
			val SIZES  = new HashMap<String, String>()
			READ.forEach[  name | SIZES.put(name, name.globalVariableSize) ]
			WRITE.forEach[ name | SIZES.put(name, name.globalVariableSize) ]

			/* Remove variables that already are on the GPU and must only be on GPU */
			// READ.removeIf([ vname | getVariableLocality(vname) == TARGET_TAG::GPU ])
			// WRITE.removeIf([ vname | getVariableLocality(vname) == TARGET_TAG::GPU ])
			// READ.addAll(inVars.filter[ isOption ].map[ 'options_' + name ]) <- options should already be on the GPU

			/* Add the loop count as a READ variable */
			// eAllContents.filter(Loop).map[ l | l.iterationBlock.getNbElems ].forEach[ v |
			//	val string_v = v + ''
			//	READ.add(string_v)
			//	SIZES.put(string_v, 'cpu_copy')
			// ] <- Not needed because those things are already on the GPU

			println("Define content of GPU job " + name + ": Get method content")
			ret = '''
				«comment»
				void «irModule.className»::«codeName»() noexcept
				{
					«target.task(#[], /* Should not need first-private for jobs,   *
										* shared is implied for all tasks in OpenMP */
						MinIns.toList, Outs.toList,
						READ.toList, WRITE.toList, SIZES,
						'''«innerContent»'''
					)»
				}
			'''
		}

		/* Regular CPU Job */
		else if (task_mode && instruction_job) {
			println("Define content of CPU job " + name)

			val MinIns = minimalInVars.filter[ !isOption ].map[ name ]
			val Outs   = outVars.map[ name ]

			ret = '''
				«comment»
				void «irModule.className»::«codeName»() noexcept
				{
					«target.task(#[], /* Should not need first-private for jobs,   *
									   * shared is implied for all tasks in OpenMP */
						MinIns.toList, Outs.toList,
						#[], #[], null, /* Don't need data movement, always on CPU */
						'''«innerContent»'''
					)»
				}
			'''
		}
		
		else if (
			(instructionContentProvider instanceof OpenMpTaskV2InstructionContentProvider) && // Only in V2
			(eAllContents.filter(IterableInstruction).size() == 0) && // No things that can be sliced
			(it instanceof InstructionJob) // Don't do that for TimeLoopJobs (special control jobs)
		) {
			/* Should only be affectations of reals or other simple types */
			val minIns = minimalInVars
			minIns.removeAll(falseInVariableForJob)
			ret = '''
				«comment»
				void «irModule.className»::«codeName»() noexcept
				{
					// No tasks will be generated
					#pragma omp task«IF !minIns.isEmpty» depend(in: «
						minimalInVars.map[codeName].join(', ')
					»)«ENDIF» depend(out: «
						outVars.map[codeName].join(', ')
					»)
					{
						«innerContent»
					}
				}
			'''
		}
		
		else if (
			(instructionContentProvider instanceof OpenMpTaskV2InstructionContentProvider) && // Only in V2
			(eAllContents.filter(Loop).filter[parallel].size > 0) && // There are multi-threadable loops
			(!eAllContents.filter(Loop)
				.filter[parallel]				// Parallel loops
				.map[iterationBlock.nbElems]	// Their connectivity
				.reject[ nb |					// We will reject the complete connectivities
					#[ 'nbCells', 'nbNodes', 'nbFaces' ].contains(nb)
				].empty
			) // Multi-threadable loops that iterate other something that is not the complete connectivity
		) {
			val ins      = minimalInVars
			val outs     = outVars

			ret = '''
				«comment»
				void «irModule.className»::«codeName»() noexcept
				{
					// Agglomerate sliced of variables if needed for the ins
					«aggSlicedVariables('Cells', ins.filter[globalVariableSize == 'nbCells'])»
					«aggSlicedVariables('Nodes', ins.filter[globalVariableSize == 'nbNodes'])»
					«aggSlicedVariables('Faces', ins.filter[globalVariableSize == 'nbFaces'])»

					// Super task!
					#pragma omp task«
					IF !ins.empty» depend(in: «ins.map[codeName].join(', ')»)«ENDIF
					» depend(out: «outs.map[codeName].join(', ')»)
					{
						«innerContent»
					}

					// Generate slices if needed for parts of the agglomerated variables
					«sliceAggVariables('Cells', outs.filter[globalVariableSize == 'nbCells'])»
					«sliceAggVariables('Nodes', outs.filter[globalVariableSize == 'nbNodes'])»
					«sliceAggVariables('Faces', outs.filter[globalVariableSize == 'nbFaces'])»
				}
			'''
		}

		/* A job without tasks */
		else {
			ret = '''
				«comment»
				void «irModule.className»::«codeName»() noexcept
				{
					«innerContent»
				}
			'''
		}

		IsInsideGPUJob = false
		return ret
	}

	private def CharSequence
	aggSlicedVariables(String which, Iterable<Variable> vars)
	'''
		«IF !vars.empty»
		for (size_t line = 0; line < nb«which» / nbX«which»; ++line)
		{
			#pragma omp task depend(in: «
				vars.map[codeName + '[line]'].join(', ')
			») depend(out: «
				vars.map[codeName].join(', ')
			»)
			{ /* ... */ }
		}
		«ENDIF»
	'''
	
	private def CharSequence
	sliceAggVariables(String which, Iterable<Variable> vars)
	'''
		«IF !vars.empty»
		for (size_t line = 0; line < nb«which» / nbX«which»; ++line)
		{
			#pragma omp task depend(in: «
				vars.map[codeName].join(', ')
			») depend(out: «
				vars.map[codeName + '[line]'].join(', ')
			»)
			{ /* ... */ }
		}
		«ENDIF»
	'''

	protected def dispatch CharSequence getInnerContent(InstructionJob it)
	'''
		«instruction.innerContent»
	'''

	private def needStaticAllocation(Variable v)
	{
		!(v.type instanceof BaseType) && typeContentProvider.isBaseTypeStatic(v.type)
	}

	protected def dispatch CharSequence getInnerContent(ExecuteTimeLoopJob it)
	'''
		«callsHeader»
		«val itVar = iterationCounter.codeName»
		«itVar» = 0;
		bool continueLoop = true;
		do
		{
			«IF task_mode»«FOR copy : copies»
			«target.update(copy.destination)»
			«ENDFOR»«ENDIF»

			«IF caller.main»
			globalTimer.start();
			cpuTimer.start();
			«ENDIF»
			«itVar»++;
			«val ppInfo = irRoot.postProcessing»
			«IF caller.main && ppInfo !== null»
				if (!writer.isDisabled() && «ppInfo.periodReference.codeName» >= «ppInfo.lastDumpVariable.codeName» + «ppInfo.periodValue.codeName»)
					dumpVariables(«itVar»);
			«ENDIF»
			«traceContentProvider.getBeginOfLoopTrace(irModule, itVar, caller.main)»

			«callsContent»

			// Evaluate loop condition with variables at time n
			continueLoop = («whileCondition.content»);

			if (continueLoop)
			{
				// Switch variables to prepare next iteration
				«FOR copy : copies»
				std::swap(«copy.source.name», «copy.destination.name»);
				«ENDFOR»
				«IF task_mode»
					«FOR copy : copies»
					std::swap(«copy.source.name»_glb, «copy.destination.name»_glb);
					«target.update(copy.destination)»
					«ENDFOR»
					«FOR v : EcoreUtil2.getContainerOfType(it, IrModule).variables
						.filter[ !option ]
						.filter[ !needStaticAllocation ]
						.filter[ v | !typeContentProvider.isArray(v.type) ]»
					«v.name»_glb = «v.name»;
					«target.update(v)»
					«ENDFOR»
				«ENDIF»
			}
			«IF caller.main»

			cpuTimer.stop();
			globalTimer.stop();
			«ENDIF»

			«traceContentProvider.getEndOfLoopTrace(irModule, itVar, caller.main, (ppInfo !== null))»

			«IF caller.main»
			cpuTimer.reset();
			ioTimer.reset();
			«ENDIF»
		} while (continueLoop);
		«IF caller.main && irRoot.postProcessing !== null»
			// force a last output at the end
			dumpVariables(«itVar», false);
		«ENDIF»
	'''

	protected def dispatch CharSequence getInnerContent(TimeLoopJob it)
	'''
		«FOR c  : copies»
			«c.content»
		«ENDFOR»
	'''

	protected def getContent(TimeLoopCopy it)
	{
		// c.destination.type == c.source.type
		val t = source.type
		switch t
		{
			BaseType: copyBaseType(destination.name, source.name, t.sizes.size, new ArrayList<CharSequence>())
			ConnectivityType: copyConnectivityType(destination.name, source.name, t.connectivities.size + t.base.sizes.size, new ArrayList<CharSequence>())
			LinearAlgebraType: copyLinearAlgebraType(destination.name, source.name, t.sizes.size, new ArrayList<CharSequence>())
		}
	}

	protected def CharSequence copyBaseType(String leftName, String rightName, int dimension, List<CharSequence> indexNames)
	{
		if (dimension == 0)
			'''«leftName»«FOR i : indexNames»[«i»]«ENDFOR» = «rightName»«FOR i : indexNames»[«i»]«ENDFOR»;'''
		else
		{
			val length = '''«leftName»«FOR i : indexNames»[«i»]«ENDFOR».size()'''
			var indexName = '''i«indexNames.size + 1»'''
			indexNames += indexName
			'''
				for (size_t «indexName»(0) ; «indexName»<«length» ; «indexName»++)
					«copyBaseType(leftName, rightName, dimension-1, indexNames)»
			'''
		}
	}

	protected def CharSequence copyLinearAlgebraType(String leftName, String rightName, int dimension, List<CharSequence> indexNames)
	{
		if (dimension == 0)
			'''«leftName».setValue(«FOR i : indexNames SEPARATOR ', '»«i»«ENDFOR», «rightName».getValue(«FOR i : indexNames SEPARATOR ', '»«i»«ENDFOR»));'''
		else
		{
			val length = '''«leftName»«FOR i : indexNames BEFORE '.getValue(' SEPARATOR ', ' AFTER ')'»«i»«ENDFOR».getSize()'''
			var indexName = '''i«indexNames.size + 1»'''
			indexNames += indexName
			'''
				for (size_t «indexName»(0) ; «indexName»<«length» ; «indexName»++)
					«copyLinearAlgebraType(leftName, rightName, dimension-1, indexNames)»
			'''
		}
	}
}

@Data
class OpenMPGPUJobContentProvider extends JobContentProvider
{
	override protected CharSequence
	copyConnectivityType(String leftName, String rightName, int dimension, List<CharSequence> indexNames)
	{
		copyBaseType(leftName, rightName, dimension, indexNames)
	}

	override CharSequence
	getDefinitionContent(Job it)
	'''
		«comment»
		void «irModule.className»::«codeName»() noexcept
		{
			«IF GPUJob && (it instanceof InstructionJob)»
				// GPU Job
				#pragma omp target
				#pragma omp teams num_teams(1)
				{
					«innerContent»
				}
			«ELSE»
				// CPU Job
				«innerContent»
			«ENDIF»
		}
	'''
}

@Data
class StlThreadJobContentProvider extends JobContentProvider
{
	override protected copyConnectivityType(String leftName, String rightName, int dimension, List<CharSequence> indexNames)
	{
		copyBaseType(leftName, rightName, dimension, indexNames)
	}
}

@Data
class KokkosJobContentProvider extends JobContentProvider
{
	override getDeclarationContent(Job it)
	'''
		KOKKOS_INLINE_FUNCTION
		void «codeName»(«FOR a : arguments SEPARATOR ', '»«a»«ENDFOR») noexcept;'''

	override getDefinitionContent(Job it)
	'''
		«comment»
		void «irModule.className»::«codeName»(«FOR a : arguments SEPARATOR ', '»«a»«ENDFOR») noexcept
		{
			«innerContent»
		}
	'''

	protected def List<String> getArguments(Job it) { #[] }

	override protected copyConnectivityType(String leftName, String rightName, int dimension, List<CharSequence> indexNames)
	'''deep_copy(«leftName», «rightName»);'''
}

@Data
class KokkosTeamThreadJobContentProvider extends KokkosJobContentProvider
{
	override getArguments(Job it)
	{
		if (hasIterable) #["const member_type& teamMember"]
		else #[]
	}
}
