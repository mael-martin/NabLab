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
import static extension fr.cea.nabla.ir.ContainerExtensions.*
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
import fr.cea.nabla.ir.ir.ConnectivityCall
import fr.cea.nabla.ir.ir.IrAnnotable
import fr.cea.nabla.ir.ir.Container
import fr.cea.nabla.ir.ir.TimeLoopJob
import fr.cea.nabla.ir.ir.JobCaller
import fr.cea.nabla.ir.ir.ExecuteTimeLoopJob
import fr.cea.nabla.ir.generator.cpp.TypeContentProvider
import fr.cea.nabla.ir.JobDependencies
import org.eclipse.xtext.EcoreUtil2
import java.util.stream.IntStream
import java.util.Iterator
import java.util.HashSet
import java.util.HashMap
import java.util.List
import java.util.Set
import java.util.stream.Collectors

enum INDEX_TYPE { NODES, CELLS, FACES, NULL }

class CppGeneratorUtils
{
	def static <T>Iterable<T> iteratorToIterable(Iterator<T> iterator) { [iterator] }

	static def getFreeFunctionNs(IrModule it) { className.toLowerCase + "freefuncs" }
	static def dispatch getCodeName(InternFunction it) { irModule.freeFunctionNs + '::' + name }
	static def getHDefineName(String name) { '__' + name.toUpperCase + '_H_' }

	static TypeContentProvider typeContentProvider = new StlThreadTypeContentProvider();
	static def void registerTypeContentProvider(TypeContentProvider typeCtxProv) { typeContentProvider = typeCtxProv; }
	
	static HashMap<String, HashSet<String>> AccumulatedInVariablesPerJobs = new HashMap();
	static HashMap<String, HashSet<Variable>> MinimalInVariablesPerJobs   = new HashMap();
	static def void resetMinimalInVariables() {
		MinimalInVariablesPerJobs.clear
		AccumulatedInVariablesPerJobs.clear
	}
	static def computeMinimalInVariables(JobCaller jc) {
		/* Null check safety */
		if (jc === null)
			return null;
			
		/* Only the things that will be // */
		val jobs    = jc.calls.reject[ j | j instanceof TimeLoopJob || j instanceof ExecuteTimeLoopJob]
		val jobdeps = new JobDependencies()

		/* Init fulfilled variables for job is not needed, it will be
		 * directly computed from the IN and AccumulatedID. Init accumulated
		 * in variables for job */
		jobs.forEach[
			val HashSet<String> initAccIn = new HashSet();
			initAccIn.addAll(inVars.map[name])
			AccumulatedInVariablesPerJobs.put(name, initAccIn)
		]
		
		/* Compute fulfillment of variables by the jobs:
		 * - a variable is fulfilled if it is ensured that it is produced after the job ended
		 * - so a fulfilled variable, is a variable that is produced by the job, or a predecessor job
		 * - if a variable is subject to override, only the last job to produce it will fulfill it
		 * - all the fulfilled needed variables are the `IN \ Accumulated IN`
		 * - the Accumulated IN is the set of variables that are fulfilled before the job can begin */

		var boolean modified = true;
		while (modified) {
			/* We apply the formula
			 * 		`AccumulatedIN(j) = Union_{j' predecessor j}(IN(j'))`
			 * while the stable state is not reached.
			 * TODO: Use a BFS to do that, not a while(modified) */
			
			for (from : jobs) {
				for (to : jobdeps.getNextJobs(from).filter[x | jobs.contains(x)]) {
					/* In the DAG, have the edge `from -> to`. Here we do the following step:
					 * `AccumulatedIN(j) += IN(j')` */

					val accumulatedInTo   = AccumulatedInVariablesPerJobs.get(to.name);
					val accumulatedInFrom = AccumulatedInVariablesPerJobs.get(from.name);
					val sizeBeforeAddAll  = accumulatedInTo.size
					accumulatedInTo.addAll(accumulatedInFrom)
					modified = (sizeBeforeAddAll != accumulatedInTo.size)
				}
			}
		}
		
		/* Now apply the formula: `NeededFulfilledVars = IN \ AccumulatedIN of predecessors` */
		for (from : jobs) {
			for (to : jobdeps.getNextJobs(from).filter[x | jobs.contains(x)]) {
				val INS               = to.inVars;
				val accumulatedInFrom = AccumulatedInVariablesPerJobs.get(from.name);
				val minimalINS        = new HashSet();
				minimalINS.addAll(INS.reject[v | v.isConst || v.isConstExpr || accumulatedInFrom.contains(v.name)])
				MinimalInVariablesPerJobs.put(to.name, minimalINS)
			}
		}
	}
	
