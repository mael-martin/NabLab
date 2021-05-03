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

import fr.cea.nabla.ir.ir.Job
import fr.cea.nabla.ir.ir.Variable
import java.util.Set

import static fr.cea.nabla.ir.generator.cpp.CppGeneratorUtils.*

abstract class OpenMPTaskProvider
{
	/* Internal helper */
	protected def abstract CharSequence getSimpleTaskDirective(Set<String> fp, Set<String> shared)
	protected def CharSequence getSimpleTaskEnd()
	'''
		// clang-format on
	'''
	
	/* Simple task without dependencies */
	def abstract CharSequence generateTask(Job parentJob, Set<String> fp, Set<String> shared, CharSequence inner)
	def abstract CharSequence generateTask(Job parentJob, Set<String> fp, Set<String> shared, int priority, CharSequence inner)

	/* Dependencies that are variables */
	def abstract CharSequence generateTask(
		Job parentJob, Set<String> fp, Set<String> shared,
		Set<Variable> IN,  boolean IN_ALL,  CharSequence IN_FROM,
		Set<Variable> OUT, boolean OUT_ALL, CharSequence OUT_TO,
		CharSequence inner
	)
	def abstract CharSequence generateTask(
		Job parentJob, Set<String> fp, Set<String> shared,
		Set<Variable> IN,  boolean IN_ALL,  CharSequence IN_FROM,
		Set<Variable> OUT, boolean OUT_ALL, CharSequence OUT_TO,
		int priority,
		CharSequence inner
	)
	
	/* The user must specify the name of all variables and craft their name/index */
	def abstract CharSequence generateTask(
		Job parentJob, Set<String> fp, Set<String> shared,
		Set<String> IN, Set<String> OUT,
		CharSequence inner
	)
	def abstract CharSequence generateTask(
		Job parentJob, Set<String> fp, Set<String> shared,
		Set<String> IN, Set<String> OUT,
		int priority,
		CharSequence inner
	)
}

class OpenMPTaskClangProvider extends OpenMPTaskProvider
{
	override CharSequence getSimpleTaskDirective(Set<String> fp, Set<String> shared)
	'''
		// clang-format off
		#pragma omp task default(none)«
		FOR v : fp     BEFORE ' firstprivate(' SEPARATOR ', ' AFTER ')'»«v»«ENDFOR»«
		FOR v : shared BEFORE ' shared('       SEPARATOR ', ' AFTER ')'»«v»«ENDFOR»'''

	override generateTask(Job parentJob, Set<String> fp, Set<String> shared, CharSequence inner)
	'''
		«getSimpleTaskDirective(fp, shared)»
		«simpleTaskEnd»
		{
			«inner»
		}
	'''

	override CharSequence generateTask(Job parentJob, Set<String> fp, Set<String> shared, int priority, CharSequence inner)
	{ generateTask(parentJob, fp, shared, inner) }
	
	override CharSequence generateTask(
		Job parentJob, Set<String> fp, Set<String> shared,
		Set<Variable> IN,  boolean IN_ALL,  CharSequence IN_FROM,
		Set<Variable> OUT, boolean OUT_ALL, CharSequence OUT_TO,
		CharSequence inner
	) '''
		«getSimpleTaskDirective(fp, shared)»«
		IF IN  !== null && IN.size  > 0»«IF IN_ALL »«getDependenciesAll(parentJob, 'in' , IN )»«ELSE»«getDependencies(parentJob, 'in',  IN,  IN_FROM)»«ENDIF»«ENDIF»«
		IF OUT !== null && OUT.size > 0»«IF OUT_ALL»«getDependenciesAll(parentJob, 'out', OUT)»«ELSE»«getDependencies(parentJob, 'out', OUT, OUT_TO )»«ENDIF»«ENDIF»
		«simpleTaskEnd»
		{
			«inner»
		}
	'''

	override CharSequence generateTask(
		Job parentJob, Set<String> fp, Set<String> shared,
		Set<Variable> IN,  boolean IN_ALL,  CharSequence IN_FROM,
		Set<Variable> OUT, boolean OUT_ALL, CharSequence OUT_TO,
		int priority,
		CharSequence inner
	) { generateTask(parentJob, fp, shared, IN, IN_ALL, IN_FROM, OUT, OUT_ALL, OUT_TO, inner) }

	override CharSequence generateTask(
		Job parentJob, Set<String> fp, Set<String> shared,
		Set<String> IN, Set<String> OUT,
		CharSequence inner
	) '''
		«getSimpleTaskDirective(fp, shared)»«
		IF IN  !== null && IN.size  > 0»«FOR v : IN  BEFORE ' \\\ndepend(in: '  SEPARATOR ', ' AFTER ')'»(«v»)«ENDFOR»«ENDIF»«
		IF OUT !== null && OUT.size > 0»«FOR v : OUT BEFORE ' \\\ndepend(out: ' SEPARATOR ', ' AFTER ')'»(«v»)«ENDFOR»«ENDIF»
		«simpleTaskEnd»
		{
			«inner»
		}
	'''

	override CharSequence generateTask(
		Job parentJob, Set<String> fp, Set<String> shared,
		Set<String> IN, Set<String> OUT,
		int priority,
		CharSequence inner
	) { generateTask(parentJob, fp, shared, IN, OUT, inner) }
}

class OpenMPTaskMPCProvider extends OpenMPTaskClangProvider
{
	override CharSequence generateTask(Job parentJob, Set<String> fp, Set<String> shared, int priority, CharSequence inner)
	'''
	{
		mpc_omp_task("Task for «parentJob.name»@«parentJob.at»", «priority») 
		«generateTask(parentJob, fp, shared, inner)»
	}
	'''
	
	override CharSequence generateTask(
		Job parentJob, Set<String> fp, Set<String> shared,
		Set<Variable> IN,  boolean IN_ALL,  CharSequence IN_FROM,
		Set<Variable> OUT, boolean OUT_ALL, CharSequence OUT_TO,
		int priority,
		CharSequence inner
	) '''
	{
		mpc_omp_task("Task for «parentJob.name»@«parentJob.at»", «priority») 
		«generateTask(parentJob, fp, shared, IN, IN_ALL, IN_FROM, OUT, OUT_ALL, OUT_TO, inner)»
	}
	'''

	override CharSequence generateTask(
		Job parentJob, Set<String> fp, Set<String> shared,
		Set<String> IN, Set<String> OUT,
		int priority,
		CharSequence inner
	) '''
	{
		mpc_omp_task("Task for «parentJob.name»@«parentJob.at»", «priority») 
		«generateTask(parentJob, fp, shared, IN, OUT, inner)»
	}
	'''
}