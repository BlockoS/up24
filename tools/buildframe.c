#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>

#define SCREEN_WIDTH 40U
#define SCREEN_HEIGHT 25U

typedef struct {
    size_t size;
    size_t capacity;
    unsigned char *data;
} buffer_t;

int read_file(const char *filename, buffer_t *buffer) {
    int ret = 0;
    FILE *in = fopen(filename, "rb");
    if(in == NULL) {
        fprintf(stderr, "failed to open %s: %s\n", filename, strerror(errno));
    } else {
        struct stat in_stat = {0};
        int fd = fileno(in);

        if(fstat(fd, &in_stat) < 0) {
            fprintf(stderr, "failed to retrieve file info for %s: %s\n", filename, strerror(errno));  
        } else {
            buffer->size = in_stat.st_size;
            if((buffer->size > buffer->capacity) || (buffer->data == NULL)) {
                buffer->data = (unsigned char*)realloc(buffer->data, buffer->size);
                buffer->capacity = buffer->size;
            }
            if(fread(buffer->data, 1, buffer->size, in) != buffer->size) {
                fprintf(stderr, "failed to read %ld from %s: %s\n", buffer->size, filename, strerror(errno));
            } else {
                ret = 1;
            }
        }
        fclose(in);
    }
    return ret;
}

int main(int argc, char **argv) {
    if(argc != 4) {
        fprintf(stderr, "Usage: build_frame char_data color_dada output\n");
        return EXIT_FAILURE;
    }

    buffer_t char_vram = { 0, 0, NULL };
    buffer_t color_vram = { 0, 0, NULL };

    FILE *out = fopen(argv[3], "wb");
    if(out == NULL) {
        fprintf(stderr, "failed to open %s: %s\n", argv[3], strerror(errno));
        return EXIT_FAILURE;
    }

    int ret = EXIT_FAILURE;

    if(!read_file(argv[1], &char_vram)) {
        // ...
    } else if(!read_file(argv[2], &color_vram)) {
        // ...
    } else if((char_vram.size != color_vram.size) && (char_vram.size != (SCREEN_WIDTH * SCREEN_HEIGHT))) {
        fprintf(stderr, "invalid buffer size\n");
    } else {
        for(size_t j=0; j<SCREEN_HEIGHT; j++) {
            fwrite(&char_vram.data[j*SCREEN_WIDTH], 1, SCREEN_WIDTH, out);
            fwrite(&color_vram.data[j*SCREEN_WIDTH], 1, SCREEN_WIDTH, out);
        }
        ret = EXIT_SUCCESS;
    }

    if(out) {
        fclose(out);
    }
    free(char_vram.data);
    free(color_vram.data);
    return ret;
}