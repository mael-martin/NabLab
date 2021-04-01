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

import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtend.lib.annotations.Data

import java.util.Set
import java.util.HashMap

import fr.cea.nabla.ir.ir.Affectation
import fr.cea.nabla.ir.ir.ConnectivityCall
import fr.cea.nabla.ir.ir.Exit
import fr.cea.nabla.ir.ir.If
import fr.cea.nabla.ir.ir.Instruction
import fr.cea.nabla.ir.ir.InstructionBlock
import fr.cea.nabla.ir.ir.Interval
import fr.cea.nabla.ir.ir.ItemIdDefinition
import fr.cea.nabla.ir.ir.ItemIndexDefinition
import fr.cea.nabla.ir.ir.IterationBlock
import fr.cea.nabla.ir.ir.Iterator
import fr.cea.nabla.ir.ir.Loop
import fr.cea.nabla.ir.ir.ReductionInstruction
import fr.cea.nabla.ir.ir.Return
import fr.cea.nabla.ir.ir.SetDefinition
import fr.cea.nabla.ir.ir.VariableDeclaration
import fr.cea.nabla.ir.ir.While
import fr.cea.nabla.ir.ir.Variable
import fr.cea.nabla.ir.ir.ItemIdValueIterator
import fr.cea.nabla.ir.ir.Job
import fr.cea.nabla.ir.ir.IrAnnotable

import static extension fr.cea.nabla.ir.ArgOrVarExtensions.*
import static extension fr.cea.nabla.ir.ContainerExtensions.*
import static extension fr.cea.nabla.ir.generator.Utils.*
import static extension fr.cea.nabla.ir.generator.cpp.CppGeneratorUtils.*
import static extension fr.cea.nabla.ir.generator.cpp.ItemIndexAndIdValueContentProvider.*
import java.util.stream.IntStream

@Data
abstract class InstructionContentProvider
{
	protected val extension TypeContentProvider
	protected val extension ExpressionContentProvider
	protected abstract def CharSequence getReductionContent(ReductionInstruction it)
	protected abstract def CharSequence getParallelLoopContent(Loop it)

	def dispatch CharSequence getContent(VariableDeclaration it)
	'''
		«IF variable.type.baseTypeStatic»
			«IF variable.const»const «ENDIF»«variable.type.cppType» «variable.name»«IF variable.defaultValue !== null»(«variable.defaultValue.content»)«ENDIF»;
		«ELSE»
			«IF variable.const»const «ENDIF»«variable.type.cppType» «variable.name»;
			«initCppTypeContent(variable.name, variable.type)»
		«ENDIF»
	'''

	def dispatch CharSequence getContent(InstructionBlock it)
	'''
		{
			«FOR i : instructions»
			«i.content»
			«ENDFOR»
		}'''

	def dispatch CharSequence getContent(Affectation it)
	{
		if (left.target.linearAlgebra && !(left.iterators.empty && left.indices.empty))
			'''«left.codeName».setValue(«formatIteratorsAndIndices(left.target.type, left.iterators, left.indices)», «right.content»);'''
		else
			'''«left.content» = «right.content»;'''
	}

	def dispatch CharSequence getContent(ReductionInstruction it)
	{
		reductionContent
	}

	def dispatch CharSequence getContent(Loop it)
	{
		if (parallel)
			iterationBlock.defineInterval(parallelLoopContent)
		else
			iterationBlock.defineInterval(sequentialLoopContent)
	}

	def dispatch CharSequence getContent(If it)
	'''
		if («condition.content») 
		«val thenContent = thenInstruction.content»
		«IF !(thenContent.charAt(0) == '{'.charAt(0))»	«ENDIF»«thenContent»
		«IF (elseInstruction !== null)»
			«val elseContent = elseInstruction.content»
			else
			«IF !(elseContent.charAt(0) == '{'.charAt(0))»	«ENDIF»«elseContent»
		«ENDIF»
	'''

	def dispatch CharSequence getContent(ItemIndexDefinition it)
	'''
		const size_t «index.name»(«value.content»);
	'''

	def dispatch CharSequence getContent(ItemIdDefinition it)
	'''
		const Id «id.name»(«value.content»);
	'''

	def dispatch CharSequence getContent(SetDefinition it)
	{
		getSetDefinitionContent(name, value)
	}

	def dispatch CharSequence getContent(While it)
	'''
		while («condition.content»)
		«val iContent = instruction.content»
		«IF !(iContent.charAt(0) == '{'.charAt(0))»	«ENDIF»«iContent»
	'''

