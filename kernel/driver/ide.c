#include <x86.h>
#include <trap/traps.h>
#include <libs/debug.h>
#include <libs/stdio.h>
#include <driver/device.h>

#define SECTSIZE 512

#define ISA_DATA                0x00
#define ISA_ERROR               0x01
#define ISA_PRECOMP             0x01
#define ISA_CTRL                0x02
#define ISA_SECCNT              0x02
#define ISA_SECTOR              0x03
#define ISA_CYL_LO              0x04
#define ISA_CYL_HI              0x05
#define ISA_SDH                 0x06
#define ISA_COMMAND             0x07
#define ISA_STATUS              0x07

#define IDE_BSY                 0x80
#define IDE_DRDY                0x40
#define IDE_DF                  0x20
#define IDE_DRQ                 0x08
#define IDE_ERR                 0x01

#define IDE_CMD_READ            0x20
#define IDE_CMD_WRITE           0x30
#define IDE_CMD_IDENTIFY        0xEC

#define IDE_IDENT_SECTORS       20
#define IDE_IDENT_MODEL         54
#define IDE_IDENT_CAPABILITIES  98
#define IDE_IDENT_CMDSETS       164
#define IDE_IDENT_MAX_LBA       120
#define IDE_IDENT_MAX_LBA_EXT   200

#define IO_BASE0                0x1F0
#define IO_BASE1                0x170
#define IO_CTRL0                0x3F4
#define IO_CTRL1                0x374

#define MAX_IDE                 4
#define MAX_NSECS               128
#define MAX_DISK_NSECS          0x10000000U
#define VALID_IDE(ideno)        (((ideno) >= 0) && ((ideno) < MAX_IDE) && (IDEDevices[ideno].valid))

static const struct {
    unsigned short base;        // I/O Base
    unsigned short ctrl;        // Control Base
} channels[2] = {
    {IO_BASE0, IO_CTRL0},
    {IO_BASE1, IO_CTRL1},
};

#define IO_BASE(ideno)          (channels[(ideno) >> 1].base)
#define IO_CTRL(ideno)          (channels[(ideno) >> 1].ctrl)

static struct IDEDevice {
    unsigned char valid;        // 0 or 1 (If Device Really Exists)
    unsigned int sets;          // Commend Sets Supported
    unsigned int size;          // Size in Sectors
    unsigned char model[41];    // Model in String
} IDEDevices[MAX_IDE];

static int IDEWaitReady(unsigned short iobase, bool check_error) 
{
    int r;
    while ((r = inb(iobase + ISA_STATUS)) & IDE_BSY)
        /* nothing */;
    if (check_error && (r & (IDE_DF | IDE_ERR)) != 0) {
        return -1;
    }
    return 0;
}

void IDEInitialize(void) 
{
    static_assert((SECTSIZE % 4) == 0);

    printk("++ setup ide device\n");
    for (uint16_t ideno = 0; ideno < MAX_IDE; ideno ++) {
        /* assume that no device here */
        IDEDevices[ideno].valid = 0;

        uint16_t iobase = IO_BASE(ideno);

        /* wait device ready */
        IDEWaitReady(iobase, 0);

        /* step1: select drive */
        outb(iobase + ISA_SDH, 0xE0 | ((ideno & 1) << 4));
        IDEWaitReady(iobase, 0);

        /* step2: send ATA identify command */
        outb(iobase + ISA_COMMAND, IDE_CMD_IDENTIFY);
        IDEWaitReady(iobase, 0);

        /* step3: polling */
        if (inb(iobase + ISA_STATUS) == 0 || IDEWaitReady(iobase, 1) != 0) {
            continue ;
        }

        /* device is ok */
        IDEDevices[ideno].valid = 1;

        /* read identification space of the device */
        unsigned int buffer[128];
        insl(iobase + ISA_DATA, buffer, sizeof(buffer) / sizeof(unsigned int));

        unsigned char *ident = (unsigned char *)buffer;
        unsigned int sectors;
        unsigned int cmdsets = *(unsigned int *)(ident + IDE_IDENT_CMDSETS);
        /* device use 48-bits or 28-bits addressing */
        if (cmdsets & (1 << 26)) {
            sectors = *(unsigned int *)(ident + IDE_IDENT_MAX_LBA_EXT);
        }
        else {
            sectors = *(unsigned int *)(ident + IDE_IDENT_MAX_LBA);
        }
        IDEDevices[ideno].sets = cmdsets;
        IDEDevices[ideno].size = sectors;

        /* check if supports LBA */
        assert((*(unsigned short *)(ident + IDE_IDENT_CAPABILITIES) & 0x200) != 0);

        unsigned char *model = IDEDevices[ideno].model, *data = ident + IDE_IDENT_MODEL;
        unsigned int i, length = 40;
        for (i = 0; i < length; i += 2) {
            model[i] = data[i + 1], model[i + 1] = data[i];
        }
        do {
            model[i] = '\0';
        } while (i -- > 0 && model[i] == ' ');

        printk("ide %d: %10u(sectors), '%s'.\n", ideno, IDEDevices[ideno].size, IDEDevices[ideno].model);
    }

    // enable ide interrupt
    PICEnable(IRQ_IDE1);
    PICEnable(IRQ_IDE2);
}

