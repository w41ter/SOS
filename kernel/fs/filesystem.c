#include <libs/stdio.h>
#include <libs/debug.h>
#include <libs/types.h>
#include <libs/string.h>
#include <fs/file.h>
#include <fs/filesystem.h>
#include <driver/device.h>
#include <proc/spinlock.h>

#define FS_IDE_NO 1
#define SUPER_BLOCK_NO 1

static SuperBlock superBlock;

static uint8_t sector[BSIZE];
static SpinLock sectorLock;

static void LoadSuperBlock(void)
{
    assert(IsIDEDeviceValid(FS_IDE_NO));
    IDEReadSectors(FS_IDE_NO, SUPER_BLOCK_NO, sector, 1);
    superBlock = *(SuperBlock*)sector;
}

static void BlockZero(uint32_t bno)
{
    /* must lock */
    bzero(sector, BSIZE);
    IDEWriteSectors(FS_IDE_NO, bno, sector, 1);
}

static uint32_t AllocateBlock()
{   
    Acquire(&sectorLock);
    for (size_t b = 0; b < superBlock.size; b += BPB) {
        IDEReadSectors(FS_IDE_NO, BBLOCK(b, superBlock), sector, 1);
        for (size_t bi = 0; bi < BPB && b + bi < superBlock.size; bi++) {
            uint32_t m = 1 << (bi % 8);
            if ((sector[bi/8] & m) != 0)
                continue;
            /* Is block free? */
            sector[bi/8] |= m;
            IDEWriteSectors(FS_IDE_NO, BBLOCK(b, superBlock), sector, 1);
            BlockZero(b + bi);
            Release(&sectorLock);
            return b + bi;
        }
    }
    Release(&sectorLock);
    panic("balloc: out of blocks");
    return 0;
}

// Free a disk block.
static void FreeBlock(uint32_t b)
{
    Acquire(&sectorLock);
    IDEReadSectors(FS_IDE_NO, BBLOCK(b, superBlock), sector, 1);
    uint32_t bi = b % BPB;
    uint32_t m = 1 << (bi % 8);
    if (sector[bi/8] & m)
        panic("freeing free block");
    sector[bi/8] &= ~m;
    IDEWriteSectors(FS_IDE_NO, BBLOCK(b, superBlock), sector, 1);
    Release(&sectorLock);
}

static uint16_t xshort(uint16_t x)
{
    uint16_t y;
    uint8_t *a = (uint8_t*)&y;
    a[0] = x;
    a[1] = x >> 8;
    return y;
}

static uint32_t xint(uint32_t x)
{
    uint32_t y;
    uint8_t *a = (uint8_t*)&y;
    a[0] = x;
    a[1] = x >> 8;
    a[2] = x >> 16;
    a[3] = x >> 24;
    return y;
}

static uint32_t GetBlockNumByOffset(DiskInode *inode, uint32_t offset)
{
    uint32_t bn = offset / BSIZE;
    if (bn < NDIRECT) {
        return xint(inode->addrs[bn]);
    }
    
    Acquire(&sectorLock);
    IDEReadSectors(FS_IDE_NO, xint(inode->addrs[NDIRECT]), sector, 1);

    size_t bo = *((uint32_t*)sector + bn - NDIRECT);
    Release(&sectorLock);
    return bo;
}

static uint32_t SearchItemInBlock(
    uint32_t bn, uint32_t type, const char *name, size_t size)
{
    Acquire(&sectorLock);
    IDEReadSectors(FS_IDE_NO, BBLOCK(bn, superBlock), sector, 1);
    for (DiskFileEntry *entry = (DiskFileEntry*)sector;
        entry - (DiskFileEntry*)sector < size
        && entry - (DiskFileEntry*)sector < BSIZE; entry++) {
        if (strcmp(name, entry->name) == 0) {
            Release(&sectorLock);
            return entry->inum;
        }
    }
    Release(&sectorLock);
    return 0;
}

static uint32_t FindFileInodeNum(uint32_t inum, const char *name)
{
    DiskInode parent;
    ReadInode(inum, &parent);
    size_t size = xint(parent.size);
    for (size_t i = 0; i < size; i += BSIZE) {
        uint32_t num = SearchItemInBlock(
            GetBlockNumByOffset(&parent, i), FT_File, name, size - i);
        if (num != 0) 
            return num;
    }
    return 0;
}

static uint32_t FindEntryInodeNum(uint32_t inum, const char *dir)
{
    DiskInode parent;
    ReadInode(inum, &parent);
    size_t size = xint(parent.size);
    for (size_t i = 0; i < size; i += BSIZE) {
        uint32_t num = SearchItemInBlock(
            GetBlockNumByOffset(&parent, i), FT_Dir, dir, size - i);
        if (num != 0) 
            return num;
    }
    return 0;
}

static void GetFileName(const char *from, char *to, size_t count)
{
    size_t last = find_last_of(from, '/');
    strncpy(to, from + last + 1, count);
}

