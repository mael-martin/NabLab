#ifndef NABLALIB_UTILS_PNM_PNM_H
#define NABLALIB_UTILS_PNM_PNM_H

#ifdef __cplusplus
extern "C" {
#endif

#include <inttypes.h>
#include <stdlib.h>
#include <stdio.h>

struct pnm_file {
    const char *name;
    int type;
    char header[3];
    int xsize;
    int ysize;
    int maxval;
    FILE *fd;
    uint8_t *bitmap;
};

/* Write the content of a pnm file */
int pnm_file_write(struct pnm_file *);

/* Open an existing pnm file */
int pnm_file_open(struct pnm_file *);

/* Close the pnm file, will be written onto disk before closing */
int pnm_file_close(struct pnm_file *);

/* Create a new pnm file */
struct pnm_file * pnm_file_new(int X, int Y, const char *name);

#ifdef __cplusplus
}
#endif

#endif // NABLALIB_UTILS_PNM_PNM_H
