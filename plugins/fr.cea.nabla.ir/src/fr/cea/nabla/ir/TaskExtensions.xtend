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

import fr.cea.nabla.ir.ir.Variable
import fr.cea.nabla.ir.ir.IrFactory
import fr.cea.nabla.ir.ir.ConnectivityType
import java.util.stream.IntStream
import fr.cea.nabla.ir.ir.TimeLoopCopy
import org.eclipse.emf.common.util.EList

class TaskExtensions
{
	/* Helpers and setters for parameters */

	static int num_tasks = 1
	static def setNumTasks(int ntasks) { num_tasks = ntasks }

	static private def getConnectivityName(Variable v)
	{
		if (v.type instanceof ConnectivityType) {
			return (v.type as ConnectivityType).connectivities.head.name
		}

		else { return "simple" }
	}
	
	/* Create the TimeLoopCopyInstruction */
	
	static private def createTimeLoopCopyInstruction(TimeLoopCopy tlc)
	{
		return IrFactory::eINSTANCE.createTimeLoopCopyInstruction => [
			content = IrFactory::eINSTANCE.createTimeLoopCopy => [
				destination = tlc.destination
				source      = tlc.source
			]
		]
	}

	static def createTimeLoopCopyInstruction(EList<TimeLoopCopy> tlcs)
	{
		tlcs.map[ createTimeLoopCopyInstruction ]
	}
	
	/* Create the TaskDependencyVariable */

	static def createTaskDependencyVariable(Variable v)
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