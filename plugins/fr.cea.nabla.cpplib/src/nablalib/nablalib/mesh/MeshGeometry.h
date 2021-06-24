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

#include "nablalib/utils/OMPTarget.h"
#include <cstdio>

template<size_t N> __attribute__((noinline)) static void
GPU_MeshGeometry_alloc(GPU_MeshGeometry<N> *gpu, MeshGeometry<N> *cpu)
{
    static_assert(std::is_trivial<GPU_MeshGeometry<N>>::value, "Must be trivial");
    GPU_MeshGeometry<N> local_gpu;

    /* Alias vectors to pointers... Construct the thing as it should be on the
     * GPU, to raw copy later. */
    local_gpu.nodes_count = cpu->getNodes().size();
    local_gpu.edges_count = cpu->getEdges().size();
    local_gpu.quads_count = cpu->getQuads().size();
    local_gpu.nodes       = N_GPU_ALLOC_VECTOR(RealArray1D<N>, cpu->getNodes().size());
    local_gpu.edges       = N_GPU_ALLOC_VECTOR(Edge,           cpu->getEdges().size());
    local_gpu.quads       = N_GPU_ALLOC_VECTOR(Quad,           cpu->getQuads().size());

    /* Raw copy the local boi into the GPU */
    N_VECTOR_CPU_TO_GPU(local_gpu.nodes, cpu->getNodes(), RealArray1D<N>);
    N_VECTOR_CPU_TO_GPU(local_gpu.edges, cpu->getEdges(), Edge);
    N_VECTOR_CPU_TO_GPU(local_gpu.quads, cpu->getQuads(), Quad);

    int rc = omp_target_memcpy(gpu, &local_gpu, sizeof(GPU_MeshGeometry<N>),
                               0, 0, omptarget_device_id, omptarget_host_id);
    fprintf(stderr, "[GPU_MeshGeometry_alloc] omp_target_memcpy -> %d\n", rc);
}

template<size_t N> static inline void
GPU_MeshGeometry_free(GPU_MeshGeometry<N> *gpu)
{
    /* Get the raw GPU data to get GPU pointers */
    GPU_MeshGeometry<N> local_gpu;
    omp_target_memcpy(&local_gpu, gpu, sizeof(GPU_MeshGeometry<N>),
                      0, 0, omptarget_host_id, omptarget_device_id);
    N_GPU_FREE(local_gpu.nodes);
    N_GPU_FREE(local_gpu.quads);
    N_GPU_FREE(local_gpu.edges);
}

#endif /* NABLALIB_GPU */

}
#endif /* NABLALIB_MESH_MESHGEOMETRY_H_ */
