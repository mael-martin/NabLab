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
import fr.cea.nabla.ir.ir.ArgOrVarRef
import fr.cea.nabla.ir.ir.BaseType
import fr.cea.nabla.ir.ir.ConnectivityType
import fr.cea.nabla.ir.ir.ExecuteTimeLoopJob
import fr.cea.nabla.ir.ir.IrModule
import fr.cea.nabla.ir.ir.IrPackage
import fr.cea.nabla.ir.ir.IrRoot
import fr.cea.nabla.ir.ir.IrType
import fr.cea.nabla.ir.ir.Job
import fr.cea.nabla.ir.ir.JobCaller
import fr.cea.nabla.ir.ir.LinearAlgebraType
import fr.cea.nabla.ir.ir.Loop
import fr.cea.nabla.ir.ir.ReductionInstruction
import fr.cea.nabla.ir.ir.TimeLoopJob
import fr.cea.nabla.ir.ir.Variable
import java.util.HashMap
import java.util.HashSet
import java.util.List
import java.util.Set
import org.eclipse.xtend.lib.annotations.Data

import static fr.cea.nabla.ir.transformers.IrTransformationUtils.*

import static extension fr.cea.nabla.ir.ArgOrVarExtensions.*
import static extension fr.cea.nabla.ir.transformers.ComputeCostTransformation.*

enum TARGET_TAG { CPU, GPU, BOTH } // CPU = (1 << 1), GPU = (1 << 2), BOTH = (CPU | GPU) <- Not possible in Xtext...
	

/* Job -> EnsuredDependency<Variable> := which one needs CPU or GPU
 * Variable -> EnsuredDependency<Job> := which one needs CPU or GPU */
class EnsuredDependency
{
	public Set<String> GPU = new HashSet<String>();
	public Set<String> CPU = new HashSet<String>();
	
	static def EnsuredDependency
	newMerge(EnsuredDependency first, EnsuredDependency second)
	{
		val ret = new EnsuredDependency

		ret.GPU.addAll(first.GPU)
		ret.CPU.addAll(first.CPU)

		ret.GPU.addAll(second.GPU)
		ret.CPU.addAll(second.CPU)

		return ret
	}

	static def EnsuredDependency
	newMerge(Set<EnsuredDependency> first, Set<EnsuredDependency> second)
	{
		val ret = new EnsuredDependency

		ret.GPU.addAll(first.map[GPU].flatten)
		ret.CPU.addAll(first.map[CPU].flatten)

		ret.GPU.addAll(second.map[GPU].flatten)
		ret.CPU.addAll(second.map[CPU].flatten)

		return ret
	}
}

/* Needs the ComputeCostTransformation to be done before */
@Data
class JobMergeFromCost extends IrTransformationStep
{
	new() { super('JobDataflowComputations') }

	private enum INDEX_TYPE { NODES, CELLS, FACES, NULL } // Nabla first dimension index type
	private enum IMPL_TYPE  { BASE, ARRAY, CONNECTIVITY, LINEARALGEBRA, NULL } // Implementation type
	
	/* Coefficients for the granularity and the synchronization of a job => priority */
	static final double priority_coefficient_task_granularity     = 10.0   // Granularity is not really important here, and it is already the greatest number
	static final double priority_coefficient_task_synchronization = 30.0   // We mostly care about the synchronicity of the task
	static final double priority_coefficient_task_at              = 40.0   // The @ influence the scheduling

