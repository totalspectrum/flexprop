/*
 * tkAppInit.c --
 *
 *	Provides a default version of the main program and Tcl_AppInit
 *	procedure for wish and other Tk-based applications.
 *
 * Copyright (c) 1993 The Regents of the University of California.
 * Copyright (c) 1994-1997 Sun Microsystems, Inc.
 * Copyright (c) 1998-1999 Scriptics Corporation.
 *
 * See the file "license.terms" for information on usage and redistribution of
 * this file, and for a DISCLAIMER OF ALL WARRANTIES.
 */

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

#ifdef TK_TEST
extern Tcl_PackageInitProc Tktest_Init;
#endif /* TK_TEST */

/* define the system-wide LSN dir for install */
#ifndef LSN_DIR
#define LSN_DIR "/usr/share/flexprop"
#endif

/*
 * The following #if block allows you to change the AppInit function by using
 * a #define of TCL_LOCAL_APPINIT instead of rewriting this entire file. The
 * #if checks for that #define and uses Tcl_AppInit if it doesn't exist.
 */

#ifndef TK_LOCAL_APPINIT
#define TK_LOCAL_APPINIT Tcl_AppInit
#endif
#ifndef MODULE_SCOPE
#   define MODULE_SCOPE extern
#endif
MODULE_SCOPE int TK_LOCAL_APPINIT(Tcl_Interp *);
MODULE_SCOPE int main(int, char **);

/*
 * The following #if block allows you to change how Tcl finds the startup
 * script, prime the library or encoding paths, fiddle with the argv, etc.,
 * without needing to rewrite Tk_Main()
 */
#define TK_LOCAL_MAIN_HOOK fixup_argv

#ifdef TK_LOCAL_MAIN_HOOK
MODULE_SCOPE int TK_LOCAL_MAIN_HOOK(int *argc, char ***argv);
#endif

/* Make sure the stubbed variants of those are never used. */
#undef Tcl_ObjSetVar2
#undef Tcl_NewStringObj

/*
 *----------------------------------------------------------------------
 *
 * main --
 *
 *	This is the main program for the application.
 *
 * Results:
 *	None: Tk_Main never returns here, so this procedure never returns
 *	either.
 *
 * Side effects:
 *	Just about anything, since from here we call arbitrary Tcl code.
 *
 *----------------------------------------------------------------------
 */

