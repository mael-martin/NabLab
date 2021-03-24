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
 * Note: the partition is as follows
 *   +-------------------+      CartesianPartition2D<5, 2>
 *   | 4               4 |                           |  |
 *   |    +----+----+    |                  TaskNumber  |
 *   |    | 2  |  3 |    |                 SideTaskNumber
 *   |    +----+----+    |
 *   |    | 0  | 1  |    |
 *   |    +----+----+    |
 *   | 4               4 |
 *   +-------------------+
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

    /* One partition for all the outer things */
    const size_t OuterPartitionId = SideTaskNumber * SideTaskNumber;

    CartesianPartition2D(const uint64_t problem_x, const uint64_t problem_y, CartesianMesh2D *mesh)
        : m_problem_x(problem_x), m_problem_y(problem_y),
        m_cells_per_partition_x(problem_x / SideTaskNumber), m_cells_per_partition_y(problem_y / SideTaskNumber),
        m_geometry(mesh->getGeometry())
    {
        static_assert(SideTaskNumber * SideTaskNumber + 1 == TaskNumber, "TaskNumber must be of the form SideTaskNumber^2+1");
        static_assert(SideTaskNumber >= 3, "At lest need 3 tasks for the sides, e.g. at least 10 tasks");
        if ((math::min<uint64_t>(problem_x, problem_x) / SideTaskNumber) <= MAX_SHIFT)
            abort();

#define __PUSH_FROM(what, from) for (const auto &id : mesh->get##from()) { m_outer_##what.push_back(id); }
        /* Outer nodes */
        __PUSH_FROM(nodes, TopNodes)
        __PUSH_FROM(nodes, BottomNodes)
        __PUSH_FROM(nodes, RightNodes)
        __PUSH_FROM(nodes, LeftNodes)

        /* Outer cells */
        __PUSH_FROM(cells, OuterCells)

        /* Outer faces */
        __PUSH_FROM(faces, TopFaces)
        __PUSH_FROM(faces, BottomFaces)
        __PUSH_FROM(faces, RightFaces)
        __PUSH_FROM(faces, LeftFaces)
#undef __PUSH_FROM
    }

    ~CartesianPartition2D() = default;

    inline size_t getTaskNumber()     const noexcept { return TaskNumber;     }
    inline size_t getSideTaskNumber() const noexcept { return SideTaskNumber; }

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

    static void setMaxDataShift(uint32_t max_shift) noexcept { MAX_SHIFT = max_shift; }

    /* Pin functions, from a partition get always the same id for the
     * node/cell/face to mark it as a dependency with OpenMP. Don't have faces
     * pins for the moment. */
    inline Id
    PIN_cellsFromPartition(const size_t partition) const noexcept
    {
        /* Outer partition? */
        if (partition == OuterPartitionId) {
            return m_outer_cells[0];
        }

        /* Inner partition, get the bl cell. See RANGE_cellsFromPartition. */
        const size_t partition_x = partition % SideTaskNumber;
        const size_t partition_y = partition / SideTaskNumber;
        const size_t cell_bl_x   = (partition_x * m_cells_per_partition_x) + (partition_x == 0);
        const size_t cell_bl_y   = (partition_y * m_cells_per_partition_y) + (partition_y == 0);
        return cellIdFromPosition(cell_bl_x, cell_bl_y);
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
        vector<pair<Id, Id>> ret;

        /* Outer partition? */
        if (partition == OuterPartitionId) {
            /* Ugly and will be horrible at run time (XXX) */
            for (const Id id : m_outer_cells)
                ret.emplace_back(make_pair(id, id));
        }

        /* This is an inner partition */
        else {
            /* Get the coordinates of the bottom left and top right cells */
            const size_t partition_x         = partition % SideTaskNumber;
            const size_t partition_y         = partition / SideTaskNumber;
            const size_t max_partition_coord = SideTaskNumber - 1;

            /* Bottom left cell, apply corrections if the partition is on the
             * left or at the bottom of the mesh */
            const size_t cell_bl_x = (partition_x * m_cells_per_partition_x) + (partition_x == 0);
            const size_t cell_bl_y = (partition_y * m_cells_per_partition_y) + (partition_y == 0);

            /* Top right cell, apply corrections if the partition is on the
             * right or at the top of the mesh */
            const size_t cell_tr_x = ((partition_x + 1) * m_cells_per_partition_x - 1)                              /* Regular part */
                                   + ((partition_x == max_partition_coord) * ((partition_x % SideTaskNumber) - 1)); /* On the right */
            const size_t cell_tr_y = ((partition_y + 1) * m_cells_per_partition_y - 1)                              /* Regular part */
                                   + ((partition_y == max_partition_coord) * ((partition_x % SideTaskNumber) - 1)); /* On the top   */

            /* Now we have:
             * +-------------cell_tr
             * |             |      <- line (a pair) from Id to Id
             * |  Partition  |      <- line (a pair) from Id to Id
             * |             |      <- line (a pair) from Id to Id
             * cell_bl-------+
             */

            for (size_t y = cell_bl_y; y <= cell_tr_y; ++y) {
                ret.emplace_back(make_pair(cellIdFromPosition(cell_bl_x, y), cellIdFromPosition(cell_tr_x, y)));
            }
        }

        return ret;
    }

    /* Get all nodes from a partition */
    inline vector<pair<Id, Id>>
    RANGE_nodesFromPartition(const size_t partition) const noexcept
    {
        vector<pair<Id, Id>> ret;
        const vector<pair<Id, Id>> cells_in_partition = RANGE_cellsFromPartition(partition);
        for (const auto &cell_range : cells_in_partition) {
            auto[bottom_range, upper_range] = RANGE_nodesFromCells(cell_range);
            ret.emplace_back(upper_range);
            ret.emplace_back(bottom_range);
        }
        return ret;
    }

