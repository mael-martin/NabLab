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

import fr.cea.nabla.ir.UnzipHelper
import fr.cea.nabla.ir.Utils
import fr.cea.nabla.ir.generator.ApplicationGenerator
import fr.cea.nabla.ir.generator.GenerationContent
import fr.cea.nabla.ir.ir.BaseType
import fr.cea.nabla.ir.ir.Connectivity
import fr.cea.nabla.ir.ir.ConnectivityType
import fr.cea.nabla.ir.ir.InternFunction
import fr.cea.nabla.ir.ir.IrModule
import fr.cea.nabla.ir.ir.IrRoot
import fr.cea.nabla.ir.ir.LinearAlgebraType
import fr.cea.nabla.ir.ir.Variable
import java.util.ArrayList
import java.util.LinkedHashSet

import static extension fr.cea.nabla.ir.ContainerExtensions.*
import static extension fr.cea.nabla.ir.ExtensionProviderExtensions.*
import static extension fr.cea.nabla.ir.IrModuleExtensions.*
import static extension fr.cea.nabla.ir.IrRootExtensions.*
import static extension fr.cea.nabla.ir.IrTypeExtensions.*
import static extension fr.cea.nabla.ir.generator.Utils.*
import static extension fr.cea.nabla.ir.generator.cpp.CppGeneratorUtils.*
import java.util.stream.IntStream

class CppApplicationGenerator extends CppGenerator implements ApplicationGenerator
{
	val String levelDBPath
	val cMakeVars = new LinkedHashSet<Pair<String, String>>
	public static var boolean createPartitions = false

	new(Backend backend, String wsPath, String levelDBPath, Iterable<Pair<String, String>> cMakeVars)
	{
		super(backend)
		this.levelDBPath = levelDBPath
		cMakeVars.forEach[x | this.cMakeVars += x]

		// Set WS_PATH variables in CMake and unzip NRepository if necessary
		this.cMakeVars += new Pair(CMakeContentProvider.WS_PATH, wsPath)
		UnzipHelper::unzipNRepository(wsPath)
	}

	override getGenerationContents(IrRoot ir)
	{
		ir.modules.filter[t|t!==null].forEach[registerGlobalVariable]
		val fileContents = new ArrayList<GenerationContent>
		for (module : ir.modules)
		{
			fileContents += new GenerationContent(module.className + '.h', module.headerFileContent, false)
			fileContents += new GenerationContent(module.className + '.cc', module.sourceFileContent, false)
		}
		fileContents += new GenerationContent('CMakeLists.txt', backend.cmakeContentProvider.getContentFor(ir, levelDBPath, cMakeVars), false)
		return fileContents
	}