	def dispatch CharSequence getContent(Return it)
	'''
		return «expression.content»;
	'''

	def dispatch CharSequence getContent(Exit it)
	'''
		throw std::runtime_error("«message»");
	'''

	def dispatch getInnerContent(Instruction it)
	{ 
		content
	}

	def dispatch getInnerContent(InstructionBlock it)
	'''
		«FOR i : instructions»
		«i.content»
		«ENDFOR»
	'''

	protected def boolean isParallel(Loop it) { parallelLoop }

	protected def CharSequence getSequentialLoopContent(Loop it)
	'''
		for (size_t «iterationBlock.indexName»=0; «iterationBlock.indexName»<«iterationBlock.nbElems»; «iterationBlock.indexName»++)
		{
			«body.innerContent»
		}
	'''

	// ### IterationBlock Extensions ###
	protected def dispatch defineInterval(Iterator it, CharSequence innerContent)
	{
		if (container.connectivityCall.connectivity.indexEqualId)
			innerContent
		else
		'''
		{
			«IF container instanceof ConnectivityCall»«getSetDefinitionContent(container.uniqueName, container as ConnectivityCall)»«ENDIF»
			const size_t «nbElems»(«container.uniqueName».size());
			«innerContent»
		}
		'''
	}

	protected def dispatch defineInterval(Interval it, CharSequence innerContent)
	{
		innerContent
	}

	protected def dispatch getIndexName(Iterator it) { index.name }
	protected def dispatch getIndexName(Interval it) { index.name }
	protected def dispatch getNbElems(Iterator it) { container.nbElemsVar }
	protected def dispatch getNbElems(Interval it) { nbElems.content }

	private def getSetDefinitionContent(String setName, ConnectivityCall call)
	'''
		const auto «setName»(mesh->«call.accessor»);
	'''
}

@Data
class SequentialInstructionContentProvider extends InstructionContentProvider
{
	override isParallel(Loop it) { false }

	override protected getReductionContent(ReductionInstruction it)
	{
		throw new UnsupportedOperationException("ReductionInstruction must have been replaced before using this code generator")
	}

	override protected getParallelLoopContent(Loop it)
	{
		sequentialLoopContent
	}
}

@Data
class StlThreadInstructionContentProvider extends InstructionContentProvider
{
	override getReductionContent(ReductionInstruction it)
	'''
		«result.type.cppType» «result.name»;
		«iterationBlock.defineInterval('''
		«result.name» = parallel_reduce(«iterationBlock.nbElems», «result.defaultValue.content», [&](«result.type.cppType»& accu, const size_t& «iterationBlock.indexName»)
			{
				«FOR innerInstruction : innerInstructions»
				«innerInstruction.content»
				«ENDFOR»
				return (accu = «binaryFunction.codeName»(accu, «lambda.content»));
			},
			&«binaryFunction.codeName»);''')»
	'''

	override getParallelLoopContent(Loop it)
	'''
		parallel_exec(«iterationBlock.nbElems», [&](const size_t& «iterationBlock.indexName»)
		{
			«body.innerContent»
		});
	'''
}

@Data
class KokkosInstructionContentProvider extends InstructionContentProvider
{
	override getReductionContent(ReductionInstruction it)
	'''
		«result.type.cppType» «result.name»;
		«iterationBlock.defineInterval('''
		Kokkos::parallel_reduce(«firstArgument», KOKKOS_LAMBDA(const size_t& «iterationBlock.indexName», «result.type.cppType»& accu)
		{
			«FOR innerInstruction : innerInstructions»
			«innerInstruction.content»
			«ENDFOR»
			accu = «binaryFunction.codeName»(accu, «lambda.content»);
		}, KokkosJoiner<«result.type.cppType»>(«result.name», «result.defaultValue.content», &«binaryFunction.codeName»));''')»
	'''

	override getParallelLoopContent(Loop it)
	'''
		Kokkos::parallel_for(«iterationBlock.nbElems», KOKKOS_LAMBDA(const size_t& «iterationBlock.indexName»)
		{
			«body.innerContent»
		});
	'''

	protected def getFirstArgument(ReductionInstruction it) 
	{
		iterationBlock.nbElems
	}
}

@Data
class KokkosTeamThreadInstructionContentProvider extends KokkosInstructionContentProvider
{
	override String getFirstArgument(ReductionInstruction it) 
	{
		"Kokkos::TeamThreadRange(teamMember, " + iterationBlock.nbElems + ")"
	}

