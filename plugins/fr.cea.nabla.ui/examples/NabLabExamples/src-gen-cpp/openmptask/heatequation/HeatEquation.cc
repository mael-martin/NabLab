#define NABLALIB_DEBUG 0
#define NABLA_DEBUG 0
/* DO NOT EDIT THIS FILE - it is machine generated */

#include "HeatEquation.h"
#include <rapidjson/document.h>
#include <rapidjson/istreamwrapper.h>
#include <rapidjson/stringbuffer.h>
#include <rapidjson/writer.h>

static size_t ___DAG_loops = 0;
#include <algorithm>
namespace internal {
auto max = [](const auto& vec) -> Id { return *std::max_element(vec.begin(), vec.end()); };
auto min = [](const auto& vec) -> Id { return *std::min_element(vec.begin(), vec.end()); };

static size_t nbX_CELLS = 0;
static size_t nbX_FACES = 0;
static size_t nbX_NODES = 0;
}

/******************** Free functions definitions ********************/

namespace heatequationfreefuncs
{
double det(RealArray1D<2> a, RealArray1D<2> b)
{
	return (a[0] * b[1] - a[1] * b[0]);
}

template<size_t x>
double norm(RealArray1D<x> a)
{
	return std::sqrt(heatequationfreefuncs::dot(a, a));
}

template<size_t x>
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
RealArray1D<x> sumR1(RealArray1D<x> a, RealArray1D<x> b)
{
	return a + b;
}

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

	// outputPath
	assert(o.HasMember("outputPath"));
	const rapidjson::Value& valueof_outputPath = o["outputPath"];
	assert(valueof_outputPath.IsString());
	outputPath = valueof_outputPath.GetString();
	// outputPeriod
	assert(o.HasMember("outputPeriod"));
	const rapidjson::Value& valueof_outputPeriod = o["outputPeriod"];
	assert(valueof_outputPeriod.IsInt());
	outputPeriod = valueof_outputPeriod.GetInt();
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
, writer("HeatEquation", options.outputPath)
, lastDump(numeric_limits<int>::min())
, X(nbNodes)
, center(nbCells)
, u_n(nbCells)
, u_nplus1(nbCells)
, V(nbCells)
, f(nbCells)
, outgoingFlux(nbCells)
, surface(nbFaces)
{
	const auto& gNodes = mesh->getGeometry()->getNodes();
	// Copy node coordinates
	for (size_t rNodes=0; rNodes<nbNodes; rNodes++)
	{
		X[rNodes][0] = gNodes[rNodes][0];
		X[rNodes][1] = gNodes[rNodes][1];
	}
}


/**
 * Job computeOutgoingFlux called @1.0 in executeTimeLoopN method.
 * In variables: V, center, deltat, surface, u_n
 * Out variables: outgoingFlux
 */
void HeatEquation::computeOutgoingFlux() noexcept
{
	for (size_t task = 0; task < 10; ++task)
	{
		const Id ___omp_base  = ((nbCells / 10) * task);
		const Id ___omp_limit = (10 - 1 != task)
			? ((nbCells / 10) * (task + 1))
			: (nbCells);
		assert(___omp_base != ___omp_limit);
		#if NABLA_DEBUG == 1
		fprintf(stderr, "ComputeOutgoingFlux@1.0: %ld -> %ld\n", ___omp_base, ___omp_limit);
		#endif
		const Id ___omp_min_CELLS   = std::min(___omp_base, ___omp_limit - 1);
		const Id ___omp_max_CELLS   = std::max(___omp_base, ___omp_limit - 1);
		const Id ___omp_base_CELLS  = ___omp_min_CELLS;
		const Id ___omp_count_CELLS = ___omp_max_CELLS - ___omp_min_CELLS; // Don't do +1
		#pragma omp task  \
		firstprivate(task, ___omp_base, ___omp_limit, ___omp_base_CELLS, ___omp_count_CELLS)  \
		default(none) shared(stderr, mesh, this->u_n, this->center, this->surface, this->deltat, this->V, this->outgoingFlux) priority(2) \
		/* dep loop (range) */ depend(out:	(this->outgoingFlux[___omp_base_CELLS]))
		{
			for (size_t j1Cells = ___omp_base; j1Cells < ___omp_limit; ++j1Cells)
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
						double reduction1((u_n[j2Cells] - u_n[j1Cells]) / heatequationfreefuncs::norm(center[j2Cells] - center[j1Cells]) * surface[cfFaces]);
						reduction0 = heatequationfreefuncs::sumR0(reduction0, reduction1);
					}
				}
				outgoingFlux[j1Cells] = deltat / V[j1Cells] * reduction0;
			}
		}
	}
}