	/* FIXME: Those two need to be specified in the NGEN file */
	static public int OMPTaskMaxNumber = 4
	static public boolean OMPTraces = false
	static def OMPTaskMaxNumberIterator() {
		iteratorToIterable(IntStream.range(0, OMPTaskMaxNumber).iterator)
	}
	
	static def getAllOMPTasks() {
		iteratorToIterable(IntStream.range(0, OMPTaskMaxNumber).iterator)
	}
	static def getAllOMPTasksAsCharSequence()
	'''{«
	FOR i : iteratorToIterable(IntStream.range(0, OMPTaskMaxNumber).iterator) SEPARATOR ', '»«
		i»«
	ENDFOR»}'''
	
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
	static def Set<INDEX_TYPE> getPresentGlobalVariableTypes() {
		GlobalVariableIndexTypes.values.toSet
	}
	static def String getVariableIndexTypeLimit(INDEX_TYPE idxtype) {
		switch idxtype {
		case INDEX_TYPE::CELLS: return 'nbCells'
		case INDEX_TYPE::NODES: return 'nbNodes'
		case INDEX_TYPE::FACES: return 'nbFaces'
		case INDEX_TYPE::NULL:  throw new Exception("No contained element for variable, index type is INDEX_TYPE::NULL")
		}
	}
	static def INDEX_TYPE getGlobalVariableType(String varName) {
		return GlobalVariableIndexTypes.getOrDefault(varName, INDEX_TYPE::NULL);
	}
	static def String getGlobalVariableMaxElementNumber(String varName) {
		return GlobalVariableIndexTypes.getOrDefault(varName, INDEX_TYPE::NULL).variableIndexTypeLimit
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
	static def boolean isGlobalVariableProducedBySuperTask(String varName) { return GlobalVariableProducedBySuperTask.contains(varName) }
	
	/* Variables that will need to be first private */
	static HashMap<String, HashSet<String>> additionalFPriv  = new HashMap();
	static def void resetAdditionalFirstPrivateVariables() { additionalFPriv.clear }
	static def void registerAdditionalFirstPrivVariables(Job it) {
		if (it === null)
			return;
		eAllContents.filter(ConnectivityCall).filter[!connectivityCall.connectivity.indexEqualId].forEach[ container |
			val cname = (container as Container).uniqueName
			val afp   = additionalFPriv.getOrDefault(name, new HashSet())
			afp.add(cname)
			additionalFPriv.put(name, afp)
		]
	}
	static def void removeAdditionalFirstPrivVariables(IrAnnotable it) {
		if (it === null) return;
		val parentJob  = EcoreUtil2.getContainerOfType(it, Job)
		if (parentJob === null) return;
		eAllContents.filter(ConnectivityCall).filter[!connectivityCall.connectivity.indexEqualId].forEach[ container |
			val cname = (container as Container).uniqueName
			val afp   = additionalFPriv.getOrDefault(parentJob.name, null)
			if (afp === null) return;
			afp.remove(cname)
			additionalFPriv.put(parentJob.name, afp)
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
	static def getVariableName(Variable it) {
		if (isConstExpr) {
			val parentModule = EcoreUtil2.getContainerOfType(it, IrModule)
			return '''«parentModule.className»::«name»'''
		}

		else return isOption ? '''options.«name»''' : '''this->«name»'''
	}
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
				case INDEX_TYPE::NODES: return '''internal_omptask::«lower ? 'min' : 'max'»(mesh->getNodesOfCell(«index»))'''
				case INDEX_TYPE::FACES: return '''internal_omptask::«lower ? 'min' : 'max'»(mesh->getFacesOfCell(«index»))'''
				case INDEX_TYPE::CELLS: return index
				default: {}
			}
		}

		case INDEX_TYPE::NODES: {
			switch casttype {
				case INDEX_TYPE::CELLS: return '''internal_omptask::«lower ? 'min' : 'max'»(mesh->getCellsOfNode(«index»))'''
				case INDEX_TYPE::NODES: return index
				default: {}
			}
		}

		case INDEX_TYPE::FACES: {
			switch casttype {
				case INDEX_TYPE::FACES: return index
				case INDEX_TYPE::CELLS: return '''internal_omptask::«lower ? 'min' : 'max'»(mesh->getCellsOfFace(«index»))'''
				case INDEX_TYPE::NODES: return '''internal_omptask::«lower ? 'min' : 'max'»(mesh->getNodesOfFace(«index»))'''
				default: {}
			}
		}
			
		case INDEX_TYPE::NULL:
			throw new Exception("Can't convert from index of type 'NULL'")
		}
		
