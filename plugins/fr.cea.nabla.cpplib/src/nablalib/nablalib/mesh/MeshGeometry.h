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
 * MeshGeometry *mesh = ...;
 * GPU_MeshGeometry mesh_glb;
 * GPU_MeshGeometry_alloc(&mesh_glb, mesh); // Now all the data is on GPU
 * ... ... ...
 * GPU_MeshGeometry_free(&mesh_glb); // Now things are deleted from the GPU
 */

template<size_t N>
struct GPU_MeshGeometry
{
    RealArray1D<n> *nodes;
    Edge *edges;
    Quad *quads;

    size_t nodes_count;
    size_t edges_count;
    size_t quads_count;
};

template<size_t N> static inline void
GPU_MeshGeometry_alloc(GPU_MeshGeometry<N> *gpu, MeshGeometry *cpu)
{
    /* Alias vectors to pointers... */
    gpu->nodes       = cpu->getNodes().data();
    gpu->edges       = cpu->getEdges().data();
    gpu->quads       = cpu->getQuads().data();
    gpu->nodes_count = cpu->getNodes().size();
    gpu->edges_count = cpu->getEdges().size();
    gpu->quads_count = cpu->getQuads().size();

    /* Copy the big structure with all counters */
    #pragma omp target enter data map(alloc: gpu[:1])
    #pragma omp target update to (gpu[:1])

    /* The deep-copy boi */
    #pragma omp target enter data map(alloc: gpu->nodes[:gpu->nodes_count])
    #pragma omp target enter data map(alloc: gpu->edges[:gpu->edges_count])
    #pragma omp target enter data map(alloc: gpu->quads[:gpu->quads_count])
    #pragma omp target update to (gpu->nodes[:gpu->nodes_count])
    #pragma omp target update to (gpu->edges[:gpu->edges_count])
    #pragma omp target update to (gpu->quads[:gpu->quads_count])
}

template<size_t N> static inline void
GPU_MeshGeometry_free(GPU_MeshGeometry<N> *gpu)
{
    /* Free in the correct order */
    #pragma omp target exit data(delete: gpu->nodes[:gpu->nodes_count])
    #pragma omp target exit data(delete: gpu->edges[:gpu->edges_count])
    #pragma omp target exit data(delete: gpu->quads[:gpu->quads_count])
    #pragma omp target exit data(delete: gpu[:1])
}

#endif /* NABLALIB_GPU */

}
#endif /* NABLALIB_MESH_MESHGEOMETRY_H_ */
