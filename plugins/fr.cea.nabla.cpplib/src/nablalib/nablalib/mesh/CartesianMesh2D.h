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

#include <utility>
#include "nablalib/types/Types.h"
#include "nablalib/types/BoundedArray.h"
#include "nablalib/mesh/MeshGeometry.h"

using namespace std;

namespace nablalib::mesh
{

class CartesianMesh2D {
public:
	static constexpr int MaxNbNodesOfCell = 4;
	static constexpr int MaxNbNodesOfFace = 2;
	static constexpr int MaxNbCellsOfNode = 4;
	static constexpr int MaxNbCellsOfFace = 2;
	static constexpr int MaxNbFacesOfCell = 4;
	static constexpr int MaxNbNeighbourCells = 4;

	CartesianMesh2D(MeshGeometry<2>* geometry, const vector<Id>& inner_nodes_ids,
                  const vector<Id>& top_nodes_ids, const vector<Id>& bottom_nodes_ids,
                  const vector<Id>& left_nodes_ids, const vector<Id>& right_nodes_ids,
                  const Id top_left_node_id, const Id top_right_node_id,
                  const Id bottom_left_node_id, const Id bottom_right_node_id,
                  const vector<Id>& inner_cells_ids_ , const vector<Id>& outer_cells_ids_);

	MeshGeometry<2>* getGeometry() noexcept { return m_geometry; }

	size_t getNbNodes() const noexcept { return m_geometry->getNodes().size(); }

	size_t getNbCells() const noexcept { return m_geometry->getQuads().size(); }

	size_t getNbFaces() const noexcept { return m_geometry->getEdges().size(); }
	const vector<Id>& getFaces() const noexcept { return m_faces; }

	size_t getNbInnerNodes() const noexcept { return m_inner_nodes.size(); }
	const vector<Id>& getInnerNodes() const noexcept { return m_inner_nodes; }
	size_t getNbTopNodes() const noexcept { return m_top_nodes.size(); }
	const vector<Id>& getTopNodes() const noexcept { return m_top_nodes; }
	size_t getNbBottomNodes() const noexcept { return m_bottom_nodes.size(); }
	const vector<Id>& getBottomNodes() const noexcept { return m_bottom_nodes; }
	size_t getNbLeftNodes() const noexcept { return m_left_nodes.size(); }
	const vector<Id>& getLeftNodes() const noexcept { return m_left_nodes; }
	size_t getNbRightNodes() const noexcept { return m_right_nodes.size(); }
	const vector<Id>& getRightNodes() const noexcept { return m_right_nodes; }

	size_t getNbInnerCells() const noexcept { return m_inner_cells.size();}
	const vector<Id>& getInnerCells() const noexcept {return m_inner_cells;}
	size_t getNbOuterCells() const noexcept { return m_outer_cells.size();}
	const vector<Id>& getOuterCells() const noexcept {return m_outer_cells;}
	size_t getNbTopCells() const noexcept { return m_top_cells.size(); }
	const vector<Id>& getTopCells() const noexcept { return m_top_cells; }
	size_t getNbBottomCells() const noexcept { return m_bottom_cells.size(); }
	const vector<Id>& getBottomCells() const noexcept { return m_bottom_cells; }
	size_t getNbLeftCells() const noexcept { return m_left_cells.size(); }
	const vector<Id>& getLeftCells() const noexcept { return m_left_cells; }
	size_t getNbRightCells() const noexcept { return m_right_cells.size(); }
	const vector<Id>& getRightCells() const noexcept { return m_right_cells; }

	size_t getNbTopFaces() const noexcept { return m_top_faces.size(); }
	const vector<Id>& getTopFaces() const noexcept { return m_top_faces; }
	size_t getNbBottomFaces() const noexcept { return m_bottom_faces.size(); }
	const vector<Id>& getBottomFaces() const noexcept { return m_bottom_faces; }
	size_t getNbLeftFaces() const noexcept { return m_left_faces.size(); }
	const vector<Id>& getLeftFaces() const noexcept { return m_left_faces; }
	size_t getNbRightFaces() const noexcept { return m_right_faces.size(); }
	const vector<Id>& getRightFaces() const noexcept { return m_right_faces; }

