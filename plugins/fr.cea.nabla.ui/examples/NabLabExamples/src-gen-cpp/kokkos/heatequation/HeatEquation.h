/* DO NOT EDIT THIS FILE - it is machine generated */

#ifndef __HEATEQUATION_H_
#define __HEATEQUATION_H_

#include <fstream>
#include <iomanip>
#include <type_traits>
#include <limits>
#include <utility>
#include <cmath>
#include <leveldb/db.h>
#include <leveldb/write_batch.h>
#include <Kokkos_Core.hpp>
#include <Kokkos_hwloc.hpp>
#include "nablalib/mesh/CartesianMesh2DFactory.h"
#include "nablalib/mesh/CartesianMesh2D.h"
#include "nablalib/utils/Utils.h"
#include "nablalib/utils/Timer.h"
#include "nablalib/types/Types.h"
#include "nablalib/utils/Serializer.h"
#include "nablalib/utils/kokkos/Parallel.h"
#include "nablalib/mesh/PvdFileWriter2D.h"
#include "nablalib/utils/kokkos/Serializer.h"

using namespace nablalib::mesh;
using namespace nablalib::utils;
using namespace nablalib::types;
using namespace nablalib::utils::kokkos;

/******************** Free functions declarations ********************/

namespace heatequationfreefuncs
{
KOKKOS_INLINE_FUNCTION
double det(RealArray1D<2> a, RealArray1D<2> b);
template<size_t x>
KOKKOS_INLINE_FUNCTION
double norm(RealArray1D<x> a);
template<size_t x>
KOKKOS_INLINE_FUNCTION
double dot(RealArray1D<x> a, RealArray1D<x> b);
template<size_t x>
KOKKOS_INLINE_FUNCTION
RealArray1D<x> sumR1(RealArray1D<x> a, RealArray1D<x> b);
KOKKOS_INLINE_FUNCTION
double sumR0(double a, double b);
}

/******************** Module declaration ********************/

class HeatEquation
{
	/* Don't move this object around */
	HeatEquation(HeatEquation &&)           = delete;
	HeatEquation(const HeatEquation &)      = delete;
	HeatEquation& operator=(HeatEquation &) = delete;

public:
	struct Options
	{
		double stopTime;
		int maxIterations;
		double PI;
		double alpha;
		std::string nonRegression;

		void jsonInit(const char* jsonContent);
	};

	HeatEquation(CartesianMesh2D* aMesh, Options& aOptions);
	~HeatEquation();

	void simulate();
	KOKKOS_INLINE_FUNCTION
	void computeOutgoingFlux() noexcept;
	KOKKOS_INLINE_FUNCTION
	void computeSurface() noexcept;
	KOKKOS_INLINE_FUNCTION
	void computeTn() noexcept;
	KOKKOS_INLINE_FUNCTION
	void computeV() noexcept;
	KOKKOS_INLINE_FUNCTION
	void iniCenter() noexcept;
	KOKKOS_INLINE_FUNCTION
	void iniF() noexcept;
	KOKKOS_INLINE_FUNCTION
	void iniTime() noexcept;
	KOKKOS_INLINE_FUNCTION
	void computeUn() noexcept;
	KOKKOS_INLINE_FUNCTION
	void iniUn() noexcept;
	KOKKOS_INLINE_FUNCTION
	void setUpTimeLoopN() noexcept;
	KOKKOS_INLINE_FUNCTION
	void executeTimeLoopN() noexcept;
	void createDB(const std::string& db_name);

private:
	// Mesh and mesh variables
	CartesianMesh2D* mesh;
	size_t __attribute__((unused))nbNodes, nbCells, nbFaces, nbNeighbourCells, nbNodesOfFace, nbNodesOfCell;

	// User options
	Options& options;

	// Timers
	Timer globalTimer;
	Timer cpuTimer;
	Timer ioTimer;

public:
	// Global variables
	int n;
	static constexpr double deltat = 0.001;
	double t_n;
	double t_nplus1;
	double t_n0;
	Kokkos::View<RealArray1D<2>*> X;
	Kokkos::View<RealArray1D<2>*> center;
	Kokkos::View<double*> u_n;
	Kokkos::View<double*> u_nplus1;
	Kokkos::View<double*> V;
	Kokkos::View<double*> f;
	Kokkos::View<double*> outgoingFlux;
	Kokkos::View<double*> surface;
};

#endif
