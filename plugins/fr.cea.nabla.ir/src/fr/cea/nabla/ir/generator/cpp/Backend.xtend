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

import fr.cea.nabla.ir.transformers.IrTransformationStep
import fr.cea.nabla.ir.transformers.JobMergeFromCost
import fr.cea.nabla.ir.transformers.ReplaceReductions
import org.eclipse.xtend.lib.annotations.Accessors

import static fr.cea.nabla.ir.generator.cpp.CppGeneratorUtils.*
import static fr.cea.nabla.ir.generator.cpp.OpenMpTaskMainContentProvider.*

abstract class Backend
{
	@Accessors(PUBLIC_GETTER, PROTECTED_SETTER) String name
	@Accessors(PUBLIC_GETTER, PROTECTED_SETTER) IrTransformationStep irTransformationStep = null
	@Accessors(PUBLIC_GETTER, PROTECTED_SETTER) CMakeContentProvider cmakeContentProvider
	@Accessors(PUBLIC_GETTER, PROTECTED_SETTER) TypeContentProvider typeContentProvider
	@Accessors(PUBLIC_GETTER, PROTECTED_SETTER) ExpressionContentProvider expressionContentProvider
	@Accessors(PUBLIC_GETTER, PROTECTED_SETTER) InstructionContentProvider instructionContentProvider
	@Accessors(PUBLIC_GETTER, PROTECTED_SETTER) FunctionContentProvider functionContentProvider
	@Accessors(PUBLIC_GETTER, PROTECTED_SETTER) TraceContentProvider traceContentProvider
	@Accessors(PUBLIC_GETTER, PROTECTED_SETTER) IncludesContentProvider includesContentProvider
	@Accessors(PUBLIC_GETTER, PROTECTED_SETTER) JsonContentProvider jsonContentProvider
	@Accessors(PUBLIC_GETTER, PROTECTED_SETTER) JobCallerContentProvider jobCallerContentProvider
	@Accessors(PUBLIC_GETTER, PROTECTED_SETTER) JobContentProvider jobContentProvider
	@Accessors(PUBLIC_GETTER, PROTECTED_SETTER) MainContentProvider mainContentProvider
}

/** Expected variables: N_CXX_COMPILER */
class SequentialBackend extends Backend
{
	new()
	{
		name 									= 'Sequential'
		JobContentProvider::task_mode 			= false
		CppApplicationGenerator::first_touch    = false
		
		irTransformationStep = new ReplaceReductions(true)
		cmakeContentProvider = new CMakeContentProvider
		typeContentProvider = new StlThreadTypeContentProvider
		expressionContentProvider = new ExpressionContentProvider(typeContentProvider)
		instructionContentProvider = new SequentialInstructionContentProvider(typeContentProvider, expressionContentProvider)
		functionContentProvider = new FunctionContentProvider(typeContentProvider, expressionContentProvider, instructionContentProvider)
		traceContentProvider = new TraceContentProvider
		includesContentProvider = new SequentialIncludesContentProvider
		jsonContentProvider = new JsonContentProvider(expressionContentProvider)
		jobCallerContentProvider = new JobCallerContentProvider
		jobContentProvider = new StlThreadJobContentProvider(traceContentProvider, expressionContentProvider, instructionContentProvider, jobCallerContentProvider)
		mainContentProvider = new MainContentProvider(jsonContentProvider)
	}
}

/** Expected variables: N_CXX_COMPILER */
class StlThreadBackend extends Backend
{
	new()
	{
		name 									= 'StlThread'
		JobContentProvider::task_mode 			= false
		CppApplicationGenerator::first_touch    = false

		cmakeContentProvider = new StlThreadCMakeContentProvider
		typeContentProvider = new StlThreadTypeContentProvider
		expressionContentProvider = new ExpressionContentProvider(typeContentProvider)
		instructionContentProvider = new StlThreadInstructionContentProvider(typeContentProvider, expressionContentProvider)
		functionContentProvider = new FunctionContentProvider(typeContentProvider, expressionContentProvider, instructionContentProvider)
		traceContentProvider = new TraceContentProvider
		includesContentProvider = new StlThreadIncludesContentProvider
		jsonContentProvider = new JsonContentProvider(expressionContentProvider)
		jobCallerContentProvider = new JobCallerContentProvider
		jobContentProvider = new StlThreadJobContentProvider(traceContentProvider, expressionContentProvider, instructionContentProvider, jobCallerContentProvider)
		mainContentProvider = new MainContentProvider(jsonContentProvider)
	}
}

