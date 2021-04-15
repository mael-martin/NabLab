#define NABLALIB_DEBUG 0
#define NABLA_DEBUG 0
/* DO NOT EDIT THIS FILE - it is machine generated */

#include "HeatEquation.h"
#include <rapidjson/document.h>
#include <rapidjson/istreamwrapper.h>
#include <rapidjson/stringbuffer.h>
#include <rapidjson/writer.h>


/******************** Free functions definitions ********************/

namespace heatequationfreefuncs
{
KOKKOS_INLINE_FUNCTION
double det(RealArray1D<2> a, RealArray1D<2> b)
{
	return (a[0] * b[1] - a[1] * b[0]);
}

template<size_t x>
KOKKOS_INLINE_FUNCTION
double norm(RealArray1D<x> a)
{
	return std::sqrt(heatequationfreefuncs::dot(a, a));
}

template<size_t x>
KOKKOS_INLINE_FUNCTION
double dot(RealArray1D<x> a, RealArray1D<x> b)
{
	double result(0.0);
	for (size_t i=0; i<x; i++)
	{
		result = result + a[i] * b[i];
	}
	return result;
}

template<size_t x>
KOKKOS_INLINE_FUNCTION
RealArray1D<x> sumR1(RealArray1D<x> a, RealArray1D<x> b)
{
	return a + b;
}

KOKKOS_INLINE_FUNCTION
double sumR0(double a, double b)
{
	return a + b;
}
}

/******************** Options definition ********************/

void
HeatEquation::Options::jsonInit(const char* jsonContent)
{
	rapidjson::Document document;
	assert(!document.Parse(jsonContent).HasParseError());
	assert(document.IsObject());
	const rapidjson::Value::Object& o = document.GetObject();

	// stopTime
	if (o.HasMember("stopTime"))
	{
		const rapidjson::Value& valueof_stopTime = o["stopTime"];
		assert(valueof_stopTime.IsDouble());
		stopTime = valueof_stopTime.GetDouble();
	}
	else
		stopTime = 0.1;
	// maxIterations
	if (o.HasMember("maxIterations"))
	{
		const rapidjson::Value& valueof_maxIterations = o["maxIterations"];
		assert(valueof_maxIterations.IsInt());
		maxIterations = valueof_maxIterations.GetInt();
	}
	else
		maxIterations = 500;
	// PI
	if (o.HasMember("PI"))
	{
		const rapidjson::Value& valueof_PI = o["PI"];
		assert(valueof_PI.IsDouble());
		PI = valueof_PI.GetDouble();
	}
	else
		PI = 3.1415926;
	// alpha
	if (o.HasMember("alpha"))
	{
		const rapidjson::Value& valueof_alpha = o["alpha"];
		assert(valueof_alpha.IsDouble());
		alpha = valueof_alpha.GetDouble();
	}
	else
		alpha = 1.0;
	// Non regression
	assert(o.HasMember("nonRegression"));
	const rapidjson::Value& valueof_nonRegression = o["nonRegression"];
	assert(valueof_nonRegression.IsString());
	nonRegression = valueof_nonRegression.GetString();
}

/******************** Module definition ********************/

HeatEquation::~HeatEquation()
{
}

HeatEquation::HeatEquation(CartesianMesh2D* aMesh, Options& aOptions)
: mesh(aMesh)
, nbNodes(mesh->getNbNodes())
, nbCells(mesh->getNbCells())
, nbFaces(mesh->getNbFaces())
, nbNeighbourCells(CartesianMesh2D::MaxNbNeighbourCells)
, nbNodesOfFace(CartesianMesh2D::MaxNbNodesOfFace)
, nbNodesOfCell(CartesianMesh2D::MaxNbNodesOfCell)
, options(aOptions)
, X("X", nbNodes)
, center("center", nbCells)
, u_n("u_n", nbCells)
, u_nplus1("u_nplus1", nbCells)
, V("V", nbCells)
, f("f", nbCells)
, outgoingFlux("outgoingFlux", nbCells)
, surface("surface", nbFaces)
{
	const auto& gNodes = mesh->getGeometry()->getNodes();
	// Copy node coordinates
	for (size_t rNodes=0; rNodes<nbNodes; rNodes++)
	{
		X(rNodes)[0] = gNodes[rNodes][0];
		X(rNodes)[1] = gNodes[rNodes][1];
	}
}


/**
 * Job computeOutgoingFlux called @1.0 in executeTimeLoopN method.
 * In variables: V, center, deltat, surface, u_n
 * Out variables: outgoingFlux
 */
