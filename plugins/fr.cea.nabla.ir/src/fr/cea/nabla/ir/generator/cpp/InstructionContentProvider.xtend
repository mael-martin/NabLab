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

import fr.cea.nabla.ir.ir.Affectation
import fr.cea.nabla.ir.ir.ConnectivityCall
import fr.cea.nabla.ir.ir.Exit
import fr.cea.nabla.ir.ir.Function
import fr.cea.nabla.ir.ir.If
import fr.cea.nabla.ir.ir.Instruction
import fr.cea.nabla.ir.ir.InstructionBlock
import fr.cea.nabla.ir.ir.Interval
import fr.cea.nabla.ir.ir.IrAnnotable
import fr.cea.nabla.ir.ir.ItemIdDefinition
import fr.cea.nabla.ir.ir.ItemIdValueIterator
import fr.cea.nabla.ir.ir.ItemIndexDefinition
import fr.cea.nabla.ir.ir.IterationBlock
import fr.cea.nabla.ir.ir.Iterator
import fr.cea.nabla.ir.ir.Job
import fr.cea.nabla.ir.ir.Loop
import fr.cea.nabla.ir.ir.ReductionInstruction
import fr.cea.nabla.ir.ir.Return
import fr.cea.nabla.ir.ir.SetDefinition
import fr.cea.nabla.ir.ir.TaskInstruction
import fr.cea.nabla.ir.ir.Variable
import fr.cea.nabla.ir.ir.VariableDeclaration
import fr.cea.nabla.ir.ir.While
import java.util.HashMap
import java.util.HashSet
import java.util.Set
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.EcoreUtil2

import static extension fr.cea.nabla.ir.ArgOrVarExtensions.*
import static extension fr.cea.nabla.ir.ContainerExtensions.*
import static extension fr.cea.nabla.ir.generator.Utils.*
import static extension fr.cea.nabla.ir.generator.cpp.CppGeneratorUtils.*
import static extension fr.cea.nabla.ir.generator.cpp.ItemIndexAndIdValueContentProvider.*
import static extension fr.cea.nabla.ir.transformers.JobMergeFromCost.*

@Data
abstract class InstructionContentProvider
{
	protected val extension TypeContentProvider
	protected val extension ExpressionContentProvider
	protected abstract def CharSequence getReductionContent(ReductionInstruction it)
	protected abstract def CharSequence getParallelLoopContent(Loop it)

	def dispatch CharSequence getContent(VariableDeclaration it)
	'''
		«IF variable.type.baseTypeStatic»
			«IF variable.const»const «ENDIF»«variable.type.cppType» «variable.name»«IF variable.defaultValue !== null»(«variable.defaultValue.content»)«ENDIF»;
		«ELSE»
			«IF variable.const»const «ENDIF»«variable.type.cppType» «variable.name»;
			«initCppTypeContent(variable.name, variable.type)»
		«ENDIF»
	'''
	
	def dispatch CharSequence getContent(TaskInstruction it) { throw new Exception("Unsuported operation") }

	def dispatch CharSequence getContent(InstructionBlock it)
	'''
		{
			«FOR i : instructions»
			«i.content»
			«ENDFOR»
		}'''

	def dispatch CharSequence getContent(Affectation it)
	{
		if (left.target.linearAlgebra && !(left.iterators.empty && left.indices.empty))
			'''«left.codeName».setValue(«formatIteratorsAndIndices(left.target.type, left.iterators, left.indices)», «right.content»);'''
		else
			'''«left.content» = «right.content»;'''
	}

	def dispatch CharSequence getContent(ReductionInstruction it)
	{
		reductionContent
	}

	def dispatch CharSequence getContent(Loop it)
	{
		if (parallel)
			iterationBlock.defineInterval(parallelLoopContent)
		else
			iterationBlock.defineInterval(sequentialLoopContent)
	}

	def dispatch CharSequence getContent(If it)
	'''
		if («condition.content») 
		«val thenContent = thenInstruction.content»
		«IF !(thenContent.charAt(0) == '{'.charAt(0))»	«ENDIF»«thenContent»
		«IF (elseInstruction !== null)»
			«val elseContent = elseInstruction.content»
			else
			«IF !(elseContent.charAt(0) == '{'.charAt(0))»	«ENDIF»«elseContent»
		«ENDIF»
	'''

