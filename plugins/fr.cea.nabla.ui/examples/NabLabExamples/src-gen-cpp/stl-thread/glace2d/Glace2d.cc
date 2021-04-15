#define NABLALIB_DEBUG 0
#define NABLA_DEBUG 0
/* DO NOT EDIT THIS FILE - it is machine generated */

#include "Glace2d.h"
#include <rapidjson/document.h>
#include <rapidjson/istreamwrapper.h>
#include <rapidjson/stringbuffer.h>
#include <rapidjson/writer.h>


/******************** Free functions definitions ********************/

namespace glace2dfreefuncs
{
double det(RealArray2D<2,2> a)
{
	return a[0][0] * a[1][1] - a[0][1] * a[1][0];
}

RealArray1D<2> perp(RealArray1D<2> a)
{
	return {a[1], -a[0]};
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
double norm(RealArray1D<x> a)
{
	return std::sqrt(glace2dfreefuncs::dot(a, a));
}

template<size_t l>
RealArray2D<l,l> tensProduct(RealArray1D<l> a, RealArray1D<l> b)
{
	RealArray2D<l,l> result;
	for (size_t ia=0; ia<l; ia++)
	{
		for (size_t ib=0; ib<l; ib++)
		{
			result[ia][ib] = a[ia] * b[ib];
		}
	}
	return result;
}

template<size_t x, size_t y>
RealArray1D<x> matVectProduct(RealArray2D<x,y> a, RealArray1D<y> b)
{
	RealArray1D<x> result;
	for (size_t ix=0; ix<x; ix++)
	{
		RealArray1D<y> tmp;
		for (size_t iy=0; iy<y; iy++)
		{
			tmp[iy] = a[ix][iy];
		}
		result[ix] = glace2dfreefuncs::dot(tmp, b);
	}
	return result;
}

template<size_t l>
double trace(RealArray2D<l,l> a)
{
	double result(0.0);
	for (size_t ia=0; ia<l; ia++)
	{
		result = result + a[ia][ia];
	}
	return result;
}

RealArray2D<2,2> inverse(RealArray2D<2,2> a)
{
	const double alpha(1.0 / glace2dfreefuncs::det(a));
	return {a[1][1] * alpha, -a[0][1] * alpha, -a[1][0] * alpha, a[0][0] * alpha};
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

template<size_t x>
RealArray2D<x,x> sumR2(RealArray2D<x,x> a, RealArray2D<x,x> b)
{
	return a + b;
}

double minR0(double a, double b)
{
	return std::min(a, b);
}
}

/******************** Options definition ********************/

void
Glace2d::Options::jsonInit(const char* jsonContent)
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
		stopTime = 0.2;
	// maxIterations
	if (o.HasMember("maxIterations"))
	{
		const rapidjson::Value& valueof_maxIterations = o["maxIterations"];
		assert(valueof_maxIterations.IsInt());
		maxIterations = valueof_maxIterations.GetInt();
	}
	else
		maxIterations = 20000;
	// gamma
	if (o.HasMember("gamma"))
	{
		const rapidjson::Value& valueof_gamma = o["gamma"];
		assert(valueof_gamma.IsDouble());
		gamma = valueof_gamma.GetDouble();
	}
	else
		gamma = 1.4;
	// xInterface
	if (o.HasMember("xInterface"))
	{
		const rapidjson::Value& valueof_xInterface = o["xInterface"];
		assert(valueof_xInterface.IsDouble());
		xInterface = valueof_xInterface.GetDouble();
	}
	else
		xInterface = 0.5;
	// deltatIni
	if (o.HasMember("deltatIni"))
	{
		const rapidjson::Value& valueof_deltatIni = o["deltatIni"];
		assert(valueof_deltatIni.IsDouble());
		deltatIni = valueof_deltatIni.GetDouble();
	}
	else
		deltatIni = 1.0E-5;
	// deltatCfl
	if (o.HasMember("deltatCfl"))
	{
		const rapidjson::Value& valueof_deltatCfl = o["deltatCfl"];
		assert(valueof_deltatCfl.IsDouble());
		deltatCfl = valueof_deltatCfl.GetDouble();
	}
	else
		deltatCfl = 0.4;
	// rhoIniZg
	if (o.HasMember("rhoIniZg"))
	{
		const rapidjson::Value& valueof_rhoIniZg = o["rhoIniZg"];
		assert(valueof_rhoIniZg.IsDouble());
		rhoIniZg = valueof_rhoIniZg.GetDouble();
	}
	else
		rhoIniZg = 1.0;
	// rhoIniZd
	if (o.HasMember("rhoIniZd"))
	{
		const rapidjson::Value& valueof_rhoIniZd = o["rhoIniZd"];
		assert(valueof_rhoIniZd.IsDouble());
		rhoIniZd = valueof_rhoIniZd.GetDouble();
	}
	else
		rhoIniZd = 0.125;
	// pIniZg
	if (o.HasMember("pIniZg"))
	{
		const rapidjson::Value& valueof_pIniZg = o["pIniZg"];
		assert(valueof_pIniZg.IsDouble());
		pIniZg = valueof_pIniZg.GetDouble();
	}
	else
		pIniZg = 1.0;
	// pIniZd
	if (o.HasMember("pIniZd"))
	{
		const rapidjson::Value& valueof_pIniZd = o["pIniZd"];
		assert(valueof_pIniZd.IsDouble());
		pIniZd = valueof_pIniZd.GetDouble();
	}
	else
		pIniZd = 0.1;
	// Non regression
	assert(o.HasMember("nonRegression"));
	const rapidjson::Value& valueof_nonRegression = o["nonRegression"];
	assert(valueof_nonRegression.IsString());
	nonRegression = valueof_nonRegression.GetString();
}

/******************** Module definition ********************/

Glace2d::~Glace2d()
{
}

Glace2d::Glace2d(CartesianMesh2D* aMesh, Options& aOptions)
: mesh(aMesh)
, nbNodes(mesh->getNbNodes())
, nbCells(mesh->getNbCells())
, nbInnerNodes(mesh->getNbInnerNodes())
, nbTopNodes(mesh->getNbTopNodes())
, nbBottomNodes(mesh->getNbBottomNodes())
, nbLeftNodes(mesh->getNbLeftNodes())
, nbRightNodes(mesh->getNbRightNodes())
, nbNodesOfCell(CartesianMesh2D::MaxNbNodesOfCell)
, nbCellsOfNode(CartesianMesh2D::MaxNbCellsOfNode)
, options(aOptions)
, X_n(nbNodes)
, X_nplus1(nbNodes)
, X_n0(nbNodes)
, b(nbNodes)
, bt(nbNodes)
, Ar(nbNodes)
, Mt(nbNodes)
, ur(nbNodes)
, c(nbCells)
, m(nbCells)
, p(nbCells)
, rho(nbCells)
, e(nbCells)
, E_n(nbCells)
, E_nplus1(nbCells)
, V(nbCells)
, deltatj(nbCells)
, uj_n(nbCells)
, uj_nplus1(nbCells)
, l(nbCells, std::vector<double>(nbNodesOfCell))
, Cjr_ic(nbCells, std::vector<RealArray1D<2>>(nbNodesOfCell))
, C(nbCells, std::vector<RealArray1D<2>>(nbNodesOfCell))
, F(nbCells, std::vector<RealArray1D<2>>(nbNodesOfCell))
, Ajr(nbCells, std::vector<RealArray2D<2,2>>(nbNodesOfCell))
{
	const auto& gNodes = mesh->getGeometry()->getNodes();
	// Copy node coordinates
	for (size_t rNodes=0; rNodes<nbNodes; rNodes++)
	{
		X_n0[rNodes][0] = gNodes[rNodes][0];
		X_n0[rNodes][1] = gNodes[rNodes][1];
	}
}


/**
 * Job computeCjr called @1.0 in executeTimeLoopN method.
 * In variables: X_n
 * Out variables: C
 */
void Glace2d::computeCjr() noexcept
{
	parallel_exec(nbCells, [&](const size_t& jCells)
	{
		const Id jId(jCells);
		{
			const auto nodesOfCellJ(mesh->getNodesOfCell(jId));
			const size_t nbNodesOfCellJ(nodesOfCellJ.size());
			for (size_t rNodesOfCellJ=0; rNodesOfCellJ<nbNodesOfCellJ; rNodesOfCellJ++)
			{
				const Id rPlus1Id(nodesOfCellJ[(rNodesOfCellJ+1+nbNodesOfCell)%nbNodesOfCell]);
				const Id rMinus1Id(nodesOfCellJ[(rNodesOfCellJ-1+nbNodesOfCell)%nbNodesOfCell]);
				const size_t rPlus1Nodes(rPlus1Id);
				const size_t rMinus1Nodes(rMinus1Id);
				C[jCells][rNodesOfCellJ] = 0.5 * glace2dfreefuncs::perp(X_n[rPlus1Nodes] - X_n[rMinus1Nodes]);
			}
		}
	});
}

/**
 * Job computeInternalEnergy called @1.0 in executeTimeLoopN method.
 * In variables: E_n, uj_n
 * Out variables: e
 */
void Glace2d::computeInternalEnergy() noexcept
{
	parallel_exec(nbCells, [&](const size_t& jCells)
	{
		e[jCells] = E_n[jCells] - 0.5 * glace2dfreefuncs::dot(uj_n[jCells], uj_n[jCells]);
	});
}

/**
 * Job iniCjrIc called @1.0 in simulate method.
 * In variables: X_n0
 * Out variables: Cjr_ic
 */
void Glace2d::iniCjrIc() noexcept
{
	parallel_exec(nbCells, [&](const size_t& jCells)
	{
		const Id jId(jCells);
		{
			const auto nodesOfCellJ(mesh->getNodesOfCell(jId));
			const size_t nbNodesOfCellJ(nodesOfCellJ.size());
			for (size_t rNodesOfCellJ=0; rNodesOfCellJ<nbNodesOfCellJ; rNodesOfCellJ++)
			{
				const Id rPlus1Id(nodesOfCellJ[(rNodesOfCellJ+1+nbNodesOfCell)%nbNodesOfCell]);
				const Id rMinus1Id(nodesOfCellJ[(rNodesOfCellJ-1+nbNodesOfCell)%nbNodesOfCell]);
				const size_t rPlus1Nodes(rPlus1Id);
				const size_t rMinus1Nodes(rMinus1Id);
				Cjr_ic[jCells][rNodesOfCellJ] = 0.5 * glace2dfreefuncs::perp(X_n0[rPlus1Nodes] - X_n0[rMinus1Nodes]);
			}
		}
	});
}

/**
 * Job iniTime called @1.0 in simulate method.
 * In variables: 
 * Out variables: t_n0
 */
void Glace2d::iniTime() noexcept
{
	t_n0 = 0.0;
}

/**
 * Job iniTimeStep called @1.0 in simulate method.
 * In variables: deltatIni
 * Out variables: deltat_n0
 */
void Glace2d::iniTimeStep() noexcept
{
	deltat_n0 = options.deltatIni;
}

/**
 * Job computeLjr called @2.0 in executeTimeLoopN method.
 * In variables: C
 * Out variables: l
 */
void Glace2d::computeLjr() noexcept
{
	parallel_exec(nbCells, [&](const size_t& jCells)
	{
		const Id jId(jCells);
		{
			const auto nodesOfCellJ(mesh->getNodesOfCell(jId));
			const size_t nbNodesOfCellJ(nodesOfCellJ.size());
			for (size_t rNodesOfCellJ=0; rNodesOfCellJ<nbNodesOfCellJ; rNodesOfCellJ++)
			{
				l[jCells][rNodesOfCellJ] = glace2dfreefuncs::norm(C[jCells][rNodesOfCellJ]);
			}
		}
	});
}

/**
 * Job computeV called @2.0 in executeTimeLoopN method.
 * In variables: C, X_n
 * Out variables: V
 */
void Glace2d::computeV() noexcept
{
	parallel_exec(nbCells, [&](const size_t& jCells)
	{
		const Id jId(jCells);
		double reduction0(0.0);
		{
			const auto nodesOfCellJ(mesh->getNodesOfCell(jId));
			const size_t nbNodesOfCellJ(nodesOfCellJ.size());
			for (size_t rNodesOfCellJ=0; rNodesOfCellJ<nbNodesOfCellJ; rNodesOfCellJ++)
			{
				const Id rId(nodesOfCellJ[rNodesOfCellJ]);
				const size_t rNodes(rId);
				reduction0 = glace2dfreefuncs::sumR0(reduction0, glace2dfreefuncs::dot(C[jCells][rNodesOfCellJ], X_n[rNodes]));
			}
		}
		V[jCells] = 0.5 * reduction0;
	});
}

/**
 * Job initialize called @2.0 in simulate method.
 * In variables: Cjr_ic, X_n0, gamma, pIniZd, pIniZg, rhoIniZd, rhoIniZg, xInterface
 * Out variables: E_n, m, p, rho, uj_n
 */
void Glace2d::initialize() noexcept
{
	parallel_exec(nbCells, [&](const size_t& jCells)
	{
		const Id jId(jCells);
		double rho_ic;
		double p_ic;
		RealArray1D<2> reduction0({0.0, 0.0});
		{
			const auto nodesOfCellJ(mesh->getNodesOfCell(jId));
			const size_t nbNodesOfCellJ(nodesOfCellJ.size());
			for (size_t rNodesOfCellJ=0; rNodesOfCellJ<nbNodesOfCellJ; rNodesOfCellJ++)
			{
				const Id rId(nodesOfCellJ[rNodesOfCellJ]);
				const size_t rNodes(rId);
				reduction0 = glace2dfreefuncs::sumR1(reduction0, X_n0[rNodes]);
			}
		}
		const RealArray1D<2> center(0.25 * reduction0);
		if (center[0] < options.xInterface) 
		{
			rho_ic = options.rhoIniZg;
			p_ic = options.pIniZg;
		}
		else
		{
			rho_ic = options.rhoIniZd;
			p_ic = options.pIniZd;
		}
		double reduction1(0.0);
		{
			const auto nodesOfCellJ(mesh->getNodesOfCell(jId));
			const size_t nbNodesOfCellJ(nodesOfCellJ.size());
			for (size_t rNodesOfCellJ=0; rNodesOfCellJ<nbNodesOfCellJ; rNodesOfCellJ++)
			{
				const Id rId(nodesOfCellJ[rNodesOfCellJ]);
				const size_t rNodes(rId);
				reduction1 = glace2dfreefuncs::sumR0(reduction1, glace2dfreefuncs::dot(Cjr_ic[jCells][rNodesOfCellJ], X_n0[rNodes]));
			}
		}
		const double V_ic(0.5 * reduction1);
		m[jCells] = rho_ic * V_ic;
		p[jCells] = p_ic;
		rho[jCells] = rho_ic;
		E_n[jCells] = p_ic / ((options.gamma - 1.0) * rho_ic);
		uj_n[jCells] = {0.0, 0.0};
	});
}

/**
 * Job setUpTimeLoopN called @2.0 in simulate method.
 * In variables: X_n0, deltat_n0, t_n0
 * Out variables: X_n, deltat_n, t_n
 */
void Glace2d::setUpTimeLoopN() noexcept
{
	t_n = t_n0;
	deltat_n = deltat_n0;
	for (size_t i1(0) ; i1<X_n.size() ; i1++)
		for (size_t i2(0) ; i2<X_n[i1].size() ; i2++)
			X_n[i1][i2] = X_n0[i1][i2];
}

/**
 * Job computeDensity called @3.0 in executeTimeLoopN method.
 * In variables: V, m
 * Out variables: rho
 */
void Glace2d::computeDensity() noexcept
{
	parallel_exec(nbCells, [&](const size_t& jCells)
	{
		rho[jCells] = m[jCells] / V[jCells];
	});
}

/**
 * Job executeTimeLoopN called @3.0 in simulate method.
 * In variables: Ajr, Ar, C, E_n, F, Mt, V, X_n, b, bt, c, deltatCfl, deltat_n, deltat_nplus1, deltatj, e, gamma, l, m, p, rho, t_n, uj_n, ur
 * Out variables: Ajr, Ar, C, E_nplus1, F, Mt, V, X_nplus1, b, bt, c, deltat_nplus1, deltatj, e, l, p, rho, t_nplus1, uj_nplus1, ur
 */
void Glace2d::executeTimeLoopN() noexcept
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
	
