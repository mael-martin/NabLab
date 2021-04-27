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

import java.util.HashMap
import java.util.Map

import org.eclipse.xtend.lib.annotations.Data

import fr.cea.nabla.ir.ir.IrRoot
import fr.cea.nabla.ir.ir.Instruction
import fr.cea.nabla.ir.ir.Affectation
import fr.cea.nabla.ir.ir.ArgOrVarRef
import fr.cea.nabla.ir.ir.Expression
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
import fr.cea.nabla.ir.ir.InstructionBlock
import fr.cea.nabla.ir.ir.Exit
import fr.cea.nabla.ir.ir.VariableDeclaration
import fr.cea.nabla.ir.ir.ItemIndexDefinition
import fr.cea.nabla.ir.ir.ItemIdDefinition
import fr.cea.nabla.ir.ir.SetDefinition
import fr.cea.nabla.ir.ir.InstructionJob
import fr.cea.nabla.ir.ir.TimeLoopJob
import fr.cea.nabla.ir.ir.ConnectivityCall
import fr.cea.nabla.ir.ir.Iterator

/* Approximate the number of connectivities' element number on connectivity call.
 * One simple rule: all methods must return a positive integer or zero.
 */
@Data
abstract class GeometryInformations
{
	def abstract int getCellsNumber();
	def abstract int getNodesNumber();
	def abstract int getFacesNumber();
	
	protected def abstract int getOuterCellsIntersectionNumber();
	protected def abstract int getOuterNodesIntersectionNumber();
	protected def abstract int getOuterFacesIntersectionNumber();
	
	def int getInnerCellsNumber() { cellsNumber - outerCellsNumber }
	def int getOuterCellsNumber() { topCellsNumber + bottomCellsNumber + rightCellsNumber + leftCellsNumber - outerCellsIntersectionNumber }
	def abstract int getTopCellsNumber();
	def abstract int getBottomCellsNumber();
	def abstract int getLeftCellsNumber();
	def abstract int getRightCellsNumber();

	def int getInnerNodesNumber() { nodesNumber - outerNodesNumber }
	def int getOuterNodesNumber() { topNodesNumber + bottomNodesNumber + rightNodesNumber + leftNodesNumber - outerNodesIntersectionNumber }
	def abstract int getTopNodesNumber();
	def abstract int getBottomNodesNumber();
	def abstract int getLeftNodesNumber();
	def abstract int getRightNodesNumber();

	def int getInnerFacesNumber() { facesNumber - outerFacesNumber }
	def int getOuterFacesNumber() { topFacesNumber + bottomFacesNumber + rightFacesNumber + leftFacesNumber - outerFacesIntersectionNumber }
	def abstract int getTopFacesNumber();
	def abstract int getBottomFacesNumber();
	def abstract int getLeftFacesNumber();
	def abstract int getRightFacesNumber();
}

@Data
class Mesh2DGeometryInformations extends GeometryInformations
{
	int X;
	int Y;
	
	new(int x, int y)
	{
		this.X = x;
		this.Y = y;
		if (x <= 2 || y <= 2)
			throw new Exception("With the Mesh2DGeomtry, x and y must at least be equal to 3")
	}

	/* Intersections between the outer connectivities */
	override protected getOuterCellsIntersectionNumber() { 4 }
	override protected getOuterNodesIntersectionNumber() { 4 }
	override protected getOuterFacesIntersectionNumber() { 0 }
	
	/* Use approximations sometimes, not really important */
	override getCellsNumber() { X * Y }
	override getNodesNumber() { (X + 1) * (Y + 1) }
	override getFacesNumber() { 4 * cellsNumber }
	
	override getTopCellsNumber()    { X               }
	override getBottomCellsNumber() { topCellsNumber  }
	override getLeftCellsNumber()   { Y               }
	override getRightCellsNumber()  { leftCellsNumber }
	
	override getTopNodesNumber()    { X + 1           }
	override getBottomNodesNumber() { topNodesNumber  }
	override getLeftNodesNumber()   { Y + 1           }
	override getRightNodesNumber()  { leftNodesNumber }
	
	override getTopFacesNumber()    { topCellsNumber   }
	override getBottomFacesNumber() { topFacesNumber   }
	override getLeftFacesNumber()   { rightCellsNumber }
	override getRightFacesNumber()  { leftFacesNumber  }
	
}

@Data
class ComputeCostTransformation extends IrTransformationStep
{
	/* Default probabilities for likely and unlikely */
	static final double defaultLikelyProbability    = 0.7
	static final double defaultUnlikelyProbability  = 1 - defaultLikelyProbability

	/* Operation costs, see which values are correct */
	static final int    operationCostADDITION       = 1
	static final int    operationCostSUBSTRACTION   = operationCostADDITION
	static final int    operationCostMULTIPLICATION = 3 * operationCostADDITION
	static final int    operationCostDIVISION       = 3 * operationCostMULTIPLICATION
	static final int    operationCostREMINDER       = operationCostDIVISION
	
	/* A default cost, for external functions */
	static final int    defaultUnknownCost          = 10
	
	/* HashMaps to store cost of functions, jobs, etc */
	static Map<String, Integer> functionCostMap = new HashMap();
	static Map<String, Integer> jobCostMap      = new HashMap();
	
	/* FIXME: Hack, force X and Y and Mesh2D geometry, get for glace2D, used json in tests */
	int HACK_X = 200
	int HACK_Y = 20
	