	def dispatch CharSequence getContent(ItemIndexDefinition it)
	'''
		const size_t «index.name»(«value.content»);
	'''

	def dispatch CharSequence getContent(ItemIdDefinition it)
	'''
		const Id «id.name»(«value.content»);
	'''

	def dispatch CharSequence getContent(SetDefinition it)
	{
		getSetDefinitionContent(name, value)
	}

	def dispatch CharSequence getContent(While it)
	'''
		while («condition.content»)
		«val iContent = instruction.content»
		«IF !(iContent.charAt(0) == '{'.charAt(0))»	«ENDIF»«iContent»
	'''

	def dispatch CharSequence getContent(Return it)
	'''
		return «expression.content»;
	'''

	def dispatch CharSequence getContent(Exit it)
	'''
		throw std::runtime_error("«message»");
	'''

	def dispatch getInnerContent(Instruction it)
	{ 
		content
	}

	def dispatch getInnerContent(InstructionBlock it)
	'''
		«FOR i : instructions»
		«i.content»
		«ENDFOR»
	'''

	protected def boolean isParallel(Loop it) { parallelLoop }

	protected def CharSequence getSequentialLoopContent(Loop it)
	'''
		for (size_t «iterationBlock.indexName»=0; «iterationBlock.indexName»<«iterationBlock.nbElems»; «iterationBlock.indexName»++)
		{
			«body.innerContent»
		}
	'''

	// ### IterationBlock Extensions ###
	protected def dispatch defineInterval(Iterator it, CharSequence innerContent)
	{
		if (container.connectivityCall.connectivity.indexEqualId)
			innerContent
		else
		'''
		{
			«IF container instanceof ConnectivityCall»«getSetDefinitionContent(container.uniqueName, container as ConnectivityCall)»«ENDIF»
			const size_t «nbElems»(«container.uniqueName».size());
			«innerContent»
		}
		'''
	}

	protected def dispatch defineInterval(Interval it, CharSequence innerContent)
	{
		innerContent
	}

	protected def dispatch getIndexName(Iterator it) { index.name }
	protected def dispatch getIndexName(Interval it) { index.name }
	protected def dispatch getNbElems(Iterator it) { container.nbElemsVar }
	protected def dispatch getNbElems(Interval it) { nbElems.content }

	protected def getSetDefinitionContent(String setName, ConnectivityCall call)
	'''
		const auto «setName»(mesh->«call.accessor»);
	'''
}

@Data
class SequentialInstructionContentProvider extends InstructionContentProvider
{
	override isParallel(Loop it) { false }

	override protected getReductionContent(ReductionInstruction it)
	{
		throw new UnsupportedOperationException("ReductionInstruction must have been replaced before using this code generator")
	}

	override protected getParallelLoopContent(Loop it)
	{
		sequentialLoopContent
	}
}

@Data
class StlThreadInstructionContentProvider extends InstructionContentProvider
{
	override getReductionContent(ReductionInstruction it)
	'''
		«result.type.cppType» «result.name»;
		«iterationBlock.defineInterval('''
		«result.name» = nablalib::utils::stl::parallel_reduce(«iterationBlock.nbElems», «result.defaultValue.content», [&](«result.type.cppType»& accu, const size_t& «iterationBlock.indexName»)
			{
				«FOR innerInstruction : innerInstructions»
				«innerInstruction.content»
				«ENDFOR»
				return (accu = «binaryFunction.codeName»(accu, «lambda.content»));
			},
			&«binaryFunction.codeName»);''')»
	'''

	override getParallelLoopContent(Loop it)
	'''
		nablalib::utils::stl::parallel_exec(«iterationBlock.nbElems», [&](const size_t& «iterationBlock.indexName»)
		{
			«body.innerContent»
		});
	'''
}

