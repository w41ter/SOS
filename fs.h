#ifndef _FILE_SYSTEM_H_
#define _FILE_SYSTEM_H_

#include "list.h"
#include "types.h"

#define MAX_FILES_PER_PART  4096
#define BITS_PER_SECTOR     4096
#define SECTOR_SIZE         512
#define BLOCK_SIZE          SECTOR_SIZE

enum file_types {
    FT_Unknown,
    FT_Reg_file,
    FT_dir,
};

struct super_block {
    uint32_t magic;
    uint32_t sector_nums;
    uint32_t inode_nums;
    uint32_t part_lba_base;

    uint32_t block_bitmap_lba;
    uint32_t block_bitmap_sectors;

    uint32_t inode_bitmap_lba;
    uint32_t inode_bitmap_sectors;

    uint32_t data_start_lba;
    uint32_t root_inode_no;
    uint32_t dir_entry_size;

    uint8_t pad[460];               // 凑够 512 字节
} __attribute__((packed));


#define NDIRECT 12

struct inode {
    uint32_t no;
    uint32_t size;
    uint32_t open_times;
    bool write_deny;

    uint32_t sectors[NDIRECT + 1];
    struct list_node node; 
};

#define MAX_FILE_NAME_LENGTH 32

struct dir {
    struct inode *inode;
    uint32_t pos;
    uint8_t buf[512];
};

struct dir_entry {
    uint32_t no;
    enum file_types type;
    char name[MAX_FILE_NAME_LENGTH];
};

#endif /* _FILE_SYSTEM_H_ */