/* loadelf.h - an elf loader for the Parallax Propeller microcontroller

Copyright (c) 2011 David Michael Betz

Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

#ifndef __LOADELF_H__
#define __LOADELF_H__

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

/* base address of cog driver overlays to be loaded into eeprom */
#define COG_DRIVER_IMAGE_BASE   0xc0000000

#define ST_NULL     0
#define ST_PROGBITS 1
#define ST_SYMTAB   2
#define ST_STRTAB   3
#define ST_RELA     4
#define ST_HASH     5
#define ST_DYNAMIC  6
#define ST_NOTE     7
#define ST_NOBITS   8
#define ST_REL      9
#define ST_SHLIB    10
#define ST_DYNSYM   11

#define SF_WRITE    1
#define SF_ALLOC    2
#define SF_EXECUTE  4

#define PT_NULL     0    
#define PT_LOAD     1
    
#define ELFNAMEMAX  128

typedef struct {
    uint8_t     ident[16];
    uint16_t    type;
    uint16_t    machine;
    uint32_t    version;
    uint32_t    entry;
    uint32_t    phoff;
    uint32_t    shoff;
    uint32_t    flags;
    uint16_t    ehsize;
    uint16_t    phentsize;
    uint16_t    phnum;
    uint16_t    shentsize;
    uint16_t    shnum;
    uint16_t    shstrndx;
} ElfHdr;

typedef struct {
    uint32_t    name;
    uint32_t    type;
    uint32_t    flags;
    uint32_t    addr;
    uint32_t    offset;
    uint32_t    size;
    uint32_t    link;
    uint32_t    info;
    uint32_t    addralign;
    uint32_t    entsize;
} ElfSectionHdr;

typedef struct {
    uint32_t    type;
    uint32_t    offset;
    uint32_t    vaddr;
    uint32_t    paddr;
    uint32_t    filesz;
    uint32_t    memsz;
    uint32_t    flags;
    uint32_t    align;
} ElfProgramHdr;

typedef struct {
    uint32_t    name;
    uint32_t    value;
    uint32_t    size;
    uint8_t     info;
    uint8_t     other;
    uint16_t    shndx;
} ElfSymbol;

#define INFO_BIND(i)    ((i) >> 4)
#define INFO_TYPE(i)    ((i) & 0x0f)

#define STB_LOCAL   0
#define STB_GLOBAL  1
#define STB_WEAK    2

typedef struct {
    ElfHdr hdr;
    uint32_t stringOff;
    uint32_t symbolOff;
    uint32_t symbolStringOff;
    uint32_t symbolCnt;
    FILE *fp;
} ElfContext;

#define SectionInProgramSegment(s, p) \
        ((s)->offset >= (p)->offset && (s)->offset < (p)->offset + (p)->filesz \
     &&  (s)->addr   >= (p)->vaddr  && (s)->addr   < (p)->vaddr  + (p)->memsz)

#define ProgramSegmentsMatch(p1, p2) \
        ((p1)->offset == (p2)->offset && (p1)->vaddr == (p2)->vaddr)

int ReadAndCheckElfHdr(FILE *fp, ElfHdr *hdr);
ElfContext *OpenElfFile(FILE *fp, ElfHdr *hdr);
void FreeElfContext(ElfContext *c);
int GetProgramSize(ElfContext *c, uint32_t *pStart, uint32_t *pSize, uint32_t *pCogImagesSize);
int FindSectionTableEntry(ElfContext *c, const char *name, ElfSectionHdr *section);
int FindProgramSegment(ElfContext *c, const char *name, ElfProgramHdr *program);
uint8_t *LoadProgramSegment(ElfContext *c, ElfProgramHdr *program);
int LoadSectionTableEntry(ElfContext *c, int i, ElfSectionHdr *section);
int LoadProgramTableEntry(ElfContext *c, int i, ElfProgramHdr *program);
int FindElfSymbol(ElfContext *c, const char *name, ElfSymbol *symbol);
int LoadElfSymbol(ElfContext *c, int i, char *name, ElfSymbol *symbol);
void ShowElfFile(ElfContext *c);

#ifdef __cplusplus
}
#endif

#endif
