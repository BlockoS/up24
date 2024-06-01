#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>

void bounce(unsigned int h, uint32_t data[256]) {
    int32_t v_max[256];

    int32_t iy0 = 65536;
    int32_t iy = iy0;

    int32_t ground = (float)h * (65536.f / 25.f);

    bool freefall = true;

    int32_t ivmax = -0.05 * sqrt(2.0*0.91*(25.0-h)/25.0) * 65536 * 0.65;
    
    int32_t a = 74; // 65536 * 0.91 * 0.05 * 0.05 / 2.0
    int32_t iv = a;
 
    int i0 = 0;
    int i;

    int bounce = 0;

    for(i=0; i<256; i++) {
        v_max[i] = ivmax;
        ivmax = ivmax * 0.65;
    }

    for(i=0; i<256; i++) {
        if(freefall) {
            iy -= iv;
            if(iy < ground) {
                freefall = false;
                i0 = 4;
            } else {
                iv += 149;
            }
        }
        if(!freefall) {
            --i0;
            if(i0 < 0) {
                iv = v_max[bounce];
                bounce++;
                freefall = true;
            }
            iy = ground;
        }

        data[i] = iy;
    }
}

int main() {
#if 0
    float ground_truth[256] = {0};
    
    float t;
    float tc = 0.f;
    float dt = 0.05f;

    float g = 0.91f;

    float y0 = 1.f;
    float y = y0;
    float ymax = y0;

    float vmax = sqrt(2.f*ymax*g);
    float v0 = vmax;
    float v = 0.f;
    
    float rho = 0.75f;
    float tau = 0.1f;

    bool freefall = true;

    int i;

    for(t=0.f, i=0; (t<10.f) && (ymax > 0.001f) && (i<256); t+=dt, i++) {
        if(freefall) {
            y = y + v*dt - g*dt*dt/2.f;
            if(y < 0) {
                freefall = false;
                tc = t + tau;
            } else {
                v -= g*dt;
            }
        }
        if(freefall == false) {
            if(t >= tc) {
                vmax *= rho;
                v = vmax;
                freefall = true;
            }
            y = 0.f;
        }
        ymax = vmax*vmax / g / 2.f;
        ground_truth[i] = y;
    }
#endif
    char filename[128];

    uint8_t y24[256];
    uint32_t data[256] = {0};

    for(int i=0; i<256; i++) {
        y24[i] = (255-i) * 25.f / 255.f;
    }

    for(int k=0; k<3; k++) {
        bounce(8*k, data);
        {
            FILE *stream;
            snprintf(filename, 256, "bounce%d.dat", k);
            stream = fopen(filename, "w");
            for(int i=0; i<256; i++) {
                uint32_t t = data[i] >> 8;
                if(t > 255) {
                    t = 255;
                }
                fprintf(stream, "%d\n", y24[t]);
            }
            fprintf(stream, "\n");
            fclose(stream);
        }

        {
            FILE *stream;
            snprintf(filename, 256, "bounce%d.bin", k);
            uint8_t out[256];
            for(int i=0; i<256; i++) {
                uint32_t t = data[i] >> 8;
                if(t > 255) {
                    t = 255;
                }
                out[i] = y24[t];
            }
            stream = fopen(filename, "wb");
            fwrite(out, 1, sizeof(out), stream);
            fclose(stream);
        }
    }
    return EXIT_SUCCESS;
}