private:
    /* Don"t move it around */
    CartesianPartition2D(const CartesianPartition2D &)      = delete;
    CartesianPartition2D(CartesianPartition2D &&)           = delete;
    CartesianPartition2D& operator=(CartesianPartition2D &) = delete;

    /* Helpers */
    inline Id cellIdFromPosition(const size_t x, const size_t y) const noexcept { return y * SideTaskNumber + x; }

    inline size_t
    partitionFromCellId(const Id cell) const noexcept
    {
        const size_t mesh_x = cell % m_problem_x;
        const size_t mesh_y = cell / m_problem_x;

        /* Check outers */
        if (mesh_x == 0 || mesh_x == m_problem_x - 1 || mesh_y == 0 || mesh_y == m_problem_y - 1)
            return OuterPartitionId;

        /* Inner partition */
        const size_t partition_x = math::min<size_t>(mesh_x / SideTaskNumber, SideTaskNumber - 1);
        const size_t partition_y = math::min<size_t>(mesh_y / SideTaskNumber, SideTaskNumber - 1);

        return partition_y * SideTaskNumber + partition_x;
    }

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
        auto[first_cell, last_cell] = RANGE_cell;
        const size_t line           = first_cell / SideTaskNumber;
        pair<Id, Id> RANGE_lower    = make_pair(first_cell + line, last_cell + line + 1);
        pair<Id, Id> RANGE_upper    = make_pair(first_cell + line + 1 + m_problem_x, last_cell + line + 1 + 1 + m_problem_x);
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
    static inline uint32_t MAX_SHIFT = 0; /* Detected at generation time */

    const uint64_t m_problem_x;
    const uint64_t m_problem_y;
    const size_t m_cells_per_partition_x;
    const size_t m_cells_per_partition_y;

    vector<Id> m_outer_nodes;
    vector<Id> m_outer_cells;
    vector<Id> m_outer_faces;

    MeshGeometry<2> *m_geometry;
};
}

#endif /* NABLALIB_MESH_CARTESIANPARTITION2D_H_ */