		computeCjr(); // @1.0
		computeInternalEnergy(); // @1.0
		computeLjr(); // @2.0
		computeV(); // @2.0
		computeDensity(); // @3.0
		computeEOSp(); // @4.0
		computeEOSc(); // @5.0
		computeAjr(); // @6.0
		computedeltatj(); // @6.0
		computeAr(); // @7.0
		computeBr(); // @7.0
		computeDt(); // @7.0
		computeBoundaryConditions(); // @8.0
		computeBt(); // @8.0
		computeMt(); // @8.0
		computeTn(); // @8.0
		computeU(); // @9.0
		computeFjr(); // @10.0
		computeXn(); // @10.0
		computeEn(); // @11.0
		computeUn(); // @11.0
		
	
		// Evaluate loop condition with variables at time n
		continueLoop = (t_nplus1 < options.stopTime && n + 1 < options.maxIterations);
	
		if (continueLoop)
		{
			// Switch variables to prepare next iteration
			std::swap(t_nplus1, t_n);
			std::swap(deltat_nplus1, deltat_n);
			std::swap(X_nplus1, X_n);
			std::swap(E_nplus1, E_n);
			std::swap(uj_nplus1, uj_n);
		}
	
		cpuTimer.stop();
		globalTimer.stop();
	
		// Timers display
			std::cout << " {CPU: " << __BLUE__ << cpuTimer.print(true) << __RESET__ ", IO: " << __RED__ << "none" << __RESET__ << "} ";
		
