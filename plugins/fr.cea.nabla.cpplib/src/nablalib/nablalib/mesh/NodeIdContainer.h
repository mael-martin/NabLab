/*******************************************************************************
 * Copyright (c) 2020 CEA
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 * Contributors: see AUTHORS file
 *******************************************************************************/
#ifndef NABLALIB_MESH_NODEIDCONTAINER_H_
#define NABLALIB_MESH_NODEIDCONTAINER_H_

#include <iostream>
#include <array>
#include <type_traits>
#include <utility>

using namespace std;
using namespace nablalib::types;

namespace nablalib::mesh
{

// Template class for node IDs collection. Restricted usage of integral types.
template <typename T, size_t N, typename enable_if<is_integral<T>::value>::type* = nullptr>
struct NodeIdContainer : public array<T, N>
{
    const array<T, N>&
    getNodeIds() const noexcept
    {
        static_assert(std::is_trivial<NodeIdContainer<T, N>>::value, "Must be trivial");
        return *this;
    }
};

template <typename T, size_t N>
ostream& operator<<(ostream& s, const NodeIdContainer<T, N>& o)
{
    auto nodeIds = o.getNodeIds();
    if (nodeIds.size() > 0) {
        s << "[" << nodeIds[0];
        for (size_t i(1); i < nodeIds.size(); ++i)
            s << ", " << nodeIds[i];
        s << "]";
    }
    return s;
}

// Type alias
using Edge = NodeIdContainer<Id, 2>;
using Quad = NodeIdContainer<Id, 4>;

}
#endif /* NABLALIB_MESH_NODEIDCONTAINER_H_ */