	GeometryInformations geometry;

	new()
	{
		super('Compute cost of jobs and functions')
		functionCostMap.clear
		jobCostMap.clear
		
		/* Default for the moment */
		geometry = new Mesh2DGeometryInformations(HACK_X, HACK_Y)
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
			/* Compute the cost of an intern function, cache it in HashMap */
			InternFunction: {
				var cost = functionCostMap.getOrDefault(name, 0)
				if (cost == 0) {
					trace('        Evaluate cost of INTERN function ' + name)
					cost = 0
					trace('        Cost of INTERN function ' + name + ' evaluated to: ' + cost)
					functionCostMap.put(name, cost)
				}
				return cost
			}

			ExternFunction: {
				trace("        Can't evaluate cost of EXTERN function " + name + ", set it to default (" + defaultUnknownCost + ")")
				return defaultUnknownCost
			}

			default: throw new Exception("Unknown function type for " + it.toString + ", can't evaluate its cost")
		}
	}

	private def int evaluateCost(Job it)
	{
		switch it {
			/* A job instruction, may be transformed by the OpenMPTask backend */
			InstructionJob: {
				var cost = jobCostMap.getOrDefault(name, 0)
				if (cost == 0) {
					trace('        Evaluate cost of job ' + name)
					cost = evaluateCost(instruction)
					trace('        Cost of job ' + name + ' evaluated to: ' + cost)
					jobCostMap.put(name, cost)
				}
				return cost
			}

			/* Ignored jobs, won't be transformed in a particular way with the OpenMPTask backend */
			TimeLoopJob: {
				trace('        Skip cost evaluation of time loop job ' + name)
				return 0
			}
			
			/* Panic */
			default: throw new Exception("Unknown Job type for " + it.toString + ", can't evaluate its cost")
		}
	}
	
	private def int evaluateCost(Instruction it)
	{
		switch it {
			/* Simple things, constants, set them to correct things */
			VariableDeclaration | ItemIndexDefinition | ItemIdDefinition | SetDefinition: return 1
			
			/* Recursive things */
			InstructionBlock: return instructions.map[evaluateCost].reduce[ p1, p2 | p1 + p2 ]
			Affectation:      return 1 + evaluateCost(left) + evaluateCost(right)
			If:               return ( evaluateCost(thenInstruction) * defaultLikelyProbability
									 + evaluateCost(elseInstruction) * defaultUnlikelyProbability
									 + evaluateCost(condition)).intValue

			/* Loops */
			Loop: evaluateCost(body) * evaluateRep(it as Loop).intValue
			ReductionInstruction: innerInstructions.map[evaluateCost].reduce[ p1, p2 | p1 + p2 ] * evaluateRep(it as ReductionInstruction).intValue
			
			/* Edge case things and panic */
			Exit:    return 1
			While:   throw new Exception("Unsupported 'While' Instruction")
			default: throw new Exception("Unknown Instruction type for " + it.toString + ", can't evaluate cost")
		}
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
			ArgOrVarRef:      return 1 + (indices.map[evaluateCost].reduce[ p1, p2 | p1 + p2 ] ?: 0) /* 1 because A[x] = ... */
			
			/* Connectivity call and others are calculated before the simulation begins */
			Cardinality: return 1
			
			/* Constants */
			IntConstant | RealConstant | BoolConstant | MinConstant | MaxConstant | BaseTypeConstant | VectorConstant: return 1

			/* The values for then/else are arbitrary, add a way for the user to change them/to calculate them */
			ContractedIf: return ( evaluateCost(thenExpression) * defaultLikelyProbability
								 + evaluateCost(elseExpression) * defaultUnlikelyProbability
								 + evaluateCost(condition)).intValue
			
			/* Panic */
			default: throw new Exception("Unknown Expression type for " + it.toString + ", can't evaluate its cost")
		}
	}
	
	private def int evaluateOperatorCost(String op)
	{
		/* Evaluate cost of an operator. Those are arbitrary values, change them for real cost for the targeted CPU/GPU */
		if (op == "+") return operationCostADDITION;
		if (op == "-") return operationCostSUBSTRACTION;
		if (op == "*") return operationCostMULTIPLICATION;
		if (op == "/") return operationCostDIVISION;
		if (op == "%") return operationCostREMINDER;
		throw new Exception("Unknown operator '" + op + "', can't evaluate its cost")
	}
	
	/* Repetition evaluation methods */
	
	private def double evaluateRep(Container it)
	{
		switch it {
			/* Get the repetition of a connectivity */
			ConnectivityCall: {
				throw new Exception("Not implemented")
			}

			default: throw new Exception("Unknown Container type for " + it.toString + ", can't evaluate its repetition")
		}
	}
	
	private def double evaluateRep(Instruction it)
	{
		switch it {
			/* Iterable instructions */
			Loop | ReductionInstruction: {
				val connectivity = eAllContents.filter(Iterator).map[container].filter(ConnectivityCall).head
				return evaluateRep(connectivity)
			}
			
			/* Conditional, get the probability */
			If: {
				return defaultLikelyProbability
			}

			/* Loop, get the expected iterations => Poisson law with If? */
			While: {
				throw new Exception("Not implemented")
			}

			default: throw new Exception("Unknown Instruction type for " + it.toString + ", can't evaluate its repetition")
		}
	}
}