/** Expected variables: N_CXX_COMPILER, N_KOKKOS_PATH */
class KokkosBackend extends Backend
{
	new()
	{
		name 									= 'Kokkos'
		JobContentProvider::task_mode 			= false
		CppApplicationGenerator::first_touch    = false

		cmakeContentProvider = new KokkosCMakeContentProvider
		typeContentProvider = new KokkosTypeContentProvider
		expressionContentProvider = new ExpressionContentProvider(typeContentProvider)
		instructionContentProvider = new KokkosInstructionContentProvider(typeContentProvider, expressionContentProvider)
		functionContentProvider = new KokkosFunctionContentProvider(typeContentProvider, expressionContentProvider, instructionContentProvider)
		traceContentProvider = new KokkosTraceContentProvider
		includesContentProvider = new KokkosIncludesContentProvider
		jsonContentProvider = new JsonContentProvider(expressionContentProvider)
		jobCallerContentProvider = new JobCallerContentProvider
		jobContentProvider = new KokkosJobContentProvider(traceContentProvider, expressionContentProvider, instructionContentProvider, jobCallerContentProvider)
		mainContentProvider = new KokkosMainContentProvider(jsonContentProvider)
	}
}

/** Expected variables: N_CXX_COMPILER, N_KOKKOS_PATH */
class KokkosTeamThreadBackend extends Backend
{
	new()
	{
		name 									= 'Kokkos Team Thread'
		JobContentProvider::task_mode 			= false
		CppApplicationGenerator::first_touch    = false

		cmakeContentProvider = new KokkosCMakeContentProvider
		typeContentProvider = new KokkosTypeContentProvider
		expressionContentProvider = new ExpressionContentProvider(typeContentProvider)
		instructionContentProvider = new KokkosTeamThreadInstructionContentProvider(typeContentProvider, expressionContentProvider)
		functionContentProvider = new KokkosFunctionContentProvider(typeContentProvider, expressionContentProvider, instructionContentProvider)
		traceContentProvider = new KokkosTraceContentProvider
		includesContentProvider = new KokkosIncludesContentProvider
		jsonContentProvider = new JsonContentProvider(expressionContentProvider)
		jobCallerContentProvider = new KokkosTeamThreadJobCallerContentProvider
		jobContentProvider = new KokkosTeamThreadJobContentProvider(traceContentProvider, expressionContentProvider, instructionContentProvider, jobCallerContentProvider)
		mainContentProvider = new KokkosMainContentProvider(jsonContentProvider)
	}
}

/** Expected variables: N_CXX_COMPILER */
class OpenMpBackend extends Backend
{
	new()
	{
		name 									= 'OpenMP'
		CppApplicationGenerator::first_touch    = false
		JobContentProvider::task_mode 			= false

		cmakeContentProvider = new OpenMpCMakeContentProvider
		typeContentProvider = new StlThreadTypeContentProvider
		expressionContentProvider = new ExpressionContentProvider(typeContentProvider)
		instructionContentProvider = new OpenMpInstructionContentProvider(typeContentProvider, expressionContentProvider)
		functionContentProvider = new FunctionContentProvider(typeContentProvider, expressionContentProvider, instructionContentProvider)
		traceContentProvider = new TraceContentProvider
		includesContentProvider = new OpenMpIncludesContentProvider
		jsonContentProvider = new JsonContentProvider(expressionContentProvider)
		jobCallerContentProvider = new JobCallerContentProvider
		jobContentProvider = new StlThreadJobContentProvider(traceContentProvider, expressionContentProvider, instructionContentProvider, jobCallerContentProvider)
		mainContentProvider = new MainContentProvider(jsonContentProvider)
	}
}

/** Expected variables: N_CXX_COMPILER */
class OpenMpTaskV2Backend extends Backend
{
	new()
	{
		OMPTraces        					 = false
		CppApplicationGenerator::first_touch = false
		name             					 = 'OpenMPTask'

		cmakeContentProvider       = new OpenMpTaskCMakeContentProvider
		typeContentProvider        = new StlThreadTypeContentProvider
		expressionContentProvider  = new ExpressionContentProvider(typeContentProvider)
		instructionContentProvider = new OpenMpTaskV2InstructionContentProvider(typeContentProvider, expressionContentProvider)
		functionContentProvider    = new FunctionContentProvider(typeContentProvider, expressionContentProvider, instructionContentProvider)
		traceContentProvider       = new TraceContentProvider
		includesContentProvider    = new OpenMpIncludesContentProvider
		jsonContentProvider        = new JsonContentProvider(expressionContentProvider)
		jobCallerContentProvider   = new OpenMpTaskV2JobCallerContentProvider
		jobContentProvider         = new StlThreadJobContentProvider(traceContentProvider, expressionContentProvider, instructionContentProvider, jobCallerContentProvider)
		mainContentProvider        = new OpenMpTaskMainContentProvider(jsonContentProvider)
		registerTypeContentProvider(typeContentProvider)
	}
}

