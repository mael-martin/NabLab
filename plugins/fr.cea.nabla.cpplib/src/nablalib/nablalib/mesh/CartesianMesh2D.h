/*******************************************************************************
 * Copyright (c) 2020 CEA
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 * Contributors: see AUTHORS file
 *******************************************************************************/
#ifndef NABLALIB_MESH_CARTESIANMESH2D_H_
#define NABLALIB_MESH_CARTESIANMESH2D_H_

/* Need NABLALIB_DEBUG to be defined */
#ifndef NABLALIB_DEBUG
#define NABLALIB_DEBUG 0
#endif

#include <utility>
#include <cstdint>
#include <cmath>
#include <algorithm>
#include <map>
#include <cstdlib>
#include <iomanip>
#include <memory>
#include <stdio.h>
#include "metis-5.1.0/include/metis.h"
#include "nablalib/types/Types.h"
#include "nablalib/mesh/MeshGeometry.h"

/* Note: the mesh is as follows for the nodes and cells. The faces don't seem
 * to follow the graph in the Factory source file.
 *  15---16---17---18---19
 *   | 8  | 9  | 10 | 11 |
 *  10---11---12---13---14
 *   | 4  | 5  | 6  | 7  |
 *   5----6----7----8----9
 *   | 0  | 1  | 2  | 3  |
 *   0----1----2----3----4
 */

using namespace std;

/* Mesh namespace */
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

bool getCellNeighbor(const size_t X, const size_t Y, const size_t x, const size_t y, CSR_2D_Direction dir, pair<Id, Id> &ret) noexcept;
pair<Id, Id> getCellCoordinateFromId(const size_t X, const size_t Y, const Id cellid) noexcept;
Id getCellIdFromCoordinate(const size_t X, const size_t Y, const pair<Id, Id> &coo) noexcept;

/* Create CSR matrix from a 2D cartesian mesh */
struct CSR_Matrix
{
    idx_t* xadj      { nullptr };
    idx_t* adjncy    { nullptr };
    idx_t xadj_len   { 0 };
    idx_t adjncy_len { 0 };

    static CSR_Matrix createFrom2DCartesianMesh(size_t X, size_t Y) noexcept;
    static void free(CSR_Matrix &matrix) noexcept;
};

/* The cartesian mesh 2D class */
class CartesianMesh2D
{
/* Constructor and global things */
public:
    static constexpr int MaxNbNodesOfCell = 4;
    static constexpr int MaxNbNodesOfFace = 2;
    static constexpr int MaxNbCellsOfNode = 4;
    static constexpr int MaxNbCellsOfFace = 2;
    static constexpr int MaxNbFacesOfCell = 4;
    static constexpr int MaxNbNeighbourCells = 4;

    /* For the partitions, set before calling the construcor */
    static void setPartitionNumber(size_t num)      noexcept { PartitionNumber = num; }
    static void setMaxDataShift(uint32_t max_shift) noexcept { MAX_SHIFT = max_shift; }
    static size_t getPartitionNumber() noexcept { return PartitionNumber; }

    uint64_t getProblemX() const noexcept { return m_problem_x; }
    uint64_t getProblemY() const noexcept { return m_problem_y; }

    CartesianMesh2D(MeshGeometry<2>* geometry, const vector<Id>& inner_nodes_ids,
                  const vector<Id>& top_nodes_ids, const vector<Id>& bottom_nodes_ids,
                  const vector<Id>& left_nodes_ids, const vector<Id>& right_nodes_ids,
                  const Id top_left_node_id, const Id top_right_node_id,
                  const Id bottom_left_node_id, const Id bottom_right_node_id,
                  const vector<Id>& inner_cells_ids_ , const vector<Id>& outer_cells_ids_,
                  const size_t problem_x, const size_t problem_y);

    MeshGeometry<2>* getGeometry() noexcept { return m_geometry; }

/* Mesh methods */
public:
    size_t getNbNodes() const noexcept { return m_geometry->getNodes().size(); }
    size_t getNbCells() const noexcept { return m_geometry->getQuads().size(); }
    size_t getNbFaces() const noexcept { return m_geometry->getEdges().size(); }
    const vector<Id>& getFaces() const noexcept { return m_faces; }

    size_t getNbInnerNodes()  const noexcept { return m_inner_nodes.size();  }
    size_t getNbTopNodes()    const noexcept { return m_top_nodes.size();    }
    size_t getNbBottomNodes() const noexcept { return m_bottom_nodes.size(); }
    size_t getNbLeftNodes()   const noexcept { return m_left_nodes.size();   }
    size_t getNbRightNodes()  const noexcept { return m_right_nodes.size();  }
    const vector<Id>& getInnerNodes()  const noexcept { return m_inner_nodes;  }
    const vector<Id>& getTopNodes()    const noexcept { return m_top_nodes;    }
    const vector<Id>& getBottomNodes() const noexcept { return m_bottom_nodes; }
    const vector<Id>& getLeftNodes()   const noexcept { return m_left_nodes;   }
    const vector<Id>& getRightNodes()  const noexcept { return m_right_nodes;  }

