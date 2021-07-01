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

import fr.cea.nabla.ir.ir.ExecuteTimeLoopJob
import fr.cea.nabla.ir.ir.InstructionJob
import fr.cea.nabla.ir.ir.Job
import fr.cea.nabla.ir.ir.JobCaller
import fr.cea.nabla.ir.ir.TimeLoopCopy
import fr.cea.nabla.ir.ir.TimeLoopJob
import fr.cea.nabla.ir.ir.Variable
import fr.cea.nabla.ir.transformers.TARGET_TAG
import java.util.Set

import static extension fr.cea.nabla.ir.JobCallerExtensions.*
import static extension fr.cea.nabla.ir.JobExtensions.*
import static extension fr.cea.nabla.ir.generator.Utils.*
import static extension fr.cea.nabla.ir.generator.cpp.CppGeneratorUtils.*
import static extension fr.cea.nabla.ir.transformers.JobMergeFromCost.*
import fr.cea.nabla.ir.ir.ReductionInstruction

class JobCallerContentProvider
{
	def getCallsHeader(JobCaller it) ''''''

	def getCallsContent(JobCaller it)
	'''
		«FOR j : calls»
		«j.callName.replace('.', '->')»(); // @«j.at»
		«ENDFOR»

	'''
}

class OpenMPGPUJobCallerContentProvider extends JobCallerContentProvider
{
	val OpenMPTargetProvider target = new OpenMPTargetProvider()
	
	private def boolean
	hasTopLevelReductionOnGPU(Job it)
	{
		// All reduction that have INs on GPU will have their reduction run on
		// GPU, even if it's a CPU job.
		val hasNoInCPUVars = inVars.map[ name.variableWriteLocality ].filter[ t | t == TARGET_TAG::CPU ].isEmpty
		val hasReduction   = eAllContents.filter(ReductionInstruction).size > 0
		return hasNoInCPUVars && hasReduction
	}

	override getCallsContent(JobCaller it)
	'''
		«FOR j : calls»
			«j.callName.replace('.', '->')»(); // @«j.at»«IF j.GPUJob» [GPU]«ENDIF»
			«IF j.GPUJob /* Get back variables produced on GPU on the CPU if needed */»
				«val outGPU = j.outVars»
				«val inCPU  = calls
					.filter[ !hasTopLevelReductionOnGPU && !GPUJob ]
					.map[ inVars ].toSet.flatten
					.filter[ !option && !const && !constExpr ]»
				«val getBackToCPU = inCPU.filter[ v | outGPU.contains(v) ]»
				«FOR v : getBackToCPU»
					«target.updateFrom(v)»
				«ENDFOR»
			«ENDIF»
		«ENDFOR»

	'''
}

class OpenMpTaskV2JobCallerContentProvider extends JobCallerContentProvider
{
	var boolean OMPRegion = false

	override CharSequence
	getCallsHeader(JobCaller it)
	''''''
	
	private def CharSequence
	OMPRegionIndent()
	{
		if (OMPRegion)
			'''		'''
		else
			''''''
	}
	
	private def CharSequence
	OMPRegionClose()
	{
		if (OMPRegion) {
			OMPRegion = false
			return '''
				}
			}
			'''
		}
		
		else
			return ''''''
	}

	override CharSequence
	getCallsContent(JobCaller it)
	'''
		«FOR j : calls»
			«j.OMPRegionLimit»
			«OMPRegionIndent»«j.callName.replace('.', '->')»(); // @«j.at»
		«ENDFOR»
		«OMPRegionClose»
	'''

	/* Create or end a parallel region task single to create all the other tasks */
	private def CharSequence
	OMPRegionLimit(Job it)
	{
		switch it {
			case null: throw new Exception("Can't do anything with a null job")

			/* TimeLoopJob == ExecuteTimeLoopJob | TearDownTimeLoopJob | SetUpTimeLoopJob */
			TimeLoopCopy | TimeLoopJob: {
				OMPRegionClose
			}

			InstructionJob: {
				if (!OMPRegion) {
					OMPRegion = true
					'''
						#pragma omp parallel
						{
							#pragma omp single nowait
							{
					'''
				} else ''''''
			}

			default: {
				throw new Exception("Unknown Job type for " + name + "@" + at)
			}
		}
	}
}

class OpenMpTargetJobCallerContentProvider extends JobCallerContentProvider
{
	var boolean OMPRegion = false

	override CharSequence
	getCallsHeader(JobCaller it)
	''''''
	
	private def CharSequence
	OMPRegionIndent()
	{
		if (OMPRegion)
			'''		'''
		else
			''''''
	}
	
	private def CharSequence
	OMPRegionClose()
	{
		if (OMPRegion) {
			OMPRegion = false
			return '''
				}
			}
			'''
		}
		
		else
			return ''''''
	}

	override CharSequence
	getCallsContent(JobCaller it)
	'''
		«FOR j : calls»
			«j.OMPRegionLimit»
			«OMPRegionIndent»«j.callName.replace('.', '->')»(); // «IF JobContentProvider::task_mode && isGPUJob(j)»GPU «ENDIF»@«j.at»
		«ENDFOR»
		«OMPRegionClose»
	'''

