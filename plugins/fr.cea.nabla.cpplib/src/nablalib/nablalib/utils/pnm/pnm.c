#include "nablalib/utils/pnm/pnm.h"
#include <string.h>

static unsigned char pnm_file_masks[] = {
    0x80, 0x40, 0x20, 0x10,
    0x08, 0x04, 0x02, 0x01
};

#define READ_BUFFER_MAX 4096

static inline int
___pnm_file_read_header(struct pnm_file *file)
{
    char str[READ_BUFFER_MAX];

    fgets(str, READ_BUFFER_MAX, file->fd);

    while (str[0] == '#')
        fgets(str, READ_BUFFER_MAX, file->fd);
    sscanf(str, "%s", file->header);

    if (file->header[0] == 'P') {
        sscanf(&file->header[1], "%d", &file->type);
        return 0;
    }

    else {
        return 1;
    }
}

static inline void
___pnm_file_new_defaults(struct pnm_file *file)
{
    file->type      = 5;
    file->header[0] = 'P';
    file->header[1] = '5';
    file->header[2] = '\0';
}

static inline int
___pnm_file_read_size(struct pnm_file *file)
{
    char str[READ_BUFFER_MAX];

    if (NULL == fgets(str, READ_BUFFER_MAX, file->fd))
        return 1;

    while (str[0] == '#') {
        if (NULL == fgets(str, READ_BUFFER_MAX, file->fd))
            return 1;
    }

    if (EOF == sscanf(str, "%d %d", &file->xsize, &file->ysize))
        return 1;

    return 0;
}

static inline int
___pnm_file_read_maxval(struct pnm_file *file)
{
    char str[READ_BUFFER_MAX];

    if (NULL == fgets(str, READ_BUFFER_MAX, file->fd))
        return 1;

    while (str[0] == '#') {
        if (NULL == fgets(str, READ_BUFFER_MAX, file->fd))
            return 1;
    }

    if (EOF == sscanf(str, "%d", &file->maxval))
        return 1;

    return 0;
}

static inline int
___pnm_file_read_raw(struct pnm_file *file, int linesize)
{
    int thebyte;

    file->bitmap = (uint8_t *) malloc(file->ysize * linesize);
    if (file->bitmap == NULL)
        return 1;

    if (file->type == 4) {
        int adr = 0;
        int ls = ((file->xsize - 1) / 8) + 1;
        uint8_t *line = (uint8_t *) malloc(ls);
        if (NULL == line) {
            free(file->bitmap);
            file->bitmap = NULL;
            return 1;
        }

        for (int i = 0; i < file->ysize; i++) {
            fread(line, ls, 1, file->fd);

            for (int j = 0; j < file->xsize; j++) {
                thebyte = (int) (j / 8);
                file->bitmap[adr] = (!(line[thebyte] & pnm_file_masks[j % 8])) * 255;
                adr++;
            }
        }
        free(line);
    }

    else if (0 == fread(file->bitmap, sizeof(uint8_t), file->ysize * linesize, file->fd)) {
        free(file->bitmap);
        file->bitmap = NULL;
        return 1;
    }

    return 0;
}

static inline int
___pnm_file_read_ascii(struct pnm_file *file, int linesize)
{
    int thebit;
    unsigned char val;
    int adr;

    file->bitmap = (uint8_t *) malloc(file->ysize * linesize);
    if (file->bitmap == NULL)
        return 1;

    if (file->type == 1) {
        adr = 0;
        for (int i = 0; i < file->ysize; i++) {
            for (int j = 0; j < linesize; j++) {
                val = 0;
                for (int k = 0; k < 8; k++) {
                    if (EOF == fscanf(file->fd, "%d", &thebit))
                        goto error;
                    if (thebit)
                        val |= pnm_file_masks[k];
                }
                file->bitmap[adr] = val;
                adr ++;
            }
        }
    }

    else {
        adr = 0;
        for (int i = 0; i < file->ysize; i++) {
            for (int j = 0; j < linesize; j++) {
                if (EOF == fscanf(file->fd, "%c", &file->bitmap[adr]))
                    goto error;
                adr++;
            }
        }
    }

    return 0;
error:
    if (file->bitmap) {
        free(file->bitmap);
        file->bitmap = NULL;
    }
    return 1;
}

static inline int
___pnm_file_read(struct pnm_file *file)
{
    unsigned int linesize;

    switch (file->type) {
    case 1:
        linesize = ((file->xsize - 1) / 8) + 1;
        // linesize = file->xsize;
        return ___pnm_file_read_ascii(file, linesize);

    case 2:
        linesize = file->xsize;
        return ___pnm_file_read_ascii(file, linesize);

    case 3:
        linesize = 3 * file->xsize;
        return ___pnm_file_read_ascii(file, linesize);
        break;
    case 4:
        linesize = ((file->xsize - 1) / 8) + 1;
        // linesize = file->xsize;
        return ___pnm_file_read_raw(file, linesize);

    case 5:
        linesize = file->xsize;
        return ___pnm_file_read_raw(file, linesize);

    case 6:
        linesize = file->xsize * 3;
        return ___pnm_file_read_raw(file, linesize);

    default:
        return 1;
    }
}

