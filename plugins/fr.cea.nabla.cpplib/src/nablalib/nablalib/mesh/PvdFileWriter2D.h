/*******************************************************************************
 * Copyright (c) 2020 CEA
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 * Contributors: see AUTHORS file
 *******************************************************************************/
#ifndef NABLALIB_MESH_PVDFILEWRITER2D_H_
#define NABLALIB_MESH_PVDFILEWRITER2D_H_

#include <string>
#include <map>
#include <fstream>
#include <sstream>

#include "nablalib/types/Types.h"
#include "nablalib/mesh/NodeIdContainer.h"

using namespace std;

namespace nablalib::mesh
{

class PvdFileWriter2D
{
public:
	enum State { closed, ready, onNodes, nodesFinished, onCells, cellsFinished, onNodeArray, onCellArray };
	PvdFileWriter2D(const string& moduleName, const string& directoryName);
	~PvdFileWriter2D();

	bool isDisabled() { return m_directory_name.empty(); }
	const string& outputDirectory() { return m_directory_name; }

	void startVtpFile(
			const int& iteration,
			const double& time,
			const size_t& nbNodes,
			const RealArray1D<2>* nodes,
			const size_t& nbCells,
			const Quad* cells);

	void openNodeData();
	void openCellData();
	void openNodeArray(const string& name, const int& arraySize);
	void openCellArray(const string& name, const int& arraySize);
	void closeNodeData();
	void closeCellData();
	void closeNodeArray();
	void closeCellArray();

	void closeVtpFile();

	void write(const double& data)
	{
		m_vtp_writer << " " << data;
	}

	template<size_t N> void write(const RealArray1D<N>& data)
	{
		for (size_t i=0 ; i<N ; ++i)
			m_vtp_writer << " " << data[i];
	}

protected:
	ofstream m_vtp_writer;

private:
	void changeState(const State& expectedState, const State& newState);
	map<double, string> m_file_name_by_times;
	string m_module_name;
	string m_directory_name;
	State m_state;
};
}
#endif /* NABLALIB_MESH_PVDFILEWRITER2D_H_ */
