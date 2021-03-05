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

import fr.cea.nabla.ir.ir.JobCaller

import static extension fr.cea.nabla.ir.JobCallerExtensions.*
import static extension fr.cea.nabla.ir.JobExtensions.*
import static extension fr.cea.nabla.ir.generator.Utils.*
import fr.cea.nabla.ir.DefaultVarDependencies
import fr.cea.nabla.ir.ir.Variable
import java.util.Set
import fr.cea.nabla.ir.ir.Job

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
	static val extension DefaultVarDependencies = new DefaultVarDependencies
	
	def getDependencies(Job j)
	{
		val Set<Variable> ins = j.inVars.toSet
		val Set<Variable> outs = j.outVars.toSet
		val Set<Variable> inouts = ins.clone.toSet
		inouts.retainAll(outs)
		ins.removeAll(inouts)
		outs.removeAll(inouts)
		'''«getDependencies('in', ins)»«getDependencies('out', outs)»«getDependencies('inout', inouts)»'''
	}

	def getDependencies(String inout, Iterable<Variable> deps)
	{
		if (deps.length != 0)
			''' depend(«inout»: «FOR v : deps SEPARATOR ', '»«__getVariableName(v)»«ENDFOR»)'''
		else
			''''''
	}
	
	def __getVariableName(Variable it)
	{
		if (isOption)
			'''options.«name»'''
		else
			'''this->«name»'''
	}

	override getCallsHeader(JobCaller it) ''''''

	override getCallsContent(JobCaller it)
	'''
		«var jobsByAt = calls.groupBy[at]»
		«FOR at : jobsByAt.keySet.sort»
			«var atJobs = jobsByAt.get(at)»

			// @«at»
			«FOR j : atJobs»
				#pragma omp task«getDependencies(j)»
				«j.callName.replace('.', '->')»(); // New task «j.callName»@«j.at»
			«ENDFOR»
		«ENDFOR»
		
		// Wait for this loop tasks to be done...
		#pragma omp taskwait
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
