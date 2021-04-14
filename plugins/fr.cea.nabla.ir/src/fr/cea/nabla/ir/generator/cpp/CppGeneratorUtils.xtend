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

import static extension fr.cea.nabla.ir.ExtensionProviderExtensions.getInstanceName
import static extension fr.cea.nabla.ir.IrModuleExtensions.getClassName
import static extension fr.cea.nabla.ir.Utils.getIrModule
import static extension fr.cea.nabla.ir.ArgOrVarExtensions.*
import fr.cea.nabla.ir.ir.ExternFunction
import fr.cea.nabla.ir.ir.InternFunction
import fr.cea.nabla.ir.ir.IrModule
import fr.cea.nabla.ir.ir.IterableInstruction
import fr.cea.nabla.ir.ir.Job
import fr.cea.nabla.ir.ir.ArgOrVarRef
import fr.cea.nabla.ir.ir.Affectation
import fr.cea.nabla.ir.ir.Variable
import fr.cea.nabla.ir.ir.IrPackage
import fr.cea.nabla.ir.ir.ConnectivityType
import fr.cea.nabla.ir.ir.ArgOrVar
import fr.cea.nabla.ir.ir.ItemIndex
import fr.cea.nabla.ir.ir.IrAnnotable
import fr.cea.nabla.ir.ir.Loop
import fr.cea.nabla.ir.ir.ReductionInstruction
import fr.cea.nabla.ir.generator.cpp.TypeContentProvider
import org.eclipse.xtext.EcoreUtil2
import java.util.stream.IntStream
import java.util.Iterator
import java.util.HashSet
import java.util.Set
import java.util.HashMap

enum INDEX_TYPE { NODES, CELLS, FACES, NULL }

class CppGeneratorUtils
{
	def static <T>Iterable<T> iteratorToIterable(Iterator<T> iterator) { [iterator] }

	static def getFreeFunctionNs(IrModule it) { className.toLowerCase + "freefuncs" }
	static def dispatch getCodeName(InternFunction it) { irModule.freeFunctionNs + '::' + name }
	static def getHDefineName(String name) { '__' + name.toUpperCase + '_H_' }

	static TypeContentProvider typeContentProvider = new StlThreadTypeContentProvider();
	static def void registerTypeContentProvider(TypeContentProvider typeCtxProv) { typeContentProvider = typeCtxProv; }
	
	/* FIXME: Those two need to be specified in the NGEN file */
	static public int OMPTaskMaxNumber = 4
	static public boolean OMPTraces = false
	static def OMPTaskMaxNumberIterator() { iteratorToIterable(IntStream.range(0, OMPTaskMaxNumber).iterator) }
	
	static def getAllOMPTasks() { iteratorToIterable(IntStream.range(0, OMPTaskMaxNumber).iterator) }
	static def getAllOMPTasksAsCharSequence() '''{«FOR i : iteratorToIterable(IntStream.range(0, OMPTaskMaxNumber).iterator) SEPARATOR ', '»«i»«ENDFOR»}'''
	
	/* Global variable => index type */
	static HashMap<String, INDEX_TYPE> GlobalVariableIndexTypes = new HashMap();
	static def void registerGlobalVariable(String varName, INDEX_TYPE type) {
		if (type !== null && type != INDEX_TYPE::NULL)
			GlobalVariableIndexTypes.put(varName, type);
	}
	static def void registerGlobalVariable(String varName, String type) {
		if (type !== null && type != INDEX_TYPE::NULL) {
			switch type {
				case "nodes": GlobalVariableIndexTypes.put(varName, INDEX_TYPE::NODES)
				case "cells": GlobalVariableIndexTypes.put(varName, INDEX_TYPE::CELLS)
				case "faces": GlobalVariableIndexTypes.put(varName, INDEX_TYPE::FACES)
			}
		}
	}
	static def void registerGlobalVariable(IrModule it) {
		for (v : variables.filter[!option].filter[ t |
			typeContentProvider.getCppTypeCanBePartitionized(t.type) &&
			typeContentProvider.getCppTypeEnum(t.type) == CPP_TYPE::CONNECTIVITY
		]) { registerGlobalVariable(v.name, (v.type as ConnectivityType).connectivities.head.name) }
	}
	static def INDEX_TYPE getGlobalVariableType(String varName) {
		return GlobalVariableIndexTypes.getOrDefault(varName, INDEX_TYPE::NULL);
	}
	static def void resetGlobalVariable() { GlobalVariableIndexTypes.clear }
	