		// Progress
		std::cout << progress_bar(n, options.maxIterations, t_n, options.stopTime, 25);
		std::cout << __BOLD__ << __CYAN__ << Timer::print(
			eta(n, options.maxIterations, t_n, options.stopTime, deltat_n, globalTimer), true)
			<< __RESET__ << "\r";
		std::cout.flush();
	
		cpuTimer.reset();
		ioTimer.reset();
	} while (continueLoop);
}

/**
 * Job computeEOSp called @4.0 in executeTimeLoopN method.
 * In variables: e, gamma, rho
 * Out variables: p
 */
void Glace2d::computeEOSp() noexcept
{
	parallel_exec(nbCells, [&](const size_t& jCells)
	{
		p[jCells] = (options.gamma - 1.0) * rho[jCells] * e[jCells];
	});
}

/**
 * Job computeEOSc called @5.0 in executeTimeLoopN method.
 * In variables: gamma, p, rho
 * Out variables: c
 */
void Glace2d::computeEOSc() noexcept
{
	parallel_exec(nbCells, [&](const size_t& jCells)
	{
		c[jCells] = std::sqrt(options.gamma * p[jCells] / rho[jCells]);
	});
}

/**
 * Job computeAjr called @6.0 in executeTimeLoopN method.
 * In variables: C, c, l, rho
 * Out variables: Ajr
 */
