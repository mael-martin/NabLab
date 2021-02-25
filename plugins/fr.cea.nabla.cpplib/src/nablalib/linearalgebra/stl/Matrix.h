/*******************************************************************************
 * Copyright (c) 2020 CEA
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 * Contributors: see AUTHORS file
 *******************************************************************************/
#ifndef NABLALIB_LINEARALGEBRA_STL_MATRIX_H_
#define NABLALIB_LINEARALGEBRA_STL_MATRIX_H_

#include <iostream>
#include <iomanip>
#include <string>
#include <sstream>
#include <map>
#include <list>
#include <utility>
#include <algorithm>
#include <numeric>
#include <initializer_list>
#include <cmath>
#include <cassert>
#include <limits>
#include <mutex>

#include "nablalib/linearalgebra/stl/CrsMatrix.h"

namespace nablalib::linearalgebra::stl
{

typedef CrsMatrix<double> SparseMatrixType;

// TODO: templatiser la classe pour passer nb_row, nb_col, nb_nnz en tpl arg,
// calculable dans une passe d'IR pour passer toutes les a1loc en static
class Matrix
{

 public:
  Matrix(const std::string name, const int rows, const int cols);
  explicit Matrix(const std::string name, const int rows, const int cols,
                  std::initializer_list<std::tuple<int, int, double>> init_list);
  ~Matrix();

  // explicit build
  void build();
  // implicit build and accessor
  SparseMatrixType& crsMatrix();
  const int getNbRows() const;
  const int getNbCols() const;
  // getter
  double getValue(const int row, const int col) const;
  // setter
  void setValue(const int row, const int col, double value);
  
 //private:
  int findCrsOffset(const int& i, const int& j) const;

  // Attributes
  std::map<int, std::list<std::pair<int, double>>> m_building_struct;
  const std::string m_name;
  const int m_nb_rows;
  const int m_nb_cols;
  int m_nb_nnz;
  SparseMatrixType* m_matrix;
  std::mutex m_mutex;
};

}
#endif /* NABLALIB_LINEARALGEBRA_STL_MATRIX_H_ */