		throw new Exception("Unknown conversion from '" + basetype + "' to '" + casttype + "'")
	}

	static def getDependencies(Job it, String inout, Iterable<Variable> deps, CharSequence from)
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
«FOR v : dep_ranges SEPARATOR ' \\\n'»depend(«inout»:	(«getVariableName(v)»[«from»]))«ENDFOR»'''
		}

		/* All simple values */
		if (need_simple)
			ret = '''«ret» \
«FOR v : dep_simple SEPARATOR ', \\\n'»depend(«inout»:	(«getVariableName(v)»))«ENDFOR»'''
		
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

		val dep_ranges  = dependencies.filter(v|v.isVariableRange).toSet;
		val dep_simple  = dependencies.filter(v|!v.isVariableRange).toSet;
		dep_simple.addAll(forced_simple) /* Forced simple */

		var ret = ''''''
		
		/* Treat all duplicated outputs dependencies */
		val HashMap<String, String> correctionForDuplicatedOuts = new HashMap();
		if (inout == 'out' && isDuplicatedOutJob) {
			findDuplicatesOuts.forEach[ v | 
				correctionForDuplicatedOuts.put(v.name, v.name + '_' + name)
			]
		}

		val need_ranges = dep_ranges.length >= 1;
		val need_simple = dep_simple.length >= 1;

		if (need_ranges)
		{
			/* All ranges : XXX : Can't be used with partial things like 'innerCells', must be all the variable */
			ret = '''«ret»«
FOR v : dep_ranges»«FOR i : OMPTaskMaxNumberIterator» \
depend(«inout»:	(«
	getVariableName(v)»[«
	getBaseIndex('''(«getVariableName(v)».size())''', '''«i»''')»]))«
	ENDFOR»«ENDFOR»'''
		}

		if (need_simple)
		{
			/* All simple values */
			ret = '''«ret» \