	/* Global variables produced by a super task => don't bother with indices as it breaks everything with OpenMP */
	static HashSet<String> GlobalVariableProducedBySuperTask = new HashSet();
	static def void resetGlobalVariableProducedBySuperTask() { GlobalVariableProducedBySuperTask.clear }
	static def void registerGlobalVariableProducedBySuperTask(IrModule it) {
		eAllContents.filter(Job).forEach[ j |
			if (!jobIsSuperTask(j))
				return;
				j.outVars.forEach[ v | GlobalVariableProducedBySuperTask.add(v.name) ]
		]
	}
	
	/* False 'in' variables */
	static private def getFalseInVariableForJob(Job it)
	{
		val parentJobCaller = caller
		if (parentJobCaller === null) {
			println("No parent job caller...")
			return #[]
		}
		var allouts = new HashSet<Variable>();
		var allins  = new HashSet<Variable>();
		for (j : parentJobCaller.calls) {
			allins.addAll(j.inVars)
			allouts.addAll(j.outVars)
		}
		allins.removeAll(allouts)
		return allins
	}

	static def dispatch getCodeName(ExternFunction it)
	{
		if (provider.extensionName == "Math") 'std::' + name
		else 'options.' + provider.instanceName + '.' + name
	}
	
	/* Get most used variables in loops and reductions */
	static def getMostUsedVariable(IterableInstruction it)
	{
		val affectations = eAllContents.filter(ArgOrVarRef);
		val targets = affectations.filter(Variable);
		val used = affectations.filter(ItemIndex);
	}

	/* Get variable dependencies and their ranges, etc */
	static def getVariableName(Variable it) { isOption ? '''options.«name»''' : '''this->«name»''' }
	static def isVariableRange(Variable it)
	{
		if (isOption)
			return false

		val type = (it as ArgOrVar).type;
		switch (type) {
			ConnectivityType: return true
			default: return false
		}
	}
	
	/* Construct OpenMP clauses */
	static def getPriority(Job it)
	{
		if (it !== null)
		{
			val max_at = caller.calls.map[at].max
			''' /* priority(«(max_at - at + 1.0).intValue») */'''
		} else ''''''
	}
	
	static def getDependencies_PARTITION(Job it, String inout, Iterable<Variable> deps, CharSequence taskPartition, boolean needNeighbors)
	{
		/* Construct the OpenMP clause */
		val falseIns = getFalseInVariableForJob(it);
		val dependencies = deps.toSet;
		if (dependencies.length == 0) return ''''''
		dependencies.removeAll(falseIns)

		val dep_ranges  = dependencies.filter(v|v.isVariableRange);
		val dep_simple  = dependencies.filter(v|!v.isVariableRange);
		val need_ranges = dep_ranges.length >= 1;
		val need_simple = dep_simple.length >= 1;
		var ret = ''''''

		/* All ranges, with the neighbors */
		if (need_ranges && needNeighbors)
			ret = ''' \
/* dep partition (range neighbor) */ depend(«inout»: «FOR v : dep_ranges SEPARATOR ', '»«
FOR i : iteratorToIterable(IntStream.range(0, OMPTaskMaxNumber).iterator) SEPARATOR ', '
»this->partitions[mesh->NEIGHBOR_getForPartition(«taskPartition», «i»)].«v.name»«ENDFOR»«ENDFOR»)'''
		
		/* All ranges, but without neighbors */
		else if (need_ranges)
			ret = ''' \
/* dep partiton (range no-neighbor) */ depend(«inout»: «FOR v : dep_ranges SEPARATOR ', '»this->partitions[«taskPartition»].«v.name»«ENDFOR»)'''

		/* All simple values */
		if (need_simple)
			ret = '''«ret» \
/* dep partition (simple) */ depend(«inout»: «FOR v : dep_simple SEPARATOR ', '»«getVariableName(v)»«ENDFOR»)'''
		
		return ret
	}

	static def getUsedIndexType(Job it) {
		val variables = inVars
		variables.addAll(outVars)
		if (variables.length == 0) return #[].toSet

		val falseIns = falseInVariableForJob;
		variables.removeAll(falseIns)
		
		val ret = variables.map[name.globalVariableType].toSet
		ret.remove(INDEX_TYPE::NULL)
		return ret
	}
	
