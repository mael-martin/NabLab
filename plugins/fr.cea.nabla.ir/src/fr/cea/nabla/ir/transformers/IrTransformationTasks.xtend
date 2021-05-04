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
import fr.cea.nabla.ir.ir.IrRoot
import fr.cea.nabla.ir.ir.IterableInstruction
import fr.cea.nabla.ir.ir.Job
import fr.cea.nabla.ir.ir.TimeLoopJob
import fr.cea.nabla.ir.ir.IrFactory

import static extension fr.cea.nabla.ir.transformers.JobMergeFromCost.*
import fr.cea.nabla.ir.ir.InstructionJob

class IrTransformationTasks extends IrTransformationStep
{
	new()
	{
		super('IrTransformationTasks')
	}

	override transform(IrRoot ir)
	{
		trace('    IR -> IR: ' + description)
		trace('    IR -> IR: ' + description + ':Sub:CreateTasks')
		replaceNonLoopJobs(ir)

		return true
	}
	
	private def void replaceNonLoopJobs(IrRoot ir)
	{
		// Don't generate tasks for executetimeloop jobs
		val jobs = ir.eAllContents.filter(Job).reject[ j | j instanceof ExecuteTimeLoopJob ]
		jobs.forEach[ j |
			val loops = j.eAllContents.filter[ i | i instanceof IterableInstruction ].size > 0

			// The timeloop special case
			if (j instanceof TimeLoopJob) {
				msg('Job ' + j.name + '@' + j.at + ' is a time loop job, generate one task for it')
				val ins = j.inVars.map[ v | IrFactory::eINSTANCE.createTaskDependencyVariable => [
					name      = v.name
					indexType = v.name.variableIndexTypeAsString
					index     = "" // All the variable
				]]
				val minIns = j.minimalInVars.map[ v | IrFactory::eINSTANCE.createTaskDependencyVariable => [
					name      = v.name
					indexType = v.name.variableIndexTypeAsString
					index     = "" // All the variable
				]]
				val outs = j.outVars.map[ v | IrFactory::eINSTANCE.createTaskDependencyVariable => [
					name      = v.name
					indexType = v.name.variableIndexTypeAsString
					index     = "" // All the variable
				]]
				
				val instructionBlock = IrFactory::eINSTANCE.createInstructionBlock => [
					instructions += j.copies // FIXME: Add a TimeLoopCopyInstruction type in the IR
				]

				val jobTask = IrFactory::eINSTANCE.createTaskInstruction => [
					inVars        += ins
					outVars       += outs
					minimalInVars += minIns
					content       = instructionBlock
				]
				
				/* Replace! */
				/* TODO */
			}

			// Jobs without loops or reductions
			else if (!loops && j instanceof InstructionJob) {
				msg('Job ' + j.name + '@' + j.at + ' is not a loop job, generate one task for it')
				val ins = j.inVars.map[ v | IrFactory::eINSTANCE.createTaskDependencyVariable => [
					name      = v.name
					indexType = v.name.variableIndexTypeAsString
					index     = "" // All the variable
				]]
				val minIns = j.minimalInVars.map[ v | IrFactory::eINSTANCE.createTaskDependencyVariable => [
					name      = v.name
					indexType = v.name.variableIndexTypeAsString
					index     = "" // All the variable
				]]
				val outs = j.outVars.map[ v | IrFactory::eINSTANCE.createTaskDependencyVariable => [
					name      = v.name
					indexType = v.name.variableIndexTypeAsString
					index     = "" // All the variable
				]]

				val jobTask = IrFactory::eINSTANCE.createTaskInstruction => [
					inVars        += ins
					outVars       += outs
					minimalInVars += minIns
					content       = (j as InstructionJob).instruction
				]
				
				/* Replace! */
				(j as InstructionJob).instruction = jobTask
			}
			
			/* Panik!!! */
			else {
				throw new Exception("Unknown job type for " + j.name + "@" + j.at + ": " + j.toString)
			}
		]
	}
}
