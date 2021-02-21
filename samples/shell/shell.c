//
// A very simple command line shell for the P2
// useful for copying files between host and SD card,
// for example.
// Copyright 2021 Total Spectrum Software Inc.
// MIT Licensed, see LICENSE.txt for details.
//
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dirent.h>
#include <ctype.h>
#include <sys/stat.h>
#include <sys/vfs.h>

#ifndef PATH_MAX
#define PATH_MAX 256
#endif

// buffer for holding temporary file names
static char tempname[PATH_MAX];
// ditto for temporary directories
static char tempdir[PATH_MAX];

// utility function: check if a name refers to a directory
// returns 0 if not, 1 if it is
// if an error happens returns 0
int is_directory(const char *filename)
{
    int r;
    struct stat sbuf;
    r = stat(filename, &sbuf);
    if (r) return 0;
    if (S_IFDIR == (sbuf.st_mode & S_IFMT)) {
        return 1;
    }
    return 0;
}

//
// perform a directory listing
//
void do_dir(const char *filename)
{
    DIR *d;
    struct dirent *ent;
    struct stat sbuf;
    int r;
    
    if (!filename || filename[0] == 0) {
        getcwd(tempname, sizeof(tempname));
        filename = tempname;
    }
    if (!is_directory(filename)) {
        printf("ERROR: %s is not a directory\n", filename);
        return;
    }
    if ( 0 == (d = opendir(filename)) ) {
        printf("ERROR: unable to read directory %s\n", filename);
        return;
    }
    getcwd(tempdir, sizeof(tempdir));
    chdir(filename);
    for(;;) {
        ent = readdir(d); // get next directory entry
        if (!ent) break;  // NULL pointer indicates we are done

        // read information about the file associated with this
        // directory information
        r = stat(ent->d_name, &sbuf);
        if (r) {
            // some kind of error happened
            printf("??? error in stat of %s\n", ent->d_name);
        } else if ((sbuf.st_mode & S_IFMT) == S_IFDIR) {
            // this is a directory
            printf("%8s %s\n", "<dir>", ent->d_name);
        } else {
            // not a directory, print the size
            printf("%8u %s\n", sbuf.st_size, ent->d_name);
        }
    }
    // all done, close the directory
    closedir(d);
    chdir(tempdir);
}

//
// perform a copy from file src to file dest
//
void do_copy(const char *src, const char *dest)
{
    const char *basename;
    FILE *inf, *outf;
    int c;
    
    if (is_directory(src)) {
        printf("Cannot copy whole directories yet\n");
        return;
    }
    if (is_directory(dest)) {
        // copy /host/x.bin /sd
        // should be transformed to
        // copy /host/x.bin /sd/x.bin
        basename = strrchr(src, "/");
        if (basename) {
            basename++;
        } else {
            basename = src;
        }
        snprintf(tempname, sizeof(tempname), "%s/%s", dest, basename);
        dest = tempname;
    }
    inf = fopen(src, "rb");
    if (!inf) {
        perror(src);
        return;
    }
    outf = fopen(dest, "wb");
    if (!outf) {
        perror(dest);
        fclose(inf);
        return;
    }
    for(;;) {
        c = fgetc(inf);
        if (c < 0) break;
        fputc(c, outf);
    }
    
    fclose(inf);
    fclose(outf);
}

// show the help text
void do_help(void)
{
    printf("cd            :  show current directory path\n");
    printf("cd <dir>      :  change to directory dir\n");
    printf("copy <s> <d>  :  copy file s to d\n");
    printf("del <f>       :  delete ordinary file <f>\n");
    printf("dir           :  display contents of current directory\n");
    printf("dir <d>       :  display contents of directory d\n");
    printf("exec <f>      :  execute file <f> (never returns)\n");
    printf("help          :  show this help\n");
    printf("mkdir <d>     :  create new directory d\n");
    printf("rmdir <d>     :  remove directory d\n");
}

// parse a command line into the command and up to 2 optional arguments
// returns the command
char *parse_cmd(char *buf, char **arg1, char **arg2)
{
    char *cmd;
    *arg1 = *arg2 = 0;
    while (isspace(*buf)) buf++;
    if (*buf == 0) {
        return 0;
    }
    cmd = buf;
    while (*buf && !isspace(*buf)) {
        buf++;
    }
    if (*buf) {
        *buf++ = 0;
    }
    while (*buf && isspace(*buf)) {
        buf++;
    }
    if (*buf) {
        *arg1 = buf;
        while (*buf && !isspace(*buf)) {
            buf++;
        }
        if (*buf) {
            *buf++ = 0;
        }
    }
    while (*buf && isspace(*buf)) {
        buf++;
    }
    if (*buf) {
        *arg2 = buf;
        while (*buf && *buf != '\n') {
            buf++;
        }
        *buf = 0;
    }
    return cmd;
}
        
// main program
void main()
{
    char cmdbuf[512];
    char *cmd;
    char *arg1, *arg2;
    int r;
    
    // initialize the file systems
    r = mount("/sd", _vfs_open_sdcard());
    if (r == 0) {
        printf("mounted SD card as /sd\n");
    }

    // start off on the host side
    r = mount("/host", _vfs_open_host());
    if (r == 0) {
        printf("mounted host file system as /host\n");
        chdir("/host");
    } else {
        chdir("/sd");
    }

    for(;;) {
        // print prompt
        printf("cmd> ");
        cmd = fgets(cmdbuf, sizeof(cmdbuf), stdin);
        if (!cmd) break;

        cmd = parse_cmd(cmd, &arg1, &arg2);
        if (!cmd) {
            continue;
        }
        if (!strcmp(cmd, "?") || !strcmp(cmd, "help")) {
            do_help();
        } else if (!strcmp(cmd, "cd")) {
            if (!arg1 || !arg1[0]) {
                // just show the current directory
                getcwd(tempdir, sizeof(tempdir));
                printf("%s\n", tempdir);
            } else {
                if (!is_directory(arg1)) {
                    printf("%s is not a directory\n", arg1);
                } else {
                    chdir(arg1);
                }
            }
        } else if (!strcmp(cmd, "copy") || !strcmp(cmd, "cp")) {
            do_copy(arg1, arg2);
        } else if (!strcmp(cmd, "del") || !strcmp(cmd, "rm")) {
            r = unlink(arg1);
            if (r) perror(arg1);
        } else if (!strcmp(cmd, "dir") || !strcmp(cmd, "ls")) {
            do_dir(arg1);
        } else if (!strcmp(cmd, "exec") || !strcmp(cmd, "chain")) {
            _execve(arg1, 0, 0);
            // if we get here something went wrong
            perror(arg1);
        } else if (!strcmp(cmd, "mkdir") || !strcmp(cmd, "md")) {
            r = mkdir(arg1, 0755);
            if (r) perror(arg1);
        } else if (!strcmp(cmd, "rmdir") || !strcmp(cmd, "rd")) {
            r = rmdir(arg1);
            if (r) perror(arg1);
        } else {
            printf("Unknown command: %s\n", cmd);
            do_help();
        }
    }
}