    size_t getNbInnerCells()  const noexcept { return m_inner_cells.size();  }
    size_t getNbOuterCells()  const noexcept { return m_outer_cells.size();  }
    size_t getNbTopCells()    const noexcept { return m_top_cells.size();    }
    size_t getNbBottomCells() const noexcept { return m_bottom_cells.size(); }
    size_t getNbLeftCells()   const noexcept { return m_left_cells.size();   }
    size_t getNbRightCells()  const noexcept { return m_right_cells.size();  }
    const vector<Id>& getInnerCells()  const noexcept { return m_inner_cells;  }
    const vector<Id>& getOuterCells()  const noexcept { return m_outer_cells;  }
    const vector<Id>& getTopCells()    const noexcept { return m_top_cells;    }
    const vector<Id>& getBottomCells() const noexcept { return m_bottom_cells; }
    const vector<Id>& getLeftCells()   const noexcept { return m_left_cells;   }
    const vector<Id>& getRightCells()  const noexcept { return m_right_cells;  }

    const vector<Id>& getTopFaces()    const noexcept { return m_top_faces;    }
    const vector<Id>& getBottomFaces() const noexcept { return m_bottom_faces; }
    const vector<Id>& getLeftFaces()   const noexcept { return m_left_faces;   }
    const vector<Id>& getRightFaces()  const noexcept { return m_right_faces;  }
    size_t getNbTopFaces()    const noexcept { return m_top_faces.size();    }
    size_t getNbBottomFaces() const noexcept { return m_bottom_faces.size(); }
    size_t getNbLeftFaces()   const noexcept { return m_left_faces.size();   }
    size_t getNbRightFaces()  const noexcept { return m_right_faces.size();  }

    size_t getNbOuterFaces()             const noexcept { return m_outer_faces.size();            }
    size_t getNbInnerFaces()             const noexcept { return m_inner_faces.size();            }
    size_t getNbInnerHorizontalFaces()   const noexcept { return m_inner_horizontal_faces.size(); }
    size_t getNbInnerVerticalFaces()     const noexcept { return m_inner_vertical_faces.size();   }
    vector<Id> getOuterFaces()           const noexcept { return m_outer_faces;                   }
    vector<Id> getInnerFaces()           const noexcept { return m_inner_faces;                   }
    vector<Id> getInnerHorizontalFaces() const noexcept { return m_inner_horizontal_faces;        }
    vector<Id> getInnerVerticalFaces()   const noexcept { return m_inner_vertical_faces;          }

    inline Id getTopLeftNode()     const noexcept { return m_top_left_node;     }
    inline Id getTopRightNode()    const noexcept { return m_top_right_node;    }
    inline Id getBottomLeftNode()  const noexcept { return m_bottom_left_node;  }
    inline Id getBottomRightNode() const noexcept { return m_bottom_right_node; }

    inline auto getNodesOfCell(const Id& cellId)    const noexcept -> const array<Id, 4>& { return m_geometry->getQuads()[cellId].getNodeIds(); }
    inline auto getNodesOfFace(const Id& faceId)    const noexcept -> const array<Id, 2>& { return m_geometry->getEdges()[faceId].getNodeIds(); }
    inline Id getFirstNodeOfFace(const Id& faceId)  const noexcept { return m_geometry->getEdges()[faceId].getNodeIds()[0]; }
    inline Id getSecondNodeOfFace(const Id& faceId) const noexcept { return m_geometry->getEdges()[faceId].getNodeIds()[1]; }

    vector<Id> getCellsOfNode(const Id& nodeId) const noexcept;
    vector<Id> getCellsOfFace(const Id& faceId) const;

    vector<Id> getNeighbourCells(const Id& cellId) const;
    vector<Id> getFacesOfCell(const Id& cellId) const;

    Id getCommonFace(const Id& cellId1, const Id& cellId2) const;

    Id getBackCell(const Id& faceId) const;
    Id getFrontCell(const Id& faceId) const;
    Id getTopFaceOfCell(const Id& cellId) const noexcept;
    Id getBottomFaceOfCell(const Id& cellId) const noexcept;
    Id getLeftFaceOfCell(const Id& cellId) const noexcept;
    Id getRightFaceOfCell(const Id& cellId) const noexcept;