	static def convertIndexType(CharSequence index, INDEX_TYPE basetype, INDEX_TYPE casttype, boolean lower)
	{
		switch basetype {
		case INDEX_TYPE::CELLS: {
			switch casttype {
				case INDEX_TYPE::NODES: return '''internal::«lower ? 'min' : 'max'»(mesh->getNodesOfCell(«index»))'''
				case INDEX_TYPE::FACES: return '''internal::«lower ? 'min' : 'max'»(mesh->getFacesOfCell(«index»))'''
				case INDEX_TYPE::CELLS: return index
				default: {}
			}
		}

		case INDEX_TYPE::NODES: {
			switch casttype {
				case INDEX_TYPE::CELLS: return '''internal::«lower ? 'min' : 'max'»(mesh->getCellsOfNode(«index»))'''
				case INDEX_TYPE::NODES: return index
				default: {}
			}
		}

		case INDEX_TYPE::FACES: {
			switch casttype {
				case INDEX_TYPE::FACES: return index
				case INDEX_TYPE::CELLS: return '''internal::«lower ? 'min' : 'max'»(mesh->getCellsOfFace(«index»))'''
				case INDEX_TYPE::NODES: return '''internal::«lower ? 'min' : 'max'»(mesh->getNodesOfFace(«index»))'''
				default: {}
			}
		}
			
		case INDEX_TYPE::NULL:
			throw new Exception("Can't convert from index of type 'NULL'")
		}
		
		throw new Exception("Unknown conversion from '" + basetype + "' to '" + casttype + "'")
	}

	static def getDependencies_LOOP(Job it, String inout, Iterable<Variable> deps, CharSequence from, CharSequence count)
	{
		/* Construct the OpenMP clause */
		val falseIns = getFalseInVariableForJob(it);
		val dependencies = deps.toSet;
		if (dependencies.length == 0) return ''''''
		dependencies.removeAll(falseIns)
		
		/* Force simple variables if it's produced by a super task */
		val forced_simple = dependencies.filter[v|GlobalVariableProducedBySuperTask.contains(v.name)].toSet
		dependencies.removeAll(forced_simple)

		val dep_ranges  = dependencies.filter(v|v.isVariableRange);
		val dep_simple  = dependencies.filter(v|!v.isVariableRange).toSet;
		dep_simple.addAll(forced_simple) /* Forced simple */

		val need_ranges = dep_ranges.length >= 1;
		val need_simple = dep_simple.length >= 1;
		var ret         = ''''''

		/* All ranges  */
		if (need_ranges) {
		ret = ''' \
«FOR v : dep_ranges SEPARATOR ' \\\n'
	»/* dep loop (range) */ depend(«inout»:	(this->«v.name»[«from»_«v.name.globalVariableType»]))«
ENDFOR»'''
		}

		/* All simple values */
		if (need_simple)
			ret = '''«ret» \
«FOR v : dep_simple SEPARATOR ', \\\n'»/* dep loop (simpL) */ depend(«inout»:	(this->«v.name»))«ENDFOR»'''
		
		return ret
	}
	
	static def getBaseIndex_LOOP(CharSequence nbElems, CharSequence partitionId) '''((«nbElems» / «OMPTaskMaxNumber») * «partitionId»)'''

	static def getAffinities(Job it, Iterable<Variable> deps, CharSequence taskPartition)
	{
		val falseIns = getFalseInVariableForJob(it);
		val dep = deps.filter(v | v.isVariableRange).toSet // Simple and stupid algorithm to choose which variable is important
		if (dep.length == 0) return ''''''
		dep.removeAll(falseIns)
		// return ''' affinity(this->«dep.head.name»[«getVariableRange(dep.head, taskPartition)»])'''
		return ''''''
	}