@Data
class KokkosInstructionContentProvider extends InstructionContentProvider
{
	override getReductionContent(ReductionInstruction it)
	'''
		«result.type.cppType» «result.name»;
		«iterationBlock.defineInterval('''
		Kokkos::parallel_reduce(«firstArgument», KOKKOS_LAMBDA(const size_t& «iterationBlock.indexName», «result.type.cppType»& accu)
		{
			«FOR innerInstruction : innerInstructions»
			«innerInstruction.content»
			«ENDFOR»
			accu = «binaryFunction.codeName»(accu, «lambda.content»);
		}, KokkosJoiner<«result.type.cppType»>(«result.name», «result.defaultValue.content», &«binaryFunction.codeName»));''')»
	'''

	override getParallelLoopContent(Loop it)
	'''
		Kokkos::parallel_for(«iterationBlock.nbElems», KOKKOS_LAMBDA(const size_t& «iterationBlock.indexName»)
		{
			«body.innerContent»
		});
	'''

	protected def getFirstArgument(ReductionInstruction it) 
	{
		iterationBlock.nbElems
	}
}

@Data
class KokkosTeamThreadInstructionContentProvider extends KokkosInstructionContentProvider
{
	override String getFirstArgument(ReductionInstruction it) 
	{
		"Kokkos::TeamThreadRange(teamMember, " + iterationBlock.nbElems + ")"
	}

	override getParallelLoopContent(Loop it)
	'''
		{
			«iterationBlock.autoTeamWork»

			Kokkos::parallel_for(Kokkos::TeamThreadRange(teamMember, teamWork.second), KOKKOS_LAMBDA(const size_t& «iterationBlock.indexName»Team)
			{
				int «iterationBlock.indexName»(«iterationBlock.indexName»Team + teamWork.first);
				«body.innerContent»
			});
		}
	'''

	private def getAutoTeamWork(IterationBlock it)
	'''
		const auto teamWork(computeTeamWorkRange(teamMember, «nbElems»));
		if (!teamWork.second)
			return;
	'''
}

@Data
class OpenMpInstructionContentProvider extends InstructionContentProvider
{
	override getReductionContent(ReductionInstruction it)
	'''
		«result.type.cppType» «result.name»(«result.defaultValue.content»);
		#pragma omp parallel for reduction(min:«result.name»)
		«iterationBlock.defineInterval('''
		for (size_t «iterationBlock.indexName»=0; «iterationBlock.indexName»<«iterationBlock.nbElems»; «iterationBlock.indexName»++)
		{
			«result.name» = «binaryFunction.codeName»(«result.name», «lambda.content»);
		}''')»
	'''

	override getParallelLoopContent(Loop it)
	'''
		«val vars = modifiedVariables»
		#pragma omp parallel«IF !vars.empty» for shared(«vars.map[codeName].join(', ')»«ENDIF»)
		«sequentialLoopContent»
	'''

	private def getModifiedVariables(Loop l)
	{
		val modifiedVars = l.eAllContents.filter(Affectation).map[left.target].toSet
		modifiedVars.filter[global]
	}
}

@Data
class OpenMpTaskInstructionContentProvider extends InstructionContentProvider
{
	HashMap<String, Pair<Integer, Integer>> dataShift = new HashMap(); /* item name => iterator shift    */
	HashMap<String, String> dataConnectivity          = new HashMap(); /* item name => connectivity type */
	HashMap<String, Integer> counters                 = new HashMap();
	HashMap<String, CharSequence> auxString           = new HashMap();
	
	OpenMPTaskProvider taskProvider
	
	private def void levelINC() { counters.put("Level", counters.getOrDefault('Level', 0) + 1) }
	private def void levelDEC() { counters.put("Level", Math::max(counters.get('Level') - 1, 0)) }
	private def void endTASK()  { counters.put("Task", 0) }
	private def void beginTASK(CharSequence taskId) { counters.put("Task", 1); auxString.put("TaskId", taskId) }
	
