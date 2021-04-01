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
		/* Will be used to compute unnecessary dependencies */
		var allouts = calls.map[outVars.filter[!isOption]].flatten.toSet
		var allins  = calls.map[inVars.filter[!isOption]].flatten.toSet
		allins.removeAll(allouts)
	'''
		// Launch all tasks for this loop...
		«IF allins.size > 0»
		// XXX: We will have problems with the following dependencies:
		// «FOR v : allins SEPARATOR ', '»«v.name»«ENDFOR»
		«ENDIF»
		
		«super.getCallsContent(it)»
		// Wait for this loop tasks to be done...
		#pragma omp taskwait

	'''
	}

	def getDAG(JobCaller it)
	'''
		puts("# DAG «name»");
		«FOR j : calls»
		puts("(\"R«j.name»@«j.at»\", [«
			FOR d : j.inVars SEPARATOR ', '»\"«d.name»\"«ENDFOR»], [«
			FOR d : j.outVars SEPARATOR ', '»\"«d.name»\"«ENDFOR»])");
		«ENDFOR»
	'''
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