	size_t getNbOuterFaces() const noexcept { return m_outer_faces.size(); }
	vector<Id> getOuterFaces() const noexcept { return m_outer_faces; }
	size_t getNbInnerFaces() const noexcept { return m_inner_faces.size(); }
	vector<Id> getInnerFaces() const noexcept { return m_inner_faces; }
	size_t getNbInnerHorizontalFaces() const noexcept { return m_inner_horizontal_faces.size(); }
	vector<Id> getInnerHorizontalFaces() const noexcept { return m_inner_horizontal_faces; }
	size_t getNbInnerVerticalFaces() const noexcept { return m_inner_vertical_faces.size(); }
	vector<Id> getInnerVerticalFaces() const noexcept { return m_inner_vertical_faces; }

	Id getTopLeftNode() const noexcept { return m_top_left_node; }
	Id getTopRightNode() const noexcept { return m_top_right_node; }
	Id getBottomLeftNode() const noexcept { return m_bottom_left_node; }
	Id getBottomRightNode() const noexcept { return m_bottom_right_node; }

	const array<Id, 4>& getNodesOfCell(const Id& cellId) const noexcept;
	const array<Id, 2>& getNodesOfFace(const Id& faceId) const noexcept;
	Id getFirstNodeOfFace(const Id& faceId) const noexcept;
	Id getSecondNodeOfFace(const Id& faceId) const noexcept;

	BoundedArray<Id, MaxNbCellsOfNode> getCellsOfNode(const Id& nodeId) const noexcept;
	BoundedArray<Id, MaxNbCellsOfFace> getCellsOfFace(const Id& faceId) const;

	BoundedArray<Id, MaxNbNeighbourCells> getNeighbourCells(const Id& cellId) const;
	BoundedArray<Id, MaxNbFacesOfCell>    getFacesOfCell(const Id& cellId) const;

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

 private:
	inline Id index2IdCell(const size_t& i, const size_t& j) const noexcept { return static_cast<Id>(i * m_nb_x_quads + j); }
	inline Id index2IdNode(const size_t& i, const size_t& j) const noexcept { return static_cast<Id>(i * (m_nb_x_quads + 1) + j); }
	inline pair<size_t, size_t>
    id2IndexCell(const Id& k) const noexcept
    {
        size_t i(static_cast<size_t>(k) / m_nb_x_quads);
        size_t j(static_cast<size_t>(k) - i * m_nb_x_quads);
        return make_pair(i, j);
    }
	inline pair<size_t, size_t>
    id2IndexNode(const Id& k) const noexcept
    {
        size_t i(static_cast<size_t>(k) / (m_nb_x_quads + 1));
        size_t j(static_cast<size_t>(k) - i * (m_nb_x_quads + 1));
        return make_pair(i, j);
    }

	bool isInnerEdge(const Edge& e) const noexcept;
	bool isVerticalEdge(const Edge& e) const noexcept;
	bool isHorizontalEdge(const Edge& e) const noexcept;
	bool isInnerVerticalEdge(const Edge& e) const noexcept;
	bool isInnerHorizontalEdge(const Edge& e) const noexcept;

	size_t getNbCommonIds(const vector<Id>& a, const vector<Id>& b) const noexcept;
	template <size_t N, size_t M>
	size_t	getNbCommonIds(const array<Id, N>& as, const array<Id, M>& bs) const noexcept
	{
		size_t nbCommonIds(0);
		for (const auto& a : as)
			if (find(bs.begin(), bs.end(), a) != bs.end())
				++nbCommonIds;
		return nbCommonIds;
	}

