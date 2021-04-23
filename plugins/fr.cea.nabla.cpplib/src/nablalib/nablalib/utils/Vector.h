/* Need the following before being included:
 * #define NABLA_ALLOCATOR mmap_allocator
 * or
 * #define NABLA_ALLOCATOR std::allocator
 */


#pragma once

#include <vector>
extern "C"
{
#include <sys/mman.h>
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
}

template <typename T>
class mmap_allocator
{
public:
	typedef size_t size_type;
	typedef ptrdiff_t difference_type;
	typedef T *pointer;
	typedef const T *const_pointer;
	typedef T &reference;
	typedef const T &const_reference;
	typedef T value_type;

	mmap_allocator()  noexcept = default;
	~mmap_allocator() noexcept = default;

	template <class U>
	struct rebind
	{
		typedef mmap_allocator<U> other;
	};

	template <class U> mmap_allocator (const mmap_allocator<U> &) {}

	auto address(reference x) const noexcept -> pointer { return &x; }
	auto address(const_reference x) const noexcept -> const_pointer { return &x; }
	auto max_size() const -> size_type { return size_t(-1) / sizeof(value_type); }

	pointer allocate(size_type n, const T *hint = 0) noexcept
	{
		return (pointer)mmap(nullptr, sizeof(T) * n, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
	}

	void deallocate(pointer p, size_type n) noexcept
	{
		if (munmap(p, sizeof(T) * n)) {
			perror("munmap");
			exit(EXIT_FAILURE);
		}
	}

	void construct(pointer p, const T &val) { new (static_cast<void *>(p)) T(val); }
	void construct(pointer p) { new (static_cast<void *>(p)) T(); }
	void destroy(pointer p) { p->~T(); }
};

template <typename T>
using nabla_vector = std::vector<T, NABLA_ALLOCATOR<T>>;