void HeatEquation::computeOutgoingFlux() noexcept
{
	Kokkos::parallel_for(nbCells, KOKKOS_LAMBDA(const size_t& j1Cells)
	{
		const Id j1Id(j1Cells);
		double reduction0(0.0);
		{
			const auto neighbourCellsJ1(mesh->getNeighbourCells(j1Id));
			const size_t nbNeighbourCellsJ1(neighbourCellsJ1.size());
			for (size_t j2NeighbourCellsJ1=0; j2NeighbourCellsJ1<nbNeighbourCellsJ1; j2NeighbourCellsJ1++)
			{
				const Id j2Id(neighbourCellsJ1[j2NeighbourCellsJ1]);
				const size_t j2Cells(j2Id);
				const Id cfId(mesh->getCommonFace(j1Id, j2Id));
				const size_t cfFaces(cfId);
				double reduction1((u_n(j2Cells) - u_n(j1Cells)) / heatequationfreefuncs::norm(center(j2Cells) - center(j1Cells)) * surface(cfFaces));
				reduction0 = heatequationfreefuncs::sumR0(reduction0, reduction1);
			}
		}
		outgoingFlux(j1Cells) = deltat / V(j1Cells) * reduction0;
	});
}

/**
 * Job computeSurface called @1.0 in simulate method.
 * In variables: X
 * Out variables: surface
 */
void HeatEquation::computeSurface() noexcept
{
	Kokkos::parallel_for(nbFaces, KOKKOS_LAMBDA(const size_t& fFaces)
	{
		const Id fId(fFaces);
		double reduction0(0.0);
		{
			const auto nodesOfFaceF(mesh->getNodesOfFace(fId));
			const size_t nbNodesOfFaceF(nodesOfFaceF.size());
			for (size_t rNodesOfFaceF=0; rNodesOfFaceF<nbNodesOfFaceF; rNodesOfFaceF++)
			{
				const Id rId(nodesOfFaceF[rNodesOfFaceF]);
				const Id rPlus1Id(nodesOfFaceF[(rNodesOfFaceF+1+nbNodesOfFace)%nbNodesOfFace]);
				const size_t rNodes(rId);
				const size_t rPlus1Nodes(rPlus1Id);
				reduction0 = heatequationfreefuncs::sumR0(reduction0, heatequationfreefuncs::norm(X(rNodes) - X(rPlus1Nodes)));
			}
		}
		surface(fFaces) = 0.5 * reduction0;
	});
}

/**
 * Job computeTn called @1.0 in executeTimeLoopN method.
 * In variables: deltat, t_n
 * Out variables: t_nplus1
 */
void HeatEquation::computeTn() noexcept
{
	t_nplus1 = t_n + deltat;
}

/**
 * Job computeV called @1.0 in simulate method.
 * In variables: X
 * Out variables: V
 */
void HeatEquation::computeV() noexcept
{
	Kokkos::parallel_for(nbCells, KOKKOS_LAMBDA(const size_t& jCells)
	{
		const Id jId(jCells);
		double reduction0(0.0);
		{
			const auto nodesOfCellJ(mesh->getNodesOfCell(jId));
			const size_t nbNodesOfCellJ(nodesOfCellJ.size());
			for (size_t rNodesOfCellJ=0; rNodesOfCellJ<nbNodesOfCellJ; rNodesOfCellJ++)
			{
				const Id rId(nodesOfCellJ[rNodesOfCellJ]);
				const Id rPlus1Id(nodesOfCellJ[(rNodesOfCellJ+1+nbNodesOfCell)%nbNodesOfCell]);
				const size_t rNodes(rId);
				const size_t rPlus1Nodes(rPlus1Id);
				reduction0 = heatequationfreefuncs::sumR0(reduction0, heatequationfreefuncs::det(X(rNodes), X(rPlus1Nodes)));
			}
		}
		V(jCells) = 0.5 * reduction0;
	});
}

/**
 * Job iniCenter called @1.0 in simulate method.
 * In variables: X
 * Out variables: center
 */
void HeatEquation::iniCenter() noexcept
{
	Kokkos::parallel_for(nbCells, KOKKOS_LAMBDA(const size_t& jCells)
	{
		const Id jId(jCells);
		RealArray1D<2> reduction0({0.0, 0.0});
		{
			const auto nodesOfCellJ(mesh->getNodesOfCell(jId));
			const size_t nbNodesOfCellJ(nodesOfCellJ.size());
			for (size_t rNodesOfCellJ=0; rNodesOfCellJ<nbNodesOfCellJ; rNodesOfCellJ++)
			{
				const Id rId(nodesOfCellJ[rNodesOfCellJ]);
				const size_t rNodes(rId);
				reduction0 = heatequationfreefuncs::sumR1(reduction0, X(rNodes));
			}
		}
		center(jCells) = 0.25 * reduction0;
	});
}

