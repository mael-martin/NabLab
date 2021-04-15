#define NABLALIB_DEBUG 0
#define NABLA_DEBUG 0
/* DO NOT EDIT THIS FILE - it is machine generated */

#include "ExplicitHeatEquation.h"
#include <rapidjson/document.h>
#include <rapidjson/istreamwrapper.h>
#include <rapidjson/stringbuffer.h>
#include <rapidjson/writer.h>

static size_t ___DAG_loops = 0;
#include <algorithm>
namespace internal_omptask {
auto max = [](const auto& vec) -> Id { return *std::max_element(vec.begin(), vec.end()); };
auto min = [](const auto& vec) -> Id { return *std::min_element(vec.begin(), vec.end()); };

static size_t nbX_CELLS = 0;
static size_t nbX_FACES = 0;
static size_t nbX_NODES = 0;
}

/******************** Free functions definitions ********************/

namespace explicitheatequationfreefuncs
{
template<size_t x>
double norm(RealArray1D<x> a)
{
	return std::sqrt(explicitheatequationfreefuncs::dot(a, a));
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

double det(RealArray1D<2> a, RealArray1D<2> b)
{
	return (a[0] * b[1] - a[1] * b[0]);
}

template<size_t x>
RealArray1D<x> sumR1(RealArray1D<x> a, RealArray1D<x> b)
{
	return a + b;
}

double minR0(double a, double b)
{
	return std::min(a, b);
}

double sumR0(double a, double b)
{
	return a + b;
}

double prodR0(double a, double b)
{
	return a * b;
}
}

/******************** Options definition ********************/

void
ExplicitHeatEquation::Options::jsonInit(const char* jsonContent)
{
	rapidjson::Document document;
	assert(!document.Parse(jsonContent).HasParseError());
	assert(document.IsObject());
	const rapidjson::Value::Object& o = document.GetObject();

	// u0
	if (o.HasMember("u0"))
	{
		const rapidjson::Value& valueof_u0 = o["u0"];
		assert(valueof_u0.IsDouble());
		u0 = valueof_u0.GetDouble();
	}
	else
		u0 = 1.0;
	// stopTime
	if (o.HasMember("stopTime"))
	{
		const rapidjson::Value& valueof_stopTime = o["stopTime"];
		assert(valueof_stopTime.IsDouble());
		stopTime = valueof_stopTime.GetDouble();
	}
	else
		stopTime = 1.0;
	// maxIterations
	if (o.HasMember("maxIterations"))
	{
		const rapidjson::Value& valueof_maxIterations = o["maxIterations"];
		assert(valueof_maxIterations.IsInt());
		maxIterations = valueof_maxIterations.GetInt();
	}
	else
		maxIterations = 500000000;
	// Non regression
	assert(o.HasMember("nonRegression"));
	const rapidjson::Value& valueof_nonRegression = o["nonRegression"];
	assert(valueof_nonRegression.IsString());
	nonRegression = valueof_nonRegression.GetString();
}

/******************** Module definition ********************/

ExplicitHeatEquation::~ExplicitHeatEquation()
{
}

ExplicitHeatEquation::ExplicitHeatEquation(CartesianMesh2D* aMesh, Options& aOptions)
: mesh(aMesh)
, nbNodes(mesh->getNbNodes())
, nbCells(mesh->getNbCells())
, nbFaces(mesh->getNbFaces())
, nbNeighbourCells(CartesianMesh2D::MaxNbNeighbourCells)
, nbNodesOfFace(CartesianMesh2D::MaxNbNodesOfFace)
, nbCellsOfFace(CartesianMesh2D::MaxNbCellsOfFace)
, nbNodesOfCell(CartesianMesh2D::MaxNbNodesOfCell)
, options(aOptions)
, deltat(0.001)
, X(nbNodes)
, Xc(nbCells)
, u_n(nbCells)
, u_nplus1(nbCells)
, V(nbCells)
, D(nbCells)
, faceLength(nbFaces)
, faceConductivity(nbFaces)
, alpha(nbCells, std::vector<double>(nbCells))
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
 * Job computeFaceLength called @1.0 in simulate method.
 * In variables: X
 * Out variables: faceLength
 */
void ExplicitHeatEquation::computeFaceLength() noexcept
{
	for (size_t task = 0; task < 10; ++task)
	{
		const Id ___omp_base  = ((nbFaces / 10) * task);
		const Id ___omp_limit = (10 - 1 != task) ? ((nbFaces / 10) * (task + 1)) : (nbFaces);
		#pragma omp task  \
		firstprivate(task, ___omp_base, ___omp_limit)  \
		default(none) shared(stderr, mesh, this->X, this->faceLength) priority(4) \
		/* dep loop (range) */ depend(out:	(this->faceLength[___omp_base]))
		{
			for (size_t fFaces = ___omp_base; fFaces < ___omp_limit; ++fFaces)
			{
				const Id fId(fFaces);
				double reduction0(0.0);
				{
					const auto nodesOfFaceF(mesh->getNodesOfFace(fId));
					const size_t nbNodesOfFaceF(nodesOfFaceF.size());
					for (size_t pNodesOfFaceF=0; pNodesOfFaceF<nbNodesOfFaceF; pNodesOfFaceF++)
					{
						const Id pId(nodesOfFaceF[pNodesOfFaceF]);
						const Id pPlus1Id(nodesOfFaceF[(pNodesOfFaceF+1+nbNodesOfFace)%nbNodesOfFace]);
						const size_t pNodes(pId);
						const size_t pPlus1Nodes(pPlus1Id);
						reduction0 = explicitheatequationfreefuncs::sumR0(reduction0, explicitheatequationfreefuncs::norm(X[pNodes] - X[pPlus1Nodes]));
					}
				}
				faceLength[fFaces] = 0.5 * reduction0;
			}
		}
	}
}

/**
 * Job computeTn called @1.0 in executeTimeLoopN method.
 * In variables: deltat, t_n
 * Out variables: t_nplus1
 */
void ExplicitHeatEquation::computeTn() noexcept
{
	/* ONLY_AFFECTATION, still need to launch a task for that
	 * TODO: Group all affectations in one job */
	#pragma omp task  \
	default(none) shared(stderr, mesh, this->t_n, this->deltat, this->t_nplus1) priority(1) \
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
void ExplicitHeatEquation::computeV() noexcept
{
	for (size_t task = 0; task < 10; ++task)
	{
		const Id ___omp_base  = ((nbCells / 10) * task);
		const Id ___omp_limit = (10 - 1 != task) ? ((nbCells / 10) * (task + 1)) : (nbCells);
		#pragma omp task  \
		firstprivate(task, ___omp_base, ___omp_limit)  \
		default(none) shared(stderr, mesh, this->X, this->V) priority(4) \
		/* dep loop (range) */ depend(out:	(this->V[___omp_base]))
		{
			for (size_t jCells = ___omp_base; jCells < ___omp_limit; ++jCells)
			{
				const Id jId(jCells);
				double reduction0(0.0);
				{
					const auto nodesOfCellJ(mesh->getNodesOfCell(jId));
					const size_t nbNodesOfCellJ(nodesOfCellJ.size());
					for (size_t pNodesOfCellJ=0; pNodesOfCellJ<nbNodesOfCellJ; pNodesOfCellJ++)
					{
						const Id pId(nodesOfCellJ[pNodesOfCellJ]);
						const Id pPlus1Id(nodesOfCellJ[(pNodesOfCellJ+1+nbNodesOfCell)%nbNodesOfCell]);
						const size_t pNodes(pId);
						const size_t pPlus1Nodes(pPlus1Id);
						reduction0 = explicitheatequationfreefuncs::sumR0(reduction0, explicitheatequationfreefuncs::det(X[pNodes], X[pPlus1Nodes]));
					}
				}
				V[jCells] = 0.5 * reduction0;
			}
		}
	}
}

/**
 * Job initD called @1.0 in simulate method.
 * In variables: 
 * Out variables: D
 */
void ExplicitHeatEquation::initD() noexcept
{
	for (size_t task = 0; task < 10; ++task)
	{
		const Id ___omp_base  = ((nbCells / 10) * task);
		const Id ___omp_limit = (10 - 1 != task) ? ((nbCells / 10) * (task + 1)) : (nbCells);
		#pragma omp task  \
		firstprivate(task, ___omp_base, ___omp_limit)  \
		default(none) shared(stderr, mesh, this->D) priority(4) \
		/* dep loop (range) */ depend(out:	(this->D[___omp_base]))
		{
			for (size_t cCells = ___omp_base; cCells < ___omp_limit; ++cCells)
			{
				D[cCells] = 1.0;
			}
		}
	}
}

/**
 * Job initTime called @1.0 in simulate method.
 * In variables: 
 * Out variables: t_n0
 */
void ExplicitHeatEquation::initTime() noexcept
{
	/* ONLY_AFFECTATION, still need to launch a task for that
	 * TODO: Group all affectations in one job */
	#pragma omp task  \
	default(none) shared(stderr, mesh, this->t_n0) priority(4) \
	/* dep loop all (simpL) */ depend(out:	(this->t_n0))
	{
		t_n0 = 0.0;
	}
}

/**
 * Job initXc called @1.0 in simulate method.
 * In variables: X
 * Out variables: Xc
 */
void ExplicitHeatEquation::initXc() noexcept
{
	for (size_t task = 0; task < 10; ++task)
	{
		const Id ___omp_base  = ((nbCells / 10) * task);
		const Id ___omp_limit = (10 - 1 != task) ? ((nbCells / 10) * (task + 1)) : (nbCells);
		#pragma omp task  \
		firstprivate(task, ___omp_base, ___omp_limit)  \
		default(none) shared(stderr, mesh, this->X, this->Xc) priority(4) \
		/* dep loop (range) */ depend(out:	(this->Xc[___omp_base]))
		{
			for (size_t cCells = ___omp_base; cCells < ___omp_limit; ++cCells)
			{
				const Id cId(cCells);
				RealArray1D<2> reduction0({0.0, 0.0});
				{
					const auto nodesOfCellC(mesh->getNodesOfCell(cId));
					const size_t nbNodesOfCellC(nodesOfCellC.size());
					for (size_t pNodesOfCellC=0; pNodesOfCellC<nbNodesOfCellC; pNodesOfCellC++)
					{
						const Id pId(nodesOfCellC[pNodesOfCellC]);
						const size_t pNodes(pId);
						reduction0 = explicitheatequationfreefuncs::sumR1(reduction0, X[pNodes]);
					}
				}
				Xc[cCells] = 0.25 * reduction0;
			}
		}
	}
}

/**
 * Job updateU called @1.0 in executeTimeLoopN method.
 * In variables: alpha, u_n
 * Out variables: u_nplus1
 */
void ExplicitHeatEquation::updateU() noexcept
{
	for (size_t task = 0; task < 10; ++task)
	{
		const Id ___omp_base  = ((nbCells / 10) * task);
		const Id ___omp_limit = (10 - 1 != task) ? ((nbCells / 10) * (task + 1)) : (nbCells);
		#pragma omp task  \
		firstprivate(task, ___omp_base, ___omp_limit)  \
		default(none) shared(stderr, mesh, this->alpha, this->u_n, this->u_nplus1) priority(1) \
		/* dep loop (range) */ depend(out:	(this->u_nplus1[___omp_base]))
		{
			for (size_t cCells = ___omp_base; cCells < ___omp_limit; ++cCells)
			{
				const Id cId(cCells);
				double reduction0(0.0);
				{
					const auto neighbourCellsC(mesh->getNeighbourCells(cId));
					const size_t nbNeighbourCellsC(neighbourCellsC.size());
					for (size_t dNeighbourCellsC=0; dNeighbourCellsC<nbNeighbourCellsC; dNeighbourCellsC++)
					{
						const Id dId(neighbourCellsC[dNeighbourCellsC]);
						const size_t dCells(dId);
						reduction0 = explicitheatequationfreefuncs::sumR0(reduction0, alpha[cCells][dCells] * u_n[dCells]);
					}
				}
				u_nplus1[cCells] = alpha[cCells][cCells] * u_n[cCells] + reduction0;
			}
		}
	}
}

/**
 * Job computeDeltaTn called @2.0 in simulate method.
 * In variables: D, V
 * Out variables: deltat
 */
void ExplicitHeatEquation::computeDeltaTn() noexcept
{
	double reduction0(numeric_limits<double>::max());
	#pragma omp task  \
	default(none) shared(stderr, mesh, this->V, this->D, this->deltat) priority(3) firstprivate(reduction0, nbCells) \
	/* dep loop all (rgpin) */ depend(in:	(this->V[(((this->V.size()) / 10) * 0)])) \
	/* dep loop all (rgpin) */ depend(in:	(this->V[(((this->V.size()) / 10) * 1)])) \
	/* dep loop all (rgpin) */ depend(in:	(this->V[(((this->V.size()) / 10) * 2)])) \
	/* dep loop all (rgpin) */ depend(in:	(this->V[(((this->V.size()) / 10) * 3)])) \
	/* dep loop all (rgpin) */ depend(in:	(this->V[(((this->V.size()) / 10) * 4)])) \
	/* dep loop all (rgpin) */ depend(in:	(this->V[(((this->V.size()) / 10) * 5)])) \
	/* dep loop all (rgpin) */ depend(in:	(this->V[(((this->V.size()) / 10) * 6)])) \
	/* dep loop all (rgpin) */ depend(in:	(this->V[(((this->V.size()) / 10) * 7)])) \
	/* dep loop all (rgpin) */ depend(in:	(this->V[(((this->V.size()) / 10) * 8)])) \
	/* dep loop all (rgpin) */ depend(in:	(this->V[(((this->V.size()) / 10) * 9)])) \
	/* dep loop all (rgpin) */ depend(in:	(this->D[(((this->D.size()) / 10) * 0)])) \
	/* dep loop all (rgpin) */ depend(in:	(this->D[(((this->D.size()) / 10) * 1)])) \
	/* dep loop all (rgpin) */ depend(in:	(this->D[(((this->D.size()) / 10) * 2)])) \
	/* dep loop all (rgpin) */ depend(in:	(this->D[(((this->D.size()) / 10) * 3)])) \
	/* dep loop all (rgpin) */ depend(in:	(this->D[(((this->D.size()) / 10) * 4)])) \
	/* dep loop all (rgpin) */ depend(in:	(this->D[(((this->D.size()) / 10) * 5)])) \
	/* dep loop all (rgpin) */ depend(in:	(this->D[(((this->D.size()) / 10) * 6)])) \
	/* dep loop all (rgpin) */ depend(in:	(this->D[(((this->D.size()) / 10) * 7)])) \
	/* dep loop all (rgpin) */ depend(in:	(this->D[(((this->D.size()) / 10) * 8)])) \
	/* dep loop all (rgpin) */ depend(in:	(this->D[(((this->D.size()) / 10) * 9)])) \
	/* dep reduction result */ depend(out:	(this->deltat))
	{
	{
		for (size_t cCells=0; cCells<nbCells; cCells++)
			reduction0 = explicitheatequationfreefuncs::minR0(reduction0, V[cCells] / D[cCells]);
	}
	deltat = reduction0 * 0.24;
	}
}

/**
 * Job computeFaceConductivity called @2.0 in simulate method.
 * In variables: D
 * Out variables: faceConductivity
 */
void ExplicitHeatEquation::computeFaceConductivity() noexcept
{
	for (size_t task = 0; task < 10; ++task)
	{
		const Id ___omp_base  = ((nbFaces / 10) * task);
		const Id ___omp_limit = (10 - 1 != task) ? ((nbFaces / 10) * (task + 1)) : (nbFaces);
		// WARN: Conversions in in/out for omp task
		// No 'in' dependencies because there is a `#pragma omp taskwait` at the begin of the `at`
		#pragma omp task  \
		firstprivate(task, ___omp_base, ___omp_limit)  \
		default(none) shared(stderr, mesh, this->D, this->faceConductivity) priority(3) \
		/* dep loop (range) */ depend(out:	(this->faceConductivity[___omp_base]))
		{
			for (size_t fFaces = ___omp_base; fFaces < ___omp_limit; ++fFaces)
			{
				const Id fId(fFaces);
				double reduction0(1.0);
				{
					const auto cellsOfFaceF(mesh->getCellsOfFace(fId));
					const size_t nbCellsOfFaceF(cellsOfFaceF.size());
					for (size_t c1CellsOfFaceF=0; c1CellsOfFaceF<nbCellsOfFaceF; c1CellsOfFaceF++)
					{
						const Id c1Id(cellsOfFaceF[c1CellsOfFaceF]);
						const size_t c1Cells(c1Id);
						reduction0 = explicitheatequationfreefuncs::prodR0(reduction0, D[c1Cells]);
					}
				}
				double reduction1(0.0);
				{
					const auto cellsOfFaceF(mesh->getCellsOfFace(fId));
					const size_t nbCellsOfFaceF(cellsOfFaceF.size());
					for (size_t c2CellsOfFaceF=0; c2CellsOfFaceF<nbCellsOfFaceF; c2CellsOfFaceF++)
					{
						const Id c2Id(cellsOfFaceF[c2CellsOfFaceF]);
						const size_t c2Cells(c2Id);
						reduction1 = explicitheatequationfreefuncs::sumR0(reduction1, D[c2Cells]);
					}
				}
				faceConductivity[fFaces] = 2.0 * reduction0 / reduction1;
			}
		}
	}
}

/**
 * Job initU called @2.0 in simulate method.
 * In variables: Xc, u0, vectOne
 * Out variables: u_n
 */
void ExplicitHeatEquation::initU() noexcept
{
	for (size_t task = 0; task < 10; ++task)
	{
		const Id ___omp_base  = ((nbCells / 10) * task);
		const Id ___omp_limit = (10 - 1 != task) ? ((nbCells / 10) * (task + 1)) : (nbCells);
		#pragma omp task  \
		firstprivate(task, ___omp_base, ___omp_limit)  \
		default(none) shared(stderr, mesh, this->Xc, ExplicitHeatEquation::vectOne, this->u_n) priority(3) \
		/* dep loop (range) */ depend(in:	(this->Xc[___omp_base])) \
		/* dep loop (range) */ depend(out:	(this->u_n[___omp_base]))
		{
			for (size_t cCells = ___omp_base; cCells < ___omp_limit; ++cCells)
			{
				if (explicitheatequationfreefuncs::norm(Xc[cCells] - vectOne) < 0.5) 
					u_n[cCells] = options.u0;
				else
					u_n[cCells] = 0.0;
			}
		}
	}
}

/**
 * Job setUpTimeLoopN called @2.0 in simulate method.
 * In variables: t_n0
 * Out variables: t_n
 */
void ExplicitHeatEquation::setUpTimeLoopN() noexcept
{
	t_n = t_n0;
}

/**
 * Job computeAlphaCoeff called @3.0 in simulate method.
 * In variables: V, Xc, deltat, faceConductivity, faceLength
 * Out variables: alpha
 */
void ExplicitHeatEquation::computeAlphaCoeff() noexcept
{
	for (size_t task = 0; task < 10; ++task)
	{
		const Id ___omp_base  = ((nbCells / 10) * task);
		const Id ___omp_limit = (10 - 1 != task) ? ((nbCells / 10) * (task + 1)) : (nbCells);
		// WARN: Conversions in in/out for omp task
		// No 'in' dependencies because there is a `#pragma omp taskwait` at the begin of the `at`
		#pragma omp task  \
		firstprivate(task, ___omp_base, ___omp_limit)  \
		default(none) shared(stderr, mesh, this->deltat, this->V, this->faceLength, this->faceConductivity, this->Xc, this->alpha) priority(2) \
		/* dep loop (range) */ depend(out:	(this->alpha[___omp_base]))
		{
			for (size_t cCells = ___omp_base; cCells < ___omp_limit; ++cCells)
			{
				const Id cId(cCells);
				double alphaDiag(0.0);
				{
					const auto neighbourCellsC(mesh->getNeighbourCells(cId));
					const size_t nbNeighbourCellsC(neighbourCellsC.size());
					for (size_t dNeighbourCellsC=0; dNeighbourCellsC<nbNeighbourCellsC; dNeighbourCellsC++)
					{
						const Id dId(neighbourCellsC[dNeighbourCellsC]);
						const size_t dCells(dId);
						const Id fId(mesh->getCommonFace(cId, dId));
						const size_t fFaces(fId);
						const double alphaExtraDiag(deltat / V[cCells] * (faceLength[fFaces] * faceConductivity[fFaces]) / explicitheatequationfreefuncs::norm(Xc[cCells] - Xc[dCells]));
						alpha[cCells][dCells] = alphaExtraDiag;
						alphaDiag = alphaDiag + alphaExtraDiag;
					}
				}
				alpha[cCells][cCells] = 1 - alphaDiag;
			}
		}
	}
}

/**
 * Job executeTimeLoopN called @4.0 in simulate method.
 * In variables: alpha, deltat, t_n, u_n
 * Out variables: t_nplus1, u_nplus1
 */
void ExplicitHeatEquation::executeTimeLoopN() noexcept
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
	
		// Launch all tasks for this loop...
		
		#pragma omp parallel
		{
		#pragma omp single nowait
		{
		computeTn(); // @1.0
		updateU(); // @1.0
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

void ExplicitHeatEquation::simulate()
{
	std::cout << "\n" << __BLUE_BKG__ << __YELLOW__ << __BOLD__ <<"\tStarting ExplicitHeatEquation ..." << __RESET__ << "\n\n";
	
	std::cout << "[" << __GREEN__ << "TOPOLOGY" << __RESET__ << "]  HWLOC unavailable cannot get topological informations" << std::endl;
	
	std::cout << "[" << __GREEN__ << "OUTPUT" << __RESET__ << "]    " << __BOLD__ << "Disabled" << __RESET__ << std::endl;

	// Launch all tasks for this loop...
	
	#pragma omp parallel
	{
	#pragma omp single nowait
	{
	computeFaceLength(); // @1.0
	computeV(); // @1.0
	initD(); // @1.0
	initTime(); // @1.0
	initXc(); // @1.0
	/* A job will do an index conversion, need to wait as it is not supported */
	#pragma omp taskwait
	computeDeltaTn(); // @2.0
	computeFaceConductivity(); // @2.0 (do conversions)
	initU(); // @2.0
	// Wait before time loop: true
	}}
	setUpTimeLoopN(); // @2.0
	/* A job will do an index conversion, need to wait as it is not supported */
	#pragma omp taskwait
	computeAlphaCoeff(); // @3.0 (do conversions)
	executeTimeLoopN(); // @4.0
	
	std::cout << __YELLOW__ << "\n\tDone ! Took " << __MAGENTA__ << __BOLD__ << globalTimer.print() << __RESET__ << std::endl;
}


void ExplicitHeatEquation::createDB(const std::string& db_name)
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
	batch.Put("vectOne", serialize(vectOne));
	batch.Put("deltat", serialize(deltat));
	batch.Put("t_n", serialize(t_n));
	batch.Put("t_nplus1", serialize(t_nplus1));
	batch.Put("t_n0", serialize(t_n0));
	batch.Put("X", serialize(X));
	batch.Put("Xc", serialize(Xc));
	batch.Put("u_n", serialize(u_n));
	batch.Put("u_nplus1", serialize(u_nplus1));
	batch.Put("V", serialize(V));
	batch.Put("D", serialize(D));
	batch.Put("faceLength", serialize(faceLength));
	batch.Put("faceConductivity", serialize(faceConductivity));
	batch.Put("alpha", serialize(alpha));
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
	string dataFile;
	
	if (argc == 2)
	{
		dataFile = argv[1];
	}
	else
	{
		std::cerr << "[ERROR] Wrong number of arguments. Expecting 1 arg: dataFile." << std::endl;
		std::cerr << "(ExplicitHeatEquation.json)" << std::endl;
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
	ExplicitHeatEquation::Options explicitHeatEquationOptions;
	if (d.HasMember("explicitHeatEquation"))
	{
		rapidjson::StringBuffer strbuf;
		rapidjson::Writer<rapidjson::StringBuffer> writer(strbuf);
		d["explicitHeatEquation"].Accept(writer);
		explicitHeatEquationOptions.jsonInit(strbuf.GetString());
	}
	ExplicitHeatEquation* explicitHeatEquation = new ExplicitHeatEquation(mesh, explicitHeatEquationOptions);
	
	// Start simulation
	// Simulator must be a pointer when a finalize is needed at the end (Kokkos, omp...)
	explicitHeatEquation->simulate();
	// Non regression testing
	if (explicitHeatEquationOptions.nonRegression == "CreateReference")
		explicitHeatEquation->createDB("ExplicitHeatEquationDB.ref");
	if (explicitHeatEquationOptions.nonRegression == "CompareToReference") {
		explicitHeatEquation->createDB("ExplicitHeatEquationDB.current");
		if (!compareDB("ExplicitHeatEquationDB.current", "ExplicitHeatEquationDB.ref"))
			ret = 1;
		leveldb::DestroyDB("ExplicitHeatEquationDB.current", leveldb::Options());
	}
	
	delete explicitHeatEquation;
	delete mesh;
	return ret;
}
