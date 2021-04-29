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

import fr.cea.nabla.ir.ir.Instruction
import fr.cea.nabla.ir.ir.IrFactory
import java.util.HashMap
import java.util.HashSet
import java.util.List
import java.util.Map
import java.util.Set
import org.eclipse.emf.ecore.util.FeatureMapUtil

class IrTransformationUtils
{
	/**
	 * Extension of the EcoreUtil::replace operation for a list of objects.
	 * If the eContainmentFeature is a 1:1 multiplicity, an instance of InstructionBlock is created,
	 * else, the 'newInstructions' replace 'oldInstruction'.
	 */
	static def replace(Instruction oldInstruction, List<Instruction> newInstructions)
	{
		val container = oldInstruction.eContainer
		if (container !== null && !newInstructions.empty)
		{
			val feature = oldInstruction.eContainmentFeature
			if (FeatureMapUtil.isMany(container, feature))
			{
				val list = container.eGet(feature) as List<Object>
				val reductionIndex = list.indexOf(oldInstruction)
				list.set(reductionIndex, newInstructions.get(0))
				for (i : 1..<newInstructions.length)
					list.add(reductionIndex+i, newInstructions.get(i))
			}
			else
			{
				val replacementBlock = IrFactory::eINSTANCE.createInstructionBlock =>
				[
					for (toAdd : newInstructions)
						instructions += toAdd
				]
				container.eSet(feature, replacementBlock)
			}
		}
	}

	/**
	 * Nearly the same method as above except that the 'existingInstruction' is not replace;
	 * instructions are just inserted before
	 */
	static def insertBefore(Instruction existingInstruction, List<Instruction> instructionsToInsert)
	{
		val container = existingInstruction.eContainer
		if (container !== null && !instructionsToInsert.empty)
		{
			val feature = existingInstruction.eContainmentFeature
			if (FeatureMapUtil.isMany(container, feature))
			{
				val list = container.eGet(feature) as List<Object>
				val reductionIndex = list.indexOf(existingInstruction)
				for (toAdd : instructionsToInsert)
					list.add(reductionIndex, toAdd)
			}
			else
			{
				val replacementBlock = IrFactory::eINSTANCE.createInstructionBlock =>
				[
					for (toAdd : instructionsToInsert) instructions += toAdd
					instructions += existingInstruction
				]
				container.eSet(feature, replacementBlock)
			}
		}
	}
	
	static def <KEY, VAL> Map<VAL, Set<KEY>> reverseHashMap(Map<KEY, VAL> hashmap)
	{
		val Map<VAL, Set<KEY>> reversemap = new HashMap();
		hashmap.keySet.forEach[ k | 
			val value = hashmap.get(k)
			val keys  = reversemap.getOrDefault(value, new HashSet())
			keys.add(k)
			reversemap.put(value, keys)
		]
		return reversemap
	}
}
