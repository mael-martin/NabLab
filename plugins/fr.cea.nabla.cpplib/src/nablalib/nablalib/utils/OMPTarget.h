#pragma once

#pragma omp declare target
extern "C" {
extern int omptarget_device_id;
extern int omptarget_host_id;
}
#pragma omp end declare target

/* Move a vector to the GPU */
#define N_VECTOR_CPU_TO_GPU(gpu_ptr, cpu_vector, base_type)             \
    omp_target_memcpy((void *)gpu_ptr, (void *)((cpu_vector).data()),   \
                      sizeof(base_type) * (cpu_vector).size(),          \
                      0, 0, omptarget_device_id, omptarget_host_id)

/* Move a vector to the CPU */
#define N_VECTOR_CPU_FROM_GPU(gpu_ptr, cpu_vector, base_type)

/* Alloc macros: Simple case */
#define N_GPU_ALLOC(basetype) \
    (basetype *)omp_target_alloc(sizeof(basetype), omptarget_device_id)

/* Alloc macros: Vector case */
#define N_GPU_ALLOC_VECTOR(basetype, size) \
    (basetype *)omp_target_alloc(sizeof(basetype) * (size), omptarget_device_id)

/* Free a GPU pointer */
#define N_GPU_FREE(ptr) omp_target_free((void *)ptr, omptarget_device_id)
