/*******************************************************************************
 * Copyright (c) 2020 CEA
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 * Contributors: see AUTHORS file
 *******************************************************************************/
#include "nablalib/mesh/CartesianMesh2D.h"
#include "nablalib/utils/pnm/pnm.h"
#include <stdexcept>
#include <sstream>
#include <cassert>
#include <cstdlib>

template<typename T> static inline void
vector_uniq(vector<T> &vec)
{
    std::sort(vec.begin(), vec.end());
    vec.resize(distance(vec.begin(), unique(vec.begin(), vec.end())));
}

namespace math
{
template<typename T> static inline T min(T a, T b) { return a < b ? a : b; }
template<typename T> static inline T max(T a, T b) { return a > b ? a : b; }
}

namespace nablalib::mesh
{

    CartesianMesh2D::CartesianMesh2D(MeshGeometry<2>* geometry, const vector<Id>& inner_nodes_ids,
                                     const vector<Id>& top_nodes_ids, const vector<Id>& bottom_nodes_ids,
                                     const vector<Id>& left_nodes_ids, const vector<Id>& right_nodes_ids,
                                     const Id top_left_node_id, const Id top_right_node_id,
                                     const Id bottom_left_node_id, const Id bottom_right_node_id,
                                     const vector<Id>& inner_cells_ids_, const vector<Id>& outer_cells_ids_,
                                     const size_t problem_x, const size_t problem_y)
        : m_geometry(geometry)
          , m_inner_nodes(inner_nodes_ids)
          , m_top_nodes(top_nodes_ids)
          , m_bottom_nodes(bottom_nodes_ids)
          , m_left_nodes(left_nodes_ids)
          , m_right_nodes(right_nodes_ids)
          , m_top_left_node(top_left_node_id)
          , m_top_right_node(top_right_node_id)
          , m_bottom_left_node(bottom_left_node_id)
          , m_bottom_right_node(bottom_right_node_id)
          , m_top_faces(0)
          , m_bottom_faces(0)
          , m_left_faces(0)
          , m_right_faces(0)
          , m_inner_cells(inner_cells_ids_)
          , m_outer_cells(outer_cells_ids_)
          , m_nb_x_quads(bottom_nodes_ids.size() - 1)
          , m_nb_y_quads(left_nodes_ids.size() - 1)
          , m_problem_x(problem_x)
          , m_problem_y(problem_y)
    {
        if (CartesianMesh2D::PartitionNumber != 0) {
            /* Care aboit the partitions here */
            if ((math::min<uint64_t>(problem_x, problem_x) / CartesianMesh2D::PartitionNumber) <= MAX_SHIFT)
                abort();
        }

        // faces partitionment
        const auto& edges = m_geometry->getEdges();
        for (size_t edgeId(0); edgeId < edges.size(); ++edgeId) {
            m_faces.emplace_back(edgeId);
            // Top boundary faces
            if (edgeId >= 2 * m_nb_x_quads * m_nb_y_quads + m_nb_y_quads) m_top_faces.emplace_back(edgeId);
            // Bottom boundary faces
            if ((edgeId < 2 * m_nb_x_quads) && (edgeId % 2 == 0)) m_bottom_faces.emplace_back(edgeId);
            // Left boundary faces
            if ((edgeId % (2 * m_nb_x_quads + 1) == 1) &&  (edgeId < (2 * m_nb_x_quads + 1) * m_nb_y_quads)) m_left_faces.emplace_back(edgeId);
            // Right boundary faces
            if (edgeId % (2 * m_nb_x_quads + 1) == 2 * m_nb_x_quads) m_right_faces.emplace_back(edgeId);
            // Outer Faces
            if (!isInnerEdge(edges[edgeId])) {
                m_outer_faces.emplace_back(edgeId);
            } else {
                m_inner_faces.emplace_back(edgeId);
                if (isVerticalEdge(edges[edgeId])) {
                    m_inner_vertical_faces.emplace_back(edgeId);
                } else if (isHorizontalEdge(edges[edgeId])) {
                    m_inner_horizontal_faces.emplace_back(edgeId);
                } else {
                    stringstream msg;
                    msg << "The inner edge " << edgeId << " should be either vertical or horizontal" << endl;
                    throw runtime_error(msg.str());
                }
            }
        }
        // Construction of boundary cell sets
        const auto& cells = m_geometry->getQuads();
        for (size_t cellId(0); cellId < cells.size(); ++cellId) {
            size_t i,j;
            tie(i, j) = id2IndexCell(cellId);
            // Top boundary cells
            if (i == m_nb_y_quads - 1) m_top_cells.emplace_back(cellId);
            // Bottom boundary cells
            if (i == 0) m_bottom_cells.emplace_back(cellId);
            // Left boundary cells
            if (j == 0) m_left_cells.emplace_back(cellId);
            // Right boundary cells
            if (j == m_nb_x_quads - 1) m_right_cells.emplace_back(cellId);
        }

        if (CartesianMesh2D::PartitionNumber != 0) {
            /* Create the partitions because we care about them here */
            idx_t *metis_partition_cell = createPartitions();
            computePartialPartitions();
            computeNeighborPartitions(metis_partition_cell);
            printPartialPartitions();
        }
    }

