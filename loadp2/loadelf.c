/* loadelf.c - an elf loader for the Parallax Propeller microcontroller

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

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "loadelf.h"

#define message printf

#ifndef TRUE
#define TRUE    1
#define FALSE   0
#endif

#define IDENT_SIGNIFICANT_BYTES 9

static uint8_t ident[] = {
    0x7f, 'E', 'L', 'F',                        // magic number
    0x01,                                       // class
    0x01,                                       // data
    0x01,                                       // version
    0x00,                                       // os / abi identification
    0x00,                                       // abi version
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00    // padding
};

static int FindProgramTableEntry(ElfContext *c, ElfSectionHdr *section, ElfProgramHdr *program);
static void ShowSectionHdr(ElfSectionHdr *section);
static void ShowProgramHdr(ElfProgramHdr *program);

int ReadAndCheckElfHdr(FILE *fp, ElfHdr *hdr)
{
    if (fread(hdr, 1, sizeof(ElfHdr), fp) != sizeof(ElfHdr))
        return FALSE;
    return memcmp(ident, hdr->ident, IDENT_SIGNIFICANT_BYTES) == 0;
}

ElfContext *OpenElfFile(FILE *fp, ElfHdr *hdr)
{
    ElfSectionHdr section;
    ElfContext *c;
    
    /* allocate and initialize a context structure */
    if (!(c = (ElfContext *)malloc(sizeof(ElfContext))))
        return NULL;
    memset(c, 0, sizeof(ElfContext));
    c->hdr = *hdr;
    c->fp = fp;
        
    /* get the string section offset */
    if (!LoadSectionTableEntry(c, c->hdr.shstrndx, &section)) {
        free(c);
        return NULL;
    }
    c->stringOff = section.offset;
    
    /* get the symbol table section offset */
    if (FindSectionTableEntry(c, ".symtab", &section)) {
        c->symbolOff = section.offset;
        c->symbolCnt = section.size / sizeof(ElfSymbol);
        if (FindSectionTableEntry(c, ".strtab", &section))
            c->symbolStringOff = section.offset;
        else {
            c->symbolOff = 0;
            c->symbolCnt = 0;
        }
    }
    
    /* return the context */
    return c;
}

void FreeElfContext(ElfContext *c)
{
    free(c);
}

void CloseElfFile(ElfContext *c)
{
    if (c->fp) {
        fclose(c->fp);
        c->fp = 0;
    }
}

int GetProgramSize(ElfContext *c, uint32_t *pStart, uint32_t *pSize, uint32_t *pCogImagesSize)
{
    ElfProgramHdr program;
    uint32_t start = 0xffffffff;
    uint32_t end = 0;
    uint32_t cogImagesStart = 0xffffffff;
    uint32_t cogImagesEnd = 0;
    int cogImagesFound = FALSE;
    int i;
    for (i = 0; i < c->hdr.phnum; ++i) {
        if (!LoadProgramTableEntry(c, i, &program)) {
            message("Can't read ELF program header %d", i);
            return FALSE;
        }
        if (program.paddr < COG_DRIVER_IMAGE_BASE) {
            if (program.paddr < start)
                start = program.paddr;
            if (program.paddr + program.filesz > end)
                end = program.paddr + program.filesz;
        }
        else {
            if (program.paddr < cogImagesStart)
                cogImagesStart = program.paddr;
            if (program.paddr + program.filesz > cogImagesEnd)
                cogImagesEnd = program.paddr + program.filesz;
            cogImagesFound = TRUE;
        }
    }
    *pStart = start;
    *pSize = end - start;
    *pCogImagesSize = cogImagesFound ? cogImagesEnd - cogImagesStart : 0;
    return TRUE;
}

int FindProgramSegment(ElfContext *c, const char *name, ElfProgramHdr *program)
{
    ElfSectionHdr section;
    if (!FindSectionTableEntry(c, name, &section))
        return -1;
    return FindProgramTableEntry(c, &section, program);
}

