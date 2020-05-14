/*******************************************************************************
 * Copyright (c) 2020 CEA
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 * Contributors: see AUTHORS file
 *******************************************************************************/
package fr.cea.nabla.ir.generator.cpp

import fr.cea.nabla.ir.ir.BaseType
import fr.cea.nabla.ir.ir.ConnectivityType

class Ir2CppUtils 
{
	static def dispatch boolean isBaseTypeStatic(ConnectivityType it)
	{ 
		base.baseTypeStatic
	}

	static def dispatch boolean isBaseTypeStatic(BaseType it)
	{ 
		sizes.empty || sizes.forall[x | x.constExpr]
	}
}