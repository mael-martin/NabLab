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

import fr.cea.nabla.ir.LoopLevelGetter
import fr.cea.nabla.ir.ir.Affectation
import fr.cea.nabla.ir.ir.ExecuteTimeLoopJob
import fr.cea.nabla.ir.ir.Instruction
import fr.cea.nabla.ir.ir.InstructionBlock
import fr.cea.nabla.ir.ir.InstructionJob
import fr.cea.nabla.ir.ir.IrModule
import fr.cea.nabla.ir.ir.IrRoot
import fr.cea.nabla.ir.ir.IterableInstruction
import fr.cea.nabla.ir.ir.Job
import fr.cea.nabla.ir.ir.ReductionInstruction
import fr.cea.nabla.ir.ir.TaskInstruction
import fr.cea.nabla.ir.ir.TimeLoopJob
import java.util.HashMap
import org.eclipse.xtext.EcoreUtil2

import static fr.cea.nabla.ir.LoopLevelGetter.*
import static fr.cea.nabla.ir.TaskExtensions.*

class IrTransformationTasks extends IrTransformationStep
{
	new()
	{
		super('IrTransformationTasks')
		TouchedJobs = new HashMap();
	}
	
	var HashMap<String, Integer> TouchedJobs;	/* Keep track of visited jobs */

	override boolean
	transform(IrRoot ir)
	{
		trace('    IR -> IR: ' + description)
		trace('    IR -> IR: ' + description + ':Sub:CreateSimpleTasks')
		replaceNonLoopJobs(ir)
		trace('    IR -> IR: ' + description + ':Sub:CreateSuperTasks')
		replaceSuperTasks(ir)
		trace('    IR -> IR: ' + description + ':Sub:CreateIterableInstructionTasks')
		replaceIterableInstructionJobs(ir)
		trace('    IR -> IR: ' + description + ':Verification')
		val ok = assertAllJobsTouched(ir)
		msg('status: ' + ok)
		return ok
	}
	
	/* Parse the IR and task-icize the jobs */

	private def void
	replaceNonLoopJobs(IrRoot ir)
	{
		var invalidated_list = false
		do {
			invalidated_list = false;
			for (j : ir.eAllContents.filter(Job).reject[ j | j instanceof ExecuteTimeLoopJob ].toList) {
				/* Because XTEND don't support BREAK and CONTINUE */
				if (!invalidated_list && j !== null) {
					invalidated_list = ___replaceNonLoopJobs(j)
				}
			}
		} while (invalidated_list);
		
		/* Verify that we did get ride of the TimeLoopJobs */
		val tlj_list = ir.eAllContents.filter(TimeLoopJob).reject[ j | j instanceof ExecuteTimeLoopJob].toList
		if (tlj_list !== null && tlj_list.size > 0) {
			throw new Exception(
				"There are still references to " + tlj_list.size + " TimeLoopJob objects: " +
				tlj_list.map[ name ].reduce[ s1, s2 | s1 + ', ' + s2 ]
			)
		}
	}

	private def void
	replaceIterableInstructionJobs(IrRoot ir)
	{
		for (j : ir.eAllContents.filter(Job).reject[ j |
			j instanceof ExecuteTimeLoopJob 				/* Won't be inside the // region */
		].filter[ j |
			(TouchedJobs.getOrDefault(j.name, 0) == 0) && 	/* Not already touched jobs (Super Tasks already done) */
			(j instanceof InstructionJob) &&				/* Get only instruction jobs here, because II are inside them */
			!(jobMustBeSuperTask(j as InstructionJob))		/* No super task here */
		].toList) {
			___replaceIterableInstructionJobs(j as InstructionJob)
		}
	}
	
	private def void
	replaceSuperTasks(IrRoot ir)
	{
		for (j : ir.eAllContents.filter(Job)
								.filter[ k | k instanceof InstructionJob ]
								.filter[ k |
									jobMustBeSuperTask(k as InstructionJob) && TouchedJobs.getOrDefault(k.name, 0) == 0
								].toList) {
			msg('Job ' + j.name + '@' + j.at + ' must be a SuperTask => glob it inside a task')
			(j as InstructionJob).instruction = createTaskInstruction(j as InstructionJob)
			TouchedJobs.put(j.name, 1)
		}
	}
	
	/* Ensure that all the jobs are treated */

