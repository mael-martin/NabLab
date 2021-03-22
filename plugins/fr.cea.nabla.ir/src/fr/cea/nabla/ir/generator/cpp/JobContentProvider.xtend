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

import fr.cea.nabla.ir.ir.BaseType
import fr.cea.nabla.ir.ir.ConnectivityType
import fr.cea.nabla.ir.ir.ExecuteTimeLoopJob
import fr.cea.nabla.ir.ir.InstructionJob
import fr.cea.nabla.ir.ir.Job
import fr.cea.nabla.ir.ir.LinearAlgebraType
import fr.cea.nabla.ir.ir.TimeLoopCopy
import fr.cea.nabla.ir.ir.ArgOrVar
import fr.cea.nabla.ir.ir.TimeLoopJob
import fr.cea.nabla.ir.ir.Variable
import java.util.ArrayList
import java.util.List
import java.util.stream.IntStream
import org.eclipse.xtend.lib.annotations.Data

import static extension fr.cea.nabla.ir.IrModuleExtensions.*
import static extension fr.cea.nabla.ir.JobCallerExtensions.*
import static extension fr.cea.nabla.ir.JobExtensions.*
import static extension fr.cea.nabla.ir.Utils.*
import static extension fr.cea.nabla.ir.generator.Utils.*
import static extension fr.cea.nabla.ir.generator.cpp.CppGeneratorUtils.*

@Data
abstract class JobContentProvider
{
	protected val TraceContentProvider traceContentProvider
	protected val extension ExpressionContentProvider
	protected val extension InstructionContentProvider
	protected val extension JobCallerContentProvider

	protected def abstract CharSequence copyConnectivityType(String leftName, String rightName, int dimension, List<CharSequence> indexNames)

	def getDeclarationContent(Job it)
	'''
		void «codeName»() noexcept;'''

	def getDefinitionContent(Job it)
	'''
		«comment»
		void «irModule.className»::«codeName»() noexcept
		{
			«innerContent»
		}
	'''

	protected def dispatch CharSequence getInnerContent(InstructionJob it)
	'''
		«instruction.innerContent»
	'''

	protected def dispatch CharSequence getInnerContent(ExecuteTimeLoopJob it)
	'''
		«callsHeader»
		«val itVar = iterationCounter.codeName»
		«itVar» = 0;
		bool continueLoop = true;
		do
		{
			«IF caller.main»
			globalTimer.start();
			cpuTimer.start();
			«ENDIF»
			«itVar»++;
			«val ppInfo = irRoot.postProcessing»
			«IF caller.main && ppInfo !== null»
				if (!writer.isDisabled() && «ppInfo.periodReference.codeName» >= «ppInfo.lastDumpVariable.codeName» + «ppInfo.periodValue.codeName»)
					dumpVariables(«itVar»);
			«ENDIF»
			«traceContentProvider.getBeginOfLoopTrace(irModule, itVar, caller.main)»

			«callsContent»

			// Evaluate loop condition with variables at time n
			continueLoop = («whileCondition.content»);

			if (continueLoop)
			{
				// Switch variables to prepare next iteration
				«FOR copy : copies»
					std::swap(«copy.source.name», «copy.destination.name»);
				«ENDFOR»
			}
			«IF caller.main»

			cpuTimer.stop();
			globalTimer.stop();
			«ENDIF»

			«traceContentProvider.getEndOfLoopTrace(irModule, itVar, caller.main, (ppInfo !== null))»

			«IF caller.main»
			cpuTimer.reset();
			ioTimer.reset();
			«ENDIF»
		} while (continueLoop);
		«IF caller.main && irRoot.postProcessing !== null»
			// force a last output at the end
			dumpVariables(«itVar», false);
		«ENDIF»
	'''

	protected def dispatch CharSequence getInnerContent(TimeLoopJob it)
	'''
		«FOR c  : copies»
			«c.content»
		«ENDFOR»
	'''

	protected def getContent(TimeLoopCopy it)
	{
		// c.destination.type == c.source.type
		val t = source.type
		switch t
		{
			BaseType: copyBaseType(destination.name, source.name, t.sizes.size, new ArrayList<CharSequence>())
			ConnectivityType: copyConnectivityType(destination.name, source.name, t.connectivities.size + t.base.sizes.size, new ArrayList<CharSequence>())
			LinearAlgebraType: copyLinearAlgebraType(destination.name, source.name, t.sizes.size, new ArrayList<CharSequence>())
		}
	}

	protected def CharSequence copyBaseType(String leftName, String rightName, int dimension, List<CharSequence> indexNames)
	{
		if (dimension == 0)
			'''«leftName»«FOR i : indexNames»[«i»]«ENDFOR» = «rightName»«FOR i : indexNames»[«i»]«ENDFOR»;'''
		else
		{
			val length = '''«leftName»«FOR i : indexNames»[«i»]«ENDFOR».size()'''
			var indexName = '''i«indexNames.size + 1»'''
			indexNames += indexName
			'''
				for (size_t «indexName»(0) ; «indexName»<«length» ; «indexName»++)
					«copyBaseType(leftName, rightName, dimension-1, indexNames)»
			'''
		}
	}