/**
 * Job computeSurface called @1.0 in simulate method.
 * In variables: X
 * Out variables: surface
 */
void HeatEquation::computeSurface() noexcept
{
	for (size_t task = 0; task < 10; ++task)
	{
		const Id ___omp_base  = ((nbFaces / 10) * task);
		const Id ___omp_limit = (10 - 1 != task)
			? ((nbFaces / 10) * (task + 1))
			: (nbFaces);
		assert(___omp_base != ___omp_limit);
		#if NABLA_DEBUG == 1
		fprintf(stderr, "ComputeSurface@1.0: %ld -> %ld\n", ___omp_base, ___omp_limit);
		#endif
		const Id ___omp_min_FACES   = std::min(___omp_base, ___omp_limit - 1);
		const Id ___omp_max_FACES   = std::max(___omp_base, ___omp_limit - 1);
		const Id ___omp_base_FACES  = ___omp_min_FACES;
		const Id ___omp_count_FACES = ___omp_max_FACES - ___omp_min_FACES; // Don't do +1
		#pragma omp task  \
		firstprivate(task, ___omp_base, ___omp_limit, ___omp_base_FACES, ___omp_count_FACES)  \
		default(none) shared(stderr, mesh, this->X, this->surface) priority(3) \
		/* dep loop (range) */ depend(out:	(this->surface[___omp_base_FACES]))
		{
			for (size_t fFaces = ___omp_base; fFaces < ___omp_limit; ++fFaces)
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
						reduction0 = heatequationfreefuncs::sumR0(reduction0, heatequationfreefuncs::norm(X[rNodes] - X[rPlus1Nodes]));
					}
				}
				surface[fFaces] = 0.5 * reduction0;
			}
		}
	}
}

/**
 * Job computeTn called @1.0 in executeTimeLoopN method.
 * In variables: deltat, t_n
 * Out variables: t_nplus1
 */
void HeatEquation::computeTn() noexcept
{
	/* ONLY_AFFECTATION, still need to launch a task for that
	 * TODO: Group all affectations in one job */
	#pragma omp task  \
	default(none) shared(stderr, mesh, this->t_n, this->deltat, this->t_nplus1) priority(2) \
	/* dep loop all (simpL) */ depend(out:	(this->t_nplus1))
	{
		t_nplus1 = t_n + deltat;
	}
}

/**
 * Job computeV called @1.0 in simulate method.
 * In variables: X
 * Out variables: V
 */
