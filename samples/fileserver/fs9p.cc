//
// simple test program for 9p access to host files
//

#include <string.h>
#include <stdint.h>
#include "fs9p.h"

int maxlen = MAXLEN;
static uint8_t txbuf[MAXLEN];

// command to put 1 byte in the host buffer
static uint8_t *doPut1(uint8_t *ptr, unsigned x) {
    *ptr++ = x;
    return ptr;
}

// send a 16 bit integer to the host
static uint8_t *doPut2(uint8_t *ptr, unsigned x) {
    ptr = doPut1(ptr, x & 0xff);
    ptr = doPut1(ptr, (x>>8) & 0xff);
    return ptr;
}
// send a 32 bit integer to the host
static uint8_t *doPut4(uint8_t *ptr, unsigned x) {
    ptr = doPut1(ptr, x & 0xff);
    ptr = doPut1(ptr, (x>>8) & 0xff);
    ptr = doPut1(ptr, (x>>16) & 0xff);
    ptr = doPut1(ptr, (x>>24) & 0xff);
    return ptr;
}

static uint8_t *doPutStr(uint8_t *ptr, const char *s) {
    unsigned L = strlen(s);
    unsigned i = 0;
    ptr = doPut2(ptr, L);
    for (i = 0; i < L; i++) {
        *ptr++ = *s++;
    }
    return ptr;
}

static unsigned FETCH2(uint8_t *b)
{
    unsigned r;
    r = b[0];
    r |= (b[1]<<8);
    return r;
}
static unsigned FETCH4(uint8_t *b)
{
    unsigned r;
    r = b[0];
    r |= (b[1]<<8);
    r |= (b[2]<<16);
    r |= (b[3]<<24);
    return r;
}

// root directory for connection
// set up by fs_init
fs_file rootdir;
sendrecv_func sendRecv;

// initialize connection to host
// returns 0 on success, -1 on failure
// "fn" is the function to send a 9P protocol request to
// the host and read back a reply
int fs_init(sendrecv_func fn)
{
    uint8_t *ptr;
    uint32_t size;
    int len;
    unsigned msize;
    unsigned s;
    unsigned tag;

    sendRecv = fn;
    ptr = doPut4(txbuf, 0);
    ptr = doPut1(ptr, t_version);
    ptr = doPut2(ptr, NOTAG);
    ptr = doPut4(ptr, MAXLEN);
    ptr = doPutStr(ptr, "9P2000");
    len = (*fn)(txbuf, ptr, MAXLEN);

    ptr = txbuf+4;

    if (ptr[0] != r_version) {
        return -1;
    }
    
    tag = FETCH2(ptr+1);
    msize = FETCH4(ptr+3);

    s = FETCH2(ptr+7);
    if (s != 6 || 0 != strncmp(&ptr[9], "9P2000", 6)) {
        //ser.printf("Bad version response from host: s=%d ver=%s\n", s, &ptr[9]);
        return -1;
    }
    if (msize < 64 || msize > MAXLEN) {
        //ser.printf("max message size %u is out of range\n", msize);
        return -1;
    }
    maxlen = msize;

    // OK, try to attach
    ptr = doPut4(txbuf, 0);  // space for size
    ptr = doPut1(ptr, t_attach);
    ptr = doPut2(ptr, NOTAG);  // not sure about this one...
    ptr = doPut4(ptr, (uint32_t)&rootdir); // our FID
    ptr = doPut4(ptr, NOFID); // no authorization requested
    ptr = doPutStr(ptr, "user");
    ptr = doPutStr(ptr, ""); // no aname

    len = (*sendRecv)(txbuf, ptr, maxlen);
    
    ptr = txbuf+4;
    if (ptr[0] != r_attach) {
        //ser.printf("Unable to attach\n");
        return -1;
    }
    return 0;
}

fs_file *fs_getroot()
{
    return &rootdir;
}

// walk from fid "dir" along path, creating fid "newfile"
// if "skipLast" is nonzero, then do not try to walk the last element
// (needed for create or other operations where the file may not exist)
static int do_fs_walk(fs_file *dir, fs_file *newfile, const char *path, int skipLast)
{
    uint8_t *ptr;
    uint8_t *sizeptr;
    int c;
    uint32_t curdir = (uint32_t) dir;
    int len;
    int r;
    int sentone = 0;
    
    do {
        ptr = doPut4(txbuf, 0); // space for size
        ptr = doPut1(ptr, t_walk);
        ptr = doPut2(ptr, NOTAG);
        ptr = doPut4(ptr, curdir);
        curdir = (uint32_t)newfile;
        ptr = doPut4(ptr, curdir);
        while (*path == '/') path++;
        len = ptr - txbuf;
        if (*path) {
            ptr = doPut2(ptr, 1); // nwname
            sizeptr = ptr;
            ptr = doPut2(ptr, 0);
            while (*path && *path != '/' && len < maxlen) {
                *ptr++ = *path++;
                len++;
            }
	    if (skipLast && !*path) {
	      if (sentone) {
		return 0;
	      } else {
		doPut2(sizeptr, 1);
		ptr = sizeptr+2;
		ptr = doPut1(ptr, '.');
	      }
	    } else {
	      doPut2(sizeptr, (uint32_t)(ptr - (sizeptr+2)));
	    }
        } else {
            ptr = doPut2(ptr, 0);
        }

        r = (*sendRecv)(txbuf, ptr, maxlen);
	sentone = 1;
        if (txbuf[4] != r_walk) {
            return -1;
        }
    } while (*path);
    return 0;
}