    Id getTopCell(const Id& cellId) const noexcept;
    Id getBottomCell(const Id& cellId) const noexcept;
    Id getLeftCell(const Id& cellId) const noexcept;
    Id getRightCell(const Id& cellId) const noexcept;

    Id getBottomFaceNeighbour(const Id& faceId) const;
    Id getBottomLeftFaceNeighbour(const Id& faceId) const;
    Id getBottomRightFaceNeighbour(const Id& faceId) const;

    Id getTopFaceNeighbour(const Id& faceId) const;
    Id getTopLeftFaceNeighbour(const Id& faceId) const;
    Id getTopRightFaceNeighbour(const Id& faceId) const;

    Id getRightFaceNeighbour(const Id& faceId) const;
    Id getLeftFaceNeighbour(const Id& faceId) const;

/* Partition methods */
public:
    /* HOWTO:
     * #pragma omp task                                                                     \
     *     depend(iterator(neighbor_index=0:mesh->NEIGHBOR_getNumberForPartition(task)),    \
     *            in: this->partitions[neighbor_index].F)                                   \
     *     ... ... ...                                                                      \
     *     depend(out: this->uj_nplus1)
     * { ... }
     * NOTE:
     * - the neighbor_index 0 is always the partition itself.
     * - this->partition[idx].var_name  <- partitioned variable.
     * - this->var_name                 <- unpartitioned variable.
     */
    size_t NEIGHBOR_getNumberForPartition(size_t partition) const noexcept;
    size_t NEIGHBOR_getForPartition(size_t partition, size_t neighbor_index) const noexcept;

#define ___DEFINE_REVERSE_LINK_ACCESSORS(what)                          \
    size_t partition = m_##what##s_to_partitions[what];                 \
    if constexpr (NABLALIB_DEBUG) {                                     \
    if (std::find(m_partitions_##what##s[partition].begin(),            \
                  m_partitions_##what##s[partition].end(),              \
                  what) == m_partitions_##what##s[partition].end()) {   \
        abort();                                                        \
    }}                                                                  \
    return partition;