	override getParallelLoopContent(Loop it)
	'''
		{
			«iterationBlock.autoTeamWork»

			Kokkos::parallel_for(Kokkos::TeamThreadRange(teamMember, teamWork.second), KOKKOS_LAMBDA(const size_t& «iterationBlock.indexName»Team)
			{
				int «iterationBlock.indexName»(«iterationBlock.indexName»Team + teamWork.first);
				«body.innerContent»
			});
		}
	'''

	private def getAutoTeamWork(IterationBlock it)
	'''
		const auto teamWork(computeTeamWorkRange(teamMember, «nbElems»));
		if (!teamWork.second)
			return;
	'''
}

@Data
class OpenMpInstructionContentProvider extends InstructionContentProvider
{
	override getReductionContent(ReductionInstruction it)
	'''
		«result.type.cppType» «result.name»(«result.defaultValue.content»);
		#pragma omp parallel for reduction(min:«result.name»)
		«iterationBlock.defineInterval('''
		for (size_t «iterationBlock.indexName»=0; «iterationBlock.indexName»<«iterationBlock.nbElems»; «iterationBlock.indexName»++)
		{
			«result.name» = «binaryFunction.codeName»(«result.name», «lambda.content»);
		}''')»
	'''

	override getParallelLoopContent(Loop it)
	'''
		«val vars = modifiedVariables»
		#pragma omp parallel«IF !vars.empty» for shared(«vars.map[codeName].join(', ')»«ENDIF»)
		«sequentialLoopContent»
	'''

	private def getModifiedVariables(Loop l)
	{
		val modifiedVars = l.eAllContents.filter(Affectation).map[left.target].toSet
		modifiedVars.filter[global]
	}
}

@Data
class OpenMpTaskInstructionContentProvider extends InstructionContentProvider
{
	HashMap<String, Pair<Integer, Integer>> dataShift = new HashMap(); /* item name => iterator shift    */
	HashMap<String, String> dataConnectivity          = new HashMap(); /* item name => connectivity type */
	HashMap<String, Integer> counters                 = new HashMap();

	override dispatch getInnerContent(InstructionBlock it)
	'''
		«val isReduction = (instructions.size == 2) &&
		                   (instructions.toList.head instanceof ReductionInstruction) &&
		                   (instructions.toList.last instanceof Affectation)»
		«FOR i : instructions»
		«i.content»
		«ENDFOR»
		««« This bracket is opened in the getReductionContent function
		«IF isReduction»
		}
		«ENDIF»
	'''

	override dispatch CharSequence getContent(Affectation it)
	{
		val parentJob = EcoreUtil2.getContainerOfType(it, Job);

		if (left.target.linearAlgebra && !(left.iterators.empty && left.indices.empty))
			'''«left.codeName».setValue(«formatIteratorsAndIndices(left.target.type, left.iterators, left.indices)», «right.content»);'''
		else if (parentJob !== null && parentJob.eAllContents.filter(Instruction).size == 1)
		{
			val ins = parentJob.inVars
			val outs = parentJob.outVars
			'''
				/* ONLY_AFFECTATION, still need to launch a task for that
				 * TODO: Group all affectations in one job */
				«takeOMPTraces(ins, outs)»
				#pragma omp task«
					getDependenciesAll(parentJob, 'in',  ins,  0, OMPTaskMaxNumber)»«
					getDependenciesAll(parentJob, 'out', outs, 0, OMPTaskMaxNumber)»
					«left.content» = «right.content»;
			'''
		}
		else
			'''«left.content» = «right.content»;'''
	}

	override getReductionContent(ReductionInstruction it)
	{
		val parentJob = EcoreUtil2.getContainerOfType(it, Job)
		val ins  = parentJob.getInVars  /* Need to be computed before, consumed */
		val outs = parentJob.getOutVars /* Produced, unlock jobs that need them */
		val out  = outs.head            /* Produced, unlock jobs that need them */
		'''
			«result.type.cppType» «result.name»(«result.defaultValue.content»);
			«takeOMPTraces(ins, outs)»
			#pragma omp task firstprivate(«result.name», «iterationBlock.nbElems»)«
				getDependenciesAll(parentJob, 'in', ins, 0, OMPTaskMaxNumber)» depend(out: this->«out.name»)
			{
			«iterationBlock.defineInterval('''
			for (size_t «iterationBlock.indexName»=0; «iterationBlock.indexName»<«iterationBlock.nbElems»; «iterationBlock.indexName»++)
				«result.name» = «binaryFunction.codeName»(«result.name», «lambda.content»);
			''')»
		'''
	}