	/* Create or end a parallel region task single to create all the other tasks */
	private def CharSequence
	OMPRegionLimit(Job it)
	{
		switch it {
			case null: throw new Exception("Can't do anything with a null job")

			/* TimeLoopJob == ExecuteTimeLoopJob | TearDownTimeLoopJob | SetUpTimeLoopJob */
			TimeLoopCopy | TimeLoopJob: {
				OMPRegionClose
			}

			InstructionJob: {
				if (!OMPRegion) {
					OMPRegion = true
					'''
						#pragma omp parallel num_threads(2) /* 2 to exec more than one job if possible,
															 * the rest of the CPUs will be populated by
															 * the second level parallel for chuncks */
						{
							#pragma omp single nowait
							{
					'''
				} else ''''''
			}

			default: {
				throw new Exception("Unknown Job type for " + name + "@" + at)
			}
		}
	}
}

class OpenMpTaskJobCallerContentProvider extends JobCallerContentProvider
{
	
	override CharSequence
	getCallsHeader(JobCaller it)
	''''''

	override CharSequence
	getCallsContent(JobCaller it)
	{
		var boolean execTimeLoopPresent = false;
		val Set<Variable> duplicates    = findDuplicates
		if (duplicates.size > 0) {
			val dup_str = duplicates.map[name].reduce[ p1, p2 | p1 + ', ' + p2 ]
			throw new Exception(duplicates.size + " job(s) generate the same variable, duplicated variable(s) are/is " + dup_str)
		}
		'''
		// Launch all tasks for this loop...
		«IF OMPTraces»
			++___DAG_loops;
			fprintf(stderr, "### NEW LOOP %ld\n", ___DAG_loops);
		«ENDIF»
		
		#pragma omp parallel
		{
		#pragma omp single nowait
		{
		«val jobsByAt = calls.groupBy[at]»
		«FOR at : jobsByAt.keySet.sort»
			«FOR j : jobsByAt.get(at)»
				«IF j instanceof ExecuteTimeLoopJob || j instanceof TimeLoopJob»
					«IF !execTimeLoopPresent»
						// Wait before time loop: «execTimeLoopPresent = true»
						}}
					«ENDIF»
				«ENDIF»
				«IF OMPTraces»
					fprintf(stderr, "(\"T«j.callName»_«j.at»\", [«
						FOR v : j.minimalInVars /* inoutVars == Ø */ SEPARATOR ', '»\"«v.name»\"«ENDFOR»], [«
						FOR v : j.outVars SEPARATOR ', '»\"«v.name»\"«ENDFOR»])\n");
				«ENDIF»
				«j.callName.replace('.', '->')»(); // @«j.at»«
					IF j.usedIndexType.length > 1» (do conversions)«ENDIF»«
					IF jobIsSuperTask(j)» (super task)«ENDIF»«IF isDuplicatedOutJob(j)» (race condition on out var)«ENDIF»
			«ENDFOR»
		«ENDFOR»
		«IF ! execTimeLoopPresent»
		}}
		«ENDIF»

		'''
	}
}

class KokkosTeamThreadJobCallerContentProvider extends JobCallerContentProvider
{
	override getCallsHeader(JobCaller it)
	{
		if (calls.exists[x | x.hasIterable])
		'''
		auto team_policy(Kokkos::TeamPolicy<>(
			Kokkos::hwloc::get_available_numa_count(),
			Kokkos::hwloc::get_available_cores_per_numa() * Kokkos::hwloc::get_available_threads_per_core()));

		'''
		else ''''''
	}

	override getCallsContent(JobCaller it)
	'''
		«var nbTimes = 0»
		«val jobsByAt = calls.groupBy[at]»
		«FOR at : jobsByAt.keySet.sort»
			«val atJobs = jobsByAt.get(at)»
			// @«at»
			«IF (atJobs.forall[!hasIterable])»
				«FOR j : atJobs.sortBy[name]»
				«j.callName.replace('.', '->')»();
				«ENDFOR»
			«ELSE»
			Kokkos::parallel_for(team_policy, KOKKOS_LAMBDA(member_type thread)
			{
				«FOR j : atJobs.sortBy[name]»
					«IF nbTimes++==0 && main»
					if (thread.league_rank() == 0)
						Kokkos::single(Kokkos::PerTeam(thread), KOKKOS_LAMBDA(){
							std::cout << "[" << __GREEN__ << "RUNTIME" << __RESET__ << "]   Using " << __BOLD__ << setw(3) << thread.league_size() << __RESET__ << " team(s) of "
								<< __BOLD__ << setw(3) << thread.team_size() << __RESET__<< " thread(s)" << std::endl;});
					«ENDIF»
					«IF !j.hasLoop»
					if (thread.league_rank() == 0)
						«IF !j.hasIterable /* Only simple instruction jobs */»
							Kokkos::single(Kokkos::PerTeam(thread), KOKKOS_LAMBDA(){«j.callName.replace('.', '->')»();});
						«ELSE /* Only for jobs containing ReductionInstruction */»
							«j.callName.replace('.', '->')»(thread);
						«ENDIF»
					«ELSE»
						«j.callName.replace('.', '->')»(thread);
					«ENDIF»
				«ENDFOR»
			});
			«ENDIF»

		«ENDFOR»
	'''
}