void Glace2d::computeAjr() noexcept
{
	parallel_exec(nbCells, [&](const size_t& jCells)
	{
		const Id jId(jCells);
		{
			const auto nodesOfCellJ(mesh->getNodesOfCell(jId));
			const size_t nbNodesOfCellJ(nodesOfCellJ.size());
			for (size_t rNodesOfCellJ=0; rNodesOfCellJ<nbNodesOfCellJ; rNodesOfCellJ++)
			{
				Ajr[jCells][rNodesOfCellJ] = ((rho[jCells] * c[jCells]) / l[jCells][rNodesOfCellJ]) * glace2dfreefuncs::tensProduct(C[jCells][rNodesOfCellJ], C[jCells][rNodesOfCellJ]);
			}
		}
	});
}

/**
 * Job computedeltatj called @6.0 in executeTimeLoopN method.
 * In variables: V, c, l
 * Out variables: deltatj
 */
void Glace2d::computedeltatj() noexcept
{
	parallel_exec(nbCells, [&](const size_t& jCells)
	{
		const Id jId(jCells);
		double reduction0(0.0);
		{
			const auto nodesOfCellJ(mesh->getNodesOfCell(jId));
			const size_t nbNodesOfCellJ(nodesOfCellJ.size());
			for (size_t rNodesOfCellJ=0; rNodesOfCellJ<nbNodesOfCellJ; rNodesOfCellJ++)
			{
				reduction0 = glace2dfreefuncs::sumR0(reduction0, l[jCells][rNodesOfCellJ]);
			}
		}
		deltatj[jCells] = 2.0 * V[jCells] / (c[jCells] * reduction0);
	});
}

