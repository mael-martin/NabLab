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
	Id index2IdCell(const size_t& i, const size_t& j) const noexcept;
	Id index2IdNode(const size_t& i, const size_t& j) const noexcept;
	pair<size_t, size_t> id2IndexCell(const Id& k) const noexcept;
	pair<size_t, size_t> id2IndexNode(const Id& k) const noexcept;

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

struct GPU_CartesianMesh2D {
	static constexpr int MaxNbNodesOfCell    = 4;
	static constexpr int MaxNbNodesOfFace    = 2;
	static constexpr int MaxNbCellsOfNode    = 4;
	static constexpr int MaxNbCellsOfFace    = 2;
	static constexpr int MaxNbNeighbourCells = 4;

	GPU_MeshGeometry<2>* geometry;

    /* nodes */
	const Id *inner_nodes;
	const Id *top_nodes;
	const Id *bottom_nodes;
	const Id *left_nodes;
	const Id *right_nodes;

	Id inner_nodes_count;
	Id top_nodes_count;
	Id bottom_nodes_count;
	Id left_nodes_count;
	Id right_nodes_count;

	Id top_left_node;
	Id top_right_node;
	Id bottom_left_node; Id bottom_right_node;

    /* border cells */
	const Id *top_cells;
	const Id *bottom_cells;
	const Id *left_cells;
	const Id *right_cells;

	Id top_cells_count;
	Id bottom_cells_count;
	Id left_cells_count;
	Id right_cells_count;

    /**********************************\
    |  faces:                          |
    |  /!\ Ignored for the moment /!\  |
    \**********************************/

    /* cells again */
	const Id *inner_cells;
	const Id *outer_cells;
	Id inner_cells_count;
	Id outer_cells_count;

    /* problem sizes */
	size_t nb_x_quads;
	size_t nb_y_quads;

    /* Methods */
	size_t getNbNodes() const noexcept { return geometry->nodes_count; }
	size_t getNbCells() const noexcept { return geometry->quads_count; }

	size_t getNbInnerNodes()  const noexcept { return inner_nodes_count;  }
	size_t getNbTopNodes()    const noexcept { return top_nodes_count;    }
	size_t getNbBottomNodes() const noexcept { return bottom_nodes_count; }
	size_t getNbLeftNodes()   const noexcept { return left_nodes_count;   }
	size_t getNbRightNodes()  const noexcept { return right_nodes_count;  }

	const Id *getInnerNodes()  const noexcept { return inner_nodes;  }
	const Id *getTopNodes()    const noexcept { return top_nodes;    }
	const Id *getBottomNodes() const noexcept { return bottom_nodes; }
	const Id *getLeftNodes()   const noexcept { return left_nodes;   }
	const Id *getRightNodes()  const noexcept { return right_nodes;  }

	size_t getNbInnerCells()  const noexcept { return inner_cells_count;  }
	size_t getNbOuterCells()  const noexcept { return outer_cells_count;  }
	size_t getNbTopCells()    const noexcept { return top_cells_count;    }
	size_t getNbBottomCells() const noexcept { return bottom_cells_count; }
	size_t getNbLeftCells()   const noexcept { return left_cells_count;   }
	size_t getNbRightCells()  const noexcept { return right_cells_count;  }

	const Id *getInnerCells()  const noexcept { return inner_cells;  }
	const Id *getOuterCells()  const noexcept { return outer_cells;  }
	const Id *getTopCells()    const noexcept { return top_cells;    }
	const Id *getBottomCells() const noexcept { return bottom_cells; }
	const Id *getLeftCells()   const noexcept { return left_cells;   }
	const Id *getRightCells()  const noexcept { return right_cells;  }

	Id getTopLeftNode()     const noexcept { return top_left_node;     }
	Id getTopRightNode()    const noexcept { return top_right_node;    }
	Id getBottomLeftNode()  const noexcept { return bottom_left_node;  }
	Id getBottomRightNode() const noexcept { return bottom_right_node; }

    inline const std::array<Id, 4>&
	getNodesOfCell(const Id& cellId) const noexcept
    {
        return geometry->quads[cellId].getNodeIds();
    }