	private def getHeaderFileContent(IrModule it)
	'''
	«fileHeader»

	#ifndef «name.HDefineName»
	#define «name.HDefineName»

	«backend.includesContentProvider.getIncludes(!levelDBPath.nullOrEmpty, (irRoot.postProcessing !== null))»
	«FOR provider : extensionProviders»
	#include "«provider.className».h"
	«ENDFOR»
	«IF !main»
	#include "«irRoot.mainModule.className».h"
	«ENDIF»

	«backend.includesContentProvider.getUsings(!levelDBPath.nullOrEmpty)»
	«IF main && irRoot.modules.size > 1»

		«FOR m : irRoot.modules.filter[x | x !== it]»
			class «m.className»;
		«ENDFOR»
	«ENDIF»
	«val internFunctions = functions.filter(InternFunction)»
	«IF !internFunctions.empty»

	/******************** Free functions declarations ********************/

	namespace «freeFunctionNs»
	{
	«FOR f : internFunctions»
		«functionContentProvider.getDeclarationContent(f)»;
	«ENDFOR»
	}
	«ENDIF»
	«IF createPartitions»

	/******************** Partition declaration ********************/
	
	struct «className»Partition
	{
		/* Global variables that must be placed inside partitions from the «className» class */
		«FOR v : variables.filter[!option].filter[t|typeContentProvider.getCppTypeCanBePartitionized(t.type)]»
			«v.variableDeclaration»
		«ENDFOR»

		«className»Partition() = default;
		~«className»Partition() = default;

		/* Don't move this object around */
		«className»Partition(«className»Partition &&) = delete;
		«className»Partition(const «className»Partition &) = delete;
		«className»Partition& operator=(«className»Partition &) = delete;
	};
	«ENDIF»

	/******************** Module declaration ********************/

	class «className»
	{
		«IF kokkosTeamThread»
		typedef Kokkos::TeamPolicy<Kokkos::DefaultExecutionSpace::scratch_memory_space>::member_type member_type;

		«ENDIF»
		/* Don't move this object around */
		«className»(«className» &&)           = delete;
		«className»(const «className» &)      = delete;
		«className»& operator=(«className» &) = delete;

	public:
		struct Options
		{
			«IF postProcessing !== null»std::string «Utils.OutputPathNameAndValue.key»;«ENDIF»
			«FOR v : options»
			«typeContentProvider.getCppType(v.type)» «v.name»;
			«ENDFOR»
			«FOR v : extensionProviders»
			«v.className» «v.instanceName»;
			«ENDFOR»
			«IF levelDB»std::string «Utils.NonRegressionNameAndValue.key»;«ENDIF»

			void jsonInit(const char* jsonContent);
		};

		«className»(«meshClassName»* aMesh, Options& aOptions);
		~«className»();
		«IF main»
			«IF irRoot.modules.size > 1»

				«FOR adm : irRoot.modules.filter[x | x !== it]»
				inline void set«adm.name.toFirstUpper»(«adm.className»* value) { «adm.name» = value; }
				«ENDFOR»
			«ENDIF»
		«ELSE»

		inline void setMainModule(«irRoot.mainModule.className»* value)
		{
			mainModule = value,
			mainModule->set«name.toFirstUpper»(this);
		}
		«ENDIF»

		void simulate();
		«FOR j : jobs»
		«backend.jobContentProvider.getDeclarationContent(j)»
		«ENDFOR»
		«IF levelDB»void createDB(const std::string& db_name);«ENDIF»

	private:
		«IF OMPTraces»
		unsigned long task_id = 0; /* Used by the OpenMpTaskInstructionProvider */
		«ENDIF»
	
		«IF postProcessing !== null»
		void dumpVariables(int iteration, bool useTimer=true);

		«ENDIF»
		«IF kokkosTeamThread»
		/**
		 * Utility function to get work load for each team of threads
		 * In  : thread and number of element to use for computation
		 * Out : pair of indexes, 1st one for start of chunk, 2nd one for size of chunk
		 */
		const std::pair<size_t, size_t> computeTeamWorkRange(const member_type& thread, const size_t& nb_elmt) noexcept;

		«ENDIF»
		// Mesh and mesh variables
		«meshClassName»* mesh;
		«FOR c : irRoot.connectivities.filter[multiple] BEFORE 'size_t ' SEPARATOR ', '»«c.nbElemsVar»«ENDFOR»;

		// User options
		Options& options;
		«IF postProcessing !== null»PvdFileWriter2D writer;«ENDIF»

		«IF irRoot.modules.size > 1»
			«IF main»
				// Additional modules
				«FOR m : irRoot.modules.filter[x | x !== it]»
					«m.className»* «m.name»;
				«ENDFOR»
			«ELSE»
				// Main module
				«irRoot.mainModule.className»* mainModule;
			«ENDIF»

		«ENDIF»
		// Timers
		Timer globalTimer;
		Timer cpuTimer;
		Timer ioTimer;

	public:
		«globalVariableDeclarations»
	};

	#endif
	'''
	
	/* Get the global variables that will be used in the compute methods */
	private def getGlobalVariableDeclarations(IrModule it)
	{
		if (createPartitions)
		'''
			// Global not partitionable variables
			«FOR v : variables.filter[!option].filter[t|!typeContentProvider.getCppTypeCanBePartitionized(t.type)]»
				«v.variableDeclaration»
			«ENDFOR»

			// Partitions for variables that can be partitionized
			«className»Partition *partitions;
		'''
		
		else
		'''
			// Global variables
			«FOR v : variables.filter[!option]»
				«v.variableDeclaration»
			«ENDFOR»
		'''
		
	}

