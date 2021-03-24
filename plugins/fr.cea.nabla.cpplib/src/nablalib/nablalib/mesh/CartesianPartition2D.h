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
#include "metis-5.1.0/include/metis.h"
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

/* Create CSR matrix from a 2D cartesian mesh */
struct CSR_Matrix
{
    idx_t *xadj;
    idx_t *adjncy;
    idx_t xadj_len;
    idx_t adjncy_len;

    static CSR_Matrix
    createFrom2DCartesianMesh(size_t X, size_t Y) noexcept
    {
        /* Will std::terminate on out of memory */
        CSR_Matrix ret;
        ret.xadj_len   = (X * Y);
        ret.adjncy_len = (4 * 2)                                // Corners
                       + (2 * (X - 2) * 3) + (2 * (Y - 2) * 3)  // Border
                       + (4 * (X - 2) * (Y - 2));               // Inner
        ret.xadj       = new idx_t[ret.xadj_len + 1]();
        ret.adjncy     = new idx_t[ret.adjncy_len]();

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

        ret.xadj[ret.xadj_len] = ret.adjncy_len; // For metis
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
 *                      |  PartitionNumber
 *                      TaskNumber
 */

template <size_t TaskNumber, size_t PartitionNumber>
class CartesianPartition2D final
{
public:
    static constexpr int MaxNbNodesOfCell    = CartesianMesh2D::MaxNbNodesOfCell;
    static constexpr int MaxNbNodesOfFace    = CartesianMesh2D::MaxNbNodesOfFace;
    static constexpr int MaxNbCellsOfNode    = CartesianMesh2D::MaxNbCellsOfNode;
    static constexpr int MaxNbCellsOfFace    = CartesianMesh2D::MaxNbCellsOfFace;
    static constexpr int MaxNbFacesOfCell    = CartesianMesh2D::MaxNbFacesOfCell;
    static constexpr int MaxNbNeighbourCells = CartesianMesh2D::MaxNbNeighbourCells;

    CartesianPartition2D(const uint64_t problem_x, const uint64_t problem_y, CartesianMesh2D *mesh)
        : m_problem_x(problem_x), m_problem_y(problem_y), m_geometry(mesh->getGeometry())
    {
        static_assert(PartitionNumber == TaskNumber, "Only one partition per task is supported");
        if ((math::min<uint64_t>(problem_x, problem_x) / PartitionNumber) <= MAX_SHIFT)
            abort();

        CSR_Matrix matrix     = CSR_Matrix::createFrom2DCartesianMesh(problem_x, problem_y);
        idx_t num_partition   = PartitionNumber;
        idx_t num_constraints = 1; // Number of balancing constraints, which must be at least 1.
        idx_t objval; // On return, the edge cut volume of the partitioning solution.
        idx_t *ret_partition_cell = new idx_t[matrix.xadj_len]();

        int ret = METIS_PartGraphRecursive(&matrix.xadj_len, &num_constraints,
                                           matrix.xadj, matrix.adjncy,
                                           NULL, NULL, NULL,
                                           &num_partition,
                                           NULL, NULL, NULL,
                                           &objval, ret_partition_cell);

        /* Populate the partition -> cell relations */
        for (size_t i = 0; i < matrix.xadj_len; ++i)
        {
            m_partitions[ret_partition_cell[i]].emplace_back(i);
            const array<Id, 4> nodesFromCell = RANGE_nodesFromCells(i);
            m_partitions_nodes[ret_partition_cell[i]].emplace_back(nodesFromCell[0]);
            m_partitions_nodes[ret_partition_cell[i]].emplace_back(nodesFromCell[1]);
            m_partitions_nodes[ret_partition_cell[i]].emplace_back(nodesFromCell[2]);
            m_partitions_nodes[ret_partition_cell[i]].emplace_back(nodesFromCell[3]);
        }

        for (size_t i = 0; i < num_partition; ++i)
        {
            std::cout << "Partition " << i << ": " << m_partitions[i].size() << " cells | " << m_partitions_nodes[i].size() << " nodes\n";
        }

        delete[] ret_partition_cell;
        CSR_Matrix::free(matrix);
    }

    ~CartesianPartition2D() = default;

    inline size_t getTaskNumber()      const noexcept { return TaskNumber;      }
    inline size_t getPartitionNumber() const noexcept { return PartitionNumber; }

    /* XXX: See how to get neighbors with metis */
#if 0
    inline auto
    getNeighbor(const size_t partition) const noexcept
    {
    }
#endif

    static void setMaxDataShift(uint32_t max_shift) noexcept { MAX_SHIFT = max_shift; }

    /* Pin functions, from a partition get always the same id for the
     * node/cell/face to mark it as a dependency with OpenMP. Don't have faces
     * pins for the moment. */
    inline Id
    PIN_cellsFromPartition(const size_t partition) const noexcept
    {
        return m_partitions.at(partition)[0];
    }

    inline Id
    PIN_nodesFromPartition(const size_t partition) const noexcept
    {
        /* Pin the first node from a partition */
        return PIN_nodesFromCells(PIN_cellsFromPartition(partition));
    }

    /* Range functions, from a partition get a way to iterate through all the
     * nodes/cells/faces. Don't have faces ranges for the moment (FIXME). */
    inline const vector<Id>&
    RANGE_cellsFromPartition(const size_t partition) const noexcept
    {
        return m_partitions.at(partition);
    }

    /* Get all nodes from a partition */
    inline const vector<Id>&
    RANGE_nodesFromPartition(const size_t partition) const noexcept
    {
        return m_partitions_nodes.at(partition);
    }

    /* Internal methods */
private:
    /* Don"t move it around */
    CartesianPartition2D(const CartesianPartition2D &)      = delete;
    CartesianPartition2D(CartesianPartition2D &&)           = delete;
    CartesianPartition2D& operator=(CartesianPartition2D &) = delete;

    /* Helpers */
    inline Id cellIdFromPosition(const size_t x, const size_t y) const noexcept { return y * PartitionNumber + x; }

    inline Id
    PIN_nodesFromCells(const Id cell) const noexcept
    {
        return RANGE_nodesFromCells(cell)[0];
    }

    inline const array<Id, 4>
    RANGE_nodesFromCells(const Id cell) const noexcept
    {
        /* All the cells must be on the same line. With the same mesh:
         * Lower nodes:
         * 0: 0,1 | 1: 1,2 | 2: 2,3 | 3: 3,4 <- line 0, 0 -> 4
         * 4: 5,6 | ... ... ... ... | 7: 8,9 <- line 1, 5 -> 9
         * ...
         * For Upper nodes, get the nodes of the next line. With that we can
         * have the ~~magic~~ simple equations that are used in this function.
         */
        array<Id, 4> ret;
        const size_t current_line = cell / m_problem_x;
        const size_t next_line    = current_line + 1;
        const Id next_cell        = cell + m_problem_x;
        ret[0] = cell + current_line;
        ret[1] = cell + current_line + 1;
        ret[2] = next_cell + next_line;
        ret[3] = next_cell + next_line + 1;
        return ret;
    }

    /* Attributes */
private:
    static inline uint32_t MAX_SHIFT = 0; /* Detected at generation time */

    const uint64_t m_problem_x;
    const uint64_t m_problem_y;

    MeshGeometry<2> *m_geometry;

    map<Id, vector<Id>> m_partitions;
    map<Id, vector<Id>> m_partitions_nodes;
};
}

#endif /* NABLALIB_MESH_CARTESIANPARTITION2D_H_ */