	static def getDependenciesAll_PARTITION(Job it, String inout, Iterable<Variable> deps, int fromTask, int taskLimit)
	{
		/* Construct the OpenMP clause(s) */
		val falseIns = getFalseInVariableForJob(it);
		val dependencies = deps.toSet;
		if (dependencies.length == 0) return ''''''
		dependencies.removeAll(falseIns)

		val dep_ranges  = dependencies.filter(v|v.isVariableRange);
		val dep_simple  = dependencies.filter(v|!v.isVariableRange);
		val need_ranges = dep_ranges.length >= 1;
		val need_simple = dep_simple.length >= 1;
		var ret = ''''''

		if (need_ranges)
		{
			/* All ranges */
			ret = ''' \
/* dep partition all (range) */ depend(«inout»: «FOR v : dep_ranges SEPARATOR ', '»«
FOR i : iteratorToIterable(IntStream.range(0, OMPTaskMaxNumber).iterator) SEPARATOR ', '
»this->partitions[«i»].«v.name»«ENDFOR»«ENDFOR»)'''
		}

		if (need_simple)
		{
			/* All simple values */
			ret = '''«ret» \
/* dep partition all (simple) */ depend(«inout»: «FOR v : dep_simple SEPARATOR ', '»this->«v.name»«ENDFOR»)'''
		}

		return ret
	}

	static def getDependenciesAll_LOOP(Job it, String inout, Iterable<Variable> deps)
	{
		/* Construct the OpenMP clause(s) */
		val falseIns = getFalseInVariableForJob(it);
		val dependencies = deps.toSet;
		if (dependencies.length == 0) return ''''''
		dependencies.removeAll(falseIns)

		/* Force simple variables if it's produced by a super task */
		val forced_simple = dependencies.filter[v|GlobalVariableProducedBySuperTask.contains(v.name)].toSet
		dependencies.removeAll(forced_simple)

		val dep_ranges  = dependencies.filter(v|v.isVariableRange);
		val dep_simple  = dependencies.filter(v|!v.isVariableRange).toSet;
		dep_simple.addAll(forced_simple) /* Forced simple */

		val need_ranges = dep_ranges.length >= 1;
		val need_simple = dep_simple.length >= 1;
		var ret = ''''''

		if (need_ranges)
		{
			/* All ranges : XXX : Can't be used with partial things like 'innerCells', must be all the variable */
			ret = '''«FOR v : dep_ranges SEPARATOR ' \\\n'»«FOR i : OMPTaskMaxNumberIterator» \
/* dep loop all (rgpin) */ depend(«inout»:	(this->«v.name»[«getBaseIndex_LOOP('''(this->«v.name».size())''', '''«i»''')»]))«
ENDFOR»«ENDFOR»'''
		}

		if (need_simple)
		{
			/* All simple values */
			ret = '''«ret» \
«FOR v : dep_simple SEPARATOR ' \\\n'»/* dep loop all (simpL) */ depend(«inout»:	(this->«v.name»))«ENDFOR»'''
		}

		return ret
	}

	static def takeOMPTraces_PARTITION(IrAnnotable it, Set<Variable> ins, Set<Variable> outs, CharSequence partitionId, boolean need_neighbors) {
		if (OMPTraces) {
			val parentJob      = EcoreUtil2.getContainerOfType(it, Job)
			val ins_fmt        = ins.map[printVariableRangeFmt_PARTITION(partitionId, need_neighbors)]
			val outs_fmt       = outs.map[printVariableRangeFmt_PARTITION(partitionId, false)]
			val printf_values  = ins.map[printVariableRangeValue_PARTITION(partitionId, need_neighbors)].toList
			printf_values.addAll(outs.map[printVariableRangeValue_PARTITION(partitionId, false)])

			'''
			fprintf(stderr, "(\"T«parentJob.name»@«parentJob.at»«IF partitionId !== null»:%ld«ENDIF»\", [«
				FOR v : ins_fmt  SEPARATOR ', '»«v»«ENDFOR»], [«
				FOR v : outs_fmt SEPARATOR ', '»«v»«ENDFOR»])\n"«
				IF partitionId !== null», «partitionId»«ENDIF»«
				IF printf_values.size > 0», «FOR v : printf_values SEPARATOR ', '»«v»«ENDFOR»«ENDIF»);
			'''
		}
		else ''''''
	}
	