	private def getSourceFileContent(IrModule it)
	'''
	#define NABLALIB_DEBUG 0
	«fileHeader»

	#include "«className».h"
	#include <rapidjson/document.h>
	#include <rapidjson/istreamwrapper.h>
	#include <rapidjson/stringbuffer.h>
	#include <rapidjson/writer.h>
	«IF main && irRoot.modules.size > 1»
		«FOR m : irRoot.modules.filter[x | x !== it]»
			#include "«m.className».h"
		«ENDFOR»
	«ENDIF»
	
	«IF isOpenMpTask»
	static size_t ___DAG_loops = 0;
	«ENDIF»

	«val internFunctions = functions.filter(InternFunction)»
	«IF !internFunctions.empty»

	/******************** Free functions definitions ********************/

	namespace «freeFunctionNs»
	{
	«FOR f : internFunctions SEPARATOR '\n'»
		«functionContentProvider.getDefinitionContent(f)»
	«ENDFOR»
	}
	«ENDIF»

	/******************** Options definition ********************/

	void
	«className»::Options::jsonInit(const char* jsonContent)
	{
		rapidjson::Document document;
		assert(!document.Parse(jsonContent).HasParseError());
		assert(document.IsObject());
		const rapidjson::Value::Object& o = document.GetObject();

		«IF postProcessing !== null»
		«val opName = Utils.OutputPathNameAndValue.key»
		// «opName»
		assert(o.HasMember("«opName»"));
		const rapidjson::Value& «jsonContentProvider.getJsonName(opName)» = o["«opName»"];
		assert(«jsonContentProvider.getJsonName(opName)».IsString());
		«opName» = «jsonContentProvider.getJsonName(opName)».GetString();
		«ENDIF»
		«FOR v : options»
		«jsonContentProvider.getJsonContent(v.name, v.type as BaseType, v.defaultValue)»
		«ENDFOR»
		«FOR v : extensionProviders»
		«val vName = v.instanceName»
		// «vName»
		if (o.HasMember("«vName»"))
		{
			rapidjson::StringBuffer strbuf;
			rapidjson::Writer<rapidjson::StringBuffer> writer(strbuf);
			o["«vName»"].Accept(writer);
			«vName».jsonInit(strbuf.GetString());
		}
		«ENDFOR»
		«IF levelDB»
		// Non regression
		«val nrName = Utils.NonRegressionNameAndValue.key»
		assert(o.HasMember("«nrName»"));
		const rapidjson::Value& «jsonContentProvider.getJsonName(nrName)» = o["«nrName»"];
		assert(«jsonContentProvider.getJsonName(nrName)».IsString());
		«nrName» = «jsonContentProvider.getJsonName(nrName)».GetString();
		«ENDIF»
	}

	/******************** Module definition ********************/
	
	«className»::~«className»()
	{
		«IF createPartitions»
		/* Delete all partitions */
		for (size_t part = 0; part < «OMPTaskMaxNumber»; ++part)
			(&partitions[part])->~«className»Partition();
		std::free(partitions);
		«ENDIF»
	}

	«className»::«className»(«meshClassName»* aMesh, Options& aOptions)
	: mesh(aMesh)
	«FOR c : irRoot.connectivities.filter[multiple]»
	, «c.nbElemsVar»(«c.connectivityAccessor»)
	«ENDFOR»
	, options(aOptions)
	«IF postProcessing !== null», writer("«irRoot.name»", options.«Utils.OutputPathNameAndValue.key»)«ENDIF»
	«IF ! createPartitions»
		«FOR v : variablesWithDefaultValue.filter[x | !x.constExpr]»
		, «v.name»(«expressionContentProvider.getContent(v.defaultValue)»)
		«ENDFOR»
		«FOR v : variables.filter[needStaticAllocation]»
		, «v.name»(«typeContentProvider.getCstrInit(v.type, v.name)»)
		«ENDFOR»
	«ENDIF»
	{
		«val dynamicArrayVariables = variables.filter[needDynamicAllocation]»
		«IF !dynamicArrayVariables.empty»
			// Allocate dynamic arrays (RealArrays with at least a dynamic dimension)
			#error "Not handled for the moment (OMP Task Backend)"
			«FOR v : dynamicArrayVariables»
				«typeContentProvider.initCppTypeContent(v.name, v.type)»
			«ENDFOR»

		«ENDIF»
		«IF main»
		const auto& gNodes = mesh->getGeometry()->getNodes();
		«IF createPartitions /* FIXME */»
			// FIXME: first touch for NUMA effects
			partitions = («className»Partition *) std::malloc(«meshClassName»::getPartitionNumber() * sizeof(«className»Partition));
			«val iterator = backend.typeContentProvider.formatIterators(irRoot.initNodeCoordVariable.type as ConnectivityType, #["rNodes"])»
			for (size_t part = 0; part < «OMPTaskMaxNumber»; ++part)
			{
				new (&partitions[part]) «className»Partition();
				«FOR v : variablesWithDefaultValue.filter[x | !x.constExpr].filter[typeContentProvider.getCppTypeCanBePartitionized(type)]»
				partitions[part].«v.name» = «typeContentProvider.getCppType(v.type)»(«expressionContentProvider.getContent(v.defaultValue)»);
				«ENDFOR»
				«FOR v : variables.filter[needStaticAllocation].filter[typeContentProvider.getCppTypeCanBePartitionized(type)]»
				partitions[part].«v.name» = «typeContentProvider.getCppType(v.type)»(«typeContentProvider.getCstrInit(v.type, v.name)»);
				«ENDFOR»
				
				// Copy node coordinates
				for (const size_t rNodes : mesh->RANGE_nodesFromPartition(part))
				{
					partitions[part].«irRoot.initNodeCoordVariable.name»«iterator»[0] = gNodes[rNodes][0];
					partitions[part].«irRoot.initNodeCoordVariable.name»«iterator»[1] = gNodes[rNodes][1];
				}
			}
		«ELSE»
			// Copy node coordinates
			«val iterator = backend.typeContentProvider.formatIterators(irRoot.initNodeCoordVariable.type as ConnectivityType, #["rNodes"])»
			for (size_t rNodes=0; rNodes<nbNodes; rNodes++)
			{
				«irRoot.initNodeCoordVariable.name»«iterator»[0] = gNodes[rNodes][0];
				«irRoot.initNodeCoordVariable.name»«iterator»[1] = gNodes[rNodes][1];
			}
			«ENDIF»
		«ENDIF»
	}

	«IF kokkosTeamThread»

	const std::pair<size_t, size_t> «className»::computeTeamWorkRange(const member_type& thread, const size_t& nb_elmt) noexcept
	{
		/*
		if (nb_elmt % thread.team_size())
		{
			std::cerr << "[ERROR] nb of elmt (" << nb_elmt << ") not multiple of nb of thread per team ("
		              << thread.team_size() << ")" << std::endl;
			std::terminate();
		}
		*/
		// Size
		size_t team_chunk(std::floor(nb_elmt / thread.league_size()));
		// Offset
		const size_t team_offset(thread.league_rank() * team_chunk);
		// Last team get remaining work
		if (thread.league_rank() == thread.league_size() - 1)
		{
			size_t left_over(nb_elmt - (team_chunk * thread.league_size()));
			team_chunk += left_over;
		}
		return std::pair<size_t, size_t>(team_offset, team_chunk);
	}
	«ENDIF»

	«FOR j : jobs SEPARATOR '\n'»
		«backend.jobContentProvider.getDefinitionContent(j)»
	«ENDFOR»
	«IF main»
	«IF postProcessing !== null»

	void «className»::dumpVariables(int iteration, bool useTimer)
	{
		if (!writer.isDisabled())
		{
			if (useTimer)
			{
				cpuTimer.stop();
				ioTimer.start();
			}
			auto quads = mesh->getGeometry()->getQuads();
			«IF createPartitions»
				«val coo_var_name = irRoot.nodeCoordVariable.name»
				«val coo_var_type = irRoot.nodeCoordVariable.type»
				«typeContentProvider.getCppType(coo_var_type)» «coo_var_name» = «typeContentProvider.getCppType(coo_var_type)»(«typeContentProvider.getCstrInit(coo_var_type, coo_var_name)»);
				«FOR i : iteratorToIterable(IntStream.range(0, OMPTaskMaxNumber).iterator)»
					«val index_type = "nodes"»
					for (const size_t index : mesh->RANGE_«index_type»FromPartition(«i»)) «coo_var_name»[index] = partitions[«i»].«coo_var_name»[index];
				«ENDFOR»
			«ENDIF»
			writer.startVtpFile(iteration, «irRoot.timeVariable.name», nbNodes, «irRoot.nodeCoordVariable.name».data(), nbCells, quads.data());
			«val outputVarsByConnectivities = irRoot.postProcessing.outputVariables.groupBy(x | x.support.name)»
			writer.openNodeData();
			«val nodeVariables = outputVarsByConnectivities.get("node")»
			«IF !nodeVariables.nullOrEmpty»
				«FOR v : nodeVariables»
				{
					«IF createPartitions»
					«typeContentProvider.getCppType(v.target.type)» «v.target.name» = «typeContentProvider.getCppType(v.target.type)»(«typeContentProvider.getCstrInit(v.target.type, v.target.name)»);
					«val node_var_name = v.target.name»
					«FOR i : iteratorToIterable(IntStream.range(0, OMPTaskMaxNumber).iterator)»
						for (const size_t index : mesh->RANGE_cellsFromPartition(«i»)) «node_var_name»[index] = partitions[«i»].«node_var_name»[index];
					«ENDFOR»
					«ENDIF»
					writer.openNodeArray("«v.outputName»", «v.target.type.sizesSize»);
					for (size_t i=0 ; i<nbNodes ; ++i)
						writer.write(«v.target.writeCallContent»);
					writer.closeNodeArray();
				}
				«ENDFOR»
			«ENDIF»
			writer.closeNodeData();
			writer.openCellData();
			«val cellVariables = outputVarsByConnectivities.get("cell")»
			«IF !cellVariables.nullOrEmpty»
				«FOR v : cellVariables»
				{
					«IF createPartitions»
					«val node_var_name = v.target.name»
					«typeContentProvider.getCppType(v.target.type)» «node_var_name» = «typeContentProvider.getCppType(v.target.type)»(«typeContentProvider.getCstrInit(v.target.type, node_var_name)»);
					«FOR i : iteratorToIterable(IntStream.range(0, OMPTaskMaxNumber).iterator)»
						for (const size_t index : mesh->RANGE_nodesFromPartition(«i»)) «node_var_name»[index] = partitions[«i»].«node_var_name»[index];
					«ENDFOR»
					«ENDIF»
					writer.openCellArray("«v.outputName»", «v.target.type.sizesSize»);
					for (size_t i=0 ; i<nbCells ; ++i)
						writer.write(«v.target.writeCallContent»);
					writer.closeCellArray();
				}
				«ENDFOR»
			«ENDIF»
			writer.closeCellData();
			writer.closeVtpFile();
			«postProcessing.lastDumpVariable.name» = «postProcessing.periodReference.name»;
			if (useTimer)
			{
				ioTimer.stop();
				cpuTimer.start();
			}
		}
	}
	«ENDIF»

	void «className»::«irRoot.main.codeName»()
	{
		«backend.traceContentProvider.getBeginOfSimuTrace(it)»

		«jobCallerContentProvider.getCallsHeader(irRoot.main)»
		«jobCallerContentProvider.getCallsContent(irRoot.main)»
		«backend.traceContentProvider.getEndOfSimuTrace(linearAlgebra)»
	}
	
	«IF levelDB»

	void «className»::createDB(const std::string& db_name)
	{
		// Creating data base
		leveldb::DB* db;
		leveldb::Options options;
		options.create_if_missing = true;
		leveldb::Status status = leveldb::DB::Open(options, db_name, &db);
		assert(status.ok());
		// Batch to write all data at once
		leveldb::WriteBatch batch;
		«FOR v : irRoot.variables.filter[!option]»
		batch.Put("«v.dbKey»", serialize(«getDbValue(it, v, '->')»));
		«ENDFOR»
		status = db->Write(leveldb::WriteOptions(), &batch);
		// Checking everything was ok
		assert(status.ok());
		std::cerr << "Reference database " << db_name << " created." << std::endl;
		// Freeing memory
		delete db;
	}

	/******************** Non regression testing ********************/

	bool compareDB(const std::string& current, const std::string& ref)
	{
		// Final result
		bool result = true;

		// Loading ref DB
		leveldb::DB* db_ref;
		leveldb::Options options_ref;
		options_ref.create_if_missing = false;
		leveldb::Status status = leveldb::DB::Open(options_ref, ref, &db_ref);
		if (!status.ok())
		{
			std::cerr << "No ref database to compare with ! Looking for " << ref << std::endl;
			return false;
		}
		leveldb::Iterator* it_ref = db_ref->NewIterator(leveldb::ReadOptions());

		// Loading current DB
		leveldb::DB* db;
		leveldb::Options options;
		options.create_if_missing = false;
		status = leveldb::DB::Open(options, current, &db);
		assert(status.ok());
		leveldb::Iterator* it = db->NewIterator(leveldb::ReadOptions());

		// Results comparison
		std::cerr << "# Comparing results ..." << std::endl;
		for (it_ref->SeekToFirst(); it_ref->Valid(); it_ref->Next()) {
			auto key = it_ref->key();
			std::string value;
			auto status = db->Get(leveldb::ReadOptions(), key, &value);
			if (status.IsNotFound()) {
				std::cerr << "ERROR - Key : " << key.ToString() << " not found." << endl;
				result = false;
			}
			else {
				if (value == it_ref->value().ToString())
					std::cerr << key.ToString() << ": " << "OK" << std::endl;
				else {
					std::cerr << key.ToString() << ": " << "ERROR" << std::endl;
					result = false;
				}
			}
		}

		// looking for key in the db that are not in the ref (new variables)
		for (it->SeekToFirst(); it->Valid(); it->Next()) {
			auto key = it->key();
			std::string value;
			if (db_ref->Get(leveldb::ReadOptions(), key, &value).IsNotFound()) {
				std::cerr << "ERROR - Key : " << key.ToString() << " can not be compared (not present in the ref)." << std::endl;
				result = false;
			}
		}

		// Freeing memory
		delete db;
		delete db_ref;

		return result;
	}
	«ENDIF»

	int main(int argc, char* argv[]) 
	{
		int ret = EXIT_SUCCESS;
		«backend.mainContentProvider.getContentFor(it, levelDBPath)»
		return ret;
	}
	«ENDIF»
	'''