	override boolean
	transform(IrRoot ir) 
	{
		/* Minimal IN variables */
		trace('    IR -> IR: ' + description + ':ComputeMinimalInVars')
		MinimalInVariablesPerJobs.clear
		AccumulatedInVariablesPerJobs.clear
		ir.eAllContents.filter(JobCaller).forEach[
	    	computeMinimalInVariables
		]

		/* Global variable types */
		trace('    IR -> IR: ' + description + ':VariableReport')
		GlobalVariableIndexTypes.clear
		ir.modules.filter[ t | t !== null ].forEach[ registerGlobalVariable ]
		reportHashMap('VariableIndex', reverseHashMap(GlobalVariableIndexTypes), 'Indexes:', ': ')

		/* Synchronization coefficient and priorities */
		val int max_at = ir.eAllContents.filter(Job).map[ at ].max.intValue
		val HashMap<String, Integer> reusedOutVarsByJob = new HashMap();
		ir.eAllContents.filter(JobCaller).map[ parallelJobs ].toList.flatten.forEach[ it |
			computeSynchroCoeff
			computeTaskPriorities(max_at)
			reusedOutVarsByJob.put(name, outReusedVarsNumber)
		]

		reportHashMap('SynchroCoeffs', reverseHashMap(JobSynchroCoeffs),   'Synchro Coeff:',   ': ')
		reportHashMap('Priority',      reverseHashMap(JobPriorities),      'Priority',         ': ')

		ir.eAllContents.filter(JobCaller).forEach[
			calls.forEach[ j |
				JobCostByName.put(j.name, j.jobCost)
				JobPlacedOnGPU.put(j.name, !isJobGPUBlacklisted(j))
			]
		]
		
		trace('    IR -> IR: ' + description + ':ComputeVarMovements')
		VariableRegionLocality.clear
		computeVariableRegionLocality(ir)
		computeVariableWriteRegionLocality(ir)
		reportHashMap('VariableLocality',      reverseHashMap(VariableRegionLocality),      'Region Locality',       ': ')
		reportHashMap('VariableWriteLocality', reverseHashMap(VariableWriteRegionLocality), 'Region Write Locality', ': ')

		/* Return OK */
		return true
	}
	
	static HashMap<String, TARGET_TAG>		  VariableRegionLocality		= new HashMap();
	static HashMap<String, TARGET_TAG>        VariableWriteRegionLocality   = new HashMap();
	static HashMap<String, HashSet<String>>   AccumulatedInVariablesPerJobs = new HashMap();
	static HashMap<String, HashSet<Variable>> MinimalInVariablesPerJobs     = new HashMap();
	static HashMap<String, Integer>           JobSynchroCoeffs              = new HashMap();
	static HashMap<String, INDEX_TYPE>        GlobalVariableIndexTypes      = new HashMap();
	static HashMap<String, Integer>           JobPriorities                 = new HashMap();
	static HashMap<String, Integer>           JobCostByName                 = new HashMap();
	static HashMap<String, Boolean>           JobPlacedOnGPU                = new HashMap();
	
	static public final int num_threads = 12; // FIXME: Must be set by the user, here we generate for sandy
	static public final int num_tasks   = num_threads * 1; // FIXME: Must be set by the user
	
	/*********************************
	 * Get the locality of variables *
	 *********************************/
	
	static def TARGET_TAG
	getVariableLocality(String vname)
	{
		/* Will throw if the name is not found, should not if everything is fine */
		return VariableRegionLocality.get(vname)
	}
	
	static def TARGET_TAG
	getVariableWriteLocality(String vname)
	{
		return VariableWriteRegionLocality.get(vname)
	}
	
	private def void
	computeVariableWriteRegionLocality(IrRoot ir)
	{
		ir.eAllContents.filter(Job).forEach[ job |
			val jtag = job.GPUJob ? TARGET_TAG::GPU : TARGET_TAG::CPU
			val vars = job.outVars
			vars.forEach[ v |
				VariableWriteRegionLocality.put(v.name, jtag)
			]
		]
		ir.eAllContents.filter(Variable).filter[ const || constExpr || option ].reject[ v |
			VariableWriteRegionLocality.keySet.contains(v.name)
		].forEach[ v |
			VariableWriteRegionLocality.put(v.name, TARGET_TAG::BOTH)
		]
	}
	
