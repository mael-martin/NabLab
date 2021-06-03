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
import fr.cea.nabla.ir.transformers.JobMergeFromCost

@Data
class MainContentProvider
{
	val extension JsonContentProvider jsonContentProvider
	
	protected def boolean
	isGPU()
	{
		return false
	}

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
		«IF isGPU»
		omptarget_device_id = omp_get_default_device();
		omptarget_host_id   = omp_get_initial_device();
		mesh_glb            = N_GPU_ALLOC(GPU_CartesianMesh2D);
		if (omp_get_num_devices() < 1 || omptarget_device_id < 0) {
			puts("ERROR: No device found ¯\(º_o)/¯");
			exit(1);
		}
		GPU_«meshClassName»_alloc(mesh_glb, mesh);
		«ENDIF»

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
		«IF isGPU»
		GPU_«meshClassName»_free(mesh_glb);
		N_GPU_FREE(mesh_glb);
		«ENDIF»
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
	public static int num_threads       = JobMergeFromCost.num_threads;
	public static int max_active_levels = 1;

	protected override boolean
	isGPU()
	{
		return true
	}
	
	protected override getSimulationCall(IrModule it)
	'''
	// setenv("OMP_PROC_BIND", "true", 1); // <- do nothing, set the env before calling the executable
	omp_set_num_threads(«num_threads»);
	«name»->simulate();
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
