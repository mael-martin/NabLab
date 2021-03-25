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
#include <algorithm>
#include <cstdlib>
#include "metis-5.1.0/include/metis.h"
#include "nablalib/types/Types.h"
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
        : m_problem_x(problem_x), m_problem_y(problem_y), m_mesh(mesh)
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

        /* Populate the partitions:
         * - partition -> cell relations
         * - partition -> node relations
         */
        for (size_t i = 0; i < matrix.xadj_len; ++i)
        {
            m_partitions[ret_partition_cell[i]].emplace_back(i);
            const array<Id, 4> nodesFromCell = RANGE_nodesFromCells(i);
            m_partitions_nodes[ret_partition_cell[i]].emplace_back(nodesFromCell[0]);
            m_partitions_nodes[ret_partition_cell[i]].emplace_back(nodesFromCell[1]);
            m_partitions_nodes[ret_partition_cell[i]].emplace_back(nodesFromCell[2]);
            m_partitions_nodes[ret_partition_cell[i]].emplace_back(nodesFromCell[3]);
        }

#define __POPULATE_NODE_PARTITIONS(what, from) {                                    \
        const std::vector<Id> &mesh_vector = m_mesh->get##from##Nodes();            \
        const std::vector<Id> &partition_vector = m_partitions_nodes[i];            \
        /* Get the number of edge nodes that are in the partition */                \
        std::set_intersection(mesh_vector.begin(),      mesh_vector.end(),          \
                              partition_vector.begin(), partition_vector.end(),     \
                              std::back_inserter(m_partitions_##what##_nodes[i]));  \
        /* Because the edge RANGE will be used to index the edge vector from
         * the mesh, we need to reindex: replace each elements in the edge
         * partition by its index in the mesh vector */                             \
        /* XXX: This is ugly, find a better way to do it... */                      \
        std::vector <Id> &partition_edge = m_partitions_##what##_nodes[i];          \
        for (size_t index_in_partition = 0;                                         \
             index_in_partition < partition_edge.size();                            \
             ++index_in_partition) {                                                \
            for (size_t index = 0; index < mesh_vector.size(); ++index) {           \
                if (mesh_vector[index] == partition_edge[index_in_partition]) {     \
                    partition_edge[index_in_partition] = index;                     \
                    break;                                                          \
                }                                                                   \
            }                                                                       \
        }                                                                           \
    }

        for (size_t i = 0; i < num_partition; ++i)
        {
            /* Nodes */
            std::sort(m_partitions_nodes[i].begin(), m_partitions_nodes[i].end());
            m_partitions_nodes[i].erase(std::unique(m_partitions_nodes[i].begin(), m_partitions_nodes[i].end()), m_partitions_nodes[i].end());

            /* Inner, Left, Right, Top, Bottom nodes relations */
            __POPULATE_NODE_PARTITIONS(inner,  Inner );
            __POPULATE_NODE_PARTITIONS(right,  Right );
            __POPULATE_NODE_PARTITIONS(left,   Left  );
            __POPULATE_NODE_PARTITIONS(top,    Top   );
            __POPULATE_NODE_PARTITIONS(bottom, Bottom);

            /* Some beautifull printing */
            std::cout << "Partition " << i << ": " << m_partitions[i].size() << " cells "
                      << "| " << m_partitions_nodes[i].size() << " nodes"
                      << " (top: "    << m_partitions_top_nodes[i].size()
                      << ", bottom: " << m_partitions_bottom_nodes[i].size()
                      << ", right: "  << m_partitions_right_nodes[i].size()
                      << ", left: "   << m_partitions_left_nodes[i].size()
                      << ", inner: "  << m_partitions_inner_nodes[i].size()
                      << ")\n";
        }

        delete[] ret_partition_cell;
        CSR_Matrix::free(matrix);
    }
#undef __POPULATE_NODE_PARTITIONS

    ~CartesianPartition2D() = default;

    inline size_t getTaskNumber()      const noexcept { return TaskNumber;      }
    inline size_t getPartitionNumber() const noexcept { return PartitionNumber; }

    /* XXX: See how to get neighbors with metis */
    // inline auto getNeighbor(const size_t partition) const noexcept { }

    static void setMaxDataShift(uint32_t max_shift) noexcept { MAX_SHIFT = max_shift; }

public:
    /* Pin functions, from a partition get always the same id for the
     * node/cell/face to mark it as a dependency with OpenMP. FIXME: Don't have
     * faces pins for the moment.
     * Pin the first node from a partition. */
    inline Id PIN_cellsFromPartition(const size_t partition) const noexcept { return m_partitions.at(partition)[0]; }
    inline Id PIN_nodesFromPartition(const size_t partition) const noexcept { return PIN_nodesFromCells(PIN_cellsFromPartition(partition)); }

public:
    /* Range functions, from a partition get a way to iterate through all the
     * nodes/cells/faces. Don't have faces ranges for the moment (FIXME). */
    inline auto RANGE_cellsFromPartition(const size_t partition) const noexcept -> const vector<Id>& { return m_partitions.at(partition); }
    inline auto RANGE_nodesFromPartition(const size_t partition) const noexcept -> const vector<Id>& { return m_partitions_nodes.at(partition); }

#define __DEFINE_RANGE_FOR_SIDE_NODE(what)                                  \
    inline const vector<Id>&                                                \
    RANGE_##what##NodesFromPartition(const size_t partition) const noexcept \
    { return m_partitions_##what##_nodes.at(partition); }
    __DEFINE_RANGE_FOR_SIDE_NODE(top)
    __DEFINE_RANGE_FOR_SIDE_NODE(bottom)
    __DEFINE_RANGE_FOR_SIDE_NODE(left)
    __DEFINE_RANGE_FOR_SIDE_NODE(right)
    __DEFINE_RANGE_FOR_SIDE_NODE(inner)
#undef __DEFINE_RANGE_FOR_SIDE_NODE

    /* Internal methods */
private:
    /* Don"t move it around */
    CartesianPartition2D(const CartesianPartition2D &)      = delete;
    CartesianPartition2D(CartesianPartition2D &&)           = delete;
    CartesianPartition2D& operator=(CartesianPartition2D &) = delete;

    /* Helpers */
    inline Id cellIdFromPosition(const size_t x, const size_t y) const noexcept { return y * m_problem_x + x; }

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

    CartesianMesh2D *m_mesh;

    /* Cells partition */
    map<Id, vector<Id>> m_partitions;

    /* Nodes partitions */
    map<Id, vector<Id>> m_partitions_nodes;
    map<Id, vector<Id>> m_partitions_right_nodes;
    map<Id, vector<Id>> m_partitions_left_nodes;
    map<Id, vector<Id>> m_partitions_top_nodes;
    map<Id, vector<Id>> m_partitions_bottom_nodes;
    map<Id, vector<Id>> m_partitions_inner_nodes;
};
}

#endif /* NABLALIB_MESH_CARTESIANPARTITION2D_H_ */
