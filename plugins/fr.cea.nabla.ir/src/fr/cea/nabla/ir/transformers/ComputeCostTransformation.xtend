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

import fr.cea.nabla.ir.ir.Affectation
import fr.cea.nabla.ir.ir.ArgOrVarRef
import fr.cea.nabla.ir.ir.BaseTypeConstant
import fr.cea.nabla.ir.ir.BinaryExpression
import fr.cea.nabla.ir.ir.BoolConstant
import fr.cea.nabla.ir.ir.Cardinality
import fr.cea.nabla.ir.ir.ConnectivityCall
import fr.cea.nabla.ir.ir.Container
import fr.cea.nabla.ir.ir.ContractedIf
import fr.cea.nabla.ir.ir.ExecuteTimeLoopJob
import fr.cea.nabla.ir.ir.Exit
import fr.cea.nabla.ir.ir.Expression
import fr.cea.nabla.ir.ir.ExternFunction
import fr.cea.nabla.ir.ir.Function
import fr.cea.nabla.ir.ir.FunctionCall
import fr.cea.nabla.ir.ir.If
import fr.cea.nabla.ir.ir.Instruction
import fr.cea.nabla.ir.ir.InstructionBlock
import fr.cea.nabla.ir.ir.InstructionJob
import fr.cea.nabla.ir.ir.IntConstant
import fr.cea.nabla.ir.ir.InternFunction
import fr.cea.nabla.ir.ir.IrRoot
import fr.cea.nabla.ir.ir.ItemIdDefinition
import fr.cea.nabla.ir.ir.ItemIndexDefinition
import fr.cea.nabla.ir.ir.Iterator
import fr.cea.nabla.ir.ir.Job
import fr.cea.nabla.ir.ir.JobCaller
import fr.cea.nabla.ir.ir.Loop
import fr.cea.nabla.ir.ir.MaxConstant
import fr.cea.nabla.ir.ir.MinConstant
import fr.cea.nabla.ir.ir.Parenthesis
import fr.cea.nabla.ir.ir.RealConstant
import fr.cea.nabla.ir.ir.ReductionInstruction
import fr.cea.nabla.ir.ir.Return
import fr.cea.nabla.ir.ir.SetDefinition
import fr.cea.nabla.ir.ir.TimeLoopJob
import fr.cea.nabla.ir.ir.UnaryExpression
import fr.cea.nabla.ir.ir.VariableDeclaration
import fr.cea.nabla.ir.ir.VectorConstant
import fr.cea.nabla.ir.ir.While
import java.util.HashMap
import java.util.Map
import org.eclipse.xtend.lib.annotations.Data

import static fr.cea.nabla.ir.transformers.IrTransformationUtils.*

/* Approximate the number of connectivities' element number on connectivity call.
 * One simple rule: all methods must return a positive integer or zero. */
@Data
abstract class GeometryInformations
{
	def abstract int getCellsNumber();
	def abstract int getNodesNumber();
	def abstract int getFacesNumber();
	
	protected def abstract int getOuterCellsIntersectionNumber();
	protected def abstract int getOuterNodesIntersectionNumber();
	protected def abstract int getOuterFacesIntersectionNumber();
	
	def abstract int getNodesOfCellsNumber();
	def abstract int getNodesOfFacesNumber();
	def abstract int getCellsOfNodesNumber();
	def abstract int getCellsOfFacesNumber();
	def abstract int getFacesOfNodesNumber();
	def abstract int getFacesOfCellsNumber();
	
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

	def int getInnerFacesNumber()     { facesNumber - outerFacesNumber }
	def int getOuterFacesNumber()     { topFacesNumber + bottomFacesNumber + rightFacesNumber + leftFacesNumber - outerFacesIntersectionNumber }
	def int getInnerVerticalFaces()   { innerFacesNumber / 2 }
	def int getInnerHorizontalFaces() { innerFacesNumber / 2 }
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
	
	override int getNodesOfCellsNumber() { 4 }
	override int getNodesOfFacesNumber() { 2 }
	override int getCellsOfNodesNumber() { 4 }
	override int getCellsOfFacesNumber() { 2 }
	override int getFacesOfNodesNumber() { 4 }
	override int getFacesOfCellsNumber() { 4 }
}

