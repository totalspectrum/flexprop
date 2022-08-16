#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <unistd.h>

#undef BUILD_tk
#undef STATIC_BUILD
#include "tk.h"

#ifndef PATH_MAX
#define PATH_MAX 2048
#endif

int P2Debug_Init(Tcl_Interp *interp)
{
    return TCL_OK;
}
