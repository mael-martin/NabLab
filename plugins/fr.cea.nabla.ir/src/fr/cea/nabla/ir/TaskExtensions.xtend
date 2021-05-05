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

import fr.cea.nabla.ir.ir.Affectation
import fr.cea.nabla.ir.ir.ConnectivityCall
import fr.cea.nabla.ir.ir.ConnectivityType
import fr.cea.nabla.ir.ir.Exit
import fr.cea.nabla.ir.ir.If
import fr.cea.nabla.ir.ir.Instruction
import fr.cea.nabla.ir.ir.InstructionBlock
import fr.cea.nabla.ir.ir.InstructionJob
import fr.cea.nabla.ir.ir.Interval
import fr.cea.nabla.ir.ir.IrFactory
import fr.cea.nabla.ir.ir.ItemIdDefinition
import fr.cea.nabla.ir.ir.ItemIndexDefinition
import fr.cea.nabla.ir.ir.IterableInstruction
import fr.cea.nabla.ir.ir.Iterator
import fr.cea.nabla.ir.ir.Loop
import fr.cea.nabla.ir.ir.ReductionInstruction
import fr.cea.nabla.ir.ir.Return
import fr.cea.nabla.ir.ir.SetDefinition
import fr.cea.nabla.ir.ir.TaskDependencyVariable
import fr.cea.nabla.ir.ir.TaskInstruction
import fr.cea.nabla.ir.ir.TimeLoopCopy
import fr.cea.nabla.ir.ir.TimeLoopCopyInstruction
import fr.cea.nabla.ir.ir.TimeLoopJob
import fr.cea.nabla.ir.ir.Variable
import fr.cea.nabla.ir.ir.VariableDeclaration
import fr.cea.nabla.ir.ir.While
import java.util.HashMap
import java.util.HashSet
import java.util.List
import java.util.Map
import java.util.Set
import java.util.stream.IntStream
import org.eclipse.emf.common.util.EList

import static extension fr.cea.nabla.ir.transformers.JobMergeFromCost.*

class LoopLevelGetter
{
	static def boolean
	isSameConnectivity(Set<IterableInstruction> insts)
	{
		val itbs      = insts.map[ iterationBlock ]
		val iterators = itbs.filter(Iterator)
		val interval  = itbs.filter(Interval)
		
		/* Don't speak the same language => not the same thing we iterate over */
		if (iterators.size != 0 && interval.size != 0)
			return false

		if (iterators.size != 0) {
			/* Connectivities! */
			return iterators
				.map[ it | (container as ConnectivityCall).connectivity.name ] 	/* Grep the name of all the connectivities */
				.toSet															/* In a set, get ride of duplicates */
				.size == 1														/* If all the connectivities where equal, the size is 1 */
		}

		if (interval.size != 0) {
			/* 0 -> N
			 * false because we want to put them all into a SuperTask, that thing is not slice-able */
			return false
		}
		
		/* #interval == 0 && #iterators == 0, this is not slice-able */
		return false
	}
	
	new(Instruction i)
	{
		loops		 = new HashMap<Integer, Set<IterableInstruction>>();
		currentLevel = 0
		parseLoops(i)
	}
	
	var Map<Integer, Set<IterableInstruction>> loops /* First level loops */
	int currentLevel								 /* Current level of the parsed instruction */
	
	/* Get the First Level Loops */
	def Set<IterableInstruction>
	getFirstLevelLoop()
	{
		if (loops.size == 0)
			return #[].toSet

		val level = loops.keySet.min
		return loops.getOrDefault(level, new HashSet());
	}
	
	/* Parse and copy the first level loops */
	private def void
	parseLoops(Instruction it)
	{
		switch it {
			VariableDeclaration | Affectation | TaskInstruction | ItemIndexDefinition | ItemIdDefinition | SetDefinition | If | While | Return | Exit: {
				/* Pass it */
			}

			Loop | ReductionInstruction: {
				/* Register the loop */
				val set = loops.getOrDefault(currentLevel, new HashSet())
				set.add(it)
				loops.put(currentLevel, set)
			}

			IterableInstruction: {
				throw new Exception("Unsupported II, use only loops and reduction")
			}

			InstructionBlock: {
				/* Before the first loop levels, go find the loops */
				currentLevel += 1
				instructions.forEach[ parseLoops ]
				currentLevel -= 1
			}
		}
	}
}

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
		val falseIns = j.falseInVars
		IrFactory::eINSTANCE.createTaskInstruction => [
			inVars        += j.inVars.filter[ v | !falseIns.contains(v) ].map[ createTaskDependencyVariable ].flatten.toSet
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

	/* Create the TimeLoopCopyInstruction list if needed */
	static def List<TimeLoopCopyInstruction>
	createTimeLoopCopyInstruction(EList<TimeLoopCopy> tlcs)
	{
		tlcs.map[ createTimeLoopCopyInstruction ]
	}
	
	/* Slice a loop for a job.
	 * We now that the job is slice-able:
	 * - Only II
	 * - OK when an Affectation follows a RI
	 */
	static def
	createSlicedJob(InstructionJob j)
	{
		switch j.instruction {
			/* Multiple loops or a RI followed by an Affectation */
			InstructionBlock: {
				
			}
			
			/* Simple loop */
			IterableInstruction: {
				
			}
			
			/* PANIK!!! */
			default: {
				throw new Exception("Invalid input: no II only or RI followed by Affectation")
			}
		}
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