@Data
class ComputeCostTransformation extends IrTransformationStep
{
	/* Default probabilities for likely and unlikely */
	static final double defaultLikelyProbability    = 0.7
	static final double defaultUnlikelyProbability  = 1 - defaultLikelyProbability

	/* Operation costs, see which values are correct */
	static final int    operationCostADDITION       = 1	                               // +
	static final int    operationCostSUBSTRACTION   = operationCostADDITION            // -
	static final int    operationCostMULTIPLICATION = 3 * operationCostADDITION        // *
	static final int    operationCostDIVISION       = 3 * operationCostMULTIPLICATION  // /
	static final int    operationCostREMINDER       = operationCostDIVISION            // %
	static final int    operationCostLOGIC          = 1                                // || &&
	static final int    operationCostCOMPARISON     = 1                                // <= >= == < > !=
	static final int    operationCostNOT            = 1                                // !
	
	/* A default cost, for external functions */
	static final int    defaultUnknownCost          = 10
	
	/* HashMaps to store cost of functions, jobs, etc */
	static Map<String, Integer> functionCostMap    = new HashMap();
	static Map<String, Integer> jobCostMap         = new HashMap();
	static Map<String, Double> jobContributionMap  = new HashMap();
	
	static def int getJobCost(Job it)
	{
		if (it === null)
			throw new Exception("Invalid parameter, passing 'null' as a Job")

		switch it {
			InstructionJob: {
				val int ret = jobCostMap.getOrDefault(name, 0)
				if (ret == 0)
					throw new Exception("Cost of job '" + name + "' was not computed during transformation steps")
				return ret
				}

			/* Things not handled */
			TimeLoopJob: return 0
			default: throw new Exception("Unknown Job type for " + it.toString)
		}
	}
	
	static def double getJobContribution(Job it)
	{
		if (it === null)
			throw new Exception("Invalid parameter, passing 'null' as a Job")

		switch it {
			InstructionJob: {
				val double ret = jobContributionMap.getOrDefault(name, 0.0)
				if (ret == 0)
					throw new Exception("Contribution of job '" + name + "' was not computed during transformation steps")
				return ret
				}

			/* Things not handled */
			TimeLoopJob: return 0
			default: throw new Exception("Unknown Job type for " + it.toString)
		}
	}

	/* FIXME: Hack, force X and Y and Mesh2D geometry, get for glace2D, used json in tests */
	int HACK_X = 600
	int HACK_Y = 60
	
	GeometryInformations geometry;
	static int geometry_domain_size; // Basically `X * Y`, but with extra steps
	static def int getGeometry_domain_size() { geometry_domain_size }

	new()
	{
		super('ComputeCost')
		functionCostMap.clear
		jobCostMap.clear
		
		/* Default for the moment */
		geometry = new Mesh2DGeometryInformations(HACK_X, HACK_Y)
		geometry_domain_size = geometry.cellsNumber
	}

	override transform(IrRoot ir) 
	{
		trace('    IR -> IR: ' + description + ':ComputeFunctionCost')
		ir.eAllContents.filter(Function).forEach[evaluateCost]

		trace('    IR -> IR: ' + description + ':ComputeJobCost')
		ir.eAllContents.filter(Job).forEach[evaluateCost]
		
		trace('    IR -> IR: ' + description + ':ComputeContributions')
		ir.eAllContents.filter(JobCaller).forEach[evaluateContribution]

		reportHashMap('Cost', reverseHashMap(jobCostMap), 'Cost', ': ')
		reportHashMap('Cost', reverseHashMap(jobContributionMap), 'Contribution', ': ')
		return true
	}
	
	/* Get the contribution from the cost */
	
	private def void evaluateContribution(JobCaller it)
	{
		if (it === null) { throw new Exception("Passing a NULL JobCaller") }

		val double totalCost = calls.map[jobCost].reduce[ p1, p2 | p1 + p2 ] + 0.0

		if (totalCost <= 0.0001) { throw new Exception("Null total cost found for JobCaller") }

		calls.reject[ j | j instanceof TimeLoopJob || j instanceof ExecuteTimeLoopJob ].forEach[
			val contrib = jobCost / totalCost // FIXME: Is there a moment where the totalCost can be 0 ?
			jobContributionMap.put(name, contrib)
		]
	}
	
	/* Cost evaluation methods */
	
