#pragma once

enum { FT_Unknow, FT_Dir, FT_File };

typedef struct File {
    enum { FD_None, FD_Dev, FD_Pipe, FD_Inode } type;
    int ref; // reference count
    char readable;
    char writable;
    uint32_t dev;
    uint32_t inum;
    uint32_t size;
    uint32_t offset;
} File;

void FileInitialize(void);

enum { 
    FO_Read = 0x1, 
    FO_Write = 0x2, 
    FO_Append = 0x4
};

uint32_t FileOpen(const char *filename, uint32_t flags);
uint32_t FileClose(uint32_t fd);
uint32_t FileUnlink(uint32_t fd);

uint32_t FileTtuncate(uint32_t fd);
uint32_t FileRead(uint32_t fd, void *buf, size_t size);
uint32_t FileWrite(uint32_t fd, void *buf, size_t size);

uint32_t FileSeek(uint32_t fd, uint32_t offset);
uint32_t FileGetPos(uint32_t fd);
uint32_t IsFileEnd(uint32_t fd);