// Copy the next path element from path into name.
// Return a pointer to the element following the copied one.
// The returned path has no leading slashes,
// so the caller can check *path=='\0' to see if the name is the last one.
// If no name to remove, return 0.
//
// Examples:
//   skipelem("a/bb/c", name) = "bb/c", setting name = "a"
//   skipelem("///a//bb", name) = "bb", setting name = "a"
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char * SkipElement(char *path, char *name)
{
    char *s;
    int len;

    while (*path == '/')
        path++;
    if (*path == 0)
        return 0;
    s = path;
    while (*path != '/' && *path != 0)
        path++;
    len = path - s;
    if (len >= DIRSIZ)
        memmove(name, s, DIRSIZ);
    else {
        memmove(name, s, len);
        name[len] = 0;
    }
    while (*path == '/')
        path++;
    return path;
}

// Look up and return the inode for a path name.
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static uint32_t GetTargetDirNum(char *filename)
{
    size_t endPos = find_last_of(filename, '/');
    char *path = filename;
    char name[DIRSIZ];

    uint32_t inum = 1;
    if (*path == '/')
        inum = ROOTINO;
    else
        ;//ip = idup(proc->cwd);

    while ((path = SkipElement(path, name)) != 0) {
        if (path - filename > endPos)
            break;
        inum = FindEntryInodeNum(inum, name);
    }
    return inum;
}

uint32_t InodeByFileName(char *filename)
{
    char name[DIRSIZ];
    GetFileName(filename, name, DIRSIZ - 1);
    if (name[0] == '0') /* no file name */
        return 0;
    uint32_t dinum = GetTargetDirNum(filename);
    if (dinum == 0)
        return 0;
    return FindFileInodeNum(dinum, name);
}

static void InitInode(DiskInode *p, uint16_t type)
{
    p->type = xshort(type);
    p->nlink = xshort(1);
    p->size = xint(0);
    for (size_t i = 0; i < NDIRECT + 1; ++i) {
        p->addrs[i] = 0;
    }
}

static uint32_t AllocateInode(uint16_t type)
{
    for (uint32_t inum = 1; inum < superBlock.ninodes; ++inum) {
        Acquire(&sectorLock);
        IDEReadSectors(FS_IDE_NO, IBLOCK(inum, superBlock), sector, 1);
        for (size_t i = 0; i < IPB; ++i) {
            DiskInode *p = (DiskInode*)sector + i;
            if (xint(p->type) == FT_Unknow) {
                InitInode(p, type);
                IDEWriteSectors(FS_IDE_NO, IBLOCK(inum, superBlock), sector, 1);
                Release(&sectorLock);
                return inum;
            }
        }
        Release(&sectorLock);
    }
    return 0;
}

static uint32_t CreateInode(uint32_t parent, uint16_t type, const char *name)
{
    uint32_t inum = AllocateInode(FT_Dir);
    DiskFileEntry dir;
    dir.inum = xshort(inum);
    strncpy(dir.name, name, DIRSIZ);

    DiskInode p;
    ReadInode(parent, &p);
    InodeAppend(parent, xint(p.size), &dir, sizeof(dir));
    return inum;
}

static uint32_t InodeCreateEntry(char *filename)
{
    size_t post = find_last_of(filename, '/');
    char *path = filename;
    char name[DIRSIZ];

    uint32_t iparent = 1;
    if (*path == '/')
        iparent = ROOTINO;
    else
        ;//ip = idup(proc->cwd);

    while ((path = SkipElement(path, name)) != 0) {
        if (path - filename > post)
            break;
        uint32_t inum = FindEntryInodeNum(iparent, name);
        if (inum == 0) {
            inum = CreateInode(iparent, FT_Dir, name);
        } 
        iparent = inum;
    }
    return iparent;
}

uint32_t InodeCreate(char *filename)
{
    char name[DIRSIZ];
    GetFileName(filename, name, DIRSIZ - 1);
    if (name[0] == '0') /* no file name */
        return 0;
    uint32_t dinum = InodeCreateEntry(filename);
    if (dinum == 0)
        return 0;
    
    return CreateInode(dinum, FT_File, name);
}

uint32_t InodeReleaseBlockAfter(DiskInode *inode, uint32_t offset)
{
    size_t off = offset / BSIZE + 1;
    size_t size = xint(inode->size) / BSIZE + 1;

    if (off < NDIRECT) {
        for (size_t i = 0; off < NDIRECT; ++i) {
            if (xint(inode->addrs[i]) == 0)
                continue;
            FreeBlock(xint(inode->addrs[i]));
        }
        off = NDIRECT;
    }
    else if (xint(inode->addrs[NDIRECT]) == 0)
        return 0;

    off -= NDIRECT;
    size -= NDIRECT;
    /* notice, may out of memory */
    uint32_t indirect[NINDIRECT];
    size_t bn = xint(inode->addrs[NDIRECT]);
    IDEReadSectors(FS_IDE_NO, BBLOCK(bn, superBlock), indirect, 1);
    for (size_t i = off; i < NINDIRECT; ++i) {
        if (i >= size) 
            break;
        size_t bnum = xint(indirect[i]);
        if (bnum != 0)
            FreeBlock(bnum);
    }
    
    if (off == 0) {
        FreeBlock(xint(inode->addrs[NDIRECT]));
    }
    return 1;
}

