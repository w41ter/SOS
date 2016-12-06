
#include <stdio.h>
#include <inttypes.h>
#include <string.h>
#include <assert.h>
#include <stdlib.h>

#include <param.h>
#include <fs/file.h>
#include <fs/filesystem.h>

#ifndef static_assert
#define static_assert(a, b) do { switch (0) case 0: case (a): ; } while (0)
#endif

// Disk layout:
// [ boot block | sb block | log | inode blocks | free bit map | data blocks ]

// 1 fs block = 1 disk sector
#define NINODES 200

FILE *file;
uint32_t freeInode = ROOTINO;
uint32_t freeBlock = 0;  // the first free block that we can allocate
SuperBlock sb = { 0 };

void ClearAllBlocks(void);
void WriteSuperBlock(void);
void WriteRootEntry(void);
void SetBlockBitmap(uint32_t used);
void WriteFiles(int argc, char **argv);

uint16_t xshort(uint16_t x)
{
    uint16_t y;
    uint8_t *a = (uint8_t*)&y;
    a[0] = x;
    a[1] = x >> 8;
    return y;
}

uint32_t xint(uint32_t x)
{
    uint32_t y;
    uint8_t *a = (uint8_t*)&y;
    a[0] = x;
    a[1] = x >> 8;
    a[2] = x >> 16;
    a[3] = x >> 24;
    return y;
}

int main(int argc, char **argv)
{
    static_assert(sizeof(int) == 4, "");

    if (argc < 2) {
        printf("Usage: mkfs fs.img file ....\n");
        exit(-1);
    }

    file = fopen(argv[1], "wb+");
    if (file == NULL) {
        printf("Create %s failed\n", argv[1]);
        exit(-1);
    }

    ClearAllBlocks();
    WriteSuperBlock();
    WriteRootEntry();
    WriteFiles(argc - 2, &argv[2]);
    SetBlockBitmap(freeBlock);

    return 0;
}

void WriteSector(uint32_t sector, void *buf)
{
    if (fseek(file, sector * BSIZE, SEEK_SET) != 0) {
        printf("error when Write Sector\n");
        exit(-1);
    }

    if (fwrite(buf, BSIZE, 1, file) != 1) {
        printf("error when Write Sector\n");
        exit(-1);
    }
}

void ReadSector(uint32_t sector, void *buf)
{
    if (fseek(file, sector * BSIZE, SEEK_SET) != 0) {
        printf("error when Read Sector\n");
        exit(-1);
    }

    if (fread(buf, BSIZE, 1, file) != 1) {
        printf("error when Read Sector\n");
        exit(-1);
    }
}

void WriteInode(uint32_t inodeNum, DiskInode *in)
{
    uint8_t buf[BSIZE];
    DiskInode *din;
    uint32_t bn = IBLOCK(inodeNum, sb);
    ReadSector(bn, buf);
    din = ((DiskInode*)buf + (inodeNum % IPB));
    *din = *in;
    WriteSector(bn, buf);
}

void ReadInode(uint32_t inodeNum, DiskInode *in)
{
    uint8_t buf[BSIZE];
    DiskInode *din;
    uint32_t bn = IBLOCK(inodeNum, sb);
    ReadSector(bn, buf);
    din = ((DiskInode*)buf + (inodeNum % IPB));
    *in = *din;
}

uint32_t AllocInode(uint16_t type)
{
    uint32_t inum = freeInode++;
    DiskInode di = { 0 };
    di.type = xshort(type);
    di.nlink = xshort(1);
    di.size = xint(0);
    WriteInode(inum, &di);
    return inum;
}

uint32_t TryAllocateBlockWithInode(uint32_t *addr)
{
    if (xint(*addr) == 0) {
        *addr = xint(freeBlock++);
    }
    return xint(*addr);
}

#define min(a, b) ((a) < (b) ? (a) : (b))

