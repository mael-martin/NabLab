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

import fr.cea.nabla.ir.ir.ArgOrVarRef
import fr.cea.nabla.ir.ir.BaseType
import fr.cea.nabla.ir.ir.BaseTypeConstant
import fr.cea.nabla.ir.ir.BinaryExpression
import fr.cea.nabla.ir.ir.BoolConstant
import fr.cea.nabla.ir.ir.Cardinality
import fr.cea.nabla.ir.ir.ContractedIf
import fr.cea.nabla.ir.ir.Expression
import fr.cea.nabla.ir.ir.FunctionCall
import fr.cea.nabla.ir.ir.IntConstant
import fr.cea.nabla.ir.ir.MaxConstant
import fr.cea.nabla.ir.ir.MinConstant
import fr.cea.nabla.ir.ir.Parenthesis
import fr.cea.nabla.ir.ir.PrimitiveType
import fr.cea.nabla.ir.ir.RealConstant
import fr.cea.nabla.ir.ir.UnaryExpression
import fr.cea.nabla.ir.ir.VectorConstant
import fr.cea.nabla.ir.ir.Job
import static extension fr.cea.nabla.ir.ArgOrVarExtensions.*
import static extension fr.cea.nabla.ir.ContainerExtensions.*
import static extension fr.cea.nabla.ir.IrTypeExtensions.*
import static extension fr.cea.nabla.ir.Utils.*
import static extension fr.cea.nabla.ir.generator.Utils.*
import static extension fr.cea.nabla.ir.generator.cpp.CppGeneratorUtils.*
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.EcoreUtil2
import java.util.HashMap

@Data
class ExpressionContentProvider
{
	val extension TypeContentProvider typeContentProvider

	new(TypeContentProvider typeContentProvider)
	{
		this.typeContentProvider = typeContentProvider
		this.typeContentProvider.expressionContentProvider = this
	}

	def dispatch CharSequence getContent(ContractedIf it) 
	'''(«condition.content» ? «thenExpression.content» ':' «elseExpression.content»'''

	def dispatch CharSequence getContent(BinaryExpression it) 
	{
		val lContent = left.content
		val rContent = right.content
		'''«lContent» «operator» «rContent»'''
	}

	def dispatch CharSequence getContent(UnaryExpression it) '''«operator»«expression.content»'''
	def dispatch CharSequence getContent(Parenthesis it) '''(«expression.content»)'''
	def dispatch CharSequence getContent(IntConstant it) '''«value»'''
	def dispatch CharSequence getContent(RealConstant it) '''«value»'''
	def dispatch CharSequence getContent(BoolConstant it) '''«value»'''

	def dispatch CharSequence getContent(MinConstant it)
	{
		val t = type
		switch t
		{
			case (t.scalar && t.primitive == PrimitiveType::INT): '''numeric_limits<int>::min()'''
			// Be careful at MIN_VALUE which is a positive value for double.
			case (t.scalar && t.primitive == PrimitiveType::REAL): '''-numeric_limits<double>::max()'''
			default: throw new Exception('Invalid expression Min for type: ' + t.label)
		}
	}

	def dispatch CharSequence getContent(MaxConstant it)
	{
		val t = type
		switch t
		{
			case (t.scalar && t.primitive == PrimitiveType::INT): '''numeric_limits<int>::max()'''
			case (t.scalar && t.primitive == PrimitiveType::REAL): '''numeric_limits<double>::max()'''
			default: throw new Exception('Invalid expression Max for type: ' + t.label)
		}
	}

	def dispatch CharSequence getContent(BaseTypeConstant it)
	{
		val t = type as BaseType

		if (t.sizes.exists[x | !(x instanceof IntConstant)])
			throw new RuntimeException("BaseTypeConstants size expressions must be IntConstant.")

		val sizes = t.sizes.map[x | (x as IntConstant).value]
		'''{«initArray(sizes, value.content)»}'''
	}

	def dispatch CharSequence getContent(VectorConstant it)
	'''{«innerContent»}'''

	def dispatch CharSequence getContent(Cardinality it)
	{
		val call = container.connectivityCall
		if (call.connectivity.multiple)
		{
			if (call.args.empty)
				call.connectivity.nbElemsVar
			else
				'''mesh->«call.accessor».size()'''
		}
		else
			'''1'''
	}