	private def getConnectivityAccessor(Connectivity c)
	{
		if (c.inTypes.empty)
			'''mesh->getNb«c.name.toFirstUpper»()'''
		else
			'''CartesianMesh2D::MaxNb«c.name.toFirstUpper»'''
	}

	private def isLevelDB(IrModule it)
	{
		main && !levelDBPath.nullOrEmpty
	}

	private def CharSequence getVariableDeclaration(Variable v)
	{
		switch v
		{
			case v.constExpr: '''static constexpr «typeContentProvider.getCppType(v.type)» «v.name» = «expressionContentProvider.getContent(v.defaultValue)»;'''
			case v.const: '''const «typeContentProvider.getCppType(v.type)» «v.name»;'''
			default: '''«typeContentProvider.getCppType(v.type)» «v.name»;'''
		}
	}

	/** BaseType never need explicit static allocation: it is either scalar or MultiArray default cstr */
	private def needStaticAllocation(Variable v)
	{
		!(v.type instanceof BaseType) && typeContentProvider.isBaseTypeStatic(v.type)
	}

	private def needDynamicAllocation(Variable v)
	{
		!typeContentProvider.isBaseTypeStatic(v.type)
	}

	private def isKokkosTeamThread()
	{
		backend instanceof KokkosTeamThreadBackend
	}
	
	private def isOpenMpTask()
	{
		backend instanceof OpenMpTaskBackend
	}

	private def getWriteCallContent(Variable v)
	{
		val t = v.type
		switch t
		{
			ConnectivityType: '''«v.name»«typeContentProvider.formatIterators(t, #["i"])»'''
			LinearAlgebraType: '''«v.name».getValue(i)'''
			default: throw new RuntimeException("Unexpected type: " + class.name)
		}
	}
}