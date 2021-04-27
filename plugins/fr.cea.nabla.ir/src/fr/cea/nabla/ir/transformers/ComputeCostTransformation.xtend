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
import fr.cea.nabla.ir.ir.Loop
import fr.cea.nabla.ir.ir.While
import fr.cea.nabla.ir.ir.If
import fr.cea.nabla.ir.ir.BinaryExpression
import fr.cea.nabla.ir.ir.UnaryExpression
import fr.cea.nabla.ir.ir.ContractedIf
import fr.cea.nabla.ir.ir.Parenthesis
import fr.cea.nabla.ir.ir.Cardinality
import fr.cea.nabla.ir.ir.Container
import fr.cea.nabla.ir.ir.IntConstant
import fr.cea.nabla.ir.ir.RealConstant
import fr.cea.nabla.ir.ir.BoolConstant
import fr.cea.nabla.ir.ir.MinConstant
import fr.cea.nabla.ir.ir.MaxConstant
import fr.cea.nabla.ir.ir.FunctionCall
import fr.cea.nabla.ir.ir.BaseTypeConstant
import fr.cea.nabla.ir.ir.VectorConstant

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
	
	/* Cost evaluation methods */
	
	private def int evaluateCost(Function it)
	{
		switch it {
			InternFunction: evaluateCost(it as InternFunction)
			ExternFunction: evaluateCost(it as ExternFunction)
			default: throw new Exception("Unknown function type for " + it.toString + ", can't evaluate its cost")
		}
	}

	private def int evaluateCost(InternFunction it)
	{
		trace('        Evaluate cost of intern function ' + name)
		return 0;
	}

	private def int evaluateCost(ExternFunction it)
	{
		trace("        Can't evaluate cost of extern function " + name + ", set it to default")
		return 0;
	}

	private def int evaluateCost(Job it)
	{
		trace('        Evaluate cost of job ' + name)
		return 0;
	}
	
	private def int evaluateCost(Container it)
	{
		throw new Exception("Not implemented")
	}
	
	private def int evaluateCost(Expression it)
	{
		/* Special cases => stops cases */
		if (constExpr)
			return 1;

		/* Pattern matching */
		switch it {
			BinaryExpression: return evaluateCost(left) + evaluateOperatorCost(operator) + evaluateCost(right)
			UnaryExpression:  return evaluateOperatorCost(operator) + evaluateCost(expression)
			Parenthesis:      return evaluateCost(expression)
			FunctionCall:     return evaluateCost(function)
			Function:         return evaluateCost(it as Function)
			ArgOrVarRef:      return 1 + indices.map[evaluateCost].reduce[ p1, p2 | p1 + p2 ] /* 1 because A[x] = ... */
			
			/* Connectivity call and others... */
			Cardinality: return evaluateCost(container)
			
			/* Constants */
			IntConstant:      return 1
			RealConstant:     return 1
			BoolConstant:     return 1
			MinConstant:      return 1
			MaxConstant:      return 1
			BaseTypeConstant: return 1
			VectorConstant:   return 1

			/* The values for then/else are arbitrary, add a way for the user to change them/to calculate them */
			ContractedIf: return (evaluateCost(thenExpression) * 0.7 + evaluateCost(elseExpression) * 0.3).intValue
			
			/* Panic */
			default: throw new Exception("Unknown Expression type for " + it.toString + ", can't evaluate its cost")
		}
	}
	
	private def int evaluateOperatorCost(String op)
	{
		/* Evaluate cost of an operator. Those are arbitrary values, change them for real cost for the targeted CPU/GPU */
		if (op == "+") return 1;
		if (op == "-") return 1;
		if (op == "*") return 4;
		if (op == "%") return 10;
		throw new Exception("Unknown operator '" + op + "', can't evaluate its cost")
	}
	
	/* Repetition evaluation methods */
	
	private def int evaluateRep(Instruction it)
	{
		switch it {
			IterableInstruction: evaluateRep(it as IterableInstruction)
			If: evaluateRep(it as If)
			While: evaluateRep(it as While)
			default: throw new Exception("Unknown Instruction type for " + it.toString + ", can't evaluate its repetition")
		}
	}
	
	private def int evaluateRep(IterableInstruction it)
	{
		switch it {
			Loop: evaluateRep(it as Loop)
			ReductionInstruction: evaluateRep(it as ReductionInstruction)
			default: throw new Exception("Unknown IterableInstruction type for " + it.toString + ", can't evaluate its repetition")
		}
	}
	
	private def int evaluateRep(While it)
	{
		throw new Exception("Not implemented")
	}
	
	private def int evaluateRep(If it)
	{
		throw new Exception("Not implemented")
	}
	
	private def int evaluateRep(Loop it)
	{
		throw new Exception("Not implemented")
	}

	private def int evaluateRep(ReductionInstruction it)
	{
		throw new Exception("Not implemented")
	}
}