/**
 * Job computeAr called @7.0 in executeTimeLoopN method.
 * In variables: Ajr
 * Out variables: Ar
 */
void Glace2d::computeAr() noexcept
{
	parallel_exec(nbNodes, [&](const size_t& rNodes)
	{
		const Id rId(rNodes);
		RealArray2D<2,2> reduction0({0.0, 0.0,  0.0, 0.0});
		{
			const auto cellsOfNodeR(mesh->getCellsOfNode(rId));
			const size_t nbCellsOfNodeR(cellsOfNodeR.size());
			for (size_t jCellsOfNodeR=0; jCellsOfNodeR<nbCellsOfNodeR; jCellsOfNodeR++)
			{
				const Id jId(cellsOfNodeR[jCellsOfNodeR]);
				const size_t jCells(jId);
				const size_t rNodesOfCellJ(indexOf(mesh->getNodesOfCell(jId), rId));
				reduction0 = glace2dfreefuncs::sumR2(reduction0, Ajr[jCells][rNodesOfCellJ]);
			}
		}
		for (size_t i1=0; i1<2; i1++)
		{
			for (size_t i2=0; i2<2; i2++)
			{
				Ar[rNodes][i1][i2] = reduction0[i1][i2];
			}
		}
	});
}

/**
 * Job computeBr called @7.0 in executeTimeLoopN method.
 * In variables: Ajr, C, p, uj_n
 * Out variables: b
 */
