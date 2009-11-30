#ifndef __GP2XUPPERMEM__
#define __GP2XUPPERMEM__

#include <string.h>

extern void upper_malloc_init(void *pointer);
extern void *gp2x_malloc(size_t size);
extern void *gp2x_calloc(size_t n, size_t size);
extern void *gp2x_realloc(void *ptr, size_t size);
extern void gp2x_free(void *ptr);
extern void *upper_take(int Start, size_t Size);

#endif /* __GP2XUPPERMEM__ */
