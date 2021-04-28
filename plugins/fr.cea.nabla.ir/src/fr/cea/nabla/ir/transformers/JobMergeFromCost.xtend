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

import java.util.HashMap
import java.util.HashSet

import org.eclipse.xtend.lib.annotations.Data

import static extension fr.cea.nabla.ir.ArgOrVarExtensions.*
import fr.cea.nabla.ir.JobDependencies
import fr.cea.nabla.ir.ir.IrRoot
import fr.cea.nabla.ir.ir.Variable
import fr.cea.nabla.ir.ir.JobCaller
import fr.cea.nabla.ir.ir.Job
import fr.cea.nabla.ir.ir.TimeLoopJob
import fr.cea.nabla.ir.ir.ArgOrVarRef
import fr.cea.nabla.ir.ir.Affectation
import fr.cea.nabla.ir.ir.IrPackage
import fr.cea.nabla.ir.ir.ExecuteTimeLoopJob

@Data
class JobMergeFromCost extends IrTransformationStep
{
	new()
	{
		super('JobDataflowComputations')
	}

	override transform(IrRoot ir) 
	{
		trace('    IR -> IR: ' + description + ':ComputeMinimalInVars')
		MinimalInVariablesPerJobs.clear
		AccumulatedInVariablesPerJobs.clear
		ir.eAllContents.filter(JobCaller).forEach[computeMinimalInVariables]
		return true
	}
	
	static HashMap<String, HashSet<String>> AccumulatedInVariablesPerJobs = new HashMap();
	static HashMap<String, HashSet<Variable>> MinimalInVariablesPerJobs   = new HashMap();

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

	static def getMinimalInVars(Job it) {
		if (it === null)
			return new HashSet();
		return MinimalInVariablesPerJobs.getOrDefault(name, new HashSet())
	}

	def computeMinimalInVariables(JobCaller jc) {
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
}