	inline vector<Id> cellsOfNodeCollection(const vector<Id>& nodes);

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

public: // Hacky boi
	size_t m_nb_x_quads;
	size_t m_nb_y_quads;
};

/* Need some GPU things */
#ifdef NABLALIB_GPU

/* Usage:
 *
 * CartesianMesh2D *mesh = ...;
 * GPU_CartesianMesh2D mesh_glb;
 * GPU_CartesianMesh2D_alloc(&mesh_glb, mesh); // Now all the data is on GPU
 * ... ... ...
 * GPU_CartesianMesh2D_free(&mesh_glb); // Now things are deleted from the GPU
 */

#pragma omp declare target
constexpr int GPU_CartesianMesh2D_MaxNbNodesOfCell    = 4;
constexpr int GPU_CartesianMesh2D_MaxNbNodesOfFace    = 2;
constexpr int GPU_CartesianMesh2D_MaxNbCellsOfNode    = 4;
constexpr int GPU_CartesianMesh2D_MaxNbCellsOfFace    = 2;
constexpr int GPU_CartesianMesh2D_MaxNbNeighbourCells = 4;
constexpr int GPU_CartesianMesh2D_MaxNbFacesOfCell    = 4;

struct GPU_CartesianMesh2D {
	GPU_MeshGeometry<2> geometry;

    /* nodes */
	const Id *inner_nodes;
	const Id *top_nodes;
	const Id *bottom_nodes;
	const Id *left_nodes;
	const Id *right_nodes;

	size_t inner_nodes_count;
	size_t top_nodes_count;
	size_t bottom_nodes_count;
	size_t left_nodes_count;
	size_t right_nodes_count;

	size_t top_left_node;
	size_t top_right_node;
	size_t bottom_left_node;
    size_t bottom_right_node;

    /* cells */
	const Id *top_cells;
	const Id *bottom_cells;
	const Id *left_cells;
	const Id *right_cells;

	size_t top_cells_count;
	size_t bottom_cells_count;
	size_t left_cells_count;
	size_t right_cells_count;

	const Id *inner_cells;
	const Id *outer_cells;
	size_t inner_cells_count;
	size_t outer_cells_count;

    /**********************************\
    |  faces:                          |
    |  /!\ Ignored for the moment /!\  |
    \**********************************/

    /* faces */
	size_t inner_faces_count;
	size_t outer_faces_count;
	size_t top_faces_count;
	size_t bottom_faces_count;
	size_t left_faces_count;
	size_t right_faces_count;
	size_t inner_vertical_faces_count;
	size_t inner_horizontal_faces_count;

	const Id *inner_faces;
	const Id *outer_faces;
	const Id *top_faces;
	const Id *bottom_faces;
	const Id *left_faces;
	const Id *right_faces;
	const Id *inner_vertical_faces;
	const Id *inner_horizontal_faces;

    /* problem sizes */
	size_t nb_x_quads;
	size_t nb_y_quads;

public:
    /* Methods */
	size_t getNbNodes() const noexcept { return geometry.nodes_count; }
	size_t getNbFaces() const noexcept { return geometry.edges_count; }
	size_t getNbCells() const noexcept { return geometry.quads_count; }

	size_t getNbInnerNodes()    const noexcept { return inner_nodes_count;  }
	size_t getNbTopNodes()      const noexcept { return top_nodes_count;    }
	size_t getNbBottomNodes()   const noexcept { return bottom_nodes_count; }
	size_t getNbLeftNodes()     const noexcept { return left_nodes_count;   }
	size_t getNbRightNodes()    const noexcept { return right_nodes_count;  }

	const Id *getInnerNodes()   const noexcept { return inner_nodes;  }
	const Id *getTopNodes()     const noexcept { return top_nodes;    }
	const Id *getBottomNodes()  const noexcept { return bottom_nodes; }
	const Id *getLeftNodes()    const noexcept { return left_nodes;   }
	const Id *getRightNodes()   const noexcept { return right_nodes;  }