    inline BoundedArray<Id, MaxNbCellsOfNode>
	getCellsOfNode(const Id& nodeId) const noexcept
    {
        // TODO: Get ride of all the if/else
        // ((x ^ y) < 0); // true if x and y have opposite signs

        auto [i, j] = id2IndexNode(nodeId);
        vector<Id> cells;

        if (i < nb_y_quads && j < nb_x_quads) cells.emplace_back(index2IdCell(i,   j  ));
        if (i < nb_y_quads && j > 0)          cells.emplace_back(index2IdCell(i,   j-1));
        if (i > 0          && j < nb_x_quads) cells.emplace_back(index2IdCell(i-1, j  ));
        if (i > 0          && j > 0)          cells.emplace_back(index2IdCell(i-1, j-1));

        return BoundedArray<Id, MaxNbCellsOfNode>::fromVector(cells);
    }

    inline const std::array<Id, MaxNbNeighbourCells>
	getNeighbourCells(const Id& cellId) const noexcept
    {
        // TODO: Get ride of all the if/else
        // ((x ^ y) < 0); // true if x and y have opposite signs

        auto [i, j] = id2IndexNode(cellId);
        vector<Id> neighbors;

        if (i >= 1)             neighbors.emplace_back(index2IdCell(i-1, j  ));
        if (i < nb_y_quads - 1) neighbors.emplace_back(index2IdCell(i+1, j  ));
        if (j >= 1)             neighbors.emplace_back(index2IdCell(i,   j-1));
        if (j < nb_x_quads - 1) neighbors.emplace_back(index2IdCell(i,   j+1));

        return BoundedArray<Id, MaxNbNeighbourCells>::fromVector(neighbors);
    }

private:
    inline std::pair<size_t, size_t>
    id2IndexNode(const Id& k) const noexcept
    {
        size_t i = (static_cast<size_t>(k) / (nb_x_quads + 1));
        size_t j = static_cast<size_t>(k) - i * (nb_x_quads + 1);
        return std::pair<size_t, size_t>{ i, j };
    }

    inline Id
    index2IdCell(const size_t i, const size_t j) const noexcept
    {
        return static_cast<Id>(i * nb_x_quads + j);
    }
};