	private def int evaluateCost(Function it)
	{
		switch it {
			/* Compute the cost of an intern function, cache it in HashMap */
			InternFunction: {
				var cost = functionCostMap.getOrDefault(name, 0)
				if (cost == 0) {
					cost = evaluateCost(body)
					// trace('        INTERN function ' + name + ', cost evaluated to: ' + cost)
					functionCostMap.put(name, cost)
				}
				return cost
			}

			ExternFunction: {
				// trace("        EXTERN function " + name + ", set default cost default (" + defaultUnknownCost + ")")
				return defaultUnknownCost
			}

			default: throw new Exception("Unknown function type for " + it.toString + ", can't evaluate its cost")
		}
	}

	private def int evaluateCost(Job it)
	{
		if (it === null)
			return 0;
			
		switch it {
			/* A job instruction, may be transformed by the OpenMPTask backend */
			InstructionJob: {
				var cost = jobCostMap.getOrDefault(name, 0)
				if (cost == 0) {
					cost = evaluateCost(instruction)
					jobCostMap.put(name, cost)
				}
				return cost
			}

			/* Ignored jobs, won't be transformed in a particular way with the OpenMPTask backend */
			TimeLoopJob: return 0
			
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
			ReductionInstruction: (innerInstructions.map[evaluateCost].reduce[ p1, p2 | p1 + p2 ] ?: 1) * evaluateRep(it as ReductionInstruction).intValue
			
			/* Edge case things and panic */
			Return:  evaluateCost(expression)
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
		if (op == "!") return operationCostNOT;
		if (op == "&&" || op == "||") return operationCostLOGIC;
		if (op == ">" || op == "<" || op == ">=" || op == "<= " || op == "!=" || op == "==") return operationCostCOMPARISON;
		throw new Exception("Unknown operator '" + op + "', can't evaluate its cost")
	}
	
	/* Repetition evaluation methods */
	
	private def double evaluateRep(Container it)
	{
		if (it === null)
			return 0;

		switch it {
			/* Get the repetition of a connectivity */
			ConnectivityCall: {
				if      (connectivity.name == "bottomNodes") { return geometry.bottomNodesNumber }
				else if (connectivity.name == "topNodes")    { return geometry.topNodesNumber    }
				else if (connectivity.name == "rightNodes")  { return geometry.rightNodesNumber  }
				else if (connectivity.name == "leftNodes")   { return geometry.leftNodesNumber   }
				else if (connectivity.name == "innerNodes")  { return geometry.innerNodesNumber  }
				else if (connectivity.name == "outerNodes")  { return geometry.outerNodesNumber  }

				else if (connectivity.name == "bottomCells") { return geometry.bottomCellsNumber }
				else if (connectivity.name == "topCells")    { return geometry.topCellsNumber    }
				else if (connectivity.name == "rightCells")  { return geometry.rightCellsNumber  }
				else if (connectivity.name == "leftCells")   { return geometry.leftCellsNumber   }
				else if (connectivity.name == "innerCells")  { return geometry.innerCellsNumber  }
				else if (connectivity.name == "outerCells")  { return geometry.outerCellsNumber  }
				
				else if (connectivity.name == "innerHorizontalFaces") { return geometry.innerHorizontalFaces }
				else if (connectivity.name == "innerVerticalFaces")   { return geometry.innerVerticalFaces   }
				else if (connectivity.name == "bottomFaces")          { return geometry.bottomFacesNumber }
				else if (connectivity.name == "topFaces")             { return geometry.topFacesNumber    }
				else if (connectivity.name == "rightFaces")           { return geometry.rightFacesNumber  }
				else if (connectivity.name == "leftFaces")            { return geometry.leftFacesNumber   }
				else if (connectivity.name == "innerFaces")           { return geometry.innerFacesNumber  }
				else if (connectivity.name == "outerFaces")           { return geometry.outerFacesNumber  }

				else if (connectivity.name == "faces") { return geometry.facesNumber }
				else if (connectivity.name == "cells") { return geometry.cellsNumber }
				else if (connectivity.name == "nodes") { return geometry.nodesNumber }
				
				else if (connectivity.name == "nodesOfCell") { return geometry.nodesOfCellsNumber }
				else if (connectivity.name == "cellsOfNode") { return geometry.cellsOfNodesNumber }
				
				else {
					/* Panic */
					throw new Exception("Unimplemented repetition evaluation for call to connectivity of type " + connectivity.name)
				}
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