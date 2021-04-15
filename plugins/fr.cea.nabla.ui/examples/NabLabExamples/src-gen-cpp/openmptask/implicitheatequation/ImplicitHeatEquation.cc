#define NABLALIB_DEBUG 0
#define NABLA_DEBUG 0
/* DO NOT EDIT THIS FILE - it is machine generated */

#include "ImplicitHeatEquation.h"
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

namespace implicitheatequationfreefuncs
{
template<size_t x>
double norm(RealArray1D<x> a)
{
	return std::sqrt(implicitheatequationfreefuncs::dot(a, a));
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
ImplicitHeatEquation::Options::jsonInit(const char* jsonContent)
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
	// linearAlgebra
	if (o.HasMember("linearAlgebra"))
	{
		rapidjson::StringBuffer strbuf;
		rapidjson::Writer<rapidjson::StringBuffer> writer(strbuf);
		o["linearAlgebra"].Accept(writer);
		linearAlgebra.jsonInit(strbuf.GetString());
	}
}

/******************** Module definition ********************/

ImplicitHeatEquation::~ImplicitHeatEquation()
{
}

ImplicitHeatEquation::ImplicitHeatEquation(CartesianMesh2D* aMesh, Options& aOptions)
: mesh(aMesh)
, nbNodes(mesh->getNbNodes())
, nbCells(mesh->getNbCells())
, nbFaces(mesh->getNbFaces())
, nbNeighbourCells(CartesianMesh2D::MaxNbNeighbourCells)
, nbNodesOfFace(CartesianMesh2D::MaxNbNodesOfFace)
, nbCellsOfFace(CartesianMesh2D::MaxNbCellsOfFace)
, nbNodesOfCell(CartesianMesh2D::MaxNbNodesOfCell)
, options(aOptions)
, writer("ImplicitHeatEquation", options.outputPath)
, lastDump(numeric_limits<int>::min())
, deltat(0.001)
, X(nbNodes)
, Xc(nbCells)
, u_n("u_n", nbCells)
, u_nplus1("u_nplus1", nbCells)
, V(nbCells)
, D(nbCells)
, faceLength(nbFaces)
, faceConductivity(nbFaces)
, alpha("alpha", nbCells, nbCells)
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
void ImplicitHeatEquation::computeFaceLength() noexcept
{
	for (size_t task = 0; task < 10; ++task)
	{
		const Id ___omp_base  = ((nbFaces / 10) * task);
		const Id ___omp_limit = (10 - 1 != task) ? ((nbFaces / 10) * (task + 1)) : (nbFaces);
		const size_t ___omp_base_FACES = ___omp_base;
		#pragma omp task  \
		firstprivate(task, ___omp_base, ___omp_limit)  \
		default(none) shared(stderr, mesh, this->X, this->faceLength) priority(4) \
		/* dep loop (range) */ depend(out:	(this->faceLength[___omp_base_FACES]))
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
						reduction0 = implicitheatequationfreefuncs::sumR0(reduction0, implicitheatequationfreefuncs::norm(X[pNodes] - X[pPlus1Nodes]));
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
void ImplicitHeatEquation::computeTn() noexcept
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
void ImplicitHeatEquation::computeV() noexcept
{
	for (size_t task = 0; task < 10; ++task)
	{
		const Id ___omp_base  = ((nbCells / 10) * task);
		const Id ___omp_limit = (10 - 1 != task) ? ((nbCells / 10) * (task + 1)) : (nbCells);
		const size_t ___omp_base_CELLS = ___omp_base;
		#pragma omp task  \
		firstprivate(task, ___omp_base, ___omp_limit)  \
		default(none) shared(stderr, mesh, this->X, this->V) priority(4) \
		/* dep loop (range) */ depend(out:	(this->V[___omp_base_CELLS]))
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
						reduction0 = implicitheatequationfreefuncs::sumR0(reduction0, implicitheatequationfreefuncs::det(X[pNodes], X[pPlus1Nodes]));
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
void ImplicitHeatEquation::initD() noexcept
{
	for (size_t task = 0; task < 10; ++task)
	{
		const Id ___omp_base  = ((nbCells / 10) * task);
		const Id ___omp_limit = (10 - 1 != task) ? ((nbCells / 10) * (task + 1)) : (nbCells);
		const size_t ___omp_base_CELLS = ___omp_base;
		#pragma omp task  \
		firstprivate(task, ___omp_base, ___omp_limit)  \
		default(none) shared(stderr, mesh, this->D) priority(4) \
		/* dep loop (range) */ depend(out:	(this->D[___omp_base_CELLS]))
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
void ImplicitHeatEquation::initTime() noexcept
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
void ImplicitHeatEquation::initXc() noexcept
{
	for (size_t task = 0; task < 10; ++task)
	{
		const Id ___omp_base  = ((nbCells / 10) * task);
		const Id ___omp_limit = (10 - 1 != task) ? ((nbCells / 10) * (task + 1)) : (nbCells);
		const size_t ___omp_base_CELLS = ___omp_base;
		#pragma omp task  \
		firstprivate(task, ___omp_base, ___omp_limit)  \
		default(none) shared(stderr, mesh, this->X, this->Xc) priority(4) \
		/* dep loop (range) */ depend(out:	(this->Xc[___omp_base_CELLS]))
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
						reduction0 = implicitheatequationfreefuncs::sumR1(reduction0, X[pNodes]);
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
void ImplicitHeatEquation::updateU() noexcept
{
	/* ONLY_AFFECTATION, still need to launch a task for that
	 * TODO: Group all affectations in one job */
	#pragma omp task  \
	default(none) shared(stderr, mesh, this->alpha, this->u_n, this->u_nplus1) priority(1) \
	/* dep loop all (simpL) */ depend(out:	(this->u_nplus1))
	{
		u_nplus1 = options.linearAlgebra.solveLinearSystem(alpha, u_n);
	}
}

/**
 * Job computeDeltaTn called @2.0 in simulate method.
 * In variables: D, V
 * Out variables: deltat
 */
void ImplicitHeatEquation::computeDeltaTn() noexcept
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
			reduction0 = implicitheatequationfreefuncs::minR0(reduction0, V[cCells] / D[cCells]);
	}
	deltat = reduction0 * 0.24;
	}
}

/**
 * Job computeFaceConductivity called @2.0 in simulate method.
 * In variables: D
 * Out variables: faceConductivity
 */
void ImplicitHeatEquation::computeFaceConductivity() noexcept
{
	for (size_t task = 0; task < 10; ++task)
	{
		const Id ___omp_base  = ((nbFaces / 10) * task);
		const Id ___omp_limit = (10 - 1 != task) ? ((nbFaces / 10) * (task + 1)) : (nbFaces);
		const size_t ___omp_base_FACES = ___omp_base;
		// WARN: Conversions in in/out for omp task
		// No 'in' dependencies because there is a `#pragma omp taskwait` at the begin of the `at`
		#pragma omp task  \
		firstprivate(task, ___omp_base, ___omp_limit)  \
		default(none) shared(stderr, mesh, this->D, this->faceConductivity) priority(3) \
		/* dep loop (range) */ depend(out:	(this->faceConductivity[___omp_base_FACES]))
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
						reduction0 = implicitheatequationfreefuncs::prodR0(reduction0, D[c1Cells]);
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
						reduction1 = implicitheatequationfreefuncs::sumR0(reduction1, D[c2Cells]);
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
void ImplicitHeatEquation::initU() noexcept
{
	for (size_t task = 0; task < 10; ++task)
	{
		const Id ___omp_base  = ((nbCells / 10) * task);
		const Id ___omp_limit = (10 - 1 != task) ? ((nbCells / 10) * (task + 1)) : (nbCells);
		const size_t ___omp_base_CELLS = ___omp_base;
		#pragma omp task  \
		firstprivate(task, ___omp_base, ___omp_limit)  \
		default(none) shared(stderr, mesh, this->Xc, this->vectOne, this->u_n) priority(3) \
		/* dep loop (range) */ depend(in:	(this->Xc[___omp_base_CELLS])) \
		/* dep loop (simpL) */ depend(out:	(this->u_n))
		{
			for (size_t cCells = ___omp_base; cCells < ___omp_limit; ++cCells)
			{
				if (implicitheatequationfreefuncs::norm(Xc[cCells] - vectOne) < 0.5) 
					u_n.setValue(cCells, options.u0);
				else
					u_n.setValue(cCells, 0.0);
			}
		}
	}
}

/**
 * Job setUpTimeLoopN called @2.0 in simulate method.
 * In variables: t_n0
 * Out variables: t_n
 */
void ImplicitHeatEquation::setUpTimeLoopN() noexcept
{
	t_n = t_n0;
}

/**
 * Job computeAlphaCoeff called @3.0 in simulate method.
 * In variables: V, Xc, deltat, faceConductivity, faceLength
 * Out variables: alpha
 */
void ImplicitHeatEquation::computeAlphaCoeff() noexcept
{
	for (size_t task = 0; task < 10; ++task)
	{
		const Id ___omp_base  = ((nbCells / 10) * task);
		const Id ___omp_limit = (10 - 1 != task) ? ((nbCells / 10) * (task + 1)) : (nbCells);
		const size_t ___omp_base_CELLS = ___omp_base;
		// WARN: Conversions in in/out for omp task
		// No 'in' dependencies because there is a `#pragma omp taskwait` at the begin of the `at`
		#pragma omp task  \
		firstprivate(task, ___omp_base, ___omp_limit)  \
		default(none) shared(stderr, mesh, this->deltat, this->V, this->faceLength, this->faceConductivity, this->Xc, this->alpha) priority(2) \
		/* dep loop (simpL) */ depend(out:	(this->alpha))
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
						const double alphaExtraDiag(-deltat / V[cCells] * (faceLength[fFaces] * faceConductivity[fFaces]) / implicitheatequationfreefuncs::norm(Xc[cCells] - Xc[dCells]));
						alpha.setValue(cCells, dCells, alphaExtraDiag);
						alphaDiag = alphaDiag + alphaExtraDiag;
					}
				}
				alpha.setValue(cCells, cCells, 1 - alphaDiag);
			}
		}
	}
}

/**
 * Job executeTimeLoopN called @4.0 in simulate method.
 * In variables: alpha, deltat, t_n, u_n
 * Out variables: t_nplus1, u_nplus1
 */
void ImplicitHeatEquation::executeTimeLoopN() noexcept
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

void ImplicitHeatEquation::dumpVariables(int iteration, bool useTimer)
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
			writer.openCellArray("Temperature", 1);
			for (size_t i=0 ; i<nbCells ; ++i)
				writer.write(u_n.getValue(i));
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

void ImplicitHeatEquation::simulate()
{
	std::cout << "\n" << __BLUE_BKG__ << __YELLOW__ << __BOLD__ <<"\tStarting ImplicitHeatEquation ..." << __RESET__ << "\n\n";
	
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
	std::cout << "[CG] average iteration: " << options.linearAlgebra.m_info.m_nb_it / options.linearAlgebra.m_info.m_nb_call << std::endl;
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
		std::cerr << "(ImplicitHeatEquation.json)" << std::endl;
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
	ImplicitHeatEquation::Options implicitHeatEquationOptions;
	if (d.HasMember("implicitHeatEquation"))
	{
		rapidjson::StringBuffer strbuf;
		rapidjson::Writer<rapidjson::StringBuffer> writer(strbuf);
		d["implicitHeatEquation"].Accept(writer);
		implicitHeatEquationOptions.jsonInit(strbuf.GetString());
	}
	ImplicitHeatEquation* implicitHeatEquation = new ImplicitHeatEquation(mesh, implicitHeatEquationOptions);
	
	// Start simulation
	// Simulator must be a pointer when a finalize is needed at the end (Kokkos, omp...)
	implicitHeatEquation->simulate();
	
	delete implicitHeatEquation;
	delete mesh;
	return ret;
}
