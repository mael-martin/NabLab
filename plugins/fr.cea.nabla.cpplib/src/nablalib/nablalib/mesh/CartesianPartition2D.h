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
#include <iomanip>
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

namespace nablalib::utils
{
template<typename T> static inline void
vector_uniq(vector<T> &vec)
{
    std::sort(vec.begin(), vec.end());
    vec.resize(distance(vec.begin(), unique(vec.begin(), vec.end())));
}
}

namespace nablalib::mesh
{

enum CSR_2D_Direction {
    SOUTH = (1 << 1),
    WEST  = (1 << 2),
    EAST  = (1 << 3),
    NORTH = (1 << 4)
};

enum CSR_2D_Direction_index {
    index_SOUTH = 0,
    index_WEST  = 1,
    index_EAST  = 2,
    index_NORTH = 3
};

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
    } // else { std::cerr << "No " #dir " neighbor for (x: " << x << ", y:" << y << ")\n"; }
        size_t xadj_index   = 0;
        size_t adjncy_index = 0;
        for (size_t y = 0; y < Y; ++y) {
            for (size_t x = 0; x < X; ++x) {
                ret.xadj[xadj_index] = adjncy_index;
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
    static inline bool
    getNeighbor(const size_t X, const size_t Y, const size_t x, const size_t y, CSR_2D_Direction dir, pair<Id, Id> &ret) noexcept
    {
        /* Check border conditions */
        if (((x == 0)     && (dir & CSR_2D_Direction::WEST))  ||
            ((x == X - 1) && (dir & CSR_2D_Direction::EAST))  ||
            ((y == 0)     && (dir & CSR_2D_Direction::SOUTH)) ||
            ((y == Y - 1) && (dir & CSR_2D_Direction::NORTH))) {
            return false;
        }
        ret.first  = x + ((dir & CSR_2D_Direction::EAST)  >> 3) - ((dir & CSR_2D_Direction::WEST)  >> 2);
        ret.second = y + ((dir & CSR_2D_Direction::NORTH) >> 4) - ((dir & CSR_2D_Direction::SOUTH) >> 1);
        return true;
    }
};

/* Note: the mesh is as follows for the nodes and cells. The faces don't seem
 * to follow the graph in the Factory source file.
 *  15---16---17---18---19
 *   | 8  | 9  | 10 | 11 |
 *  10---11---12---13---14
 *   | 4  | 5  | 6  | 7  |
 *   5----6----7----8----9
 *   | 0  | 1  | 2  | 3  |
 *   0----1----2----3----4
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
        idx_t metis_options[METIS_NOPTIONS];
        int ret;

        ret = METIS_SetDefaultOptions(metis_options);
        if (METIS_OK != ret) {
            std::cerr << "Could not set default options with metis\n";
            abort();
        }
        metis_options[METIS_OPTION_OBJTYPE] = METIS_OBJTYPE_CUT; /* Edge cut    */
        metis_options[METIS_OPTION_MINCONN] = true; /* Minimize connections     */
        metis_options[METIS_OPTION_CONTIG]  = true; /* Contiguous partitions    */
        metis_options[METIS_OPTION_NCUTS]   = 5; /* 5 generation, take the best */

        /* It is used to partition a graph into k equal-size parts using
         * multilevel recursive bisection. It provides the functionality of
         * the pmetis program. The objective of the partitioning is to minimize
         * the edgecut. Here, objval is the edgecut.
         */
        ret = METIS_PartGraphKway(&matrix.xadj_len, &num_constraints, matrix.xadj, matrix.adjncy,
                                  NULL, NULL, NULL, &num_partition, NULL, NULL,
                                  metis_options, &objval, ret_partition_cell);
        if (METIS_OK != ret) {
            std::cerr << "Invalid return from metis\n";
            abort();
        }

        std::cout << "Edge cut is: " << objval << "\n";

        for (size_t i = 0; i < matrix.xadj_len; ++i) {
            m_partitions_cells[ret_partition_cell[i]].emplace_back(i);

            const array<Id, 4> nodes = RANGE_nodesFromCells(i);
            m_partitions_nodes[ret_partition_cell[i]].emplace_back(nodes[0]);
            m_partitions_nodes[ret_partition_cell[i]].emplace_back(nodes[1]);
            m_partitions_nodes[ret_partition_cell[i]].emplace_back(nodes[2]);
            m_partitions_nodes[ret_partition_cell[i]].emplace_back(nodes[3]);

            const array<Id, 4> faces = RANGE_facesFromCells(i);
            m_partitions_faces[ret_partition_cell[i]].emplace_back(faces[0]);
            m_partitions_faces[ret_partition_cell[i]].emplace_back(faces[1]);
            m_partitions_faces[ret_partition_cell[i]].emplace_back(faces[2]);
            m_partitions_faces[ret_partition_cell[i]].emplace_back(faces[3]);
        }


        /* Compute neighbors partitions here */
        // map <Id, array<Id, 4>> m_partitions_neighbors;

        /* Nodes and faces of partitions */
#define ___POPULATE_PARTITIONS(type, what, from) {                                               \
std::set_intersection(m_mesh->get##from().begin(), m_mesh->get##from().end(),                    \
                      m_partitions_##type[i].begin(), m_partitions_##type[i].end(),              \
                      std::back_inserter(m_partitions_##what##_##type[i]));                      \
for (size_t index_in_partition = 0;                                                              \
     index_in_partition < m_partitions_##what##_##type[i].size();                                \
     ++index_in_partition) {                                                                     \
    for (size_t index = 0; index < m_mesh->get##from().size(); ++index) {                        \
        if (m_mesh->get##from()[index] == m_partitions_##what##_##type[i][index_in_partition]) { \
            m_partitions_##what##_##type[i][index_in_partition] = index;                         \
            break;                                                                               \
        }                                                                                        \
    }                                                                                            \
}}
        /* Quick and dirty parallelisation for independent loop's body */
        #pragma omp parallel for
        for (size_t i = 0; i < num_partition; ++i) {
            utils::vector_uniq(m_partitions_nodes[i]);
            utils::vector_uniq(m_partitions_faces[i]);
            ___POPULATE_PARTITIONS(cells, top,    TopCells);
            ___POPULATE_PARTITIONS(cells, bottom, BottomCells);
            ___POPULATE_PARTITIONS(cells, left,   LeftCells);
            ___POPULATE_PARTITIONS(cells, right,  RightCells);
            ___POPULATE_PARTITIONS(cells, inner,  InnerCells);
            ___POPULATE_PARTITIONS(cells, outer,  OuterCells);
            ___POPULATE_PARTITIONS(nodes, top,    TopNodes);
            ___POPULATE_PARTITIONS(nodes, bottom, BottomNodes);
            ___POPULATE_PARTITIONS(nodes, left,   LeftNodes);
            ___POPULATE_PARTITIONS(nodes, right,  RightNodes);
            ___POPULATE_PARTITIONS(nodes, inner,  InnerNodes);
            ___POPULATE_PARTITIONS(faces, top,    TopFaces);
            ___POPULATE_PARTITIONS(faces, bottom, BottomFaces);
            ___POPULATE_PARTITIONS(faces, left,   LeftFaces);
            ___POPULATE_PARTITIONS(faces, right,  RightFaces);
            ___POPULATE_PARTITIONS(faces, inner,  InnerFaces);
            ___POPULATE_PARTITIONS(faces, outer,  OuterFaces);
            ___POPULATE_PARTITIONS(faces, innerHorizontal, InnerHorizontalFaces);
            ___POPULATE_PARTITIONS(faces, innerVertical,   InnerVerticalFaces);
        }
#undef ___POPULATE_PARTITIONS

        for (size_t i = 0; i < num_partition; ++i) {
            /* Some beautifull printing */
            const size_t max_length = std::to_string(m_partitions_cells[0].size() * 4).size() + 1;
            std::cout << "Partition " << std::setw(max_length) << i << ": "
                      /* CELLS */
                      << m_partitions_cells[i].size() << " cells"
                      << " (t "   << std::setw(max_length) << m_partitions_top_cells[i].size()
                      << ", b "   << std::setw(max_length) << m_partitions_bottom_cells[i].size()
                      << ", r "   << std::setw(max_length) << m_partitions_right_cells[i].size()
                      << ", l "   << std::setw(max_length) << m_partitions_left_cells[i].size()
                      << ", in "  << std::setw(max_length) << m_partitions_inner_cells[i].size()
                      << ", out " << std::setw(max_length) << m_partitions_outer_cells[i].size()
                      << ") "
                      /* NODES */
                      << m_partitions_nodes[i].size() << " nodes"
                      << " (t "   << std::setw(max_length) << m_partitions_top_nodes[i].size()
                      << ", b "   << std::setw(max_length) << m_partitions_bottom_nodes[i].size()
                      << ", r "   << std::setw(max_length) << m_partitions_right_nodes[i].size()
                      << ", l "   << std::setw(max_length) << m_partitions_left_nodes[i].size()
                      << ", in "  << std::setw(max_length) << m_partitions_inner_nodes[i].size()
                      << ") "
                      /* FACES */
                      << m_partitions_faces[i].size() << " faces"
                      << " (t "   << std::setw(max_length) << m_partitions_top_faces[i].size()
                      << ", b "   << std::setw(max_length) << m_partitions_bottom_faces[i].size()
                      << ", r "   << std::setw(max_length) << m_partitions_right_faces[i].size()
                      << ", l "   << std::setw(max_length) << m_partitions_left_faces[i].size()
                      << ", in "  << std::setw(max_length) << m_partitions_inner_faces[i].size()
                      << ", inV " << std::setw(max_length) << m_partitions_innerVertical_faces[i].size()
                      << ", inH " << std::setw(max_length) << m_partitions_innerHorizontal_faces[i].size()
                      << ", out " << std::setw(max_length) << m_partitions_outer_faces[i].size()
                      << ")\n";
        }
        std::cout << "Totals: \n\t" << mesh->getNbCells()                << " cells, "
                                    << mesh->getNbNodes()                << " nodes, "
                                    << mesh->getNbFaces()                << " faces\n\t"
                                    << mesh->getNbTopFaces()             << " T faces, "
                                    << mesh->getNbBottomFaces()          << " B faces, "
                                    << mesh->getNbRightFaces()           << " R faces, "
                                    << mesh->getNbLeftFaces()            << " L faces, "
                                    << mesh->getNbInnerFaces()           << " I faces, "
                                    << mesh->getNbInnerHorizontalFaces() << " IH faces, "
                                    << mesh->getNbInnerVerticalFaces()   << " IV faces, "
                                    << mesh->getNbOuterFaces()           << " O faces\n";
        std::cout << "/!\\ DON'T TRUST THE FACES NUMBERS FOR THE MOMENT /!\\\n";
        delete[] ret_partition_cell;
        CSR_Matrix::free(matrix);
    }

    ~CartesianPartition2D() = default;

    inline size_t getTaskNumber()      const noexcept { return TaskNumber;      }
    inline size_t getPartitionNumber() const noexcept { return PartitionNumber; }

    static void setMaxDataShift(uint32_t max_shift) noexcept { MAX_SHIFT = max_shift; }

public:
    /* Neighbor function */
    inline const size_t
    NEIGHBOR_partitionFromDirection(const size_t partition, const CSR_2D_Direction dir) const noexcept
    {
        const array<Id, 4> &neighbors = m_partitions_neighbors.at(partition);
        switch (dir) {
        case CSR_2D_Direction::SOUTH:   return neighbors[CSR_2D_Direction_index::index_SOUTH];
        case CSR_2D_Direction::WEST:    return neighbors[CSR_2D_Direction_index::index_WEST];
        case CSR_2D_Direction::EAST:    return neighbors[CSR_2D_Direction_index::index_EAST];
        case CSR_2D_Direction::NORTH:   return neighbors[CSR_2D_Direction_index::index_NORTH];
        }
    }

public:
    /* Pin functions, from a partition get always the same id for the
     * node/cell/face to mark it as a dependency with OpenMP.
     * Pin the first node from a partition. */
    inline Id PIN_cellsFromPartition(const size_t partition) const noexcept { return m_partitions_cells.at(partition)[0]; }
    inline Id PIN_nodesFromPartition(const size_t partition) const noexcept { return PIN_nodesFromCells(PIN_cellsFromPartition(partition)); }
    inline Id PIN_facesFromPartition(const size_t partition) const noexcept { return PIN_facesFromCells(PIN_cellsFromPartition(partition)); }

    inline Id PIN_cellsFromPartition(const size_t partition, const CSR_2D_Direction dir) const noexcept { return m_partitions_cells.at(NEIGHBOR_partitionFromDirection(partition, dir))[0]; }
    inline Id PIN_nodesFromPartition(const size_t partition, const CSR_2D_Direction dir) const noexcept { return PIN_nodesFromCells(PIN_cellsFromPartition(NEIGHBOR_partitionFromDirection(partition, dir))); }
    inline Id PIN_facesFromPartition(const size_t partition, const CSR_2D_Direction dir) const noexcept { return PIN_facesFromCells(PIN_cellsFromPartition(NEIGHBOR_partitionFromDirection(partition, dir))); }

public:
    /* Range functions, from a partition get a way to iterate through all the
     * nodes/cells/faces. Don't have faces ranges for the moment (FIXME). */
    inline auto RANGE_cellsFromPartition(const size_t partition) const noexcept -> const vector<Id>& { return m_partitions_cells.at(partition); }
    inline auto RANGE_nodesFromPartition(const size_t partition) const noexcept -> const vector<Id>& { return m_partitions_nodes.at(partition); }
    inline auto RANGE_facesFromPartition(const size_t partition) const noexcept -> const vector<Id>& { return m_partitions_faces.at(partition); }

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

#define __DEFINE_RANGE_FOR_SIDE_CELL(what)                                  \
    inline const vector<Id>&                                                \
    RANGE_##what##CellsFromPartition(const size_t partition) const noexcept \
    { return m_partitions_##what##_cells.at(partition); }
    __DEFINE_RANGE_FOR_SIDE_CELL(top)
    __DEFINE_RANGE_FOR_SIDE_CELL(bottom)
    __DEFINE_RANGE_FOR_SIDE_CELL(left)
    __DEFINE_RANGE_FOR_SIDE_CELL(right)
    __DEFINE_RANGE_FOR_SIDE_CELL(inner)
    __DEFINE_RANGE_FOR_SIDE_CELL(outer)
#undef __DEFINE_RANGE_FOR_SIDE_CELL

#define __DEFINE_RANGE_FOR_SIDE_FACE(what)                                  \
    inline const vector<Id>&                                                \
    RANGE_##what##FaceFromPartition(const size_t partition) const noexcept  \
    { return m_partitions_##what##_faces.at(partition); }
    __DEFINE_RANGE_FOR_SIDE_FACE(top)
    __DEFINE_RANGE_FOR_SIDE_FACE(bottom)
    __DEFINE_RANGE_FOR_SIDE_FACE(left)
    __DEFINE_RANGE_FOR_SIDE_FACE(right)
    __DEFINE_RANGE_FOR_SIDE_FACE(inner)
    __DEFINE_RANGE_FOR_SIDE_FACE(outer)
    __DEFINE_RANGE_FOR_SIDE_FACE(innerVertical)
    __DEFINE_RANGE_FOR_SIDE_FACE(innerHorizontal)
#undef __DEFINE_RANGE_FOR_SIDE_FACE

    /* Internal methods */
private:
    /* Don't move it around */
    CartesianPartition2D(const CartesianPartition2D &)      = delete;
    CartesianPartition2D(CartesianPartition2D &&)           = delete;
    CartesianPartition2D& operator=(CartesianPartition2D &) = delete;

    /* Helpers */
    inline Id PIN_nodesFromCells(const Id cell) const noexcept { return RANGE_nodesFromCells(cell)[0]; }
    inline Id PIN_facesFromCells(const Id cell) const noexcept { return RANGE_facesFromCells(cell)[0]; }

    inline const array<Id, 4>
    RANGE_facesFromCells(const Id cell) const noexcept
    {
        const size_t line   = cell / m_problem_x;
        const size_t column = cell % m_problem_x;
        return array <Id, 4>{
            /* bottom */ (cell * 2) + line,
            /* top    */ (line != (m_problem_y - 1))
                         /* not the last line */ ? (((cell + m_problem_x) * 2) + (line + 1))
                         /* the last top line */ : ((m_problem_x * m_problem_y - 1) * 2 + (m_problem_y + 2) + (cell % m_problem_x)),
            /* left   */ (cell * 2) + (line + 1),
            /* right  */ (cell * 2) + (line + 2) + (column != (m_problem_x - 1))
        };
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
        const size_t current_line = cell / m_problem_x;
        const size_t next_line    = current_line + 1;
        const Id next_cell        = cell + m_problem_x;
        return array<Id, 4>{
            /* bl */ cell + current_line,
            /* br */ cell + current_line + 1,
            /* tl */ next_cell + next_line,
            /* tr */ next_cell + next_line + 1,
        };
    }

    /* Attributes */
private:
    static inline uint32_t MAX_SHIFT = 0; /* Detected at generation time */

    const uint64_t m_problem_x;
    const uint64_t m_problem_y;

    CartesianMesh2D *m_mesh;

    /* Cells partition */
    map<Id, vector<Id>> m_partitions_cells;

    map<Id, vector<Id>> m_partitions_outer_cells;
    map<Id, vector<Id>> m_partitions_inner_cells;
    map<Id, vector<Id>> m_partitions_left_cells;
    map<Id, vector<Id>> m_partitions_right_cells;
    map<Id, vector<Id>> m_partitions_top_cells;
    map<Id, vector<Id>> m_partitions_bottom_cells;

    /* Nodes partitions */
    map<Id, vector<Id>> m_partitions_nodes;
    map<Id, vector<Id>> m_partitions_right_nodes;
    map<Id, vector<Id>> m_partitions_left_nodes;
    map<Id, vector<Id>> m_partitions_top_nodes;
    map<Id, vector<Id>> m_partitions_bottom_nodes;
    map<Id, vector<Id>> m_partitions_inner_nodes;

    /* Faces partitions */
    map<Id, vector<Id>> m_partitions_faces;
    map<Id, vector<Id>> m_partitions_right_faces;
    map<Id, vector<Id>> m_partitions_left_faces;
    map<Id, vector<Id>> m_partitions_top_faces;
    map<Id, vector<Id>> m_partitions_bottom_faces;
    map<Id, vector<Id>> m_partitions_inner_faces;
    map<Id, vector<Id>> m_partitions_outer_faces;
    map<Id, vector<Id>> m_partitions_innerVertical_faces;
    map<Id, vector<Id>> m_partitions_innerHorizontal_faces;

    /* Neighbors for partitions */
    map <Id, array<Id, 4>> m_partitions_neighbors;

    /* TODO List:
     * - Find a `cell -> face` relation
     * - Find a `node -> cell` relation
     * - Find a `face -> cell` relation
     *
     * TODO Return vector<Id>
     * - [D] getCellsOfNode
     * - [D] getCellsOfFaces
     * - [D] getNeighborCells
     * - [F](Once I have the relation cell->face) getFaces getTopFaces getBottomFaces getLeftFaces getRightFaces getOuterFaces getInnerFaces getInnerHorizontalFaces getInnerVerticalFaces
     *
     * TODO Return Id
     * - [D] getBackCell getFrontCell
     * - [D] getTopCell getBottomCell getLeftCell getRightCell
     * - [D] getBottomFaceNeighbour getBottomLeftFaceNeighbour getBottomRightFaceNeighbour
     * - [D] getTopFaceNeighbour getTopLeftFaceNeighbour getTopRightFaceNeighbour
     * - [D] getRightFaceNeighbour getLeftFaceNeighbour
     * - [D] getTopLeftNode getTopRightNode getBottomLeftNode getBottomRightNode
     */
};

}

#endif /* NABLALIB_MESH_CARTESIANPARTITION2D_H_ */