int
main(
    int argc,			/* Number of command-line arguments. */
    char **argv)		/* Values of command-line arguments. */
{
#ifdef TK_LOCAL_MAIN_HOOK
    TK_LOCAL_MAIN_HOOK(&argc, &argv);
#elif (TCL_MAJOR_VERSION > 8) || (TCL_MINOR_VERSION > 6)
    /* This doesn't work with Tcl 8.6 */
    TclZipfs_AppHook(&argc, &argv);
#endif

    Tk_Main(argc, argv, TK_LOCAL_APPINIT);
    return 0;			/* Needed only to prevent compiler warning. */
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_AppInit --
 *
 *	This procedure performs application-specific initialization. Most
 *	applications, especially those that incorporate additional packages,
 *	will have their own version of this procedure.
 *
 * Results:
 *	Returns a standard Tcl completion code, and leaves an error message in
 *	the interp's result if an error occurs.
 *
 * Side effects:
 *	Depends on the startup script.
 *
 *----------------------------------------------------------------------
 */

int
Tcl_AppInit(
    Tcl_Interp *interp)		/* Interpreter for application. */
{
    if ((Tcl_Init)(interp) == TCL_ERROR) {
	return TCL_ERROR;
    }

    if (Tk_Init(interp) == TCL_ERROR) {
	return TCL_ERROR;
    }
    Tcl_StaticPackage(interp, "Tk", Tk_Init, Tk_SafeInit);

#ifdef TK_TEST
    if (Tktest_Init(interp) == TCL_ERROR) {
	return TCL_ERROR;
    }
    Tcl_StaticPackage(interp, "Tktest", Tktest_Init, 0);
#endif /* TK_TEST */

    /*
     * Call the init procedures for included packages. Each call should look
     * like this:
     *
     * if (Mod_Init(interp) == TCL_ERROR) {
     *     return TCL_ERROR;
     * }
     *
     * where "Mod" is the name of the module. (Dynamically-loadable packages
     * should have the same entry-point name.)
     */

    /*
     * Call Tcl_CreateObjCommand for application-specific commands, if they
     * weren't already created by the init procedures called above.
     */

    /*
     * Specify a user-specific startup file to invoke if the application is
     * run interactively. Typically the startup file is "~/.apprc" where "app"
     * is the name of the application. If this line is deleted then no user-
     * specific startup file will be run under any conditions.
     */

    Tcl_ObjSetVar2(interp, Tcl_NewStringObj("tcl_rcFileName", -1), NULL,
	    Tcl_NewStringObj("~/.wishrc", -1), TCL_GLOBAL_ONLY);
    return TCL_OK;
}

static void
MyRemoveFileSpec(char *orig_ptr)
{
    char *ptr = orig_ptr;
    if (!*ptr) {
        return;
    }
    // convert backslash to forward slash
    while (ptr[1] != 0) {
        if (*ptr == '\\') *ptr = '/';
        ptr++;
    }
    while (*ptr != '/' && ptr > orig_ptr) {
        --ptr;
    }
    if (ptr != orig_ptr) {
        ptr[0] = 0;
    }
}

static char *
dyn_strcat(char *base, char *suffix)
{
    char *r;

    r = malloc(sizeof(char) * (strlen(base) + strlen(suffix) + 2));
    strcpy(r, base);
    strcat(r, suffix);
    return r;
}

static int 
getProgramPath(char **argv, char *path, int size)
{
#if defined(WIN32)

    /* get the full path to the executable */
    if (!GetModuleFileNameA(NULL, path, size))
        return -1;

#elif defined(__linux__)
    int r;
    r = readlink("/proc/self/exe", path, size - 1);
    if (r >= 0)
      path[r] = 0;
    else
      return -1;
    
    char *src_dir = dyn_strcat(path, "/src");
    char *lsn_dir = dyn_strcat(LSN_DIR, "/src");

    if (access(src_dir, F_OK) != 0) {
        if (access(lsn_dir, F_OK) == 0) {
            if (strlen(LSN_DIR) >= size)
                return -1;
            strncpy(path, LSN_DIR, size);
        } else {
            return -1;
        }
    }

#elif defined(__OSX__)
    uint32_t bufsize = size - 1;
    int r = _NSGetExecutablePath(path, &bufsize);
    if (r < 0)
      return -1;
#else
    /* fall back on argv[0]... probably not the best bet, since
       shells might not put the full path in, but it's the most portable
    */
    strcpy(path, argv[0]);
#endif

    return 0;
}

#define MY_MAXPATH (2*PATH_MAX)

int fixup_argv(int *argc, char ***argv)
{
    unsigned int r;
    int i;
    static char namebuffer[MY_MAXPATH];
    static int my_argc;
    char **my_argv;

    // get where the flexprop.exe executable is
    r = getProgramPath(*argv, namebuffer, PATH_MAX);

    if (r != 0) {
        // something went wrong... fail
        strcpy(namebuffer, ".");
    } else {
        MyRemoveFileSpec(namebuffer);
    }
    //_tprintf(_T("fixup_argv: revised namebuffer=%s\n"), namebuffer);
    
    my_argc = *argc + 1;
    //_tprintf(_T("allocating my_argv (%d)\n"), my_argc);
    my_argv = malloc( (my_argc+2) * sizeof(char *) );
    my_argv[0] = (*argv)[0];
    //_tprintf(_T("copying my_argv[1]\n"));
    my_argv[1] =  dyn_strcat(namebuffer, "/src/flexprop.tcl");
    //_tprintf(_T("copying remaining argv\n"));
    for (i = 2; i <= my_argc; i++) {
        my_argv[i] = (*argv)[i-1];
    }
    //_tprintf(_T("terminating argv\n"));
    my_argv[i] = NULL;

#ifdef NEVER
    printf("argv values=\n");

    for (int j = 0; j < i; j++) {
        printf("argv[%d] = %s\n", j, my_argv[j]);
    }
#endif    
    *argc = my_argc;
    *argv = my_argv;

#ifndef __linux__
    // for Linux, just use the system libraries
    putenv(dyn_strcat("TCL_LIBRARY=", dyn_strcat(namebuffer, "/tcl_library/tcl8.6")));
    putenv(dyn_strcat("TK_LIBRARY=", dyn_strcat(namebuffer, "/tcl_library/tk8.6")));
#endif    
    return 0;
}      

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