	size_t getNbInnerCells()    const noexcept { return inner_cells_count;  }
	size_t getNbOuterCells()    const noexcept { return outer_cells_count;  }
	size_t getNbTopCells()      const noexcept { return top_cells_count;    }
	size_t getNbBottomCells()   const noexcept { return bottom_cells_count; }
	size_t getNbLeftCells()     const noexcept { return left_cells_count;   }
	size_t getNbRightCells()    const noexcept { return right_cells_count;  }

	const Id *getInnerCells()   const noexcept { return inner_cells;  }
	const Id *getOuterCells()   const noexcept { return outer_cells;  }
	const Id *getTopCells()     const noexcept { return top_cells;    }
	const Id *getBottomCells()  const noexcept { return bottom_cells; }
	const Id *getLeftCells()    const noexcept { return left_cells;   }
	const Id *getRightCells()   const noexcept { return right_cells;  }

	Id getTopLeftNode()         const noexcept { return top_left_node;     }
	Id getTopRightNode()        const noexcept { return top_right_node;    }
	Id getBottomLeftNode()      const noexcept { return bottom_left_node;  }
	Id getBottomRightNode()     const noexcept { return bottom_right_node; }

	const Id* getTopFaces()     const noexcept { return top_faces; }
	const Id* getBottomFaces()  const noexcept { return bottom_faces; }
	const Id* getLeftFaces()    const noexcept { return left_faces; }
	const Id* getRightFaces()   const noexcept { return right_faces; }

	size_t getNbTopFaces()      const noexcept { return top_faces_count;    }
	size_t getNbBottomFaces()   const noexcept { return bottom_faces_count; }
	size_t getNbLeftFaces()     const noexcept { return left_faces_count;   }
	size_t getNbRightFaces()    const noexcept { return right_faces_count;  }

	size_t getNbOuterFaces()            const noexcept { return outer_faces_count; }
	size_t getNbInnerFaces()            const noexcept { return inner_faces_count; }
	size_t getNbInnerHorizontalFaces()  const noexcept { return inner_horizontal_faces_count; }
	size_t getNbInnerVerticalFaces()    const noexcept { return inner_vertical_faces_count; }

	const Id* getOuterFaces()           const noexcept { return outer_faces; }
	const Id* getInnerFaces()           const noexcept { return inner_faces; }
	const Id* getInnerHorizontalFaces() const noexcept { return inner_horizontal_faces; }
	const Id* getInnerVerticalFaces()   const noexcept { return inner_vertical_faces; }


    inline const std::array<Id, 4>&
	getNodesOfCell(const Id& cellId) const noexcept
    {
        return geometry.quads[cellId].getNodeIds();
    }

    inline const std::array<Id, GPU_CartesianMesh2D_MaxNbNeighbourCells>
	getNeighbourCells(const Id& cellId) const noexcept
    {
        BoundedArray<Id, GPU_CartesianMesh2D_MaxNbNeighbourCells> ret;
        auto [i, j]  = id2IndexNode(cellId);
        size_t index = 0;

        if (i >= 1)             ret[index++] = index2IdCell(i-1, j  );
        if (i < nb_y_quads - 1) ret[index++] = index2IdCell(i+1, j  );
        if (j >= 1)             ret[index++] = index2IdCell(i,   j-1);
        if (j < nb_x_quads - 1) ret[index++] = index2IdCell(i,   j+1);

        return ret;
    }


    inline BoundedArray<Id, GPU_CartesianMesh2D_MaxNbCellsOfNode>
	getCellsOfNode(const Id& nodeId) const noexcept
    {
        BoundedArray<Id, GPU_CartesianMesh2D_MaxNbCellsOfNode> ret;
        auto [i, j]  = id2IndexNode(nodeId);
        size_t index = 0;

        if (i < nb_y_quads && j < nb_x_quads) ret[index++] = index2IdCell(i,   j  );
        if (i < nb_y_quads && j > 0)          ret[index++] = index2IdCell(i,   j-1);
        if (i > 0          && j < nb_x_quads) ret[index++] = index2IdCell(i-1, j  );
        if (i > 0          && j > 0)          ret[index++] = index2IdCell(i-1, j-1);

        ret.resize(index);
        return ret;
    }

