#ifndef GP2X_WRAPPER
#define GP2X_WRAPPER

#define malloc(size) malloc(size)
#define calloc(n,size) calloc(n,size)
#define realloc(ptr,size) realloc(ptr,size)
#define free(size) free(size)

#define printf gp2x_printf

#if defined(__cplusplus)
extern "C" {
#endif
extern void gp2x_printf(char* fmt, ...);
#if defined(__cplusplus)
}
#endif

#endif