uint8_t *LoadProgramSegment(ElfContext *c, ElfProgramHdr *program)
{
    uint8_t *buf;
    if (!(buf = (uint8_t *)malloc(program->filesz)))
        return NULL;
    if (fseek(c->fp, program->offset, SEEK_SET) != 0) {
        free(buf);
        return NULL;
    }
    if (fread(buf, 1, program->filesz, c->fp) != program->filesz) {
        free(buf);
        return NULL;
    }
    return buf;
}

int FindSectionTableEntry(ElfContext *c, const char *name, ElfSectionHdr *section)
{
    int i;
    for (i = 0; i < c->hdr.shnum; ++i) {
        char thisName[ELFNAMEMAX], *p = thisName;
        int cnt, ch;
        if (!LoadSectionTableEntry(c, i, section)) {
            message("Can't read ELF section header %d", i);
            return 1;
        }
        fseek(c->fp, c->stringOff + section->name, SEEK_SET);
        for (cnt = 0; ++cnt < ELFNAMEMAX && (ch = getc(c->fp)) != '\0'; )
            *p++ = ch;
        *p = '\0';
        if (strcmp(name, thisName) == 0)
            return TRUE;
    }
    return FALSE;
}

int LoadSectionTableEntry(ElfContext *c, int i, ElfSectionHdr *section)
{
    return fseek(c->fp, c->hdr.shoff + i * c->hdr.shentsize, SEEK_SET) == 0
        && fread(section, 1, sizeof(ElfSectionHdr), c->fp) == sizeof(ElfSectionHdr);
}

static int FindProgramTableEntry(ElfContext *c, ElfSectionHdr *section, ElfProgramHdr *program)
{
    int i;
    for (i = 0; i < c->hdr.shnum; ++i) {
        if (!LoadProgramTableEntry(c, i, program)) {
            message("Can't read ELF program header %d", i);
            return -1;
        }
        if (SectionInProgramSegment(section, program))
            return i;
    }
    return -1;
}

int LoadProgramTableEntry(ElfContext *c, int i, ElfProgramHdr *program)
{
    return fseek(c->fp, c->hdr.phoff + i * c->hdr.phentsize, SEEK_SET) == 0
        && fread(program, 1, sizeof(ElfProgramHdr), c->fp) == sizeof(ElfProgramHdr);
}

int FindElfSymbol(ElfContext *c, const char *name, ElfSymbol *symbol)
{
    int i;
    for (i = 1; i < c->symbolCnt; ++i) {
        char thisName[ELFNAMEMAX];
        if (LoadElfSymbol(c, i, thisName, symbol) == 0 && strcmp(name, thisName) == 0)
            return TRUE;
    }
    return FALSE;
}

int LoadElfSymbol(ElfContext *c, int i, char *name, ElfSymbol *symbol)
{
    char *p = name;
    if (fseek(c->fp, c->symbolOff + i * sizeof(ElfSymbol), SEEK_SET) != 0
    ||  fread(symbol, 1, sizeof(ElfSymbol), c->fp) != sizeof(ElfSymbol))
        return -1;
    if (symbol->name) {
        int cnt, ch;
        fseek(c->fp, c->symbolStringOff + symbol->name, SEEK_SET);
        for (cnt = 0; ++cnt < ELFNAMEMAX && (ch = getc(c->fp)) != '\0'; )
            *p++ = ch;
    }
    *p = '\0';
    return 0;
}