    vector<Id>
    CartesianMesh2D::getCellsOfNode(const Id& nodeId) const noexcept
    {
        vector<Id> cells;
        size_t i,j;
        tie(i, j) = id2IndexNode(nodeId);
        if (i < m_nb_y_quads && j < m_nb_x_quads) cells.emplace_back(index2IdCell(i, j));
        if (i < m_nb_y_quads && j > 0)            cells.emplace_back(index2IdCell(i, j-1));
        if (i > 0            && j < m_nb_x_quads) cells.emplace_back(index2IdCell(i-1, j));
        if (i > 0            && j > 0)            cells.emplace_back(index2IdCell(i-1, j-1));
        return cells;
    }

    vector<Id>
    CartesianMesh2D::getCellsOfFace(const Id& faceId) const
    {
        vector<Id> cells;
        size_t i_f = static_cast<size_t>(faceId) / (2 * m_nb_x_quads + 1);
        size_t k_f = static_cast<size_t>(faceId) - i_f * (2 * m_nb_x_quads + 1);

        if (i_f < m_nb_y_quads) {  // all except upper bound faces
            if (k_f == 2 * m_nb_x_quads) {  // right bound edge
                cells.emplace_back(index2IdCell(i_f, m_nb_x_quads-1));
            }
            else if (k_f == 1) {  // left bound edge
                cells.emplace_back(index2IdCell(i_f, 0));
            }
            else if (k_f % 2 == 0) {  // horizontal edge
                if (i_f > 0)  // Not bottom bound edge
                    cells.emplace_back(index2IdCell(i_f-1, k_f/2));
                cells.emplace_back(index2IdCell(i_f, k_f/2));
            }
            else {  // vertical edge (neither left bound nor right bound)
                cells.emplace_back(index2IdCell(i_f, (k_f-1)/2 - 1));
                cells.emplace_back(index2IdCell(i_f, (k_f-1)/2));
            }
        } else {  // upper bound faces
            cells.emplace_back(index2IdCell(i_f-1, k_f));
        }
        return cells;
    }

    vector<Id>
    CartesianMesh2D::getNeighbourCells(const Id& cellId) const
    {
        std::vector<Id> neighbours;
        size_t i,j;
        tie(i, j) = id2IndexCell(cellId);
        if (i >= 1) neighbours.emplace_back(index2IdCell(i-1, j));
        if (i < m_nb_y_quads-1) neighbours.emplace_back(index2IdCell(i+1, j));
        if (j >= 1) neighbours.emplace_back(index2IdCell(i, j-1));
        if (j < m_nb_x_quads-1) neighbours.emplace_back(index2IdCell(i, j+1));
        return neighbours;
    }

    vector<Id>
    CartesianMesh2D::getFacesOfCell(const Id& cellId) const
    {
        size_t i,j;
        tie(i, j) = id2IndexCell(cellId);
        Id bottom_face(static_cast<Id>(2 * j + i * (2 * m_nb_x_quads + 1)));
        Id left_face(bottom_face + 1);
        Id right_face(bottom_face + static_cast<Id>(j == m_nb_x_quads-1 ? 2 : 3));
        Id top_face(bottom_face + static_cast<Id>(i < m_nb_y_quads-1 ? 2 * m_nb_x_quads + 1 : 2 * m_nb_x_quads + 1 - j));
        return vector<Id>({bottom_face, left_face, right_face, top_face});
    }

    Id
    CartesianMesh2D::getCommonFace(const Id& cellId1, const Id& cellId2) const
    {
        auto cell1Faces{getFacesOfCell(cellId1)};
        auto cell2Faces{getFacesOfCell(cellId2)};
        auto result = find_first_of(cell1Faces.begin(), cell1Faces.end(), cell2Faces.begin(), cell2Faces.end());
        if (result == cell1Faces.end()) {
            stringstream msg;
            msg << "No common faces found between cell " << cellId1 << " and cell " << cellId2 << endl;
            throw runtime_error(msg.str());
        }
        return *result;
    }

