/*******************************************************************************
 * Copyright (c) 2020 CEA
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 * Contributors: see AUTHORS file
 *******************************************************************************/
#ifndef NABLALIB_TYPES_BOUNDEDARRAY_H_
#define NABLALIB_TYPES_BOUNDEDARRAY_H_

#include <array>
#include <cassert>
#include <algorithm>
#include <utility>

namespace nablalib::types
{

/******************************************************************************/
// Generic bounded array
// This is done to replace the 'return std::vector'. Doing this will _normally_
// permit us to have 1-Dimension std::vector for global nablab variable, and
// thus facilitate the map to GPU
template <typename T, size_t DIM>
struct BoundedArray : public std::array<T, DIM>
{
    static constexpr size_t boundary_size = DIM;

    inline void
    setUsedSize(size_t new_size) noexcept
    {
        assert(new_size <= boundary_size);
        used_size = new_size;
    }

    inline size_t
    getUsedSize(void) const noexcept
    {
        return used_size;
    }

    static inline BoundedArray<T, DIM>
    fromVector(const std::vector<T> &from)
    {
        BoundedArray<T, DIM> ret;
        ret.setUsedSize(from.size);
        std::copy(from.begin(), from.end(), ret->begin());
        return ret;
    }

    static inline BoundedArray<T, DIM>
    fromVector(const size_t new_size, const std::vector<T> &from)
    {
        BoundedArray<T, DIM> ret;
        ret.setUsedSize(new_size);
        for (size_t i = 0; i < new_size; ++i) {
            ret[i] = from[i];
        }
        return ret;
    }

private:
    size_t used_size { 0 };
};

}

#endif