	private def void
	computeVariableRegionLocality(IrRoot ir)
	{
		/* First pass */
		ir.eAllContents.filter(JobCaller).map[ parallelJobs ].toSet.flatten.forEach[ job |
			val jtag = job.isGPUJob ? TARGET_TAG::GPU : TARGET_TAG::CPU
			val vars = job.inVars
			vars.addAll(job.outVars)
			vars.forEach[ v |
				var region_locality = VariableRegionLocality.getOrDefault(v.name, jtag)
				if (region_locality != jtag) {
					region_locality = TARGET_TAG::BOTH
				}
				VariableRegionLocality.put(v.name, region_locality)
			]
		]

		/* Second pass: {var}plus1 and {var} should have the same region locality
		 * - Get all the vars
		 * - If we find a couple ({var}plus1, {var}), we merge the region tags:
		 *   tag({var}plus1) |= tag({var})
		 * XXX: Only supporte the 'plus1', should add a way to link the 'plus1',
		 *      'minus1', 'plus2', etc variables with the corresponding one. */
		val all_vars = ir.eAllContents
		.filter(JobCaller)
		.map[ parallelJobs ].toSet.flatten
		.map[
			val vars = inVars
			vars.addAll(outVars)
			return vars
		].flatten

		all_vars.forEach[ v |
			val var_region_base  = VariableRegionLocality.get(v.name)
			val var_region_plus1 = VariableRegionLocality.getOrDefault(v.name + 'plus1', null) // XXX
			if (var_region_plus1 !== null && var_region_base != var_region_plus1) {
				VariableRegionLocality.put(v.name + 'plus1', TARGET_TAG::BOTH)
			}
		]
	}

	/******************************************
	 * Get Jobs that must be run on CPU / GPU *
	 ******************************************/
	
	static def boolean
	isCPUJob(String name)
	{
		return ! isGPUJob(name)
	}

	static def boolean
	isCPUJob(Job it)
	{
		return isCPUJob(name)
	}

	static def boolean
	isGPUJob(String name)
	{
		return JobPlacedOnGPU.getOrDefault(name, false)
	}

	static def boolean
	isGPUJob(Job it)
	{
		return isGPUJob(name)
	}
	
	/***********
	 * helpers *
	 ***********/

	static private def boolean
	getTypeCanBePartitionized(IrType it)
	{
		switch it {
			case null:                   false
			BaseType case sizes.empty:   false
			BaseType | ConnectivityType: true
			LinearAlgebraType:           false
			default: throw new RuntimeException("Unexpected type: " + class.name)
		}
	}

	static private def IMPL_TYPE
	getImplTypeEnum(IrType it)
	{
		switch it {
			case null:                 IMPL_TYPE::NULL
			BaseType case sizes.empty: IMPL_TYPE::BASE
			BaseType:                  IMPL_TYPE::ARRAY
			ConnectivityType:          IMPL_TYPE::CONNECTIVITY
			LinearAlgebraType:         IMPL_TYPE::LINEARALGEBRA
			default:                   IMPL_TYPE::NULL
		}
	}

	private static def List<Job>
	getParallelJobs(JobCaller it)
	{
		if (it === null) return #[]
		return calls.reject[ j | j instanceof TimeLoopJob || j instanceof ExecuteTimeLoopJob ].toList
	}
	
	/**************************************************************************
	 * Synchronization coefficients => like a barrier, take also into account *
	 * the 'sequenciality' of a job                                           *
	 **************************************************************************/

	static def String
	getGlobalVariableSize(String name)
	{
		switch GlobalVariableIndexTypes.getOrDefault(name, INDEX_TYPE::NULL) {
			case INDEX_TYPE::CELLS: return 'nbCells'
			case INDEX_TYPE::NODES: return 'nbNodes'
			case INDEX_TYPE::FACES: return 'nbFaces'
			case INDEX_TYPE::NULL:  return null
		}
	}

	static def String
	getGlobalVariableSize(Variable it)
	{
		return name.globalVariableSize
	}

	static private def boolean
	isRangeVariable(Variable it)
	{
		return (!isOption)
		|| (GlobalVariableIndexTypes.getOrDefault(name, INDEX_TYPE::NULL) != INDEX_TYPE::NULL)
	}
	 
	static def
	getSynchroCoeff(Job it)
	{
		if (it === null) return 0
		return JobSynchroCoeffs.getOrDefault(name, 0)
	}
	 
