/*******************************************************************************
 * Copyright (c) 2020 CEA
 * This program and the accompanying materials are made available under the 
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 * Contributors: see AUTHORS file
 *******************************************************************************/
package fr.cea.nabla.ir.transformers

import fr.cea.nabla.ir.JobDependencies
import fr.cea.nabla.ir.ir.Affectation
import fr.cea.nabla.ir.ir.ArgOrVar
import fr.cea.nabla.ir.ir.ArgOrVarRef
import fr.cea.nabla.ir.ir.ConnectivityType
import fr.cea.nabla.ir.ir.ExecuteTimeLoopJob
import fr.cea.nabla.ir.ir.IrPackage
import fr.cea.nabla.ir.ir.IrRoot
import fr.cea.nabla.ir.ir.Job
import fr.cea.nabla.ir.ir.JobCaller
import fr.cea.nabla.ir.ir.TimeLoopJob
import fr.cea.nabla.ir.ir.Variable
import java.util.HashMap
import java.util.HashSet
import java.util.Set
import org.eclipse.xtend.lib.annotations.Data

import static extension fr.cea.nabla.ir.ArgOrVarExtensions.*
import fr.cea.nabla.ir.ir.Loop
import fr.cea.nabla.ir.ir.ReductionInstruction

@Data
class JobMergeFromCost extends IrTransformationStep
{
	new()
	{
		super('JobDataflowComputations')
	}

	private enum INDEX_TYPE { NODES, CELLS, FACES, NULL }

	override transform(IrRoot ir) 
	{
		trace('    IR -> IR: ' + description + ':ComputeMinimalInVars')
		MinimalInVariablesPerJobs.clear
		AccumulatedInVariablesPerJobs.clear
		ir.eAllContents.filter(JobCaller).forEach[computeMinimalInVariables]

		/* Set MAX_TASK_NUMBER = ncpu * max(concurrentJobs + 1) */
		val max_concurrent_jobs = ir.eAllContents.filter(JobCaller).map[ jc |
			val jobsByAt = jc.calls.groupBy[at]
			jobsByAt.keySet.map[ at | jobsByAt.get(at).size ].max
		].max
		num_tasks = num_threads * (max_concurrent_jobs + 1);
		
		trace('    IR -> IR: ' + description + ':SynchroCoeffsReport')
		ir.eAllContents.filter(JobCaller).map[parallelJobs].toList.flatten.forEach[computeSynchroCoeff]
		val HashMap<Integer, Set<String>> reverseJobSynchroCoeffs = new HashMap();
		for (j : JobSynchroCoeffs.keySet) {
			val cost          = JobSynchroCoeffs.get(j)
			val jobSetForCost = reverseJobSynchroCoeffs.getOrDefault(cost, new HashSet())
			jobSetForCost.add(j)
			reverseJobSynchroCoeffs.put(cost, jobSetForCost)
		}
		for (cost : reverseJobSynchroCoeffs.keySet.sort) {
			trace('        - ' + reverseJobSynchroCoeffs.get(cost).reduce[ String p1, String p2 |
				p1 + ', ' + p2
			] + ' => ' + cost)
		}
		return true
	}
	
	static HashMap<String, HashSet<String>> AccumulatedInVariablesPerJobs = new HashMap();
	static HashMap<String, HashSet<Variable>> MinimalInVariablesPerJobs   = new HashMap();
	static HashMap<String, Integer> JobSynchroCoeffs                      = new HashMap();
	
	static public final int num_threads = 4; // FIXME: Must be set by the user
	static int num_tasks;
	static def int getNum_tasks() { return num_tasks; }
	
	/* helpers */
	private static def getParallelJobs(JobCaller it)
	{
		if (it === null) return #[]
		return calls.reject[ j | j instanceof TimeLoopJob || j instanceof ExecuteTimeLoopJob ].toList
	}
	
	/* Synchronization coefficients => like a barrier, take also into account
	 * the 'sequenciality' of a job */

	static private def isRangeVariable(Variable it)
	{
		if (isOption) return false
		switch (it as ArgOrVar).type {
			ConnectivityType: return true
			default: return false
		}
	}
	 
	 static def getSynchroCoeff(Job it)
	 {
	 	if (it === null) return 0
	 	return JobSynchroCoeffs.getOrDefault(name, 0)
	 }
	 
	 private def computeSynchroCoeff(Job it)
	 {
	 	if (it === null) return 0
	 	
	 	/* Job will need all the produced part of a range variable => massively synchronizing job */
		val jobNeedMoreSynchro = [Job it |
			(( eAllContents.filter(Loop).filter[multithreadable].size
			+  eAllContents.filter(ReductionInstruction).size ) > 3 // Magic! Need to be stored at Nabla2IR transformation time
			|| eAllContents.filter(ReductionInstruction).size > 0)
			? 1 : 0 ] // Return an Integer

		/* Sum the synchronization weight for in/out */
	 	val mapped = [ Set<Variable> list |
	 		list.map[ rangeVariable ].map[ t |
	 			t ? (num_tasks * jobNeedMoreSynchro.apply(it))
	 			  : 1
	 		].reduce[ p1, p2 | p1 + p2 ] ?: 0
	 	];

		/* Get all the variables and their weight as synchronization points */
	 	val synchroIN  = mapped.apply(minimalInVars)
	 	val synchroOUT = mapped.apply(outVars)

	 	JobSynchroCoeffs.put(name, synchroIN + synchroOUT)
	 }
	
	/* In/Out/MinIn variables from Jobs */

	static def Set<Variable> getInVars(Job it) {
		return (it === null) ? #[].toSet
		: eAllContents.filter(ArgOrVarRef).filter[ x |
			x.eContainingFeature != IrPackage::eINSTANCE.affectation_Left
		].map[target].filter(Variable).filter[global].toSet
	}

	static def Set<Variable> getOutVars(Job it) {
		return (it === null) ? #[].toSet
		: eAllContents.filter(Affectation).map[left.target]
					  .filter(Variable)
					  .filter[global].toSet
	}

	static def Set<Variable> getMinimalInVars(Job it) {
		if (it === null) return new HashSet();
		return MinimalInVariablesPerJobs.getOrDefault(name, new HashSet())
	}

	def computeMinimalInVariables(JobCaller jc) {
		/* Null check safety */
		if (jc === null)
			return null;
			
		/* Only the things that will be // */
		val jobs    = jc.parallelJobs
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
}