	private def int getCurrentLevel() { return counters.getOrDefault('Level', 0); }
	private def CharSequence getCurrentTASK() { return (counters.getOrDefault('Task', 0) == 1) ? auxString.get('TaskId') : null }
	private def getChildTasks(InstructionBlock it) { return eAllContents.filter(Loop).filter[multithreadable].size + eAllContents.filter(ReductionInstruction).size }
	private def isInsideAJob(IrAnnotable it) { (null !== EcoreUtil2.getContainerOfType(it, Job)) && (EcoreUtil2.getContainerOfType(it, Function) === null); }

	override dispatch CharSequence getContent(TaskInstruction it)
	{
		throw new Exception("Unimplemented")
	}
	
	private def getInnerContentInternal(InstructionBlock it)
	{
		var Loop lastLoopType = null
	'''
		«FOR i : instructions»
			«i.content»
		«ENDFOR»
		««« This bracket is opened in the getReductionContent function
		«IF (instructions.size == 2) &&
		    (instructions.toList.head instanceof ReductionInstruction) &&
		    (instructions.toList.last instanceof Affectation)»
		«taskProvider.closeUnclosedTask» /* Close the reduction */
		«ENDIF»
		««« Close the last loop if necessary
		«IF lastLoopType !== null»
		#pragma omp taskwait /* Close the last loop */
		«ENDIF»
	'''
	}
	override dispatch getInnerContent(InstructionBlock it)
	{
		levelINC();
		val launch_super_task = (insideAJob && (currentLevel == 1) && (childTasks > 1))
		val parentJob         = EcoreUtil2.getContainerOfType(it, Job)
		val ins               = parentJob.minimalInVars
		val outs              = parentJob.outVars
		if (launch_super_task) {
			beginTASK('supertask');
			instructions.forEach[removeAdditionalFirstPrivVariables]
		}

		val ret = '''
		«IF launch_super_task»
		«taskProvider.generateTask(parentJob,
			#[].toSet, parentJob.taskShared,
			ins,  true, null,
			outs, true, null,
			'''
			// BEGIN OF SUPER TASK
			«innerContentInternal»
			// END OF SUPER TASK
			'''
		)»
		«ELSE»
		«innerContentInternal»
		«ENDIF»
		'''

		if (launch_super_task) { endTASK(); }
		levelDEC();
		return ret
	}

	override dispatch CharSequence getContent(Affectation it)
	{
		val parentJob = EcoreUtil2.getContainerOfType(it, Job);

		if (left.target.linearAlgebra && !(left.iterators.empty && left.indices.empty))
			'''«left.codeName».setValue(«formatIteratorsAndIndices(left.target.type, left.iterators, left.indices)», «right.content»);'''

		else if (parentJob !== null && parentJob.eAllContents.filter(Instruction).size == 1)
		{
			val ins = parentJob.minimalInVars
			val outs = parentJob.outVars
			val super_task = (currentTASK !== null)
			if (!super_task) {
				beginTASK(getAllOMPTasksAsCharSequence)
			}

			val ret = '''
				/* ONLY_AFFECTATION, still need to launch a task for that
				 * TODO: Group all affectations in one job */
				«IF ! super_task»
					«taskProvider.generateTask(parentJob,
						#[].toSet, parentJob.taskShared,
						ins,  true, null,
						outs, true, null,
						'''«left.content» = «right.content»;'''
					)»
				«ELSE»
					«left.content» = «right.content»;
				«ENDIF»
			'''
			if (!super_task) endTASK()
			return ret
		}
		
		/* TODO: Handle the case where the job is only about doing assignations, and there are at least 2 of them... */
		else
			'''«left.content» = «right.content»;'''
	}

