/*******************************************************************************
 * Copyright (c) 2020 CEA
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 * Contributors: see AUTHORS file
 *******************************************************************************/

#include "nablalib/types/MultiArray.h"
#include <iostream>
#include <typeinfo>

namespace nablalib::types
{

/******************************************************************************/
void dummy() {

  RealArray<7> v{{0., 1., 2., 3., 4., 5., 6.}};

  std::cout << "RealArray<7> v test value:\t" << v << std::endl;
  std::cout << "v dimension is: " << v.dimensions << std::endl;

  std::cout << "Adding 10 to every values of v, 'on the fly':\t" << v + 10 << std::endl << std::endl;

  std::cout << "Same operation but in place (by modifying v itself):\n";
  v += 10;
  std::cout << v << std::endl << std::endl;

  std::cout << "Adding 10 again, then dividing by 2 every values 'on the fly':\n\t" << (v + 10) / 2 << std::endl << std::endl;

  std::cout << "Testing array operation, (v + v) == (v * 2) : "
            << std::boolalpha << (v + v == v * 2) << std::endl << std::endl;

  std::cout << "4 dimensions test:\n\t";
  RealArray<3, 4, 5, 6> u;
  u[0][0][0][0] = 666.;
  std::cout << "u[0][0][0][0] = " << u[0][0][0][0] << std::endl << "u dimensions are: " << u.dimensions << std::endl;

  std::cout << "5x5 matrix w:\n";

  constexpr size_t DIM1 = 5;
  constexpr size_t DIM2 = 2;
  constexpr size_t DIM3 = 3;
  IntArray<DIM1, DIM2 + DIM3> w{ 2, -1,  0,  0,  0,
                                -1,  2, -1,  0,  0,
                                 0, -1,  2, -1,  0,
                                 0,  0, -1,  2, -1,
                                 0,  0,  0, -1,  2};

  std::cout << w << std::endl;

  std::cout << "Testing array operation, (w + w) == (w * 2) : "
            << std::boolalpha << (w + w == w * 2) << std::endl << std::endl;

  std::cout << "Multiplying by 2.66 every values of w (rouding to integer):\n";
  RealArray<5, 5> tmp(w * 2.66);
  w *= 2.66;
  std::cout << w << std::endl;

  std::cout << "While values should be (if not rounded):\n";
  std::cout << tmp <<  std::endl;
}

/******************************************************************************/
#ifdef TEST

int main() {
  dummy();
}

#endif

}