/**
 * Job iniF called @1.0 in simulate method.
 * In variables: 
 * Out variables: f
 */
void HeatEquation::iniF() noexcept
{
	Kokkos::parallel_for(nbCells, KOKKOS_LAMBDA(const size_t& jCells)
	{
		f(jCells) = 0.0;
	});
}

/**
 * Job iniTime called @1.0 in simulate method.
 * In variables: 
 * Out variables: t_n0
 */
void HeatEquation::iniTime() noexcept
{
	t_n0 = 0.0;
}

/**
 * Job computeUn called @2.0 in executeTimeLoopN method.
 * In variables: deltat, f, outgoingFlux, u_n
 * Out variables: u_nplus1
 */
void HeatEquation::computeUn() noexcept
{
	Kokkos::parallel_for(nbCells, KOKKOS_LAMBDA(const size_t& jCells)
	{
		u_nplus1(jCells) = f(jCells) * deltat + u_n(jCells) + outgoingFlux(jCells);
	});
}

/**
 * Job iniUn called @2.0 in simulate method.
 * In variables: PI, alpha, center
 * Out variables: u_n
 */
void HeatEquation::iniUn() noexcept
{
	Kokkos::parallel_for(nbCells, KOKKOS_LAMBDA(const size_t& jCells)
	{
		u_n(jCells) = std::cos(2 * options.PI * options.alpha * center(jCells)[0]);
	});
}

/**
 * Job setUpTimeLoopN called @2.0 in simulate method.
 * In variables: t_n0
 * Out variables: t_n
 */
void HeatEquation::setUpTimeLoopN() noexcept
{
	t_n = t_n0;
}

/**
 * Job executeTimeLoopN called @3.0 in simulate method.
 * In variables: V, center, deltat, f, outgoingFlux, surface, t_n, u_n
 * Out variables: outgoingFlux, t_nplus1, u_nplus1
 */
void HeatEquation::executeTimeLoopN() noexcept
{
	n = 0;
	bool continueLoop = true;
	do
	{
		globalTimer.start();
		cpuTimer.start();
		n++;
		if (n!=1)
			std::cout << "[" << __CYAN__ << __BOLD__ << setw(3) << n << __RESET__ "] t = " << __BOLD__
				<< setiosflags(std::ios::scientific) << setprecision(8) << setw(16) << t_n << __RESET__;
	
		computeOutgoingFlux(); // @1.0
		computeTn(); // @1.0
		computeUn(); // @2.0
		
	
		// Evaluate loop condition with variables at time n
		continueLoop = (t_nplus1 < options.stopTime && n + 1 < options.maxIterations);
	
		if (continueLoop)
		{
			// Switch variables to prepare next iteration
			std::swap(t_nplus1, t_n);
			std::swap(u_nplus1, u_n);
		}
	
		cpuTimer.stop();
		globalTimer.stop();
	
		// Timers display
			std::cout << " {CPU: " << __BLUE__ << cpuTimer.print(true) << __RESET__ ", IO: " << __RED__ << "none" << __RESET__ << "} ";
		
		// Progress
		std::cout << progress_bar(n, options.maxIterations, t_n, options.stopTime, 25);
		std::cout << __BOLD__ << __CYAN__ << Timer::print(
			eta(n, options.maxIterations, t_n, options.stopTime, deltat, globalTimer), true)
			<< __RESET__ << "\r";
		std::cout.flush();
	
		cpuTimer.reset();
		ioTimer.reset();
	} while (continueLoop);
}

