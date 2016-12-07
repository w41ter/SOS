#include <param.h>
#include <libs/types.h>
#include <libs/stdio.h>
#include <libs/debug.h>
#include <proc/spinlock.h>
#include <fs/file.h>
#include <fs/filesystem.h>

/* file descriptor */
static SpinLock lock;
static File files[NFILE];

uint32_t FileOpen(const char *filename, uint32_t flags)
{
    bool read = flags & FO_Read;
    bool write = flags & FO_Write;
    bool append = flags & FO_Append;

    uint32_t inum = InodeByFileName((char*)filename);
    if (inum == 0) {
        if (append)
            inum = InodeCreate((char*)filename);
        if (inum == 0)
            return 0;
    }
    
    uint32_t fd;
    File *p = NULL;
    for (size_t i = 0; i < NFILE; ++i) {
        if (files[i].type == FD_None) {
            fd = i;
            p = &files[i];
            goto FOUND;
        }
    }
    return 0;
FOUND:
    p->type = FD_Inode;
    p->writable = write;
    p->readable = read;
    p->inum = inum;

    DiskInode inode;
    ReadInode(inum, &inode);
    p->size = inode.size;
    p->offset = 0;

    if (!append)
        InodeTruncate(inum, 0);
    else 
        p->offset = inode.size - 1;
    return fd;
}

uint32_t FileClose(uint32_t fd)
{
    assert(fd < NFILE && "out of fd");

    File *p = &files[fd];
    if (p->type == FD_None)
        return 0;
    
    p->type = FD_None;
    return 1;
}

uint32_t FileUnlink(uint32_t fd)
{
    assert(fd < NFILE && "out of fd");

    File *p = &files[fd];
    if (p->type == FD_None)
        return 0;
    
    p->type = FD_None;
    ReleaseInode(p->inum);
    return 1;
}

uint32_t FileTtuncate(uint32_t fd)
{
    assert(fd < NFILE && "out of fd");

    File *p = &files[fd];
    if (p->type == FD_None)
        return 0;
    
    InodeTruncate(p->inum, p->offset);
    p->size = p->offset;
    return 1;
}

uint32_t FileRead(uint32_t fd, void *buf, size_t size)
{
    assert(fd < NFILE && "out of fd");
    assert(buf && "nullptr exception");

    File *p = &files[fd];
    if (p->type == FD_None || !p->readable)
        return 0;
    
    return InodeRead(p->inum, p->offset, buf, size);
}

uint32_t FileWrite(uint32_t fd, void *buf, size_t size)
{
    assert(fd < NFILE && "out of fd");
    assert(buf && "nullptr exception");

    File *p = &files[fd];
    if (p->type == FD_None || !p->writable)
        return 0;
    
    InodeTruncate(p->inum, p->offset);
    size_t res = InodeAppend(p->inum, p->offset, buf, size);
    p->size = p->offset + res;
    return res;
}

uint32_t FileSeek(uint32_t fd, uint32_t offset)
{
    assert(fd < NFILE && "out of fd");

    File *p = &files[fd];
    if (p->type == FD_None)
        return 0;
    
    if (p->size <= offset) 
        p->offset = p->size - 1;
    else 
        p->offset = offset;
    return 1;
}

uint32_t FileGetPos(uint32_t fd)
{
    assert(fd < NFILE && "out of fd");
    if (files[fd].type == FD_None)
        return 0;
    return files[fd].offset;
}

uint32_t IsFileEnd(uint32_t fd) 
{
    assert(fd < NFILE && "out of fd");
    return (files[fd].type = FD_None 
        || files[fd].size == files[fd].offset + 1);
}

void FileInitialize(void)
{
    InitSpinLock(&lock, "file descriptor lock");
    for (size_t i = 0; i < NFILE; ++i) {
        files[i].type = FD_None;
    }
}