    Id
    CartesianMesh2D::getBackCell(const Id& faceId) const
    {
        vector<Id> cells(getCellsOfFace(faceId));
        if (cells.size() < 2) {
            stringstream msg;
            msg << "Error in getBackCell(" << faceId << "): please consider using this method with inner face only." << endl;
            throw runtime_error(msg.str());
        }
        return cells[0];
    }

    Id
    CartesianMesh2D::getFrontCell(const Id& faceId) const
    {
        vector<Id> cells(getCellsOfFace(faceId));
        if (cells.size() < 2) {
            stringstream msg;
            msg << "Error in getFrontCell(" << faceId << "): please consider using this method with inner face only." << endl;
            throw runtime_error(msg.str());
        }
        return cells[1];
    }

    size_t
    CartesianMesh2D::getNbCommonIds(const vector<Id>& as, const vector<Id>& bs) const noexcept
    {
        size_t nbCommonIds = 0;
        for (auto a : as) {
            for (auto b : bs)
                if (a == b) nbCommonIds++;
        }
        return nbCommonIds;
    }

    bool
    CartesianMesh2D::isInnerEdge(const Edge& e) const noexcept
    {
        size_t i1, i2, j1, j2;
        tie(i1, j1) = id2IndexNode(e.getNodeIds()[0]);
        tie(i2, j2) = id2IndexNode(e.getNodeIds()[1]);
        // If nodes are located on the same boundary, then the face is an outer one
        if ((i1 == 0 && i2 == 0) || (i1 == m_nb_y_quads && i2 == m_nb_y_quads) ||
            (j1 == 0 && j2 == 0) || (j1 == m_nb_x_quads && j2 == m_nb_x_quads))
            return false;
        // else it's an inner one
        return true;
    }

    Id
    CartesianMesh2D::getBottomFaceOfCell(const Id& cellId) const noexcept
    {
        size_t i,j;
        tie(i, j) = id2IndexCell(cellId);
        Id bottom_face(static_cast<Id>(2 * j + i * (2 * m_nb_x_quads + 1)));
        return bottom_face;
    }

    Id
    CartesianMesh2D::getLeftFaceOfCell(const Id& cellId) const noexcept
    {
        Id left_face(getBottomFaceOfCell(cellId) + 1);
        return left_face;
    }

    Id
    CartesianMesh2D::getRightFaceOfCell(const Id& cellId) const noexcept
    {
        size_t i,j;
        tie(i, j) = id2IndexCell(cellId);
        Id bottom_face(static_cast<Id>(2 * j + i * (2 * m_nb_x_quads + 1)));
        Id right_face(bottom_face + static_cast<Id>(j == m_nb_x_quads - 1 ? 2 : 3));
        return right_face;
    }

    Id
    CartesianMesh2D::getTopFaceOfCell(const Id& cellId) const noexcept
    {
        size_t i,j;
        tie(i, j) = id2IndexCell(cellId);
        Id bottom_face(static_cast<Id>(2 * j + i * (2 * m_nb_x_quads + 1)));
        Id top_face(bottom_face + static_cast<Id>(i < m_nb_y_quads - 1 ? 2 * m_nb_x_quads + 1 : 2 * m_nb_x_quads + 1 - j));
        return top_face;
    }

    Id
    CartesianMesh2D::getTopCell(const Id& cellId) const noexcept
    {
        size_t i,j;
        tie(i, j) = id2IndexCell(cellId);
        if (i == m_nb_y_quads-1) return cellId;
        return index2IdCell(i+1, j);
    }

    Id
    CartesianMesh2D::getBottomCell(const Id& cellId) const noexcept
    {
        size_t i,j;
        tie(i, j) = id2IndexCell(cellId);
        if (i==0) return cellId;
        return index2IdCell(i-1, j);
    }

    Id
    CartesianMesh2D::getLeftCell(const Id& cellId) const noexcept
    {
        size_t i,j;
        tie(i, j) = id2IndexCell(cellId);
        if (j==0) return cellId;
        return index2IdCell(i, j-1);
    }