void HeatEquation::computeV() noexcept
{
	for (size_t task = 0; task < 10; ++task)
	{
		const Id ___omp_base  = ((nbCells / 10) * task);
		const Id ___omp_limit = (10 - 1 != task)
			? ((nbCells / 10) * (task + 1))
			: (nbCells);
		assert(___omp_base != ___omp_limit);
		#if NABLA_DEBUG == 1
		fprintf(stderr, "ComputeV@1.0: %ld -> %ld\n", ___omp_base, ___omp_limit);
		#endif
		const Id ___omp_min_CELLS   = std::min(___omp_base, ___omp_limit - 1);
		const Id ___omp_max_CELLS   = std::max(___omp_base, ___omp_limit - 1);
		const Id ___omp_base_CELLS  = ___omp_min_CELLS;
		const Id ___omp_count_CELLS = ___omp_max_CELLS - ___omp_min_CELLS; // Don't do +1
		#pragma omp task  \
		firstprivate(task, ___omp_base, ___omp_limit, ___omp_base_CELLS, ___omp_count_CELLS)  \
		default(none) shared(stderr, mesh, this->X, this->V) priority(3) \
		/* dep loop (range) */ depend(out:	(this->V[___omp_base_CELLS]))
		{
			for (size_t jCells = ___omp_base; jCells < ___omp_limit; ++jCells)
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
						reduction0 = heatequationfreefuncs::sumR0(reduction0, heatequationfreefuncs::det(X[rNodes], X[rPlus1Nodes]));
					}
				}
				V[jCells] = 0.5 * reduction0;
			}
		}
	}
}

/**
 * Job iniCenter called @1.0 in simulate method.
 * In variables: X
 * Out variables: center
 */
void HeatEquation::iniCenter() noexcept
{
	for (size_t task = 0; task < 10; ++task)
	{
		const Id ___omp_base  = ((nbCells / 10) * task);
		const Id ___omp_limit = (10 - 1 != task)
			? ((nbCells / 10) * (task + 1))
			: (nbCells);
		assert(___omp_base != ___omp_limit);
		#if NABLA_DEBUG == 1
		fprintf(stderr, "IniCenter@1.0: %ld -> %ld\n", ___omp_base, ___omp_limit);
		#endif
		const Id ___omp_min_CELLS   = std::min(___omp_base, ___omp_limit - 1);
		const Id ___omp_max_CELLS   = std::max(___omp_base, ___omp_limit - 1);
		const Id ___omp_base_CELLS  = ___omp_min_CELLS;
		const Id ___omp_count_CELLS = ___omp_max_CELLS - ___omp_min_CELLS; // Don't do +1
		#pragma omp task  \
		firstprivate(task, ___omp_base, ___omp_limit, ___omp_base_CELLS, ___omp_count_CELLS)  \
		default(none) shared(stderr, mesh, this->X, this->center) priority(3) \
		/* dep loop (range) */ depend(out:	(this->center[___omp_base_CELLS]))
		{
			for (size_t jCells = ___omp_base; jCells < ___omp_limit; ++jCells)
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
						reduction0 = heatequationfreefuncs::sumR1(reduction0, X[rNodes]);
					}
				}
				center[jCells] = 0.25 * reduction0;
			}
		}
	}
}

/**
 * Job iniF called @1.0 in simulate method.
 * In variables: 
 * Out variables: f
 */
void HeatEquation::iniF() noexcept
{
	for (size_t task = 0; task < 10; ++task)
	{
		const Id ___omp_base  = ((nbCells / 10) * task);
		const Id ___omp_limit = (10 - 1 != task)
			? ((nbCells / 10) * (task + 1))
			: (nbCells);
		assert(___omp_base != ___omp_limit);
		#if NABLA_DEBUG == 1
		fprintf(stderr, "IniF@1.0: %ld -> %ld\n", ___omp_base, ___omp_limit);
		#endif
		const Id ___omp_min_CELLS   = std::min(___omp_base, ___omp_limit - 1);
		const Id ___omp_max_CELLS   = std::max(___omp_base, ___omp_limit - 1);
		const Id ___omp_base_CELLS  = ___omp_min_CELLS;
		const Id ___omp_count_CELLS = ___omp_max_CELLS - ___omp_min_CELLS; // Don't do +1
		#pragma omp task  \
		firstprivate(task, ___omp_base, ___omp_limit, ___omp_base_CELLS, ___omp_count_CELLS)  \
		default(none) shared(stderr, mesh, this->f) priority(3) \
		/* dep loop (range) */ depend(out:	(this->f[___omp_base_CELLS]))
		{
			for (size_t jCells = ___omp_base; jCells < ___omp_limit; ++jCells)
			{
				f[jCells] = 0.0;
			}
		}
	}
}