void Glace2d::computeBr() noexcept
{
	parallel_exec(nbNodes, [&](const size_t& rNodes)
	{
		const Id rId(rNodes);
		RealArray1D<2> reduction0({0.0, 0.0});
		{
			const auto cellsOfNodeR(mesh->getCellsOfNode(rId));
			const size_t nbCellsOfNodeR(cellsOfNodeR.size());
			for (size_t jCellsOfNodeR=0; jCellsOfNodeR<nbCellsOfNodeR; jCellsOfNodeR++)
			{
				const Id jId(cellsOfNodeR[jCellsOfNodeR]);
				const size_t jCells(jId);
				const size_t rNodesOfCellJ(indexOf(mesh->getNodesOfCell(jId), rId));
				reduction0 = glace2dfreefuncs::sumR1(reduction0, p[jCells] * C[jCells][rNodesOfCellJ] + glace2dfreefuncs::matVectProduct(Ajr[jCells][rNodesOfCellJ], uj_n[jCells]));
			}
		}
		for (size_t i1=0; i1<2; i1++)
		{
			b[rNodes][i1] = reduction0[i1];
		}
	});
}

/**
 * Job computeDt called @7.0 in executeTimeLoopN method.
 * In variables: deltatCfl, deltatj
 * Out variables: deltat_nplus1
 */
void Glace2d::computeDt() noexcept
{
	double reduction0;
	reduction0 = parallel_reduce(nbCells, numeric_limits<double>::max(), [&](double& accu, const size_t& jCells)
		{
			return (accu = glace2dfreefuncs::minR0(accu, deltatj[jCells]));
		},
		&glace2dfreefuncs::minR0);
	deltat_nplus1 = options.deltatCfl * reduction0;
}

/**
 * Job computeBoundaryConditions called @8.0 in executeTimeLoopN method.
 * In variables: Ar, b
 * Out variables: Mt, bt
 */
void Glace2d::computeBoundaryConditions() noexcept
{
	const RealArray2D<2,2> I({1.0, 0.0, 0.0, 1.0});
	{
		const auto topNodes(mesh->getTopNodes());
		const size_t nbTopNodes(topNodes.size());
		parallel_exec(nbTopNodes, [&](const size_t& rTopNodes)
		{
			const Id rId(topNodes[rTopNodes]);
			const size_t rNodes(rId);
			const RealArray1D<2> N({0.0, 1.0});
			const RealArray2D<2,2> NxN(glace2dfreefuncs::tensProduct(N, N));
			const RealArray2D<2,2> IcP(I - NxN);
			bt[rNodes] = glace2dfreefuncs::matVectProduct(IcP, b[rNodes]);
			Mt[rNodes] = IcP * (Ar[rNodes] * IcP) + NxN * glace2dfreefuncs::trace(Ar[rNodes]);
		});
	}
	{
		const auto bottomNodes(mesh->getBottomNodes());
		const size_t nbBottomNodes(bottomNodes.size());
		parallel_exec(nbBottomNodes, [&](const size_t& rBottomNodes)
		{
			const Id rId(bottomNodes[rBottomNodes]);
			const size_t rNodes(rId);
			const RealArray1D<2> N({0.0, -1.0});
			const RealArray2D<2,2> NxN(glace2dfreefuncs::tensProduct(N, N));
			const RealArray2D<2,2> IcP(I - NxN);
			bt[rNodes] = glace2dfreefuncs::matVectProduct(IcP, b[rNodes]);
			Mt[rNodes] = IcP * (Ar[rNodes] * IcP) + NxN * glace2dfreefuncs::trace(Ar[rNodes]);
		});
	}
	{
		const auto leftNodes(mesh->getLeftNodes());
		const size_t nbLeftNodes(leftNodes.size());
		parallel_exec(nbLeftNodes, [&](const size_t& rLeftNodes)
		{
			const Id rId(leftNodes[rLeftNodes]);
			const size_t rNodes(rId);
			for (size_t i1=0; i1<2; i1++)
			{
				for (size_t i2=0; i2<2; i2++)
				{
					Mt[rNodes][i1][i2] = I[i1][i2];
				}
			}
			bt[rNodes] = {0.0, 0.0};
		});
	}
	{
		const auto rightNodes(mesh->getRightNodes());
		const size_t nbRightNodes(rightNodes.size());
		parallel_exec(nbRightNodes, [&](const size_t& rRightNodes)
		{
			const Id rId(rightNodes[rRightNodes]);
			const size_t rNodes(rId);
			for (size_t i1=0; i1<2; i1++)
			{
				for (size_t i2=0; i2<2; i2++)
				{
					Mt[rNodes][i1][i2] = I[i1][i2];
				}
			}
			bt[rNodes] = {0.0, 0.0};
		});
	}
}

/**
 * Job computeBt called @8.0 in executeTimeLoopN method.
 * In variables: b
 * Out variables: bt
 */
