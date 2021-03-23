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

static inline constexpr std::size_t
isqrt(std::size_t value)
{
    return isqrt_impl(1, 3, value);
}
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
        : m_problem_x(problem_x), m_problem_y(problem_y)
    {
        static_assert(SideTaskNumber * SideTaskNumber + 1 == TaskNumber, "TaskNumber must be of the form SideTaskNumber^2+1");
        static_assert(SideTaskNumber >= 3, "At lest need 3 tasks for the sides, e.g. at least 10 tasks");

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

private:
    /* Don"t move it around */
    CartesianPartition2D(const CartesianPartition2D &)      = delete;
    CartesianPartition2D(CartesianPartition2D &&)           = delete;
    CartesianPartition2D& operator=(CartesianPartition2D &) = delete;

    /* Attributes */
    static inline uint32_t MAX_SHIFT = 0; /* Detected at generation time */

    const uint64_t m_problem_x;
    const uint64_t m_problem_y;

    vector<Id> m_outer_nodes;
    vector<Id> m_outer_cells;
    vector<Id> m_outer_faces;
};
}

#endif /* NABLALIB_MESH_CARTESIANPARTITION2D_H_ */
