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

import static extension fr.cea.nabla.ir.ExtensionProviderExtensions.getInstanceName
import static extension fr.cea.nabla.ir.IrModuleExtensions.getClassName
import static extension fr.cea.nabla.ir.Utils.getIrModule
import static extension fr.cea.nabla.ir.ArgOrVarExtensions.*
import fr.cea.nabla.ir.ir.ExternFunction
import fr.cea.nabla.ir.ir.InternFunction
import fr.cea.nabla.ir.ir.IrModule
import fr.cea.nabla.ir.ir.IterableInstruction
import fr.cea.nabla.ir.ir.Job
import fr.cea.nabla.ir.ir.ArgOrVarRef
import fr.cea.nabla.ir.ir.Affectation
import fr.cea.nabla.ir.ir.Variable
import fr.cea.nabla.ir.ir.IrPackage
import fr.cea.nabla.ir.ir.ConnectivityType
import fr.cea.nabla.ir.ir.ArgOrVar
import fr.cea.nabla.ir.ir.LinearAlgebraType
import fr.cea.nabla.ir.ir.BaseType
import java.util.Iterator
import fr.cea.nabla.ir.ir.ItemIndex
import java.util.stream.IntStream

class CppGeneratorUtils
{
	def static <T>Iterable<T> iteratorToIterable(Iterator<T> iterator) { [iterator] }

	static def getFreeFunctionNs(IrModule it) { className.toLowerCase + "freefuncs" }
	static def dispatch getCodeName(InternFunction it) { irModule.freeFunctionNs + '::' + name }
	static def getHDefineName(String name) { '__' + name.toUpperCase + '_H_' }
	
	/* FIXME: Those two need to be specified in the NGEN file */
	static public int OMPTaskMaxNumber = 4
	static public boolean OMPTraces = false

	static def dispatch getCodeName(ExternFunction it)
	{
		if (provider.extensionName == "Math") 'std::' + name
		else 'options.' + provider.instanceName + '.' + name
	}
	
	/* Get most used variables in loops and reductions */
	static def getMostUsedVariable(IterableInstruction it)
	{
		val affectations = eAllContents.filter(ArgOrVarRef);
		val targets = affectations.filter(Variable);
		val used = affectations.filter(ItemIndex);
	}

	/* Get variable dependencies and their ranges, etc */
	static def getVariableName(Variable it) { isOption ? '''options.«name»''' : '''this->«name»''' }
	static def isVariableRange(Variable it)
	{
		val type = (it as ArgOrVar).type;
		switch (type) {
			ConnectivityType: return true
			default: return false
		}
	}

	/* Construct OpenMP clauses */
	static def getDependencies(String inout, Iterable<Variable> deps, CharSequence taskPartition, boolean needNeighbors)
	{
		/* Construct the OpenMP clause */
		val dependencies = deps.filter(v|!v.isOption);
		if (dependencies.length == 0) return ''''''

		val dep_ranges  = dependencies.filter(v|v.isVariableRange);
		val dep_simple  = dependencies.filter(v|!v.isVariableRange);
		val need_ranges = dep_ranges.length >= 1;
		val need_simple = dep_simple.length >= 1;
		var ret = ''''''

		/* Only needed for ranges with neighbors */
		val iterator = iteratorToIterable(IntStream.range(0, OMPTaskMaxNumber).iterator)

		/* All ranges, with the neighbors */
		if (need_ranges && needNeighbors)
			ret = ''' depend(«inout»: «FOR v : dep_ranges»«FOR i : iterator SEPARATOR ', '»(«
				getVariableName(v)»«getVariableRange(v, '''«taskPartition», «i»''')»)«ENDFOR»«ENDFOR»)'''
		
		/* All ranges, but without neighbors */
		else if (need_ranges)
			ret = ''' depend(«inout»: «FOR v : dep_ranges SEPARATOR ', '»(«
				getVariableName(v)»«getVariableRange(v, '''«taskPartition»''')»)«ENDFOR»)'''

		/* All simple values */
		if (need_simple)
			ret = '''«ret» depend(«inout»: «FOR v : dep_simple SEPARATOR ', '»(«getVariableName(v)»)«ENDFOR»)'''
		
		return ret
	}

	static def getAffinities(Iterable<Variable> deps, CharSequence taskPartition)
	{
		val dep = deps.filter(v | v.isVariableRange && ! v.isOption) // Simple and stupid algorithm to choose which variable is important
		if (dep.length != 0) ''' affinity(this->«dep.head.name»«getVariableRange(dep.head, taskPartition)»)'''
		else ''''''
	}

	static def getDependenciesAll(String inout, Iterable<Variable> deps, int fromTask, int taskLimit)
	{
		/* Construct the OpenMP clause(s) */
		val dependencies = deps.filter(v|!v.isOption);
		if (dependencies.length == 0) return ''''''

		val dep_ranges  = dependencies.filter(v|v.isVariableRange);
		val dep_simple  = dependencies.filter(v|!v.isVariableRange);
		val need_ranges = dep_ranges.length >= 1;
		val need_simple = dep_simple.length >= 1;
		var ret = ''''''

		if (need_ranges)
		{
			/* All ranges */
			val iterator = iteratorToIterable(IntStream.range(0, OMPTaskMaxNumber).iterator)
			ret = ''' depend(«inout»: «FOR v : dep_ranges»«FOR i : iterator SEPARATOR ', '»(«
			getVariableName(v)»«getVariableRange(v, '''«i»''')»)«ENDFOR»«ENDFOR»)'''
		}

		if (need_simple)
		{
			/* All simple values */
			ret = '''«ret» depend(«inout»: «FOR v : dep_simple SEPARATOR ', '»(«getVariableName(v)»)«ENDFOR»)'''
		}

		return ret
	}
	
	static def getLoopRange(CharSequence connectivityType, CharSequence taskCurrent) '''___partition->RANGE_«connectivityType»FromPartition(«taskCurrent»)'''
	static def getVariableRange(Variable it, CharSequence taskCurrent)
	{
		val type = (it as ArgOrVar).type;
		switch (type) {
			ConnectivityType: {
				val connectivites = (type as ConnectivityType).connectivities.map[name].head;
				return '''[(___partition->PIN_«connectivites»FromPartition(«taskCurrent»))]'''
			}
			LinearAlgebraType: return '''''' /* This is an opaque type, don't know what to do with it */
			BaseType: return '''''' /* An integer, etc => the name is the dependency */
			default: return '''''' /* Don't know => pin all the variable */
		}
	}
	
	/* Get DF */
	static def getInVars(IterableInstruction it) { return eAllContents.filter(ArgOrVarRef).filter[x|x.eContainingFeature != IrPackage::eINSTANCE.affectation_Left].map[target].filter(Variable).filter[global].toSet }
	static def getOutVars(IterableInstruction it) { return eAllContents.filter(Affectation).map[left.target].filter(Variable).filter[global].toSet }
	static def getInVars(Job it) { return eAllContents.filter(ArgOrVarRef).filter[x|x.eContainingFeature != IrPackage::eINSTANCE.affectation_Left].map[target].filter(Variable).filter[global].toSet }
	static def getOutVars(Job it) { return eAllContents.filter(Affectation).map[left.target].filter(Variable).filter[global].toSet }
}