void ShowElfFile(ElfContext *c)
{
    ElfSectionHdr section;
    ElfProgramHdr program;
    int i;

    /* show file header */
    printf("ELF Header:\n");
    printf("  ident:    ");
    for (i = 0; i < sizeof(c->hdr.ident); ++i)
        printf(" %02x", c->hdr.ident[i]);
    putchar('\n');
    printf("  type:      %04x\n", c->hdr.type);
    printf("  machine:   %04x\n", c->hdr.machine);
    printf("  version:   %08x\n", c->hdr.version);
    printf("  entry:     %08x\n", c->hdr.entry);
    printf("  phoff:     %08x\n", c->hdr.phoff);
    printf("  shoff:     %08x\n", c->hdr.shoff);
    printf("  flags:     %08x\n", c->hdr.flags);
    printf("  ehsize:    %d\n", c->hdr.entry);
    printf("  phentsize: %d\n", c->hdr.phentsize);
    printf("  phnum:     %d\n", c->hdr.phnum);
    printf("  shentsize: %d\n", c->hdr.shentsize);
    printf("  shnum:     %d\n", c->hdr.shnum);
    printf("  shstrndx:  %d\n", c->hdr.shstrndx);
    
    /* show the section table */
    for (i = 0; i < c->hdr.shnum; ++i) {
        char name[ELFNAMEMAX], *p = name;
        int cnt, ch;
        if (!LoadSectionTableEntry(c, i, &section)) {
            printf("error: can't read section header %d\n", i);
            return;
        }
        fseek(c->fp, c->stringOff + section.name, SEEK_SET);
        for (cnt = 0; ++cnt < ELFNAMEMAX && (ch = getc(c->fp)) != '\0'; )
            *p++ = ch;
        *p = '\0';
        printf("SectionHdr %d:\n", i);
        printf("  name:      %08x %s\n", section.name, name);
        ShowSectionHdr(&section);
    }
        
    /* show the program table */
    for (i = 0; i < c->hdr.phnum; ++i) {
        if (!LoadProgramTableEntry(c, i, &program)) {
            printf("error: can't read program header %d\n", i);
            return;
        }
        printf("ProgramHdr %d:\n", i);
        ShowProgramHdr(&program);
    }
    
    /* show the symbol table */
    for (i = 1; i < c->symbolCnt; ++i) {
        char name[ELFNAMEMAX];
        ElfSymbol symbol;
        if (LoadElfSymbol(c, i, name, &symbol) == 0 && symbol.name && INFO_BIND(symbol.info) == STB_GLOBAL)
            printf("  %08x %s: %08x\n", symbol.name, name, symbol.value);
    }
}

static void ShowSectionHdr(ElfSectionHdr *section)
{
    printf("  type:      %08x\n", section->type);
    printf("  flags:     %08x\n", section->flags);
    printf("  addr:      %08x\n", section->addr);
    printf("  offset:    %08x\n", section->offset);
    printf("  size:      %08x\n", section->size);
    printf("  link:      %08x\n", section->link);
    printf("  info:      %08x\n", section->info);
    printf("  addralign: %08x\n", section->addralign);
    printf("  entsize:   %08x\n", section->entsize);
}

static void ShowProgramHdr(ElfProgramHdr *program)
{
    printf("  type:      %08x\n", program->type);
    printf("  offset:    %08x\n", program->offset);
    printf("  vaddr:     %08x\n", program->vaddr);
    printf("  paddr:     %08x\n", program->paddr);
    printf("  filesz:    %08x\n", program->filesz);
    printf("  memsz:     %08x\n", program->memsz);
    printf("  flags:     %08x\n", program->flags);
    printf("  align:     %08x\n", program->align);
}

#ifdef MAIN

int main(int argc, char *argv[])
{
    ElfContext *c;
    ElfHdr hdr;
    FILE *fp;

    /* check the arguments */
    if (argc != 2) {
        printf("usage: loadelf <file>\n");
        return 1;
    }
    
    /* open the image file */
    if (!(fp = fopen(argv[1], "rb"))) {
        printf("error: opening '%s'\n", argv[1]);
        return 1;
    }
    
    /* make sure it's an elf file */
    if (!ReadAndCheckElfHdr(fp, &hdr)) {
        printf("error: not an elf file");
        return 1;
    }
    
    /* open the elf file */
    if (!(c = OpenElfFile(fp, &hdr))) {
        printf("error: opening elf file\n");
        return 1;
    }
    
    /* show the contents of the elf file */
    ShowElfFile(c);
    
    /* close the elf file */
    CloseElfFile(c);
    
    return 0;
}

#endif