	override getReductionContent(ReductionInstruction it)
	{
		// Ignore super task here
		beginTASK(getAllOMPTasksAsCharSequence)
		removeAdditionalFirstPrivVariables(iterationBlock)
		val parentJob 		= EcoreUtil2.getContainerOfType(it, Job)
		val outs      		= parentJob.outVars
		val out       		= outs.head
		val Set<String> ins = new HashSet();
		OMPTaskMaxNumberIterator.forEach[ i | ins.add('(' + result.name + '_tab[' + i + '])') ]

		val ret = '''
			static «result.type.cppType» «result.name»_tab[«OMPTaskMaxNumber»];

			for (size_t i = 0; i < «OMPTaskMaxNumber»; ++i)
			{
				«result.name»_tab[i] = «result.defaultValue.content»;
				«getPartialReduction(it, '''i''')»
			}

			«taskProvider.generateUnclosedTask(parentJob,
				#[].toSet, #['this->' + out.name, result.name + '_tab'].toSet,
				ins, #[ 'this->' + out.name ].toSet,
				'''
					«result.type.cppType» «result.name» = «result.defaultValue.content»;
					for (size_t i = 0; i < «OMPTaskMaxNumber»; ++i)
						«result.name» = «binaryFunction.codeName»(«result.name»_tab[i], «result.name»);
				'''
			)»
		'''

		endTASK()
		return ret
	}
	