	def dispatch CharSequence getContent(FunctionCall it)
	{
		if (function.name == 'solveLinearSystem')
			switch (args.length)
			{
				// 2 args means no precond, everything default
				case 2: '''«function.codeName»(«args.get(0).content», «args.get(1).content»)'''
				// 3 args either means no precond with x0, or precond without x0
				case 3: '''«function.codeName»(«args.get(0).content», «args.get(1).content», «args.get(2).cppLinearAlgebraHelper»)'''
				// 4 args either means no precond with x0 and iteration threshold, or precond with x0
				case 4: '''«function.codeName»(«args.get(0).content», «args.get(1).content», «args.get(2).cppLinearAlgebraHelper», «args.get(3).cppLinearAlgebraHelper»)'''
				// 5 args either no precond with everything, or precond with x0 and iteration threshold
				case 5: '''«function.codeName»(«args.get(0).content», «args.get(1).content», «args.get(2).cppLinearAlgebraHelper», «args.get(3).cppLinearAlgebraHelper», «args.get(4).content»)'''
				// 6 args means precond with everything
				case 6: '''«function.codeName»(«args.get(0).content», «args.get(1).content», «args.get(2).content», «args.get(3).cppLinearAlgebraHelper», «args.get(4).content», «args.get(5).content»)'''
				default: throw new RuntimeException("Wrong numbers of arguments for solveLinearSystem")
			}
		else
			'''«function.codeName»(«FOR a:args SEPARATOR ', '»«a.content»«ENDFOR»)'''
	}

	def dispatch CharSequence getContent(ArgOrVarRef it)
	{
		if (target.linearAlgebra && !(iterators.empty && indices.empty))
			'''«codeName».getValue(«formatIteratorsAndIndices(target.type, iterators, indices)»)'''
		else
			'''«codeName»«formatIteratorsAndIndices(target.type, iterators, indices)»'''
	}

	def CharSequence getCodeName(ArgOrVarRef it)
	{
		if (irModule === target.irModule) target.codeName
		else 'mainModule->' + target.codeName
	}

	private def dispatch CharSequence getInnerContent(Expression it) { content }
	private def dispatch CharSequence getInnerContent(VectorConstant it)
	'''«FOR v : values SEPARATOR ', '»«v.innerContent»«ENDFOR»'''

	private def CharSequence initArray(int[] sizes, CharSequence value)
	'''«FOR size : sizes SEPARATOR ",  "»«FOR i : 0..<size SEPARATOR ', '»«value»«ENDFOR»«ENDFOR»'''

	// Simple helper to add pointer information to VectorType variable for LinearAlgebra cases
	private def getCppLinearAlgebraHelper(Expression expr) 
	{
		switch expr.type.dimension
		{
			case 1: '&' + expr.content
			default: expr.content
		}
	}
}

@Data
class OpenMpTaskExpressionContentProvider extends ExpressionContentProvider
{
	val extension TypeContentProvider typeContentProvider = super.typeContentProvider
	
	static val HashMap<String, String> IndexTypeToIdPartition = new HashMap();
	static def void registerPartitionIdForIndexType(String INDEX_TYPE, String partitionId)
	{
		IndexTypeToIdPartition.put(INDEX_TYPE, partitionId)
	}

	override dispatch CharSequence getContent(ArgOrVarRef it)
	{
		if (target.linearAlgebra && !(iterators.empty && indices.empty))
			'''«codeName».getValue(«formatIteratorsAndIndices(target.type, iterators, indices)»)'''
		else
			'''«codeName»«formatIteratorsAndIndices(target.type, iterators, indices)»'''
	}

	override CharSequence getCodeName(ArgOrVarRef it)
	{
		val insideJob        = EcoreUtil2.getContainerOfType(it, Job) !== null
		val index_type       = getGlobalVariableType(target.codeName);
		val partition_prefix = '''partitions[«IndexTypeToIdPartition.get(index_type.toString)»].'''
		if (index_type == INDEX_TYPE::NULL || !insideJob) {
			super.getCodeName(it)
		}
		
		else if (irModule === target.irModule) '''«partition_prefix»«target.codeName»'''
		else '''«partition_prefix»mainModule->«target.codeName»'''
	}
}