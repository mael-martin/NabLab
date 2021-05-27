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
import fr.cea.nabla.ir.ir.IrFactory
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
import java.util.Map
import java.util.Set
import org.eclipse.xtend.lib.annotations.Data
import org.jgrapht.graph.DefaultWeightedEdge
import org.jgrapht.graph.DirectedWeightedPseudograph

import static fr.cea.nabla.ir.transformers.IrTransformationUtils.*

import static extension fr.cea.nabla.ir.ArgOrVarExtensions.*
import static extension fr.cea.nabla.ir.transformers.ComputeCostTransformation.*
import fr.cea.nabla.ir.transformers.EnsuredDependency.TARGET_TAG

/* Job -> EnsuredDependency<Variable> := which one needs CPU or GPU
 * Variable -> EnsuredDependency<Job> := which one needs CPU or GPU */
class EnsuredDependency
{
	public Set<String> GPU = new HashSet<String>();
	public Set<String> CPU = new HashSet<String>();
	
	enum TARGET_TAG { CPU, GPU, BOTH } // CPU = (1 << 1), GPU = (1 << 2), BOTH = (CPU | GPU) <- Not possible in Xtext...
	
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
	
	static val SourceNodeLabel = 'SourceJob'
	static val SinkNodeLabel   = 'SinkJob'
	
	static val double lambda = 0.5

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