	private def getPartialReduction(ReductionInstruction it, CharSequence partitionId)
	{
		val parentJob  		   = EcoreUtil2.getContainerOfType(it, Job)
		val ins        		   = parentJob.minimalInVars /* Need to be computed before, consumed */
		val Set<String> shared = parentJob.taskShared
		shared.addAll(#[result.name + '_tab'])
	'''
		const Id ___omp_base  = «getBaseIndex(iterationBlock, partitionId)»;
		const Id ___omp_limit = «getLimitIndex(iterationBlock, partitionId)»;
		«taskProvider.generateTask(parentJob,
			#['___omp_base', '___omp_limit', 'i'].toSet, shared,
			ins,  true, null,
			#[result.name + '_tab[i]'].toSet,
			'''
				«iterationBlock.defineInterval('''
				«overrideIterationBlock(it,
					'''___omp_base''',
					'''___omp_limit''',
					'''«result.name»_tab[i] = «binaryFunction.codeName»(«result.name»_tab[i], «lambda.content»);'''
				)»
				''')»
			'''
		)»
	'''
	}

	protected override CharSequence getSequentialLoopContent(Loop it)
	{
		/* TODO: if inside a task and need a connectivity, use the «currentTask»
		 * value to get the right thing. Also see if it's necessary */
		val ret = '''
		for (size_t «iterationBlock.indexName»=0; «iterationBlock.indexName»<«iterationBlock.nbElems»; «iterationBlock.indexName»++)
		{
			«body.innerContent»
		}
		'''
		return ret
	}

	/* Slice the loop in chunks and feed it to the tasks. */
	override getParallelLoopContent(Loop it)
	{
		levelINC();
		val parentJob = EcoreUtil2.getContainerOfType(it, Job)
		counters.put("Loop"+parentJob.name, counters.getOrDefault('Loop'+parentJob.name, 0) + 1)
		dataShift.clear()
		dataConnectivity.clear()
		eAllContents.filter(ItemIdDefinition).forEach[item |
			if (item instanceof ItemIdValueIterator)
				addDataShift(item.id.itemName, item.value as ItemIdValueIterator)
		]
		var ret = ''''''

		if (getCurrentTASK() !== null) ret = '''
			«sequentialLoopContent»
			'''

		else ret = '''
			«launchTasks»
			'''

		levelDEC();
		return ret
	}
	
	/* Compute the shift pair, the first element is the negative shift, the second the positive shift. */
	private def Pair<Integer, Integer> computeShiftPair(Pair<Integer, Integer> pair, int shift)
	{
		return shift < 0 ? new Pair<Integer, Integer>(Math::min(pair.key, shift), pair.value)
		                 : new Pair<Integer, Integer>(pair.key, Math::max(pair.value, shift))
	}
	
	private def void addDataShift(String itemName, ItemIdValueIterator value)
	{
		var Pair<Integer, Integer> shifts = dataShift.get(itemName)
		if (shifts === null) { shifts = new Pair<Integer, Integer>(0, 0); } /* New shift! */
		shifts = computeShiftPair(shifts, value.shift);
		dataShift.put(itemName, shifts);
		dataConnectivity.put(itemName, value.iterator.container.connectivityCall.connectivity.name)
	}

	private def overrideIterationBlock(Loop it, CharSequence base, CharSequence limit)
	'''
		for (size_t «iterationBlock.indexName» = «base»; «iterationBlock.indexName» < «limit»; ++«iterationBlock.indexName»)
		{
			«body.innerContent»
		}
	'''
	private def overrideIterationBlock(ReductionInstruction it, CharSequence base, CharSequence limit, CharSequence reductionContent)
	'''
		for (size_t «iterationBlock.indexName» = «base»; «iterationBlock.indexName» < «limit»; ++«iterationBlock.indexName»)
		{
			«reductionContent»
		}
	'''

	private def launchSingleTaskForPartition(Loop it, CharSequence partitionId, Set<Variable> ins, Set<Variable> outs)
	{
		val parentJob  = EcoreUtil2.getContainerOfType(it, Job)
		val super_task = (currentTASK !== null)
		if (!super_task) {
			beginTASK(partitionId)
			removeAdditionalFirstPrivVariables(body)
		}

		val ret = '''
		{
			const Id ___omp_base  = «getBaseIndex(iterationBlock, partitionId)»;
			const Id ___omp_limit = «getLimitIndex(iterationBlock, partitionId)»;
			«IF ! super_task»
				«IF parentJob.usedIndexType.length > 1»
					«taskProvider.generateTask(parentJob,
						parentJob.taskFirstPrivate, parentJob.taskShared,
						ins,  true,  null,
						outs, false, '''___omp_base''',
						'''«overrideIterationBlock(it, '''___omp_base''', '''___omp_limit''')»'''
					)»
				«ELSE»
					«taskProvider.generateTask(parentJob,
						parentJob.taskFirstPrivate, parentJob.taskShared,
						ins,  false, '''___omp_base''',
						outs, false, '''___omp_base''',
						'''«overrideIterationBlock(it, '''___omp_base''', '''___omp_limit''')»'''
					)»
				«ENDIF»
			«ENDIF»
		}
		'''

		if (!super_task) endTASK()
		return ret
	}
	
	/* Get base and limit index for each loop in tasks */
	private def getBaseIndex(IterationBlock it, CharSequence partitionId)
		'''«getBaseIndex(nbElems, partitionId)»'''
	private def getLimitIndex(IterationBlock it, CharSequence partitionId)
		'''(«OMPTaskMaxNumber» - 1 != «partitionId») ? ((«nbElems» / «OMPTaskMaxNumber») * («partitionId» + 1)) : («nbElems»)'''
	
	/* Slice a loop in multiple tasks with dependencies */
	private def launchTasks(Loop it)
	{
		val parentJob = EcoreUtil2.getContainerOfType(it, Job)
		val ins       = parentJob.minimalInVars /* Need to be computed before, consumed. */
		val outs      = parentJob.outVars       /* Produced, unlock jobs that need them. */
		if (eAllContents.filter(ItemIdDefinition).size == 0)
		{
			val String itemname = iterationBlock.indexName.toString

			/* Auto detect cells */
			if (itemname.contains("Cell") || itemname.contains("cell")) {
				dataShift.put(String::valueOf(itemname.charAt(0)), new Pair<Integer, Integer>(0, 0))
				dataConnectivity.put(String::valueOf(itemname.charAt(0)), "cells");
			}
			
			/* Auto detect nodes */
			else if (itemname.contains("Node") || itemname.contains("node")) {
				dataShift.put(String::valueOf(itemname.charAt(0)), new Pair<Integer, Integer>(0, 0))
				dataConnectivity.put(String::valueOf(itemname.charAt(0)), "nodes");
			}
			
			/* Auto detect faces */
			else if (itemname.contains("Face") || itemname.contains("face")) {
				dataShift.put(String::valueOf(itemname.charAt(0)), new Pair<Integer, Integer>(0, 0))
				dataConnectivity.put(String::valueOf(itemname.charAt(0)), "faces");
			}
			
			else { throw new Exception("Unknown iterator " + itemname + ", could not autofill dataShifts and dataConnectivity") }
		}
		val ret = '''
			for (size_t task = 0; task < «OMPTaskMaxNumber»; ++task)
			«launchSingleTaskForPartition(it, '''task''', ins, outs)»
		'''
		return ret;
	}
}