	protected def CharSequence copyLinearAlgebraType(String leftName, String rightName, int dimension, List<CharSequence> indexNames)
	{
		if (dimension == 0)
			'''«leftName».setValue(«FOR i : indexNames SEPARATOR ', '»«i»«ENDFOR», «rightName».getValue(«FOR i : indexNames SEPARATOR ', '»«i»«ENDFOR»));'''
		else
		{
			val length = '''«leftName»«FOR i : indexNames BEFORE '.getValue(' SEPARATOR ', ' AFTER ')'»«i»«ENDFOR».getSize()'''
			var indexName = '''i«indexNames.size + 1»'''
			indexNames += indexName
			'''
				for (size_t «indexName»(0) ; «indexName»<«length» ; «indexName»++)
					«copyLinearAlgebraType(leftName, rightName, dimension-1, indexNames)»
			'''
		}
	}
}

@Data
class StlThreadJobContentProvider extends JobContentProvider
{
	override protected copyConnectivityType(String leftName, String rightName, int dimension, List<CharSequence> indexNames)
	{
		copyBaseType(leftName, rightName, dimension, indexNames)
	}
}

@Data
class OpenMpTaskJobContentProvider extends JobContentProvider
{
	override protected copyConnectivityType(String leftName, String rightName, int dimension, List<CharSequence> indexNames)
	{
		copyBaseType(leftName, rightName, dimension, indexNames)
	}

	override protected dispatch CharSequence getInnerContent(TimeLoopJob it)
	{
		val ins  = copies.map[source]
		val outs = copies.map[destination]
		'''
			/* INS: «FOR n : ins.map[name] SEPARATOR ", "»«n»«ENDFOR»
			 * OUTS: «FOR n : outs.map[name] SEPARATOR ", "»«n»«ENDFOR»
			 */
			#pragma omp task«getDependenciesAll('in', ins, 0, OMPTaskMaxNumber)»«getDependenciesAll('out', outs, 0, OMPTaskMaxNumber)»
			{
			«FOR c : copies»
				«c.content»
			«ENDFOR»
			}
		'''
	}

	/* FIXME: Duplicated utility functions (see InstructionContentProvider.xtend) */
	private def getVariableName(Variable it) { isOption ? '''options.«name»''' : '''this->«name»''' }
	private def isVariableRange(Variable it)
	{
		val type = (it as ArgOrVar).type;
		switch (type) {
			ConnectivityType: return true
			default: return false
		}
	}
	private def getVariableRange(Variable it, CharSequence taskCurrent, CharSequence taskLimit)
	{
		val type = (it as ArgOrVar).type;
		switch (type) {
			ConnectivityType: {
				val connectivites = (type as ConnectivityType).connectivities.map[name];
				val cppname       = getVariableName;
				val depInferior   = '''«cppname».size()*(«taskCurrent»)/(«taskLimit»)'''
				// val depSuperior   = '''«cppname».size()*(«taskCurrent»+1)/(«taskLimit»)'''
				return '''[«depInferior»]/*«connectivites»*/'''
			}
			LinearAlgebraType: return '''''' /* This is an opaque type, don't know what to do with it */
			BaseType: return '''''' /* An integer, etc => the name is the dependency */
			default: return '''''' /* Don't know => pin all the variable */
		}
	}
	def getDependenciesAll(String inout, Iterable<Variable> deps, int fromTask, int taskLimit)
	{
		if (deps.length != 0)
		{
			val range = IntStream.range(fromTask, taskLimit).toArray
			''' depend(«inout»: «
			FOR v : deps SEPARATOR ', '»«
				IF v.isVariableRange»«FOR i : range SEPARATOR ', '»«getVariableName(v)»«getVariableRange(v, i.toString, taskLimit.toString)»«ENDFOR»«
				ELSE»«getVariableName(v)»«ENDIF»«
			ENDFOR»)'''
		}
		else ''''''
	}
}

@Data
class KokkosJobContentProvider extends JobContentProvider
{
	override getDeclarationContent(Job it)
	'''
		KOKKOS_INLINE_FUNCTION
		void «codeName»(«FOR a : arguments SEPARATOR ', '»«a»«ENDFOR») noexcept;'''

	override getDefinitionContent(Job it)
	'''
		«comment»
		void «irModule.className»::«codeName»(«FOR a : arguments SEPARATOR ', '»«a»«ENDFOR») noexcept
		{
			«innerContent»
		}
	'''

	protected def List<String> getArguments(Job it) { #[] }

	override protected copyConnectivityType(String leftName, String rightName, int dimension, List<CharSequence> indexNames)
	'''deep_copy(«leftName», «rightName»);'''
}

@Data
class KokkosTeamThreadJobContentProvider extends KokkosJobContentProvider
{
	override getArguments(Job it)
	{
		if (hasIterable) #["const member_type& teamMember"]
		else #[]
	}
}