    Id
    CartesianMesh2D::getRightCell(const Id& cellId) const noexcept
    {
        size_t i,j;
        tie(i, j) = id2IndexCell(cellId);
        if (j == m_nb_x_quads-1)  return cellId;
        return index2IdCell(i, j+1);
    }

    /*
     * Definitions for later functions:
     *
     *            |-27-|-28-|-29-|-30-|
     *           19   21   23   25   26
     *            |-18-|-20-|-22-|-24-|
     *           10   12   14   16   17
     *            |--9-|-11-|-13-|-15-|
     *            1    3    5    7    8
     *            |-0--|-2--|-4--|-6--|
     *
     * E.g. with face number 14: (i.e. vertical face)
     *      - Bottom Face = 5
     *      - Bottom Left Face = 11
     *      - Bottom Right Face = 13
     *      - Top Face = 23
     *      - Top Left Face = 20
     *      - Top Right Face = 22
     *      - Left Face = 12
     *      - Right Face = 16
     *
     * E.g. with face number 13: (i.e. horizontal face)
     *      - Bottom Face = 4
     *      - Bottom Left Face = 5
     *      - Bottom Right Face = 7
     *      - Top Face = 22
     *      - Top Left Face = 14
     *      - Top Right Face = 16
     *      - Left Face = 11
     *      - Right Face = 15
     */


    Id CartesianMesh2D::getBottomFaceNeighbour(const Id& faceId) const
    {
        const Edge& face(m_geometry->getEdges()[faceId]);
        assert(isInnerEdge(face));
        return (faceId - (2 * m_nb_x_quads + 1));
    }

    Id CartesianMesh2D::getBottomLeftFaceNeighbour(const Id& faceId) const
    {
        const Edge& face(m_geometry->getEdges()[faceId]);
        assert(isInnerEdge(face));
        if (isVerticalEdge(face))
            return (faceId - 3);
        else  // horizontal
            return ((faceId + 1) - (2 * m_nb_x_quads + 1));
    }

    Id CartesianMesh2D::getBottomRightFaceNeighbour(const Id& faceId) const
    {
        const Edge& face(m_geometry->getEdges()[faceId]);
        assert(isInnerEdge(face));
        if (isVerticalEdge(face))
            return (faceId - 1);
        else  // horizontal
            return ((faceId + 3) - (2 * m_nb_x_quads + 1));
    }

    Id CartesianMesh2D::getTopFaceNeighbour(const Id& faceId) const
    {
        const Edge& face(m_geometry->getEdges()[faceId]);
        assert(isInnerEdge(face));
        return (faceId + (2 * m_nb_x_quads + 1));
    }

    Id CartesianMesh2D::getTopLeftFaceNeighbour(const Id& faceId) const
    {
        const Edge& face(m_geometry->getEdges()[faceId]);
        assert(isInnerEdge(face));
        if (isVerticalEdge(face))
            return ((faceId - 3) + (2 * m_nb_x_quads + 1));
        else  // horizontal
            return (faceId + 1);
    }

    Id CartesianMesh2D::getTopRightFaceNeighbour(const Id& faceId) const
    {
        const Edge& face(m_geometry->getEdges()[faceId]);
        assert(isInnerEdge(face));
        if (isVerticalEdge(face))
            return ((faceId - 1) + (2 * m_nb_x_quads + 1));
        else  // horizontal
            return (faceId + 3);
    }

    Id CartesianMesh2D::getRightFaceNeighbour(const Id& faceId) const
    {
        const Edge& face(m_geometry->getEdges()[faceId]);
        assert(isInnerEdge(face));
        return (faceId + 2);
    }

    Id CartesianMesh2D::getLeftFaceNeighbour(const Id& faceId) const
    {
        const Edge& face(m_geometry->getEdges()[faceId]);
        assert(isInnerEdge(face));
        return (faceId - 2);
    }

    pair<size_t, size_t>
    CartesianMesh2D::id2IndexCell(const Id& k) const noexcept
    {
        size_t i(static_cast<size_t>(k) / m_nb_x_quads);
        size_t j(static_cast<size_t>(k) - i * m_nb_x_quads);
        return make_pair(i, j);
    }

    pair<size_t, size_t>
    CartesianMesh2D::id2IndexNode(const Id& k) const noexcept
    {
        size_t i(static_cast<size_t>(k) / (m_nb_x_quads + 1));
        size_t j(static_cast<size_t>(k) - i * (m_nb_x_quads + 1));
        return make_pair(i, j);
    }

