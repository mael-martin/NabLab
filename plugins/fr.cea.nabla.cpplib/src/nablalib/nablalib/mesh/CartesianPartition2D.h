/*******************************************************************************
 * Copyright (c) 2020 CEA
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 * Contributors: see AUTHORS file
 *******************************************************************************/
#ifndef NABLALIB_MESH_CARTESIANPARTITION2D_H_
#define NABLALIB_MESH_CARTESIANPARTITION2D_H_

#include <utility>
#include <cstdint>
#include <cmath>
#include <cstdlib>
#include <algorithm>
#include "nablalib/types/Types.h"
#include "nablalib/mesh/MeshGeometry.h"
#include "nablalib/mesh/CartesianMesh2D.h"

using namespace std;

namespace nablalib::mesh::math
{
static inline constexpr std::size_t
isqrt_impl(std::size_t sq, std::size_t dlt, std::size_t value)
{
    return sq <= value ? isqrt_impl(sq+dlt, dlt+2, value) : (dlt >> 1) - 1;
}
static inline constexpr std::size_t isqrt(std::size_t value) { return isqrt_impl(1, 3, value); }
template<typename T> static inline T min(const T a, const T b) { return a < b ? a : b; }
}

namespace nablalib::mesh
{

/* Note: the mesh is as follows
 *  15---16---17---18---19          |-27-|-28-|-29-|-30-|
 *   | 8  | 9  | 10 | 11 |         19   21   23   25   26
 *  10---11---12---13---14          |-18-|-20-|-22-|-24-|
 *   | 4  | 5  | 6  | 7  |         10   12   14   16   17
 *   5----6----7----8----9          |--9-|-11-|-13-|-15-|
 *   | 0  | 1  | 2  | 3  |          1    3    5    7    8
 *   0----1----2----3----4          |-0--|-2--|-4--|-6--|
 *
 * CartesianPartition2D<5, 2>
 *                      |  |
 *                      |  SideTaskNumber -> number of partitions
 *                      TaskNumber        -> number of tasks
 */

template <size_t TaskNumber, size_t SideTaskNumber>
class CartesianPartition2D final
{
public:
    static constexpr int MaxNbNodesOfCell    = CartesianMesh2D::MaxNbNodesOfCell;
    static constexpr int MaxNbNodesOfFace    = CartesianMesh2D::MaxNbNodesOfFace;
    static constexpr int MaxNbCellsOfNode    = CartesianMesh2D::MaxNbCellsOfNode;
    static constexpr int MaxNbCellsOfFace    = CartesianMesh2D::MaxNbCellsOfFace;
    static constexpr int MaxNbFacesOfCell    = CartesianMesh2D::MaxNbFacesOfCell;
    static constexpr int MaxNbNeighbourCells = CartesianMesh2D::MaxNbNeighbourCells;

    /* Create CSR matrix from a 2D cartesian mesh */
    struct CSR_Matrix
    {
        Id *xadj;
        Id *adjncy;
        size_t xadj_len;
        size_t adjncy_len;

        static CSR_Matrix
        createFrom2DCartesianMesh(size_t X, size_t Y) noexcept
        {
            /* Will std::terminate on out of memory */
            CSR_Matrix ret;
            ret.xadj_len   = (X * Y) + 1;
            ret.adjncy_len = (4 * 2)                                // Corners
                           + (2 * (X - 2) * 3) + (2 * (Y - 2) * 3)  // Border
                           + (4 * (X - 2) * (Y - 2));               // Inner
            ret.xadj       = new Id[ret.xadj_len]();
            ret.adjncy     = new Id[ret.adjncy_len]();

#define __ADD_NEIGHBOR(dir)                                                 \
    pair<Id, Id> neighbor_##dir{};                                          \
    if (getNeighbor(X, Y, x, y, CSR_2D_Direction::dir, neighbor_##dir)) {   \
        ret.adjncy[adjncy_index] = neighbor_##dir.first         /* x */     \
                                 + neighbor_##dir.second * X;   /* y */     \
        adjncy_index++;                                                     \
    }

            size_t xadj_index = 0;
            size_t adjncy_index = 0;
            for (size_t x = 0; x < X; ++x) {
                for (size_t y = 0; y < Y; ++y) {
                    __ADD_NEIGHBOR(SOUTH);
                    __ADD_NEIGHBOR(WEST);
                    __ADD_NEIGHBOR(EAST);
                    __ADD_NEIGHBOR(NORTH);
                    xadj_index++; /* Because there is at least one neighbor */
                }
            }

#undef __ADD_NEIGHBOR

            return ret;
        }

        static void
        free(CSR_Matrix &matrix) noexcept
        {
            if (matrix.xadj)   { delete[] matrix.xadj;   }
            if (matrix.adjncy) { delete[] matrix.adjncy; }
            matrix.xadj       = nullptr;
            matrix.adjncy     = nullptr;
            matrix.xadj_len   = 0;
            matrix.adjncy_len = 0;
        }

    private:
        enum CSR_2D_Direction {
            SOUTH = (1 << 1),
            WEST  = (1 << 2),
            EAST  = (1 << 3),
            NORTH = (1 << 4)
        };

        static inline bool
        getNeighbor(const size_t X, const size_t Y, const size_t x, const size_t y, CSR_2D_Direction dir, pair<Id, Id> &ret) noexcept
        {
            /* Check border conditions */
            if (((x == 0)     && (dir & CSR_2D_Direction::EAST))  ||
                ((x == X - 1) && (dir & CSR_2D_Direction::WEST))  ||
                ((y == 0)     && (dir & CSR_2D_Direction::SOUTH)) ||
                ((y == Y - 1) && (dir & CSR_2D_Direction::NORTH))) {
                return false;
            }

            const size_t delta_x = ((dir & CSR_2D_Direction::EAST)  >> 3) - ((dir & CSR_2D_Direction::WEST)  >> 2);
            const size_t delta_y = ((dir & CSR_2D_Direction::NORTH) >> 4) - ((dir & CSR_2D_Direction::SOUTH) >> 1);

            ret.first = x + delta_x;
            ret.first = y + delta_y;
            return true;
        }
    };

