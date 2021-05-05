/*******************************************************************************
 * Copyright (c) 2020 CEA
 * This program and the accompanying materials are made available under the 
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 * Contributors: see AUTHORS file
 *******************************************************************************/
package fr.cea.nabla.ir

import fr.cea.nabla.ir.ir.ConnectivityType
import fr.cea.nabla.ir.ir.InstructionJob
import fr.cea.nabla.ir.ir.IrFactory
import fr.cea.nabla.ir.ir.TaskDependencyVariable
import fr.cea.nabla.ir.ir.TaskInstruction
import fr.cea.nabla.ir.ir.TimeLoopCopy
import fr.cea.nabla.ir.ir.TimeLoopCopyInstruction
import fr.cea.nabla.ir.ir.TimeLoopJob
import fr.cea.nabla.ir.ir.Variable
import java.util.List
import java.util.stream.IntStream
import org.eclipse.emf.common.util.EList

import static extension fr.cea.nabla.ir.transformers.JobMergeFromCost.*

class TaskExtensions
{
	/* Helpers and setters for parameters */

	static int num_tasks = 1
	static def setNumTasks(int ntasks) { num_tasks = ntasks }

	static private def String
	getConnectivityName(Variable v)
	{
		if (v.type instanceof ConnectivityType) {
			return (v.type as ConnectivityType).connectivities.head.name
		}

		else { return "simple" }
	}
	
	/* Create a simple TaskInstruction from an InstructionJob */
	static def TaskInstruction
	createTaskInstruction(InstructionJob j)
	{
		IrFactory::eINSTANCE.createTaskInstruction => [
			inVars        += j.inVars.map[ createTaskDependencyVariable ].flatten.toSet
			outVars       += j.outVars.map[ createTaskDependencyVariable ].flatten.toSet
			minimalInVars += j.minimalInVars.map[ createTaskDependencyVariable ].flatten.toSet
			content        = j.instruction
		]
	}
	
	/* Create an InstructionJob from a TimeLoopJob */
	
	static def InstructionJob
	createInstructionJob(TimeLoopJob j)
	{
		IrFactory::eINSTANCE.createInstructionJob => [
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
		]
	}
	
	/* Create the TimeLoopCopyInstruction */
	
	static private def TimeLoopCopyInstruction
	createTimeLoopCopyInstruction(TimeLoopCopy tlc)
	{
		return IrFactory::eINSTANCE.createTimeLoopCopyInstruction => [
			content = IrFactory::eINSTANCE.createTimeLoopCopy => [
				destination = tlc.destination
				source      = tlc.source
			]
		]
	}

	static def List<TimeLoopCopyInstruction>
	createTimeLoopCopyInstruction(EList<TimeLoopCopy> tlcs)
	{
		tlcs.map[ createTimeLoopCopyInstruction ]
	}
	
	/* Create the TaskDependencyVariable */

	static def List<TaskDependencyVariable>
	createTaskDependencyVariable(Variable v)
	{
		val connName = v.connectivityName
		/* Simple, index is null */
		if (connName == "simple") {
			return #[IrFactory::eINSTANCE.createTaskDependencyVariable => [
				defaultValue 	 = v.defaultValue
				const 		 	 = v.const
				constExpr 	 	 = v.constExpr
				option 		 	 = v.option
				name 		 	 = v.name
				connectivityName = connName // Can be 'faces', 'nodes', 'cells'
				indexType 	 	 = connName // Same for now, this should be innerCells, leftNodes, etc
				index 		 	 = -1
			]].toList
		}

		return IntStream.range(0, num_tasks).iterator.map[ i | IrFactory::eINSTANCE.createTaskDependencyVariable => [
			defaultValue 	 = v.defaultValue
			const 		 	 = v.const
			constExpr 	 	 = v.constExpr
			option 		 	 = v.option
			name 		 	 = v.name
			connectivityName = connName // Can be 'faces', 'nodes', 'cells'
			indexType 	 	 = connName // Same for now, this should be innerCells, leftNodes, etc
			index 		 	 = i
		]].toList
	}
}