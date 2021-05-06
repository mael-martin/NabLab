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
import fr.cea.nabla.ir.ir.Job
import fr.cea.nabla.ir.ir.Loop
import fr.cea.nabla.ir.ir.LoopSliceInstruction
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
import org.eclipse.xtext.EcoreUtil2

import static extension fr.cea.nabla.ir.transformers.JobMergeFromCost.*
import fr.cea.nabla.ir.ir.CArray

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

	/* Get the connectivity of a variable */
	static private def String
	getConnectivityName(Variable v)
	{
		if (v.type instanceof ConnectivityType) {
			return (v.type as ConnectivityType).connectivities.head.name
		}

		else { return "simple" }
	}
	
	/* Create a simple TaskInstruction from an InstructionJob, this is used to
	 * wrap the content of a job inside its own task */
	static def TaskInstruction
	createTaskInstruction(InstructionJob j)
	{
		val falseIns = j.falseInVars
		IrFactory::eINSTANCE.createTaskInstruction => [
			/* All slices are needed */
			inVars        += j.inVars.filter[ v | !falseIns.contains(v) ].map[ createTaskDependencyVariable ].flatten.toSet
			outVars       += j.outVars.map[ createTaskDependencyVariable ].flatten.toSet
			minimalInVars += j.minimalInVars.map[ createTaskDependencyVariable ].flatten.toSet
			/* Copy the inner content of the job */
			content = j.instruction
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
				/* Get all slices of data that is used/modified */
				j.copies.map[ source.createTaskDependencyVariable ].forEach[ v | inVars += v ]
				j.copies.map[ destination.createTaskDependencyVariable ].forEach[ v | outVars += v ]
				minimalInVars += inVars
				/* Copy the content that is wrapped inside the task */
				content = IrFactory::eINSTANCE.createInstructionBlock => [
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
	
	/* Create a slice of a Loop */
	private static def List<LoopSliceInstruction>
	createSliceLoop(Loop l)
	{
		val parentJob = EcoreUtil2.getContainerOfType(l, Job)
		val falseIns  = parentJob.falseInVars
		return IntStream.range(0, num_tasks).iterator.map[ i |
			IrFactory::eINSTANCE.createLoopSliceInstruction => [
				/* A slice will be executed in its own task */
				task = IrFactory::eINSTANCE.createTaskInstruction => [
					/* Keep only the slice of data that is modified/used by this loop slice */
					inVars        += parentJob.inVars.filter[ v | !falseIns.contains(v) ].map[ createTaskDependencyVariable ].flatten.filter[ v | v.index == i ].toSet
					outVars       += parentJob.outVars.map[ createTaskDependencyVariable ].flatten.filter[ v | v.index == i ].toSet
					minimalInVars += parentJob.minimalInVars.map[ createTaskDependencyVariable ].flatten.filter[ v | v.index == i ].toSet

					/* the inner content of the loop is the same for all slices */
					content = l.body
				]
				/* Keep the iteration block as the thing that should be if no slice was generated */
				iterationBlock = l.iterationBlock
			]
		].toList
	}
	
	/* Create a slice of a Reduction, we generate the declaration for the
	 * partial reduction data holder */
	private static def List<Instruction>
	createSlicedReduction(ReductionInstruction RI)
	{
		val List<Instruction> ret = #[].toList
		val storage               = createPartialReductionStorage(RI)
		val parentJob             = EcoreUtil2.getContainerOfType(RI, Job)
		val falseIns              = parentJob.falseInVars
		ret += IrFactory::eINSTANCE.createVariableDeclaration => [ variable = storage ]
		
		return IntStream.range(0, num_tasks).iterator.map[ i |
			IrFactory::eINSTANCE.createLoopSliceInstruction => [
				iterationBlock = RI.iterationBlock
				task           = IrFactory::eINSTANCE.createTaskInstruction => [
					inVars        += parentJob.inVars.filter[ v | !falseIns.contains(v) ].map[ createTaskDependencyVariable ].flatten.filter[ v | v.index == i ].toSet
					outVars       += parentJob.outVars.map[ createTaskDependencyVariable ].flatten.filter[ v | v.index == i ].toSet
					minimalInVars += parentJob.minimalInVars.map[ createTaskDependencyVariable ].flatten.filter[ v | v.index == i ].toSet
					content        = createSlicedReductionCoreAffectation(RI)
				]
			]
		].toList
	}
	
	/* Create the affectation for the core of the reduction */
	private static def Instruction
	createSlicedReductionCoreAffectation(ReductionInstruction RI)
	{
		throw new Exception("Not implemented")
	}
	
	/* Create the temporary storage, it's static for now */
	private static def Variable
	createPartialReductionStorage(ReductionInstruction RI)
	{
		/* Assert: reduction on simple types */
		if (RI.result.type instanceof CArray) {
			throw new Exception("Reductions on CArrays are not supported: it will create composed CArrays")
		}
		
		/* The storage */
		return IrFactory::eINSTANCE.createVariable => [
			name = RI.result.name + "_tab"
			type = IrFactory::eINSTANCE.createCArray => [
				primitive = RI.result.type
				size      = num_tasks
				static    = true
			]
			defaultValue = RI.result.defaultValue
			const        = false
			constExpr    = false
			option       = false
		]
	}
	
	/* Generate the final reduction, where all the partial reduction results are
	 * reduced and stored in the final variable */
	private static def Instruction
	createSlicedReductionFinalReduction(ReductionInstruction RI, String finalResult)
	{
		throw new Exception("Not implemented")
	}
	
	/* Create a slice of a IB:
	 * - Only Loop
	 * - OK when Affectation follows a RI
	 */
	 private static def InstructionBlock
	 createSlicedInstructionBlock(InstructionBlock IB)
	 {
	 	var Instruction last_instruction = null
	 	val List<Instruction> IS         = #[].toList
	 	
	 	/* Slice all the instructions */
	 	for (I : IB.instructions) {
	 		switch I {
	 			/* Slice the loops */
	 			Loop: {
	 				IS += createSliceLoop(I as Loop)
	 			}

				/* Slice the reduction, we expect that the next instruction is an affectation */
	 			ReductionInstruction: {
	 				IS += createSlicedReduction(I as ReductionInstruction)
	 			}
	 			
	 			/* Affectation: only if last slice (generate one final reduction), check if last instruction was a reduction! */
	 			Affectation: {
	 				if ((last_instruction !== null) && (last_instruction instanceof ReductionInstruction)) {
	 					IS += createSlicedReductionFinalReduction(last_instruction as ReductionInstruction, (I as Affectation).left.target.name)
	 				}
	 			}

	 			default: throw new Exception("Unhandled instruction for slice creation")
	 		}
	 		last_instruction = I
	 	}
	 	
	 	/* No affectation after the last reduction? Create the final reduction here */
	 	if ((last_instruction !== null) && (last_instruction instanceof ReductionInstruction)) {
	 		val RI = last_instruction as ReductionInstruction
	 		IS += createSlicedReductionFinalReduction(RI, RI.result.name)
	 	}
	 	
	 	/* Return the sliced InstructionBlock */
	 	return IrFactory::eINSTANCE.createInstructionBlock => [
	 		instructions += IS
	 	]
	 }
	
	/* Slice a loop for a job.
	 * We now that the job is slice-able:
	 * - Only II
	 * - OK when an Affectation follows a RI
	 */
	static def void
	createSlicedJob(InstructionJob j)
	{
		switch j.instruction {
			/* Multiple loops or a RI followed by an Affectation */
			InstructionBlock: {
				j.instruction = createSlicedInstructionBlock(j.instruction as InstructionBlock)
			}
			
			/* Simple loop */
			Loop: {
				j.instruction = IrFactory::eINSTANCE.createInstructionBlock => [
					instructions += createSliceLoop(j.instruction as Loop)
				]
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