	private def boolean
	assertAllJobsTouched(IrRoot ir)
	{
		ir.eAllContents.filter(Job)
			.filter[ j | ! (j instanceof ExecuteTimeLoopJob) ] // Don't need them
			.map[ j |
				val visited = TouchedJobs.getOrDefault(j.name, 0) == 1
				if (!visited)
					msg('Job ' + j.name + '@' + j.at + ' is not marked as touched')
				return visited
			]
			.reduce[ t1, t2 | t1 && t2 ] // All jobs are to be touched
	}
	
	/* Internal helper functions */
	
	private def void
	assertInstructionJobSliceable(InstructionJob j)
	{
		switch j.instruction {
			/* It's OK */
			IterableInstruction: {
				msg('Job ' + j.name + '@' + j.at + ' is a slice-able job')
			}

			/* IB must only be composed of loops/reductions */
			InstructionBlock: {
				var Instruction last_inst = null
				for (ib_content : (j.instruction as InstructionBlock).instructions) {
					val II_only_condition 			= (ib_content instanceof IterableInstruction)
					val RI_followedby_AFF_condition = (last_inst !== null
													&& last_inst instanceof ReductionInstruction
													&& ib_content instanceof Affectation)

					if (!(II_only_condition || RI_followedby_AFF_condition)) {
						val jobname = "Job " + j.name + "@" + j.at
						if (!RI_followedby_AFF_condition)
							throw new Exception(jobname + ": an Affectation is not the successor of a RI")
						if (!II_only_condition)
							throw new Exception(jobname + ": IB is not composed of only II")
					}
					
					// Register previous instruction
					last_inst = ib_content
				}
			}

			/* PANIK!!! */
			default: { throw new Exception("Job " + j.name + "@" + j.at + " is not slice-able! Incorrect II positions") }
		}
	}

	private def void
	replaceTimeLoopJob(TimeLoopJob to_replace, Job replacement)
	{
		msg('Replace TimeLoopJob by InstructionJob for ' + to_replace.name + '@' + to_replace.at)
		val mod    = EcoreUtil2.getContainerOfType(to_replace, IrModule)
		val ir     = EcoreUtil2.getContainerOfType(to_replace, IrRoot)
		val caller = to_replace.caller
		
		ir.jobs.remove(to_replace)
		caller.calls.remove(to_replace)
		mod.jobs.remove(to_replace)
		
		ir.jobs.add(replacement)
		caller.calls.add(replacement)
		mod.jobs.add(replacement)
	}
	
	private def boolean
	jobMustBeSuperTask(InstructionJob j)
	{
		val lget  = new LoopLevelGetter(j.instruction)
		val loops = lget.firstLevelLoop.toSet
		return ! isSameConnectivity(loops)
	}
	
	private def void
	___replaceIterableInstructionJobs(InstructionJob it)
	{
		assertInstructionJobSliceable
		TouchedJobs.put(name, 1)
		createSlicedJob(it)
	}
	
	private def boolean
	___replaceNonLoopJobs(Job j)
	{
		val noTasks =  j.eAllContents.filter(TaskInstruction).size == 0 						// Don't re-replace
		val loops   =  j.eAllContents.filter[ k | k instanceof IterableInstruction ].size > 0 	// Replace loops by tasks
					&& noTasks 																	// Already replaced?
					
		if (TouchedJobs.getOrDefault(j.name, 0) == 1)
			return false;	/* Still valid */

		/* The TimeLoopCopy special case */
		if (j instanceof TimeLoopJob) {
			msg('Job ' + j.name + '@' + j.at + ' is a time loop job, generate one task for it')
			replaceTimeLoopJob(j, createInstructionJob(j))
			TouchedJobs.put(j.name, 1)
			TouchedJobs.put(j.name + 'Task', 1)
			return true;	/* Invalidate */
		}

		/* Jobs without loops or reductions */
		else if (!loops && j instanceof InstructionJob) {
			msg('Job ' + j.name + '@' + j.at + ' is not a loop job, generate one task for it')
			(j as InstructionJob).instruction = createTaskInstruction(j as InstructionJob)
			TouchedJobs.put(j.name, 1)
			return false;	/* Still valid */
		}
		
		else if (! (j instanceof InstructionJob)) {
			/* Ignore the InstructionJob with loops/reductions for the moment, or PANIK!!! */
			throw new Exception("Unknown job type for " + j.name + "@" + j.at + ": " + j.toString)
		}
		
		return false;	/* Still valid */
	}
}