«FOR v : dep_simple SEPARATOR ' \\\n'»depend(«inout»:	(«getVariableName(v)»))«ENDFOR»'''
		}

		return ret
	}
	
	static def createControlTask(String varName, List<String> jobsIn)
	{
		val idxtype = varName.globalVariableType
		if (idxtype == INDEX_TYPE::NULL || GlobalVariableProducedBySuperTask.contains(varName))
		'''
			// clang-format off
			#pragma omp task depend(in: «FOR j : jobsIn SEPARATOR ', '»«varName»_«j»«ENDFOR») depend(out: this->«varName»)
			{ /* Control Task */ }
			// clang-format on
		'''
		else
		'''
			«FOR i : OMPTaskMaxNumberIterator»
				«val base_index = '''«getBaseIndex('''«varName».size()''', '''«i»''')»'''»
				// clang-format off
				#pragma omp task depend(in: «FOR j : jobsIn SEPARATOR ', '»(this->«varName»_«j»[«i»])«ENDFOR») depend(out: (this->«varName»[«base_index»]))
				{ /* Control Task */ }
				// clang-format on
			«ENDFOR»
		'''
	}

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
	static def getInoutVars(Job it) {
		outVars.filter[ v | isVariableProduceByPredecessorJob(v) ]
	}
	static def getExclusivOutVars(Job it) {
		val otherOuts = caller.calls.filter[j | j != it].map[outVars].flatten
		return outVars.reject[ v | otherOuts.contains(v) ]
	}
	static def getMinimalInVars(Job it) {
		if (it === null)
			return new HashSet();
		return MinimalInVariablesPerJobs.getOrDefault(name, new HashSet())
	}
	
	/* Shared variables, don't copy them into threads */
	static def getSharedVarsNames(Job it) {
		val ins = inVars.filter[!isOption].toSet;
		ins.addAll(outVars.filter[!isOption])
		val ret = ins.map[variableName].toSet
		return ret
	}
	static def getSharedVarsClause(Job it) { getSharedVarsClause(it, #[]) }
	static def getSharedVarsClause(Job it, List<String> additional) {
		val shared = sharedVarsNames
		''' \
default(none) shared(stderr, mesh«
IF shared.size > 0», «FOR v : shared SEPARATOR ', '»«v»«ENDFOR»«ENDIF»«
FOR a : additional BEFORE ', ' SEPARATOR ', '»«a»«ENDFOR»)'''
	}
	static def getFirstPrivateVars(Job it) {
		''' \
firstprivate(task, ___omp_base, ___omp_limit«
	IF additionalFPriv !== null && additionalFPriv.getOrDefault(name, new HashSet()).length > 0», «
	FOR p : additionalFPriv.get(name) SEPARATOR ', '»«p»«ENDFOR»«
	ENDIF»)'''
	}
	
	/* Get duplicated out variables in job caller */
	static private def int getJobIndexInList(Job it, Job[] list) {
		val int index = list.indexed.map[ pair |
			val i = pair.key
			val j = pair.value
			return (j.name == name) ? i : list.size
		].reduce[ p1, p2 |
			return (p1 == list.size) ? p2 : p1
		]
		if (index == list.size)
			throw new Exception("Can't find job " + it + ' (' + name + '@' + at + ') in list')
		else
			return index
	}
	static def boolean isVariableProduceByPredecessorJob(Job it, Variable v) {
		if (it === null || caller === null)
			return false;
		val Job[] jobList    = caller.calls
		val jobIndexInList   = getJobIndexInList(jobList);
		val predProducedVars = jobList.indexed.filter[ pair |
			val j = pair.value
			return (pair.key >= jobIndexInList) && j.at <= at && j.name != name
		].map[pair|pair.value].map[outVars].flatten.toSet
		return predProducedVars.contains(v)
	}
	static def Set<Variable> findDuplicates(JobCaller it) {
		if (it === null)
			return #[].toSet
		val collection = calls.map[outVars].flatten.toList
		val uniques    = new HashSet<Variable>() 
		val ret        = collection.stream().filter([e | !uniques.add(e)]).collect(Collectors.toSet()) 
		return ret !== null ? ret : #[].toSet
	}
	static def Set<Job> getDuplicateOutJobs(JobCaller it) {
		if (it === null || calls === null)
			return #[].toSet
		val duplicatedOuts = findDuplicates
		if (duplicatedOuts === null || duplicatedOuts.size == 0)
			return #[].toSet
		return calls.filter[outVars.map[t|duplicatedOuts.contains(t)].reduce[p1, p2 | p1 || p2]].toSet
	}
	static def boolean isDuplicatedOutJob(Job it) {
		return it !== null ? caller.duplicateOutJobs.filter[j|j.name == name].size > 0 : false
	}
	static def Set<Variable> findDuplicatesOuts(Job it) {
		if (it === null)
			return #[].toSet
		val allOutsDuplicated = findDuplicates(caller)
		allOutsDuplicated.retainAll(outVars)
		return allOutsDuplicated
	}
}
