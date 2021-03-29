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
import java.util.stream.IntStream
import java.util.Iterator
import java.util.List

class CppGeneratorUtils
{
	def static <T>Iterable<T> iteratorToIterable(Iterator<T> iterator) { [iterator] }

	static def getFreeFunctionNs(IrModule it) { className.toLowerCase + "freefuncs" }
	static def dispatch getCodeName(InternFunction it) { irModule.freeFunctionNs + '::' + name }
	static def getHDefineName(String name) { '__' + name.toUpperCase + '_H_' }
	static def getOMPTaskMaxNumber() { return 10; /* FIXME: Need to be given from the NGEN file */ }
	static def getOMPSideTaskNumber() { return Math::floor(Math::sqrt(OMPTaskMaxNumber)).intValue(); }

	enum DIRECTION_2D {
		NORTH,
		SOUTH,
		WEST,
		EAST
	}
	
	static def DIRECTION_2D_ALL() { return #[DIRECTION_2D::NORTH, DIRECTION_2D::SOUTH, DIRECTION_2D::WEST, DIRECTION_2D::EAST]; }
	static def DIRECTION_2D_CPPNAME(DIRECTION_2D dir)
	{
		switch (dir)
		{
			case NORTH: return '''CSR_2D_Direction::NORTH'''
			case SOUTH: return '''CSR_2D_Direction::SOUTH'''
			case WEST:  return '''CSR_2D_Direction::WEST'''
			case EAST:  return '''CSR_2D_Direction::EAST'''
		}
	}
	
	
	static public boolean OMPTraces = false /* FIXME: Need to be given from the NGEN file */

	static def dispatch getCodeName(ExternFunction it)
	{
		if (provider.extensionName == "Math") 'std::' + name
		else 'options.' + provider.instanceName + '.' + name
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
	static def getDependenciesAll(String inout, Iterable<Variable> deps, int fromTask, int taskLimit)
	{
		if (deps.length != 0)
		{
			val range = IntStream.range(fromTask, taskLimit).toArray
			''' depend(«inout»: «
			FOR v : deps SEPARATOR ', '»«
				IF v.isVariableRange»«FOR i : range SEPARATOR ', '»«getVariableName(v)»«getVariableRange(v, i.toString)»«ENDFOR»«
				ELSE»«getVariableName(v)»«
				ENDIF»«
			ENDFOR»)'''
		}
		else ''''''
	}
	static def getDependencies(String inout, Iterable<Variable> deps, CharSequence taskPartition, List<DIRECTION_2D> directions)
	{
		if (deps.length != 0) {
			var ret = getDependencies(inout, deps, taskPartition)
			for (dir : directions) {
				ret = '''«ret» depend(«inout»: «FOR v : deps SEPARATOR ', '»«getVariableName(v)»«getVariableRange(v, taskPartition, dir)»«ENDFOR»)'''
			}
		return ret;
		}
		else ''''''
	}
	static def getDependencies(String inout, Iterable<Variable> deps, CharSequence taskPartition)
	{
		if (deps.length != 0) ''' depend(«inout»: «FOR v : deps SEPARATOR ', '»«getVariableName(v)»«getVariableRange(v, taskPartition)»«ENDFOR»)'''
		else ''''''
	}
	
	static def getLoopRange(CharSequence connectivityType, CharSequence taskCurrent) '''___partition->RANGE_«connectivityType»FromPartition(«taskCurrent»)'''
	
	static def getVariableRange(Variable it, CharSequence taskCurrent) { getVariableRange(it, taskCurrent, null) }
	static def getVariableRange(Variable it, CharSequence taskCurrent, DIRECTION_2D dir)
	{
		val neighbor = dir === null ? '''''' : ''', «DIRECTION_2D_CPPNAME(dir)»'''
		val type = (it as ArgOrVar).type;
		switch (type) {
			ConnectivityType: {
				val connectivites = (type as ConnectivityType).connectivities.map[name].head;
				return '''[___partition->PIN_«connectivites»FromPartition(«taskCurrent»«neighbor»)]'''
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
