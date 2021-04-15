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
import fr.cea.nabla.ir.ir.Loop
import fr.cea.nabla.ir.ir.ReductionInstruction
import fr.cea.nabla.ir.generator.cpp.TypeContentProvider
import java.util.stream.IntStream
import java.util.Iterator
import java.util.HashSet
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
			''' priority(«(max_at - at + 1.0).intValue»)'''
		} else ''''''
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

	static def getDependencies(Job it, String inout, Iterable<Variable> deps, CharSequence from, CharSequence count)
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
	
	static def getBaseIndex(CharSequence nbElems, CharSequence partitionId) '''((«nbElems» / «OMPTaskMaxNumber») * «partitionId»)'''

	static def getAffinities(Job it, Iterable<Variable> deps, CharSequence taskPartition)
	{
		val falseIns = getFalseInVariableForJob(it);
		val dep = deps.filter(v | v.isVariableRange).toSet // Simple and stupid algorithm to choose which variable is important
		if (dep.length == 0) return ''''''
		dep.removeAll(falseIns)
		// return ''' affinity(this->«dep.head.name»[«getVariableRange(dep.head, taskPartition)»])'''
		return ''''''
	}

	static def getDependenciesAll(Job it, String inout, Iterable<Variable> deps)
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
/* dep loop all (rgpin) */ depend(«inout»:	(this->«v.name»[«getBaseIndex('''(this->«v.name».size())''', '''«i»''')»]))«
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
	static def getSharedVarsNames(Job it) {
		val ins = inVars.filter[!isOption].toSet;
		ins.addAll(outVars.filter[!isOption])
		val ret = ins.map["this->" + name].toSet
		return ret
	}
	static def getSharedVarsClause(Job it, boolean isDependAll) {
		val shared = sharedVarsNames
		''' \
default(none) shared(stderr, mesh«IF shared.size > 0», «FOR v : shared SEPARATOR ', '»«v»«ENDFOR»«ENDIF»)'''
	}
	static def getFirstPrivateVars(Job it) {
		val idxs   = usedIndexType.map[t | '''___omp_base_«t», ___omp_count_«t»''' ]
		''' \
firstprivate(task, ___omp_base, ___omp_limit«IF idxs.size > 0», «ENDIF»«FOR i : idxs SEPARATOR ', '»«i»«ENDFOR»)'''
	}
}
