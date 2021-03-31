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

import fr.cea.nabla.ir.Utils
import fr.cea.nabla.ir.ir.IrModule
import org.eclipse.xtend.lib.annotations.Data

import static extension fr.cea.nabla.ir.IrModuleExtensions.*
import static extension fr.cea.nabla.ir.IrRootExtensions.*
import static extension fr.cea.nabla.ir.generator.cpp.CppGeneratorUtils.*
import fr.cea.nabla.ir.ir.ItemIdValueIterator

@Data
class MainContentProvider
{
	val extension JsonContentProvider jsonContentProvider

	def getContentFor(IrModule it, String levelDBPath)
	'''
		string dataFile;

		if (argc == 2)
		{
			dataFile = argv[1];
		}
		else
		{
			std::cerr << "[ERROR] Wrong number of arguments. Expecting 1 arg: dataFile." << std::endl;
			std::cerr << "(«irRoot.name».json)" << std::endl;
			return -1;
		}

		// read json dataFile
		ifstream ifs(dataFile);
		rapidjson::IStreamWrapper isw(ifs);
		rapidjson::Document d;
		d.ParseStream(isw);
		assert(d.IsObject());

		// Mesh instanciation
		«meshClassName»Factory meshFactory;
		if (d.HasMember("mesh"))
		{
			rapidjson::StringBuffer strbuf;
			rapidjson::Writer<rapidjson::StringBuffer> writer(strbuf);
			d["mesh"].Accept(writer);
			meshFactory.jsonInit(strbuf.GetString());
		}
		«meshClassName»* mesh = meshFactory.create();
		«getPartitionCreation()»

		// Module instanciation(s)
		«FOR m : irRoot.modules»
			«m.instanciation»
		«ENDFOR»

		«getSimulationCall(it)»
		«IF !levelDBPath.nullOrEmpty»
			«val nrName = Utils.NonRegressionNameAndValue.key»
			«val dbName = irRoot.name + "DB"»
			// Non regression testing
			if («name»Options.«nrName» == "«Utils.NonRegressionValues.CreateReference.toString»")
				«name»->createDB("«dbName».ref");
			if («name»Options.«nrName» == "«Utils.NonRegressionValues.CompareToReference.toString»") {
				«name»->createDB("«dbName».current");
				if (!compareDB("«dbName».current", "«dbName».ref"))
					ret = 1;
				leveldb::DestroyDB("«dbName».current", leveldb::Options());
			}
		«ENDIF»

		«FOR m : irRoot.modules.reverseView»
			delete «m.name»;
		«ENDFOR»
		«getPartitionDestruction()»
		delete mesh;
	'''

	private def getInstanciation(IrModule it)
	'''
		«className»::Options «name»Options;
		if (d.HasMember("«name»"))
		{
			rapidjson::StringBuffer strbuf;
			rapidjson::Writer<rapidjson::StringBuffer> writer(strbuf);
			d["«name»"].Accept(writer);
			«name»Options.jsonInit(strbuf.GetString());
		}
		«className»* «name» = new «className»(mesh, «name»Options);
		«IF !main»«name»->setMainModule(«irRoot.mainModule.name»);«ENDIF»
	'''
	
	protected def getPartitionCreation(IrModule it) ''''''
	protected def getPartitionDestruction(IrModule it) ''''''

	protected def getSimulationCall(IrModule it)
	'''
	// Start simulation
	// Simulator must be a pointer when a finalize is needed at the end (Kokkos, omp...)
	«name»->simulate();
	'''
}

@Data
class OpenMpTaskMainContentProvider extends MainContentProvider
{
	override protected getPartitionCreation(IrModule it)
	'''
		/* Global variable for the partitions */
		CartesianPartition2D<«OMPTaskMaxNumber», «OMPTaskMaxNumber»>::setMaxDataShift(«eAllContents.filter(ItemIdValueIterator).map[shift].max»);
		___partition = new CartesianPartition2D<«OMPTaskMaxNumber», «OMPTaskMaxNumber»>(meshFactory.nbXQuads, meshFactory.nbYQuads, mesh);
	'''
	
	override protected getPartitionDestruction(IrModule it)
	'''
		delete ___partition;
	'''

	override protected getSimulationCall(IrModule it)
	'''
		// Start simulation
		// Simulator must be a pointer when a finalize is needed at the end
		// Wrap the simulate in OMP region => mono producer
		#pragma omp parallel
		{
			#pragma omp single nowait
			{
				«name»->simulate();
			}
		}
	'''
}

@Data
class KokkosMainContentProvider extends MainContentProvider
{
	override getContentFor(IrModule it, String levelDBPath)
	'''
		Kokkos::initialize(argc, argv);
		«super.getContentFor(it, levelDBPath)»
		// simulator must be deleted before calling finalize
		Kokkos::finalize();
	'''
}