	static def printVariableRangeFmt_PARTITION(Variable it, CharSequence taskCurrent, boolean needNeighbors)
	{
		if ((!isVariableRange) || (!needNeighbors && taskCurrent !== null))
			return '''\"%p\"'''

		/* Need the neighbors, or just get all for the getDependencies /
		 * getDependenciesAll cases. Here it's the same, but keep the if / else
		 * to have the same logic has in the printVariableRangeValue function. */
		val iterator = iteratorToIterable(IntStream.range(0, OMPTaskMaxNumber).iterator)
		if (taskCurrent !== null)
			return '''«FOR i : iterator SEPARATOR ', '»\"%p\"«ENDFOR»'''
		else
			return '''«FOR i : iterator SEPARATOR ', '»\"%p\"«ENDFOR»'''
	}
	static def printVariableRangeValue_PARTITION(Variable it, CharSequence taskCurrent, boolean needNeighbors)
	{
		if (!isVariableRange)
			return '''&«name»'''

		if (!needNeighbors && taskCurrent !== null)
			return '''&(this->partitions[«taskCurrent»].«name»)'''

		/* Need the neighbors, or just get all for the getDependencies/getDependenciesAll cases */
		val iterator = iteratorToIterable(IntStream.range(0, OMPTaskMaxNumber).iterator)
		if (taskCurrent !== null)
			return '''«FOR i : iterator SEPARATOR ', '»&(this->partitions[mesh->NEIGHBOR_getForPartition(«taskCurrent», «i»)].«name»)«ENDFOR»'''
		else
			return '''«FOR i : iterator SEPARATOR ', '»&(this->partitions[«i»].«name»)«ENDFOR»'''
	}
	
	static def indexVariableDeclarationsIfOMPTraces_LOOP(Job parentJob)
	'''
		«IF OMPTraces»
		const size_t task = 0;
		«FOR idxType : parentJob.usedIndexType»
			«val sample_variable = parentJob.allVars.filter[v | v.name.globalVariableType == idxType].head»
			const Id ___omp_base_«idxType»  = 0;
			const Id ___omp_count_«idxType» = «sample_variable.name».size() - 1;
			#if NABLA_DEBUG == 1
			assert(___omp_count_«idxType» >= 1);
			#endif
		«ENDFOR»
		«ENDIF»
	'''
	static def printVariableRange_LOOP(Job it, Set<Variable> ins, Set<Variable> outs) {
		if (!OMPTraces)
			return ''''''
		/* Construct the OpenMP clause(s) */
		val falseIns = getFalseInVariableForJob(it);
		ins.removeAll(falseIns)
		outs.removeAll(falseIns)

		/* Force simple variables if it's produced by a super task */
		val forced_simple_ins  = ins.filter[v|GlobalVariableProducedBySuperTask.contains(v.name)].toSet
		val forced_simple_outs = outs.filter[v|GlobalVariableProducedBySuperTask.contains(v.name)].toSet
		ins.removeAll(forced_simple_ins)
		outs.removeAll(forced_simple_outs)

		val dep_ranges_ins  = ins.filter(v|v.isVariableRange).toList;
		val dep_simple_ins  = ins.filter(v|!v.isVariableRange).toSet;
		dep_simple_ins.addAll(forced_simple_ins) /* Forced simple */

		val dep_ranges_outs = outs.filter(v|v.isVariableRange).toList;
		val dep_simple_outs = outs.filter(v|!v.isVariableRange).toSet;
		dep_simple_outs.addAll(forced_simple_outs) /* Forced simple */
		
		/* Print the unique task id */
		var ret = '''fprintf(stderr, "(\"T«name»@«at»:%ld\", [", task);'''
		
		/* Print the IN dependencies */
		if (dep_simple_ins.length > 0) { ret = '''«ret»fprintf(stderr, "«FOR v : dep_simple_ins SEPARATOR ', '»\"«v.name»\"«ENDFOR»");''' }
		if (dep_ranges_ins.length > 0) {
			for (var int i = 0; i < dep_ranges_ins.length; i += 1) {
				if (i != 0) {
					ret = '''
					«ret»
					fprintf(stderr, ", ");
					'''
				}
				ret = '''
				«ret»
				for (Id i = ___omp_base_«dep_ranges_ins.get(i).name.globalVariableType
				»; i < ___omp_base_«dep_ranges_ins.get(i).name.globalVariableType
				» + ___omp_count_«dep_ranges_ins.get(i).name.globalVariableType» + 1; ++i) { fprintf(stderr, "\"«
				dep_ranges_ins.get(i).name»_%ld\"", i); if (i != ___omp_base_«dep_ranges_ins.get(i).name.globalVariableType
				» + ___omp_count_«dep_ranges_ins.get(i).name.globalVariableType») fprintf(stderr, ", "); }
				'''
			}
		}

		/* Separation */
		ret = '''
		«ret»
		fprintf(stderr, "], [");
		'''
		
		/* Print the OUT dependencies */
		if (dep_simple_outs.length > 0) { ret = '''«ret»fprintf(stderr, "«FOR v : dep_simple_outs SEPARATOR ', '»\"«v.name»\"«ENDFOR»");''' }
		if (dep_ranges_outs.length > 0) {
			for (var int i = 0; i < dep_ranges_outs.length; i += 1) {
				if (i != 0) {
					ret = '''
					«ret»
					fprintf(stderr, ", ");
					'''
				}
				ret = '''
				«ret»
				for (Id i = ___omp_base_«dep_ranges_outs.get(i).name.globalVariableType
				»; i < ___omp_base_«dep_ranges_outs.get(i).name.globalVariableType
				» + ___omp_count_«dep_ranges_outs.get(i).name.globalVariableType» + 1; ++i) { fprintf(stderr, "\"«
				dep_ranges_outs.get(i).name»_%ld\"", i); if (i != ___omp_base_«dep_ranges_outs.get(i).name.globalVariableType
				» + ___omp_count_«dep_ranges_outs.get(i).name.globalVariableType») fprintf(stderr, ", "); }
				'''
			}
		}
		
		/* Print the end of the trace line */
		ret = '''
		«ret»
		fprintf(stderr, "])\n");
		'''

	}
	