    vector<Id>
    CartesianMesh2D::cellsOfNodeCollection(const vector<Id>& nodes)
    {
        vector<Id> cells(0);
        for (auto&& node_id : nodes) {
            for (auto&& cell_id : getCellsOfNode(node_id))
                cells.emplace_back(cell_id);
        }
        // Deleting duplicates
        std::sort(cells.begin(), cells.end());
        cells.erase(std::unique(cells.begin(), cells.end()), cells.end());
        return cells;
    }

    /*********************************
     * Partition constructor methods *
     *********************************/

    void
    CartesianMesh2D::printPartialPartitions() noexcept
    {
        for (size_t i = 0; i < CartesianMesh2D::PartitionNumber; ++i) {
            const size_t max_length = std::to_string(m_partitions_cells[0].size() * 4).size() + 1;
            std::cout << "Partition " << std::setw(max_length) << i << ":\n\t"
                      /* CELLS */
                      << m_partitions_cells[i].size() << " cells"
                      << " (t "   << std::setw(max_length) << m_partitions_top_cells[i].size()
                      << ", b "   << std::setw(max_length) << m_partitions_bottom_cells[i].size()
                      << ", r "   << std::setw(max_length) << m_partitions_right_cells[i].size()
                      << ", l "   << std::setw(max_length) << m_partitions_left_cells[i].size()
                      << ", in "  << std::setw(max_length) << m_partitions_inner_cells[i].size()
                      << ", out " << std::setw(max_length) << m_partitions_outer_cells[i].size()
                      << ")\n\t"
                      /* NODES */
                      << m_partitions_nodes[i].size() << " nodes"
                      << " (t "   << std::setw(max_length) << m_partitions_top_nodes[i].size()
                      << ", b "   << std::setw(max_length) << m_partitions_bottom_nodes[i].size()
                      << ", r "   << std::setw(max_length) << m_partitions_right_nodes[i].size()
                      << ", l "   << std::setw(max_length) << m_partitions_left_nodes[i].size()
                      << ", in "  << std::setw(max_length) << m_partitions_inner_nodes[i].size()
                      << ")\n\t"
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
                      << ")\n\t"
                      /* NEIGHBORS */
                      << "neighbors: ";
            for (const Id part : m_partitions_neighbors[i])
                std::cout << "  " << part;
            std::cout << "\n";
        }

        std::cout << "Totals: \n\t"
                  << getNbCells()                << " cells, "
                  << getNbNodes()                << " nodes, "
                  << getNbFaces()                << " faces\n\t"
                  << getNbTopFaces()             << " T faces, "
                  << getNbBottomFaces()          << " B faces, "
                  << getNbRightFaces()           << " R faces, "
                  << getNbLeftFaces()            << " L faces, "
                  << getNbInnerFaces()           << " I faces, "
                  << getNbInnerHorizontalFaces() << " IH faces, "
                  << getNbInnerVerticalFaces()   << " IV faces, "
                  << getNbOuterFaces()           << " O faces\n";

        std::cout << "Reverse links (for " << CartesianMesh2D::PartitionNumber << " partitions): \n";
        for (size_t i = 0; i < CartesianMesh2D::PartitionNumber; ++i) {
            std::cout << "\tPartition " << i << ":"
                      << "\tcells " << std::count(m_cells_to_partitions.begin(), m_cells_to_partitions.end(), i)
                      << "\tnodes " << std::count(m_nodes_to_partitions.begin(), m_nodes_to_partitions.end(), i)
                      << "\tfaces " << std::count(m_faces_to_partitions.begin(), m_faces_to_partitions.end(), i)
                      << "\n";
        }
        std::cout << "PARTITIONS MESSAGES END\n" << std::endl;
    }