    inline size_t getPartitionOfNode(Id node) noexcept { ___DEFINE_REVERSE_LINK_ACCESSORS(node) }
    inline size_t getPartitionOfCell(Id cell) noexcept { ___DEFINE_REVERSE_LINK_ACCESSORS(cell) }
    inline size_t getPartitionOfFace(Id face) noexcept { ___DEFINE_REVERSE_LINK_ACCESSORS(face) }
#undef ___DEFINE_REVERSE_LINK_ACCESSORS

#define ___DEFINE_RANGE_FOR_SIDE(what, Type, type) \
    inline const vector<Id>& RANGE_##what##Type##FromPartition(const size_t partition) const noexcept \
    { return m_partitions_##what##_##type.at(partition); }

    inline auto RANGE_cellsFromPartition(const size_t partition) const noexcept -> const vector<Id>& { return m_partitions_cells.at(partition); }
    inline auto RANGE_nodesFromPartition(const size_t partition) const noexcept -> const vector<Id>& { return m_partitions_nodes.at(partition); }
    inline auto RANGE_facesFromPartition(const size_t partition) const noexcept -> const vector<Id>& { return m_partitions_faces.at(partition); }

    ___DEFINE_RANGE_FOR_SIDE(top,       Nodes, nodes)
    ___DEFINE_RANGE_FOR_SIDE(bottom,    Nodes, nodes)
    ___DEFINE_RANGE_FOR_SIDE(left,      Nodes, nodes)
    ___DEFINE_RANGE_FOR_SIDE(right,     Nodes, nodes)
    ___DEFINE_RANGE_FOR_SIDE(inner,     Nodes, nodes)

    ___DEFINE_RANGE_FOR_SIDE(top,       Cells, cells)
    ___DEFINE_RANGE_FOR_SIDE(bottom,    Cells, cells)
    ___DEFINE_RANGE_FOR_SIDE(left,      Cells, cells)
    ___DEFINE_RANGE_FOR_SIDE(right,     Cells, cells)
    ___DEFINE_RANGE_FOR_SIDE(inner,     Cells, cells)
    ___DEFINE_RANGE_FOR_SIDE(outer,     Cells, cells)

    ___DEFINE_RANGE_FOR_SIDE(top,       Faces, faces)
    ___DEFINE_RANGE_FOR_SIDE(bottom,    Faces, faces)
    ___DEFINE_RANGE_FOR_SIDE(left,      Faces, faces)
    ___DEFINE_RANGE_FOR_SIDE(right,     Faces, faces)
    ___DEFINE_RANGE_FOR_SIDE(inner,     Faces, faces)
    ___DEFINE_RANGE_FOR_SIDE(outer,     Faces, faces)
    ___DEFINE_RANGE_FOR_SIDE(innerVertical,   Faces, faces)
    ___DEFINE_RANGE_FOR_SIDE(innerHorizontal, Faces, faces)
#undef ___DEFINE_RANGE_FOR_SIDE

/* Don't move it around */
private:
    CartesianMesh2D(const CartesianMesh2D &)      = delete;
    CartesianMesh2D(CartesianMesh2D &&)           = delete;
    CartesianMesh2D& operator=(CartesianMesh2D &) = delete;

/* Helper functions */
public:
    inline Id index2IdCell(const size_t& i, const size_t& j) const noexcept { return static_cast<Id>(i * m_nb_x_quads + j); }
    inline Id index2IdNode(const size_t& i, const size_t& j) const noexcept { return static_cast<Id>(i * (m_nb_x_quads + 1) + j); }
    pair<size_t, size_t> id2IndexCell(const Id& k) const noexcept;
    pair<size_t, size_t> id2IndexNode(const Id& k) const noexcept;

/* Internal helper functions */
private:
    bool isInnerEdge(const Edge& e) const noexcept;
    inline bool isVerticalEdge(const Edge& e) const noexcept { return (e.getNodeIds()[0] == e.getNodeIds()[1] + m_nb_x_quads + 1 || e.getNodeIds()[1] == e.getNodeIds()[0] + m_nb_x_quads + 1); }
    inline bool isHorizontalEdge(const Edge& e) const noexcept { return (e.getNodeIds()[0] == e.getNodeIds()[1] + 1 || e.getNodeIds()[1] == e.getNodeIds()[0] + 1); }
    inline bool isInnerVerticalEdge(const Edge& e) const noexcept { return isInnerEdge(e) && isVerticalEdge(e); }
    inline bool isInnerHorizontalEdge(const Edge& e) const noexcept { return isInnerEdge(e) && isHorizontalEdge(e); }


    size_t getNbCommonIds(const vector<Id>& a, const vector<Id>& b) const noexcept;
    template <size_t N, size_t M> size_t
    getNbCommonIds(const array<Id, N>& as, const array<Id, M>& bs) const noexcept
    {
        size_t nbCommonIds(0);
        for (const auto& a : as)
            if (find(bs.begin(), bs.end(), a) != bs.end())
                ++nbCommonIds;
        return nbCommonIds;
    }

    inline vector<Id> cellsOfNodeCollection(const vector<Id>& nodes);

    const array<Id, 4> RANGE_facesFromCells(const Id cell) const noexcept;
    const array<Id, 4> RANGE_nodesFromCells(const Id cell) const noexcept;

/* Partition constructor methods */
private:
    void printPartialPartitions() noexcept;
    idx_t* createPartitions() noexcept;
    void computeNeighborPartitions(idx_t *metis_partition_cell) noexcept;
    void computePartialPartitions() noexcept;

/* Members from CartesianMesh2D */
private:
    MeshGeometry<2>* m_geometry;

    vector<Id> m_inner_nodes;
    vector<Id> m_top_nodes;
    vector<Id> m_bottom_nodes;
    vector<Id> m_left_nodes;
    vector<Id> m_right_nodes;
    Id m_top_left_node;
    Id m_top_right_node;
    Id m_bottom_left_node;
    Id m_bottom_right_node;

    vector<Id> m_top_cells;
    vector<Id> m_bottom_cells;
    vector<Id> m_left_cells;
    vector<Id> m_right_cells;

    vector<Id> m_faces;
    vector<Id> m_outer_faces;
    vector<Id> m_inner_faces;
    vector<Id> m_inner_horizontal_faces;
    vector<Id> m_inner_vertical_faces;
    vector<Id> m_top_faces;
    vector<Id> m_bottom_faces;
    vector<Id> m_left_faces;
    vector<Id> m_right_faces;

    vector<Id> m_inner_cells;
    vector<Id> m_outer_cells;

    size_t m_nb_x_quads;
    size_t m_nb_y_quads;

/* Members from CartesianPartition2D */
private:
    static inline uint32_t MAX_SHIFT     = 0; /* Detected at generation time */
    static inline size_t PartitionNumber = 0;

    const uint64_t m_problem_x;
    const uint64_t m_problem_y;

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

    /* For reverse operations */
    vector<Id> m_cells_to_partitions;
    vector<Id> m_nodes_to_partitions;
    vector<Id> m_faces_to_partitions;

    /* Neighbors for partitions */
    vector<vector<Id>> m_partitions_neighbors;

    /* TODO Return vector<Id>
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
#endif /* NABLALIB_MESH_CARTESIANMESH2D_H_ */