    CartesianPartition2D(const uint64_t problem_x, const uint64_t problem_y, CartesianMesh2D *mesh)
        : m_problem_x(problem_x), m_problem_y(problem_y), m_geometry(mesh->getGeometry())
    {
        static_assert(SideTaskNumber == TaskNumber, "Only one partition per task is supported");
        if ((math::min<uint64_t>(problem_x, problem_x) / SideTaskNumber) <= MAX_SHIFT)
            abort();
    }

    ~CartesianPartition2D() = default;

    inline size_t getTaskNumber()     const noexcept { return TaskNumber;     }
    inline size_t getSideTaskNumber() const noexcept { return SideTaskNumber; }

    /* XXX: See how to get neighbors with metis */
#if 0
    inline constexpr array<size_t, 4>
    getNeighbor(const size_t partition) const noexcept
    {
        const size_t partition_X = partition % SideTaskNumber;
        const size_t partition_Y = partition / SideTaskNumber;
        array<size_t, 4> ret;
        ret[0] = (partition_X == 0)              ? OuterPartitionId : (partition_X - 1) + (partition_Y * SideTaskNumber); /* On the left side?   */
        ret[1] = (partition_X == SideTaskNumber) ? OuterPartitionId : (partition_X + 1) + (partition_Y * SideTaskNumber); /* On the right side?  */
        ret[2] = (partition_Y == 0)              ? OuterPartitionId : partition_X + (partition_Y - 1) * SideTaskNumber;   /* On the bottom side? */
        ret[3] = (partition_Y == SideTaskNumber) ? OuterPartitionId : partition_X + (partition_Y + 1) * SideTaskNumber;   /* On the top side?    */
        return ret;
    }
#endif

    static void setMaxDataShift(uint32_t max_shift) noexcept { MAX_SHIFT = max_shift; }

    /* Pin functions, from a partition get always the same id for the
     * node/cell/face to mark it as a dependency with OpenMP. Don't have faces
     * pins for the moment. */
    inline Id
    PIN_cellsFromPartition(const size_t partition) const noexcept
    {
        return 0;
    }

    inline Id
    PIN_nodesFromPartition(const size_t partition) const noexcept
    {
        /* Pin the first node from a partition */
        return PIN_nodesFromCells(PIN_cellsFromPartition(partition));
    }

    /* Range functions, from a partition get a way to iterate through all the
     * nodes/cells/faces. Don't have faces ranges for the moment (FIXME). */
    inline vector<pair<Id, Id>>
    RANGE_cellsFromPartition(const size_t partition) const noexcept
    {
        vector<pair<Id, Id>> ret{};
        return ret;
    }

    /* Get all nodes from a partition */
    inline vector<pair<Id, Id>>
    RANGE_nodesFromPartition(const size_t partition) const noexcept
    {
        vector<pair<Id, Id>> ret{};
        return ret;
    }

    /* Internal methods */
private:
    /* Don"t move it around */
    CartesianPartition2D(const CartesianPartition2D &)      = delete;
    CartesianPartition2D(CartesianPartition2D &&)           = delete;
    CartesianPartition2D& operator=(CartesianPartition2D &) = delete;

    /* Helpers */
    inline Id cellIdFromPosition(const size_t x, const size_t y) const noexcept { return y * SideTaskNumber + x; }

    inline pair<pair<Id, Id>, pair<Id, Id>>
    RANGE_nodesFromCells(pair<Id, Id> RANGE_cell) const noexcept
    {
        /* All the cells must be on the same line. With the same mesh:
         * Lower nodes:
         * 0: 0,1 | 1: 1,2 | 2: 2,3 | 3: 3,4 <- line 0, 0 -> 4
         * 4: 5,6 | ... ... ... ... | 7: 8,9 <- line 1, 5 -> 9
         * ...
         * For Upper nodes, get the nodes of the next line. With that we can
         * have the ~~magic~~ simple equations that are used in this function.
         */

        /* Lower cells, cells from the current line */
        auto[first_cell, last_cell] = RANGE_cell;
        size_t line                 = first_cell / SideTaskNumber;
        pair<Id, Id> RANGE_lower    = make_pair(first_cell + line, last_cell + line + 1);

        /* Lower cells from next line are the upper cells from the current line */
        first_cell              += m_problem_x;
        last_cell               += m_problem_x;
        line                    += 1;
        pair<Id, Id> RANGE_upper = make_pair(first_cell + line, last_cell + line + 1);

        return make_pair(RANGE_lower, RANGE_upper);
    }

    inline Id
    PIN_nodesFromCells(const Id cell) const noexcept
    {
        /* See RANGE_nodesFromCells. Here we pin the first node from a cell. */
        const size_t line = cell / SideTaskNumber;
        return cell + line;
    }

    /* Attributes */
private:
    static inline uint32_t MAX_SHIFT = 0; /* Detected at generation time */

    const uint64_t m_problem_x;
    const uint64_t m_problem_y;

    MeshGeometry<2> *m_geometry;
};
}

#endif /* NABLALIB_MESH_CARTESIANPARTITION2D_H_ */