    idx_t*
    CartesianMesh2D::createPartitions() noexcept
    {
        /* 1 partition case */
        if (CartesianMesh2D::PartitionNumber == 1) {
            idx_t *metis_partition_cell = new idx_t[m_problem_x * m_problem_y]();
            m_cells_to_partitions.resize(getNbCells());
            m_nodes_to_partitions.resize(getNbNodes());
            m_faces_to_partitions.resize(getNbFaces());

            for (size_t i = 0; i < m_problem_x * m_problem_y; ++i) {
                m_partitions_cells[0].emplace_back(i);

                const array<Id, 4> nodes = RANGE_nodesFromCells(i);
                m_partitions_nodes[0].emplace_back(nodes[0]);
                m_partitions_nodes[0].emplace_back(nodes[1]);
                m_partitions_nodes[0].emplace_back(nodes[2]);
                m_partitions_nodes[0].emplace_back(nodes[3]);

                const array<Id, 4> faces = RANGE_facesFromCells(i);
                m_partitions_faces[0].emplace_back(faces[0]);
                m_partitions_faces[0].emplace_back(faces[1]);
                m_partitions_faces[0].emplace_back(faces[2]);
                m_partitions_faces[0].emplace_back(faces[3]);

                metis_partition_cell[i] = 0;

                /* Reverse links */
                m_cells_to_partitions[i] = 0;

                m_nodes_to_partitions[nodes[0]] = 0;
                m_nodes_to_partitions[nodes[1]] = 0;
                m_nodes_to_partitions[nodes[2]] = 0;
                m_nodes_to_partitions[nodes[3]] = 0;

                m_faces_to_partitions[faces[0]] = 0;
                m_faces_to_partitions[faces[1]] = 0;
                m_faces_to_partitions[faces[2]] = 0;
                m_faces_to_partitions[faces[3]] = 0;
            }
            return metis_partition_cell;
        }

        /* multi partitions case */
        CSR_Matrix matrix     = CSR_Matrix::createFrom2DCartesianMesh(m_problem_x, m_problem_y);
        idx_t num_partition   = CartesianMesh2D::PartitionNumber;
        idx_t num_constraints = 1;  // Number of balancing constraints, which must be at least 1.
        idx_t objval;               // On return, the edge cut volume of the partitioning solution.
        idx_t *metis_partition_cell = (idx_t *) malloc(sizeof(idx_t) * (matrix.xadj_len));
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
                                  metis_options, &objval, metis_partition_cell);
        if (METIS_OK != ret) {
            std::cerr << "Invalid return from metis\n";
            abort();
        }

        std::cout << "Edge cut is: " << objval << "\n";

        m_cells_to_partitions.resize(getNbCells());
        m_nodes_to_partitions.resize(getNbNodes());
        m_faces_to_partitions.resize(getNbFaces());

        for (idx_t i = 0; i < matrix.xadj_len; ++i) {
            m_partitions_cells[metis_partition_cell[i]].emplace_back(i);

            const array<Id, 4> nodes = RANGE_nodesFromCells(i);
            const array<Id, 4> faces = RANGE_facesFromCells(i);

            /* Add in revere links. What to do if a node is in multiple partitions?
             * => In case of multiple links, link to the partition with the higher ID number.
             */

            m_cells_to_partitions[i] = metis_partition_cell[i];

            m_nodes_to_partitions[nodes[0]] = metis_partition_cell[i];
            m_nodes_to_partitions[nodes[1]] = metis_partition_cell[i];
            m_nodes_to_partitions[nodes[2]] = metis_partition_cell[i];
            m_nodes_to_partitions[nodes[3]] = metis_partition_cell[i];

            m_faces_to_partitions[faces[0]] = metis_partition_cell[i];
            m_faces_to_partitions[faces[1]] = metis_partition_cell[i];
            m_faces_to_partitions[faces[2]] = metis_partition_cell[i];
            m_faces_to_partitions[faces[3]] = metis_partition_cell[i];
        }

        /* Partition to node relation */
        for (size_t node = 0; node < m_nodes_to_partitions.size(); ++node) {
            const size_t part = m_nodes_to_partitions[node];
            m_partitions_nodes[part].emplace_back(node);
        }

        /* Partition to face relation */
        for (size_t face = 0; face < m_faces_to_partitions.size(); ++face) {
            const size_t part = m_faces_to_partitions[face];
            m_partitions_faces[part].emplace_back(face);
        }