int fs_walk(fs_file *dir, fs_file *newfile, const char *path)
{
    return do_fs_walk(dir, newfile, path, 0);
}

int fs_open_relative(fs_file *dir, fs_file *f, const char *path, int fs_mode)
{
    int r;
    uint8_t *ptr;
    uint8_t mode = fs_mode;

    r = fs_walk(dir, f, path);
    if (r != 0) return r;
    ptr = doPut4(txbuf, 0); // space for size
    ptr = doPut1(ptr, t_open);
    ptr = doPut2(ptr, NOTAG);
    ptr = doPut4(ptr, (uint32_t)f);
    ptr = doPut1(ptr, mode);
    r = (*sendRecv)(txbuf, ptr, maxlen);
    if (txbuf[4] != r_open) {
        return -1;
    }
    f->offlo = f->offhi = 0;
    return 0;
}

int fs_open(fs_file *f, const char *path, int fs_mode)
{
    return fs_open_relative(&rootdir, f, path, fs_mode);
}

int fs_create(fs_file *f, const char *path)
{
    int r;
    fs_file dir;
    uint8_t *ptr;
    uint32_t permissions = 0666; // rw for all
    const char *lastname;
    
    // first, walk to the directory containing our target file
    r = do_fs_walk(&rootdir, f, path, 1);
    if (r < 0) {
        // directory not found
        return -2;
    }
    lastname = strrchr(path, '/');
    if (!lastname) {
        lastname = path;
    } else {
        lastname++;
    }
    // try to create the file
    ptr = doPut4(txbuf, 0); // space for size
    ptr = doPut1(ptr, t_create);
    ptr = doPut2(ptr, NOTAG);
    ptr = doPut4(ptr, (uint32_t)f);
    ptr = doPutStr(ptr, lastname);
    ptr = doPut4(ptr, permissions);
    ptr = doPut1(ptr, FS_MODE_TRUNC | FS_MODE_WRITE);
    r = (*sendRecv)(txbuf, ptr, maxlen);
    if (r >= 0 && txbuf[4] == r_create) {
      return r;
    }
    
    // can we open the file with truncation set?
    r = fs_open_relative(f, f, lastname, FS_MODE_TRUNC | FS_MODE_WRITE);
    if (r < 0) {
        return r;
    }
    return 0;
}

int fs_close(fs_file *f)
{
    uint8_t *ptr;
    int r;
    ptr = doPut4(txbuf, 0); // space for size
    ptr = doPut1(ptr, t_clunk);
    ptr = doPut2(ptr, NOTAG);
    ptr = doPut4(ptr, (uint32_t)f);
    r = (*sendRecv)(txbuf, ptr, maxlen);
    if (r < 0 || txbuf[4] != r_clunk) {
        return -1;
    }
    return 0;
}

int fs_read(fs_file *f, uint8_t *buf, int count)
{
    uint8_t *ptr;
    int totalread = 0;
    int curcount;
    int r;
    int left;
    uint32_t oldlo;
    while (count > 0) {
        ptr = doPut4(txbuf, 0); // space for size
        ptr = doPut1(ptr, t_read);
        ptr = doPut2(ptr, NOTAG);
        ptr = doPut4(ptr, (uint32_t)f);
        ptr = doPut4(ptr, f->offlo);
        ptr = doPut4(ptr, f->offhi);
        left = maxlen - (ptr + 4 - txbuf);
        if (count < left) {
            curcount = count;
        } else {
            curcount = left;
        }
        ptr = doPut4(ptr, curcount);
        r = (*sendRecv)(txbuf, ptr, maxlen);
        if (r < 0) return r;
        ptr = txbuf + 4;
        if (*ptr++ != r_read) {
            return -1;
        }
        ptr += 2; // skip tag
        r = FETCH4(ptr); ptr += 4;
        if (r < 0 || r > curcount) {
            return -1;
        }
        if (r == 0) {
            // EOF reached
            break;
        }
        memcpy(buf, ptr, r);
        buf += r;
        totalread += r;
        count -= r;
        oldlo = f->offlo;
        f->offlo = oldlo + r;
        if (f->offlo < oldlo) {
            f->offhi++;
        }
    }
    return totalread;
}

int fs_write(fs_file *f, const uint8_t *buf, int count)
{
    uint8_t *ptr;
    int totalread = 0;
    int curcount;
    int r;
    int left;
    uint32_t oldlo;
    while (count > 0) {
        ptr = doPut4(txbuf, 0); // space for size
        ptr = doPut1(ptr, t_write);
        ptr = doPut2(ptr, NOTAG);
        ptr = doPut4(ptr, (uint32_t)f);
        ptr = doPut4(ptr, f->offlo);
        ptr = doPut4(ptr, f->offhi);
        left = maxlen - (ptr + 4 - txbuf);
        if (count < left) {
            curcount = count;
        } else {
            curcount = left;
        }
        ptr = doPut4(ptr, curcount);
        // now copy in the data
        memcpy(ptr, buf, curcount);
        r = (*sendRecv)(txbuf, ptr+curcount, maxlen);
        if (r < 0) return r;
        ptr = txbuf + 4;
        if (*ptr++ != r_write) {
            return -1;
        }
        ptr += 2; // skip tag
        r = FETCH4(ptr); ptr += 4;
        if (r < 0 || r > curcount) {
            return -1;
        }
        if (r == 0) {
            // EOF reached
            break;
        }
        buf += r;
        totalread += r;
        count -= r;
        oldlo = f->offlo;
        f->offlo = oldlo + r;
        if (f->offlo < oldlo) {
            f->offhi++;
        }
    }
    return totalread;
}
