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
import java.util.List
import java.util.Map
import java.util.Set

import static fr.cea.nabla.ir.generator.cpp.CppGeneratorUtils.*
import static extension fr.cea.nabla.ir.generator.Utils.*

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

	/* Dependencies that are variables, the 'out' is manual */
	def abstract CharSequence generateTask(
		Job parentJob, Set<String> fp, Set<String> shared,
		Set<Variable> IN,  boolean IN_ALL,  CharSequence IN_FROM,
		Set<String> OUT,
		CharSequence inner
	)
	def abstract CharSequence generateTask(
		Job parentJob, Set<String> fp, Set<String> shared,
		Set<Variable> IN,  boolean IN_ALL,  CharSequence IN_FROM,
		Set<String> OUT,
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

	/* The user must specify the name of all variables and craft their name/index AND close the task with a '}' */
	def abstract CharSequence generateUnclosedTask(
		Job parentJob, Set<String> fp, Set<String> shared,
		Set<String> IN, Set<String> OUT,
		CharSequence inner
	)
	def abstract CharSequence generateUnclosedTask(
		Job parentJob, Set<String> fp, Set<String> shared,
		Set<String> IN, Set<String> OUT,
		int priority,
		CharSequence inner
	)
	
	/* Close an unclosed task */
	def abstract CharSequence closeUnclosedTask()
	def abstract CharSequence closeUnclosedTaskWithPriority()
}

class OpenMPTaskClangProvider extends OpenMPTaskProvider
{
	/* Internal helper */
	override CharSequence getSimpleTaskDirective(Set<String> fp, Set<String> shared)
	'''
		// clang-format off
		#pragma omp task default(none)«
		FOR v : fp     BEFORE ' firstprivate(' SEPARATOR ', ' AFTER ')'»«v»«ENDFOR»«
		FOR v : shared BEFORE ' shared('       SEPARATOR ', ' AFTER ')'»«v»«ENDFOR»'''

	/* Simple task without dependencies */
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

	/* Dependencies that are variables, the 'out' is manual */
	override CharSequence generateTask(
		Job parentJob, Set<String> fp, Set<String> shared,
		Set<Variable> IN,  boolean IN_ALL,  CharSequence IN_FROM,
		Set<String> OUT,
		CharSequence inner
	) '''
		«getSimpleTaskDirective(fp, shared)»«
		IF IN  !== null && IN.size  > 0»«IF IN_ALL»«getDependenciesAll(parentJob, 'in', IN)»«ELSE»«getDependencies(parentJob, 'in', IN, IN_FROM)»«ENDIF»«ENDIF»«
		IF OUT !== null && OUT.size > 0»«FOR v : OUT BEFORE ' \\\ndepend(out: ' SEPARATOR ', ' AFTER ')'»(«v»)«ENDFOR»«ENDIF»
		«simpleTaskEnd»
		{
			«inner»
		}
	'''

	override CharSequence generateTask(
		Job parentJob, Set<String> fp, Set<String> shared,
		Set<Variable> IN,  boolean IN_ALL,  CharSequence IN_FROM,
		Set<String> OUT,
		int priority,
		CharSequence inner
	) { generateTask(parentJob, fp, shared, IN, IN_ALL, IN_FROM, OUT, inner) }
	
	/* Dependencies that are variables */
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

	/* The user must specify the name of all variables and craft their name/index */
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

