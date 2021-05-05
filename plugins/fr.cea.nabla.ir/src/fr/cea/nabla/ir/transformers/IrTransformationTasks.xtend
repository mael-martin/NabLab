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

import fr.cea.nabla.ir.ir.ExecuteTimeLoopJob
import fr.cea.nabla.ir.ir.InstructionJob
import fr.cea.nabla.ir.ir.IrFactory
import fr.cea.nabla.ir.ir.IrModule
import fr.cea.nabla.ir.ir.IrRoot
import fr.cea.nabla.ir.ir.IterableInstruction
import fr.cea.nabla.ir.ir.Job
import fr.cea.nabla.ir.ir.TaskInstruction
import fr.cea.nabla.ir.ir.TimeLoopJob
import java.util.HashMap
import org.eclipse.xtext.EcoreUtil2

import static extension fr.cea.nabla.ir.TaskExtensions.*
import static extension fr.cea.nabla.ir.transformers.JobMergeFromCost.*

class IrTransformationTasks extends IrTransformationStep
{
	new()
	{
		super('IrTransformationTasks')
	}
	
	var HashMap<String, Integer> TouchedJobs = new HashMap();

	override transform(IrRoot ir)
	{
		trace('    IR -> IR: ' + description)
		trace('    IR -> IR: ' + description + ':Sub:CreateSimpleTasks')
		replaceNonLoopJobs(ir)
		trace('    IR -> IR: ' + description + ':Sub:CreateSuperTasks -> Unimplemented')
		trace('    IR -> IR: ' + description + ':Sub:CreateIterableInstructionTasks')
		replaceIterableInstructionJobs(ir)
		return true
	}
	
	private def void replaceTimeLoopJob(TimeLoopJob to_replace, Job replacement)
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
	
	private def void replaceIterableInstructionJobs(IrRoot ir)
	{
	}
	
	private def boolean ___replaceNonLoopJobs(Job j)
	{
		val noTasks =  j.eAllContents.filter(TaskInstruction).size == 0 						// Don't re-replace
		val loops   =  j.eAllContents.filter[ k | k instanceof IterableInstruction ].size > 0 	// Replace loops by tasks
					&& noTasks 																	// Already replaced?
					
		if (TouchedJobs.getOrDefault(j.name, 0) == 1)
			return false;

		/* The TimeLoopCopy special case */
		if (j instanceof TimeLoopJob) {
			msg('Job ' + j.name + '@' + j.at + ' is a time loop job, generate one task for it')
			replaceTimeLoopJob(j, IrFactory::eINSTANCE.createInstructionJob => [
				caller      = j.caller
				name 		= j.name + 'Task'
				at   		= j.at
				onCycle     = j.onCycle
				instruction = IrFactory::eINSTANCE.createTaskInstruction => [
					j.copies.map[ source.createTaskDependencyVariable ].forEach[ v | inVars += v ]
					j.copies.map[ destination.createTaskDependencyVariable ].forEach[ v | outVars += v ]
					minimalInVars += inVars
					content        = IrFactory::eINSTANCE.createInstructionBlock => [
						instructions += createTimeLoopCopyInstruction(j.copies)
					]
				]
			])

			/* Invalidate */
			TouchedJobs.put(j.name, 1)
			TouchedJobs.put(j.name + 'Task', 1)
			return true;
		}

		/* Jobs without loops or reductions */
		else if (!loops && j instanceof InstructionJob) {
			msg('Job ' + j.name + '@' + j.at + ' is not a loop job, generate one task for it')
			(j as InstructionJob).instruction = IrFactory::eINSTANCE.createTaskInstruction => [
				inVars        += j.inVars.map[ createTaskDependencyVariable ].flatten.toSet
				outVars       += j.outVars.map[ createTaskDependencyVariable ].flatten.toSet
				minimalInVars += j.minimalInVars.map[ createTaskDependencyVariable ].flatten.toSet
				content        = (j as InstructionJob).instruction
			]

			/* Still valid */
			TouchedJobs.put(j.name, 1)
			return false;
		}
		
		else if (! (j instanceof InstructionJob)) {
			/* Ignore the InstructionJob with loops/reductions for the moment, or PANIK!!! */
			throw new Exception("Unknown job type for " + j.name + "@" + j.at + ": " + j.toString)
		}
		
		return false;
	}
	
	private def void replaceNonLoopJobs(IrRoot ir)
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
}