		/* Set MAX_TASK_NUMBER = ncpu * max(concurrentJobs + 1) */
		val max_concurrent_jobs = ir.eAllContents.filter(JobCaller).map[ jc |
			val jobsByAt = jc.calls.groupBy[ at ]
			jobsByAt.keySet.map[ at | jobsByAt.get(at).size ].max
		].max
		num_tasks = num_threads * (max_concurrent_jobs + 1);

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
			]
		]

		/* Try to offload parts of the computation to the GPU */
		ir.eAllContents.filter(JobCaller).forEach[ jc |
			val DAGs = jc.computePossibleTaggedDAG_TREESEARCH
			msg("Got " + DAGs.size + " DAGs to test")
			DAGs.forEach[ DAG |
				val taggedAccIn = computeEnsuredDependency(DAG, false)
				val double crit = rankGPUPartition(DAG, taggedAccIn, lambda)
				msg('Got crit rank for DAG: ' + crit.toString)
			]
		]

		/* Return OK */
		return true
	}
	
	static HashMap<String, HashSet<String>> AccumulatedInVariablesPerJobs = new HashMap();
	static HashMap<String, HashSet<Variable>> MinimalInVariablesPerJobs   = new HashMap();
	static HashMap<String, Integer> JobSynchroCoeffs                      = new HashMap();
	static HashMap<String, INDEX_TYPE> GlobalVariableIndexTypes           = new HashMap();
	static HashMap<String, Integer> JobPriorities                         = new HashMap();
	static HashMap<String, Integer> JobCostByName                         = new HashMap();
	
	static public final int num_threads = 4; // FIXME: Must be set by the user
	static int num_tasks;
	static def int getNum_tasks() { return num_tasks; }
	
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
	
	private def Map<String, EnsuredDependency.TARGET_TAG>
	initDAGTags(JobCaller it)
	{
		val DAG_TAGS = new HashMap<String, EnsuredDependency.TARGET_TAG>();

		/* Things that are CPU only */

		DAG_TAGS.put(SourceNodeLabel, EnsuredDependency.TARGET_TAG::CPU)
		DAG_TAGS.put(SinkNodeLabel,   EnsuredDependency.TARGET_TAG::CPU)

		calls.filter(TimeLoopJob).forEach[ it | DAG_TAGS.put(name, EnsuredDependency.TARGET_TAG::CPU)]
		calls.filter(ExecuteTimeLoopJob).forEach[ it | DAG_TAGS.put(name, EnsuredDependency.TARGET_TAG::CPU)]

		parallelJobs.forEach[ it |
			if (isJobGPUBlacklisted) {
				DAG_TAGS.put(name, EnsuredDependency.TARGET_TAG::CPU)
			} else {
				DAG_TAGS.put(name, EnsuredDependency.TARGET_TAG::GPU)
			}
		]

		return DAG_TAGS
	}
	
	/*********************************
	 * Rank a bipartition of the DAG *
	 *********************************/
	 
	private def double
	rankGPUPartition(Map<String, TARGET_TAG> DAG_VERTICIES, Map<String, EnsuredDependency> DAG_EDGES, double lambda)
	{
		var critere = 0.0
		val P_GPU   = DAG_VERTICIES.filter[ jname, jtag | jtag == TARGET_TAG::GPU ].keySet.toList
		val P_CPU   = DAG_VERTICIES.filter[ jname, jtag | jtag == TARGET_TAG::CPU ].keySet.toList

		/* C(lambda, P) = Sum_{i in P, j in Pred(i)}(e_{j,i} * x_i * x_j) /// (1)
		 *              + Sum_{i in P, j in Succ(i)}(e_{i,j} * x_i * x_j) /// (2)
		 *              - lambda Sum_{i in P}(u_i)                        /// (3)
		 */
		
		/****************************************\
		|  XXX: (╯°□°)╯__┻━┻ C'EST TOUT CASSÉ !  |
		\****************************************/

		/* (1) */
		val all1 = new HashSet<Double>().toList
		all1 += #[0.0]
		all1 += P_GPU.map[ i |
			val all2   = new HashSet<Double>().toList
			val i_deps = DAG_EDGES.getOrDefault(i, new EnsuredDependency).CPU.toList
			all2 += #[0.0]
			all2 += i_deps.map[ e_ji |
				switch GlobalVariableIndexTypes.getOrDefault(e_ji, INDEX_TYPE::NULL) {
					case INDEX_TYPE::CELLS: return 1.0
					case INDEX_TYPE::NODES: return 4.0
					case INDEX_TYPE::FACES: return 2.0
					case INDEX_TYPE::NULL:  return 0.0
				}
			].toList
			return all2.reduce[ p1, p2 | p1 + p2 ]
		].toList
		critere += all1.reduce[ p1, p2 | p1 + p2 ] * getGeometry_domain_size

		/* (2) */
		val all3 = new HashSet<Double>().toList
		all3 += #[0.0]
		all3 += P_CPU.map[ i |
			val all2 = new HashSet<Double>().toList
			all2 += #[0.0]
			all2 += DAG_EDGES.getOrDefault(i, new EnsuredDependency).GPU.toList.map[ e_ji |
				switch GlobalVariableIndexTypes.getOrDefault(e_ji, INDEX_TYPE::NULL) {
					case INDEX_TYPE::CELLS: return 1.0
					case INDEX_TYPE::NODES: return 4.0
					case INDEX_TYPE::FACES: return 2.0
					case INDEX_TYPE::NULL:  return 0.0
				}
			].toList
			return all2.reduce[ p1, p2 | p1 + p2 ]
		].toList
		critere += all3.reduce[ p1, p2 | p1 + p2 ] * getGeometry_domain_size

		/* (3) */
		val all4 = new HashSet<Double>().toList
		all4 += #[0.0]
		all4 += P_GPU.map[ i |
			JobCostByName.getOrDefault(i, 0).doubleValue
		]

		/* The sum */
		return critere - lambda * all4.reduce[ p1, p2 | p1 + p2 ]
	}
	
	/*************************************************************************
	 * Compute the AccumulatedIn but with variable localization, i.e. on CPU *
	 * or on GPU.                                                            *
	 *************************************************************************/

	private def Map<String, EnsuredDependency>
	computeEnsuredDependency(Map<String, EnsuredDependency.TARGET_TAG> DAG_TAG, boolean BOTH_is_CPU)
	{
		val JobEnsuredDependencies = new HashMap<String, EnsuredDependency>();
		val VariableTags           = new EnsuredDependency;
		
		DAG_TAG.forEach[ jname, TAG |
			val In = MinimalInVariablesPerJobs.get(jname)
			if (In !== null) {
				if      (TAG == EnsuredDependency.TARGET_TAG::CPU) { VariableTags.CPU.addAll(In.map[ name ]) }
				else if (TAG == EnsuredDependency.TARGET_TAG::GPU) { VariableTags.GPU.addAll(In.map[ name ]) }
				else if (BOTH_is_CPU)                              { VariableTags.CPU.addAll(In.map[ name ]) }
				else {
					VariableTags.GPU.addAll(In.map[ name ])
					VariableTags.CPU.addAll(In.map[ name ])
				}
			}
		]

		for (jname : DAG_TAG.keySet.toList) {
			val jtag  = DAG_TAG.get(jname)
			val AccIn = AccumulatedInVariablesPerJobs.get(jname)
			if (AccIn !== null) {
				val AccTagedIn = new EnsuredDependency
				AccTagedIn.CPU += AccIn.filter[ v | VariableTags.CPU.contains(v) ]
				AccTagedIn.GPU += AccIn.filter[ v | VariableTags.GPU.contains(v) ]

				/* If a variable is present on both CPU and GPU, it doesn't need to
				 * be moved to the job location. */
				if      (jtag == EnsuredDependency.TARGET_TAG::CPU) { AccTagedIn.GPU.removeAll(AccTagedIn.CPU) }
				else if (jtag == EnsuredDependency.TARGET_TAG::GPU) { AccTagedIn.CPU.removeAll(AccTagedIn.GPU) }
				else if (BOTH_is_CPU)                               { AccTagedIn.GPU.removeAll(AccTagedIn.CPU) }
				else { throw new Exception("A job should not be present on both CPU and GPU") }

				// msg("Job " + jname)
				// msgItem("CPU: " + AccTagedIn.CPU.size)
				// msgItem("GPU: " + AccTagedIn.GPU.size)
				JobEnsuredDependencies.put(jname, AccTagedIn)
			}
		}

		/* JobEnsuredDependencies := [
		 * ... ... ...
		 * { CPU: Needed variables on CPU, if this job is on GPU, need data move
		 * , GPU: Needed variables on GPU, if this job is on CPU, need data move
		 * }
		 * ... ... ...
		 * ] */
		return JobEnsuredDependencies
	}
	
	/*********************************************************************
	 * Generate a list of possible DAG with jobs assigned to CPU or GPU. *
	 * Will generate N different DAGs and will iter on them while the    *
	 * computed cost decrease.                                           *
	 *********************************************************************/
	
	private def List<Map<String, TARGET_TAG>>
	computePossibleTaggedDAG_TREESEARCH(JobCaller it)
	{
		calls.map[ job |
			val map = new HashMap<String, TARGET_TAG>()
			calls.filter[ isJobGPUBlacklisted ].forEach[ j | map.put(j.name, EnsuredDependency.TARGET_TAG::CPU)  ] // Forced
			calls.reject[ isJobGPUBlacklisted ].forEach[ j | map.put(j.name, EnsuredDependency.TARGET_TAG::BOTH) ] // Will vary
			map.put(job.name, EnsuredDependency::TARGET_TAG::GPU)
			return computePossibleTaggedDAG_TREESEARCH_REC(map)
		]
	}

	private def Map<String, TARGET_TAG>
	computePossibleTaggedDAG_TREESEARCH_REC(Map<String, TARGET_TAG> all_jobs)
	{
		val Map<String, TARGET_TAG> local = new HashMap<String, TARGET_TAG>()
		var boolean continue_rec_calls    = false
		var int rec_calls_counter         = 0

		/* While including a job into the GPU partition is a good thing,
		 * we continue. */
		do {
			var CPU_jobs = all_jobs.filter[ p1, p2 | p2 == TARGET_TAG::BOTH ].keySet.toList

			/* Can't find any new job to place on the GPU */
			if (CPU_jobs.size == 0) {
				continue_rec_calls = false
			}

			/* Try to find a job to place on GPU */
			else {
				var boolean continue_find_pivot = false
				do {
					// msg("(╯°□°)╯__┻━┻")
					val double current_rank   = rankGPUPartition(all_jobs, computeEnsuredDependency(all_jobs, true), lambda)
					val String pivot_job      = CPU_jobs.get(0)
					val TARGET_TAG old_target = all_jobs.get(pivot_job)
					CPU_jobs.remove(0)

					/* Flip the job */
					all_jobs.put(pivot_job, TARGET_TAG::GPU)
					val double new_rank = rankGPUPartition(all_jobs, computeEnsuredDependency(all_jobs, true), lambda)

					/* Found the pivot for that iteration, go to next one */
					if (new_rank <= current_rank) {
						continue_find_pivot = false
						continue_rec_calls  = true
					}

					/* Restore and continue to search pivot */
					else {
						all_jobs.put(pivot_job, old_target)
						continue_find_pivot = true
						continue_rec_calls  = true
					}

					/* We didn't found the pivot but we have no more jobs to
					 * flip around, we exit. */
					if (CPU_jobs.size == 0) {
						continue_find_pivot = false
						continue_rec_calls  = false
					}
				}
				while (continue_find_pivot)
			}

			rec_calls_counter += 1
		}
		while (continue_rec_calls);

		/* Remaining jobs will be CPU jobs */
		val remaining_jobs = all_jobs.filter[ p1, p2 | p2 == TARGET_TAG::BOTH ].keySet
		remaining_jobs.forEach[ jname | all_jobs.put(jname, TARGET_TAG::CPU) ]
		msg("Ended recursion with " + rec_calls_counter + " calls")
		return local
	}

	/*************************************************************************
	 * Generate a list of all possible DAG with jobs assigned to CPU or GPU. *
	 * Please note that this is a recursive function that will enumerate ALL *
	 * possible graphs, nothing intelligent done here...                     *
	 *************************************************************************/
	 
	private def Set<Map<String, EnsuredDependency.TARGET_TAG>>
	computePossibleTaggedDAG_ALL(JobCaller it)
	{
		val jobs = calls
		val map  = new HashMap<String, TARGET_TAG>()
		jobs.filter[ isJobGPUBlacklisted ].forEach[ j | map.put(j.name, EnsuredDependency.TARGET_TAG::CPU)  ] // Forced
		jobs.reject[ isJobGPUBlacklisted ].forEach[ j | map.put(j.name, EnsuredDependency.TARGET_TAG::BOTH) ] // Will vary
		msg("Base graph: " + map.keySet.reduce[ s1, s2 | s1 + ', ' + s2 ])
		return computePossibleTaggedDAG_ALL_REC(map)
	}

	private def Set<Map<String, EnsuredDependency.TARGET_TAG>>
	computePossibleTaggedDAG_ALL_REC(Map<String, TARGET_TAG> all_jobs)
	{
		val Map<String, TARGET_TAG> local_GPU = new HashMap<String, TARGET_TAG>()
		val Map<String, TARGET_TAG> local_CPU = new HashMap<String, TARGET_TAG>()
		var boolean one_already_assigned      = false
		var boolean remaining_jobs            = false

		for (jname : all_jobs.keySet) {
			val jtag = all_jobs.get(jname)
			switch jtag {
				/* Assign if needed */
				case TARGET_TAG::BOTH: {
					if (!one_already_assigned) {
						one_already_assigned = true
						local_GPU.put(jname, TARGET_TAG::GPU)
						local_CPU.put(jname, TARGET_TAG::CPU)
					} else {
						remaining_jobs = true
						local_CPU.put(jname, TARGET_TAG::BOTH)
						local_GPU.put(jname, TARGET_TAG::BOTH)
					}
				}

				/* Copy */
				default: {
					local_GPU.put(jname, jtag)
					local_CPU.put(jname, jtag)
				}
			}
		}

		/* All jobs have been assigned to a target (CPU or GPU) */
		if (!remaining_jobs) {
			msgItem("Got DAG: { CPU: " + local_CPU.filter[ p1, p2 |
				p2 == EnsuredDependency::TARGET_TAG::CPU
			].keySet.reduce[ p1, p2 | p1 + ", " + p2 ] +
			", GPU: " + local_CPU.filter[ p1, p2 |
				p2 == EnsuredDependency::TARGET_TAG::GPU
			].keySet.reduce[ p1, p2 | p1 + ", " + p2 ] + " }")

			msgItem("Got DAG: { CPU: " + local_GPU.filter[ p1, p2 |
				p2 == EnsuredDependency::TARGET_TAG::CPU
			].keySet.reduce[ p1, p2 | p1 + ", " + p2 ] +
			", GPU: " + local_GPU.filter[ p1, p2 |
				p2 == EnsuredDependency::TARGET_TAG::GPU
			].keySet.reduce[ p1, p2 | p1 + ", " + p2 ] + " }")

			return #[ local_GPU, local_CPU ].toSet
		}

		/* At least one job have not been assigned to the GPU or CPU */
		val Set<Map<String, TARGET_TAG>> ret = new HashSet<Map<String, TARGET_TAG>>();
		ret.addAll(computePossibleTaggedDAG_ALL_REC(local_GPU))
		ret.addAll(computePossibleTaggedDAG_ALL_REC(local_CPU))
		return ret;
	}

	/**************************************************************************
	 * Synchronization coefficients => like a barrier, take also into account *
	 * the 'sequenciality' of a job                                           *
	 **************************************************************************/

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
	
	/***********************************************************************
	 * Compute the DAG with the minimal IN and to cost to pass by a vertex *
	 * is its cost                                                         *
	 ***********************************************************************/
	 
	static private def DirectedWeightedPseudograph<Job, DefaultWeightedEdge>
	computeDAG(JobCaller it)
	{
	 	/* Create nodes */
	 	val jobs = parallelJobs
	 	val g    = new DirectedWeightedPseudograph<Job, DefaultWeightedEdge>(DefaultWeightedEdge)
	 	jobs.forEach[ x | g.addVertex(x) ]
	 	
	 	/* FROM -> TO */
	 	for (from : jobs) {
	 		for (to : jobs.reject[ j | j.name == from.name ]) {
	 			val FROM_OUTS = from.outVars
	 			val TO_MIN_IN = to.minimalInVars
	 			FROM_OUTS.retainAll(TO_MIN_IN)
	 			if (FROM_OUTS.size > 0) {
	 				g.addEdge(from, to)
	 				g.setEdgeWeight(from, to, from.jobCost)
	 			}
	 		}
	 	}
	 	
	 	/* Add source */
	 	val source = IrFactory::eINSTANCE.createInstructionJob => [ name = SourceNodeLabel ]
	 	g.addVertex(source)
	 	for (old_source : g.vertexSet.filter[ v | v !== source && g.incomingEdgesOf(v).empty ]) {
	 		g.addEdge(source, old_source)
	 		g.setEdgeWeight(source, old_source, 0)
	 	}
	 	
	 	/* Add sink */
	 	val sink = IrFactory::eINSTANCE.createInstructionJob => [ name = SinkNodeLabel ]
	 	g.addVertex(sink)
	 	for (old_sink : g.vertexSet.filter[ v | v !== sink && g.outgoingEdgesOf(v).empty ]) {
	 		g.addEdge(old_sink, sink)
	 		g.setEdgeWeight(old_sink, sink, 0)
	 	}

	 	return g
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