void Glace2d::computeBt() noexcept
{
	{
		const auto innerNodes(mesh->getInnerNodes());
		const size_t nbInnerNodes(innerNodes.size());
		parallel_exec(nbInnerNodes, [&](const size_t& rInnerNodes)
		{
			const Id rId(innerNodes[rInnerNodes]);
			const size_t rNodes(rId);
			for (size_t i1=0; i1<2; i1++)
			{
				bt[rNodes][i1] = b[rNodes][i1];
			}
		});
	}
}

/**
 * Job computeMt called @8.0 in executeTimeLoopN method.
 * In variables: Ar
 * Out variables: Mt
 */
void Glace2d::computeMt() noexcept
{
	{
		const auto innerNodes(mesh->getInnerNodes());
		const size_t nbInnerNodes(innerNodes.size());
		parallel_exec(nbInnerNodes, [&](const size_t& rInnerNodes)
		{
			const Id rId(innerNodes[rInnerNodes]);
			const size_t rNodes(rId);
			for (size_t i1=0; i1<2; i1++)
			{
				for (size_t i2=0; i2<2; i2++)
				{
					Mt[rNodes][i1][i2] = Ar[rNodes][i1][i2];
				}
			}
		});
	}
}

/**
 * Job computeTn called @8.0 in executeTimeLoopN method.
 * In variables: deltat_nplus1, t_n
 * Out variables: t_nplus1
 */
void Glace2d::computeTn() noexcept
{
	t_nplus1 = t_n + deltat_nplus1;
}

/**
 * Job computeU called @9.0 in executeTimeLoopN method.
 * In variables: Mt, bt
 * Out variables: ur
 */
void Glace2d::computeU() noexcept
{
	parallel_exec(nbNodes, [&](const size_t& rNodes)
	{
		ur[rNodes] = glace2dfreefuncs::matVectProduct(glace2dfreefuncs::inverse(Mt[rNodes]), bt[rNodes]);
	});
}

/**
 * Job computeFjr called @10.0 in executeTimeLoopN method.
 * In variables: Ajr, C, p, uj_n, ur
 * Out variables: F
 */
void Glace2d::computeFjr() noexcept
{
	parallel_exec(nbCells, [&](const size_t& jCells)
	{
		const Id jId(jCells);
		{
			const auto nodesOfCellJ(mesh->getNodesOfCell(jId));
			const size_t nbNodesOfCellJ(nodesOfCellJ.size());
			for (size_t rNodesOfCellJ=0; rNodesOfCellJ<nbNodesOfCellJ; rNodesOfCellJ++)
			{
				const Id rId(nodesOfCellJ[rNodesOfCellJ]);
				const size_t rNodes(rId);
				F[jCells][rNodesOfCellJ] = p[jCells] * C[jCells][rNodesOfCellJ] + glace2dfreefuncs::matVectProduct(Ajr[jCells][rNodesOfCellJ], (uj_n[jCells] - ur[rNodes]));
			}
		}
	});
}

/**
 * Job computeXn called @10.0 in executeTimeLoopN method.
 * In variables: X_n, deltat_n, ur
 * Out variables: X_nplus1
 */
void Glace2d::computeXn() noexcept
{
	parallel_exec(nbNodes, [&](const size_t& rNodes)
	{
		X_nplus1[rNodes] = X_n[rNodes] + deltat_n * ur[rNodes];
	});
}

/**
 * Job computeEn called @11.0 in executeTimeLoopN method.
 * In variables: E_n, F, deltat_n, m, ur
 * Out variables: E_nplus1
 */
void Glace2d::computeEn() noexcept
{
	parallel_exec(nbCells, [&](const size_t& jCells)
	{
		const Id jId(jCells);
		double reduction0(0.0);
		{
			const auto nodesOfCellJ(mesh->getNodesOfCell(jId));
			const size_t nbNodesOfCellJ(nodesOfCellJ.size());
			for (size_t rNodesOfCellJ=0; rNodesOfCellJ<nbNodesOfCellJ; rNodesOfCellJ++)
			{
				const Id rId(nodesOfCellJ[rNodesOfCellJ]);
				const size_t rNodes(rId);
				reduction0 = glace2dfreefuncs::sumR0(reduction0, glace2dfreefuncs::dot(F[jCells][rNodesOfCellJ], ur[rNodes]));
			}
		}
		E_nplus1[jCells] = E_n[jCells] - (deltat_n / m[jCells]) * reduction0;
	});
}

/**
 * Job computeUn called @11.0 in executeTimeLoopN method.
 * In variables: F, deltat_n, m, uj_n
 * Out variables: uj_nplus1
 */