void InodeAppend(uint32_t inum, void *p, size_t n)
{
    uint8_t buf[BSIZE];
    uint32_t indirect[NINDIRECT];
    DiskInode inode = { 0 };

    ReadInode(inum, &inode);

    uint32_t offset = xint(inode.size);
    while (n > 0) {
        uint32_t bn = offset / BSIZE;
        uint32_t target = 0;
        assert(bn < MAXFILE);
        if (bn < NDIRECT) {
            target = TryAllocateBlockWithInode(&inode.addrs[bn]);
        } 
        else {
            uint32_t indoff = TryAllocateBlockWithInode(&inode.addrs[NDIRECT]);
            ReadSector(indoff, (char*)indirect);
            if (xint(indirect[bn - NDIRECT]) == 0) {
                indirect[bn - NDIRECT] = xint(freeBlock++);
                WriteSector(indoff, (char*)indirect);
            }
            target = xint(indirect[bn - NDIRECT]);
        }
        size_t size = min(n, (bn + 1) * BSIZE - offset);
        ReadSector(target, buf);
        bcopy(p, buf + offset - bn * BSIZE, size);
        WriteSector(target, buf);
        n -= size;
        offset += size;
        p += size;
    }
    inode.size = xint(offset);
    WriteInode(inum, &inode);
}

void ClearAllBlocks(void)
{
    uint32_t buf[BSIZE];
    memset(buf, 0, sizeof(buf));
    for (size_t i = 0; i < FSSIZE; ++i) {
        WriteSector(i, buf);
    }
}

void WriteSuperBlock(void) 
{
    assert(file != NULL);

    int nbitmap = FSSIZE/(BSIZE*8) + 1;
    int ninodeblocks = NINODES / IPB + 1;
    int nlog = LOGSIZE;
    int nmeta;    // Number of meta blocks (boot, sb, nlog, inode, bitmap)
    int nblocks;  // Number of data blocks
    uint8_t buf[BSIZE];

    // 1 fs block = 1 disk sector
    nmeta = 2 + nlog + ninodeblocks + nbitmap;
    nblocks = FSSIZE - nmeta;

    sb.size = xint(FSSIZE);
    sb.nblocks = xint(nblocks);
    sb.ninodes = xint(NINODES);
    sb.nlog = xint(nlog);
    sb.logStart = xint(2);
    sb.inodeStart = xint(2+nlog);
    sb.bmapStart = xint(2+nlog+ninodeblocks);

    printf("nmeta %d (boot, super, log blocks %u inode blocks %u, bitmap blocks %u) blocks %d total %d\n",
            nmeta, nlog, ninodeblocks, nbitmap, nblocks, FSSIZE);
    
    bzero(buf, sizeof(buf));
    memmove(buf, &sb, sizeof(sb));
    WriteSector(1, buf);

    freeBlock = nmeta;
}

void WriteRootEntry(void)
{
    uint32_t rootino = AllocInode(FT_Dir);
    assert(rootino == ROOTINO);

    DiskFileEntry entry = { 0 };
    bzero(&entry, sizeof(entry));
    entry.inum = xshort(rootino);
    strcpy(entry.name, ".");
    InodeAppend(rootino, &entry, sizeof(entry));

    bzero(&entry, sizeof(entry));
    entry.inum = xshort(rootino);
    strcpy(entry.name, "..");
    InodeAppend(rootino, &entry, sizeof(entry));
}

void SetBlockBitmap(uint32_t used)
{
    uint8_t buf[BSIZE];
    printf("balloc: first %d blocks have been allocated\n", used);
    assert(used < BSIZE*8);
    bzero(buf, BSIZE);
    for (size_t i = 0; i < used; ++i) {
        buf[i/8] = buf[i/8] | (0x1 << (i%8));
    }
    printf("balloc: write bitmap block at sector %d\n", sb.bmapStart);
    WriteSector(sb.bmapStart, buf);
}

void WriteFiles(int argc, char **argv)
{
    if (argc <= 0)
        return;
    
    uint8_t buf[BSIZE];

    for (size_t i = 0; i < argc; ++i) {
        assert(index(argv[i], '/') == 0);
        FILE *file = fopen(argv[i], "rb");
        if (file == NULL) {
            printf("open file %s failed\n", argv[i]);
            exit(1);
        }

        // Skip leading _ in name when writing to file system.
        // The binaries are named _rm, _cat, etc. to keep the
        // build operating system from trying to execute them
        // in place of system binaries like rm and cat.
        if(argv[i][0] == '_')
            ++argv[i];
        uint32_t inum = AllocInode(FT_File);
        DiskFileEntry entry = { 0 };
        bzero(&entry, sizeof(entry));
        entry.inum = xshort(inum);
        strncpy(entry.name, argv[i], DIRSIZ);
        InodeAppend(ROOTINO, &entry, sizeof(entry));

        size_t size = 0;
        while((size = fread(buf, 1, sizeof(buf), file)) != 0)
            InodeAppend(inum, buf, size);

        fclose(file);
    }
}