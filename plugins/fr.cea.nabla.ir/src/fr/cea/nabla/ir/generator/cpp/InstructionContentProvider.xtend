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

import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtend.lib.annotations.Data

import java.util.stream.IntStream
import java.util.Set
import java.util.HashMap
import java.util.regex.Pattern

import fr.cea.nabla.ir.ir.Affectation
import fr.cea.nabla.ir.ir.ConnectivityCall
import fr.cea.nabla.ir.ir.Exit
import fr.cea.nabla.ir.ir.If
import fr.cea.nabla.ir.ir.Instruction
import fr.cea.nabla.ir.ir.InstructionBlock
import fr.cea.nabla.ir.ir.Interval
import fr.cea.nabla.ir.ir.ItemIdDefinition
import fr.cea.nabla.ir.ir.ItemIndexDefinition
import fr.cea.nabla.ir.ir.IterationBlock
import fr.cea.nabla.ir.ir.Iterator
import fr.cea.nabla.ir.ir.Loop
import fr.cea.nabla.ir.ir.ReductionInstruction
import fr.cea.nabla.ir.ir.Return
import fr.cea.nabla.ir.ir.SetDefinition
import fr.cea.nabla.ir.ir.VariableDeclaration
import fr.cea.nabla.ir.ir.While
import fr.cea.nabla.ir.ir.Variable
import fr.cea.nabla.ir.ir.ArgOrVarRef
import fr.cea.nabla.ir.ir.IrPackage
import fr.cea.nabla.ir.ir.ItemIndex
import fr.cea.nabla.ir.ir.ItemIdValueIterator
import fr.cea.nabla.ir.ir.ArgOrVar
import fr.cea.nabla.ir.ir.ConnectivityType
import fr.cea.nabla.ir.ir.BaseType
import fr.cea.nabla.ir.ir.LinearAlgebraType
import fr.cea.nabla.ir.ir.IterableInstruction
import fr.cea.nabla.ir.ir.Job