void HeatEquation::simulate()
{
	std::cout << "\n" << __BLUE_BKG__ << __YELLOW__ << __BOLD__ <<"\tStarting HeatEquation ..." << __RESET__ << "\n\n";
	
	if (Kokkos::hwloc::available())
	{
		std::cout << "[" << __GREEN__ << "TOPOLOGY" << __RESET__ << "]  NUMA=" << __BOLD__ << Kokkos::hwloc::get_available_numa_count()
			<< __RESET__ << ", Cores/NUMA=" << __BOLD__ << Kokkos::hwloc::get_available_cores_per_numa()
			<< __RESET__ << ", Threads/Core=" << __BOLD__ << Kokkos::hwloc::get_available_threads_per_core() << __RESET__ << std::endl;
	}
	else
	{
		std::cout << "[" << __GREEN__ << "TOPOLOGY" << __RESET__ << "]  HWLOC unavailable cannot get topological informations" << std::endl;
	}
	
	// std::cout << "[" << __GREEN__ << "KOKKOS" << __RESET__ << "]    " << __BOLD__ << (is_same<MyLayout,Kokkos::LayoutLeft>::value?"Left":"Right")" << __RESET__ << " layout" << std::endl;
	
	std::cout << "[" << __GREEN__ << "OUTPUT" << __RESET__ << "]    " << __BOLD__ << "Disabled" << __RESET__ << std::endl;

	computeSurface(); // @1.0
	computeV(); // @1.0
	iniCenter(); // @1.0
	iniF(); // @1.0
	iniTime(); // @1.0
	iniUn(); // @2.0
	setUpTimeLoopN(); // @2.0
	executeTimeLoopN(); // @3.0
	
	std::cout << __YELLOW__ << "\n\tDone ! Took " << __MAGENTA__ << __BOLD__ << globalTimer.print() << __RESET__ << std::endl;
}


void HeatEquation::createDB(const std::string& db_name)
{
	// Creating data base
	leveldb::DB* db;
	leveldb::Options options;
	options.create_if_missing = true;
	leveldb::Status status = leveldb::DB::Open(options, db_name, &db);
	assert(status.ok());
	// Batch to write all data at once
	leveldb::WriteBatch batch;
	batch.Put("n", serialize(n));
	batch.Put("deltat", serialize(deltat));
	batch.Put("t_n", serialize(t_n));
	batch.Put("t_nplus1", serialize(t_nplus1));
	batch.Put("t_n0", serialize(t_n0));
	batch.Put("X", serialize(X));
	batch.Put("center", serialize(center));
	batch.Put("u_n", serialize(u_n));
	batch.Put("u_nplus1", serialize(u_nplus1));
	batch.Put("V", serialize(V));
	batch.Put("f", serialize(f));
	batch.Put("outgoingFlux", serialize(outgoingFlux));
	batch.Put("surface", serialize(surface));
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

int main(int argc, char* argv[]) 
{
	int ret = EXIT_SUCCESS;
	Kokkos::initialize(argc, argv);
	string dataFile;
	
	if (argc == 2)
	{
		dataFile = argv[1];
	}
	else
	{
		std::cerr << "[ERROR] Wrong number of arguments. Expecting 1 arg: dataFile." << std::endl;
		std::cerr << "(HeatEquation.json)" << std::endl;
		return -1;
	}
	
	// read json dataFile
	ifstream ifs(dataFile);
	rapidjson::IStreamWrapper isw(ifs);
	rapidjson::Document d;
	d.ParseStream(isw);
	assert(d.IsObject());
	
	// Mesh instanciation
	CartesianMesh2DFactory meshFactory;
	if (d.HasMember("mesh"))
	{
		rapidjson::StringBuffer strbuf;
		rapidjson::Writer<rapidjson::StringBuffer> writer(strbuf);
		d["mesh"].Accept(writer);
		meshFactory.jsonInit(strbuf.GetString());
	}
	CartesianMesh2D* mesh = meshFactory.create();
	
	// Module instanciation(s)
	HeatEquation::Options heatEquationOptions;
	if (d.HasMember("heatEquation"))
	{
		rapidjson::StringBuffer strbuf;
		rapidjson::Writer<rapidjson::StringBuffer> writer(strbuf);
		d["heatEquation"].Accept(writer);
		heatEquationOptions.jsonInit(strbuf.GetString());
	}
	HeatEquation* heatEquation = new HeatEquation(mesh, heatEquationOptions);
	
	// Start simulation
	// Simulator must be a pointer when a finalize is needed at the end (Kokkos, omp...)
	heatEquation->simulate();
	// Non regression testing
	if (heatEquationOptions.nonRegression == "CreateReference")
		heatEquation->createDB("HeatEquationDB.ref");
	if (heatEquationOptions.nonRegression == "CompareToReference") {
		heatEquation->createDB("HeatEquationDB.current");
		if (!compareDB("HeatEquationDB.current", "HeatEquationDB.ref"))
			ret = 1;
		leveldb::DestroyDB("HeatEquationDB.current", leveldb::Options());
	}
	
	delete heatEquation;
	delete mesh;
	// simulator must be deleted before calling finalize
	Kokkos::finalize();
	return ret;
}