/**
 * Job iniTime called @1.0 in simulate method.
 * In variables: 
 * Out variables: t_n0
 */
void HeatEquation::iniTime() noexcept
{
	/* ONLY_AFFECTATION, still need to launch a task for that
	 * TODO: Group all affectations in one job */
	#pragma omp task  \
	default(none) shared(stderr, mesh, this->t_n0) priority(3) \
	/* dep loop all (simpL) */ depend(out:	(this->t_n0))
	{
		t_n0 = 0.0;
	}
}

/**
 * Job computeUn called @2.0 in executeTimeLoopN method.
 * In variables: deltat, f, outgoingFlux, u_n
 * Out variables: u_nplus1
 */
void HeatEquation::computeUn() noexcept
{
	for (size_t task = 0; task < 10; ++task)
	{
		const Id ___omp_base  = ((nbCells / 10) * task);
		const Id ___omp_limit = (10 - 1 != task)
			? ((nbCells / 10) * (task + 1))
			: (nbCells);
		assert(___omp_base != ___omp_limit);
		#if NABLA_DEBUG == 1
		fprintf(stderr, "ComputeUn@2.0: %ld -> %ld\n", ___omp_base, ___omp_limit);
		#endif
		const Id ___omp_min_CELLS   = std::min(___omp_base, ___omp_limit - 1);
		const Id ___omp_max_CELLS   = std::max(___omp_base, ___omp_limit - 1);
		const Id ___omp_base_CELLS  = ___omp_min_CELLS;
		const Id ___omp_count_CELLS = ___omp_max_CELLS - ___omp_min_CELLS; // Don't do +1
		#pragma omp task  \
		firstprivate(task, ___omp_base, ___omp_limit, ___omp_base_CELLS, ___omp_count_CELLS)  \
		default(none) shared(stderr, mesh, this->f, this->deltat, this->u_n, this->outgoingFlux, this->u_nplus1) priority(1) \
		/* dep loop (range) */ depend(in:	(this->outgoingFlux[___omp_base_CELLS])) \
		/* dep loop (range) */ depend(out:	(this->u_nplus1[___omp_base_CELLS]))
		{
			for (size_t jCells = ___omp_base; jCells < ___omp_limit; ++jCells)
			{
				u_nplus1[jCells] = f[jCells] * deltat + u_n[jCells] + outgoingFlux[jCells];
			}
		}
	}
}

/**
 * Job iniUn called @2.0 in simulate method.
 * In variables: PI, alpha, center
 * Out variables: u_n
 */
void HeatEquation::iniUn() noexcept
{
	for (size_t task = 0; task < 10; ++task)
	{
		const Id ___omp_base  = ((nbCells / 10) * task);
		const Id ___omp_limit = (10 - 1 != task)
			? ((nbCells / 10) * (task + 1))
			: (nbCells);
		assert(___omp_base != ___omp_limit);
		#if NABLA_DEBUG == 1
		fprintf(stderr, "IniUn@2.0: %ld -> %ld\n", ___omp_base, ___omp_limit);
		#endif
		const Id ___omp_min_CELLS   = std::min(___omp_base, ___omp_limit - 1);
		const Id ___omp_max_CELLS   = std::max(___omp_base, ___omp_limit - 1);
		const Id ___omp_base_CELLS  = ___omp_min_CELLS;
		const Id ___omp_count_CELLS = ___omp_max_CELLS - ___omp_min_CELLS; // Don't do +1
		#pragma omp task  \
		firstprivate(task, ___omp_base, ___omp_limit, ___omp_base_CELLS, ___omp_count_CELLS)  \
		default(none) shared(stderr, mesh, this->center, this->u_n) priority(2) \
		/* dep loop (range) */ depend(in:	(this->center[___omp_base_CELLS])) \
		/* dep loop (range) */ depend(out:	(this->u_n[___omp_base_CELLS]))
		{
			for (size_t jCells = ___omp_base; jCells < ___omp_limit; ++jCells)
			{
				u_n[jCells] = std::cos(2 * options.PI * options.alpha * center[jCells][0]);
			}
		}
	}
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
		if (!writer.isDisabled() && n >= lastDump + options.outputPeriod)
			dumpVariables(n);
		if (n!=1)
			std::cout << "[" << __CYAN__ << __BOLD__ << setw(3) << n << __RESET__ "] t = " << __BOLD__
				<< setiosflags(std::ios::scientific) << setprecision(8) << setw(16) << t_n << __RESET__;
	
		// Launch all tasks for this loop...
		
		#pragma omp parallel
		{
		#pragma omp single nowait
		{
		computeOutgoingFlux(); // @1.0
		computeTn(); // @1.0
		computeUn(); // @2.0
		}}
		
	
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
		if (!writer.isDisabled())
			std::cout << " {CPU: " << __BLUE__ << cpuTimer.print(true) << __RESET__ ", IO: " << __BLUE__ << ioTimer.print(true) << __RESET__ "} ";
		else
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
	// force a last output at the end
	dumpVariables(n, false);
}