bool IsIDEDeviceValid(uint16_t ideno) {
    return VALID_IDE(ideno);
}

size_t IDEDeviceSize(uint16_t ideno) {
    if (IsIDEDeviceValid(ideno)) {
        return IDEDevices[ideno].size;
    }
    return 0;
}

int IDEReadSectors(uint16_t ideno, uint32_t secno, void *dst, size_t nsecs) {
    assert(nsecs <= MAX_NSECS && VALID_IDE(ideno));
    assert(secno < MAX_DISK_NSECS && secno + nsecs <= MAX_DISK_NSECS);
    unsigned short iobase = IO_BASE(ideno), ioctrl = IO_CTRL(ideno);

    IDEWaitReady(iobase, 0);

    // generate interrupt
    outb(ioctrl + ISA_CTRL, 0);
    outb(iobase + ISA_SECCNT, nsecs);
    outb(iobase + ISA_SECTOR, secno & 0xFF);
    outb(iobase + ISA_CYL_LO, (secno >> 8) & 0xFF);
    outb(iobase + ISA_CYL_HI, (secno >> 16) & 0xFF);
    outb(iobase + ISA_SDH, 0xE0 | ((ideno & 1) << 4) | ((secno >> 24) & 0xF));
    outb(iobase + ISA_COMMAND, IDE_CMD_READ);

    int ret = 0;
    for (; nsecs > 0; nsecs --, dst += SECTSIZE) {
        if ((ret = IDEWaitReady(iobase, 1)) != 0) {
            goto out;
        }
        insl(iobase, dst, SECTSIZE / sizeof(uint32_t));
    }

out:
    return ret;
}

int IDEWriteSectors(uint16_t ideno, uint32_t secno, const void *src, size_t nsecs) {
    assert(nsecs <= MAX_NSECS && VALID_IDE(ideno));
    assert(secno < MAX_DISK_NSECS && secno + nsecs <= MAX_DISK_NSECS);

    unsigned short iobase = IO_BASE(ideno), ioctrl = IO_CTRL(ideno);

    IDEWaitReady(iobase, 0);

    // generate interrupt
    outb(ioctrl + ISA_CTRL, 0);
    outb(iobase + ISA_SECCNT, nsecs);
    outb(iobase + ISA_SECTOR, secno & 0xFF);
    outb(iobase + ISA_CYL_LO, (secno >> 8) & 0xFF);
    outb(iobase + ISA_CYL_HI, (secno >> 16) & 0xFF);
    outb(iobase + ISA_SDH, 0xE0 | ((ideno & 1) << 4) | ((secno >> 24) & 0xF));
    outb(iobase + ISA_COMMAND, IDE_CMD_WRITE);

    int ret = 0;
    for (; nsecs > 0; nsecs --, src += SECTSIZE) {
        if ((ret = IDEWaitReady(iobase, 1)) != 0) {
            goto out;
        }
        outsl(iobase, src, SECTSIZE / sizeof(uint32_t));
    }

out:
    return ret;
}

