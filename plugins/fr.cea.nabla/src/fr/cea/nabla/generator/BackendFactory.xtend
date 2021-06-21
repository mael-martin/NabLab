package fr.cea.nabla.generator

import fr.cea.nabla.ir.generator.cpp.Backend
import fr.cea.nabla.ir.generator.cpp.KokkosBackend
import fr.cea.nabla.ir.generator.cpp.KokkosTeamThreadBackend
import fr.cea.nabla.ir.generator.cpp.OpenMpBackend
import fr.cea.nabla.ir.generator.cpp.SequentialBackend
import fr.cea.nabla.ir.generator.cpp.StlThreadBackend
import fr.cea.nabla.ir.generator.cpp.OpenMpTaskBackend
import fr.cea.nabla.ir.generator.cpp.OpenMpTaskV2Backend
import fr.cea.nabla.ir.generator.cpp.OpenMpTargetBackend
import fr.cea.nabla.nablagen.TargetType

class BackendFactory
{
	def Backend getCppBackend(TargetType type)
	{
		switch type
		{
			case CPP_SEQUENTIAL: new SequentialBackend
			case STL_THREAD: new StlThreadBackend
			case OPEN_MP: new OpenMpBackend
			case OPEN_MP_TASK: new OpenMpTaskBackend
			case OPEN_MP_TASK_V2: new OpenMpTaskV2Backend
			case OPEN_MP_TARGET: new OpenMpTargetBackend
			case KOKKOS: new KokkosBackend
			case KOKKOS_TEAM_THREAD: new KokkosTeamThreadBackend
			default: throw new RuntimeException("No backend for type: " + type.literal)
		}
	}
}