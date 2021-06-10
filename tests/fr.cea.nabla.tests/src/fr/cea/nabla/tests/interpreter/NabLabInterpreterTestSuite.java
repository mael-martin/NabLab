/*******************************************************************************
 * Copyright (c) 2021 CEA
 * This program and the accompanying materials are made available under the 
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 * Contributors: see AUTHORS file
 *******************************************************************************/
package fr.cea.nabla.tests.interpreter;

import org.junit.runner.RunWith;
import org.junit.runners.Suite;

@RunWith(Suite.class)

@Suite.SuiteClasses
({
	BinaryOperationsInterpreterTest.class,
	ExpressionInterpreterTest.class,
	InstructionInterpreterTest.class,
	JobInterpreterTest.class,
	ModuleInterpreterTest.class,
	OptionsInterpreterTest.class,
	NablaExamplesInterpreterTest.class
})

public class NabLabInterpreterTestSuite {}
