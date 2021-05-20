/*******************************************************************************
 * Copyright (c) 2020 CEA
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 * Contributors: see AUTHORS file
 *******************************************************************************/

#include "nablalib/types/BoundedArray.h"
#include <iostream>
#include <typeinfo>

namespace nablalib::types
{

#ifdef TEST

int
main(void)
{
    BoundedArray<int, 4> arr1 = { 1, 2, 3, 4 };
    return arr1.boundary_size;
}

#endif

}