        if (NULL != getenv("NABLA_DEBUG_PARTITION")) {
            /* Cell debug => sample HowTo */
            {
                /* Partition to cell debug */
                for (int part = 0; part < CartesianMesh2D::PartitionNumber; ++part) {
                    std::string file_name = "partition_" + std::to_string(part) + "_to_cells.pgm";
                    pnm_file *file = pnm_file_new(m_problem_x, m_problem_y, file_name.c_str());
                    for (const Id cell : m_partitions_cells[part])
                        file->bitmap[cell] = 255;
                    assert(!pnm_file_close(file));
                }

                /* Cell to partition debug */
                for (int part = 0; part < CartesianMesh2D::PartitionNumber; ++part) {
                    std::string file_name = "cell_to_partition" + std::to_string(part) + ".pgm";
                    pnm_file *file = pnm_file_new(m_problem_x, m_problem_y, file_name.c_str());
                    for (int cell = 0; cell < m_problem_x * m_problem_y; ++cell) {
                        if (m_cells_to_partitions[cell] == part)
                            file->bitmap[cell] = 255;
                    }
                    assert(!pnm_file_close(file));
                }
            }

            /* Node debug */
            {
                /* Partition to node debug */
                for (int part = 0; part < CartesianMesh2D::PartitionNumber; ++part) {
                    std::string file_name = "partition_" + std::to_string(part) + "_to_nodes.pgm";
                    pnm_file *file = pnm_file_new(m_problem_x + 1, m_problem_y + 1, file_name.c_str());
                    for (const Id node : m_partitions_nodes[part]) {
                        auto [x, y] = id2IndexNode(node);
                        file->bitmap[node] = 255;
                    }
                    assert(!pnm_file_close(file));
                }

                /* Node to partition debug */
                for (int part = 0; part < CartesianMesh2D::PartitionNumber; ++part) {
                    std::string file_name = "node_to_partition" + std::to_string(part) + ".pgm";
                    pnm_file *file = pnm_file_new(m_problem_x + 1, m_problem_y + 1, file_name.c_str());
                    for (int node = 0; node < (m_problem_x + 1) * (m_problem_y + 1); ++node) {
                        if (m_nodes_to_partitions[node] == part)
                            file->bitmap[node] = 255;
                    }
                    assert(!pnm_file_close(file));
                }
            }
        }

