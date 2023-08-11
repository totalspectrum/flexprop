//
// A very simple command line shell for the P2
// useful for copying files between host and SD card,
// for example.
// Copyright 2021-2023 Total Spectrum Software Inc.
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

// block device for ramdisk (modify as needed)

// size of RAM disk
//#define RAMDISK_SIZE (64*1024)  // for HUB
#define RAMDISK_SIZE (8*1024*1024)

#pragma exportdef RAMDISK_SIZE

// base pin to use for RAMDISK
// use 40 for built in memory on P2-EC32MB Edge board 
#define RAM_BASEPIN 40

// driver to use for RAM disk
// select one of the following

#if 0
struct __using("spin/hubram.spin2") xmem; // plain HUB memory; adjust RAM_SIZE!
#elif 0
// P2 HyperRam add-on card
struct __using("spin/hyperram.spin2", BASEPIN = RAM_BASEPIN) xmem;
#elif 0

// 4 bit wide PSRAM
#define PSRAM_DRIVER "psram4drv-dualCE" // for Ray's Logic 24 MB board
#pragma exportdef PSRAM_DRIVER

struct __using("spin/psram.spin2", DATABUS = RAM_BASEPIN, CLK_PIN = RAM_BASEPIN+4, CE_PIN = RAM_BASEPIN+5) xmem;

#else
// 16 bit wide PSRAM
#define PSRAM_DRIVER "psram16drv" // for P2-EC32MB Edge board
#pragma exportdef PSRAM_DRIVER

struct __using("spin/psram.spin2", DATABUS = RAM_BASEPIN, CLK_PIN = RAM_BASEPIN+16, CE_PIN = RAM_BASEPIN + 17) xmem;

#endif

// good default size for littlefs
#define RAM_PAGE_SIZE 256

static int xmem_blkread(void *hubdata, unsigned long exaddr, unsigned long count) {
    xmem.read(hubdata, exaddr, RAM_PAGE_SIZE);
#ifdef _DEBUG_LFS
    const char *ptr = hubdata;
    __builtin_printf("blkread: exaddr=%x data=[%x %x %x %x ...]\n",
                     exaddr, ptr[0], ptr[1], ptr[2], ptr[3]);
#endif    
    return 0;
}

static int xmem_blkerase(unsigned long exaddr) {
#ifdef _DEBUG_LFS
    __builtin_printf("blkerase: exaddr=%x\n", exaddr);
#endif    
    xmem.fill(exaddr, 0xff, RAM_PAGE_SIZE);
    return 0;
}

static int xmem_blkwrite(void *hubsrc, unsigned long exaddr) {
#ifdef _DEBUG_LFS
    const char *ptr = hubsrc;
    __builtin_printf("blkwrite: exaddr=%x data=[%x %x %x %x ...]\n",
                     exaddr, ptr[0], ptr[1], ptr[2], ptr[3]);
#endif    
    xmem.write(hubsrc, exaddr, RAM_PAGE_SIZE);
    return 0;
}

_BlockDevice *initRamDevice() {
    static _BlockDevice dev;
    static char read_buffer[RAM_PAGE_SIZE];
    static char write_buffer[RAM_PAGE_SIZE];
    static char lookahead_buffer[RAM_PAGE_SIZE];
    
#ifdef _DEBUG_LFS
    __builtin_printf("initRamDevice\n");
#endif    
    xmem.start();
    dev.blk_read = &xmem_blkread;
    dev.blk_write = &xmem_blkwrite;
    dev.blk_erase = &xmem_blkerase;
    dev.blk_sync = (void *)&xmem.sync;

    dev.read_cache = read_buffer;
    dev.write_cache = write_buffer;
    dev.lookahead_cache = lookahead_buffer;

    return &dev;
}

// config for little fs

