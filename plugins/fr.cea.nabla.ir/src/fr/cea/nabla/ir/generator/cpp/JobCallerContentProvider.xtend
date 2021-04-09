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
import org.eclipse.xtext.EcoreUtil2
import fr.cea.nabla.ir.ir.JobCaller
import fr.cea.nabla.ir.ir.ExecuteTimeLoopJob
import fr.cea.nabla.ir.ir.IrModule

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
		val allouts = calls.map[outVars].flatten
		val module  = EcoreUtil2.getContainerOfType(it, IrModule)
		if (module !== null)
			registerGlobalVariable(module)
		var boolean execTimeLoopPresent = false;
		'''
		// Launch all tasks for this loop...
		«IF allouts.toList.size != allouts.toSet.size»
		// XXX: There are duplicate out dependencies
		«ENDIF»
		
		«IF OMPTraces»
		fprintf(stderr, "### New Loop DAG: «name» %zu\n", ___DAG_loops);
		++___DAG_loops;
		«ENDIF»
		#pragma omp parallel
		{
		#pragma omp single nowait
		{
		«FOR j : calls»
			«IF j instanceof ExecuteTimeLoopJob»
			«IF !execTimeLoopPresent»
			// Wait before time loop: «execTimeLoopPresent = true»
			}}
			«ENDIF»
			«ENDIF»
			«j.callName.replace('.', '->')»(); // @«j.at»
		«ENDFOR»
		«IF ! execTimeLoopPresent»
		}}
		«ENDIF»

		'''
	}

	def getDAG(JobCaller it)
	'''
		puts("# DAG «name»");
		«FOR j : calls»
		puts("(\"T«j.name»@«j.at»\", [«
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
