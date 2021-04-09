#include <nablalib/utils/pnm/pnm.h>
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>

int
main(int argc, char **argv)
{
#if 0
    assert(argc == 2);
    struct pnm_file file = { .name = argv[1] };
    assert(!pnm_file_open(&file));
    printf("HEADER: '%c%c%c'\n", file.header[0], file.header[1], file.header[2]);
    printf("TYPE: '%d'\n", file.type);
#endif

    assert(argc == 2);
    struct pnm_file *file = pnm_file_new(10, 10, argv[1]);
    assert(file);
    assert(!pnm_file_close(file));

    return 0;
}
