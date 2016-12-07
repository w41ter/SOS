#pragma once

#define ROOTINO 1  // root i-number
#define BSIZE 512  // block size

// Disk layout:
// [ boot block | super block | log | inode blocks | free bit map | data blocks ]
//
// mkfs computes the super block and builds an initial file system. The super describes
// the disk layout:
typedef struct SuperBlock {
  uint32_t size;         // Size of file system image (blocks)
  uint32_t nblocks;      // Number of data blocks
  uint32_t ninodes;      // Number of inodes.
  uint32_t nlog;         // Number of log blocks
  uint32_t logStart;     // Block number of first log block
  uint32_t inodeStart;   // Block number of first inode block
  uint32_t bmapStart;    // Block number of first free map block
} SuperBlock;

#define NDIRECT 12
#define NINDIRECT (BSIZE / sizeof(uint32_t))
#define MAXFILE (NDIRECT + NINDIRECT)

// On-disk inode structure
typedef struct DiskInode {
  short type;           // File type
  short major;          // Major device number (T_DEV only)
  short minor;          // Minor device number (T_DEV only)
  short nlink;          // Number of links to inode in file system
  uint32_t size;                // Size of file (bytes)
  uint32_t addrs[NDIRECT+1];    // Data block addresses
} DiskInode;

// Inodes per block.
#define IPB           (BSIZE / sizeof(DiskInode))

// Block containing inode i
#define IBLOCK(i, sb)     ((i) / IPB + sb.inodeStart)

// Bitmap bits per block
#define BPB           (BSIZE*8)

// Block of free map containing bit for block b
#define BBLOCK(b, sb) (b/BPB + sb.bmapStart)

// Directory is a file containing a sequence of dirent structures.
#define DIRSIZ 14

typedef struct DiskFileEntry {
  uint16_t inum;
  char name[DIRSIZ];
} DiskFileEntry;

void SetupFileSystem(void);

uint32_t InodeByFileName(char *filename);
uint32_t InodeCreate(char *filename);
uint32_t ReleaseInode(uint32_t inum);
void ReadInode(uint32_t inum, DiskInode *inode);
void WriteInode(uint32_t inum, DiskInode *inode);
uint32_t InodeTruncate(uint32_t inum, uint32_t offset);
uint32_t InodeRead(uint32_t inum, uint32_t offset, void *buf, size_t size);
uint32_t InodeAppend(uint32_t inum, uint32_t offset, void *buf, size_t size);