import static extension fr.cea.nabla.ir.ArgOrVarExtensions.*
import static extension fr.cea.nabla.ir.ContainerExtensions.*
import static extension fr.cea.nabla.ir.generator.Utils.*
import static extension fr.cea.nabla.ir.generator.cpp.CppGeneratorUtils.*
import static extension fr.cea.nabla.ir.generator.cpp.ItemIndexAndIdValueContentProvider.*

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

	private def getSetDefinitionContent(String setName, ConnectivityCall call)
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
		«result.name» = parallel_reduce(«iterationBlock.nbElems», «result.defaultValue.content», [&](«result.type.cppType»& accu, const size_t& «iterationBlock.indexName»)
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
		parallel_exec(«iterationBlock.nbElems», [&](const size_t& «iterationBlock.indexName»)
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
	enum VARIABLE_TYPE {
		BASIC,
		BASE,
		CONNECTIVITY
	}
	
	HashMap<String, Pair<Integer, Integer>> dataShift = new HashMap(); /* item name => iterator shift    */
	HashMap<String, String> dataConnectivity = new HashMap();          /* item name => connectivity type */

	override dispatch CharSequence getContent(Affectation it)
	{
		val parentJob = EcoreUtil2.getContainerOfType(it, Job);

		if (left.target.linearAlgebra && !(left.iterators.empty && left.indices.empty))
			'''«left.codeName».setValue(«formatIteratorsAndIndices(left.target.type, left.iterators, left.indices)», «right.content»);'''
		else if (parentJob !== null && parentJob.eAllContents.filter(Instruction).size == 1)
		{
			val ins = parentJob.inVars
			val outs = parentJob.outVars
			'''
				/* ONLY_AFFECTATION */
				#pragma omp task«
					getDependenciesAll('in', ins, 0, OMPTaskMaxNumber)»«
					getDependenciesAll('out', outs, 0, OMPTaskMaxNumber)»
				«left.content» = «right.content»;
			'''
		}
		else
			'''«left.content» = «right.content»;'''
	}

	override getReductionContent(ReductionInstruction it)
	{
		val parentJob = EcoreUtil2.getContainerOfType(it, Job)
		val ins = parentJob.getInVars       /* Need to be computed before, consumed */
		val out = parentJob.getOutVars.head /* Produced, unlock jobs that need them */
		'''
			/* REDUCTION BEGIN for job «parentJob.name»@«parentJob.at»
			 * IN:    «ins.map[name]»
			 * OUT:   «out.name»
			 */
			«result.type.cppType» «result.name»(«result.defaultValue.content»);
			#pragma omp task firstprivate(«result.name», «iterationBlock.nbElems»)\
			 «getDependenciesAll('in', ins, 0, OMPTaskMaxNumber)» \
			 depend(out: «out.name»)
			«iterationBlock.defineInterval('''
			for (size_t «iterationBlock.indexName»=0; «iterationBlock.indexName»<«iterationBlock.nbElems»; «iterationBlock.indexName»++)
			{
				«result.name» = «binaryFunction.codeName»(«result.name», «lambda.content»);
			}''')»
			/* REDUCTION END */
		'''
	}

	/* Slice the loop in chunks and feed it to the tasks. Will launch taskN
	 * tasks. For the moment, taskN is static. TODO: Fix that. */
	override getParallelLoopContent(Loop it)
	{
		dataShift.clear()
		dataConnectivity.clear()
		eAllContents.filter(ItemIdDefinition).forEach[item |
			val itemid = item.id
			val value = item.value as ItemIdValueIterator
			addDataShift(itemid.itemName, value)
		]
		'''
		/* TASKLOOP BEGIN */
		«launchTasks(OMPTaskMaxNumber) /* Each loop is 10 tasks */»
		/* TASKLOOP END */
		'''
	}
	
	/* Compute the shift pair, the first element is the negative shift, the second the positive shift. */
	protected def Pair<Integer, Integer> computeShiftPair(Pair<Integer, Integer> pair, int shift)
	{
		return shift < 0 ? new Pair<Integer, Integer>(Math::min(pair.key, shift), pair.value)
		                 : new Pair<Integer, Integer>(pair.key, Math::max(pair.value, shift))
	}
	
	protected def void addDataShift(String itemName, ItemIdValueIterator value)
	{
		var Pair<Integer, Integer> shifts = dataShift.get(itemName)
		if (shifts === null) { shifts = new Pair<Integer, Integer>(0, 0); } /* New shift! */
		shifts = computeShiftPair(shifts, value.shift);
		dataShift.put(itemName, shifts);
		dataConnectivity.put(itemName, value.iterator.container.connectivityCall.connectivity.name)
	}
	
	protected def loopDataDependencies(Loop it)
	'''
		«FOR itemindex : iterationBlock.eAllContents.filter(ItemIndex).toIterable»
			 // [«itemindex.itemName» => «dataShift.get(itemindex.itemName.toString)» | «dataConnectivity.get(itemindex.itemName.toString)»]
		«ENDFOR»
	'''
	
	protected def launchSingleTask(Loop it, /* The CORE loop */
		CharSequence taskNum, CharSequence taskLimit,
		CharSequence baseIndex, CharSequence taskNbElems, /* The limits */
		Set<Variable> ins, Set<Variable> outs, Set<Variable> inouts /* The variables dependencies (DataFlow) */
	) {
	'''
		{
			// Launch task `«taskNum»` out of `«taskLimit»`
			«loopDataDependencies»
			// static unsigned long ___task_id = 0;
			const size_t baseIndex = «baseIndex»;
			const size_t taskNbElems = «taskNbElems»;
			#pragma omp task firstprivate(baseIndex, taskNbElems)«
				getDependencies('in',    ins,    taskNum, taskLimit) /* Consumed by the task */»«
				getDependencies('out',   outs,   taskNum, taskLimit) /* Produced by the task */»«
				getDependencies('inout', inouts, taskNum, taskLimit) /* Consumed AND produced by the task */»
			// #pragma omp atomic
			// this->task_id++;
			// (UNIQ_task_id, ['in', 'in', ...], ['out', 'out', ...], start, duration) // with DAG-dot
			// fprintf(stderr, "('task_%ld', [«
				FOR v : ins SEPARATOR ', '»'«v.name»'«ENDFOR»«FOR v : inouts SEPARATOR ', '»'«v.name»'«ENDFOR»], [«
				FOR v : outs SEPARATOR ', '»'«v.name»'«ENDFOR»«FOR v : inouts SEPARATOR ', '»'«v.name»'«ENDFOR»], 0, 0)\n", task_id);
			for (size_t «iterationBlock.indexName» = baseIndex; «iterationBlock.indexName»<(baseIndex+taskNbElems); «iterationBlock.indexName»++)
			{
				«body.innerContent»
			}
		}
	'''
	}
	
	protected def launchTasks(Loop it, int taskN)
	{
		val ins = getInVars             /* Need to be computed before, consumed        */
		val outs = getOutVars           /* Produced, unlock jobs that need them        */
		val Set<Variable> inouts = ins.clone.toSet  /* Produced and consumed variables */
		inouts.retainAll(outs)
		ins.removeAll(inouts)
		outs.removeAll(inouts)

		/* The code */
		val nbElems = iterationBlock.nbElems
		val itemidcount = eAllContents.filter(ItemIdDefinition).size
		if (itemidcount == 0)
		{
			val String itemname = iterationBlock.indexName.toString
			if (Pattern.matches(".*Cells", itemname) || Pattern.matches(".*cells", itemname)) {
				dataShift.put(String::valueOf(itemname.charAt(0)), new Pair<Integer, Integer>(0, 0))
				dataConnectivity.put(String::valueOf(itemname.charAt(0)), "cells");
			} else if (Pattern.matches(".*Nodes", itemname) || Pattern.matches(".*nodes", itemname)) {
				dataShift.put(String::valueOf(itemname.charAt(0)), new Pair<Integer, Integer>(0, 0))
				dataConnectivity.put(String::valueOf(itemname.charAt(0)), "nodes");
			} else { throw new Exception("Unknown iterator " + itemname + ", could not autofill dataShifts and dataConnectivity") }
		}
		'''
			for (size_t task = 0; task < («taskN»-1); ++task)
			«launchSingleTask('''task''', '''«taskN»''', '''(«nbElems» / «taskN») * task''', '''(«nbElems» / «taskN»)''', ins, outs, inouts)»
			/* TASKLOOP REMAIN */
			«val remaining = '''(«nbElems» % «taskN»)'''»
			«val taskNbElems = '''(«nbElems» / «taskN»)'''»
			«launchSingleTask('''(«taskN» - 1)''', '''«taskN»''', '''(«nbElems»-«remaining»-«taskNbElems»)''', '''(«taskNbElems» + «remaining»)''', ins, outs, inouts)»
		'''
	}
	
	protected override CharSequence getSequentialLoopContent(Loop it)
	'''
		/* SEQUENTIAL LOOP BEGIN */
		«loopDataDependencies»
		for (size_t «iterationBlock.indexName»=0; «iterationBlock.indexName»<«iterationBlock.nbElems»; «iterationBlock.indexName»++)
		{
			«body.innerContent»
		}
		/* SEQUENTIAL LOOP END */
	'''
	
	def getDependenciesAll(String inout, Iterable<Variable> deps, int fromTask, int taskLimit)
	{
		if (deps.length != 0)
		{
			val range = IntStream.range(fromTask, taskLimit).toArray
			''' depend(«inout»: «
			FOR v : deps SEPARATOR ',\\\n'»«
				IF v.isVariableRange»«FOR i : range SEPARATOR ',\\\n'»«getVariableName(v)»«getVariableRange(v, i.toString, taskLimit.toString)»«ENDFOR»«
				ELSE»«getVariableName(v)»«ENDIF»«
			ENDFOR»)'''
		}
		else ''''''
	}

	def getDependencies(String inout, Iterable<Variable> deps, CharSequence taskCurrent, CharSequence taskLimit)
	{
		if (deps.length != 0)
			''' depend(«inout»: «FOR v : deps SEPARATOR ', '»«
				getVariableName(v)»«getVariableRange(v, taskCurrent, taskLimit)
			»«ENDFOR»)'''
		else ''''''
	}

	/* Variable name that will let OMP use it with the depend clauses... */
	private def getVariableName(Variable it) { isOption ? '''options.«name»''' : '''this->«name»''' }
	private def isVariableRange(Variable it)
	{
		val type = (it as ArgOrVar).type;
		switch (type) {
			ConnectivityType: return true
			default: return false
		}
	}
	private def getVariableRange(Variable it, CharSequence taskCurrent, CharSequence taskLimit)
	{
		val type = (it as ArgOrVar).type;
		switch (type) {
			ConnectivityType: {
				val connectivites = (type as ConnectivityType).connectivities.map[name];
				val cppname       = getVariableName;
				val depInferior   = '''«cppname».size()*(«taskCurrent»)/(«taskLimit»)'''
				// val depSuperior   = '''«cppname».size()*(«taskCurrent»+1)/(«taskLimit»)'''
				return '''[«depInferior»]/*«connectivites»*/'''
			}
			LinearAlgebraType: return '''''' /* This is an opaque type, don't know what to do with it */
			BaseType: return '''''' /* An integer, etc => the name is the dependency */
			default: return '''''' /* Don't know => pin all the variable */
		}
	}
	
	/* Get DF */
	private def getInVars(IterableInstruction it) { return eAllContents.filter(ArgOrVarRef).filter[x|x.eContainingFeature != IrPackage::eINSTANCE.affectation_Left].map[target].filter(Variable).filter[global].toSet }
	private def getOutVars(IterableInstruction it) { return eAllContents.filter(Affectation).map[left.target].filter(Variable).filter[global].toSet }

	private def getInVars(Job it) { return eAllContents.filter(ArgOrVarRef).filter[x|x.eContainingFeature != IrPackage::eINSTANCE.affectation_Left].map[target].filter(Variable).filter[global].toSet }
	private def getOutVars(Job it) { return eAllContents.filter(Affectation).map[left.target].filter(Variable).filter[global].toSet }
}