	/* Slice the loop in chunks and feed it to the tasks. */
	override getParallelLoopContent(Loop it)
	{
		val parentJob = EcoreUtil2.getContainerOfType(it, Job)
		counters.put("Loop"+parentJob.name, counters.getOrDefault('Loop'+parentJob.name, 0) + 1)
		dataShift.clear()
		dataConnectivity.clear()
		eAllContents.filter(ItemIdDefinition).forEach[item |
			if (item instanceof ItemIdValueIterator)
				addDataShift(item.id.itemName, item.value as ItemIdValueIterator)
		]
		'''
		«launchTasks(OMPTaskMaxNumber) /* TODO: Add a way for a task to take care of multiple partitions. */»
		'''
	}
	
	/* Compute the shift pair, the first element is the negative shift, the second the positive shift. */
	private def Pair<Integer, Integer> computeShiftPair(Pair<Integer, Integer> pair, int shift)
	{
		return shift < 0 ? new Pair<Integer, Integer>(Math::min(pair.key, shift), pair.value)
		                 : new Pair<Integer, Integer>(pair.key, Math::max(pair.value, shift))
	}
	
	private def void addDataShift(String itemName, ItemIdValueIterator value)
	{
		var Pair<Integer, Integer> shifts = dataShift.get(itemName)
		if (shifts === null) { shifts = new Pair<Integer, Integer>(0, 0); } /* New shift! */
		shifts = computeShiftPair(shifts, value.shift);
		dataShift.put(itemName, shifts);
		dataConnectivity.put(itemName, value.iterator.container.connectivityCall.connectivity.name)
	}

	private def getConnectivityType(Loop it)
	{
		val String itemname = iterationBlock.indexName.toString
		
		/* Check for node connectivities */
		if      (itemname.contains("BottomNodes")) { return "bottomNodes" }
		else if (itemname.contains("TopNodes"))    { return "topNodes"    }
		else if (itemname.contains("RightNodes"))  { return "rightNodes"  }
		else if (itemname.contains("LeftNodes"))   { return "leftNodes"   }
		else if (itemname.contains("InnerNodes"))  { return "innerNodes"  }
		else if (itemname.contains("OuterNodes"))  { return "outerNodes"  }
		else if (itemname.contains("Nodes"))       { return "nodes"       }

		/* Check for cell connectivities */
		else if (itemname.contains("BottomCells")) { return "bottomCells" }
		else if (itemname.contains("TopCells"))    { return "topCells"    }
		else if (itemname.contains("RightCells"))  { return "rightCells"  }
		else if (itemname.contains("LeftCells"))   { return "leftCells"   }
		else if (itemname.contains("InnerCells"))  { return "innerCells"  }
		else if (itemname.contains("OuterCells"))  { return "outerCells"  }
		else if (itemname.contains("Cells"))       { return "cells"       }
		
		/* Check for face connectivities */
		else if (itemname.contains("InnerHorizontalFaces")) { return "innerHorizontalFaces" }
		else if (itemname.contains("InnerVerticalFaces"))   { return "innerVerticalFaces"   }
		else if (itemname.contains("BottomFaces"))          { return "bottomFaces"          }
		else if (itemname.contains("TopFaces"))             { return "topFaces"             }
		else if (itemname.contains("RightFaces"))           { return "rightFaces"           }
		else if (itemname.contains("LeftFaces"))            { return "leftFaces"            }
		else if (itemname.contains("InnerFaces"))           { return "innerFaces"           }
		else if (itemname.contains("OuterFaces"))           { return "outerFaces"           }
		else if (itemname.contains("Faces"))                { return "faces"                }
		
		/* Happily ignored because don't exit from the partition -> no external contributions */
		else if (itemname.contains("CommonFace")) {
			println("Ignored " + itemname + " connectivity function in loop");
		}
		
		/* Ooops, or not implemented */
		else { throw new Exception("Unknown iterator " + itemname + ", could not autofill dataShifts and dataConnectivity") }
	}

	private def takeOMPTraces(IrAnnotable it, Set<Variable> ins, Set<Variable> outs)
	'''
		«IF OMPTraces»
		«val parentJob = EcoreUtil2.getContainerOfType(it, Job)»
		// static uint64_t ___task_id = 0;
		// ++ ___task_id;
		// (UNIQ_task_id, ['in', 'in', ...], ['out', 'out', ...], start, duration) // with DAG-dot
		// fprintf(stderr, "('R«parentJob.name»@«parentJob.at»:l«counters.get("Loop"+parentJob.name)»:t%ld', [«
			FOR v : ins SEPARATOR ', '»'«v.name»'«ENDFOR»], [«
			FOR v : outs SEPARATOR ', '»'«v.name»'«ENDFOR»], 0, 0)\n", ___task_id);
		«ENDIF»
	'''
	
