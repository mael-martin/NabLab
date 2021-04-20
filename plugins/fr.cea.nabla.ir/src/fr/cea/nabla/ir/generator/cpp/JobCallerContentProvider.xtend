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

import static extension fr.cea.nabla.ir.JobCallerExtensions.*
import static extension fr.cea.nabla.ir.JobExtensions.*
import static extension fr.cea.nabla.ir.generator.Utils.*
import static extension fr.cea.nabla.ir.generator.cpp.CppGeneratorUtils.*
import fr.cea.nabla.ir.ir.JobCaller
import fr.cea.nabla.ir.ir.ExecuteTimeLoopJob
import fr.cea.nabla.ir.ir.TimeLoopJob

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

class OpenMpTaskJobCallerContentProvider extends JobCallerContentProvider
{
	
	override getCallsHeader(JobCaller it) ''''''

	override getCallsContent(JobCaller it)
	{
		var boolean execTimeLoopPresent = false;
		val duplicatedOuts = findDuplicates
		'''
		// Launch all tasks for this loop...
		«IF duplicatedOuts.size > 0»
			// XXX: There are duplicate out dependencies: «FOR v : duplicatedOuts SEPARATOR ', '»«v.name»«ENDFOR»
		«ENDIF»
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
			«val atJobs = jobsByAt.get(at)»
			«IF atJobs.filter[usedIndexType.length > 1].length > 0»
				/* A job will do an index conversion, need to wait as it is not supported */
				#pragma omp taskwait
			«ENDIF»
			«FOR j : atJobs»
				«IF j instanceof ExecuteTimeLoopJob || j instanceof TimeLoopJob»
					«IF !execTimeLoopPresent»
						// Wait before time loop: «execTimeLoopPresent = true»
						}}
					«ENDIF»
				«ENDIF»
				«IF OMPTraces»
					fprintf(stderr, "(\"T«j.callName»_«j.at»\", [«
						FOR v : j.inVars  SEPARATOR ', '»\"«v.name»\"«ENDFOR»], [«
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