void HeatEquation::dumpVariables(int iteration, bool useTimer)
{
	if (!writer.isDisabled())
	{
		if (useTimer)
		{
			cpuTimer.stop();
			ioTimer.start();
		}
		auto quads = mesh->getGeometry()->getQuads();
		writer.startVtpFile(iteration, t_n, nbNodes, X.data(), nbCells, quads.data());
		writer.openNodeData();
		writer.closeNodeData();
		writer.openCellData();
		{
			writer.openCellArray("Temperature", 0);
			for (size_t i=0 ; i<nbCells ; ++i)
				writer.write(u_n[i]);
			writer.closeCellArray();
		}
		writer.closeCellData();
		writer.closeVtpFile();
		lastDump = n;
		if (useTimer)
		{
			ioTimer.stop();
			cpuTimer.start();
		}
	}
}

void HeatEquation::simulate()
{
	std::cout << "\n" << __BLUE_BKG__ << __YELLOW__ << __BOLD__ <<"\tStarting HeatEquation ..." << __RESET__ << "\n\n";
	
	std::cout << "[" << __GREEN__ << "TOPOLOGY" << __RESET__ << "]  HWLOC unavailable cannot get topological informations" << std::endl;
	
	if (!writer.isDisabled())
		std::cout << "[" << __GREEN__ << "OUTPUT" << __RESET__ << "]    VTK files stored in " << __BOLD__ << writer.outputDirectory() << __RESET__ << " directory" << std::endl;
	else
		std::cout << "[" << __GREEN__ << "OUTPUT" << __RESET__ << "]    " << __BOLD__ << "Disabled" << __RESET__ << std::endl;

	// Launch all tasks for this loop...
	
	#pragma omp parallel
	{
	#pragma omp single nowait
	{
	computeSurface(); // @1.0
	computeV(); // @1.0
	iniCenter(); // @1.0
	iniF(); // @1.0
	iniTime(); // @1.0
	iniUn(); // @2.0
	// Wait before time loop: true
	}}
	setUpTimeLoopN(); // @2.0
	executeTimeLoopN(); // @3.0
	
	std::cout << __YELLOW__ << "\n\tDone ! Took " << __MAGENTA__ << __BOLD__ << globalTimer.print() << __RESET__ << std::endl;
}


int main(int argc, char* argv[]) 
{
	int ret = EXIT_SUCCESS;
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
	internal::nbX_CELLS = meshFactory.getNbXQuads();
	internal::nbX_NODES = meshFactory.getNbXQuads() + 1;
	internal::nbX_FACES = 0; // TODO
	heatEquation->simulate();
	
	delete heatEquation;
	delete mesh;
	return ret;
}