void Glace2d::computeUn() noexcept
{
	parallel_exec(nbCells, [&](const size_t& jCells)
	{
		const Id jId(jCells);
		RealArray1D<2> reduction0({0.0, 0.0});
		{
			const auto nodesOfCellJ(mesh->getNodesOfCell(jId));
			const size_t nbNodesOfCellJ(nodesOfCellJ.size());
			for (size_t rNodesOfCellJ=0; rNodesOfCellJ<nbNodesOfCellJ; rNodesOfCellJ++)
			{
				reduction0 = glace2dfreefuncs::sumR1(reduction0, F[jCells][rNodesOfCellJ]);
			}
		}
		uj_nplus1[jCells] = uj_n[jCells] - (deltat_n / m[jCells]) * reduction0;
	});
}

void Glace2d::simulate()
{
	std::cout << "\n" << __BLUE_BKG__ << __YELLOW__ << __BOLD__ <<"\tStarting Glace2d ..." << __RESET__ << "\n\n";
	
	std::cout << "[" << __GREEN__ << "TOPOLOGY" << __RESET__ << "]  HWLOC unavailable cannot get topological informations" << std::endl;
	
	std::cout << "[" << __GREEN__ << "OUTPUT" << __RESET__ << "]    " << __BOLD__ << "Disabled" << __RESET__ << std::endl;

	iniCjrIc(); // @1.0
	iniTime(); // @1.0
	iniTimeStep(); // @1.0
	initialize(); // @2.0
	setUpTimeLoopN(); // @2.0
	executeTimeLoopN(); // @3.0
	
	std::cout << __YELLOW__ << "\n\tDone ! Took " << __MAGENTA__ << __BOLD__ << globalTimer.print() << __RESET__ << std::endl;
}


void Glace2d::createDB(const std::string& db_name)
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
	batch.Put("t_n", serialize(t_n));
	batch.Put("t_nplus1", serialize(t_nplus1));
	batch.Put("t_n0", serialize(t_n0));
	batch.Put("deltat_n", serialize(deltat_n));
	batch.Put("deltat_nplus1", serialize(deltat_nplus1));
	batch.Put("deltat_n0", serialize(deltat_n0));
	batch.Put("X_n", serialize(X_n));
	batch.Put("X_nplus1", serialize(X_nplus1));
	batch.Put("X_n0", serialize(X_n0));
	batch.Put("b", serialize(b));
	batch.Put("bt", serialize(bt));
	batch.Put("Ar", serialize(Ar));
	batch.Put("Mt", serialize(Mt));
	batch.Put("ur", serialize(ur));
	batch.Put("c", serialize(c));
	batch.Put("m", serialize(m));
	batch.Put("p", serialize(p));
	batch.Put("rho", serialize(rho));
	batch.Put("e", serialize(e));
	batch.Put("E_n", serialize(E_n));
	batch.Put("E_nplus1", serialize(E_nplus1));
	batch.Put("V", serialize(V));
	batch.Put("deltatj", serialize(deltatj));
	batch.Put("uj_n", serialize(uj_n));
	batch.Put("uj_nplus1", serialize(uj_nplus1));
	batch.Put("l", serialize(l));
	batch.Put("Cjr_ic", serialize(Cjr_ic));
	batch.Put("C", serialize(C));
	batch.Put("F", serialize(F));
	batch.Put("Ajr", serialize(Ajr));
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
		std::cerr << "(Glace2d.json)" << std::endl;
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
	Glace2d::Options glace2dOptions;
	if (d.HasMember("glace2d"))
	{
		rapidjson::StringBuffer strbuf;
		rapidjson::Writer<rapidjson::StringBuffer> writer(strbuf);
		d["glace2d"].Accept(writer);
		glace2dOptions.jsonInit(strbuf.GetString());
	}
	Glace2d* glace2d = new Glace2d(mesh, glace2dOptions);
	
	// Start simulation
	// Simulator must be a pointer when a finalize is needed at the end (Kokkos, omp...)
	glace2d->simulate();
	// Non regression testing
	if (glace2dOptions.nonRegression == "CreateReference")
		glace2d->createDB("Glace2dDB.ref");
	if (glace2dOptions.nonRegression == "CompareToReference") {
		glace2d->createDB("Glace2dDB.current");
		if (!compareDB("Glace2dDB.current", "Glace2dDB.ref"))
			ret = 1;
		leveldb::DestroyDB("Glace2dDB.current", leveldb::Options());
	}
	
	delete glace2d;
	delete mesh;
	return ret;
}