	/* Return a list of dependencies between potential partitions generated by a loop.
	 * TODO: Generate the direction, to take only neighbors in that direction
	 * and reduce dependencies, but for that OpenMP iterators need to work... */
	private def detectDependencies(Loop it)
	{
		for (itblock : iteratorToIterable(eAllContents.filter(IterationBlock)))
		{
			val name = itblock.indexName.toString

			/* Cell => outer Cell */
			if (name.contains("NeighborCells") || name.contains("NeighbourCells") || // In all directions
				name.contains("TopCell") || name.contains("BottomCell") || name.contains("RightCell") || name.contains("LeftCell") // Do better with dir
			) return true

			/* Node => outer Cell */
			if (name.contains("CellsOfNode"))
				return true

			/* Cell => outer Face */
			if (name.contains("FaceOfCell") || name.contains("FacesOfCell"))
				return true

			/* Face => outer Cell */
			if (name.contains("CellsOfFaces") || name.contains("BackCell") || name.contains("FrontCell"))
				return true

			/* Cell => outer Node */
			if (name.contains("NodesOfCell"))
				return true

			/* Face => outer Node */
			if (name.contains("NodesOfFace") || name.contains("NodeOfFace"))
				return true
				
			/* Face => outer Face */
			if (name.contains("BottomFaceNeighbour") || name.contains("BottomLeftFaceNeighbour") || name.contains("BottomRightFaceNeighbour") ||
				name.contains("TopFaceNeighbour")    || name.contains("TopLeftFaceNeighbour")    || name.contains("TopRightFaceNeighbour")    ||
				name.contains("RightFaceNeighbour")  || name.contains("LeftFaceNeighbour")
			)
				return true
		}
		return false
	}
	
	/* TODO: Take into account which directions are used (to only pin 1 or 2
	 * partitions, not all the neighbors). */
	private def launchSingleTaskForPartition(Loop it, CharSequence partitionId, Set<Variable> ins, Set<Variable> outs)
	'''
		{
			«takeOMPTraces(ins, outs)»
			«val has_shifts = dataShift.size > 0»
			«val parentJob = EcoreUtil2.getContainerOfType(it, Job)»
			#pragma omp task«
			getDependencies(parentJob, 'in',  ins,  partitionId, has_shifts || detectDependencies) /* Consumed by the task */»«
			getDependencies(parentJob, 'out', outs, partitionId, false)                            /* Produced by the task */»
			for (const size_t «iterationBlock.indexName» : «getLoopRange(connectivityType, partitionId.toString)»)
			{
				«body.innerContent»
			}
		}
	'''
	
	private def launchTasks(Loop it, int taskN)
	{
		val parentJob = EcoreUtil2.getContainerOfType(it, Job)
		val ins       = parentJob.inVars  /* Need to be computed before, consumed. */
		val outs      = parentJob.outVars /* Produced, unlock jobs that need them. */
		if (eAllContents.filter(ItemIdDefinition).size == 0)
		{
			val String itemname = iterationBlock.indexName.toString

			/* Auto detect cells */
			if (itemname.contains("Cell") || itemname.contains("cell")) {
				dataShift.put(String::valueOf(itemname.charAt(0)), new Pair<Integer, Integer>(0, 0))
				dataConnectivity.put(String::valueOf(itemname.charAt(0)), "cells");
			}
			
			/* Auto detect nodes */
			else if (itemname.contains("Node") || itemname.contains("node")) {
				dataShift.put(String::valueOf(itemname.charAt(0)), new Pair<Integer, Integer>(0, 0))
				dataConnectivity.put(String::valueOf(itemname.charAt(0)), "nodes");
			}
			
			/* Auto detect faces */
			else if (itemname.contains("Face") || itemname.contains("face")) {
				dataShift.put(String::valueOf(itemname.charAt(0)), new Pair<Integer, Integer>(0, 0))
				dataConnectivity.put(String::valueOf(itemname.charAt(0)), "faces");
			}
			
			else { throw new Exception("Unknown iterator " + itemname + ", could not autofill dataShifts and dataConnectivity") }
		}
		'''
			for (size_t task = 0; task < («taskN»); ++task)
			«launchSingleTaskForPartition(it, '''task''', ins, outs)»
		'''
	}
}