int
pnm_file_open(struct pnm_file *file)
{
    file->fd = fopen(file->name, "r+b");
    if (file->fd == NULL)
        return 1;

    if (___pnm_file_read_header(file) ||
        ___pnm_file_read_size(file))
        return 1;

    if ((file->type != 1) && (file->type != 4) &&
        ___pnm_file_read_maxval(file))
        return 1;

    return ___pnm_file_read(file);
}


int
pnm_file_close(struct pnm_file *file)
{
    if (pnm_file_write(file))
        return 1;

    if (file->bitmap) {
        free(file->bitmap);
        file->bitmap = NULL;
    }

    if (NULL != file->fd) {
        fclose(file->fd);
        file->fd = NULL;
    }

    return 0;
}

static inline int
___pnm_file_write_raw(struct pnm_file *file, int linesize)
{
    return (0 == fwrite(file->bitmap, sizeof(uint8_t),
                        linesize * file->ysize, file->fd));
}

static inline int
___pnm_file_write_ascii(struct pnm_file *file, int linesize)
{
    int thebyte, thepixel, adr;

    if (file->type == 1) {
        adr = 0;

        for (int i = 0; i < file->ysize; i++) {
            for (int j = 0; j < file->xsize; j++) {
                thepixel = (i * file->xsize) + j;
                thebyte  = (int)(thepixel / 8);
                if (2 != fprintf(file->fd, "%1d ",
                                 file->bitmap[thebyte] & pnm_file_masks[thepixel % 8]))
                    return 1;
            }
            if (1 != fprintf(file->fd,"\n"))
                return 1;
        }
    }

    else {
        adr = 0;
        for (int i = 0; i < file->ysize; i++) {
            for (int j = 0; j < linesize; j++) {
                if (0 == fprintf(file->fd, "%d " , file->bitmap[adr]))
                    return 1;
                adr++;
            }
            if (1 != fprintf(file->fd, "\n"))
                return 1;
        }
    }

    return 0;
}

int
pnm_file_write(struct pnm_file *file)
{
    unsigned int linesize;

    fprintf(file->fd, "%s\n", file->header);
    fprintf(file->fd, "# created using pnm.c\n");
    fprintf(file->fd, "%d %d\n", file->xsize, file->ysize);
    if ((file->type != 1) && (file->type != 4))
        fprintf(file->fd, "%d\n" ,file->maxval);

    switch (file->type) {
    case 1:
        linesize = ((file->xsize - 1) / 8) + 1;
        return ___pnm_file_write_ascii(file, linesize);

    case 2:
        linesize = file->xsize;
        return ___pnm_file_write_ascii(file, linesize);

    case 3:
        linesize = 3 * file->xsize;
        return ___pnm_file_write_ascii(file, linesize);

    case 4:
        linesize = ((file->xsize - 1) / 8) + 1;
        return ___pnm_file_write_raw(file, linesize);

    case 5:
        linesize = file->xsize;
        return ___pnm_file_write_raw(file, linesize);

    case 6:
        linesize = file->xsize * 3;
        return ___pnm_file_write_raw(file, linesize);

     default:
        return 1;
    }
}

static inline int
___pnm_file_new(struct pnm_file *file)
{
    unsigned int linesize;

    switch (file->type) {
    case 1:
        linesize = ((file->xsize - 1) / 8) + 1;
        // linesize = file->xsize;
        break;

    case 2:
        linesize = file->xsize;
        break;

    case 3:
        linesize = 3 * file->xsize;
        break;

    case 4:
        linesize = ((file->xsize - 1) / 8) + 1;
        // linesize = file->xsize;
        break;

    case 5:
        linesize = file->xsize;
        break;

    case 6:
        linesize = file->xsize * 3;
        break;

    default:
        return 1;
    }

    file->bitmap = (uint8_t *) malloc(file->ysize * linesize);
    memset(file->bitmap, 0, file->ysize * linesize);
    return (file->bitmap == NULL);
}

struct pnm_file *
pnm_file_new(int X, int Y, const char *name)
{
    struct pnm_file *file = (struct pnm_file *) malloc(sizeof(struct pnm_file));
    if (NULL == file)
        return NULL;

    struct pnm_file ___tmp_file = {
        .name   = name,
        .xsize  = X,
        .ysize  = Y,
        .maxval = 0,
        .fd     = NULL,
        .bitmap = NULL,
    };
    ___pnm_file_new_defaults(&___tmp_file);

    ___tmp_file.fd = fopen(___tmp_file.name, "w+b");
    if (___tmp_file.fd == NULL)
        goto error;
    if (___pnm_file_new(&___tmp_file))
        goto error;

    // if (0 == sprintf(___tmp_file.header, "P%d", ___tmp_file.type))
    //     return NULL;

    *file = ___tmp_file;
    return file;
error:
    if (file)
        free(file);
    return NULL;
}