	const array<Id, 2>&
    getNodesOfFace(const Id& faceId) const noexcept
    {
	    return geometry.edges[faceId].getNodeIds();
    }

	Id getFirstNodeOfFace(const Id& faceId)  const noexcept { return getNodesOfFace(faceId)[0]; }
	Id getSecondNodeOfFace(const Id& faceId) const noexcept { return getNodesOfFace(faceId)[1]; }

	BoundedArray<Id, GPU_CartesianMesh2D_MaxNbCellsOfFace>
    getCellsOfFace(const Id& faceId) const noexcept
    {
	    BoundedArray<Id, GPU_CartesianMesh2D_MaxNbCellsOfFace> ret;
        size_t index = 0;
        size_t i_f   = static_cast<size_t>(faceId) / (2 * nb_x_quads + 1);
        size_t k_f   = static_cast<size_t>(faceId) - i_f * (2 * nb_x_quads + 1);

        // all except upper bound faces
        if (i_f < nb_y_quads) {
            // right bound edge
            if (k_f == 2 * nb_x_quads) {
                ret[index++] = index2IdCell(i_f, nb_x_quads-1);
            }

            // left bound edge
            else if (k_f == 1) {
                ret[index++] = index2IdCell(i_f, 0);
            }

            // horizontal edge
            else if (k_f % 2 == 0) {
                // Not bottom bound edge
                if (i_f > 0)
                    ret[index++] = index2IdCell(i_f-1, k_f/2);

                ret[index++] = index2IdCell(i_f, k_f/2);
            }

            // vertical edge (neither left bound nor right bound)
            else {
                ret[index++] = index2IdCell(i_f, (k_f-1)/2 - 1);
                ret[index++] = index2IdCell(i_f, (k_f-1)/2);
            }
        }

        // upper bound faces
        else {
            ret[index++] = index2IdCell(i_f-1, k_f);
        }

        ret.resize(index);
        return ret;
    }

	BoundedArray<Id, GPU_CartesianMesh2D_MaxNbFacesOfCell>
    getFacesOfCell(const Id& cellId) const noexcept
    {
        BoundedArray<Id, GPU_CartesianMesh2D_MaxNbFacesOfCell> ret;
        auto [i, j] = id2IndexCell(cellId);

        Id bottom_face = static_cast<Id>(2 * j + i * (2 * nb_x_quads + 1));
        Id left_face   = bottom_face + 1;
        Id right_face  = bottom_face + static_cast<Id>(j == nb_x_quads-1 ? 2 : 3);
        Id top_face    = bottom_face + static_cast<Id>(i < nb_y_quads-1 ? 2 * nb_x_quads + 1 : 2 * nb_x_quads + 1 - j);

        ret[0] = bottom_face;
        ret[1] = left_face;
        ret[2] = right_face;
        ret[3] = top_face;
        return ret;
    }

	Id
    getCommonFace(const Id& cellId1, const Id& cellId2) const noexcept
    {
        auto cell1Faces{getFacesOfCell(cellId1)};
        auto cell2Faces{getFacesOfCell(cellId2)};
        auto result = find_first_of(
                cell1Faces.begin(), cell1Faces.end(),
                cell2Faces.begin(), cell2Faces.end()
        );
        return *result; // Will segv on GPU
    }

	Id getBackCell(const Id& faceId)    const noexcept { return getCellsOfFace(faceId)[0]; }
	Id getFrontCell(const Id& faceId)   const noexcept { return getCellsOfFace(faceId)[1]; }

