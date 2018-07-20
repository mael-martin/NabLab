/*******************************************************************************
 * Copyright (c) 2018 CEA
 * This program and the accompanying materials are made available under the 
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 *
 * Contributors:
 * 	Benoit Lelandais - initial implementation
 * 	Marie-Pierre Oudot - initial implementation
 * 	Jean-Sylvan Camier - Nabla generation support
 *******************************************************************************/
#ifndef MESH_MESH_H_
#define MESH_MESH_H_

#include <vector>
#include <algorithm>

#include "mesh/NodeIdContainer.h"

using namespace std;

namespace nablalib
{

template<class T> class Mesh
{
public:
	Mesh(int nbNodes, int nbEdges, int nbQuads, int nbInnerNodes)
	: m_nodes(nbNodes)
	, m_edges(nbEdges)
	, m_quads(nbQuads)
	, m_innerNodeIds(nbInnerNodes)
	{}

	const vector<int> getQuadIdsOfNode(const int nodeId)
	{
		vector<int> candidateQuadIds;
		for (int quadId = 0; quadId < m_quads.size(); quadId++)
		{
			auto q = m_quads[quadId];
			auto qNodeIds = q.getNodeIds();
			if (find(qNodeIds.begin(), qNodeIds.end(), nodeId)
					!= qNodeIds.end())
				candidateQuadIds.push_back(quadId);
		}
		return candidateQuadIds;
	}

	vector<Edge>& getEdges() { return m_edges; }
	vector<int>& getInnerNodeIds() { return m_innerNodeIds; }
	vector<T>& getNodes() { return m_nodes; }
	vector<Quad>& getQuads() { return m_quads; }

private:
	vector<T> m_nodes;
	vector<Edge> m_edges;
	vector<Quad> m_quads;
	vector<int> m_innerNodeIds;
};

}
#endif /* MESH_MESH_H_ */
