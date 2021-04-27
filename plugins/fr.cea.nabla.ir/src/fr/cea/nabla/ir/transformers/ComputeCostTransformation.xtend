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

import static extension fr.cea.nabla.ir.transformers.IrTransformationUtils.*

import java.util.ArrayList
import java.util.List
import java.util.HashMap
import java.util.HashSet
import java.util.Set
import java.util.Map

import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.emf.ecore.EObject

import fr.cea.nabla.ir.ir.IrRoot
import fr.cea.nabla.ir.ir.Instruction
import fr.cea.nabla.ir.ir.IrFactory
import fr.cea.nabla.ir.ir.Affectation
import fr.cea.nabla.ir.ir.ArgOrVarRef
import fr.cea.nabla.ir.ir.BaseType
import fr.cea.nabla.ir.ir.Expression
import fr.cea.nabla.ir.ir.IrFactory
import fr.cea.nabla.ir.ir.PrimitiveType
import fr.cea.nabla.ir.ir.Variable
import fr.cea.nabla.ir.ir.Expression
import fr.cea.nabla.ir.ir.IterableInstruction
import fr.cea.nabla.ir.ir.IterationBlock
import fr.cea.nabla.ir.ir.Job
import fr.cea.nabla.ir.ir.ReductionInstruction
import fr.cea.nabla.ir.ir.Function
import fr.cea.nabla.ir.ir.InternFunction
import fr.cea.nabla.ir.ir.ExternFunction

@Data
class ComputeCostTransformation extends IrTransformationStep
{
	new()
	{
		super('Compute cost of jobs and functions')
	}

	override transform(IrRoot ir) 
	{
		trace('    IR -> IR: ' + description)

		val functions = ir.eAllContents.filter(Function)
		functions.forEach[evaluateCost]

		val jobs = ir.eAllContents.filter(Job)
		jobs.forEach[evaluateCost]

		return true
	}
	
	private def evaluateCost(Function it)
	{
		switch it {
			InternFunction: evaluateCost(it as InternFunction)
			ExternFunction: evaluateCost(it as ExternFunction)
		}
	}

	private def evaluateCost(InternFunction it)
	{
		trace('        Evaluate cost of intern function ' + name)
	}

	private def evaluateCost(ExternFunction it)
	{
		trace("        Can't evaluate cost of extern function " + name + ", set it to default")
	}

	private def evaluateCost(Job it)
	{
		trace('        Evaluate cost of job ' + name)
	}
}