	static def getLoopRange(CharSequence connectivityType, CharSequence taskCurrent) '''mesh->RANGE_«connectivityType»FromPartition(«taskCurrent»)'''
	
	/* Is a job a super task job? */
	static def boolean jobIsSuperTask(Job it) {
		return (
			eAllContents.filter(Loop).filter[multithreadable].size +
			eAllContents.filter(ReductionInstruction).size
		) > 3
		/* Magic number, take into account the initial loops, see
		 * `OpenMpTaskInstructionContentProvider::getChildTasks(InstructionBlock it)`
		 * For the original formula. */
	}

	/* Get DF */
	static def getInVars(Job it) {
		(it === null)
		? #[].toSet
		: eAllContents.filter(ArgOrVarRef).filter[x|x.eContainingFeature != IrPackage::eINSTANCE.affectation_Left].map[target].filter(Variable).filter[global].toSet
	}
	static def getOutVars(Job it) {
		(it === null)
		? #[].toSet
		: eAllContents.filter(Affectation).map[left.target].filter(Variable).filter[global].toSet
	}
	static def getAllVars(Job it) {
		val ret = inVars.toSet;
		ret.addAll(outVars)
		return ret;
	}
	
	/* Shared variables, don't copy them into threads */
	static def getSharedVarsNames_PARTITION(Job it) {
		val ins = caller.calls.map[inVars.filter[!isOption].filter[t|!typeContentProvider.getCppTypeCanBePartitionized(t.type)]].flatten.toSet;
		ins.addAll(outVars.filter[!isOption].filter[t|!typeContentProvider.getCppTypeCanBePartitionized(t.type)])
		val ret = ins.map["this->" + name].toSet
		ret.add("this->partitions")
		return ret
	}
	static def getSharedVarsClause_PARTITION(Job it) {
		val shared = sharedVarsNames_PARTITION
		'''default(none) shared(stderr, mesh«IF shared.size > 0», «FOR v : shared SEPARATOR ', '»«v»«ENDFOR»«ENDIF»)'''
	}
	static def getSharedVarsNames_LOOP(Job it) {
		val ins = inVars.filter[!isOption].toSet;
		ins.addAll(outVars.filter[!isOption])
		val ret = ins.map["this->" + name].toSet
		return ret
	}
	static def getSharedVarsClause_LOOP(Job it, boolean isDependAll) {
		val shared = sharedVarsNames_LOOP
		''' \
default(none) shared(stderr, mesh«IF shared.size > 0», «FOR v : shared SEPARATOR ', '»«v»«ENDFOR»«ENDIF»)'''
	}
	static def getFirstPrivateVars_LOOP(Job it) {
		val idxs   = usedIndexType.map[t | '''___omp_base_«t», ___omp_count_«t», ___omp_min_«t», ___omp_max_«t»''' ]
		''' \
firstprivate(task, ___omp_base, ___omp_limit«IF idxs.size > 0», «ENDIF»«FOR i : idxs SEPARATOR ', '»«i»«ENDFOR»)'''
	}
}