	private def
	computeSynchroCoeff(Job it)
	{
		/* Job will need all the produced part of a range variable => massively synchronizing job */
		val jobNeedMoreSynchro =
			(( eAllContents.filter(Loop).filter[multithreadable].size
			+  eAllContents.filter(ReductionInstruction).size ) > 3 // Magic! Need to be stored at Nabla2IR transformation time
			|| eAllContents.filter(ReductionInstruction).size > 0)

		/* Sum the synchronization weight for in/out */
	 	val mapped = [ Set<Variable> list |
	 		list.map[ rangeVariable ].map[ isRange |
	 			(isRange && jobNeedMoreSynchro) ? num_tasks : 1
	 		].reduce[ p1, p2 | p1 + p2 ] ?: 0
	 	];

		/* The number of produced variables, each one of these variable will contribute to another task */
	 	JobSynchroCoeffs.put(name, mapped.apply(outVars))
	}
	
	/************************************
	 * In/Out/MinIn variables from Jobs *
	 ************************************/

	static def Set<Variable>
	getInVars(Job it)
	{
		return (it === null) ? #[].toSet
		: eAllContents.filter(ArgOrVarRef).filter[ x |
			x.eContainingFeature != IrPackage::eINSTANCE.affectation_Left
		].map[target].filter(Variable).filter[global].toSet
	}

	static def Set<Variable>
	getOutVars(Job it)
	{
		return (it === null) ? #[].toSet
		: eAllContents.filter(Affectation).map[left.target]
					  .filter(Variable)
					  .filter[global].toSet
	}
	
	static def int
	getOutReusedVarsNumber(Job it)
	{
		caller.parallelJobs.filter[ j | j.name != name ]
		      .map[ inVars.toList ].flatten
		      .filter[ v | outVars.contains(v) ]
		      .size
	}

	static def Set<Variable>
	getMinimalInVars(Job it)
	{
		if (it === null) return new HashSet();
		return MinimalInVariablesPerJobs.getOrDefault(name, new HashSet())
	}

	private def void
	computeMinimalInVariables(JobCaller jc)
	{
		/* Null check safety */
		if (jc === null)
			return;
			
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

	/*********************************
	 * Global variable => index type *
	 *********************************/

	static private def void
	registerGlobalVariable(IrModule it)
	{
		for (v : variables.filter[!option].filter[ t |
			t.type.typeCanBePartitionized &&
			t.type.implTypeEnum == IMPL_TYPE::CONNECTIVITY
		]) {
			val varName = v.name
			val type    = (v.type as ConnectivityType).connectivities.head.name
			switch type {
				case "nodes": GlobalVariableIndexTypes.put(varName, INDEX_TYPE::NODES)
				case "cells": GlobalVariableIndexTypes.put(varName, INDEX_TYPE::CELLS)
				case "faces": GlobalVariableIndexTypes.put(varName, INDEX_TYPE::FACES)
				case null: { }
				default: { }
			}
		}
	}
	
	/**********************
	 * Get a Job priority *
	 **********************/

	 static private def void
	 computeTaskPriorities(Job it, int max_at)
	 {
	 	/* ORDER_IN_DAG: Class of quality
	 	 * Other terms (what in formula): modulate inside the current class of quality
	 	 * 
	 	 * FORMULA:
	 	 * 		PRIORITY = SUM{what}(COEFF(what) * VALUE(what))
	 	 * 
	 	 * Take into account:
	 	 * - the level in the DAG
	 	 * - the synchronicity: the 'out' over 'in', the greater, the more
	 	 *   'few variables unlock a lots of variables'.
	 	 * - the granularity: do jobs with more work before others
	 	 */
	 	 
	    val max_syncro = caller.parallelJobs.map[ JobSynchroCoeffs.getOrDefault(name, 0) ].reduce[ p1, p2 | p1 + p2 ]

	 	val synchro     = priority_coefficient_task_synchronization * (JobSynchroCoeffs.getOrDefault(name, 0) / max_syncro);
	 	val granularity = priority_coefficient_task_granularity * jobContribution;
	 	val at_coeff    = priority_coefficient_task_at * ((max_at - at + 1) / max_at);
	 	val priority    = at_coeff + synchro + granularity;
	 	JobPriorities.put(name, priority.intValue)
	 }

	 static def int
	 getPriority(Job it)
	 {
	 	if (it === null) throw new Exception("Asking a priority for a 'null' job")
	 	return JobPriorities.getOrDefault(name, 1)
	 }
}