#include <png.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_SIZE (16 * 1024 * 1024)
#define WIDTH 480
#define HEIGHT 360

int main()
{
    png_uint_32 width;
    png_uint_32 height;
    int interlace_method;
    int compression_method;
    int filter_method;
    int i;
    int j;
    int k;
    png_bytepp rows;
	png_byte color_type;
	char *buf = (char *)malloc(MAX_SIZE);
	if (!buf) {
		fprintf(stderr, "Couldn't allocate memory\n");
		return 1;
	}
	FILE *fOutputPtr = fopen("data.txt","w");
	
	int prevValues[WIDTH][HEIGHT];
	for (j = 0; j < HEIGHT; j++) {
		for (i = 0; i < WIDTH; i++) {
			prevValues[i][j] = 0;
		}
	}
	for (k = 43; k < 6517; k++) {
		int length = snprintf(NULL, 0, "%d", k);
		char* str = malloc(length + 1);
		snprintf(str, length + 1, "%d", k);
		strcat(str, ".png");
		FILE *fp = fopen(str, "r");
		if (!fp) {
			perror("fopen");
			free(buf);
			return 1;
		}
		png_structp png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
		if (!png_ptr) {
			fprintf(stderr, "!png_ptr\n");
			return 1;
		}
		png_infop info_ptr = png_create_info_struct(png_ptr);
		if (!info_ptr) {
			fprintf(stderr, "!info_ptr\n");
			return 1;
		}
		png_set_palette_to_rgb(png_ptr);
		png_init_io(png_ptr, fp);
		png_read_png(png_ptr, info_ptr, PNG_TRANSFORM_IDENTITY, NULL);
		rows = png_get_rows(png_ptr, info_ptr);
		color_type = png_get_color_type(png_ptr, info_ptr);
		for (j = 0; j < HEIGHT; j++) {
			int printJ = 0;
			int firstInd = -1;
			int changed = 0;
			for (i = 0; i < WIDTH * 3; i += 3) {
				if (prevValues[i/3][j] == 0 && rows[j][i] > 128) {
					prevValues[i/3][j] = 1;
					changed = 1;
				}
				else if (prevValues[i/3][j] == 1 && rows[j][i] < 128) {
					prevValues[i/3][j] = 0;
					changed = 1;
				}
				if (changed) {
					if (firstInd == -1) {
						firstInd = i;
						fprintf(fOutputPtr, "%d,", i/3);
					}
					changed = 0;
					printJ = 1;
				} else {
					if (firstInd != -1) {
						firstInd = -1;
						fprintf(fOutputPtr, "%d,", i/3);
					}
				}
			}
			if (printJ) {
				fprintf(fOutputPtr, "%d;", j);
			}
		}
		fprintf(fOutputPtr, "\n");

		fclose(fp);
  		// Clean up after the read, and free any memory allocated  
  		png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
	  	printf("%d done\n", k);
    }
    fclose(fOutputPtr);
    return 0;
}