/** Expected variables: N_CXX_COMPILER, N_C_COMPILER */
class OpenMpTaskBackend extends Backend
{
	new()
	{
		OpenMpTaskMainContentProvider::num_threads 		 = JobMergeFromCost::num_threads; // FIXME: Must be set by the user
		OpenMpTaskMainContentProvider::max_active_levels = 1; 
		OMPTaskMaxNumber 							 	 = JobMergeFromCost::num_tasks
		OMPTraces        								 = false
		CppApplicationGenerator::first_touch    		 = true
		JobContentProvider::task_mode                    = false
		name             								 = 'OpenMPTask'

		cmakeContentProvider       = new OpenMpTaskCMakeContentProvider
		typeContentProvider        = new StlThreadTypeContentProvider
		expressionContentProvider  = new ExpressionContentProvider(typeContentProvider)
		instructionContentProvider = new OpenMpTaskInstructionContentProvider(typeContentProvider, expressionContentProvider, new OpenMPTaskMPCProvider)
		functionContentProvider    = new FunctionContentProvider(typeContentProvider, expressionContentProvider, instructionContentProvider)
		traceContentProvider       = new TraceContentProvider
		includesContentProvider    = new OpenMpIncludesContentProvider
		jsonContentProvider        = new JsonContentProvider(expressionContentProvider)
		jobCallerContentProvider   = new OpenMpTaskJobCallerContentProvider
		jobContentProvider         = new StlThreadJobContentProvider(traceContentProvider, expressionContentProvider, instructionContentProvider, jobCallerContentProvider)
		mainContentProvider        = new OpenMpTaskMainContentProvider(jsonContentProvider)
		registerTypeContentProvider(typeContentProvider)
	}
}

/** Expected variables: N_CXX_COMPILER, N_C_COMPILER */
class OpenMpGPUBackend extends Backend
{
	new()
	{
		OpenMpTaskMainContentProvider::num_threads       = JobMergeFromCost::num_threads
		OpenMpTaskMainContentProvider::max_active_levels = 1
		OMPTaskMaxNumber                                 = JobMergeFromCost::num_tasks
		OMPTraces                                        = false
		JobContentProvider::task_mode                    = false
		CppApplicationGenerator::first_touch             = false
		OpenMPTargetProvider::num_threads                = JobMergeFromCost::num_threads
		name                                             = 'OpenMPTarget'

		cmakeContentProvider       = new OpenMpTargetCMakeContentProvider
		typeContentProvider        = new StlThreadTypeContentProvider
		expressionContentProvider  = new ExpressionContentProvider(typeContentProvider)
		instructionContentProvider = new OpenMpTargetInstructionContentProvider(typeContentProvider, expressionContentProvider, new OpenMPTargetProvider)
		functionContentProvider    = new FunctionContentProvider(typeContentProvider, expressionContentProvider, instructionContentProvider)
		traceContentProvider       = new TraceContentProvider
		includesContentProvider    = new OpenMpIncludesContentProvider
		jsonContentProvider        = new JsonContentProvider(expressionContentProvider)
		jobCallerContentProvider   = new JobCallerContentProvider
		jobContentProvider         = new StlThreadJobContentProvider(traceContentProvider, expressionContentProvider, instructionContentProvider, jobCallerContentProvider)
		mainContentProvider        = new OpenMpTaskMainContentProvider(jsonContentProvider)
		registerTypeContentProvider(typeContentProvider)
	}
}

/** Expected variables: N_CXX_COMPILER, N_C_COMPILER */
class OpenMpTargetBackend extends Backend
{
	new()
	{
		OpenMpTaskMainContentProvider::num_threads       = JobMergeFromCost::num_threads
		OpenMpTaskMainContentProvider::max_active_levels = 1
		OMPTaskMaxNumber                                 = JobMergeFromCost::num_tasks
		OMPTraces                                        = false
		JobContentProvider::task_mode                    = true
		CppApplicationGenerator::first_touch             = false
		OpenMPTargetProvider::num_threads                = JobMergeFromCost::num_threads
		name                                             = 'OpenMPTarget'

		cmakeContentProvider       = new OpenMpTargetCMakeContentProvider
		typeContentProvider        = new StlThreadTypeContentProvider
		expressionContentProvider  = new ExpressionContentProvider(typeContentProvider)
		instructionContentProvider = new OpenMpTargetInstructionContentProvider(typeContentProvider, expressionContentProvider, new OpenMPTargetProvider)
		functionContentProvider    = new FunctionContentProvider(typeContentProvider, expressionContentProvider, instructionContentProvider)
		traceContentProvider       = new TraceContentProvider
		includesContentProvider    = new OpenMpIncludesContentProvider
		jsonContentProvider        = new JsonContentProvider(expressionContentProvider)
		jobCallerContentProvider   = new OpenMpTargetJobCallerContentProvider
		jobContentProvider         = new StlThreadJobContentProvider(traceContentProvider, expressionContentProvider, instructionContentProvider, jobCallerContentProvider)
		mainContentProvider        = new OpenMpTaskMainContentProvider(jsonContentProvider)
		registerTypeContentProvider(typeContentProvider)
	}
}