uint32_t InodeTruncate(uint32_t inum, uint32_t offset)
{
    DiskInode inode;
    ReadInode(inum, &inode);
    InodeReleaseBlockAfter(&inode, offset);
    inode.size = xint(offset);
    WriteInode(inum, &inode);
    return 1;
}

uint32_t ReleaseInode(uint32_t inum)
{
    DiskInode inode;
    ReadInode(inum, &inode);
    InodeReleaseBlockAfter(&inode, 0);
    inode.type = xshort(FT_Unknow);
    inode.nlink = xshort(0);
    inode.size = xint(0);
    WriteInode(inum, &inode);
    return 1;
}

void WriteInode(uint32_t inum, DiskInode *inode)
{
    Acquire(&sectorLock);
    IDEReadSectors(FS_IDE_NO, IBLOCK(inum, superBlock), sector, 1);
    *((DiskInode*)sector + (inum % IPB)) = *inode;
    Release(&sectorLock);
}

void ReadInode(uint32_t inum, DiskInode *inode)
{
    Acquire(&sectorLock);
    IDEReadSectors(FS_IDE_NO, IBLOCK(inum, superBlock), sector, 1);
    *inode = *((DiskInode*)sector + (inum % IPB));
    Release(&sectorLock);
}

#define min(a, b) ((a) < (b) ? (a) : (b))

uint32_t InodeRead(uint32_t inum, uint32_t offset, void *buf, size_t n)
{
    DiskInode inode;
    ReadInode(inum, &inode);
    while (n > 0) {
        uint32_t bn = offset / BSIZE;
        assert(bn < MAXFILE);
        uint32_t target = GetBlockNumByOffset(&inode, offset);
        size_t size = min(n, (bn + 1) * BSIZE - offset);

        Acquire(&sectorLock);
        IDEReadSectors(FS_IDE_NO, target, sector, 1);
        Release(&sectorLock);

        memcpy(buf, sector + offset - bn * BSIZE, size);
        n -= size;
        offset += size;
        buf += size;
    }
    return 1;
}

static uint32_t GetBlockByOffsetWithAllocate(DiskInode *inode, size_t bn)
{
    uint32_t indirect[NINDIRECT];
    if (bn < NDIRECT) {
        if (xint(inode->addrs[bn]) == 0) {
            inode->addrs[bn] = xint(AllocateBlock());
            Acquire(&sectorLock);
            BlockZero(inode->addrs[bn]);
            Release(&sectorLock);
        }
        return xint(inode->addrs[bn]);
    } 
    else {
        if (xint(inode->addrs[NDIRECT]) == 0) {
            inode->addrs[NDIRECT] = xint(AllocateBlock());
            Acquire(&sectorLock);
            BlockZero(inode->addrs[NDIRECT]);
            Release(&sectorLock);
        }
        uint32_t indoff = inode->addrs[NDIRECT];
        IDEReadSectors(FS_IDE_NO, indoff, indirect, 1);
        if (xint(indirect[bn - NDIRECT]) == 0) {
            indirect[bn - NDIRECT] = xint(AllocateBlock());
            Acquire(&sectorLock);
            BlockZero(indirect[bn - NDIRECT]);
            Release(&sectorLock);
            IDEWriteSectors(FS_IDE_NO, indoff, indirect, 1);
        }
        return xint(indirect[bn - NDIRECT]);
    }
}

uint32_t InodeAppend(uint32_t inum, uint32_t offset, void *p, size_t n)
{
    DiskInode inode = { 0 };
    ReadInode(inum, &inode);

    InodeTruncate(inum, offset);

    while (n > 0) {
        uint32_t bn = offset / BSIZE;
        uint32_t target = 0;
        assert(bn < MAXFILE);
        target = GetBlockByOffsetWithAllocate(&inode, bn);
        size_t size = min(n, (bn + 1) * BSIZE - offset);

        Acquire(&sectorLock);
        IDEReadSectors(FS_IDE_NO, target, p, 1);
        memcpy(sector + offset - bn * BSIZE, p, size);
        IDEWriteSectors(FS_IDE_NO, target, p, 1);
        Release(&sectorLock);

        n -= size;
        offset += size;
        p += size;
    }
    inode.size = xint(offset);
    WriteInode(inum, &inode);
    return 1;
}

void SetupFileSystem(void)
{
    printk("++ setup file system.\n");
    LoadSuperBlock();
    InitSpinLock(&sectorLock, "sector lock");
    FileInitialize();
}