	/* The user must specify the name of all variables and craft their name/index AND close the task with a '}' */
	override CharSequence generateUnclosedTask(
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
	'''

	override CharSequence generateUnclosedTask(
		Job parentJob, Set<String> fp, Set<String> shared,
		Set<String> IN, Set<String> OUT,
		int priority,
		CharSequence inner
	) { generateTask(parentJob, fp, shared, IN, OUT, inner) }

	/* Close an unclosed task */
	override CharSequence closeUnclosedTask() '''}'''
	override CharSequence closeUnclosedTaskWithPriority() { closeUnclosedTask }
}

class OpenMPTaskMPCProvider extends OpenMPTaskClangProvider
{
	/* Internal helper */
	override CharSequence getSimpleTaskDirective(Set<String> fp, Set<String> shared)
	'''
		// clang-format off
		#pragma omp task default(none)«
		FOR v : fp.reject[ v | v.contains('::') ]    BEFORE ' firstprivate(' SEPARATOR ', ' AFTER ')'»«v.replaceAll('this->','')»«ENDFOR»«
		FOR v : shared.reject[ v | v.contains('::')] BEFORE ' shared('       SEPARATOR ', ' AFTER ')'»«v.replaceAll('this->','')»«ENDFOR»'''

	/* Simple task without dependencies */
	override CharSequence generateTask(Job parentJob, Set<String> fp, Set<String> shared, int priority, CharSequence inner)
	'''
	{
		mpc_omp_task("Task for «parentJob.name»@«parentJob.at»", «priority») 
		«generateTask(parentJob, fp, shared, inner)»
	}
	'''

	/* Dependencies that are variables, the 'out' is manual */
	override CharSequence generateTask(
		Job parentJob, Set<String> fp, Set<String> shared,
		Set<Variable> IN,  boolean IN_ALL,  CharSequence IN_FROM,
		Set<String> OUT,
		int priority,
		CharSequence inner
	) '''
	{
		mpc_omp_task("Task for «parentJob.name»@«parentJob.at»", «priority») 
		«generateTask(parentJob, fp, shared, IN, IN_ALL, IN_FROM, OUT, inner)»
	}
	'''
	
	/* Dependencies that are variables */
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

	/* The user must specify the name of all variables and craft their name/index */
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

	/* The user must specify the name of all variables and craft their name/index AND close the task with a '}' */
	override CharSequence generateUnclosedTask(
		Job parentJob, Set<String> fp, Set<String> shared,
		Set<String> IN, Set<String> OUT,
		int priority,
		CharSequence inner
	) '''
	{
		mpc_omp_task("Task for «parentJob.name»@«parentJob.at»", «priority») 
		«generateUnclosedTask(parentJob, fp, shared, IN, OUT, inner)»
	}
	'''

	/* Close an unclosed task */
	override CharSequence closeUnclosedTaskWithPriority() '''}}'''
}

class OpenMPTargetProvider
{
	enum BASIC_TYPE { FLOATING, INTEGER }
	enum TASK_MODE { NONE, GPU, CPU }

	static var current_task_mode = TASK_MODE::NONE

	static def TASK_MODE
	getCurrentTaskMode()
	{
		if (current_task_mode == TASK_MODE::NONE)
			throw new Exception("The current mode is 'NONE', this getter was called where it should not be called")
		return current_task_mode;
	}

	private def void
	flipTaskMode(TASK_MODE mode)
	{
		current_task_mode = mode;
	}
	
	private def void
	flipTaskModeFromJob()
	{
		current_task_mode = IsInsideGPUJob ? TASK_MODE::GPU : TASK_MODE::CPU;
	}

	new() { }

	def CharSequence
	allocate(String name, int len)
	'''
		#pragma omp target enter data map(alloc: «name»[0:«len»])
	'''

	def CharSequence
	free(String name, int len)
	'''
		#pragma omp target exit data map(delete: «name»[0:«len»])
	'''
	
	static def void
	select_target(TASK_MODE mode)
	{
		if (mode == TASK_MODE::NONE)
			throw new Exception("You can't set the tasking mode to 'NONE'")
		current_task_mode = mode
	}
	
	def CharSequence
	task(
		List<String> fp,
		List<String> IN, List<String> OUT,
		List<String> READ, List<String> WRITE, Map<String, String> RW_VAR_SIZES,
		CharSequence body
	) {
		flipTaskModeFromJob

		if (current_task_mode == TASK_MODE::CPU) {
			/* Task will run on the host CPU */
			flipTaskMode(TASK_MODE::NONE)
			return simple_task(fp, IN, OUT, READ, WRITE, RW_VAR_SIZES, body)
		}

		else if (current_task_mode == TASK_MODE::GPU) {
			/* Task will be offloaded to the GPU */
			flipTaskMode(TASK_MODE::NONE)
			return offload_task(fp, IN, OUT, READ, WRITE, RW_VAR_SIZES, body)
		}

		else {
			/* (╯°□°)╯ ┻━┻ */
			throw new Exception("Oupsi, you must specify a tasking mode")
		}
	}

	private def CharSequence
	simple_task(
		List<String> fp,
		List<String> IN, List<String> OUT,
		List<String> READ, List<String> WRITE, Map<String, String> RW_VAR_SIZES /* Unused */,
		CharSequence body
	) '''
		«val Set<String> SHARED = #[ READ.clone.toSet, WRITE.clone.toSet ].flatten.toSet»
		#pragma omp task «
		FOR v   : fp     BEFORE '\\\nfirstprivate(' SEPARATOR ', ' AFTER ')'»«v»«ENDFOR»«
		FOR in  : IN     BEFORE '\\\ndepend(in: '   SEPARATOR ', ' AFTER ')'»«in»«ENDFOR»«
		FOR out : OUT    BEFORE '\\\ndepend(out: '  SEPARATOR ', ' AFTER ')'»«out»«ENDFOR»«
		FOR s   : SHARED BEFORE '\\\nshared('       SEPARATOR ', ' AFTER ')'»«s»«ENDFOR»
		{
			«body»
		}
	'''

	private static def CharSequence
	getSizeIndicationForVariable(String name, Map<String, String> sizes)
	{
		val size = sizes.get(name)
		if (size === null)
			'''_glb'''
		else
			'''_ptr[0:«size»]'''
	}

	private def CharSequence
	offload_task(
		List<String> fp,
		List<String> IN, List<String> OUT,
		List<String> READ, List<String> WRITE, Map<String, String> RW_VAR_SIZES,
		CharSequence body
	) '''
		#pragma omp target«
		FOR v   : fp    BEFORE '\\\nfirstprivate(' SEPARATOR ', ' AFTER ')'»«v»«ENDFOR»«
		FOR in  : IN    BEFORE '\\\ndepend(in: '   SEPARATOR ', ' AFTER ')'»«in»«ENDFOR»«
		FOR out : OUT   BEFORE '\\\ndepend(out: '  SEPARATOR ', ' AFTER ')'»«out»«ENDFOR»«
		FOR r   : READ  BEFORE '\\\nmap(to: '      SEPARATOR ', ' AFTER ')'»«r»«getSizeIndicationForVariable(r, RW_VAR_SIZES)»«ENDFOR»«
		FOR w   : WRITE BEFORE '\\\nmap(to: '      SEPARATOR ', ' AFTER ')'»«w»«getSizeIndicationForVariable(w, RW_VAR_SIZES)»«ENDFOR»
		{
			«body»
		}
	'''

	def CharSequence
	loop_reduction(String result, CharSequence body)
	{
		flipTaskModeFromJob

		if (current_task_mode == TASK_MODE::GPU) '''
			#pragma omp teams distribute parallel for reduction(min: «result») map(tofrom: «result»)
			«body»
		'''
		
		else if (current_task_mode == TASK_MODE::CPU) '''
			#pragma omp parallel for reduction(min: «result»)
			«body»
		'''
		
		else
			throw new Exception("(╯°□°)╯ ┻━┻")
	}

	def CharSequence
	loop_for(CharSequence body)
	{
		flipTaskModeFromJob

		if (current_task_mode == TASK_MODE::GPU) '''
			#pragma omp teams distribute parallel for
			«body»
		'''

		else if (current_task_mode == TASK_MODE::CPU) '''
			#pragma omp parallel for
			«body»
		'''

		else
			throw new Exception("(╯°□°)╯ ┻━┻")
	}

	def CharSequence
	declare_gpu_jobs(List<String> funcs)
	'''
	#pragma omp declare target
	«FOR f : funcs»
		«f»;
	«ENDFOR»
	#pragma omp end declare target
	'''

	def CharSequence
	declare_gpu_functions(List<CharSequence> funcs)
	'''
	#pragma omp declare target
	«FOR f : funcs»
		«f»;
	«ENDFOR»
	#pragma omp end declare target
	'''

	def CharSequence
	implement_gpu_functions(List<CharSequence> funcs)
	'''
	#pragma omp declare target
	«FOR f : funcs»
		«f»
	«ENDFOR»
	#pragma omp end declare target
	 '''
}