static inline void
GPU_CartesianMesh2D_alloc(GPU_CartesianMesh2D *gpu, CartesianMesh2D *cpu)
{
    /* The geometry */
    gpu->geometry = (GPU_MeshGeometry<2> *)malloc(sizeof(GPU_MeshGeometry<2>));
    GPU_MeshGeometry_alloc<2>(gpu->geometry, cpu->getGeometry());

    /* nodes */
	gpu->inner_nodes        = cpu->getInnerNodes().data();
	gpu->top_nodes          = cpu->getTopNodes().data();
	gpu->bottom_nodes       = cpu->getBottomNodes().data();
	gpu->left_nodes         = cpu->getLeftNodes().data();
	gpu->right_nodes        = cpu->getRightNodes().data();

	gpu->inner_nodes_count  = cpu->getNbInnerNodes();
	gpu->top_nodes_count    = cpu->getNbTopNodes();
	gpu->bottom_nodes_count = cpu->getNbBottomNodes();
	gpu->left_nodes_count   = cpu->getNbLeftNodes();
	gpu->right_nodes_count  = cpu->getNbRightNodes();

	gpu->top_left_node      = cpu->getTopLeftNode();
	gpu->top_right_node     = cpu->getTopRightNode();
	gpu->bottom_left_node   = cpu->getBottomLeftNode();
	gpu->bottom_right_node  = cpu->getBottomRightNode();

    /* border cells */
	gpu->top_cells          = cpu->getTopCells().data();
	gpu->bottom_cells       = cpu->getBottomCells().data();
	gpu->left_cells         = cpu->getLeftCells().data();
	gpu->right_cells        = cpu->getRightCells().data();

	gpu->top_cells_count    = cpu->getNbTopCells();
	gpu->bottom_cells_count = cpu->getNbBottomCells();
	gpu->left_cells_count   = cpu->getNbLeftCells();
	gpu->right_cells_count  = cpu->getNbRightCells();

    /* cells again */
	gpu->inner_cells        = cpu->getInnerCells().data();
	gpu->outer_cells        = cpu->getOuterCells().data();
	gpu->inner_cells_count  = cpu->getNbInnerCells();
	gpu->outer_cells_count  = cpu->getNbOuterCells();

    /* problem sizes */
	gpu->nb_x_quads         = cpu->m_nb_x_quads;
	gpu->nb_y_quads         = cpu->m_nb_y_quads;

    /* Copy the big structure and all counters */
    #pragma omp target enter data map(alloc: gpu[:1])
    #pragma omp target update to (gpu[:1])

    /* The deep-copy part */
    #pragma omp target enter data map(alloc: gpu->inner_nodes [:gpu->inner_nodes_count ])
    #pragma omp target enter data map(alloc: gpu->top_nodes   [:gpu->top_nodes_count   ])
    #pragma omp target enter data map(alloc: gpu->bottom_nodes[:gpu->bottom_nodes_count])
    #pragma omp target enter data map(alloc: gpu->left_nodes  [:gpu->left_nodes_count  ])
    #pragma omp target enter data map(alloc: gpu->right_nodes [:gpu->right_nodes_count ])
    #pragma omp target update to (gpu->inner_nodes [:gpu->inner_nodes_count ])
    #pragma omp target update to (gpu->top_nodes   [:gpu->top_nodes_count   ])
    #pragma omp target update to (gpu->bottom_nodes[:gpu->bottom_nodes_count])
    #pragma omp target update to (gpu->left_nodes  [:gpu->left_nodes_count  ])
    #pragma omp target update to (gpu->right_nodes [:gpu->right_nodes_count ])

    #pragma omp target enter data map(alloc: gpu->top_cells   [:gpu->top_cells_count   ])
    #pragma omp target enter data map(alloc: gpu->bottom_cells[:gpu->bottom_cells_count])
    #pragma omp target enter data map(alloc: gpu->left_cells  [:gpu->left_cells_count  ])
    #pragma omp target enter data map(alloc: gpu->right_cells [:gpu->right_cells_count ])
    #pragma omp target update to (gpu->top_cells   [:gpu->top_cells_count   ])
    #pragma omp target update to (gpu->bottom_cells[:gpu->bottom_cells_count])
    #pragma omp target update to (gpu->left_cells  [:gpu->left_cells_count  ])
    #pragma omp target update to (gpu->right_cells [:gpu->right_cells_count ])

    #pragma omp target enter data map(alloc: gpu->inner_cells[:gpu->inner_cells_count])
    #pragma omp target enter data map(alloc: gpu->outer_cells[:gpu->outer_cells_count])
    #pragma omp target update to (gpu->inner_cells[:gpu->inner_cells_count])
    #pragma omp target update to (gpu->outer_cells[:gpu->outer_cells_count])
}

static inline void
GPU_CartesianMesh2D_free(GPU_CartesianMesh2D *gpu)
{
    GPU_MeshGeometry_free<2>(gpu->geometry);
    free(gpu->geometry);

    #pragma omp target exit data map(delete: gpu->inner_nodes [:gpu->inner_nodes_count ])
    #pragma omp target exit data map(delete: gpu->top_nodes   [:gpu->top_nodes_count   ])
    #pragma omp target exit data map(delete: gpu->bottom_nodes[:gpu->bottom_nodes_count])
    #pragma omp target exit data map(delete: gpu->left_nodes  [:gpu->left_nodes_count  ])
    #pragma omp target exit data map(delete: gpu->right_nodes [:gpu->right_nodes_count ])

    #pragma omp target exit data map(delete: gpu->top_cells   [:gpu->top_cells_count   ])
    #pragma omp target exit data map(delete: gpu->bottom_cells[:gpu->bottom_cells_count])
    #pragma omp target exit data map(delete: gpu->left_cells  [:gpu->left_cells_count  ])
    #pragma omp target exit data map(delete: gpu->right_cells [:gpu->right_cells_count ])

    #pragma omp target exit data map(delete: gpu->inner_cells[:gpu->inner_cells_count])
    #pragma omp target exit data map(delete: gpu->outer_cells[:gpu->outer_cells_count])

    #pragma omp target exit data map(delete: gpu[:1])
}

#endif /* NABLALIB_GPU */

}
#endif /* NABLALIB_MESH_CARTESIANMESH2D_H_ */
