/*******************************************************************************
 * Copyright (c) 2020 CEA
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 * Contributors: see AUTHORS file
 *******************************************************************************/
#ifndef NABLALIB_MESH_MESHGEOMETRY_H_
#define NABLALIB_MESH_MESHGEOMETRY_H_

#include <vector>
#include <algorithm>

#include "nablalib/mesh/NodeIdContainer.h"

namespace nablalib::mesh
{

template<size_t N>
class MeshGeometry {
public:
    MeshGeometry(const std::vector<RealArray1D<N>>& nodes, const std::vector<Edge>& edges, const std::vector<Quad>& quads)
      : m_nodes(nodes), m_edges(edges), m_quads(quads) { }

    const std::vector<RealArray1D<N>>& getNodes() noexcept { return m_nodes; }
    const std::vector<Edge>&           getEdges() noexcept { return m_edges; }
    const std::vector<Quad>&           getQuads() noexcept { return m_quads; }

private:
    std::vector<RealArray1D<N>> m_nodes;
    std::vector<Edge> m_edges;
    std::vector<Quad> m_quads;
};

/* Need some GPU things */
#ifdef NABLALIB_GPU

/* Usage:
 *
 * MeshGeometry<2> *mesh = ...;
 * GPU_MeshGeometry<2> mesh_glb;
 * GPU_MeshGeometry_alloc<2>(&mesh_glb, mesh); // Now all the data is on GPU
 * ... ... ...
 * GPU_MeshGeometry_free<2>(&mesh_glb); // Now things are deleted from the GPU
 */

#pragma omp declare target
template<size_t N>
struct GPU_MeshGeometry
{
    const RealArray1D<N> *nodes;
    const Edge *edges;
    const Quad *quads;

    size_t nodes_count;
    size_t edges_count;
    size_t quads_count;
};
#pragma omp end declare target

#endif /* NABLALIB_GPU */

}
#endif /* NABLALIB_MESH_MESHGEOMETRY_H_ */