        CSR_Matrix::free(matrix);
        return metis_partition_cell;
    }

    void
    CartesianMesh2D::computeNeighborPartitions(idx_t *metis_partition_cell) noexcept
    {
        /* computePartialPartitions and createPartitions have been called at
         * this point. NOTE: metis_partition_cell must have
         * `m_problem_x * m_problem_y` elements inside.
         *
         * The Algo:
         * For All p In partitions, c In Partition(p), cn In Neighbor(c),
         * => If PartNum(cn) != p Then Neighbor(p) += { PartNum(cn) }
         */

    #define ___CHECK_NEIGHBOR_CELL(dir)                                                 \
    if (getCellNeighbor(m_problem_x, m_problem_y, x, y, CSR_2D_Direction::dir, cn)) {   \
        const Id cnid       = getCellIdFromCoordinate(m_problem_x, m_problem_y, cn);    \
        const Id partnum_cn = metis_partition_cell[cnid];                               \
        /* If PartNum(cn) != p Then Neighbor(p) += { PartNum(cn) } */                   \
        if (partnum_cn != i) m_partitions_neighbors[i].push_back(partnum_cn);           \
    }

        m_partitions_neighbors.resize(CartesianMesh2D::PartitionNumber);

        // For All p In partitions
        #pragma omp parallel for
        for (size_t i = 0; i < CartesianMesh2D::PartitionNumber; ++i) {
            m_partitions_neighbors[i] = vector<Id>{i};

            // For All c In Partition(p)
            for (const Id cellid : m_partitions_cells[i]) {
                auto[x, y] = getCellCoordinateFromId(m_problem_x, m_problem_y, cellid);
                pair<Id, Id> cn;

                // For All cn In Neighbor(c),
                // => If PartNum(cn) != p Then Neighbor(p) += { PartNum(cn) }
                ___CHECK_NEIGHBOR_CELL(NORTH);
                ___CHECK_NEIGHBOR_CELL(SOUTH);
                ___CHECK_NEIGHBOR_CELL(EAST);
                ___CHECK_NEIGHBOR_CELL(WEST);
            }

            vector_uniq(m_partitions_neighbors[i]);
        }

        #undef ___CHECK_NEIGHBOR_CELL

        std::free(metis_partition_cell);
    }

    void
    CartesianMesh2D::computePartialPartitions() noexcept
    {
        #define ___POPULATE_PARTITIONS(type, what, from) {                                                  \
        std::set_intersection(get##from().begin(), get##from().end(),                                       \
                              m_partitions_##type[i].begin(), m_partitions_##type[i].end(),                 \
                              std::back_inserter(m_partitions_##what##_##type[i]));                         \
        for (size_t index_in_partition = 0; index_in_partition < m_partitions_##what##_##type[i].size(); ++index_in_partition) { \
            for (size_t index = 0; index < get##from().size(); ++index) {                                   \
                if (get##from()[index] == m_partitions_##what##_##type[i][index_in_partition]) {            \
                    m_partitions_##what##_##type[i][index_in_partition] = index;                            \
                    break;                                                                                  \
                }                                                                                           \
            }                                                                                               \
        }}
        /* Quick and dirty parallelisation for independent loop's body */
        #pragma omp parallel for
        for (size_t i = 0; i < CartesianMesh2D::PartitionNumber; ++i) {
            vector_uniq(m_partitions_nodes[i]);
            vector_uniq(m_partitions_faces[i]);
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
    }

    /* Get items from a partition */

    const array<Id, 4>
    CartesianMesh2D::RANGE_facesFromCells(const Id cell) const noexcept
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

    const array<Id, 4>
    CartesianMesh2D::RANGE_nodesFromCells(const Id cell) const noexcept
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

#define ___SANITIZE_PARTITION_INDEX(index)      { if (index >= CartesianMesh2D::PartitionNumber) abort(); }
#define ___SANITIZE_NEIGHBOR_INDEX(part, index) { if (m_partitions_neighbors.at(part).size() <= (index)) index = 0; }
    size_t
    CartesianMesh2D::NEIGHBOR_getNumberForPartition(size_t partition) const noexcept
    {
        ___SANITIZE_PARTITION_INDEX(partition);
        return m_partitions_neighbors.at(partition).size();
    }

    size_t
    CartesianMesh2D::NEIGHBOR_getForPartition(size_t partition, size_t neighbor_index) const noexcept
    {
        ___SANITIZE_PARTITION_INDEX(partition);
        ___SANITIZE_NEIGHBOR_INDEX(partition, neighbor_index);
        return m_partitions_neighbors.at(partition).at(neighbor_index);
    }
#undef ___SANITIZE_PARTITION_INDEX

    /* CSR Matrix methods */

    CSR_Matrix
    CSR_Matrix::createFrom2DCartesianMesh(size_t X, size_t Y) noexcept
    {
        /* Will std::terminate on out of memory */
        CSR_Matrix ret;
        ret.xadj_len   = (X * Y);
        ret.adjncy_len = (4 * 2)                                // Corners
                       + (2 * (X - 2) * 3) + (2 * (Y - 2) * 3)  // Border
                       + (4 * (X - 2) * (Y - 2));               // Inner
        ret.xadj       = (idx_t *) malloc(sizeof(idx_t) * (ret.xadj_len + 1));
        ret.adjncy     = (idx_t *) malloc(sizeof(idx_t) * (ret.adjncy_len));

        pair<Id, Id> neighbor_{};
    #define ___ADD_NEIGHBOR(dir)                                             \
    if (getCellNeighbor(X, Y, x, y, CSR_2D_Direction::dir, neighbor_)) {     \
        ret.adjncy[adjncy_index] = getCellIdFromCoordinate(X, Y, neighbor_); \
        adjncy_index++;                                                      \
    } // else { std::cerr << "No " #dir " neighbor for (x: " << x << ", y:" << y << ")\n"; }
        size_t xadj_index   = 0;
        size_t adjncy_index = 0;
        for (size_t y = 0; y < Y; ++y) {
            for (size_t x = 0; x < X; ++x) {
                ret.xadj[xadj_index] = adjncy_index;
                ___ADD_NEIGHBOR(SOUTH);
                ___ADD_NEIGHBOR(WEST);
                ___ADD_NEIGHBOR(EAST);
                ___ADD_NEIGHBOR(NORTH);
                xadj_index++; /* Because there is at least one neighbor */
            }
        }
    #undef ___ADD_NEIGHBOR

        ret.xadj[ret.xadj_len] = ret.adjncy_len; // For metis
        return ret;
    }

    void
    CSR_Matrix::free(CSR_Matrix &matrix) noexcept
    {
        if (matrix.xadj)    std::free((void *) matrix.xadj);
        if (matrix.adjncy)  std::free((void *) matrix.adjncy);
        matrix.xadj_len   = 0;
        matrix.adjncy_len = 0;
    }

    bool
    getCellNeighbor(const size_t X, const size_t Y, const size_t x, const size_t y,
                    CSR_2D_Direction dir, pair<Id, Id> &ret) noexcept
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

    pair<Id, Id>
    getCellCoordinateFromId(const size_t X, const size_t Y, const Id cellid) noexcept
    {
        return pair<Id, Id>{
            cellid % X,
            cellid / X
        };
    }

    Id
    getCellIdFromCoordinate(const size_t X, const size_t Y, const pair<Id, Id> &coo) noexcept
    {
        return coo.first + coo.second * X;
    }
}