// flash config
struct littlefs_flash_config flash_config = {
    256,       /* page size */
    65536,     /* erase size */
    2*1024*1024, /* start offset */
    6*1024*1024, /* used size */
    NULL,      /* driver (NULL for default) */
    0LL,       /* default pin mask */
    0,         /* reserved */
};

// HUB ramdisk config
struct littlefs_flash_config ram_config = {
    RAM_PAGE_SIZE,       /* page size */
    RAM_PAGE_SIZE,       /* erase size */
    0,         /* start offset */
    RAMDISK_SIZE,  /* used size */
    NULL,      /* driver (NULL for default) */
    15ULL<<RAM_BASEPIN,  /* pin mask */
    0,         /* reserved */
};

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
        perror(filename);
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
    int count = 0;
    
    if (is_directory(src)) {
        printf("Cannot copy whole directories yet\n");
        return;
    }
    if (dest && is_directory(dest)) {
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
    if (dest) {
        outf = fopen(dest, "wb");
        if (!outf) {
            perror(dest);
            fclose(inf);
            return;
        }
    } else {
        outf = stdout;
    }
    for(;;) {
        c = fgetc(inf);
        if (c < 0) break;
        fputc(c, outf);
        count++;
    }
    
    fclose(inf);
    if (dest) {
        fclose(outf);
        printf("copied %d bytes\n", count);
    }
}

// format FLASH
void do_mkfs(const char *dirname)
{
    int r = 0;
    if ( strcmp(dirname, "/flash") == 0 ) {
        r = _mkfs_littlefs_flash(0);
    } else {
        printf("Unknown mount point %s\n", dirname);
    }
    if (r != 0) {
        printf("ERROR: got error %d during mount\n", r);
        perror(dirname);
    }
}
// mount SD or FLASH
void do_mount(const char *dirname)
{
    int r = 0;
    if ( strcmp(dirname, "/sd") == 0 ) {
        r = mount(dirname, _vfs_open_sdcard());
    } else if ( strcmp(dirname, "/flash") == 0 ) {
        r = mount(dirname, _vfs_open_littlefs_flash(1, &flash_config));
    } else if ( strcmp(dirname, "/ram") == 0 ) {
        ram_config.dev = initRamDevice();
        r = mount(dirname, _vfs_open_littlefs_flash(1, &ram_config));
    } else {
        printf("Unknown mount point %s\n", dirname);
    }
    if (r != 0) {
        printf("ERROR: got error %d during mount\n", r);
    }
}

// unmount SD
void do_umount(const char *dirname)
{
    int r;
    r = _umount(dirname);
    if (r != 0) {
        printf("ERROR: got error %d during un-mount of %s\n", r, dirname);
    }
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
    printf("type <f>      :  type file on console\n");
    printf("mount  <d>    :  mount SD card (/sd) or LFS flash (/flash)\n");
    printf("umount <d>    :  unmount SD card (/sd) or LFS flash (/flash)\n");
    printf("mkfs /flash   :  format flash with little fs\n");
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
#if 0    
    r = mount("/sd", _vfs_open_sdcard());
    if (r == 0) {
        printf("mounted SD card as /sd\n");
    }
#endif
    // start off on the host side
    r = mount("/host", _vfs_open_host());
    if (r == 0) {
        printf("mounted host file system as /host\n");
        chdir("/host");
    } else {
        chdir("/");
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
        } else if (!strcmp(cmd, "type") || !strcmp(cmd, "cat")) {
            do_copy(arg1, NULL);  // print to stdout
        } else if (!strcmp(cmd, "mkfs")) {
            do_mkfs(arg1);       // format flash
        } else if (!strcmp(cmd, "mount")) {
            do_mount(arg1);      // mount drive/flash
        } else if (!strcmp(cmd, "umount") || !strcmp(cmd, "unmount")) {
            do_umount(arg1);  // unmount drive/flash
        } else {
            printf("Unknown command: %s\n", cmd);
            do_help();
        }
    }
}