    Id
    getTopFaceOfCell(const Id& cellId) const noexcept {
        auto [i, j] = id2IndexCell(cellId);
        Id bottom_face(static_cast<Id>(2 * j + i * (2 * nb_x_quads + 1)));
        Id top_face(bottom_face + static_cast<Id>(i < nb_y_quads - 1 ? 2 * nb_x_quads + 1 : 2 * nb_x_quads + 1 - j));
        return top_face;
    }

	Id
    getBottomFaceOfCell(const Id& cellId) const noexcept
    {
        auto [i, j] = id2IndexCell(cellId);
        Id bottom_face(static_cast<Id>(2 * j + i * (2 * nb_x_quads + 1)));
        return bottom_face;
    }

	Id getLeftFaceOfCell(const Id& cellId) const noexcept { return getBottomFaceOfCell(cellId) + 1; }

	Id
    getRightFaceOfCell(const Id& cellId) const noexcept
    {
        auto [i, j] = id2IndexCell(cellId);
        Id bottom_face(static_cast<Id>(2 * j + i * (2 * nb_x_quads + 1)));
        Id right_face(bottom_face + static_cast<Id>(j == nb_x_quads - 1 ? 2 : 3));
        return right_face;
    }

	Id getBottomFaceNeighbour(const Id& faceId) const noexcept { return (faceId - (2 * nb_x_quads + 1)); }
	Id getTopFaceNeighbour(const Id& faceId)    const noexcept { return (faceId + (2 * nb_x_quads + 1)); }

	Id
    getBottomLeftFaceNeighbour(const Id& faceId) const noexcept
    {
        const Edge& face(geometry.edges[faceId]);
        if (isVerticalEdge(face))
            return (faceId - 3);
        else  // horizontal
            return ((faceId + 1) - (2 * nb_x_quads + 1));
    }

	Id
    getBottomRightFaceNeighbour(const Id& faceId) const noexcept
    {
        const Edge& face(geometry.edges[faceId]);
        if (isVerticalEdge(face))
            return (faceId - 1);
        else  // horizontal
            return ((faceId + 3) - (2 * nb_x_quads + 1));
    }

	Id
    getTopLeftFaceNeighbour(const Id& faceId) const noexcept
    {
        const Edge& face(geometry.edges[faceId]);
        if (isVerticalEdge(face))
            return ((faceId - 3) + (2 * nb_x_quads + 1));
        else  // horizontal
            return (faceId + 1);
    }

	Id
    getTopRightFaceNeighbour(const Id& faceId) const noexcept
    {
        const Edge& face(geometry.edges[faceId]);
        if (isVerticalEdge(face))
            return ((faceId - 1) + (2 * nb_x_quads + 1));
        else  // horizontal
            return (faceId + 3);
    }

	Id getRightFaceNeighbour(const Id& faceId) const noexcept { return (faceId + 2); }
	Id getLeftFaceNeighbour(const Id& faceId)  const noexcept { return (faceId - 2); }

private:
    inline std::pair<size_t, size_t>
    id2IndexNode(const Id& k) const noexcept
    {
        size_t i = (static_cast<size_t>(k) / (nb_x_quads + 1));
        size_t j = static_cast<size_t>(k) - i * (nb_x_quads + 1);
        return std::pair<size_t, size_t>{ i, j };
    }

	inline std::pair<size_t, size_t>
    id2IndexCell(const Id& k) const noexcept
    {
        size_t i(static_cast<size_t>(k) / nb_x_quads);
        size_t j(static_cast<size_t>(k) - i * nb_x_quads);
        return std::pair<size_t, size_t>(i, j);
    }

    inline Id
    index2IdCell(const size_t i, const size_t j) const noexcept
    {
        return static_cast<Id>(i * nb_x_quads + j);
    }

    inline bool
    isVerticalEdge(const Edge &e) const noexcept
    {
        return (e.getNodeIds()[0] == e.getNodeIds()[1] + nb_x_quads + 1 ||
                e.getNodeIds()[1] == e.getNodeIds()[0] + nb_x_quads + 1);
    }

    inline bool
    isHorizontalEdge(const Edge& e) const noexcept
    {
        return (e.getNodeIds()[0] == e.getNodeIds()[1] + 1 ||
                e.getNodeIds()[1] == e.getNodeIds()[0] + 1);
    }

    inline bool
    isInnerVerticalEdge(const Edge& e) const noexcept
    {
        return isInnerEdge(e) && isVerticalEdge(e);
    }

    inline bool
    isInnerHorizontalEdge(const Edge& e) const noexcept
    {
        return isInnerEdge(e) && isHorizontalEdge(e);
    }

    inline bool
    isInnerEdge(const Edge& e) const noexcept
    {
        auto [i1, j1] = id2IndexNode(e.getNodeIds()[0]);
        auto [i2, j2] = id2IndexNode(e.getNodeIds()[1]);

        // If nodes are located on the same boundary, then the face is an outer
        // one, else it's an inner one.
        return !((i1 == 0 && i2 == 0) || (i1 == nb_y_quads && i2 == nb_y_quads) ||
                 (j1 == 0 && j2 == 0) || (j1 == nb_x_quads && j2 == nb_x_quads));
    }
};
#pragma omp end declare target

#include "nablalib/utils/OMPTarget.h"
#include <cstdio>

namespace {
extern "C" {
static inline void
GPU_CartesianMesh2D_alloc(CartesianMesh2D *cpu)
{
    static_assert(std::is_trivial<GPU_CartesianMesh2D>::value, "Must be trivial");
    extern GPU_CartesianMesh2D mesh_glb;

    /* The geometry */
    mesh_glb.geometry.nodes_count = cpu->getGeometry()->getNodes().size();
    mesh_glb.geometry.edges_count = cpu->getGeometry()->getEdges().size();
    mesh_glb.geometry.quads_count = cpu->getGeometry()->getQuads().size();
    mesh_glb.geometry.nodes       = cpu->getGeometry()->getNodes().data();
    mesh_glb.geometry.edges       = cpu->getGeometry()->getEdges().data();
    mesh_glb.geometry.quads       = cpu->getGeometry()->getQuads().data();

    /* problem sizes -> don't need deep copy */
	mesh_glb.inner_cells_count  = cpu->getNbInnerCells();
	mesh_glb.outer_cells_count  = cpu->getNbOuterCells();
	mesh_glb.nb_x_quads         = cpu->m_nb_x_quads;
	mesh_glb.nb_y_quads         = cpu->m_nb_y_quads;
	mesh_glb.top_cells_count    = cpu->getNbTopCells();
	mesh_glb.bottom_cells_count = cpu->getNbBottomCells();
	mesh_glb.left_cells_count   = cpu->getNbLeftCells();
	mesh_glb.right_cells_count  = cpu->getNbRightCells();
	mesh_glb.inner_nodes_count  = cpu->getNbInnerNodes();
	mesh_glb.top_nodes_count    = cpu->getNbTopNodes();
	mesh_glb.bottom_nodes_count = cpu->getNbBottomNodes();
	mesh_glb.left_nodes_count   = cpu->getNbLeftNodes();
	mesh_glb.right_nodes_count  = cpu->getNbRightNodes();
	mesh_glb.top_left_node      = cpu->getTopLeftNode();
	mesh_glb.top_right_node     = cpu->getTopRightNode();
	mesh_glb.bottom_left_node   = cpu->getBottomLeftNode();
	mesh_glb.bottom_right_node  = cpu->getBottomRightNode();

    /* nodes -> need deep copy */
	mesh_glb.inner_nodes  = cpu->getInnerNodes().data();
	mesh_glb.top_nodes    = cpu->getTopNodes().data();
	mesh_glb.bottom_nodes = cpu->getBottomNodes().data();
	mesh_glb.left_nodes   = cpu->getLeftNodes().data();
	mesh_glb.right_nodes  = cpu->getRightNodes().data();
	mesh_glb.top_cells    = cpu->getTopCells().data();
	mesh_glb.bottom_cells = cpu->getBottomCells().data();
	mesh_glb.left_cells   = cpu->getLeftCells().data();
	mesh_glb.right_cells  = cpu->getRightCells().data();
	mesh_glb.inner_cells  = cpu->getInnerCells().data();
	mesh_glb.outer_cells  = cpu->getOuterCells().data();

    /* Copy top level data */
    #pragma omp target enter data map(alloc: mesh_glb)
    #pragma omp target update to (mesh_glb)

    /* Deep copy part */
    #pragma omp target enter data map(alloc: (mesh_glb.geometry.nodes)[:mesh_glb.geometry.nodes_count])
    #pragma omp target enter data map(alloc: (mesh_glb.geometry.edges)[:mesh_glb.geometry.edges_count])
    #pragma omp target enter data map(alloc: (mesh_glb.geometry.quads)[:mesh_glb.geometry.quads_count])
    #pragma omp target update to ((mesh_glb.geometry.nodes)[:mesh_glb.geometry.nodes_count])
    #pragma omp target update to ((mesh_glb.geometry.edges)[:mesh_glb.geometry.edges_count])
    #pragma omp target update to ((mesh_glb.geometry.quads)[:mesh_glb.geometry.quads_count])

    #pragma omp target enter data map(alloc: (mesh_glb.inner_nodes) [:mesh_glb.inner_nodes_count])
    #pragma omp target enter data map(alloc: (mesh_glb.top_nodes)   [:mesh_glb.top_nodes_count])
    #pragma omp target enter data map(alloc: (mesh_glb.bottom_nodes)[:mesh_glb.bottom_nodes_count])
    #pragma omp target enter data map(alloc: (mesh_glb.left_nodes)  [:mesh_glb.left_nodes_count])
    #pragma omp target enter data map(alloc: (mesh_glb.right_nodes) [:mesh_glb.right_nodes_count])
    #pragma omp target update to ((mesh_glb.inner_nodes) [:mesh_glb.inner_nodes_count])
    #pragma omp target update to ((mesh_glb.top_nodes)   [:mesh_glb.top_nodes_count])
    #pragma omp target update to ((mesh_glb.bottom_nodes)[:mesh_glb.bottom_nodes_count])
    #pragma omp target update to ((mesh_glb.left_nodes)  [:mesh_glb.left_nodes_count])
    #pragma omp target update to ((mesh_glb.right_nodes) [:mesh_glb.right_nodes_count])

    #pragma omp target enter data map(alloc: (mesh_glb.inner_cells) [:mesh_glb.inner_cells_count])
    #pragma omp target enter data map(alloc: (mesh_glb.top_cells)   [:mesh_glb.top_cells_count])
    #pragma omp target enter data map(alloc: (mesh_glb.bottom_cells)[:mesh_glb.bottom_cells_count])
    #pragma omp target enter data map(alloc: (mesh_glb.left_cells)  [:mesh_glb.left_cells_count])
    #pragma omp target enter data map(alloc: (mesh_glb.right_cells) [:mesh_glb.right_cells_count])
    #pragma omp target enter data map(alloc: (mesh_glb.outer_cells) [:mesh_glb.outer_cells_count])
    #pragma omp target update to ((mesh_glb.inner_cells) [:mesh_glb.inner_cells_count])
    #pragma omp target update to ((mesh_glb.top_cells)   [:mesh_glb.top_cells_count])
    #pragma omp target update to ((mesh_glb.bottom_cells)[:mesh_glb.bottom_cells_count])
    #pragma omp target update to ((mesh_glb.left_cells)  [:mesh_glb.left_cells_count])
    #pragma omp target update to ((mesh_glb.right_cells) [:mesh_glb.right_cells_count])
    #pragma omp target update to ((mesh_glb.outer_cells) [:mesh_glb.outer_cells_count])
}
}
}

#endif /* NABLALIB_GPU */

}
#endif /* NABLALIB_MESH_CARTESIANMESH2D_H_ */
