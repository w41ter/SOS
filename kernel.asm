
kernel:     file format elf32-i386


Disassembly of section .text:

c0100000 <multiboot_header>:
c0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
c0100006:	00 00                	add    %al,(%eax)
c0100008:	fe 4f 52             	decb   0x52(%edi)
c010000b:	e4 00                	in     $0x0,%al

c010000c <MemorySizeInKB>:
c010000c:	00 00                	add    %al,(%eax)
	...

c0100010 <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Detect memory size before turn on paging
  call    ProbesMemory
c0100010:	e8 db 13 00 00       	call   c01013f0 <ProbesMemory>
  movl    %eax, V2P_WO(MemorySizeInKB)
c0100015:	a3 0c 00 10 00       	mov    %eax,0x10000c
  #movl   $0x64, 0x0010000c

  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
c010001a:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
c010001d:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
c0100020:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
c0100023:	b8 00 40 10 00       	mov    $0x104000,%eax
  movl    %eax, %cr3
c0100028:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
c010002b:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
c010002e:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
c0100033:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
c0100036:	bc d0 b0 10 c0       	mov    $0xc010b0d0,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
c010003b:	b8 50 11 10 c0       	mov    $0xc0101150,%eax
  jmp *%eax
c0100040:	ff e0                	jmp    *%eax
c0100042:	66 90                	xchg   %ax,%ax
c0100044:	66 90                	xchg   %ax,%ax
c0100046:	66 90                	xchg   %ax,%ax
c0100048:	66 90                	xchg   %ax,%ax
c010004a:	66 90                	xchg   %ax,%ax
c010004c:	66 90                	xchg   %ax,%ax
c010004e:	66 90                	xchg   %ax,%ax

c0100050 <console_putc_color>:
    }
}

static void console_putc_color(char c, 
	real_color_t back, real_color_t fore)
{
c0100050:	55                   	push   %ebp
    uint8_t attribute_byte = (back_color << 4) | (fore_color & 0x0F);
    uint16_t attribute = attribute_byte << 8;

    // 0x08 是退格键的 ASCII 码
    // 0x09 是tab 键的 ASCII 码
    if (c == 0x08 && cursor_x) {
c0100051:	3c 08                	cmp    $0x8,%al
    }
}

static void console_putc_color(char c, 
	real_color_t back, real_color_t fore)
{
c0100053:	89 e5                	mov    %esp,%ebp
c0100055:	56                   	push   %esi
c0100056:	53                   	push   %ebx
    uint8_t attribute_byte = (back_color << 4) | (fore_color & 0x0F);
    uint16_t attribute = attribute_byte << 8;

    // 0x08 是退格键的 ASCII 码
    // 0x09 是tab 键的 ASCII 码
    if (c == 0x08 && cursor_x) {
c0100057:	0f 84 1f 01 00 00    	je     c010017c <console_putc_color+0x12c>
          cursor_x--;
    } else if (c == 0x09) {
c010005d:	3c 09                	cmp    $0x9,%al
c010005f:	74 63                	je     c01000c4 <console_putc_color+0x74>
          cursor_x = (cursor_x+8) & ~(8-1);
    } else if (c == '\r') {
c0100061:	3c 0d                	cmp    $0xd,%al
c0100063:	0f 84 2f 01 00 00    	je     c0100198 <console_putc_color+0x148>
          cursor_x = 0;
    } else if (c == '\n') {
c0100069:	3c 0a                	cmp    $0xa,%al
c010006b:	90                   	nop
c010006c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
c0100070:	0f 84 5f 01 00 00    	je     c01001d5 <console_putc_color+0x185>
        cursor_x = 0;
        cursor_y++;
    } else if (c >= ' ') {
c0100076:	3c 1f                	cmp    $0x1f,%al
c0100078:	0f 8e 2f 01 00 00    	jle    c01001ad <console_putc_color+0x15d>
	real_color_t back, real_color_t fore)
{
    uint8_t back_color = (uint8_t)back;
    uint8_t fore_color = (uint8_t)fore;

    uint8_t attribute_byte = (back_color << 4) | (fore_color & 0x0F);
c010007e:	83 e1 0f             	and    $0xf,%ecx
          cursor_x = 0;
    } else if (c == '\n') {
        cursor_x = 0;
        cursor_y++;
    } else if (c >= ' ') {
        video_memory[cursor_y*80 + cursor_x] = c | attribute;
c0100081:	0f b6 1d c0 a0 10 c0 	movzbl 0xc010a0c0,%ebx
c0100088:	66 98                	cbtw   
	real_color_t back, real_color_t fore)
{
    uint8_t back_color = (uint8_t)back;
    uint8_t fore_color = (uint8_t)fore;

    uint8_t attribute_byte = (back_color << 4) | (fore_color & 0x0F);
c010008a:	c1 e2 04             	shl    $0x4,%edx
          cursor_x = 0;
    } else if (c == '\n') {
        cursor_x = 0;
        cursor_y++;
    } else if (c >= ' ') {
        video_memory[cursor_y*80 + cursor_x] = c | attribute;
c010008d:	0f b6 35 c1 a0 10 c0 	movzbl 0xc010a0c1,%esi
	real_color_t back, real_color_t fore)
{
    uint8_t back_color = (uint8_t)back;
    uint8_t fore_color = (uint8_t)fore;

    uint8_t attribute_byte = (back_color << 4) | (fore_color & 0x0F);
c0100094:	09 ca                	or     %ecx,%edx
    uint16_t attribute = attribute_byte << 8;
c0100096:	c1 e2 08             	shl    $0x8,%edx
          cursor_x = 0;
    } else if (c == '\n') {
        cursor_x = 0;
        cursor_y++;
    } else if (c >= ' ') {
        video_memory[cursor_y*80 + cursor_x] = c | attribute;
c0100099:	09 c2                	or     %eax,%edx
        cursor_x++;
c010009b:	0f b6 05 c1 a0 10 c0 	movzbl 0xc010a0c1,%eax
          cursor_x = 0;
    } else if (c == '\n') {
        cursor_x = 0;
        cursor_y++;
    } else if (c >= ' ') {
        video_memory[cursor_y*80 + cursor_x] = c | attribute;
c01000a2:	8d 1c 9b             	lea    (%ebx,%ebx,4),%ebx
c01000a5:	c1 e3 04             	shl    $0x4,%ebx
c01000a8:	01 f3                	add    %esi,%ebx
        cursor_x++;
c01000aa:	8d 48 01             	lea    0x1(%eax),%ecx
          cursor_x = 0;
    } else if (c == '\n') {
        cursor_x = 0;
        cursor_y++;
    } else if (c >= ' ') {
        video_memory[cursor_y*80 + cursor_x] = c | attribute;
c01000ad:	66 89 94 1b 00 80 0b 	mov    %dx,-0x3ff48000(%ebx,%ebx,1)
c01000b4:	c0 
        cursor_x++;
c01000b5:	0f b6 15 c0 a0 10 c0 	movzbl 0xc010a0c0,%edx
c01000bc:	88 0d c1 a0 10 c0    	mov    %cl,0xc010a0c1
c01000c2:	eb 1a                	jmp    c01000de <console_putc_color+0x8e>
    // 0x08 是退格键的 ASCII 码
    // 0x09 是tab 键的 ASCII 码
    if (c == 0x08 && cursor_x) {
          cursor_x--;
    } else if (c == 0x09) {
          cursor_x = (cursor_x+8) & ~(8-1);
c01000c4:	0f b6 05 c1 a0 10 c0 	movzbl 0xc010a0c1,%eax
c01000cb:	0f b6 15 c0 a0 10 c0 	movzbl 0xc010a0c0,%edx
c01000d2:	8d 48 08             	lea    0x8(%eax),%ecx
c01000d5:	83 e1 f8             	and    $0xfffffff8,%ecx
c01000d8:	88 0d c1 a0 10 c0    	mov    %cl,0xc010a0c1
        video_memory[cursor_y*80 + cursor_x] = c | attribute;
        cursor_x++;
    }

    // 每 80 个字符一行，满80就必须换行了
    if (cursor_x >= 80) {
c01000de:	80 f9 4f             	cmp    $0x4f,%cl
c01000e1:	0f 86 a9 00 00 00    	jbe    c0100190 <console_putc_color+0x140>
        cursor_x = 0;
        cursor_y ++;
c01000e7:	83 c2 01             	add    $0x1,%edx
c01000ea:	31 c9                	xor    %ecx,%ecx
        cursor_x++;
    }

    // 每 80 个字符一行，满80就必须换行了
    if (cursor_x >= 80) {
        cursor_x = 0;
c01000ec:	c6 05 c1 a0 10 c0 00 	movb   $0x0,0xc010a0c1
        cursor_y ++;
c01000f3:	88 15 c0 a0 10 c0    	mov    %dl,0xc010a0c0
    // attribute_byte 被构造出一个黑底白字的描述格式
    uint8_t attribute_byte = (0 << 4) | (15 & 0x0F);
    uint16_t blank = 0x20 | (attribute_byte << 8);  // space 是 0x20

    // cursor_y 到 25 的时候，就该换行了
    if (cursor_y >= 25) {
c01000f9:	31 c0                	xor    %eax,%eax
c01000fb:	80 fa 18             	cmp    $0x18,%dl
c01000fe:	76 71                	jbe    c0100171 <console_putc_color+0x121>
        // 将所有行的显示数据复制到上一行，第一行永远消失了...
        int i;
        
        for (i = 0 * 80; i < 24 * 80; i++) {
              video_memory[i] = video_memory[i+80];
c0100100:	0f b7 94 00 a0 80 0b 	movzwl -0x3ff47f60(%eax,%eax,1),%edx
c0100107:	c0 
c0100108:	66 89 94 00 00 80 0b 	mov    %dx,-0x3ff48000(%eax,%eax,1)
c010010f:	c0 
    // cursor_y 到 25 的时候，就该换行了
    if (cursor_y >= 25) {
        // 将所有行的显示数据复制到上一行，第一行永远消失了...
        int i;
        
        for (i = 0 * 80; i < 24 * 80; i++) {
c0100110:	83 c0 01             	add    $0x1,%eax
c0100113:	3d 80 07 00 00       	cmp    $0x780,%eax
c0100118:	75 e6                	jne    c0100100 <console_putc_color+0xb0>
c010011a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
              video_memory[i] = video_memory[i+80];
        }

        // 最后的一行数据现在填充空格，不显示任何字符
        for (i = 24 * 80; i < 25 * 80; i++) {
              video_memory[i] = blank;
c0100120:	ba 20 0f 00 00       	mov    $0xf20,%edx
c0100125:	66 89 94 00 00 80 0b 	mov    %dx,-0x3ff48000(%eax,%eax,1)
c010012c:	c0 
        for (i = 0 * 80; i < 24 * 80; i++) {
              video_memory[i] = video_memory[i+80];
        }

        // 最后的一行数据现在填充空格，不显示任何字符
        for (i = 24 * 80; i < 25 * 80; i++) {
c010012d:	83 c0 01             	add    $0x1,%eax
c0100130:	3d d0 07 00 00       	cmp    $0x7d0,%eax
c0100135:	75 e9                	jne    c0100120 <console_putc_color+0xd0>
              video_memory[i] = blank;
        }
        
        // 向上移动了一行，所以 cursor_y 现在是 24
        cursor_y = 24;
c0100137:	c6 05 c0 a0 10 c0 18 	movb   $0x18,0xc010a0c0
c010013e:	ba 80 07 00 00       	mov    $0x780,%edx
                             "memory", "cc");
}

static inline void outb(uint16_t port, uint8_t data)
{
    asm volatile("out %0,%1" : : "a" (data), "d" (port));
c0100143:	be d4 03 00 00       	mov    $0x3d4,%esi
static uint8_t cursor_y = 0;

static void move_cursor()
{
    // 屏幕是 80 字节宽
    uint16_t cursorLocation = cursor_y * 80 + cursor_x;
c0100148:	01 d1                	add    %edx,%ecx
c010014a:	b8 0e 00 00 00       	mov    $0xe,%eax
c010014f:	89 f2                	mov    %esi,%edx
c0100151:	ee                   	out    %al,(%dx)
c0100152:	bb d5 03 00 00       	mov    $0x3d5,%ebx
    
    // 在这里用到的两个内部寄存器的编号为14与15，分别表示光标位置
    // 的高8位与低8位。

    outb(0x3D4, 14);                    // 告诉 VGA 我们要设置光标的高字节
    outb(0x3D5, cursorLocation >> 8);   // 发送高 8 位
c0100157:	89 c8                	mov    %ecx,%eax
c0100159:	66 c1 e8 08          	shr    $0x8,%ax
c010015d:	89 da                	mov    %ebx,%edx
c010015f:	ee                   	out    %al,(%dx)
c0100160:	b8 0f 00 00 00       	mov    $0xf,%eax
c0100165:	89 f2                	mov    %esi,%edx
c0100167:	ee                   	out    %al,(%dx)
c0100168:	89 c8                	mov    %ecx,%eax
c010016a:	89 da                	mov    %ebx,%edx
c010016c:	ee                   	out    %al,(%dx)
    // 如果需要的话滚动屏幕显示
    scroll();

    // 移动硬件的输入光标
    move_cursor();
}
c010016d:	5b                   	pop    %ebx
c010016e:	5e                   	pop    %esi
c010016f:	5d                   	pop    %ebp
c0100170:	c3                   	ret    
c0100171:	0f b6 d2             	movzbl %dl,%edx
c0100174:	8d 14 92             	lea    (%edx,%edx,4),%edx
c0100177:	c1 e2 04             	shl    $0x4,%edx
c010017a:	eb c7                	jmp    c0100143 <console_putc_color+0xf3>
    uint8_t attribute_byte = (back_color << 4) | (fore_color & 0x0F);
    uint16_t attribute = attribute_byte << 8;

    // 0x08 是退格键的 ASCII 码
    // 0x09 是tab 键的 ASCII 码
    if (c == 0x08 && cursor_x) {
c010017c:	0f b6 05 c1 a0 10 c0 	movzbl 0xc010a0c1,%eax
c0100183:	0f b6 15 c0 a0 10 c0 	movzbl 0xc010a0c0,%edx
c010018a:	84 c0                	test   %al,%al
c010018c:	75 32                	jne    c01001c0 <console_putc_color+0x170>
    } else if (c == '\n') {
        cursor_x = 0;
        cursor_y++;
    } else if (c >= ' ') {
        video_memory[cursor_y*80 + cursor_x] = c | attribute;
        cursor_x++;
c010018e:	31 c9                	xor    %ecx,%ecx
c0100190:	0f b6 c9             	movzbl %cl,%ecx
c0100193:	e9 61 ff ff ff       	jmp    c01000f9 <console_putc_color+0xa9>
    if (c == 0x08 && cursor_x) {
          cursor_x--;
    } else if (c == 0x09) {
          cursor_x = (cursor_x+8) & ~(8-1);
    } else if (c == '\r') {
          cursor_x = 0;
c0100198:	c6 05 c1 a0 10 c0 00 	movb   $0x0,0xc010a0c1
c010019f:	0f b6 15 c0 a0 10 c0 	movzbl 0xc010a0c0,%edx
c01001a6:	31 c9                	xor    %ecx,%ecx
c01001a8:	e9 4c ff ff ff       	jmp    c01000f9 <console_putc_color+0xa9>
c01001ad:	0f b6 0d c1 a0 10 c0 	movzbl 0xc010a0c1,%ecx
c01001b4:	0f b6 15 c0 a0 10 c0 	movzbl 0xc010a0c0,%edx
c01001bb:	e9 1e ff ff ff       	jmp    c01000de <console_putc_color+0x8e>
    uint16_t attribute = attribute_byte << 8;

    // 0x08 是退格键的 ASCII 码
    // 0x09 是tab 键的 ASCII 码
    if (c == 0x08 && cursor_x) {
          cursor_x--;
c01001c0:	8d 48 ff             	lea    -0x1(%eax),%ecx
c01001c3:	0f b6 15 c0 a0 10 c0 	movzbl 0xc010a0c0,%edx
c01001ca:	88 0d c1 a0 10 c0    	mov    %cl,0xc010a0c1
c01001d0:	e9 09 ff ff ff       	jmp    c01000de <console_putc_color+0x8e>
          cursor_x = (cursor_x+8) & ~(8-1);
    } else if (c == '\r') {
          cursor_x = 0;
    } else if (c == '\n') {
        cursor_x = 0;
        cursor_y++;
c01001d5:	0f b6 05 c0 a0 10 c0 	movzbl 0xc010a0c0,%eax
    } else if (c == 0x09) {
          cursor_x = (cursor_x+8) & ~(8-1);
    } else if (c == '\r') {
          cursor_x = 0;
    } else if (c == '\n') {
        cursor_x = 0;
c01001dc:	c6 05 c1 a0 10 c0 00 	movb   $0x0,0xc010a0c1
        cursor_y++;
c01001e3:	8d 50 01             	lea    0x1(%eax),%edx
c01001e6:	88 15 c0 a0 10 c0    	mov    %dl,0xc010a0c0
c01001ec:	eb a0                	jmp    c010018e <console_putc_color+0x13e>
c01001ee:	66 90                	xchg   %ax,%ax

c01001f0 <number>:
		__res; })

static char *number(
    char *str, int num, int base, 
    int size, int precision, int type)
{
c01001f0:	55                   	push   %ebp
c01001f1:	89 e5                	mov    %esp,%ebp
c01001f3:	57                   	push   %edi
	char c, sign, tmp[36];
	const char *digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
c01001f4:	bf 20 1b 10 c0       	mov    $0xc0101b20,%edi
		__res; })

static char *number(
    char *str, int num, int base, 
    int size, int precision, int type)
{
c01001f9:	56                   	push   %esi
c01001fa:	53                   	push   %ebx
c01001fb:	89 c3                	mov    %eax,%ebx
c01001fd:	83 ec 50             	sub    $0x50,%esp
c0100200:	89 d0                	mov    %edx,%eax
	char c, sign, tmp[36];
	const char *digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
c0100202:	f6 45 10 40          	testb  $0x40,0x10(%ebp)
c0100206:	ba 48 1b 10 c0       	mov    $0xc0101b48,%edx
c010020b:	0f 45 fa             	cmovne %edx,%edi

	if (type & SMALL) {
		digits ="0123456789abcdefghijklmnopqrstuvwxyz";
	}
	if (type & LEFT) {
		type &= ~ZEROPAD;
c010020e:	8b 55 10             	mov    0x10(%ebp),%edx
c0100211:	83 e2 fe             	and    $0xfffffffe,%edx
c0100214:	f6 45 10 10          	testb  $0x10,0x10(%ebp)
c0100218:	0f 44 55 10          	cmove  0x10(%ebp),%edx
c010021c:	89 55 10             	mov    %edx,0x10(%ebp)
	}
	if (base < 2 || base > 36) {
c010021f:	8d 51 fe             	lea    -0x2(%ecx),%edx
c0100222:	83 fa 22             	cmp    $0x22,%edx
c0100225:	0f 87 db 01 00 00    	ja     c0100406 <number+0x216>
		return 0;
	}

	c = (type & ZEROPAD) ? '0' : ' ' ;
c010022b:	8b 55 10             	mov    0x10(%ebp),%edx
c010022e:	83 e2 01             	and    $0x1,%edx
c0100231:	83 fa 01             	cmp    $0x1,%edx
c0100234:	19 f6                	sbb    %esi,%esi
c0100236:	89 75 b0             	mov    %esi,-0x50(%ebp)
c0100239:	80 65 b0 f0          	andb   $0xf0,-0x50(%ebp)
c010023d:	80 45 b0 30          	addb   $0x30,-0x50(%ebp)

	if (type & SIGN && num < 0) {
c0100241:	f6 45 10 02          	testb  $0x2,0x10(%ebp)
c0100245:	74 08                	je     c010024f <number+0x5f>
c0100247:	85 c0                	test   %eax,%eax
c0100249:	0f 88 98 01 00 00    	js     c01003e7 <number+0x1f7>
		sign = '-';
		num = -num;
	} else {
		sign = (type&PLUS) ? '+' : ((type&SPACE) ? ' ' : 0);
c010024f:	f6 45 10 04          	testb  $0x4,0x10(%ebp)
c0100253:	0f 84 4f 01 00 00    	je     c01003a8 <number+0x1b8>
c0100259:	c6 45 ab 2b          	movb   $0x2b,-0x55(%ebp)
	}

	if (sign) {
	      size--;
c010025d:	83 6d 08 01          	subl   $0x1,0x8(%ebp)
	}
	if (type & SPECIAL) {
c0100261:	8b 75 10             	mov    0x10(%ebp),%esi
c0100264:	83 e6 20             	and    $0x20,%esi
c0100267:	89 75 a4             	mov    %esi,-0x5c(%ebp)
c010026a:	74 14                	je     c0100280 <number+0x90>
		if (base == 16) {
c010026c:	83 f9 10             	cmp    $0x10,%ecx
c010026f:	0f 84 7d 01 00 00    	je     c01003f2 <number+0x202>
			size -= 2;
		} else if (base == 8) {
			size--;
c0100275:	31 d2                	xor    %edx,%edx
c0100277:	83 f9 08             	cmp    $0x8,%ecx
c010027a:	0f 94 c2             	sete   %dl
c010027d:	29 55 08             	sub    %edx,0x8(%ebp)
		}
	}
	i = 0;
	if (num == 0) {
c0100280:	85 c0                	test   %eax,%eax
c0100282:	0f 85 30 01 00 00    	jne    c01003b8 <number+0x1c8>
		tmp[i++] = '0';
c0100288:	c6 45 d0 30          	movb   $0x30,-0x30(%ebp)
c010028c:	be 01 00 00 00       	mov    $0x1,%esi
c0100291:	c7 45 ac 00 00 00 00 	movl   $0x0,-0x54(%ebp)
	}

	if (i > precision) {
		precision = i;
	}
	size -= precision;
c0100298:	8b 45 08             	mov    0x8(%ebp),%eax
c010029b:	89 f2                	mov    %esi,%edx
c010029d:	3b 75 0c             	cmp    0xc(%ebp),%esi
c01002a0:	0f 4c 55 0c          	cmovl  0xc(%ebp),%edx
c01002a4:	29 d0                	sub    %edx,%eax

	if (!(type&(ZEROPAD+LEFT))) {
c01002a6:	f6 45 10 11          	testb  $0x11,0x10(%ebp)
c01002aa:	89 55 c0             	mov    %edx,-0x40(%ebp)
c01002ad:	75 24                	jne    c01002d3 <number+0xe3>
		while (size-- > 0) {
c01002af:	85 c0                	test   %eax,%eax
c01002b1:	8d 50 ff             	lea    -0x1(%eax),%edx
c01002b4:	0f 8e 77 01 00 00    	jle    c0100431 <number+0x241>
c01002ba:	8b 55 c0             	mov    -0x40(%ebp),%edx
c01002bd:	01 d8                	add    %ebx,%eax
c01002bf:	90                   	nop
			*str++ = ' ';
c01002c0:	83 c3 01             	add    $0x1,%ebx
		precision = i;
	}
	size -= precision;

	if (!(type&(ZEROPAD+LEFT))) {
		while (size-- > 0) {
c01002c3:	39 c3                	cmp    %eax,%ebx
			*str++ = ' ';
c01002c5:	c6 43 ff 20          	movb   $0x20,-0x1(%ebx)
		precision = i;
	}
	size -= precision;

	if (!(type&(ZEROPAD+LEFT))) {
		while (size-- > 0) {
c01002c9:	75 f5                	jne    c01002c0 <number+0xd0>
c01002cb:	89 55 c0             	mov    %edx,-0x40(%ebp)
c01002ce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
			*str++ = ' ';
		}
	}
	if (sign) {
c01002d3:	80 7d ab 00          	cmpb   $0x0,-0x55(%ebp)
c01002d7:	74 0a                	je     c01002e3 <number+0xf3>
		*str++ = sign;
c01002d9:	0f b6 55 ab          	movzbl -0x55(%ebp),%edx
c01002dd:	83 c3 01             	add    $0x1,%ebx
c01002e0:	88 53 ff             	mov    %dl,-0x1(%ebx)
	}
	if (type & SPECIAL) {
c01002e3:	8b 55 a4             	mov    -0x5c(%ebp),%edx
c01002e6:	85 d2                	test   %edx,%edx
c01002e8:	74 12                	je     c01002fc <number+0x10c>
		if (base == 8) {
c01002ea:	83 f9 08             	cmp    $0x8,%ecx
c01002ed:	0f 84 08 01 00 00    	je     c01003fb <number+0x20b>
			*str++ = '0';
		} else if (base == 16) {
c01002f3:	83 f9 10             	cmp    $0x10,%ecx
c01002f6:	0f 84 14 01 00 00    	je     c0100410 <number+0x220>
			*str++ = '0';
			*str++ = digits[33];
		}
	}
	if (!(type&LEFT)) {
c01002fc:	f6 45 10 10          	testb  $0x10,0x10(%ebp)
c0100300:	75 28                	jne    c010032a <number+0x13a>
		while (size-- > 0) {
c0100302:	85 c0                	test   %eax,%eax
c0100304:	8d 48 ff             	lea    -0x1(%eax),%ecx
c0100307:	0f 8e 2b 01 00 00    	jle    c0100438 <number+0x248>
c010030d:	8b 55 c0             	mov    -0x40(%ebp),%edx
c0100310:	01 d8                	add    %ebx,%eax
c0100312:	0f b6 4d b0          	movzbl -0x50(%ebp),%ecx
c0100316:	66 90                	xchg   %ax,%ax
			*str++ = c;
c0100318:	83 c3 01             	add    $0x1,%ebx
			*str++ = '0';
			*str++ = digits[33];
		}
	}
	if (!(type&LEFT)) {
		while (size-- > 0) {
c010031b:	39 c3                	cmp    %eax,%ebx
			*str++ = c;
c010031d:	88 4b ff             	mov    %cl,-0x1(%ebx)
			*str++ = '0';
			*str++ = digits[33];
		}
	}
	if (!(type&LEFT)) {
		while (size-- > 0) {
c0100320:	75 f6                	jne    c0100318 <number+0x128>
c0100322:	89 55 c0             	mov    %edx,-0x40(%ebp)
c0100325:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
			*str++ = c;
		}
	}
	while (i < precision--) {
c010032a:	39 75 c0             	cmp    %esi,-0x40(%ebp)
c010032d:	0f 8e f7 00 00 00    	jle    c010042a <number+0x23a>
c0100333:	8b 7d c0             	mov    -0x40(%ebp),%edi
c0100336:	29 f7                	sub    %esi,%edi
c0100338:	01 df                	add    %ebx,%edi
c010033a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
		*str++ = '0';
c0100340:	83 c3 01             	add    $0x1,%ebx
	if (!(type&LEFT)) {
		while (size-- > 0) {
			*str++ = c;
		}
	}
	while (i < precision--) {
c0100343:	39 fb                	cmp    %edi,%ebx
		*str++ = '0';
c0100345:	c6 43 ff 30          	movb   $0x30,-0x1(%ebx)
	if (!(type&LEFT)) {
		while (size-- > 0) {
			*str++ = c;
		}
	}
	while (i < precision--) {
c0100349:	75 f5                	jne    c0100340 <number+0x150>
c010034b:	8b 75 ac             	mov    -0x54(%ebp),%esi
c010034e:	8d 5d d0             	lea    -0x30(%ebp),%ebx
c0100351:	89 f9                	mov    %edi,%ecx
c0100353:	8d 14 33             	lea    (%ebx,%esi,1),%edx
c0100356:	be 01 00 00 00       	mov    $0x1,%esi
c010035b:	29 de                	sub    %ebx,%esi
c010035d:	8d 76 00             	lea    0x0(%esi),%esi
		*str++ = '0';
	}
	while (i-- > 0) {
		*str++ = tmp[i];
c0100360:	0f b6 1a             	movzbl (%edx),%ebx
c0100363:	83 c1 01             	add    $0x1,%ecx
c0100366:	83 ea 01             	sub    $0x1,%edx
c0100369:	88 59 ff             	mov    %bl,-0x1(%ecx)
c010036c:	8d 1c 16             	lea    (%esi,%edx,1),%ebx
		}
	}
	while (i < precision--) {
		*str++ = '0';
	}
	while (i-- > 0) {
c010036f:	85 db                	test   %ebx,%ebx
c0100371:	7f ed                	jg     c0100360 <number+0x170>
c0100373:	8b 75 ac             	mov    -0x54(%ebp),%esi
c0100376:	31 d2                	xor    %edx,%edx
c0100378:	85 f6                	test   %esi,%esi
c010037a:	0f 49 d6             	cmovns %esi,%edx
		*str++ = tmp[i];
	}
	while (size-- > 0) {
c010037d:	85 c0                	test   %eax,%eax
c010037f:	8d 54 17 01          	lea    0x1(%edi,%edx,1),%edx
c0100383:	0f 8e 9a 00 00 00    	jle    c0100423 <number+0x233>
c0100389:	01 d0                	add    %edx,%eax
c010038b:	90                   	nop
c010038c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
		*str++ = ' ';
c0100390:	83 c2 01             	add    $0x1,%edx
		*str++ = '0';
	}
	while (i-- > 0) {
		*str++ = tmp[i];
	}
	while (size-- > 0) {
c0100393:	39 c2                	cmp    %eax,%edx
		*str++ = ' ';
c0100395:	c6 42 ff 20          	movb   $0x20,-0x1(%edx)
		*str++ = '0';
	}
	while (i-- > 0) {
		*str++ = tmp[i];
	}
	while (size-- > 0) {
c0100399:	75 f5                	jne    c0100390 <number+0x1a0>
		*str++ = ' ';
	}

	return str;
}
c010039b:	83 c4 50             	add    $0x50,%esp
c010039e:	5b                   	pop    %ebx
c010039f:	5e                   	pop    %esi
c01003a0:	5f                   	pop    %edi
c01003a1:	5d                   	pop    %ebp
c01003a2:	c3                   	ret    
c01003a3:	90                   	nop
c01003a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

	if (type & SIGN && num < 0) {
		sign = '-';
		num = -num;
	} else {
		sign = (type&PLUS) ? '+' : ((type&SPACE) ? ' ' : 0);
c01003a8:	f6 45 10 08          	testb  $0x8,0x10(%ebp)
c01003ac:	74 30                	je     c01003de <number+0x1ee>
c01003ae:	c6 45 ab 20          	movb   $0x20,-0x55(%ebp)
c01003b2:	e9 a6 fe ff ff       	jmp    c010025d <number+0x6d>
c01003b7:	90                   	nop
		} else if (base == 8) {
			size--;
		}
	}
	i = 0;
	if (num == 0) {
c01003b8:	31 f6                	xor    %esi,%esi
c01003ba:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
		tmp[i++] = '0';
	} else {
		while (num != 0) {
			tmp[i++] = digits[do_div(num,base)];
c01003c0:	31 d2                	xor    %edx,%edx
c01003c2:	83 c6 01             	add    $0x1,%esi
c01003c5:	f7 f1                	div    %ecx
c01003c7:	0f b6 14 17          	movzbl (%edi,%edx,1),%edx
	}
	i = 0;
	if (num == 0) {
		tmp[i++] = '0';
	} else {
		while (num != 0) {
c01003cb:	85 c0                	test   %eax,%eax
			tmp[i++] = digits[do_div(num,base)];
c01003cd:	88 54 35 cf          	mov    %dl,-0x31(%ebp,%esi,1)
	}
	i = 0;
	if (num == 0) {
		tmp[i++] = '0';
	} else {
		while (num != 0) {
c01003d1:	75 ed                	jne    c01003c0 <number+0x1d0>
c01003d3:	8d 46 ff             	lea    -0x1(%esi),%eax
c01003d6:	89 45 ac             	mov    %eax,-0x54(%ebp)
c01003d9:	e9 ba fe ff ff       	jmp    c0100298 <number+0xa8>

	if (type & SIGN && num < 0) {
		sign = '-';
		num = -num;
	} else {
		sign = (type&PLUS) ? '+' : ((type&SPACE) ? ' ' : 0);
c01003de:	c6 45 ab 00          	movb   $0x0,-0x55(%ebp)
c01003e2:	e9 7a fe ff ff       	jmp    c0100261 <number+0x71>

	c = (type & ZEROPAD) ? '0' : ' ' ;

	if (type & SIGN && num < 0) {
		sign = '-';
		num = -num;
c01003e7:	f7 d8                	neg    %eax
	}

	c = (type & ZEROPAD) ? '0' : ' ' ;

	if (type & SIGN && num < 0) {
		sign = '-';
c01003e9:	c6 45 ab 2d          	movb   $0x2d,-0x55(%ebp)
		num = -num;
c01003ed:	e9 6b fe ff ff       	jmp    c010025d <number+0x6d>
	if (sign) {
	      size--;
	}
	if (type & SPECIAL) {
		if (base == 16) {
			size -= 2;
c01003f2:	83 6d 08 02          	subl   $0x2,0x8(%ebp)
c01003f6:	e9 85 fe ff ff       	jmp    c0100280 <number+0x90>
	if (sign) {
		*str++ = sign;
	}
	if (type & SPECIAL) {
		if (base == 8) {
			*str++ = '0';
c01003fb:	c6 03 30             	movb   $0x30,(%ebx)
c01003fe:	83 c3 01             	add    $0x1,%ebx
c0100401:	e9 f6 fe ff ff       	jmp    c01002fc <number+0x10c>
	while (size-- > 0) {
		*str++ = ' ';
	}

	return str;
}
c0100406:	83 c4 50             	add    $0x50,%esp
	}
	if (type & LEFT) {
		type &= ~ZEROPAD;
	}
	if (base < 2 || base > 36) {
		return 0;
c0100409:	31 c0                	xor    %eax,%eax
	while (size-- > 0) {
		*str++ = ' ';
	}

	return str;
}
c010040b:	5b                   	pop    %ebx
c010040c:	5e                   	pop    %esi
c010040d:	5f                   	pop    %edi
c010040e:	5d                   	pop    %ebp
c010040f:	c3                   	ret    
	if (type & SPECIAL) {
		if (base == 8) {
			*str++ = '0';
		} else if (base == 16) {
			*str++ = '0';
			*str++ = digits[33];
c0100410:	0f b6 4f 21          	movzbl 0x21(%edi),%ecx
c0100414:	83 c3 02             	add    $0x2,%ebx
	}
	if (type & SPECIAL) {
		if (base == 8) {
			*str++ = '0';
		} else if (base == 16) {
			*str++ = '0';
c0100417:	c6 43 fe 30          	movb   $0x30,-0x2(%ebx)
			*str++ = digits[33];
c010041b:	88 4b ff             	mov    %cl,-0x1(%ebx)
c010041e:	e9 d9 fe ff ff       	jmp    c01002fc <number+0x10c>
		*str++ = '0';
	}
	while (i-- > 0) {
		*str++ = tmp[i];
	}
	while (size-- > 0) {
c0100423:	89 d0                	mov    %edx,%eax
c0100425:	e9 71 ff ff ff       	jmp    c010039b <number+0x1ab>
	if (!(type&LEFT)) {
		while (size-- > 0) {
			*str++ = c;
		}
	}
	while (i < precision--) {
c010042a:	89 df                	mov    %ebx,%edi
c010042c:	e9 1a ff ff ff       	jmp    c010034b <number+0x15b>
		precision = i;
	}
	size -= precision;

	if (!(type&(ZEROPAD+LEFT))) {
		while (size-- > 0) {
c0100431:	89 d0                	mov    %edx,%eax
c0100433:	e9 9b fe ff ff       	jmp    c01002d3 <number+0xe3>
			*str++ = '0';
			*str++ = digits[33];
		}
	}
	if (!(type&LEFT)) {
		while (size-- > 0) {
c0100438:	89 c8                	mov    %ecx,%eax
c010043a:	e9 eb fe ff ff       	jmp    c010032a <number+0x13a>
c010043f:	90                   	nop

c0100440 <kbd_getc>:

static inline uint8_t inb(uint16_t port)
{
    uint8_t data;

    asm volatile("in %1,%0" : "=a" (data) : "d" (port));
c0100440:	ba 64 00 00 00       	mov    $0x64,%edx
c0100445:	ec                   	in     (%dx),%al
		normalmap, shiftmap, ctlmap, ctlmap
	};
	uint32_t st, data, c;

	st = inb(KBSTATP);
	if((st & KBS_DIB) == 0)
c0100446:	a8 01                	test   $0x1,%al
c0100448:	0f 84 ba 00 00 00    	je     c0100508 <kbd_getc+0xc8>
c010044e:	b2 60                	mov    $0x60,%dl
c0100450:	ec                   	in     (%dx),%al
		return -1;
	data = inb(KBDATAP);
c0100451:	0f b6 c8             	movzbl %al,%ecx

	if(data == 0xE0){
c0100454:	81 f9 e0 00 00 00    	cmp    $0xe0,%ecx
c010045a:	0f 84 88 00 00 00    	je     c01004e8 <kbd_getc+0xa8>
		shift |= E0ESC;
		return 0;
	} 
	else if(data & 0x80) {
c0100460:	84 c0                	test   %al,%al
c0100462:	79 2c                	jns    c0100490 <kbd_getc+0x50>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
c0100464:	8b 15 a4 50 10 c0    	mov    0xc01050a4,%edx
c010046a:	f6 c2 40             	test   $0x40,%dl
c010046d:	75 05                	jne    c0100474 <kbd_getc+0x34>
c010046f:	89 c1                	mov    %eax,%ecx
c0100471:	83 e1 7f             	and    $0x7f,%ecx
		shift &= ~(shiftcode[data] | E0ESC);
c0100474:	0f b6 81 60 1d 10 c0 	movzbl -0x3fefe2a0(%ecx),%eax
c010047b:	83 c8 40             	or     $0x40,%eax
c010047e:	0f b6 c0             	movzbl %al,%eax
c0100481:	f7 d0                	not    %eax
c0100483:	21 d0                	and    %edx,%eax
c0100485:	a3 a4 50 10 c0       	mov    %eax,0xc01050a4
		return 0;
c010048a:	31 c0                	xor    %eax,%eax
c010048c:	c3                   	ret    
c010048d:	8d 76 00             	lea    0x0(%esi),%esi
	// 	procdump();  // now call procdump() wo. cons_lock.lock held
	// }
}

static int kbd_getc(void)
{
c0100490:	55                   	push   %ebp
c0100491:	89 e5                	mov    %esp,%ebp
c0100493:	53                   	push   %ebx
c0100494:	8b 1d a4 50 10 c0    	mov    0xc01050a4,%ebx
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
		shift &= ~(shiftcode[data] | E0ESC);
		return 0;
	} 
	else if(shift & E0ESC) {
c010049a:	f6 c3 40             	test   $0x40,%bl
c010049d:	74 09                	je     c01004a8 <kbd_getc+0x68>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
c010049f:	83 c8 80             	or     $0xffffff80,%eax
		shift &= ~E0ESC;
c01004a2:	83 e3 bf             	and    $0xffffffbf,%ebx
		shift &= ~(shiftcode[data] | E0ESC);
		return 0;
	} 
	else if(shift & E0ESC) {
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
c01004a5:	0f b6 c8             	movzbl %al,%ecx
		shift &= ~E0ESC;
	}

	shift |= shiftcode[data];
c01004a8:	0f b6 91 60 1d 10 c0 	movzbl -0x3fefe2a0(%ecx),%edx
	shift ^= togglecode[data];
c01004af:	0f b6 81 60 1c 10 c0 	movzbl -0x3fefe3a0(%ecx),%eax
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
		shift &= ~E0ESC;
	}

	shift |= shiftcode[data];
c01004b6:	09 da                	or     %ebx,%edx
	shift ^= togglecode[data];
c01004b8:	31 c2                	xor    %eax,%edx
	c = charcode[shift & (CTL | SHIFT)][data];
c01004ba:	89 d0                	mov    %edx,%eax
c01004bc:	83 e0 03             	and    $0x3,%eax
c01004bf:	8b 04 85 48 1c 10 c0 	mov    -0x3fefe3b8(,%eax,4),%eax
		data |= 0x80;
		shift &= ~E0ESC;
	}

	shift |= shiftcode[data];
	shift ^= togglecode[data];
c01004c6:	89 15 a4 50 10 c0    	mov    %edx,0xc01050a4
	c = charcode[shift & (CTL | SHIFT)][data];
	if(shift & CAPSLOCK){
c01004cc:	83 e2 08             	and    $0x8,%edx
		shift &= ~E0ESC;
	}

	shift |= shiftcode[data];
	shift ^= togglecode[data];
	c = charcode[shift & (CTL | SHIFT)][data];
c01004cf:	0f b6 04 08          	movzbl (%eax,%ecx,1),%eax
	if(shift & CAPSLOCK){
c01004d3:	74 0b                	je     c01004e0 <kbd_getc+0xa0>
		if('a' <= c && c <= 'z')
c01004d5:	8d 50 9f             	lea    -0x61(%eax),%edx
c01004d8:	83 fa 19             	cmp    $0x19,%edx
c01004db:	77 1b                	ja     c01004f8 <kbd_getc+0xb8>
		c += 'A' - 'a';
c01004dd:	83 e8 20             	sub    $0x20,%eax
		else if('A' <= c && c <= 'Z')
		c += 'a' - 'A';
	}
	return c;
}
c01004e0:	5b                   	pop    %ebx
c01004e1:	5d                   	pop    %ebp
c01004e2:	c3                   	ret    
c01004e3:	90                   	nop
c01004e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
	if((st & KBS_DIB) == 0)
		return -1;
	data = inb(KBDATAP);

	if(data == 0xE0){
		shift |= E0ESC;
c01004e8:	83 0d a4 50 10 c0 40 	orl    $0x40,0xc01050a4
		return 0;
c01004ef:	31 c0                	xor    %eax,%eax
c01004f1:	c3                   	ret    
c01004f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
	shift ^= togglecode[data];
	c = charcode[shift & (CTL | SHIFT)][data];
	if(shift & CAPSLOCK){
		if('a' <= c && c <= 'z')
		c += 'A' - 'a';
		else if('A' <= c && c <= 'Z')
c01004f8:	8d 48 bf             	lea    -0x41(%eax),%ecx
		c += 'a' - 'A';
c01004fb:	8d 50 20             	lea    0x20(%eax),%edx
c01004fe:	83 f9 19             	cmp    $0x19,%ecx
c0100501:	0f 46 c2             	cmovbe %edx,%eax
	}
	return c;
c0100504:	eb da                	jmp    c01004e0 <kbd_getc+0xa0>
c0100506:	66 90                	xchg   %ax,%ax
	};
	uint32_t st, data, c;

	st = inb(KBSTATP);
	if((st & KBS_DIB) == 0)
		return -1;
c0100508:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c010050d:	c3                   	ret    
c010050e:	66 90                	xchg   %ax,%ax

c0100510 <vsprintf>:

	return str;
}

static int vsprintf(char *buff, const char *format, va_list args)
{
c0100510:	55                   	push   %ebp
c0100511:	89 e5                	mov    %esp,%ebp
c0100513:	57                   	push   %edi
c0100514:	89 c7                	mov    %eax,%edi
c0100516:	56                   	push   %esi
c0100517:	89 d6                	mov    %edx,%esi
c0100519:	53                   	push   %ebx
c010051a:	83 ec 2c             	sub    $0x2c,%esp
	int *ip;
	int flags;              // flags to number()
	int field_width;        // width of output field
	int precision;          // min. # of digits for integers; max number of chars for from string

	for (str = buff ; *format ; ++format) {
c010051d:	0f b6 02             	movzbl (%edx),%eax

	return str;
}

static int vsprintf(char *buff, const char *format, va_list args)
{
c0100520:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	int *ip;
	int flags;              // flags to number()
	int field_width;        // width of output field
	int precision;          // min. # of digits for integers; max number of chars for from string

	for (str = buff ; *format ; ++format) {
c0100523:	84 c0                	test   %al,%al
c0100525:	0f 84 e2 03 00 00    	je     c010090d <vsprintf+0x3fd>
c010052b:	89 7d dc             	mov    %edi,-0x24(%ebp)
c010052e:	eb 14                	jmp    c0100544 <vsprintf+0x34>
		if (*format != '%') {
			*str++ = *format;
c0100530:	88 07                	mov    %al,(%edi)
c0100532:	0f b6 46 01          	movzbl 0x1(%esi),%eax
c0100536:	83 c7 01             	add    $0x1,%edi
	int *ip;
	int flags;              // flags to number()
	int field_width;        // width of output field
	int precision;          // min. # of digits for integers; max number of chars for from string

	for (str = buff ; *format ; ++format) {
c0100539:	83 c6 01             	add    $0x1,%esi
c010053c:	84 c0                	test   %al,%al
c010053e:	0f 84 04 01 00 00    	je     c0100648 <vsprintf+0x138>
		if (*format != '%') {
c0100544:	31 c9                	xor    %ecx,%ecx
c0100546:	3c 25                	cmp    $0x25,%al
c0100548:	75 e6                	jne    c0100530 <vsprintf+0x20>
c010054a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
c0100550:	83 c6 01             	add    $0x1,%esi
			continue;
		} 
		flags = 0;
		repeat:
			++format;               // this also skips first '%'
			switch (*format) {
c0100553:	0f be 06             	movsbl (%esi),%eax
c0100556:	8d 50 e0             	lea    -0x20(%eax),%edx
c0100559:	80 fa 10             	cmp    $0x10,%dl
c010055c:	77 22                	ja     c0100580 <vsprintf+0x70>
c010055e:	0f b6 d2             	movzbl %dl,%edx
c0100561:	ff 24 95 80 1b 10 c0 	jmp    *-0x3fefe480(,%edx,4)
c0100568:	83 c6 01             	add    $0x1,%esi
c010056b:	0f be 06             	movsbl (%esi),%eax
					  goto repeat;
				case ' ': flags |= SPACE;
					  goto repeat;
				case '#': flags |= SPECIAL;
					  goto repeat;
				case '0': flags |= ZEROPAD;
c010056e:	83 c9 01             	or     $0x1,%ecx
			continue;
		} 
		flags = 0;
		repeat:
			++format;               // this also skips first '%'
			switch (*format) {
c0100571:	8d 50 e0             	lea    -0x20(%eax),%edx
c0100574:	80 fa 10             	cmp    $0x10,%dl
c0100577:	76 e5                	jbe    c010055e <vsprintf+0x4e>
c0100579:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
					  goto repeat;
			}
		
		// get field width
		field_width = -1;
		if (is_digit(*format)) {
c0100580:	8d 50 d0             	lea    -0x30(%eax),%edx
c0100583:	80 fa 09             	cmp    $0x9,%dl
c0100586:	0f 87 4c 01 00 00    	ja     c01006d8 <vsprintf+0x1c8>
c010058c:	31 d2                	xor    %edx,%edx
c010058e:	66 90                	xchg   %ax,%ax
c0100590:	83 c6 01             	add    $0x1,%esi
static int skip_atoi(const char **s)
{
	int i = 0;

	while (is_digit(**s)) {
		i = i * 10 + *((*s)++) - '0';
c0100593:	8d 14 92             	lea    (%edx,%edx,4),%edx
c0100596:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx

static int skip_atoi(const char **s)
{
	int i = 0;

	while (is_digit(**s)) {
c010059a:	0f be 06             	movsbl (%esi),%eax
c010059d:	8d 58 d0             	lea    -0x30(%eax),%ebx
c01005a0:	80 fb 09             	cmp    $0x9,%bl
c01005a3:	76 eb                	jbe    c0100590 <vsprintf+0x80>
c01005a5:	89 c3                	mov    %eax,%ebx
			}
		}

		// get the precision
		precision = -1;
		if (*format == '.') {
c01005a7:	3c 2e                	cmp    $0x2e,%al
				flags |= LEFT;
			}
		}

		// get the precision
		precision = -1;
c01005a9:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		if (*format == '.') {
c01005b0:	0f 84 62 01 00 00    	je     c0100718 <vsprintf+0x208>
			}
		}

		// get the conversion qualifier
		//int qualifier = -1;   // 'h', 'l', or 'L' for integer fields
		if (*format == 'h' || *format == 'l' || *format == 'L') {
c01005b6:	80 fb 68             	cmp    $0x68,%bl
c01005b9:	0f 85 d9 00 00 00    	jne    c0100698 <vsprintf+0x188>
c01005bf:	0f b6 5e 01          	movzbl 0x1(%esi),%ebx
			//qualifier = *format;
			++format;
c01005c3:	83 c6 01             	add    $0x1,%esi
		}

		switch (*format) {
c01005c6:	8d 43 a8             	lea    -0x58(%ebx),%eax
c01005c9:	3c 20                	cmp    $0x20,%al
c01005cb:	0f 87 df 00 00 00    	ja     c01006b0 <vsprintf+0x1a0>
c01005d1:	0f b6 c0             	movzbl %al,%eax
c01005d4:	ff 24 85 c4 1b 10 c0 	jmp    *-0x3fefe43c(,%eax,4)
c01005db:	90                   	nop
c01005dc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
		} 
		flags = 0;
		repeat:
			++format;               // this also skips first '%'
			switch (*format) {
				case '-': flags |= LEFT;
c01005e0:	83 c9 10             	or     $0x10,%ecx
					  goto repeat;
c01005e3:	e9 68 ff ff ff       	jmp    c0100550 <vsprintf+0x40>
				case '+': flags |= PLUS;
c01005e8:	83 c9 04             	or     $0x4,%ecx
					  goto repeat;
c01005eb:	e9 60 ff ff ff       	jmp    c0100550 <vsprintf+0x40>
				case ' ': flags |= SPACE;
					  goto repeat;
				case '#': flags |= SPECIAL;
c01005f0:	83 c9 20             	or     $0x20,%ecx
					  goto repeat;
c01005f3:	e9 58 ff ff ff       	jmp    c0100550 <vsprintf+0x40>
			switch (*format) {
				case '-': flags |= LEFT;
					  goto repeat;
				case '+': flags |= PLUS;
					  goto repeat;
				case ' ': flags |= SPACE;
c01005f8:	83 c9 08             	or     $0x8,%ecx
					  goto repeat;
c01005fb:	e9 50 ff ff ff       	jmp    c0100550 <vsprintf+0x40>
			str = number(str, va_arg(args, unsigned long), 8,
				field_width, precision, flags);
			break;

		case 'p':
			if (field_width == -1) {
c0100600:	83 fa ff             	cmp    $0xffffffff,%edx
c0100603:	75 0b                	jne    c0100610 <vsprintf+0x100>
				field_width = 8;
				flags |= ZEROPAD;
c0100605:	83 c9 01             	or     $0x1,%ecx
				field_width, precision, flags);
			break;

		case 'p':
			if (field_width == -1) {
				field_width = 8;
c0100608:	ba 08 00 00 00       	mov    $0x8,%edx
c010060d:	8d 76 00             	lea    0x0(%esi),%esi
				flags |= ZEROPAD;
			}
			str = number(str, (unsigned long) va_arg(args, void *), 16,
c0100610:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0100613:	89 4c 24 08          	mov    %ecx,0x8(%esp)
c0100617:	8b 4d e0             	mov    -0x20(%ebp),%ecx
c010061a:	89 14 24             	mov    %edx,(%esp)
c010061d:	8d 58 04             	lea    0x4(%eax),%ebx
c0100620:	89 4c 24 04          	mov    %ecx,0x4(%esp)
c0100624:	b9 10 00 00 00       	mov    $0x10,%ecx
c0100629:	8b 10                	mov    (%eax),%edx
c010062b:	89 f8                	mov    %edi,%eax
	int *ip;
	int flags;              // flags to number()
	int field_width;        // width of output field
	int precision;          // min. # of digits for integers; max number of chars for from string

	for (str = buff ; *format ; ++format) {
c010062d:	83 c6 01             	add    $0x1,%esi
		case 'p':
			if (field_width == -1) {
				field_width = 8;
				flags |= ZEROPAD;
			}
			str = number(str, (unsigned long) va_arg(args, void *), 16,
c0100630:	e8 bb fb ff ff       	call   c01001f0 <number>
c0100635:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
c0100638:	89 c7                	mov    %eax,%edi
c010063a:	0f b6 06             	movzbl (%esi),%eax
	int *ip;
	int flags;              // flags to number()
	int field_width;        // width of output field
	int precision;          // min. # of digits for integers; max number of chars for from string

	for (str = buff ; *format ; ++format) {
c010063d:	84 c0                	test   %al,%al
c010063f:	0f 85 ff fe ff ff    	jne    c0100544 <vsprintf+0x34>
c0100645:	8d 76 00             	lea    0x0(%esi),%esi
c0100648:	89 f8                	mov    %edi,%eax
c010064a:	2b 45 dc             	sub    -0x24(%ebp),%eax
				--format;
			}
			break;
		}
	}
	*str = '\0';
c010064d:	c6 07 00             	movb   $0x0,(%edi)

	return (str -buff);
}
c0100650:	83 c4 2c             	add    $0x2c,%esp
c0100653:	5b                   	pop    %ebx
c0100654:	5e                   	pop    %esi
c0100655:	5f                   	pop    %edi
c0100656:	5d                   	pop    %ebp
c0100657:	c3                   	ret    
				field_width, precision, flags);
			break;

		case 'd':
		case 'i':
			flags |= SIGN;
c0100658:	83 c9 02             	or     $0x2,%ecx
		case 'u':
			str = number(str, va_arg(args, unsigned long), 10,
c010065b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010065e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
c0100662:	8b 4d e0             	mov    -0x20(%ebp),%ecx
c0100665:	89 14 24             	mov    %edx,(%esp)
c0100668:	8d 58 04             	lea    0x4(%eax),%ebx
c010066b:	89 4c 24 04          	mov    %ecx,0x4(%esp)
c010066f:	b9 0a 00 00 00       	mov    $0xa,%ecx
c0100674:	eb b3                	jmp    c0100629 <vsprintf+0x119>
			++format;       
			if (is_digit(*format)) {
				precision = skip_atoi(&format);
			} else if (*format == '*') {
				// it's the next argument
				precision = va_arg(args, int);
c0100676:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
c0100679:	89 d8                	mov    %ebx,%eax
c010067b:	8b 1b                	mov    (%ebx),%ebx
c010067d:	83 c0 04             	add    $0x4,%eax
			}
			if (precision < 0) {
c0100680:	85 db                	test   %ebx,%ebx
			++format;       
			if (is_digit(*format)) {
				precision = skip_atoi(&format);
			} else if (*format == '*') {
				// it's the next argument
				precision = va_arg(args, int);
c0100682:	89 5d e0             	mov    %ebx,-0x20(%ebp)
			}
			if (precision < 0) {
c0100685:	0f 88 a7 02 00 00    	js     c0100932 <vsprintf+0x422>
		}

		// get the precision
		precision = -1;
		if (*format == '.') {
			++format;       
c010068b:	8b 75 d8             	mov    -0x28(%ebp),%esi
c010068e:	bb 2a 00 00 00       	mov    $0x2a,%ebx
			if (is_digit(*format)) {
				precision = skip_atoi(&format);
			} else if (*format == '*') {
				// it's the next argument
				precision = va_arg(args, int);
c0100693:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0100696:	66 90                	xchg   %ax,%ax
			}
		}

		// get the conversion qualifier
		//int qualifier = -1;   // 'h', 'l', or 'L' for integer fields
		if (*format == 'h' || *format == 'l' || *format == 'L') {
c0100698:	89 d8                	mov    %ebx,%eax
c010069a:	83 e0 df             	and    $0xffffffdf,%eax
c010069d:	3c 4c                	cmp    $0x4c,%al
c010069f:	0f 84 1a ff ff ff    	je     c01005bf <vsprintf+0xaf>
			//qualifier = *format;
			++format;
		}

		switch (*format) {
c01006a5:	8d 43 a8             	lea    -0x58(%ebx),%eax
c01006a8:	3c 20                	cmp    $0x20,%al
c01006aa:	0f 86 21 ff ff ff    	jbe    c01005d1 <vsprintf+0xc1>
			ip = va_arg(args, int *);
			*ip = (str - buff);
			break;

		default:
			if (*format != '%')
c01006b0:	80 fb 25             	cmp    $0x25,%bl
c01006b3:	74 0f                	je     c01006c4 <vsprintf+0x1b4>
				*str++ = '%';
c01006b5:	c6 07 25             	movb   $0x25,(%edi)
c01006b8:	0f b6 1e             	movzbl (%esi),%ebx
c01006bb:	8d 47 01             	lea    0x1(%edi),%eax
c01006be:	89 c7                	mov    %eax,%edi
			if (*format) {
c01006c0:	84 db                	test   %bl,%bl
c01006c2:	74 84                	je     c0100648 <vsprintf+0x138>
				*str++ = *format;
c01006c4:	88 1f                	mov    %bl,(%edi)
c01006c6:	83 c7 01             	add    $0x1,%edi
c01006c9:	0f b6 46 01          	movzbl 0x1(%esi),%eax
c01006cd:	e9 67 fe ff ff       	jmp    c0100539 <vsprintf+0x29>
c01006d2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
		
		// get field width
		field_width = -1;
		if (is_digit(*format)) {
			field_width = skip_atoi(&format);
		} else if (*format == '*') {
c01006d8:	3c 2a                	cmp    $0x2a,%al
c01006da:	89 c3                	mov    %eax,%ebx
				case '0': flags |= ZEROPAD;
					  goto repeat;
			}
		
		// get field width
		field_width = -1;
c01006dc:	ba ff ff ff ff       	mov    $0xffffffff,%edx
		if (is_digit(*format)) {
			field_width = skip_atoi(&format);
		} else if (*format == '*') {
c01006e1:	0f 85 c0 fe ff ff    	jne    c01005a7 <vsprintf+0x97>
			// it's the next argument
			field_width = va_arg(args, int);
c01006e7:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
c01006ea:	8b 13                	mov    (%ebx),%edx
c01006ec:	89 d8                	mov    %ebx,%eax
c01006ee:	83 c0 04             	add    $0x4,%eax
			if (field_width < 0) {
c01006f1:	85 d2                	test   %edx,%edx
c01006f3:	0f 88 0a 02 00 00    	js     c0100903 <vsprintf+0x3f3>
			} else if (*format == '*') {
				// it's the next argument
				precision = va_arg(args, int);
			}
			if (precision < 0) {
				precision = 0;
c01006f9:	bb 2a 00 00 00       	mov    $0x2a,%ebx
c01006fe:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			}
		}

		// get the conversion qualifier
		//int qualifier = -1;   // 'h', 'l', or 'L' for integer fields
		if (*format == 'h' || *format == 'l' || *format == 'L') {
c0100701:	89 d8                	mov    %ebx,%eax
c0100703:	83 e0 df             	and    $0xffffffdf,%eax
c0100706:	3c 4c                	cmp    $0x4c,%al
				flags |= LEFT;
			}
		}

		// get the precision
		precision = -1;
c0100708:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
			}
		}

		// get the conversion qualifier
		//int qualifier = -1;   // 'h', 'l', or 'L' for integer fields
		if (*format == 'h' || *format == 'l' || *format == 'L') {
c010070f:	75 94                	jne    c01006a5 <vsprintf+0x195>
c0100711:	e9 a9 fe ff ff       	jmp    c01005bf <vsprintf+0xaf>
c0100716:	66 90                	xchg   %ax,%ax
		}

		// get the precision
		precision = -1;
		if (*format == '.') {
			++format;       
c0100718:	8d 46 01             	lea    0x1(%esi),%eax
c010071b:	89 45 d8             	mov    %eax,-0x28(%ebp)
			if (is_digit(*format)) {
c010071e:	0f be 46 01          	movsbl 0x1(%esi),%eax
c0100722:	8d 58 d0             	lea    -0x30(%eax),%ebx
c0100725:	80 fb 09             	cmp    $0x9,%bl
c0100728:	77 36                	ja     c0100760 <vsprintf+0x250>
c010072a:	31 db                	xor    %ebx,%ebx
c010072c:	8b 75 d8             	mov    -0x28(%ebp),%esi
c010072f:	89 55 d8             	mov    %edx,-0x28(%ebp)
c0100732:	89 da                	mov    %ebx,%edx
c0100734:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
c0100738:	83 c6 01             	add    $0x1,%esi
static int skip_atoi(const char **s)
{
	int i = 0;

	while (is_digit(**s)) {
		i = i * 10 + *((*s)++) - '0';
c010073b:	8d 14 92             	lea    (%edx,%edx,4),%edx
c010073e:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx

static int skip_atoi(const char **s)
{
	int i = 0;

	while (is_digit(**s)) {
c0100742:	0f be 06             	movsbl (%esi),%eax
c0100745:	8d 58 d0             	lea    -0x30(%eax),%ebx
c0100748:	80 fb 09             	cmp    $0x9,%bl
c010074b:	76 eb                	jbe    c0100738 <vsprintf+0x228>
c010074d:	89 55 e0             	mov    %edx,-0x20(%ebp)
c0100750:	89 c3                	mov    %eax,%ebx
c0100752:	8b 55 d8             	mov    -0x28(%ebp),%edx
c0100755:	e9 5c fe ff ff       	jmp    c01005b6 <vsprintf+0xa6>
c010075a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
		precision = -1;
		if (*format == '.') {
			++format;       
			if (is_digit(*format)) {
				precision = skip_atoi(&format);
			} else if (*format == '*') {
c0100760:	3c 2a                	cmp    $0x2a,%al
c0100762:	0f 84 0e ff ff ff    	je     c0100676 <vsprintf+0x166>
c0100768:	89 c3                	mov    %eax,%ebx
		}

		// get the precision
		precision = -1;
		if (*format == '.') {
			++format;       
c010076a:	8b 75 d8             	mov    -0x28(%ebp),%esi
			} else if (*format == '*') {
				// it's the next argument
				precision = va_arg(args, int);
			}
			if (precision < 0) {
				precision = 0;
c010076d:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
c0100774:	e9 3d fe ff ff       	jmp    c01005b6 <vsprintf+0xa6>
c0100779:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
			str = number(str, (unsigned long) va_arg(args, void *), 16,
				field_width, precision, flags);
			break;

		case 'x':
			flags |= SMALL;
c0100780:	83 c9 40             	or     $0x40,%ecx
c0100783:	e9 88 fe ff ff       	jmp    c0100610 <vsprintf+0x100>
				*str++ = ' ';
			}
			break;

		case 's':
			s = va_arg(args, char *);
c0100788:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010078b:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
c010078e:	89 55 d8             	mov    %edx,-0x28(%ebp)
c0100791:	8b 18                	mov    (%eax),%ebx
c0100793:	8d 48 04             	lea    0x4(%eax),%ecx
c0100796:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
			len = strlen(s);
c0100799:	89 1c 24             	mov    %ebx,(%esp)
c010079c:	e8 ef 0b 00 00       	call   c0101390 <strlen>
			if (precision < 0) {
c01007a1:	8b 55 d8             	mov    -0x28(%ebp),%edx
c01007a4:	83 7d e0 ff          	cmpl   $0xffffffff,-0x20(%ebp)
c01007a8:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
c01007ab:	74 07                	je     c01007b4 <vsprintf+0x2a4>
c01007ad:	3b 45 e0             	cmp    -0x20(%ebp),%eax
c01007b0:	0f 4f 45 e0          	cmovg  -0x20(%ebp),%eax
				precision = len;
			} else if (len > precision) {
				len = precision;
			}

			if (!(flags & LEFT)) {
c01007b4:	83 e1 10             	and    $0x10,%ecx
c01007b7:	75 2b                	jne    c01007e4 <vsprintf+0x2d4>
				while (len < field_width--) {
c01007b9:	8d 4a ff             	lea    -0x1(%edx),%ecx
c01007bc:	39 d0                	cmp    %edx,%eax
c01007be:	89 4d e0             	mov    %ecx,-0x20(%ebp)
c01007c1:	0f 8d 5f 01 00 00    	jge    c0100926 <vsprintf+0x416>
c01007c7:	89 d1                	mov    %edx,%ecx
c01007c9:	29 c1                	sub    %eax,%ecx
c01007cb:	01 f9                	add    %edi,%ecx
c01007cd:	8d 76 00             	lea    0x0(%esi),%esi
					*str++ = ' ';
c01007d0:	83 c7 01             	add    $0x1,%edi
			} else if (len > precision) {
				len = precision;
			}

			if (!(flags & LEFT)) {
				while (len < field_width--) {
c01007d3:	39 cf                	cmp    %ecx,%edi
					*str++ = ' ';
c01007d5:	c6 47 ff 20          	movb   $0x20,-0x1(%edi)
			} else if (len > precision) {
				len = precision;
			}

			if (!(flags & LEFT)) {
				while (len < field_width--) {
c01007d9:	75 f5                	jne    c01007d0 <vsprintf+0x2c0>
c01007db:	8b 4d e0             	mov    -0x20(%ebp),%ecx
c01007de:	29 d1                	sub    %edx,%ecx
c01007e0:	89 ca                	mov    %ecx,%edx
c01007e2:	01 c2                	add    %eax,%edx
					*str++ = ' ';
				}
			}
			for (i = 0; i < len; ++i) {
c01007e4:	85 c0                	test   %eax,%eax
c01007e6:	0f 8e 33 01 00 00    	jle    c010091f <vsprintf+0x40f>
c01007ec:	31 c9                	xor    %ecx,%ecx
c01007ee:	89 55 e0             	mov    %edx,-0x20(%ebp)
c01007f1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
				*str++ = *s++;
c01007f8:	0f b6 14 0b          	movzbl (%ebx,%ecx,1),%edx
c01007fc:	88 14 0f             	mov    %dl,(%edi,%ecx,1)
			if (!(flags & LEFT)) {
				while (len < field_width--) {
					*str++ = ' ';
				}
			}
			for (i = 0; i < len; ++i) {
c01007ff:	83 c1 01             	add    $0x1,%ecx
c0100802:	39 c1                	cmp    %eax,%ecx
c0100804:	75 f2                	jne    c01007f8 <vsprintf+0x2e8>
c0100806:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0100809:	8d 0c 07             	lea    (%edi,%eax,1),%ecx
c010080c:	89 d7                	mov    %edx,%edi
c010080e:	29 c7                	sub    %eax,%edi
c0100810:	01 cf                	add    %ecx,%edi
				*str++ = *s++;
			}
			while (len < field_width--) {
c0100812:	39 d0                	cmp    %edx,%eax
c0100814:	0f 8d fa 00 00 00    	jge    c0100914 <vsprintf+0x404>
c010081a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
				*str++ = ' ';
c0100820:	83 c1 01             	add    $0x1,%ecx
				}
			}
			for (i = 0; i < len; ++i) {
				*str++ = *s++;
			}
			while (len < field_width--) {
c0100823:	39 f9                	cmp    %edi,%ecx
				*str++ = ' ';
c0100825:	c6 41 ff 20          	movb   $0x20,-0x1(%ecx)
				}
			}
			for (i = 0; i < len; ++i) {
				*str++ = *s++;
			}
			while (len < field_width--) {
c0100829:	75 f5                	jne    c0100820 <vsprintf+0x310>
c010082b:	0f b6 46 01          	movzbl 0x1(%esi),%eax
c010082f:	e9 05 fd ff ff       	jmp    c0100539 <vsprintf+0x29>
c0100834:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
			++format;
		}

		switch (*format) {
		case 'c':
			if (!(flags & LEFT)) {
c0100838:	83 e1 10             	and    $0x10,%ecx
c010083b:	0f 85 8d 00 00 00    	jne    c01008ce <vsprintf+0x3be>
				while (--field_width > 0) {
c0100841:	83 ea 01             	sub    $0x1,%edx
c0100844:	85 d2                	test   %edx,%edx
c0100846:	0f 8e 82 00 00 00    	jle    c01008ce <vsprintf+0x3be>
c010084c:	8d 04 17             	lea    (%edi,%edx,1),%eax
c010084f:	90                   	nop
					*str++ = ' ';
c0100850:	83 c7 01             	add    $0x1,%edi
		}

		switch (*format) {
		case 'c':
			if (!(flags & LEFT)) {
				while (--field_width > 0) {
c0100853:	39 c7                	cmp    %eax,%edi
					*str++ = ' ';
c0100855:	c6 47 ff 20          	movb   $0x20,-0x1(%edi)
		}

		switch (*format) {
		case 'c':
			if (!(flags & LEFT)) {
				while (--field_width > 0) {
c0100859:	75 f5                	jne    c0100850 <vsprintf+0x340>
					*str++ = ' ';
				}
			}
			*str++ = (unsigned char) va_arg(args, int);
c010085b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
c010085e:	83 c7 01             	add    $0x1,%edi
c0100861:	8b 13                	mov    (%ebx),%edx
c0100863:	89 d9                	mov    %ebx,%ecx
c0100865:	83 c1 04             	add    $0x4,%ecx
c0100868:	88 10                	mov    %dl,(%eax)
c010086a:	e9 88 00 00 00       	jmp    c01008f7 <vsprintf+0x3e7>
c010086f:	90                   	nop
		case 'u':
			str = number(str, va_arg(args, unsigned long), 10,
				field_width, precision, flags);
			break;
		case 'b':
			str = number(str, va_arg(args, unsigned long), 2,
c0100870:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0100873:	89 4c 24 08          	mov    %ecx,0x8(%esp)
c0100877:	8b 4d e0             	mov    -0x20(%ebp),%ecx
c010087a:	89 14 24             	mov    %edx,(%esp)
c010087d:	8d 58 04             	lea    0x4(%eax),%ebx
c0100880:	89 4c 24 04          	mov    %ecx,0x4(%esp)
c0100884:	b9 02 00 00 00       	mov    $0x2,%ecx
c0100889:	e9 9b fd ff ff       	jmp    c0100629 <vsprintf+0x119>
c010088e:	66 90                	xchg   %ax,%ax
				field_width, precision, flags);
			break;

		case 'n':
			ip = va_arg(args, int *);
c0100890:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
			*ip = (str - buff);
c0100893:	89 fa                	mov    %edi,%edx
c0100895:	2b 55 dc             	sub    -0x24(%ebp),%edx
			str = number(str, va_arg(args, unsigned long), 2,
				field_width, precision, flags);
			break;

		case 'n':
			ip = va_arg(args, int *);
c0100898:	8b 01                	mov    (%ecx),%eax
c010089a:	83 c1 04             	add    $0x4,%ecx
c010089d:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
			*ip = (str - buff);
c01008a0:	89 10                	mov    %edx,(%eax)
c01008a2:	0f b6 46 01          	movzbl 0x1(%esi),%eax
			break;
c01008a6:	e9 8e fc ff ff       	jmp    c0100539 <vsprintf+0x29>
c01008ab:	90                   	nop
c01008ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
				*str++ = ' ';
			}
			break;

		case 'o':
			str = number(str, va_arg(args, unsigned long), 8,
c01008b0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01008b3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
c01008b7:	8b 4d e0             	mov    -0x20(%ebp),%ecx
c01008ba:	89 14 24             	mov    %edx,(%esp)
c01008bd:	8d 58 04             	lea    0x4(%eax),%ebx
c01008c0:	89 4c 24 04          	mov    %ecx,0x4(%esp)
c01008c4:	b9 08 00 00 00       	mov    $0x8,%ecx
c01008c9:	e9 5b fd ff ff       	jmp    c0100629 <vsprintf+0x119>
			if (!(flags & LEFT)) {
				while (--field_width > 0) {
					*str++ = ' ';
				}
			}
			*str++ = (unsigned char) va_arg(args, int);
c01008ce:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			while (--field_width > 0) {
c01008d1:	83 fa 01             	cmp    $0x1,%edx
			if (!(flags & LEFT)) {
				while (--field_width > 0) {
					*str++ = ' ';
				}
			}
			*str++ = (unsigned char) va_arg(args, int);
c01008d4:	8d 47 01             	lea    0x1(%edi),%eax
c01008d7:	8d 4b 04             	lea    0x4(%ebx),%ecx
c01008da:	8b 1b                	mov    (%ebx),%ebx
c01008dc:	88 1f                	mov    %bl,(%edi)
			while (--field_width > 0) {
c01008de:	7e 4e                	jle    c010092e <vsprintf+0x41e>
c01008e0:	01 d7                	add    %edx,%edi
			if (!(flags & LEFT)) {
				while (--field_width > 0) {
					*str++ = ' ';
				}
			}
			*str++ = (unsigned char) va_arg(args, int);
c01008e2:	89 c3                	mov    %eax,%ebx
c01008e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
			while (--field_width > 0) {
				*str++ = ' ';
c01008e8:	83 c3 01             	add    $0x1,%ebx
				while (--field_width > 0) {
					*str++ = ' ';
				}
			}
			*str++ = (unsigned char) va_arg(args, int);
			while (--field_width > 0) {
c01008eb:	39 fb                	cmp    %edi,%ebx
				*str++ = ' ';
c01008ed:	c6 43 ff 20          	movb   $0x20,-0x1(%ebx)
				while (--field_width > 0) {
					*str++ = ' ';
				}
			}
			*str++ = (unsigned char) va_arg(args, int);
			while (--field_width > 0) {
c01008f1:	75 f5                	jne    c01008e8 <vsprintf+0x3d8>
c01008f3:	8d 7c 10 ff          	lea    -0x1(%eax,%edx,1),%edi
c01008f7:	0f b6 46 01          	movzbl 0x1(%esi),%eax
			if (!(flags & LEFT)) {
				while (--field_width > 0) {
					*str++ = ' ';
				}
			}
			*str++ = (unsigned char) va_arg(args, int);
c01008fb:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
c01008fe:	e9 36 fc ff ff       	jmp    c0100539 <vsprintf+0x29>
			field_width = skip_atoi(&format);
		} else if (*format == '*') {
			// it's the next argument
			field_width = va_arg(args, int);
			if (field_width < 0) {
				field_width = -field_width;
c0100903:	f7 da                	neg    %edx
				flags |= LEFT;
c0100905:	83 c9 10             	or     $0x10,%ecx
c0100908:	e9 ec fd ff ff       	jmp    c01006f9 <vsprintf+0x1e9>
	int *ip;
	int flags;              // flags to number()
	int field_width;        // width of output field
	int precision;          // min. # of digits for integers; max number of chars for from string

	for (str = buff ; *format ; ++format) {
c010090d:	31 c0                	xor    %eax,%eax
c010090f:	e9 39 fd ff ff       	jmp    c010064d <vsprintf+0x13d>
c0100914:	0f b6 46 01          	movzbl 0x1(%esi),%eax
				}
			}
			for (i = 0; i < len; ++i) {
				*str++ = *s++;
			}
			while (len < field_width--) {
c0100918:	89 cf                	mov    %ecx,%edi
c010091a:	e9 1a fc ff ff       	jmp    c0100539 <vsprintf+0x29>
			if (!(flags & LEFT)) {
				while (len < field_width--) {
					*str++ = ' ';
				}
			}
			for (i = 0; i < len; ++i) {
c010091f:	89 f9                	mov    %edi,%ecx
c0100921:	e9 e6 fe ff ff       	jmp    c010080c <vsprintf+0x2fc>
			} else if (len > precision) {
				len = precision;
			}

			if (!(flags & LEFT)) {
				while (len < field_width--) {
c0100926:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0100929:	e9 b6 fe ff ff       	jmp    c01007e4 <vsprintf+0x2d4>
			if (!(flags & LEFT)) {
				while (--field_width > 0) {
					*str++ = ' ';
				}
			}
			*str++ = (unsigned char) va_arg(args, int);
c010092e:	89 c7                	mov    %eax,%edi
c0100930:	eb c5                	jmp    c01008f7 <vsprintf+0x3e7>
			++format;       
			if (is_digit(*format)) {
				precision = skip_atoi(&format);
			} else if (*format == '*') {
				// it's the next argument
				precision = va_arg(args, int);
c0100932:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		}

		// get the precision
		precision = -1;
		if (*format == '.') {
			++format;       
c0100935:	8b 75 d8             	mov    -0x28(%ebp),%esi
				precision = skip_atoi(&format);
			} else if (*format == '*') {
				// it's the next argument
				precision = va_arg(args, int);
			}
			if (precision < 0) {
c0100938:	bb 2a 00 00 00       	mov    $0x2a,%ebx
				precision = 0;
c010093d:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
c0100944:	e9 7d fc ff ff       	jmp    c01005c6 <vsprintf+0xb6>
c0100949:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

c0100950 <console_clear>:
    uint8_t attribute_byte = (0 << 4) | (15 & 0x0F);
    uint16_t blank = 0x20 | (attribute_byte << 8);

    int i;

    for (i = 0; i < 80 * 25; i++) {
c0100950:	31 c0                	xor    %eax,%eax
c0100952:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
          video_memory[i] = blank;
c0100958:	ba 20 0f 00 00       	mov    $0xf20,%edx
c010095d:	66 89 94 00 00 80 0b 	mov    %dx,-0x3ff48000(%eax,%eax,1)
c0100964:	c0 
    uint8_t attribute_byte = (0 << 4) | (15 & 0x0F);
    uint16_t blank = 0x20 | (attribute_byte << 8);

    int i;

    for (i = 0; i < 80 * 25; i++) {
c0100965:	83 c0 01             	add    $0x1,%eax
c0100968:	3d d0 07 00 00       	cmp    $0x7d0,%eax
c010096d:	75 e9                	jne    c0100958 <console_clear+0x8>
    outb(0x3D4, 15);                    // 告诉 VGA 我们要设置光标的低字节
    outb(0x3D5, cursorLocation);        // 发送低 8 位
}

void console_clear()
{
c010096f:	55                   	push   %ebp
                             "memory", "cc");
}

static inline void outb(uint16_t port, uint8_t data)
{
    asm volatile("out %0,%1" : : "a" (data), "d" (port));
c0100970:	b8 0e 00 00 00       	mov    $0xe,%eax
c0100975:	89 e5                	mov    %esp,%ebp
c0100977:	56                   	push   %esi
c0100978:	be d4 03 00 00       	mov    $0x3d4,%esi
c010097d:	53                   	push   %ebx
c010097e:	89 f2                	mov    %esi,%edx

    for (i = 0; i < 80 * 25; i++) {
          video_memory[i] = blank;
    }

    cursor_x = 0;
c0100980:	c6 05 c1 a0 10 c0 00 	movb   $0x0,0xc010a0c1
    cursor_y = 0;
c0100987:	c6 05 c0 a0 10 c0 00 	movb   $0x0,0xc010a0c0
c010098e:	ee                   	out    %al,(%dx)
c010098f:	31 c9                	xor    %ecx,%ecx
c0100991:	bb d5 03 00 00       	mov    $0x3d5,%ebx
c0100996:	89 c8                	mov    %ecx,%eax
c0100998:	89 da                	mov    %ebx,%edx
c010099a:	ee                   	out    %al,(%dx)
c010099b:	b8 0f 00 00 00       	mov    $0xf,%eax
c01009a0:	89 f2                	mov    %esi,%edx
c01009a2:	ee                   	out    %al,(%dx)
c01009a3:	89 c8                	mov    %ecx,%eax
c01009a5:	89 da                	mov    %ebx,%edx
c01009a7:	ee                   	out    %al,(%dx)
    move_cursor();
}
c01009a8:	5b                   	pop    %ebx
c01009a9:	5e                   	pop    %esi
c01009aa:	5d                   	pop    %ebp
c01009ab:	c3                   	ret    
c01009ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

c01009b0 <printk>:
}

static int vsprintf(char *buff, const char *format, va_list args);

void printk(const char *format, ...)
{
c01009b0:	55                   	push   %ebp
	static char buff[10240];
	va_list args;
	int i;

	va_start(args, format);
	i = vsprintf(buff, format, args);
c01009b1:	b8 c0 78 10 c0       	mov    $0xc01078c0,%eax
}

static int vsprintf(char *buff, const char *format, va_list args);

void printk(const char *format, ...)
{
c01009b6:	89 e5                	mov    %esp,%ebp
c01009b8:	53                   	push   %ebx
    move_cursor();
}

static void console_write(const char *cstr)
{
    while (*cstr) {
c01009b9:	bb c0 78 10 c0       	mov    $0xc01078c0,%ebx
}

static int vsprintf(char *buff, const char *format, va_list args);

void printk(const char *format, ...)
{
c01009be:	83 ec 04             	sub    $0x4,%esp
	static char buff[10240];
	va_list args;
	int i;

	va_start(args, format);
	i = vsprintf(buff, format, args);
c01009c1:	8b 55 08             	mov    0x8(%ebp),%edx
c01009c4:	8d 4d 0c             	lea    0xc(%ebp),%ecx
c01009c7:	e8 44 fb ff ff       	call   c0100510 <vsprintf>
	va_end(args);

	buff[i] = '\0';
c01009cc:	c6 80 c0 78 10 c0 00 	movb   $0x0,-0x3fef8740(%eax)
    move_cursor();
}

static void console_write(const char *cstr)
{
    while (*cstr) {
c01009d3:	0f be 05 c0 78 10 c0 	movsbl 0xc01078c0,%eax
c01009da:	84 c0                	test   %al,%al
c01009dc:	74 18                	je     c01009f6 <printk+0x46>
c01009de:	66 90                	xchg   %ax,%ax
          console_putc_color(*cstr++, rc_black, rc_white);
c01009e0:	83 c3 01             	add    $0x1,%ebx
c01009e3:	31 d2                	xor    %edx,%edx
c01009e5:	b9 0f 00 00 00       	mov    $0xf,%ecx
c01009ea:	e8 61 f6 ff ff       	call   c0100050 <console_putc_color>
    move_cursor();
}

static void console_write(const char *cstr)
{
    while (*cstr) {
c01009ef:	0f be 03             	movsbl (%ebx),%eax
c01009f2:	84 c0                	test   %al,%al
c01009f4:	75 ea                	jne    c01009e0 <printk+0x30>
	va_end(args);

	buff[i] = '\0';

	console_write(buff);
}
c01009f6:	83 c4 04             	add    $0x4,%esp
c01009f9:	5b                   	pop    %ebx
c01009fa:	5d                   	pop    %ebp
c01009fb:	c3                   	ret    
c01009fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

c0100a00 <cprintk>:

void cprintk(
    real_color_t background, 
    real_color_t frontground, 
    const char *format, ...)
{
c0100a00:	55                   	push   %ebp
	static char buff[10240];
	va_list args;
	int i;

	va_start(args, format);
	i = vsprintf(buff, format, args);
c0100a01:	b8 c0 50 10 c0       	mov    $0xc01050c0,%eax

void cprintk(
    real_color_t background, 
    real_color_t frontground, 
    const char *format, ...)
{
c0100a06:	89 e5                	mov    %esp,%ebp
c0100a08:	57                   	push   %edi
c0100a09:	56                   	push   %esi
c0100a0a:	53                   	push   %ebx
}

static void console_write_color(
    const char *cstr, real_color_t back, real_color_t fore)
{
    while (*cstr) {
c0100a0b:	bb c0 50 10 c0       	mov    $0xc01050c0,%ebx

void cprintk(
    real_color_t background, 
    real_color_t frontground, 
    const char *format, ...)
{
c0100a10:	83 ec 0c             	sub    $0xc,%esp
	static char buff[10240];
	va_list args;
	int i;

	va_start(args, format);
	i = vsprintf(buff, format, args);
c0100a13:	8b 55 10             	mov    0x10(%ebp),%edx
c0100a16:	8d 4d 14             	lea    0x14(%ebp),%ecx

void cprintk(
    real_color_t background, 
    real_color_t frontground, 
    const char *format, ...)
{
c0100a19:	8b 7d 08             	mov    0x8(%ebp),%edi
c0100a1c:	8b 75 0c             	mov    0xc(%ebp),%esi
	static char buff[10240];
	va_list args;
	int i;

	va_start(args, format);
	i = vsprintf(buff, format, args);
c0100a1f:	e8 ec fa ff ff       	call   c0100510 <vsprintf>
	va_end(args);

	buff[i] = '\0';
c0100a24:	c6 80 c0 50 10 c0 00 	movb   $0x0,-0x3fefaf40(%eax)
}

static void console_write_color(
    const char *cstr, real_color_t back, real_color_t fore)
{
    while (*cstr) {
c0100a2b:	0f be 05 c0 50 10 c0 	movsbl 0xc01050c0,%eax
c0100a32:	84 c0                	test   %al,%al
c0100a34:	74 15                	je     c0100a4b <cprintk+0x4b>
c0100a36:	66 90                	xchg   %ax,%ax
          console_putc_color(*cstr++, back, fore);
c0100a38:	83 c3 01             	add    $0x1,%ebx
c0100a3b:	89 f1                	mov    %esi,%ecx
c0100a3d:	89 fa                	mov    %edi,%edx
c0100a3f:	e8 0c f6 ff ff       	call   c0100050 <console_putc_color>
}

static void console_write_color(
    const char *cstr, real_color_t back, real_color_t fore)
{
    while (*cstr) {
c0100a44:	0f be 03             	movsbl (%ebx),%eax
c0100a47:	84 c0                	test   %al,%al
c0100a49:	75 ed                	jne    c0100a38 <cprintk+0x38>
	va_end(args);

	buff[i] = '\0';

	console_write_color(buff, background, frontground);
}
c0100a4b:	83 c4 0c             	add    $0xc,%esp
c0100a4e:	5b                   	pop    %ebx
c0100a4f:	5e                   	pop    %esi
c0100a50:	5f                   	pop    %edi
c0100a51:	5d                   	pop    %ebp
c0100a52:	c3                   	ret    
c0100a53:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
c0100a59:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

c0100a60 <console_init>:

	return (str -buff);
}

void console_init()
{
c0100a60:	55                   	push   %ebp
c0100a61:	89 e5                	mov    %esp,%ebp
}
c0100a63:	5d                   	pop    %ebp
c0100a64:	c3                   	ret    
c0100a65:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
c0100a69:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

c0100a70 <consputc>:

void consputc(int c)
{
	if(panicked){
c0100a70:	8b 15 a0 50 10 c0    	mov    0xc01050a0,%edx
void console_init()
{
}

void consputc(int c)
{
c0100a76:	55                   	push   %ebp
c0100a77:	89 e5                	mov    %esp,%ebp
c0100a79:	8b 45 08             	mov    0x8(%ebp),%eax
	if(panicked){
c0100a7c:	85 d2                	test   %edx,%edx
c0100a7e:	74 03                	je     c0100a83 <consputc+0x13>
    asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void cli(void)
{
    asm volatile("cli");
c0100a80:	fa                   	cli    
c0100a81:	eb fe                	jmp    c0100a81 <consputc+0x11>
	// 	uartputc('\b'); uartputc(' '); uartputc('\b');
	// } else
	// 	uartputc(c);
	// cgaputc(c);
	console_putc_color(c, rc_black, rc_white);
}
c0100a83:	5d                   	pop    %ebp
	// if(c == BACKSPACE){
	// 	uartputc('\b'); uartputc(' '); uartputc('\b');
	// } else
	// 	uartputc(c);
	// cgaputc(c);
	console_putc_color(c, rc_black, rc_white);
c0100a84:	0f be c0             	movsbl %al,%eax
c0100a87:	b9 0f 00 00 00       	mov    $0xf,%ecx
c0100a8c:	31 d2                	xor    %edx,%edx
c0100a8e:	e9 bd f5 ff ff       	jmp    c0100050 <console_putc_color>
c0100a93:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
c0100a99:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

c0100aa0 <console_intr>:
  uint32_t w;  // Write index
  uint32_t e;  // Edit index
} input;

void console_intr(int (*getc)(void))
{
c0100aa0:	55                   	push   %ebp
c0100aa1:	89 e5                	mov    %esp,%ebp
c0100aa3:	53                   	push   %ebx
c0100aa4:	83 ec 14             	sub    $0x14,%esp
c0100aa7:	8b 5d 08             	mov    0x8(%ebp),%ebx
c0100aaa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
	int c;//, doprocdump = 0;

	while ((c = getc()) >= 0) {
c0100ab0:	ff d3                	call   *%ebx
c0100ab2:	85 c0                	test   %eax,%eax
c0100ab4:	0f 88 96 00 00 00    	js     c0100b50 <console_intr+0xb0>
		switch(c) {
c0100aba:	83 f8 15             	cmp    $0x15,%eax
c0100abd:	0f 84 95 00 00 00    	je     c0100b58 <console_intr+0xb8>
c0100ac3:	83 f8 7f             	cmp    $0x7f,%eax
c0100ac6:	0f 84 dc 00 00 00    	je     c0100ba8 <console_intr+0x108>
c0100acc:	83 f8 08             	cmp    $0x8,%eax
c0100acf:	90                   	nop
c0100ad0:	0f 84 d2 00 00 00    	je     c0100ba8 <console_intr+0x108>
			input.e--;
			consputc(BACKSPACE);
		}
		break;
		default:
		if (c != 0 && input.e-input.r < INPUT_BUF) {
c0100ad6:	85 c0                	test   %eax,%eax
c0100ad8:	74 d6                	je     c0100ab0 <console_intr+0x10>
c0100ada:	8b 15 68 b1 10 c0    	mov    0xc010b168,%edx
c0100ae0:	89 d1                	mov    %edx,%ecx
c0100ae2:	2b 0d 60 b1 10 c0    	sub    0xc010b160,%ecx
c0100ae8:	83 f9 7f             	cmp    $0x7f,%ecx
c0100aeb:	77 c3                	ja     c0100ab0 <console_intr+0x10>
			c = (c == '\r') ? '\n' : c;
c0100aed:	83 f8 0d             	cmp    $0xd,%eax
c0100af0:	0f 84 dc 00 00 00    	je     c0100bd2 <console_intr+0x132>
			input.buf[input.e++ % INPUT_BUF] = c;
c0100af6:	8d 4a 01             	lea    0x1(%edx),%ecx
c0100af9:	83 e2 7f             	and    $0x7f,%edx
			consputc(c);
c0100afc:	89 04 24             	mov    %eax,(%esp)
		}
		break;
		default:
		if (c != 0 && input.e-input.r < INPUT_BUF) {
			c = (c == '\r') ? '\n' : c;
			input.buf[input.e++ % INPUT_BUF] = c;
c0100aff:	88 82 e0 b0 10 c0    	mov    %al,-0x3fef4f20(%edx)
			consputc(c);
c0100b05:	89 45 f4             	mov    %eax,-0xc(%ebp)
		}
		break;
		default:
		if (c != 0 && input.e-input.r < INPUT_BUF) {
			c = (c == '\r') ? '\n' : c;
			input.buf[input.e++ % INPUT_BUF] = c;
c0100b08:	89 0d 68 b1 10 c0    	mov    %ecx,0xc010b168
			consputc(c);
c0100b0e:	e8 5d ff ff ff       	call   c0100a70 <consputc>
			if (c == '\n' || c == C('D') 
c0100b13:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100b16:	83 f8 04             	cmp    $0x4,%eax
c0100b19:	0f 84 d1 00 00 00    	je     c0100bf0 <console_intr+0x150>
c0100b1f:	83 f8 0a             	cmp    $0xa,%eax
c0100b22:	0f 84 c8 00 00 00    	je     c0100bf0 <console_intr+0x150>
				|| input.e == input.r+INPUT_BUF) {
c0100b28:	8b 0d 60 b1 10 c0    	mov    0xc010b160,%ecx
c0100b2e:	a1 68 b1 10 c0       	mov    0xc010b168,%eax
c0100b33:	8d 91 80 00 00 00    	lea    0x80(%ecx),%edx
c0100b39:	39 d0                	cmp    %edx,%eax
c0100b3b:	0f 84 b4 00 00 00    	je     c0100bf5 <console_intr+0x155>

void console_intr(int (*getc)(void))
{
	int c;//, doprocdump = 0;

	while ((c = getc()) >= 0) {
c0100b41:	ff d3                	call   *%ebx
c0100b43:	85 c0                	test   %eax,%eax
c0100b45:	0f 89 6f ff ff ff    	jns    c0100aba <console_intr+0x1a>
c0100b4b:	90                   	nop
c0100b4c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
		}
	}
	// if(doprocdump) {
	// 	procdump();  // now call procdump() wo. cons_lock.lock held
	// }
}
c0100b50:	83 c4 14             	add    $0x14,%esp
c0100b53:	5b                   	pop    %ebx
c0100b54:	5d                   	pop    %ebp
c0100b55:	c3                   	ret    
c0100b56:	66 90                	xchg   %ax,%ax
		switch(c) {
		// case C('P'):  // Process listing.
		// doprocdump = 1;   // procdump() locks cons_lock.lock indirectly; invoke later
		// break;
		case C('U'):  // Kill line.
		while (input.e != input.w &&
c0100b58:	a1 68 b1 10 c0       	mov    0xc010b168,%eax
c0100b5d:	3b 05 64 b1 10 c0    	cmp    0xc010b164,%eax
c0100b63:	75 2d                	jne    c0100b92 <console_intr+0xf2>
c0100b65:	e9 46 ff ff ff       	jmp    c0100ab0 <console_intr+0x10>
c0100b6a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
				input.buf[(input.e-1) % INPUT_BUF] != '\n') {
			input.e--;
			consputc(BACKSPACE);
c0100b70:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
		// doprocdump = 1;   // procdump() locks cons_lock.lock indirectly; invoke later
		// break;
		case C('U'):  // Kill line.
		while (input.e != input.w &&
				input.buf[(input.e-1) % INPUT_BUF] != '\n') {
			input.e--;
c0100b77:	a3 68 b1 10 c0       	mov    %eax,0xc010b168
			consputc(BACKSPACE);
c0100b7c:	e8 ef fe ff ff       	call   c0100a70 <consputc>
		switch(c) {
		// case C('P'):  // Process listing.
		// doprocdump = 1;   // procdump() locks cons_lock.lock indirectly; invoke later
		// break;
		case C('U'):  // Kill line.
		while (input.e != input.w &&
c0100b81:	a1 68 b1 10 c0       	mov    0xc010b168,%eax
c0100b86:	3b 05 64 b1 10 c0    	cmp    0xc010b164,%eax
c0100b8c:	0f 84 1e ff ff ff    	je     c0100ab0 <console_intr+0x10>
				input.buf[(input.e-1) % INPUT_BUF] != '\n') {
c0100b92:	83 e8 01             	sub    $0x1,%eax
c0100b95:	89 c2                	mov    %eax,%edx
c0100b97:	83 e2 7f             	and    $0x7f,%edx
		switch(c) {
		// case C('P'):  // Process listing.
		// doprocdump = 1;   // procdump() locks cons_lock.lock indirectly; invoke later
		// break;
		case C('U'):  // Kill line.
		while (input.e != input.w &&
c0100b9a:	80 ba e0 b0 10 c0 0a 	cmpb   $0xa,-0x3fef4f20(%edx)
c0100ba1:	75 cd                	jne    c0100b70 <console_intr+0xd0>
c0100ba3:	e9 08 ff ff ff       	jmp    c0100ab0 <console_intr+0x10>
			input.e--;
			consputc(BACKSPACE);
		}
		break;
		case C('H'): case '\x7f':  // Backspace
		if (input.e != input.w){
c0100ba8:	a1 68 b1 10 c0       	mov    0xc010b168,%eax
c0100bad:	3b 05 64 b1 10 c0    	cmp    0xc010b164,%eax
c0100bb3:	0f 84 f7 fe ff ff    	je     c0100ab0 <console_intr+0x10>
			input.e--;
c0100bb9:	83 e8 01             	sub    $0x1,%eax
			consputc(BACKSPACE);
c0100bbc:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
			consputc(BACKSPACE);
		}
		break;
		case C('H'): case '\x7f':  // Backspace
		if (input.e != input.w){
			input.e--;
c0100bc3:	a3 68 b1 10 c0       	mov    %eax,0xc010b168
			consputc(BACKSPACE);
c0100bc8:	e8 a3 fe ff ff       	call   c0100a70 <consputc>
c0100bcd:	e9 de fe ff ff       	jmp    c0100ab0 <console_intr+0x10>
		}
		break;
		default:
		if (c != 0 && input.e-input.r < INPUT_BUF) {
			c = (c == '\r') ? '\n' : c;
			input.buf[input.e++ % INPUT_BUF] = c;
c0100bd2:	8d 42 01             	lea    0x1(%edx),%eax
c0100bd5:	83 e2 7f             	and    $0x7f,%edx
			consputc(c);
c0100bd8:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
		}
		break;
		default:
		if (c != 0 && input.e-input.r < INPUT_BUF) {
			c = (c == '\r') ? '\n' : c;
			input.buf[input.e++ % INPUT_BUF] = c;
c0100bdf:	a3 68 b1 10 c0       	mov    %eax,0xc010b168
c0100be4:	c6 82 e0 b0 10 c0 0a 	movb   $0xa,-0x3fef4f20(%edx)
			consputc(c);
c0100beb:	e8 80 fe ff ff       	call   c0100a70 <consputc>
c0100bf0:	a1 68 b1 10 c0       	mov    0xc010b168,%eax
			if (c == '\n' || c == C('D') 
				|| input.e == input.r+INPUT_BUF) {
				input.w = input.e;
c0100bf5:	a3 64 b1 10 c0       	mov    %eax,0xc010b164
c0100bfa:	e9 b1 fe ff ff       	jmp    c0100ab0 <console_intr+0x10>
c0100bff:	90                   	nop

c0100c00 <kbd_intr>:
	}
	return c;
}

void kbd_intr(void)
{
c0100c00:	55                   	push   %ebp
c0100c01:	89 e5                	mov    %esp,%ebp
c0100c03:	83 ec 18             	sub    $0x18,%esp
	console_intr(kbd_getc);
c0100c06:	c7 04 24 40 04 10 c0 	movl   $0xc0100440,(%esp)
c0100c0d:	e8 8e fe ff ff       	call   c0100aa0 <console_intr>
}
c0100c12:	c9                   	leave  
c0100c13:	c3                   	ret    
c0100c14:	66 90                	xchg   %ax,%ax
c0100c16:	66 90                	xchg   %ax,%ax
c0100c18:	66 90                	xchg   %ax,%ax
c0100c1a:	66 90                	xchg   %ax,%ax
c0100c1c:	66 90                	xchg   %ax,%ax
c0100c1e:	66 90                	xchg   %ax,%ax

c0100c20 <debug_info_eip>:
 * the specified instruction address, @addr.  Returns 0 if information
 * was found, and negative if not.  But even if it returns negative it
 * has stored some information into '*info'.
 * */
int debug_info_eip(uint32_t addr, struct eip_debug_info *info) 
{
c0100c20:	55                   	push   %ebp
c0100c21:	89 e5                	mov    %esp,%ebp
c0100c23:	57                   	push   %edi
c0100c24:	56                   	push   %esi
    stab_end = __STAB_END__;
    stabstr = __STABSTR_BEGIN__;
    stabstr_end = __STABSTR_END__;

    // String table validity checks
    if (stabstr_end <= stabstr || stabstr_end[-1] != 0) {
c0100c25:	be 05 22 10 c0       	mov    $0xc0102205,%esi
 * the specified instruction address, @addr.  Returns 0 if information
 * was found, and negative if not.  But even if it returns negative it
 * has stored some information into '*info'.
 * */
int debug_info_eip(uint32_t addr, struct eip_debug_info *info) 
{
c0100c2a:	53                   	push   %ebx
c0100c2b:	83 ec 2c             	sub    $0x2c,%esp
c0100c2e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
    stab_end = __STAB_END__;
    stabstr = __STABSTR_BEGIN__;
    stabstr_end = __STABSTR_END__;

    // String table validity checks
    if (stabstr_end <= stabstr || stabstr_end[-1] != 0) {
c0100c31:	81 fe 05 22 10 c0    	cmp    $0xc0102205,%esi
 * the specified instruction address, @addr.  Returns 0 if information
 * was found, and negative if not.  But even if it returns negative it
 * has stored some information into '*info'.
 * */
int debug_info_eip(uint32_t addr, struct eip_debug_info *info) 
{
c0100c37:	8b 7d 08             	mov    0x8(%ebp),%edi
    const struct stab *stabs, *stab_end;
    const char *stabstr, *stabstr_end;

    info->eip_file = "<unknown>";
c0100c3a:	c7 03 60 1e 10 c0    	movl   $0xc0101e60,(%ebx)
    info->eip_line = 0;
c0100c40:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
    info->eip_fn_name = "<unknown>";
c0100c47:	c7 43 08 60 1e 10 c0 	movl   $0xc0101e60,0x8(%ebx)
    info->eip_fn_namelen = 9;
c0100c4e:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
    info->eip_fn_addr = addr;
c0100c55:	89 7b 10             	mov    %edi,0x10(%ebx)
    info->eip_fn_narg = 0;
c0100c58:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
    stab_end = __STAB_END__;
    stabstr = __STABSTR_BEGIN__;
    stabstr_end = __STABSTR_END__;

    // String table validity checks
    if (stabstr_end <= stabstr || stabstr_end[-1] != 0) {
c0100c5f:	77 0d                	ja     c0100c6e <debug_info_eip+0x4e>
        return -1;
c0100c61:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
             lline ++) {
            info->eip_fn_narg ++;
        }
    }
    return 0;
}
c0100c66:	83 c4 2c             	add    $0x2c,%esp
c0100c69:	5b                   	pop    %ebx
c0100c6a:	5e                   	pop    %esi
c0100c6b:	5f                   	pop    %edi
c0100c6c:	5d                   	pop    %ebp
c0100c6d:	c3                   	ret    
    stab_end = __STAB_END__;
    stabstr = __STABSTR_BEGIN__;
    stabstr_end = __STABSTR_END__;

    // String table validity checks
    if (stabstr_end <= stabstr || stabstr_end[-1] != 0) {
c0100c6e:	80 3d 04 22 10 c0 00 	cmpb   $0x0,0xc0102204
c0100c75:	75 ea                	jne    c0100c61 <debug_info_eip+0x41>
    // 'eip'.  First, we find the basic source file containing 'eip'.
    // Then, we look in that source file for the function.  Then we look
    // for the line number.

    // Search the entire set of stabs for the source file (type N_SO).
    int lfile = 0, rfile = (stab_end - stabs) - 1;
c0100c77:	b8 04 22 10 c0       	mov    $0xc0102204,%eax
    stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
c0100c7c:	b9 64 00 00 00       	mov    $0x64,%ecx
    // 'eip'.  First, we find the basic source file containing 'eip'.
    // Then, we look in that source file for the function.  Then we look
    // for the line number.

    // Search the entire set of stabs for the source file (type N_SO).
    int lfile = 0, rfile = (stab_end - stabs) - 1;
c0100c81:	2d 04 22 10 c0       	sub    $0xc0102204,%eax
c0100c86:	c1 f8 02             	sar    $0x2,%eax
c0100c89:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
    stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
c0100c8f:	89 3c 24             	mov    %edi,(%esp)
c0100c92:	8d 55 e0             	lea    -0x20(%ebp),%edx
    // 'eip'.  First, we find the basic source file containing 'eip'.
    // Then, we look in that source file for the function.  Then we look
    // for the line number.

    // Search the entire set of stabs for the source file (type N_SO).
    int lfile = 0, rfile = (stab_end - stabs) - 1;
c0100c95:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c0100c9c:	83 e8 01             	sub    $0x1,%eax
c0100c9f:	89 45 e0             	mov    %eax,-0x20(%ebp)
    stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
c0100ca2:	8d 45 dc             	lea    -0x24(%ebp),%eax
c0100ca5:	e8 a5 03 00 00       	call   c010104f <stab_binsearch.constprop.0>
    if (lfile == 0)
c0100caa:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0100cad:	85 c0                	test   %eax,%eax
c0100caf:	74 b0                	je     c0100c61 <debug_info_eip+0x41>
        return -1;

    // Search within that file's stabs for the function definition
    // (N_FUN).
    int lfun = lfile, rfun = rfile;
c0100cb1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0100cb4:	8b 45 e0             	mov    -0x20(%ebp),%eax
    int lline, rline;
    stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
c0100cb7:	b9 24 00 00 00       	mov    $0x24,%ecx
c0100cbc:	89 3c 24             	mov    %edi,(%esp)
c0100cbf:	8d 55 e8             	lea    -0x18(%ebp),%edx
    if (lfile == 0)
        return -1;

    // Search within that file's stabs for the function definition
    // (N_FUN).
    int lfun = lfile, rfun = rfile;
c0100cc2:	89 45 e8             	mov    %eax,-0x18(%ebp)
    int lline, rline;
    stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
c0100cc5:	8d 45 e4             	lea    -0x1c(%ebp),%eax
c0100cc8:	e8 82 03 00 00       	call   c010104f <stab_binsearch.constprop.0>

    if (lfun <= rfun) {
c0100ccd:	8b 4d e8             	mov    -0x18(%ebp),%ecx
c0100cd0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0100cd3:	89 4d d0             	mov    %ecx,-0x30(%ebp)
c0100cd6:	39 c8                	cmp    %ecx,%eax
c0100cd8:	0f 8f 41 01 00 00    	jg     c0100e1f <debug_info_eip+0x1ff>
        // stabs[lfun] points to the function name
        // in the string table, but check bounds just in case.
        if (stabs[lfun].n_strx < stabstr_end - stabstr) {
c0100cde:	6b d0 0c             	imul   $0xc,%eax,%edx
c0100ce1:	8d 8a 04 22 10 c0    	lea    -0x3fefddfc(%edx),%ecx
c0100ce7:	8b 92 04 22 10 c0    	mov    -0x3fefddfc(%edx),%edx
c0100ced:	89 4d cc             	mov    %ecx,-0x34(%ebp)
c0100cf0:	89 f1                	mov    %esi,%ecx
c0100cf2:	81 e9 05 22 10 c0    	sub    $0xc0102205,%ecx
c0100cf8:	39 ca                	cmp    %ecx,%edx
c0100cfa:	73 09                	jae    c0100d05 <debug_info_eip+0xe5>
            info->eip_fn_name = stabstr + stabs[lfun].n_strx;
c0100cfc:	81 c2 05 22 10 c0    	add    $0xc0102205,%edx
c0100d02:	89 53 08             	mov    %edx,0x8(%ebx)
        }
        info->eip_fn_addr = stabs[lfun].n_value;
c0100d05:	8b 4d cc             	mov    -0x34(%ebp),%ecx
        addr -= info->eip_fn_addr;
        // Search within the function definition for the line number.
        lline = lfun;
c0100d08:	89 45 ec             	mov    %eax,-0x14(%ebp)
        rline = rfun;
c0100d0b:	8b 45 d0             	mov    -0x30(%ebp),%eax
        // stabs[lfun] points to the function name
        // in the string table, but check bounds just in case.
        if (stabs[lfun].n_strx < stabstr_end - stabstr) {
            info->eip_fn_name = stabstr + stabs[lfun].n_strx;
        }
        info->eip_fn_addr = stabs[lfun].n_value;
c0100d0e:	8b 51 08             	mov    0x8(%ecx),%edx
        addr -= info->eip_fn_addr;
        // Search within the function definition for the line number.
        lline = lfun;
        rline = rfun;
c0100d11:	89 45 f0             	mov    %eax,-0x10(%ebp)
        // stabs[lfun] points to the function name
        // in the string table, but check bounds just in case.
        if (stabs[lfun].n_strx < stabstr_end - stabstr) {
            info->eip_fn_name = stabstr + stabs[lfun].n_strx;
        }
        info->eip_fn_addr = stabs[lfun].n_value;
c0100d14:	89 53 10             	mov    %edx,0x10(%ebx)
        addr -= info->eip_fn_addr;
c0100d17:	29 d7                	sub    %edx,%edi
        // file.  Search the whole file for the line number.
        info->eip_fn_addr = addr;
        lline = lfile;
        rline = rfile;
    }
    info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
c0100d19:	8b 53 08             	mov    0x8(%ebx),%edx
    }
}

static const char *strfind(const char *str, char c)
{
	while (str) {
c0100d1c:	85 d2                	test   %edx,%edx
c0100d1e:	74 1a                	je     c0100d3a <debug_info_eip+0x11a>
		if (*str == c)
c0100d20:	80 3a 3a             	cmpb   $0x3a,(%edx)
c0100d23:	89 d0                	mov    %edx,%eax
c0100d25:	75 0e                	jne    c0100d35 <debug_info_eip+0x115>
c0100d27:	eb 13                	jmp    c0100d3c <debug_info_eip+0x11c>
c0100d29:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
c0100d30:	80 38 3a             	cmpb   $0x3a,(%eax)
c0100d33:	74 07                	je     c0100d3c <debug_info_eip+0x11c>
    }
}

static const char *strfind(const char *str, char c)
{
	while (str) {
c0100d35:	83 c0 01             	add    $0x1,%eax
c0100d38:	75 f6                	jne    c0100d30 <debug_info_eip+0x110>
		if (*str == c)
			return str;
		++str;
	}
	return NULL;
c0100d3a:	31 c0                	xor    %eax,%eax
        // file.  Search the whole file for the line number.
        info->eip_fn_addr = addr;
        lline = lfile;
        rline = rfile;
    }
    info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
c0100d3c:	29 d0                	sub    %edx,%eax

    // Search within [lline, rline] for the line number stab.
    // If found, set info->eip_line to the right line number.
    // If not found, return -1.
    stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
c0100d3e:	b9 44 00 00 00       	mov    $0x44,%ecx
        // file.  Search the whole file for the line number.
        info->eip_fn_addr = addr;
        lline = lfile;
        rline = rfile;
    }
    info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
c0100d43:	89 43 0c             	mov    %eax,0xc(%ebx)

    // Search within [lline, rline] for the line number stab.
    // If found, set info->eip_line to the right line number.
    // If not found, return -1.
    stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
c0100d46:	8d 55 f0             	lea    -0x10(%ebp),%edx
c0100d49:	8d 45 ec             	lea    -0x14(%ebp),%eax
c0100d4c:	89 3c 24             	mov    %edi,(%esp)
c0100d4f:	e8 fb 02 00 00       	call   c010104f <stab_binsearch.constprop.0>
    if (lline <= rline) {
c0100d54:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0100d57:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0100d5a:	39 c2                	cmp    %eax,%edx
c0100d5c:	0f 8f ff fe ff ff    	jg     c0100c61 <debug_info_eip+0x41>
        info->eip_line = stabs[rline].n_desc;
c0100d62:	6b c0 0c             	imul   $0xc,%eax,%eax
c0100d65:	0f b7 80 0a 22 10 c0 	movzwl -0x3fefddf6(%eax),%eax
c0100d6c:	89 43 04             	mov    %eax,0x4(%ebx)

    // Search backwards from the line number for the relevant filename stab.
    // We can't just use the "lfile" stab because inlined functions
    // can interpolate code from a different file!
    // Such included source files use the N_SOL stab type.
    while (lline >= lfile
c0100d6f:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0100d72:	39 c2                	cmp    %eax,%edx
c0100d74:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0100d77:	7c 5b                	jl     c0100dd4 <debug_info_eip+0x1b4>
           && stabs[lline].n_type != N_SOL
c0100d79:	6b c2 0c             	imul   $0xc,%edx,%eax
c0100d7c:	8d b8 04 22 10 c0    	lea    -0x3fefddfc(%eax),%edi
c0100d82:	0f b6 4f 04          	movzbl 0x4(%edi),%ecx
c0100d86:	80 f9 84             	cmp    $0x84,%cl
c0100d89:	74 2f                	je     c0100dba <debug_info_eip+0x19a>
c0100d8b:	05 f8 21 10 c0       	add    $0xc01021f8,%eax
c0100d90:	eb 1c                	jmp    c0100dae <debug_info_eip+0x18e>
c0100d92:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
           && (stabs[lline].n_type != N_SO || !stabs[lline].n_value)) {
        lline --;
c0100d98:	83 ea 01             	sub    $0x1,%edx

    // Search backwards from the line number for the relevant filename stab.
    // We can't just use the "lfile" stab because inlined functions
    // can interpolate code from a different file!
    // Such included source files use the N_SOL stab type.
    while (lline >= lfile
c0100d9b:	3b 55 d0             	cmp    -0x30(%ebp),%edx
c0100d9e:	7c 34                	jl     c0100dd4 <debug_info_eip+0x1b4>
           && stabs[lline].n_type != N_SOL
c0100da0:	89 c7                	mov    %eax,%edi
c0100da2:	83 e8 0c             	sub    $0xc,%eax
c0100da5:	0f b6 48 10          	movzbl 0x10(%eax),%ecx
c0100da9:	80 f9 84             	cmp    $0x84,%cl
c0100dac:	74 0c                	je     c0100dba <debug_info_eip+0x19a>
           && (stabs[lline].n_type != N_SO || !stabs[lline].n_value)) {
c0100dae:	80 f9 64             	cmp    $0x64,%cl
c0100db1:	75 e5                	jne    c0100d98 <debug_info_eip+0x178>
c0100db3:	8b 4f 08             	mov    0x8(%edi),%ecx
c0100db6:	85 c9                	test   %ecx,%ecx
c0100db8:	74 de                	je     c0100d98 <debug_info_eip+0x178>
        lline --;
    }
    if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr) {
c0100dba:	6b d2 0c             	imul   $0xc,%edx,%edx
c0100dbd:	81 ee 05 22 10 c0    	sub    $0xc0102205,%esi
c0100dc3:	8b 82 04 22 10 c0    	mov    -0x3fefddfc(%edx),%eax
c0100dc9:	39 f0                	cmp    %esi,%eax
c0100dcb:	73 07                	jae    c0100dd4 <debug_info_eip+0x1b4>
        info->eip_file = stabstr + stabs[lline].n_strx;
c0100dcd:	05 05 22 10 c0       	add    $0xc0102205,%eax
c0100dd2:	89 03                	mov    %eax,(%ebx)
    }

    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
c0100dd4:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
c0100dd7:	8b 55 e8             	mov    -0x18(%ebp),%edx
c0100dda:	39 d1                	cmp    %edx,%ecx
c0100ddc:	7d 3a                	jge    c0100e18 <debug_info_eip+0x1f8>
        for (lline = lfun + 1;
c0100dde:	8d 41 01             	lea    0x1(%ecx),%eax
c0100de1:	39 c2                	cmp    %eax,%edx
c0100de3:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0100de6:	7e 30                	jle    c0100e18 <debug_info_eip+0x1f8>
             lline < rfun && stabs[lline].n_type == N_PSYM;
c0100de8:	6b f0 0c             	imul   $0xc,%eax,%esi
c0100deb:	80 be 08 22 10 c0 a0 	cmpb   $0xa0,-0x3fefddf8(%esi)
c0100df2:	75 24                	jne    c0100e18 <debug_info_eip+0x1f8>
c0100df4:	8b 43 14             	mov    0x14(%ebx),%eax
c0100df7:	81 c6 f8 21 10 c0    	add    $0xc01021f8,%esi
c0100dfd:	8d 54 02 ff          	lea    -0x1(%edx,%eax,1),%edx
c0100e01:	29 ca                	sub    %ecx,%edx
c0100e03:	eb 09                	jmp    c0100e0e <debug_info_eip+0x1ee>
c0100e05:	83 c6 0c             	add    $0xc,%esi
c0100e08:	80 7e 10 a0          	cmpb   $0xa0,0x10(%esi)
c0100e0c:	75 0a                	jne    c0100e18 <debug_info_eip+0x1f8>
             lline ++) {
            info->eip_fn_narg ++;
c0100e0e:	83 c0 01             	add    $0x1,%eax
    }

    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
        for (lline = lfun + 1;
c0100e11:	39 d0                	cmp    %edx,%eax
             lline < rfun && stabs[lline].n_type == N_PSYM;
             lline ++) {
            info->eip_fn_narg ++;
c0100e13:	89 43 14             	mov    %eax,0x14(%ebx)
    }

    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
        for (lline = lfun + 1;
c0100e16:	75 ed                	jne    c0100e05 <debug_info_eip+0x1e5>
             lline < rfun && stabs[lline].n_type == N_PSYM;
             lline ++) {
            info->eip_fn_narg ++;
        }
    }
    return 0;
c0100e18:	31 c0                	xor    %eax,%eax
c0100e1a:	e9 47 fe ff ff       	jmp    c0100c66 <debug_info_eip+0x46>
        rline = rfun;
    } else {
        // Couldn't find function stab!  Maybe we're in an assembly
        // file.  Search the whole file for the line number.
        info->eip_fn_addr = addr;
        lline = lfile;
c0100e1f:	8b 45 dc             	mov    -0x24(%ebp),%eax
        lline = lfun;
        rline = rfun;
    } else {
        // Couldn't find function stab!  Maybe we're in an assembly
        // file.  Search the whole file for the line number.
        info->eip_fn_addr = addr;
c0100e22:	89 7b 10             	mov    %edi,0x10(%ebx)
        lline = lfile;
c0100e25:	89 45 ec             	mov    %eax,-0x14(%ebp)
        rline = rfile;
c0100e28:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0100e2b:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0100e2e:	e9 e6 fe ff ff       	jmp    c0100d19 <debug_info_eip+0xf9>
c0100e33:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
c0100e39:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

c0100e40 <print_debug_info>:
 * print_debuginfo - read and print the stat information for the 
 * address @eip, and info.eip_fn_addr should be the first address 
 * of the related function.
 * */
void print_debug_info(uint32_t eip) 
{
c0100e40:	55                   	push   %ebp
c0100e41:	89 e5                	mov    %esp,%ebp
c0100e43:	57                   	push   %edi
c0100e44:	56                   	push   %esi
c0100e45:	53                   	push   %ebx
c0100e46:	81 ec 4c 01 00 00    	sub    $0x14c,%esp
c0100e4c:	8b 5d 08             	mov    0x8(%ebp),%ebx
    struct eip_debug_info info;
    if (debug_info_eip(eip, &info) != 0) {
c0100e4f:	8d 85 d0 fe ff ff    	lea    -0x130(%ebp),%eax
c0100e55:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100e59:	89 1c 24             	mov    %ebx,(%esp)
c0100e5c:	e8 bf fd ff ff       	call   c0100c20 <debug_info_eip>
c0100e61:	85 c0                	test   %eax,%eax
c0100e63:	75 6a                	jne    c0100ecf <print_debug_info+0x8f>
        printk("<unknow>: -- 0x%08x --\n", eip);
    }
    else {
        char fnname[256];
        int j;
        for (j = 0; j < info.eip_fn_namelen; j ++) {
c0100e65:	8b 8d dc fe ff ff    	mov    -0x124(%ebp),%ecx
c0100e6b:	85 c9                	test   %ecx,%ecx
c0100e6d:	7e 7b                	jle    c0100eea <print_debug_info+0xaa>
c0100e6f:	8b bd d8 fe ff ff    	mov    -0x128(%ebp),%edi
c0100e75:	31 c0                	xor    %eax,%eax
c0100e77:	8d b5 e8 fe ff ff    	lea    -0x118(%ebp),%esi
c0100e7d:	8d 76 00             	lea    0x0(%esi),%esi
            fnname[j] = info.eip_fn_name[j];
c0100e80:	0f b6 14 07          	movzbl (%edi,%eax,1),%edx
c0100e84:	88 14 06             	mov    %dl,(%esi,%eax,1)
        printk("<unknow>: -- 0x%08x --\n", eip);
    }
    else {
        char fnname[256];
        int j;
        for (j = 0; j < info.eip_fn_namelen; j ++) {
c0100e87:	83 c0 01             	add    $0x1,%eax
c0100e8a:	39 c8                	cmp    %ecx,%eax
c0100e8c:	75 f2                	jne    c0100e80 <print_debug_info+0x40>
            fnname[j] = info.eip_fn_name[j];
        }
        fnname[j] = '\0';
        printk("%s:%d: %s+%d\n", info.eip_file, info.eip_line,
c0100e8e:	8b 85 d4 fe ff ff    	mov    -0x12c(%ebp),%eax
c0100e94:	2b 9d e0 fe ff ff    	sub    -0x120(%ebp),%ebx
c0100e9a:	89 74 24 0c          	mov    %esi,0xc(%esp)
c0100e9e:	c7 04 24 82 1e 10 c0 	movl   $0xc0101e82,(%esp)
c0100ea5:	89 44 24 08          	mov    %eax,0x8(%esp)
c0100ea9:	8b 85 d0 fe ff ff    	mov    -0x130(%ebp),%eax
c0100eaf:	89 5c 24 10          	mov    %ebx,0x10(%esp)
        char fnname[256];
        int j;
        for (j = 0; j < info.eip_fn_namelen; j ++) {
            fnname[j] = info.eip_fn_name[j];
        }
        fnname[j] = '\0';
c0100eb3:	c6 84 0d e8 fe ff ff 	movb   $0x0,-0x118(%ebp,%ecx,1)
c0100eba:	00 
        printk("%s:%d: %s+%d\n", info.eip_file, info.eip_line,
c0100ebb:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100ebf:	e8 ec fa ff ff       	call   c01009b0 <printk>
                fnname, eip - info.eip_fn_addr);
    }
}
c0100ec4:	81 c4 4c 01 00 00    	add    $0x14c,%esp
c0100eca:	5b                   	pop    %ebx
c0100ecb:	5e                   	pop    %esi
c0100ecc:	5f                   	pop    %edi
c0100ecd:	5d                   	pop    %ebp
c0100ece:	c3                   	ret    
 * */
void print_debug_info(uint32_t eip) 
{
    struct eip_debug_info info;
    if (debug_info_eip(eip, &info) != 0) {
        printk("<unknow>: -- 0x%08x --\n", eip);
c0100ecf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
c0100ed3:	c7 04 24 6a 1e 10 c0 	movl   $0xc0101e6a,(%esp)
c0100eda:	e8 d1 fa ff ff       	call   c01009b0 <printk>
        }
        fnname[j] = '\0';
        printk("%s:%d: %s+%d\n", info.eip_file, info.eip_line,
                fnname, eip - info.eip_fn_addr);
    }
}
c0100edf:	81 c4 4c 01 00 00    	add    $0x14c,%esp
c0100ee5:	5b                   	pop    %ebx
c0100ee6:	5e                   	pop    %esi
c0100ee7:	5f                   	pop    %edi
c0100ee8:	5d                   	pop    %ebp
c0100ee9:	c3                   	ret    
        printk("<unknow>: -- 0x%08x --\n", eip);
    }
    else {
        char fnname[256];
        int j;
        for (j = 0; j < info.eip_fn_namelen; j ++) {
c0100eea:	31 c9                	xor    %ecx,%ecx
c0100eec:	8d b5 e8 fe ff ff    	lea    -0x118(%ebp),%esi
c0100ef2:	eb 9a                	jmp    c0100e8e <print_debug_info+0x4e>
c0100ef4:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
c0100efa:	8d bf 00 00 00 00    	lea    0x0(%edi),%edi

c0100f00 <print_stack_frame>:
    asm volatile ("movl %%ebp, %0" : "=r" (ebp));
    return ebp;
}

void print_stack_frame(void) 
{
c0100f00:	55                   	push   %ebp
c0100f01:	89 e5                	mov    %esp,%ebp
c0100f03:	57                   	push   %edi
c0100f04:	56                   	push   %esi
c0100f05:	53                   	push   %ebx
c0100f06:	83 ec 1c             	sub    $0x1c,%esp
}

static inline uint32_t read_ebp(void) 
{
    uint32_t ebp;
    asm volatile ("movl %%ebp, %0" : "=r" (ebp));
c0100f09:	89 eb                	mov    %ebp,%ebx
}

static inline uint32_t read_eip(void) 
{
    uint32_t eip;
    asm volatile("movl 4(%%ebp), %0" : "=r" (eip));
c0100f0b:	8b 7d 04             	mov    0x4(%ebp),%edi
void print_stack_frame(void) 
{
    uint32_t ebp = read_ebp(), eip = read_eip();

    int i;
    for (i = 0; ebp != 0 && i < STACKFRAME_DEPTH; i ++) {
c0100f0e:	31 f6                	xor    %esi,%esi
c0100f10:	85 db                	test   %ebx,%ebx
c0100f12:	75 09                	jne    c0100f1d <print_stack_frame+0x1d>
c0100f14:	eb 2e                	jmp    c0100f44 <print_stack_frame+0x44>
c0100f16:	66 90                	xchg   %ax,%ax
c0100f18:	83 fe 13             	cmp    $0x13,%esi
c0100f1b:	7f 27                	jg     c0100f44 <print_stack_frame+0x44>
		printk("    [%d] ", i);
        print_debug_info(eip - 1);
c0100f1d:	83 ef 01             	sub    $0x1,%edi
{
    uint32_t ebp = read_ebp(), eip = read_eip();

    int i;
    for (i = 0; ebp != 0 && i < STACKFRAME_DEPTH; i ++) {
		printk("    [%d] ", i);
c0100f20:	89 74 24 04          	mov    %esi,0x4(%esp)
void print_stack_frame(void) 
{
    uint32_t ebp = read_ebp(), eip = read_eip();

    int i;
    for (i = 0; ebp != 0 && i < STACKFRAME_DEPTH; i ++) {
c0100f24:	83 c6 01             	add    $0x1,%esi
		printk("    [%d] ", i);
c0100f27:	c7 04 24 90 1e 10 c0 	movl   $0xc0101e90,(%esp)
c0100f2e:	e8 7d fa ff ff       	call   c01009b0 <printk>
        print_debug_info(eip - 1);
c0100f33:	89 3c 24             	mov    %edi,(%esp)
c0100f36:	e8 05 ff ff ff       	call   c0100e40 <print_debug_info>
        eip = ((uint32_t *)ebp)[1];
c0100f3b:	8b 7b 04             	mov    0x4(%ebx),%edi
        ebp = ((uint32_t *)ebp)[0];
c0100f3e:	8b 1b                	mov    (%ebx),%ebx
void print_stack_frame(void) 
{
    uint32_t ebp = read_ebp(), eip = read_eip();

    int i;
    for (i = 0; ebp != 0 && i < STACKFRAME_DEPTH; i ++) {
c0100f40:	85 db                	test   %ebx,%ebx
c0100f42:	75 d4                	jne    c0100f18 <print_stack_frame+0x18>
		printk("    [%d] ", i);
        print_debug_info(eip - 1);
        eip = ((uint32_t *)ebp)[1];
        ebp = ((uint32_t *)ebp)[0];
    }
}
c0100f44:	83 c4 1c             	add    $0x1c,%esp
c0100f47:	5b                   	pop    %ebx
c0100f48:	5e                   	pop    %esi
c0100f49:	5f                   	pop    %edi
c0100f4a:	5d                   	pop    %ebp
c0100f4b:	c3                   	ret    
c0100f4c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

c0100f50 <panic>:

void panic(const char *msg)
{
c0100f50:	55                   	push   %ebp
c0100f51:	89 e5                	mov    %esp,%ebp
c0100f53:	83 ec 18             	sub    $0x18,%esp
}

static inline uint32_t readeflags(void)
{
    uint32_t eflags;
    asm volatile("pushfl; popl %0" : "=r" (eflags));
c0100f56:	9c                   	pushf  
c0100f57:	58                   	pop    %eax
    if(readeflags() & FL_IF)
c0100f58:	f6 c4 02             	test   $0x2,%ah
c0100f5b:	74 01                	je     c0100f5e <panic+0xe>
    asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void cli(void)
{
    asm volatile("cli");
c0100f5d:	fa                   	cli    
		cli();
    
	printk("*** System panic: %s\n", msg);
c0100f5e:	8b 45 08             	mov    0x8(%ebp),%eax
c0100f61:	c7 04 24 9a 1e 10 c0 	movl   $0xc0101e9a,(%esp)
c0100f68:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100f6c:	e8 3f fa ff ff       	call   c01009b0 <printk>
	print_stack_frame();
c0100f71:	e8 8a ff ff ff       	call   c0100f00 <print_stack_frame>
	printk("***\n");
c0100f76:	c7 04 24 b0 1e 10 c0 	movl   $0xc0101eb0,(%esp)
c0100f7d:	e8 2e fa ff ff       	call   c01009b0 <printk>
	
	// 致命错误发生后打印栈信息后停止在这里
	panicked = 1; // freeze other CPU
c0100f82:	c7 05 a0 50 10 c0 01 	movl   $0x1,0xc01050a0
c0100f89:	00 00 00 
c0100f8c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    asm volatile("movl %0,%%cr3" : : "r" (val));
}

static inline void hlt(void)
{
    __asm__ volatile ("hlt");
c0100f90:	f4                   	hlt    
c0100f91:	eb fd                	jmp    c0100f90 <panic+0x40>
c0100f93:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
c0100f99:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

c0100fa0 <print_current_status>:
		hlt();
	}
}

void print_current_status(void)
{
c0100fa0:	55                   	push   %ebp
c0100fa1:	89 e5                	mov    %esp,%ebp
c0100fa3:	83 ec 28             	sub    $0x28,%esp
	static int round = 0;
	uint16_t reg1, reg2, reg3, reg4;

	__asm__ volatile ( "mov %%cs, %0;"
c0100fa6:	8c 4d f0             	mov    %cs,-0x10(%ebp)
c0100fa9:	8c 5d f2             	mov    %ds,-0xe(%ebp)
c0100fac:	8c 45 f4             	mov    %es,-0xc(%ebp)
c0100faf:	8c 55 f6             	mov    %ss,-0xa(%ebp)
			   "mov %%es, %2;"
			   "mov %%ss, %3;"
			   : "=m"(reg1), "=m"(reg2), "=m"(reg3), "=m"(reg4));

	// 打印当前的运行级别
	printk("%d: @ring %d\n", round, reg1 & 0x3);
c0100fb2:	0f b7 45 f0          	movzwl -0x10(%ebp),%eax
c0100fb6:	c7 04 24 b5 1e 10 c0 	movl   $0xc0101eb5,(%esp)
c0100fbd:	83 e0 03             	and    $0x3,%eax
c0100fc0:	89 44 24 08          	mov    %eax,0x8(%esp)
c0100fc4:	a1 c4 a0 10 c0       	mov    0xc010a0c4,%eax
c0100fc9:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100fcd:	e8 de f9 ff ff       	call   c01009b0 <printk>
	printk("%d:  cs = %x\n", round, reg1);
c0100fd2:	0f b7 45 f0          	movzwl -0x10(%ebp),%eax
c0100fd6:	c7 04 24 c3 1e 10 c0 	movl   $0xc0101ec3,(%esp)
c0100fdd:	89 44 24 08          	mov    %eax,0x8(%esp)
c0100fe1:	a1 c4 a0 10 c0       	mov    0xc010a0c4,%eax
c0100fe6:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100fea:	e8 c1 f9 ff ff       	call   c01009b0 <printk>
	printk("%d:  ds = %x\n", round, reg2);
c0100fef:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
c0100ff3:	c7 04 24 d1 1e 10 c0 	movl   $0xc0101ed1,(%esp)
c0100ffa:	89 44 24 08          	mov    %eax,0x8(%esp)
c0100ffe:	a1 c4 a0 10 c0       	mov    0xc010a0c4,%eax
c0101003:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101007:	e8 a4 f9 ff ff       	call   c01009b0 <printk>
	printk("%d:  es = %x\n", round, reg3);
c010100c:	0f b7 45 f4          	movzwl -0xc(%ebp),%eax
c0101010:	c7 04 24 df 1e 10 c0 	movl   $0xc0101edf,(%esp)
c0101017:	89 44 24 08          	mov    %eax,0x8(%esp)
c010101b:	a1 c4 a0 10 c0       	mov    0xc010a0c4,%eax
c0101020:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101024:	e8 87 f9 ff ff       	call   c01009b0 <printk>
	printk("%d:  ss = %x\n", round, reg4);
c0101029:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
c010102d:	c7 04 24 ed 1e 10 c0 	movl   $0xc0101eed,(%esp)
c0101034:	89 44 24 08          	mov    %eax,0x8(%esp)
c0101038:	a1 c4 a0 10 c0       	mov    0xc010a0c4,%eax
c010103d:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101041:	e8 6a f9 ff ff       	call   c01009b0 <printk>
	++round;
c0101046:	83 05 c4 a0 10 c0 01 	addl   $0x1,0xc010a0c4
}
c010104d:	c9                   	leave  
c010104e:	c3                   	ret    

c010104f <stab_binsearch.constprop.0>:
 * this code:
 *      left = 0, right = 657;
 *      stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
 * will exit setting left = 118, right = 554.
 * */
static void stab_binsearch(const struct stab *stabs, 
c010104f:	55                   	push   %ebp
c0101050:	89 e5                	mov    %esp,%ebp
c0101052:	57                   	push   %edi
c0101053:	56                   	push   %esi
c0101054:	53                   	push   %ebx
c0101055:	83 ec 18             	sub    $0x18,%esp
	int *region_left, int *region_right, int type, uint32_t addr) 
{
    int l = *region_left, r = *region_right, any_matches = 0;
c0101058:	8b 30                	mov    (%eax),%esi
 * this code:
 *      left = 0, right = 657;
 *      stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
 * will exit setting left = 118, right = 554.
 * */
static void stab_binsearch(const struct stab *stabs, 
c010105a:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int *region_left, int *region_right, int type, uint32_t addr) 
{
    int l = *region_left, r = *region_right, any_matches = 0;
c010105d:	8b 02                	mov    (%edx),%eax
 * this code:
 *      left = 0, right = 657;
 *      stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
 * will exit setting left = 118, right = 554.
 * */
static void stab_binsearch(const struct stab *stabs, 
c010105f:	89 55 dc             	mov    %edx,-0x24(%ebp)
c0101062:	89 4d e8             	mov    %ecx,-0x18(%ebp)
	int *region_left, int *region_right, int type, uint32_t addr) 
{
    int l = *region_left, r = *region_right, any_matches = 0;
c0101065:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
c010106c:	89 45 f0             	mov    %eax,-0x10(%ebp)

    while (l <= r) {
c010106f:	3b 75 f0             	cmp    -0x10(%ebp),%esi
c0101072:	0f 8f 81 00 00 00    	jg     c01010f9 <stab_binsearch.constprop.0+0xaa>
        int true_m = (l + r) / 2, m = true_m;
c0101078:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010107b:	bf 02 00 00 00       	mov    $0x2,%edi
c0101080:	01 f0                	add    %esi,%eax
c0101082:	99                   	cltd   
c0101083:	f7 ff                	idiv   %edi
c0101085:	8b 55 e8             	mov    -0x18(%ebp),%edx
c0101088:	6b d8 0c             	imul   $0xc,%eax,%ebx
c010108b:	89 c1                	mov    %eax,%ecx
c010108d:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0101090:	81 c3 04 22 10 c0    	add    $0xc0102204,%ebx

        // search for earliest stab with right type
        while (m >= l && stabs[m].n_type != type) {
c0101096:	39 f1                	cmp    %esi,%ecx
c0101098:	0f 8c 92 00 00 00    	jl     c0101130 <stab_binsearch.constprop.0+0xe1>
c010109e:	89 df                	mov    %ebx,%edi
c01010a0:	83 eb 0c             	sub    $0xc,%ebx
c01010a3:	0f b6 47 04          	movzbl 0x4(%edi),%eax
c01010a7:	39 d0                	cmp    %edx,%eax
c01010a9:	74 03                	je     c01010ae <stab_binsearch.constprop.0+0x5f>
            m --;
c01010ab:	49                   	dec    %ecx
c01010ac:	eb e8                	jmp    c0101096 <stab_binsearch.constprop.0+0x47>
            continue;
        }

        // actual binary search
        any_matches = 1;
        if (stabs[m].n_value < addr) {
c01010ae:	8b 57 08             	mov    0x8(%edi),%edx
c01010b1:	3b 55 08             	cmp    0x8(%ebp),%edx
c01010b4:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01010b7:	73 11                	jae    c01010ca <stab_binsearch.constprop.0+0x7b>
            *region_left = m;
c01010b9:	8b 55 e0             	mov    -0x20(%ebp),%edx
            l = true_m + 1;
c01010bc:	8d 70 01             	lea    0x1(%eax),%esi
            l = true_m + 1;
            continue;
        }

        // actual binary search
        any_matches = 1;
c01010bf:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
        if (stabs[m].n_value < addr) {
            *region_left = m;
c01010c6:	89 0a                	mov    %ecx,(%edx)
c01010c8:	eb a5                	jmp    c010106f <stab_binsearch.constprop.0+0x20>
            l = true_m + 1;
        } else if (stabs[m].n_value > addr) {
c01010ca:	39 55 08             	cmp    %edx,0x8(%ebp)
c01010cd:	73 14                	jae    c01010e3 <stab_binsearch.constprop.0+0x94>
            *region_right = m - 1;
c01010cf:	8b 55 dc             	mov    -0x24(%ebp),%edx
c01010d2:	8d 41 ff             	lea    -0x1(%ecx),%eax
c01010d5:	89 45 f0             	mov    %eax,-0x10(%ebp)
            l = true_m + 1;
            continue;
        }

        // actual binary search
        any_matches = 1;
c01010d8:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
        if (stabs[m].n_value < addr) {
            *region_left = m;
            l = true_m + 1;
        } else if (stabs[m].n_value > addr) {
            *region_right = m - 1;
c01010df:	89 02                	mov    %eax,(%edx)
c01010e1:	eb 8c                	jmp    c010106f <stab_binsearch.constprop.0+0x20>
            r = m - 1;
        } else {
            // exact match for 'addr', but continue loop to find
            // *region_right
            *region_left = m;
c01010e3:	8b 45 e0             	mov    -0x20(%ebp),%eax
            l = m;
            addr ++;
c01010e6:	89 ce                	mov    %ecx,%esi
c01010e8:	ff 45 08             	incl   0x8(%ebp)
            l = true_m + 1;
            continue;
        }

        // actual binary search
        any_matches = 1;
c01010eb:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
            *region_right = m - 1;
            r = m - 1;
        } else {
            // exact match for 'addr', but continue loop to find
            // *region_right
            *region_left = m;
c01010f2:	89 08                	mov    %ecx,(%eax)
c01010f4:	e9 76 ff ff ff       	jmp    c010106f <stab_binsearch.constprop.0+0x20>
c01010f9:	8b 45 e0             	mov    -0x20(%ebp),%eax
            l = m;
            addr ++;
        }
    }

    if (!any_matches) {
c01010fc:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0101100:	8b 08                	mov    (%eax),%ecx
c0101102:	75 08                	jne    c010110c <stab_binsearch.constprop.0+0xbd>
        *region_right = *region_left - 1;
c0101104:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0101107:	49                   	dec    %ecx
c0101108:	89 08                	mov    %ecx,(%eax)
c010110a:	eb 2f                	jmp    c010113b <stab_binsearch.constprop.0+0xec>
    }
    else {
        // find rightmost region containing 'addr'
        l = *region_right;
c010110c:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010110f:	8b 5d e8             	mov    -0x18(%ebp),%ebx
c0101112:	8b 00                	mov    (%eax),%eax
        for (; l > *region_left && stabs[l].n_type != type; l --)
c0101114:	39 c1                	cmp    %eax,%ecx
c0101116:	7c 07                	jl     c010111f <stab_binsearch.constprop.0+0xd0>
            /* do nothing */;
        *region_left = l;
c0101118:	8b 75 e0             	mov    -0x20(%ebp),%esi
c010111b:	89 06                	mov    %eax,(%esi)
c010111d:	eb 1c                	jmp    c010113b <stab_binsearch.constprop.0+0xec>
c010111f:	6b d0 0c             	imul   $0xc,%eax,%edx
        *region_right = *region_left - 1;
    }
    else {
        // find rightmost region containing 'addr'
        l = *region_right;
        for (; l > *region_left && stabs[l].n_type != type; l --)
c0101122:	0f b6 92 08 22 10 c0 	movzbl -0x3fefddf8(%edx),%edx
c0101129:	39 da                	cmp    %ebx,%edx
c010112b:	74 eb                	je     c0101118 <stab_binsearch.constprop.0+0xc9>
c010112d:	48                   	dec    %eax
c010112e:	eb e4                	jmp    c0101114 <stab_binsearch.constprop.0+0xc5>
c0101130:	8b 45 ec             	mov    -0x14(%ebp),%eax
        // search for earliest stab with right type
        while (m >= l && stabs[m].n_type != type) {
            m --;
        }
        if (m < l) {    // no match in [l, m]
            l = true_m + 1;
c0101133:	8d 70 01             	lea    0x1(%eax),%esi
c0101136:	e9 34 ff ff ff       	jmp    c010106f <stab_binsearch.constprop.0+0x20>
        l = *region_right;
        for (; l > *region_left && stabs[l].n_type != type; l --)
            /* do nothing */;
        *region_left = l;
    }
}
c010113b:	83 c4 18             	add    $0x18,%esp
c010113e:	5b                   	pop    %ebx
c010113f:	5e                   	pop    %esi
c0101140:	5f                   	pop    %edi
c0101141:	5d                   	pop    %ebp
c0101142:	c3                   	ret    
c0101143:	66 90                	xchg   %ax,%ax
c0101145:	66 90                	xchg   %ax,%ax
c0101147:	66 90                	xchg   %ax,%ax
c0101149:	66 90                	xchg   %ax,%ax
c010114b:	66 90                	xchg   %ax,%ax
c010114d:	66 90                	xchg   %ax,%ax
c010114f:	90                   	nop

c0101150 <main>:
//__attribute__((noreturn))
// static void mpmain(void);
void startothers(void);

int main(void) 
{
c0101150:	55                   	push   %ebp
c0101151:	89 e5                	mov    %esp,%ebp
c0101153:	83 e4 f0             	and    $0xfffffff0,%esp
c0101156:	83 ec 10             	sub    $0x10,%esp
    console_clear();
c0101159:	e8 f2 f7 ff ff       	call   c0100950 <console_clear>
    printk("Begin init kernel...\n");
c010115e:	c7 04 24 fb 1e 10 c0 	movl   $0xc0101efb,(%esp)
c0101165:	e8 46 f8 ff ff       	call   c01009b0 <printk>

    PhysicMemoryInitialize();
c010116a:	e8 31 03 00 00       	call   c01014a0 <PhysicMemoryInitialize>

    panic("test");
c010116f:	c7 04 24 11 1f 10 c0 	movl   $0xc0101f11,(%esp)
c0101176:	e8 d5 fd ff ff       	call   c0100f50 <panic>
    
    // startothers();   // start other processors
    // first_user_proc_init();
    // mpmain();
    return 0;
}
c010117b:	31 c0                	xor    %eax,%eax
c010117d:	c9                   	leave  
c010117e:	c3                   	ret    
c010117f:	90                   	nop

c0101180 <memcmp>:
#include "types.h"

int memcmp(const void * buf1, const void * buf2, uint32_t count) 
{ 
c0101180:	55                   	push   %ebp
    if (!count) 
        return(0); 
c0101181:	31 c0                	xor    %eax,%eax
#include "types.h"

int memcmp(const void * buf1, const void * buf2, uint32_t count) 
{ 
c0101183:	89 e5                	mov    %esp,%ebp
c0101185:	53                   	push   %ebx
c0101186:	8b 5d 10             	mov    0x10(%ebp),%ebx
c0101189:	8b 4d 08             	mov    0x8(%ebp),%ecx
c010118c:	8b 55 0c             	mov    0xc(%ebp),%edx
    if (!count) 
c010118f:	85 db                	test   %ebx,%ebx
c0101191:	74 27                	je     c01011ba <memcmp+0x3a>
        return(0); 
 
    while (--count && *(char *)buf1 == *(char *)buf2) { 
c0101193:	89 d8                	mov    %ebx,%eax
c0101195:	83 e8 01             	sub    $0x1,%eax
c0101198:	75 11                	jne    c01011ab <memcmp+0x2b>
c010119a:	eb 16                	jmp    c01011b2 <memcmp+0x32>
c010119c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
        buf1 = (char *)buf1 + 1; 
c01011a0:	83 c1 01             	add    $0x1,%ecx
        buf2 = (char *)buf2 + 1; 
c01011a3:	83 c2 01             	add    $0x1,%edx
int memcmp(const void * buf1, const void * buf2, uint32_t count) 
{ 
    if (!count) 
        return(0); 
 
    while (--count && *(char *)buf1 == *(char *)buf2) { 
c01011a6:	83 e8 01             	sub    $0x1,%eax
c01011a9:	74 07                	je     c01011b2 <memcmp+0x32>
c01011ab:	0f b6 1a             	movzbl (%edx),%ebx
c01011ae:	38 19                	cmp    %bl,(%ecx)
c01011b0:	74 ee                	je     c01011a0 <memcmp+0x20>
        buf1 = (char *)buf1 + 1; 
        buf2 = (char *)buf2 + 1; 
    } 
 
    return(*((unsigned char *)buf1) - *((unsigned char *)buf2));
c01011b2:	0f b6 01             	movzbl (%ecx),%eax
c01011b5:	0f b6 12             	movzbl (%edx),%edx
c01011b8:	29 d0                	sub    %edx,%eax
} 
c01011ba:	5b                   	pop    %ebx
c01011bb:	5d                   	pop    %ebp
c01011bc:	c3                   	ret    
c01011bd:	8d 76 00             	lea    0x0(%esi),%esi

c01011c0 <memcpy>:

void *memcpy(void *dest, const void *src, uint32_t count)
{
c01011c0:	55                   	push   %ebp
    char *tmp = dest;
    const char *s = src;
    while (count--)
c01011c1:	31 d2                	xor    %edx,%edx
 
    return(*((unsigned char *)buf1) - *((unsigned char *)buf2));
} 

void *memcpy(void *dest, const void *src, uint32_t count)
{
c01011c3:	89 e5                	mov    %esp,%ebp
c01011c5:	56                   	push   %esi
c01011c6:	8b 45 08             	mov    0x8(%ebp),%eax
c01011c9:	53                   	push   %ebx
c01011ca:	8b 5d 10             	mov    0x10(%ebp),%ebx
c01011cd:	8b 75 0c             	mov    0xc(%ebp),%esi
    char *tmp = dest;
    const char *s = src;
    while (count--)
c01011d0:	85 db                	test   %ebx,%ebx
c01011d2:	74 12                	je     c01011e6 <memcpy+0x26>
c01011d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
        *tmp++ = *s++;
c01011d8:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
c01011dc:	88 0c 10             	mov    %cl,(%eax,%edx,1)
c01011df:	83 c2 01             	add    $0x1,%edx

void *memcpy(void *dest, const void *src, uint32_t count)
{
    char *tmp = dest;
    const char *s = src;
    while (count--)
c01011e2:	39 da                	cmp    %ebx,%edx
c01011e4:	75 f2                	jne    c01011d8 <memcpy+0x18>
        *tmp++ = *s++;
    return dest;
}
c01011e6:	5b                   	pop    %ebx
c01011e7:	5e                   	pop    %esi
c01011e8:	5d                   	pop    %ebp
c01011e9:	c3                   	ret    
c01011ea:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

c01011f0 <memmove>:

void *memmove(void *dest, const void *src, uint32_t count)
{
c01011f0:	55                   	push   %ebp
c01011f1:	89 e5                	mov    %esp,%ebp
c01011f3:	8b 45 08             	mov    0x8(%ebp),%eax
c01011f6:	56                   	push   %esi
c01011f7:	8b 75 0c             	mov    0xc(%ebp),%esi
c01011fa:	53                   	push   %ebx
c01011fb:	8b 5d 10             	mov    0x10(%ebp),%ebx
    char *tmp;
    const char *s;

    if (dest <= src) {
c01011fe:	39 f0                	cmp    %esi,%eax
c0101200:	77 1e                	ja     c0101220 <memmove+0x30>
        tmp = dest;
        s = src;
        while (count--)
c0101202:	31 d2                	xor    %edx,%edx
c0101204:	85 db                	test   %ebx,%ebx
c0101206:	74 0e                	je     c0101216 <memmove+0x26>
        *tmp++ = *s++;
c0101208:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
c010120c:	88 0c 10             	mov    %cl,(%eax,%edx,1)
c010120f:	83 c2 01             	add    $0x1,%edx
    const char *s;

    if (dest <= src) {
        tmp = dest;
        s = src;
        while (count--)
c0101212:	39 da                	cmp    %ebx,%edx
c0101214:	75 f2                	jne    c0101208 <memmove+0x18>
        s += count;
        while (count--)
        *--tmp = *--s;
    }
    return dest;
}
c0101216:	5b                   	pop    %ebx
c0101217:	5e                   	pop    %esi
c0101218:	5d                   	pop    %ebp
c0101219:	c3                   	ret    
c010121a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
    } 
    else {
        tmp = dest;
        tmp += count;
        s = src;
        s += count;
c0101220:	01 de                	add    %ebx,%esi
        while (count--)
c0101222:	85 db                	test   %ebx,%ebx
        while (count--)
        *tmp++ = *s++;
    } 
    else {
        tmp = dest;
        tmp += count;
c0101224:	8d 0c 18             	lea    (%eax,%ebx,1),%ecx
        s = src;
        s += count;
        while (count--)
c0101227:	8d 53 ff             	lea    -0x1(%ebx),%edx
c010122a:	74 ea                	je     c0101216 <memmove+0x26>
c010122c:	f7 db                	neg    %ebx
c010122e:	01 de                	add    %ebx,%esi
c0101230:	01 cb                	add    %ecx,%ebx
c0101232:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
        *--tmp = *--s;
c0101238:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
c010123c:	88 0c 13             	mov    %cl,(%ebx,%edx,1)
    else {
        tmp = dest;
        tmp += count;
        s = src;
        s += count;
        while (count--)
c010123f:	83 ea 01             	sub    $0x1,%edx
c0101242:	83 fa ff             	cmp    $0xffffffff,%edx
c0101245:	75 f1                	jne    c0101238 <memmove+0x48>
        *--tmp = *--s;
    }
    return dest;
}
c0101247:	5b                   	pop    %ebx
c0101248:	5e                   	pop    %esi
c0101249:	5d                   	pop    %ebp
c010124a:	c3                   	ret    
c010124b:	90                   	nop
c010124c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

c0101250 <memset>:

void memset(void *dest, uint8_t val, uint32_t len)
{
c0101250:	55                   	push   %ebp
c0101251:	89 e5                	mov    %esp,%ebp
c0101253:	53                   	push   %ebx
c0101254:	8b 5d 10             	mov    0x10(%ebp),%ebx
c0101257:	8b 45 08             	mov    0x8(%ebp),%eax
c010125a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
    uint8_t *dst = (uint8_t *)dest;
    for (; len != 0; len--) {
c010125e:	85 db                	test   %ebx,%ebx
c0101260:	8d 14 18             	lea    (%eax,%ebx,1),%edx
c0101263:	74 0d                	je     c0101272 <memset+0x22>
c0101265:	8d 76 00             	lea    0x0(%esi),%esi
        *dst++ = val;
c0101268:	83 c0 01             	add    $0x1,%eax
}

void memset(void *dest, uint8_t val, uint32_t len)
{
    uint8_t *dst = (uint8_t *)dest;
    for (; len != 0; len--) {
c010126b:	39 d0                	cmp    %edx,%eax
        *dst++ = val;
c010126d:	88 48 ff             	mov    %cl,-0x1(%eax)
}

void memset(void *dest, uint8_t val, uint32_t len)
{
    uint8_t *dst = (uint8_t *)dest;
    for (; len != 0; len--) {
c0101270:	75 f6                	jne    c0101268 <memset+0x18>
        *dst++ = val;
    }
}
c0101272:	5b                   	pop    %ebx
c0101273:	5d                   	pop    %ebp
c0101274:	c3                   	ret    
c0101275:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
c0101279:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

c0101280 <bzero>:

void bzero(void *dest, uint32_t len)
{
c0101280:	55                   	push   %ebp
c0101281:	89 e5                	mov    %esp,%ebp
c0101283:	8b 4d 0c             	mov    0xc(%ebp),%ecx
c0101286:	8b 45 08             	mov    0x8(%ebp),%eax
}

void memset(void *dest, uint8_t val, uint32_t len)
{
    uint8_t *dst = (uint8_t *)dest;
    for (; len != 0; len--) {
c0101289:	85 c9                	test   %ecx,%ecx
c010128b:	8d 14 08             	lea    (%eax,%ecx,1),%edx
c010128e:	74 0b                	je     c010129b <bzero+0x1b>
        *dst++ = val;
c0101290:	83 c0 01             	add    $0x1,%eax
}

void memset(void *dest, uint8_t val, uint32_t len)
{
    uint8_t *dst = (uint8_t *)dest;
    for (; len != 0; len--) {
c0101293:	39 d0                	cmp    %edx,%eax
        *dst++ = val;
c0101295:	c6 40 ff 00          	movb   $0x0,-0x1(%eax)
}

void memset(void *dest, uint8_t val, uint32_t len)
{
    uint8_t *dst = (uint8_t *)dest;
    for (; len != 0; len--) {
c0101299:	75 f5                	jne    c0101290 <bzero+0x10>
}

void bzero(void *dest, uint32_t len)
{
    memset(dest, 0, len);
}
c010129b:	5d                   	pop    %ebp
c010129c:	c3                   	ret    
c010129d:	8d 76 00             	lea    0x0(%esi),%esi

c01012a0 <strcmp>:

int strcmp(const char *dest, const char *src)
{
c01012a0:	55                   	push   %ebp
c01012a1:	89 e5                	mov    %esp,%ebp
c01012a3:	56                   	push   %esi
c01012a4:	8b 55 08             	mov    0x8(%ebp),%edx
c01012a7:	53                   	push   %ebx
c01012a8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
c01012ab:	eb 0f                	jmp    c01012bc <strcmp+0x1c>
c01012ad:	8d 76 00             	lea    0x0(%esi),%esi
    int ret = 0 ;
    while(!(ret = *(unsigned char *)src - *(unsigned char *)dest) && *dest) {
c01012b0:	89 f3                	mov    %esi,%ebx
c01012b2:	84 db                	test   %bl,%bl
c01012b4:	74 24                	je     c01012da <strcmp+0x3a>
        ++src;
c01012b6:	83 c1 01             	add    $0x1,%ecx
        ++dest;
c01012b9:	83 c2 01             	add    $0x1,%edx
}

int strcmp(const char *dest, const char *src)
{
    int ret = 0 ;
    while(!(ret = *(unsigned char *)src - *(unsigned char *)dest) && *dest) {
c01012bc:	0f b6 32             	movzbl (%edx),%esi
c01012bf:	0f b6 01             	movzbl (%ecx),%eax
c01012c2:	89 f3                	mov    %esi,%ebx
c01012c4:	0f b6 db             	movzbl %bl,%ebx
c01012c7:	29 d8                	sub    %ebx,%eax
c01012c9:	74 e5                	je     c01012b0 <strcmp+0x10>
c01012cb:	31 d2                	xor    %edx,%edx
c01012cd:	85 c0                	test   %eax,%eax
c01012cf:	0f 95 c2             	setne  %dl
c01012d2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c01012d7:	0f 49 c2             	cmovns %edx,%eax
    else if (ret > 0) {
        ret = 1;
    }

    return ret;
}
c01012da:	5b                   	pop    %ebx
c01012db:	5e                   	pop    %esi
c01012dc:	5d                   	pop    %ebp
c01012dd:	c3                   	ret    
c01012de:	66 90                	xchg   %ax,%ax

c01012e0 <strcpy>:

char *strcpy(char *dest, const char *src)
{
c01012e0:	55                   	push   %ebp
c01012e1:	89 e5                	mov    %esp,%ebp
c01012e3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
c01012e6:	53                   	push   %ebx
c01012e7:	8b 45 08             	mov    0x8(%ebp),%eax
    char *tmp = dest;
    while (*src) {
c01012ea:	0f b6 11             	movzbl (%ecx),%edx
c01012ed:	89 c3                	mov    %eax,%ebx
c01012ef:	84 d2                	test   %dl,%dl
c01012f1:	74 15                	je     c0101308 <strcpy+0x28>
c01012f3:	90                   	nop
c01012f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
        *dest++ = *src++;
c01012f8:	83 c3 01             	add    $0x1,%ebx
c01012fb:	83 c1 01             	add    $0x1,%ecx
c01012fe:	88 53 ff             	mov    %dl,-0x1(%ebx)
}

char *strcpy(char *dest, const char *src)
{
    char *tmp = dest;
    while (*src) {
c0101301:	0f b6 11             	movzbl (%ecx),%edx
c0101304:	84 d2                	test   %dl,%dl
c0101306:	75 f0                	jne    c01012f8 <strcpy+0x18>
        *dest++ = *src++;
    }

    *dest = '\0';
c0101308:	c6 03 00             	movb   $0x0,(%ebx)
    return tmp;
}
c010130b:	5b                   	pop    %ebx
c010130c:	5d                   	pop    %ebp
c010130d:	c3                   	ret    
c010130e:	66 90                	xchg   %ax,%ax

c0101310 <strncpy>:

char *strncpy(char *dest, const char *src, uint32_t len)
{
c0101310:	55                   	push   %ebp
c0101311:	89 e5                	mov    %esp,%ebp
c0101313:	56                   	push   %esi
c0101314:	8b 75 10             	mov    0x10(%ebp),%esi
c0101317:	8b 45 08             	mov    0x8(%ebp),%eax
c010131a:	53                   	push   %ebx
c010131b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
    char *dst = dest;
    while (len > 0) {
c010131e:	85 f6                	test   %esi,%esi
c0101320:	89 c3                	mov    %eax,%ebx
c0101322:	75 0d                	jne    c0101331 <strncpy+0x21>
c0101324:	eb 17                	jmp    c010133d <strncpy+0x2d>
c0101326:	66 90                	xchg   %ax,%ax
        while (*src) {
            *dest++ = *src++;
c0101328:	83 c3 01             	add    $0x1,%ebx
c010132b:	83 c1 01             	add    $0x1,%ecx
c010132e:	88 53 ff             	mov    %dl,-0x1(%ebx)

char *strncpy(char *dest, const char *src, uint32_t len)
{
    char *dst = dest;
    while (len > 0) {
        while (*src) {
c0101331:	0f b6 11             	movzbl (%ecx),%edx
c0101334:	84 d2                	test   %dl,%dl
c0101336:	75 f0                	jne    c0101328 <strncpy+0x18>
}

char *strncpy(char *dest, const char *src, uint32_t len)
{
    char *dst = dest;
    while (len > 0) {
c0101338:	83 ee 01             	sub    $0x1,%esi
c010133b:	75 f4                	jne    c0101331 <strncpy+0x21>
            *dest++ = *src++;
        }
        len--;
    }

    *dest = '\0';
c010133d:	c6 03 00             	movb   $0x0,(%ebx)
    return dst;
}
c0101340:	5b                   	pop    %ebx
c0101341:	5e                   	pop    %esi
c0101342:	5d                   	pop    %ebp
c0101343:	c3                   	ret    
c0101344:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
c010134a:	8d bf 00 00 00 00    	lea    0x0(%edi),%edi

c0101350 <strcat>:

char *strcat(char *dest, const char *src)
{
c0101350:	55                   	push   %ebp
c0101351:	89 e5                	mov    %esp,%ebp
c0101353:	8b 45 08             	mov    0x8(%ebp),%eax
c0101356:	53                   	push   %ebx
c0101357:	8b 4d 0c             	mov    0xc(%ebp),%ecx
    char *cp = dest;
    while (*cp) {
c010135a:	80 38 00             	cmpb   $0x0,(%eax)
c010135d:	89 c2                	mov    %eax,%edx
c010135f:	74 0f                	je     c0101370 <strcat+0x20>
c0101361:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
        cp++;
c0101368:	83 c2 01             	add    $0x1,%edx
}

char *strcat(char *dest, const char *src)
{
    char *cp = dest;
    while (*cp) {
c010136b:	80 3a 00             	cmpb   $0x0,(%edx)
c010136e:	75 f8                	jne    c0101368 <strcat+0x18>
        cp++;
    }

    while ((*cp++ = *src++))
c0101370:	83 c1 01             	add    $0x1,%ecx
c0101373:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
c0101377:	83 c2 01             	add    $0x1,%edx
c010137a:	84 db                	test   %bl,%bl
c010137c:	88 5a ff             	mov    %bl,-0x1(%edx)
c010137f:	75 ef                	jne    c0101370 <strcat+0x20>
        ;

    return dest;
}
c0101381:	5b                   	pop    %ebx
c0101382:	5d                   	pop    %ebp
c0101383:	c3                   	ret    
c0101384:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
c010138a:	8d bf 00 00 00 00    	lea    0x0(%edi),%edi

c0101390 <strlen>:

int strlen(const char *src)
{
c0101390:	55                   	push   %ebp
c0101391:	89 e5                	mov    %esp,%ebp
c0101393:	8b 55 08             	mov    0x8(%ebp),%edx
    const char *eos = src;
c0101396:	89 d0                	mov    %edx,%eax
    while (*eos++)
c0101398:	83 c0 01             	add    $0x1,%eax
c010139b:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
c010139f:	75 f7                	jne    c0101398 <strlen+0x8>
        ;

    return (eos - src - 1);
c01013a1:	29 d0                	sub    %edx,%eax
c01013a3:	83 e8 01             	sub    $0x1,%eax
}
c01013a6:	5d                   	pop    %ebp
c01013a7:	c3                   	ret    
c01013a8:	90                   	nop
c01013a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

c01013b0 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char* safestrcpy(char *s, const char *t, int n)
{
c01013b0:	55                   	push   %ebp
c01013b1:	89 e5                	mov    %esp,%ebp
c01013b3:	8b 4d 10             	mov    0x10(%ebp),%ecx
c01013b6:	56                   	push   %esi
c01013b7:	8b 45 08             	mov    0x8(%ebp),%eax
c01013ba:	53                   	push   %ebx
c01013bb:	8b 55 0c             	mov    0xc(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
c01013be:	85 c9                	test   %ecx,%ecx
c01013c0:	7e 26                	jle    c01013e8 <safestrcpy+0x38>
c01013c2:	8d 74 0a ff          	lea    -0x1(%edx,%ecx,1),%esi
c01013c6:	89 c1                	mov    %eax,%ecx
c01013c8:	eb 17                	jmp    c01013e1 <safestrcpy+0x31>
c01013ca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
c01013d0:	83 c2 01             	add    $0x1,%edx
c01013d3:	0f b6 5a ff          	movzbl -0x1(%edx),%ebx
c01013d7:	83 c1 01             	add    $0x1,%ecx
c01013da:	84 db                	test   %bl,%bl
c01013dc:	88 59 ff             	mov    %bl,-0x1(%ecx)
c01013df:	74 04                	je     c01013e5 <safestrcpy+0x35>
c01013e1:	39 f2                	cmp    %esi,%edx
c01013e3:	75 eb                	jne    c01013d0 <safestrcpy+0x20>
    ;
  *s = 0;
c01013e5:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
c01013e8:	5b                   	pop    %ebx
c01013e9:	5e                   	pop    %esi
c01013ea:	5d                   	pop    %ebp
c01013eb:	c3                   	ret    
c01013ec:	66 90                	xchg   %ax,%ax
c01013ee:	66 90                	xchg   %ax,%ax

c01013f0 <ProbesMemory>:
/**
 * detect memory in protected mode 
 * return memory size detected in KB.
 */
unsigned int ProbesMemory(void)
{
c01013f0:	55                   	push   %ebp
c01013f1:	89 e5                	mov    %esp,%ebp
c01013f3:	57                   	push   %edi
c01013f4:	56                   	push   %esi
c01013f5:	53                   	push   %ebx

static inline uint8_t inb(uint16_t port)
{
    uint8_t data;

    asm volatile("in %1,%0" : "=a" (data) : "d" (port));
c01013f6:	bb 21 00 00 00       	mov    $0x21,%ebx
c01013fb:	83 ec 03             	sub    $0x3,%esp
c01013fe:	89 da                	mov    %ebx,%edx
c0101400:	ec                   	in     (%dx),%al
c0101401:	b9 a1 00 00 00       	mov    $0xa1,%ecx
c0101406:	88 45 f3             	mov    %al,-0xd(%ebp)
c0101409:	89 ca                	mov    %ecx,%edx
c010140b:	ec                   	in     (%dx),%al
c010140c:	88 45 f2             	mov    %al,-0xe(%ebp)
                             "memory", "cc");
}

static inline void outb(uint16_t port, uint8_t data)
{
    asm volatile("out %0,%1" : : "a" (data), "d" (port));
c010140f:	89 da                	mov    %ebx,%edx
c0101411:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c0101416:	ee                   	out    %al,(%dx)
c0101417:	89 ca                	mov    %ecx,%edx
c0101419:	ee                   	out    %al,(%dx)
    memCount = 0;
    memKB = 0;

    // store a copy of CR0
	//asm volatile ("movl %%cr0, %%eax":"=a"(cr0)::"eax");
    asm volatile("movl %%cr0, %0" : "=r" (cr0));
c010141a:	0f 20 c7             	mov    %cr0,%edi

	// invalidate the cache
	// write-back and invalidate the cache
	asm volatile ("wbinvd");
c010141d:	0f 09                	wbinvd 

	// plug cr0 with just PE/CD/NW
	// cache disable(486+), no-writeback(486+), 32bit mode(386+)
    asm volatile("movl %0, %%cr0" : : "r" (cr0 | 0x00000001 | 0x40000000 | 0x20000000));
c010141f:	89 f8                	mov    %edi,%eax
c0101421:	0d 01 00 00 60       	or     $0x60000001,%eax
c0101426:	0f 22 c0             	mov    %eax,%cr0

    /* kill all IRQ's */
    outb(0x21, 0xFF);
    outb(0xA1, 0xFF);

    memCount = 0;
c0101429:	31 d2                	xor    %edx,%edx
    memKB = 0;
c010142b:	30 c9                	xor    %cl,%cl
c010142d:	eb 0b                	jmp    c010143a <ProbesMemory+0x4a>
c010142f:	90                   	nop
c0101430:	31 c0                	xor    %eax,%eax
            memCount = 0;
		else {
			*mem = 0xAA55AA55;
			asm("":::"memory");
			if(*mem != 0xAA55AA55)
			memCount = 0;
c0101432:	31 d2                	xor    %edx,%edx
		}

		asm("":::"memory");
		*mem = a;
	} while (memKB < 4096 && memCount != 0);
c0101434:	84 c0                	test   %al,%al
			if(*mem != 0xAA55AA55)
			memCount = 0;
		}

		asm("":::"memory");
		*mem = a;
c0101436:	89 33                	mov    %esi,(%ebx)
	} while (memKB < 4096 && memCount != 0);
c0101438:	74 46                	je     c0101480 <ProbesMemory+0x90>
	// cache disable(486+), no-writeback(486+), 32bit mode(386+)
    asm volatile("movl %0, %%cr0" : : "r" (cr0 | 0x00000001 | 0x40000000 | 0x20000000));

	do {
		memKB++;
		memCount += 1024*1024;
c010143a:	81 c2 00 00 10 00    	add    $0x100000,%edx
        mem = (unsigned long*)memCount;

		a = *mem;
c0101440:	8b 32                	mov    (%edx),%esi
	// plug cr0 with just PE/CD/NW
	// cache disable(486+), no-writeback(486+), 32bit mode(386+)
    asm volatile("movl %0, %%cr0" : : "r" (cr0 | 0x00000001 | 0x40000000 | 0x20000000));

	do {
		memKB++;
c0101442:	83 c1 01             	add    $0x1,%ecx
		memCount += 1024*1024;
        mem = (unsigned long*)memCount;
c0101445:	89 d3                	mov    %edx,%ebx

		a = *mem;
		*mem = 0x55AA55AA;
c0101447:	c7 02 aa 55 aa 55    	movl   $0x55aa55aa,(%edx)

        // the empty asm calls tell gcc not to rely on what's in its registers
        // as saved variables (this avoids GCC optimisations)
		asm("":::"memory");
		if (*mem != 0x55AA55AA) 
c010144d:	81 3a aa 55 aa 55    	cmpl   $0x55aa55aa,(%edx)
c0101453:	75 db                	jne    c0101430 <ProbesMemory+0x40>
            memCount = 0;
		else {
			*mem = 0xAA55AA55;
c0101455:	c7 02 55 aa 55 aa    	movl   $0xaa55aa55,(%edx)
			asm("":::"memory");
			if(*mem != 0xAA55AA55)
c010145b:	81 3a 55 aa 55 aa    	cmpl   $0xaa55aa55,(%edx)
c0101461:	75 cd                	jne    c0101430 <ProbesMemory+0x40>
c0101463:	66 81 f9 ff 0f       	cmp    $0xfff,%cx
c0101468:	0f 96 c0             	setbe  %al
c010146b:	85 d2                	test   %edx,%edx
c010146d:	0f 95 45 f1          	setne  -0xf(%ebp)
c0101471:	22 45 f1             	and    -0xf(%ebp),%al
			memCount = 0;
		}

		asm("":::"memory");
		*mem = a;
	} while (memKB < 4096 && memCount != 0);
c0101474:	84 c0                	test   %al,%al
			if(*mem != 0xAA55AA55)
			memCount = 0;
		}

		asm("":::"memory");
		*mem = a;
c0101476:	89 33                	mov    %esi,(%ebx)
	} while (memKB < 4096 && memCount != 0);
c0101478:	75 c0                	jne    c010143a <ProbesMemory+0x4a>
c010147a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

    asm volatile("movl %0, %%cr0" : : "r" (cr0));
c0101480:	0f 22 c7             	mov    %edi,%cr0
c0101483:	ba 21 00 00 00       	mov    $0x21,%edx
c0101488:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c010148c:	ee                   	out    %al,(%dx)
c010148d:	b2 a1                	mov    $0xa1,%dl
c010148f:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
c0101493:	ee                   	out    %al,(%dx)
//  
	outb(0x21, irq1);
	outb(0xA1, irq2);

    return memKB;// << 20;
c0101494:	83 c4 03             	add    $0x3,%esp
// 	bse_end = (*mem & 0xFFFF) <<6;
//  
	outb(0x21, irq1);
	outb(0xA1, irq2);

    return memKB;// << 20;
c0101497:	0f b7 c1             	movzwl %cx,%eax
c010149a:	5b                   	pop    %ebx
c010149b:	5e                   	pop    %esi
c010149c:	5f                   	pop    %edi
c010149d:	5d                   	pop    %ebp
c010149e:	c3                   	ret    
c010149f:	90                   	nop

c01014a0 <PhysicMemoryInitialize>:
        page++;
    }
}

void PhysicMemoryInitialize(void)
{
c01014a0:	55                   	push   %ebp
c01014a1:	89 e5                	mov    %esp,%ebp
c01014a3:	57                   	push   %edi
c01014a4:	56                   	push   %esi
c01014a5:	53                   	push   %ebx
c01014a6:	83 ec 1c             	sub    $0x1c,%esp
    printk("Physic memory initialize...\n");
c01014a9:	c7 04 24 16 1f 10 c0 	movl   $0xc0101f16,(%esp)
c01014b0:	e8 fb f4 ff ff       	call   c01009b0 <printk>

    assert(MemorySizeInKB != 0 && "Memory size must success.");
c01014b5:	8b 15 0c 00 10 c0    	mov    0xc010000c,%edx
c01014bb:	85 d2                	test   %edx,%edx
c01014bd:	0f 84 05 02 00 00    	je     c01016c8 <PhysicMemoryInitialize+0x228>

    memorySize = MemorySizeInKB << 20;
c01014c3:	c1 e2 14             	shl    $0x14,%edx
    uint32_t nPages = memorySize / PAGE_SIZE;

    pages = (Page*)PGROUNDUP((void*)end);
c01014c6:	b8 87 c1 10 c0       	mov    $0xc010c187,%eax
    printk("Physic memory initialize...\n");

    assert(MemorySizeInKB != 0 && "Memory size must success.");

    memorySize = MemorySizeInKB << 20;
    uint32_t nPages = memorySize / PAGE_SIZE;
c01014cb:	89 d7                	mov    %edx,%edi

    pages = (Page*)PGROUNDUP((void*)end);
c01014cd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    printk("Physic memory initialize...\n");

    assert(MemorySizeInKB != 0 && "Memory size must success.");

    memorySize = MemorySizeInKB << 20;
    uint32_t nPages = memorySize / PAGE_SIZE;
c01014d2:	c1 ef 0c             	shr    $0xc,%edi
    // extern pde_t entrypgdir[];
    // dump_page_table(entrypgdir, 1);
    // // return ;

    FreeAreaInitialize(&freeArea);
    for (int i = 0; i < nPages; ++i) {
c01014d5:	31 f6                	xor    %esi,%esi

    memorySize = MemorySizeInKB << 20;
    uint32_t nPages = memorySize / PAGE_SIZE;

    pages = (Page*)PGROUNDUP((void*)end);
    freeMemoryBeginAt = (uint32_t*)V2P((uint32_t*)(pages + nPages));
c01014d7:	8d 0c 7f             	lea    (%edi,%edi,2),%ecx

    printk("\tDetected memory size: 0x%x\n", memorySize);
c01014da:	89 54 24 04          	mov    %edx,0x4(%esp)
    assert(MemorySizeInKB != 0 && "Memory size must success.");

    memorySize = MemorySizeInKB << 20;
    uint32_t nPages = memorySize / PAGE_SIZE;

    pages = (Page*)PGROUNDUP((void*)end);
c01014de:	a3 84 b1 10 c0       	mov    %eax,0xc010b184
    freeMemoryBeginAt = (uint32_t*)V2P((uint32_t*)(pages + nPages));
c01014e3:	8d 84 c8 00 00 00 40 	lea    0x40000000(%eax,%ecx,8),%eax

    printk("\tDetected memory size: 0x%x\n", memorySize);
c01014ea:	c7 04 24 33 1f 10 c0 	movl   $0xc0101f33,(%esp)
{
    printk("Physic memory initialize...\n");

    assert(MemorySizeInKB != 0 && "Memory size must success.");

    memorySize = MemorySizeInKB << 20;
c01014f1:	89 15 80 b1 10 c0    	mov    %edx,0xc010b180
    uint32_t nPages = memorySize / PAGE_SIZE;

    pages = (Page*)PGROUNDUP((void*)end);
    freeMemoryBeginAt = (uint32_t*)V2P((uint32_t*)(pages + nPages));
c01014f7:	a3 6c b1 10 c0       	mov    %eax,0xc010b16c

    printk("\tDetected memory size: 0x%x\n", memorySize);
c01014fc:	e8 af f4 ff ff       	call   c01009b0 <printk>
    printk("\ttotal pages is: 0x%x\n", nPages);
c0101501:	89 7c 24 04          	mov    %edi,0x4(%esp)
c0101505:	c7 04 24 50 1f 10 c0 	movl   $0xc0101f50,(%esp)
c010150c:	e8 9f f4 ff ff       	call   c01009b0 <printk>
    printk("\tkernel load end at: 0x%p\n", V2P(end));
c0101511:	c7 44 24 04 88 b1 10 	movl   $0x10b188,0x4(%esp)
c0101518:	00 
c0101519:	c7 04 24 67 1f 10 c0 	movl   $0xc0101f67,(%esp)
c0101520:	e8 8b f4 ff ff       	call   c01009b0 <printk>
    printk("\tpages virtual begin at: 0x%p\n", pages);
c0101525:	a1 84 b1 10 c0       	mov    0xc010b184,%eax
c010152a:	c7 04 24 00 20 10 c0 	movl   $0xc0102000,(%esp)
c0101531:	89 44 24 04          	mov    %eax,0x4(%esp)
c0101535:	e8 76 f4 ff ff       	call   c01009b0 <printk>
    printk("\tfree physic memory begin at: 0x%p\n", freeMemoryBeginAt);
c010153a:	a1 6c b1 10 c0       	mov    0xc010b16c,%eax
c010153f:	c7 04 24 20 20 10 c0 	movl   $0xc0102020,(%esp)
c0101546:	89 44 24 04          	mov    %eax,0x4(%esp)
c010154a:	e8 61 f4 ff ff       	call   c01009b0 <printk>
    // extern pde_t entrypgdir[];
    // dump_page_table(entrypgdir, 1);
    // // return ;

    FreeAreaInitialize(&freeArea);
    for (int i = 0; i < nPages; ++i) {
c010154f:	31 c0                	xor    %eax,%eax
c0101551:	85 ff                	test   %edi,%edi
    node->list = NULL;
}

static inline void list_init(struct list_t *list) {
    assert(list != NULL);
    list->head = NULL;
c0101553:	c7 05 70 b1 10 c0 00 	movl   $0x0,0xc010b170
c010155a:	00 00 00 
    list->tail = NULL;
c010155d:	c7 05 74 b1 10 c0 00 	movl   $0x0,0xc010b174
c0101564:	00 00 00 
    list->size = 0;
c0101567:	c7 05 78 b1 10 c0 00 	movl   $0x0,0xc010b178
c010156e:	00 00 00 
static void FreeAreaInitialize(FreePhysicArea *freeArea) 
{
    assert(freeArea && "null ptr exception.");

    list_init(&freeArea->list);
    freeArea->freeNumbers = 0;
c0101571:	c7 05 7c b1 10 c0 00 	movl   $0x0,0xc010b17c
c0101578:	00 00 00 
    // extern pde_t entrypgdir[];
    // dump_page_table(entrypgdir, 1);
    // // return ;

    FreeAreaInitialize(&freeArea);
    for (int i = 0; i < nPages; ++i) {
c010157b:	74 48                	je     c01015c5 <PhysicMemoryInitialize+0x125>
c010157d:	8d 76 00             	lea    0x0(%esi),%esi
        PageInitialize(pages + i);
c0101580:	8d 14 40             	lea    (%eax,%eax,2),%edx
c0101583:	a1 84 b1 10 c0       	mov    0xc010b184,%eax
c0101588:	8d 1c d0             	lea    (%eax,%edx,8),%ebx
    freeArea->freeNumbers = 0;
}

static void PageInitialize(Page *page) 
{
    assert(page && "null ptr exception");
c010158b:	85 db                	test   %ebx,%ebx
c010158d:	0f 84 1d 01 00 00    	je     c01016b0 <PhysicMemoryInitialize+0x210>
    // extern pde_t entrypgdir[];
    // dump_page_table(entrypgdir, 1);
    // // return ;

    FreeAreaInitialize(&freeArea);
    for (int i = 0; i < nPages; ++i) {
c0101593:	83 c6 01             	add    $0x1,%esi
c0101596:	39 fe                	cmp    %edi,%esi
c0101598:	89 f0                	mov    %esi,%eax
static void PageInitialize(Page *page) 
{
    assert(page && "null ptr exception");

    /* default property is  PG_Reserved */
    page->ref = 0;
c010159a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
    page->flags = PG_Reserved;
c01015a0:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
    page->property = 0;
c01015a7:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        tmpname != list_end();                  \
        tmpname = list_node_prev(tmpname))

static inline void list_node_init(struct list_node_t *node) {
    assert(node != NULL);
    node->prev = list_end();
c01015ae:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    node->next = list_end();
c01015b5:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
    node->list = NULL;
c01015bc:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
    // extern pde_t entrypgdir[];
    // dump_page_table(entrypgdir, 1);
    // // return ;

    FreeAreaInitialize(&freeArea);
    for (int i = 0; i < nPages; ++i) {
c01015c3:	75 bb                	jne    c0101580 <PhysicMemoryInitialize+0xe0>
        PageInitialize(pages + i);
    }

    uint32_t totalPages = (memorySize - (uint32_t)freeMemoryBeginAt) / PAGE_SIZE;
c01015c5:	8b 35 6c b1 10 c0    	mov    0xc010b16c,%esi
c01015cb:	8b 3d 80 b1 10 c0    	mov    0xc010b180,%edi
c01015d1:	29 f7                	sub    %esi,%edi
c01015d3:	c1 ef 0c             	shr    $0xc,%edi
//     assert(page->ref >= 0 && "decrease the number of unused page.");
// }

static void FreePhysicMemoryInitialize(uint32_t *base, uint32_t size)
{
    assert(base && pages && "nullptr exception");
c01015d6:	85 f6                	test   %esi,%esi
c01015d8:	0f 84 02 01 00 00    	je     c01016e0 <PhysicMemoryInitialize+0x240>
c01015de:	a1 84 b1 10 c0       	mov    0xc010b184,%eax
c01015e3:	85 c0                	test   %eax,%eax
c01015e5:	0f 84 f5 00 00 00    	je     c01016e0 <PhysicMemoryInitialize+0x240>

    Page *page = pages + (uint32_t)base / PAGE_SIZE;
c01015eb:	89 f2                	mov    %esi,%edx
c01015ed:	c1 ea 0c             	shr    $0xc,%edx
    freeArea.freeNumbers = size;
    /* first block */
    pages->property = size;
    while (size--) {
c01015f0:	85 ff                	test   %edi,%edi

static void FreePhysicMemoryInitialize(uint32_t *base, uint32_t size)
{
    assert(base && pages && "nullptr exception");

    Page *page = pages + (uint32_t)base / PAGE_SIZE;
c01015f2:	8d 14 52             	lea    (%edx,%edx,2),%edx
    freeArea.freeNumbers = size;
c01015f5:	89 3d 7c b1 10 c0    	mov    %edi,0xc010b17c

static void FreePhysicMemoryInitialize(uint32_t *base, uint32_t size)
{
    assert(base && pages && "nullptr exception");

    Page *page = pages + (uint32_t)base / PAGE_SIZE;
c01015fb:	8d 1c d0             	lea    (%eax,%edx,8),%ebx
    freeArea.freeNumbers = size;
    /* first block */
    pages->property = size;
c01015fe:	89 78 08             	mov    %edi,0x8(%eax)
    while (size--) {
c0101601:	0f 84 a1 00 00 00    	je     c01016a8 <PhysicMemoryInitialize+0x208>
c0101607:	8d 43 0c             	lea    0xc(%ebx),%eax
c010160a:	8d 96 00 00 00 c0    	lea    -0x40000000(%esi),%edx
c0101610:	89 c6                	mov    %eax,%esi
c0101612:	eb 26                	jmp    c010163a <PhysicMemoryInitialize+0x19a>
c0101614:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
        struct list_node_t *tail = list_tail(list);
        tail->next = node;
        node->prev = tail;
        list->tail = node;
    } else {
        list->head = node;
c0101618:	a3 70 b1 10 c0       	mov    %eax,0xc010b170
        list->tail = node;
c010161d:	a3 74 b1 10 c0       	mov    %eax,0xc010b174
c0101622:	31 c0                	xor    %eax,%eax
    }
    ++list->size;
c0101624:	83 c0 01             	add    $0x1,%eax
        assert(((uint32_t)page < (uint32_t)P2V(base)) 
            && "out of memory range.");

        SetPageFree(page);
        list_append(&freeArea.list, &page->node);
        page++;
c0101627:	83 c3 18             	add    $0x18,%ebx
c010162a:	83 c6 18             	add    $0x18,%esi

    Page *page = pages + (uint32_t)base / PAGE_SIZE;
    freeArea.freeNumbers = size;
    /* first block */
    pages->property = size;
    while (size--) {
c010162d:	83 ef 01             	sub    $0x1,%edi
c0101630:	a3 78 b1 10 c0       	mov    %eax,0xc010b178
c0101635:	74 71                	je     c01016a8 <PhysicMemoryInitialize+0x208>
c0101637:	8d 43 0c             	lea    0xc(%ebx),%eax
        assert(((uint32_t)page < (uint32_t)P2V(base)) 
c010163a:	39 d3                	cmp    %edx,%ebx
c010163c:	73 4a                	jae    c0101688 <PhysicMemoryInitialize+0x1e8>
/**
 * free physic page and insert into free area 
 */
static void SetPageFree(Page *page)
{
    assert(page && "null ptr exception");
c010163e:	85 db                	test   %ebx,%ebx
c0101640:	0f 84 b0 00 00 00    	je     c01016f6 <PhysicMemoryInitialize+0x256>

    page->flags = PG_Free;
c0101646:	c7 43 04 01 00 00 00 	movl   $0x1,0x4(%ebx)
        tmpname != list_end();                  \
        tmpname = list_node_prev(tmpname))

static inline void list_node_init(struct list_node_t *node) {
    assert(node != NULL);
    node->prev = list_end();
c010164d:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
    node->next = list_end();
c0101653:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)

static inline struct list_node_t *list_append(
    struct list_t *list, struct list_node_t *node) {
    assert(list != NULL && node != NULL);
    list_node_init(node);
    node->list = list;
c010165a:	c7 46 08 70 b1 10 c0 	movl   $0xc010b170,0x8(%esi)
    if (!list_empty(list)) {
c0101661:	8b 0d 78 b1 10 c0    	mov    0xc010b178,%ecx
c0101667:	85 c9                	test   %ecx,%ecx
c0101669:	74 ad                	je     c0101618 <PhysicMemoryInitialize+0x178>
        struct list_node_t *tail = list_tail(list);
c010166b:	8b 0d 74 b1 10 c0    	mov    0xc010b174,%ecx
        tail->next = node;
c0101671:	89 41 04             	mov    %eax,0x4(%ecx)
        node->prev = tail;
c0101674:	89 0e                	mov    %ecx,(%esi)
        list->tail = node;
c0101676:	a3 74 b1 10 c0       	mov    %eax,0xc010b174
c010167b:	a1 78 b1 10 c0       	mov    0xc010b178,%eax
c0101680:	eb a2                	jmp    c0101624 <PhysicMemoryInitialize+0x184>
c0101682:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
    Page *page = pages + (uint32_t)base / PAGE_SIZE;
    freeArea.freeNumbers = size;
    /* first block */
    pages->property = size;
    while (size--) {
        assert(((uint32_t)page < (uint32_t)P2V(base)) 
c0101688:	c7 04 24 6c 20 10 c0 	movl   $0xc010206c,(%esp)
c010168f:	89 45 e0             	mov    %eax,-0x20(%ebp)
c0101692:	89 55 e4             	mov    %edx,-0x1c(%ebp)
c0101695:	e8 b6 f8 ff ff       	call   c0100f50 <panic>
c010169a:	8b 45 e0             	mov    -0x20(%ebp),%eax
c010169d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c01016a0:	eb 9c                	jmp    c010163e <PhysicMemoryInitialize+0x19e>
c01016a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
        PageInitialize(pages + i);
    }

    uint32_t totalPages = (memorySize - (uint32_t)freeMemoryBeginAt) / PAGE_SIZE;
    FreePhysicMemoryInitialize(freeMemoryBeginAt, totalPages);
}
c01016a8:	83 c4 1c             	add    $0x1c,%esp
c01016ab:	5b                   	pop    %ebx
c01016ac:	5e                   	pop    %esi
c01016ad:	5f                   	pop    %edi
c01016ae:	5d                   	pop    %ebp
c01016af:	c3                   	ret    
    freeArea->freeNumbers = 0;
}

static void PageInitialize(Page *page) 
{
    assert(page && "null ptr exception");
c01016b0:	c7 04 24 82 1f 10 c0 	movl   $0xc0101f82,(%esp)
c01016b7:	e8 94 f8 ff ff       	call   c0100f50 <panic>
c01016bc:	e9 d2 fe ff ff       	jmp    c0101593 <PhysicMemoryInitialize+0xf3>
c01016c1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi

void PhysicMemoryInitialize(void)
{
    printk("Physic memory initialize...\n");

    assert(MemorySizeInKB != 0 && "Memory size must success.");
c01016c8:	c7 04 24 cc 1f 10 c0 	movl   $0xc0101fcc,(%esp)
c01016cf:	e8 7c f8 ff ff       	call   c0100f50 <panic>
c01016d4:	8b 15 0c 00 10 c0    	mov    0xc010000c,%edx
c01016da:	e9 e4 fd ff ff       	jmp    c01014c3 <PhysicMemoryInitialize+0x23>
c01016df:	90                   	nop
//     assert(page->ref >= 0 && "decrease the number of unused page.");
// }

static void FreePhysicMemoryInitialize(uint32_t *base, uint32_t size)
{
    assert(base && pages && "nullptr exception");
c01016e0:	c7 04 24 44 20 10 c0 	movl   $0xc0102044,(%esp)
c01016e7:	e8 64 f8 ff ff       	call   c0100f50 <panic>
c01016ec:	a1 84 b1 10 c0       	mov    0xc010b184,%eax
c01016f1:	e9 f5 fe ff ff       	jmp    c01015eb <PhysicMemoryInitialize+0x14b>
/**
 * free physic page and insert into free area 
 */
static void SetPageFree(Page *page)
{
    assert(page && "null ptr exception");
c01016f6:	c7 04 24 82 1f 10 c0 	movl   $0xc0101f82,(%esp)
c01016fd:	89 45 e0             	mov    %eax,-0x20(%ebp)
c0101700:	89 55 e4             	mov    %edx,-0x1c(%ebp)
c0101703:	e8 48 f8 ff ff       	call   c0100f50 <panic>
c0101708:	8b 45 e0             	mov    -0x20(%ebp),%eax
c010170b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c010170e:	e9 33 ff ff ff       	jmp    c0101646 <PhysicMemoryInitialize+0x1a6>
c0101713:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
c0101719:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

c0101720 <SizeOfFreePhysicPage>:
    uint32_t totalPages = (memorySize - (uint32_t)freeMemoryBeginAt) / PAGE_SIZE;
    FreePhysicMemoryInitialize(freeMemoryBeginAt, totalPages);
}

uint32_t SizeOfFreePhysicPage()
{
c0101720:	55                   	push   %ebp
    return freeArea.freeNumbers;
}
c0101721:	a1 7c b1 10 c0       	mov    0xc010b17c,%eax
    uint32_t totalPages = (memorySize - (uint32_t)freeMemoryBeginAt) / PAGE_SIZE;
    FreePhysicMemoryInitialize(freeMemoryBeginAt, totalPages);
}

uint32_t SizeOfFreePhysicPage()
{
c0101726:	89 e5                	mov    %esp,%ebp
    return freeArea.freeNumbers;
}
c0101728:	5d                   	pop    %ebp
c0101729:	c3                   	ret    
c010172a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

c0101730 <PhysicAllocatePages>:

/**
 * allocate & return Pages.
 */
Page* PhysicAllocatePages(size_t n)
{
c0101730:	55                   	push   %ebp
c0101731:	89 e5                	mov    %esp,%ebp
c0101733:	57                   	push   %edi
c0101734:	56                   	push   %esi
c0101735:	53                   	push   %ebx
c0101736:	83 ec 1c             	sub    $0x1c,%esp
    assert(n > 0 && "can not allocate zero pages.");
c0101739:	8b 4d 08             	mov    0x8(%ebp),%ecx
c010173c:	85 c9                	test   %ecx,%ecx
c010173e:	0f 8e 7c 01 00 00    	jle    c01018c0 <PhysicAllocatePages+0x190>

    if (n > SizeOfFreePhysicPage())
c0101744:	a1 7c b1 10 c0       	mov    0xc010b17c,%eax
c0101749:	39 45 08             	cmp    %eax,0x8(%ebp)
c010174c:	77 3a                	ja     c0101788 <PhysicAllocatePages+0x58>
        return NULL;

    list_for_each(node, &freeArea.list) {
c010174e:	8b 35 70 b1 10 c0    	mov    0xc010b170,%esi
c0101754:	85 f6                	test   %esi,%esi
c0101756:	74 30                	je     c0101788 <PhysicAllocatePages+0x58>
        Page *p = get_page_from_list_node(node);
        assert(p && "PhysicAllocatePages: error occupied when iterate freeArea.list.");
        
        /* last page of this block */
        Page *last = p + p->property - 1;
c0101758:	8b 46 fc             	mov    -0x4(%esi),%eax

    if (n > SizeOfFreePhysicPage())
        return NULL;

    list_for_each(node, &freeArea.list) {
        Page *p = get_page_from_list_node(node);
c010175b:	8d 7e f4             	lea    -0xc(%esi),%edi
        assert(p && "PhysicAllocatePages: error occupied when iterate freeArea.list.");
        
        /* last page of this block */
        Page *last = p + p->property - 1;
        if (p->property >= n) {
c010175e:	39 45 08             	cmp    %eax,0x8(%ebp)
c0101761:	8b 5d 08             	mov    0x8(%ebp),%ebx
    list_for_each(node, &freeArea.list) {
        Page *p = get_page_from_list_node(node);
        assert(p && "PhysicAllocatePages: error occupied when iterate freeArea.list.");
        
        /* last page of this block */
        Page *last = p + p->property - 1;
c0101764:	8d 14 40             	lea    (%eax,%eax,2),%edx
c0101767:	8d 4c d7 e8          	lea    -0x18(%edi,%edx,8),%ecx
        if (p->property >= n) {
c010176b:	77 14                	ja     c0101781 <PhysicAllocatePages+0x51>
c010176d:	eb 29                	jmp    c0101798 <PhysicAllocatePages+0x68>
c010176f:	90                   	nop
    list_for_each(node, &freeArea.list) {
        Page *p = get_page_from_list_node(node);
        assert(p && "PhysicAllocatePages: error occupied when iterate freeArea.list.");
        
        /* last page of this block */
        Page *last = p + p->property - 1;
c0101770:	8b 46 fc             	mov    -0x4(%esi),%eax

    if (n > SizeOfFreePhysicPage())
        return NULL;

    list_for_each(node, &freeArea.list) {
        Page *p = get_page_from_list_node(node);
c0101773:	8d 7e f4             	lea    -0xc(%esi),%edi
        assert(p && "PhysicAllocatePages: error occupied when iterate freeArea.list.");
        
        /* last page of this block */
        Page *last = p + p->property - 1;
c0101776:	8d 14 40             	lea    (%eax,%eax,2),%edx
        if (p->property >= n) {
c0101779:	39 c3                	cmp    %eax,%ebx
    list_for_each(node, &freeArea.list) {
        Page *p = get_page_from_list_node(node);
        assert(p && "PhysicAllocatePages: error occupied when iterate freeArea.list.");
        
        /* last page of this block */
        Page *last = p + p->property - 1;
c010177b:	8d 4c d7 e8          	lea    -0x18(%edi,%edx,8),%ecx
        if (p->property >= n) {
c010177f:	76 17                	jbe    c0101798 <PhysicAllocatePages+0x68>
    assert(n > 0 && "can not allocate zero pages.");

    if (n > SizeOfFreePhysicPage())
        return NULL;

    list_for_each(node, &freeArea.list) {
c0101781:	8b 71 10             	mov    0x10(%ecx),%esi
c0101784:	85 f6                	test   %esi,%esi
c0101786:	75 e8                	jne    c0101770 <PhysicAllocatePages+0x40>
            node = &last->node;
    }

    /* can't find proper block when progress visit here. */
    return NULL;
}
c0101788:	83 c4 1c             	add    $0x1c,%esp
Page* PhysicAllocatePages(size_t n)
{
    assert(n > 0 && "can not allocate zero pages.");

    if (n > SizeOfFreePhysicPage())
        return NULL;
c010178b:	31 c0                	xor    %eax,%eax
            node = &last->node;
    }

    /* can't find proper block when progress visit here. */
    return NULL;
}
c010178d:	5b                   	pop    %ebx
c010178e:	5e                   	pop    %esi
c010178f:	5f                   	pop    %edi
c0101790:	5d                   	pop    %ebp
c0101791:	c3                   	ret    
c0101792:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
        
        /* last page of this block */
        Page *last = p + p->property - 1;
        if (p->property >= n) {
            /* find! */
            for (int i = 0; i < n; ++i) {
c0101798:	8b 55 08             	mov    0x8(%ebp),%edx
c010179b:	31 c0                	xor    %eax,%eax
c010179d:	89 f3                	mov    %esi,%ebx
c010179f:	85 d2                	test   %edx,%edx
c01017a1:	0f 8e c2 00 00 00    	jle    c0101869 <PhysicAllocatePages+0x139>
c01017a7:	89 7d e4             	mov    %edi,-0x1c(%ebp)
c01017aa:	89 c7                	mov    %eax,%edi
c01017ac:	89 4d e0             	mov    %ecx,-0x20(%ebp)
c01017af:	89 75 dc             	mov    %esi,-0x24(%ebp)
c01017b2:	eb 5c                	jmp    c0101810 <PhysicAllocatePages+0xe0>
c01017b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    assert(node != NULL);
    struct list_t *list = list_from_node(node);
    if (list_size(list) == 1) {
        list_init(list);
        list->size = 1;
    } else if (node == list_head(list)) {
c01017b8:	3b 18                	cmp    (%eax),%ebx
c01017ba:	74 7c                	je     c0101838 <PhysicAllocatePages+0x108>
        node->next->prev = list_end();
        list->head = node->next;
    } else if (node == list_tail(list)) {
c01017bc:	3b 58 04             	cmp    0x4(%eax),%ebx
c01017bf:	0f 84 cb 00 00 00    	je     c0101890 <PhysicAllocatePages+0x160>
        node->prev->next = list_end();
        list->tail = node->prev;
    } else {
        node->prev->next = node->next;
c01017c5:	8b 13                	mov    (%ebx),%edx
c01017c7:	89 72 04             	mov    %esi,0x4(%edx)
        node->next->prev = node->prev;
c01017ca:	8b 53 04             	mov    0x4(%ebx),%edx
c01017cd:	8b 0b                	mov    (%ebx),%ecx
c01017cf:	89 0a                	mov    %ecx,(%edx)
        tmpname != list_end();                  \
        tmpname = list_node_prev(tmpname))

static inline void list_node_init(struct list_node_t *node) {
    assert(node != NULL);
    node->prev = list_end();
c01017d1:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
    node->next = list_end();
c01017d7:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
    node->list = NULL;
c01017de:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    } else {
        node->prev->next = node->next;
        node->next->prev = node->prev;
    }
    list_node_init(node);
    --list->size;
c01017e5:	83 68 08 01          	subl   $0x1,0x8(%eax)
                struct list_node_t *tmp = node;
                node = list_node_next(node);
                list_remove(tmp);
                assert(node && "PhysicAllocatePages: error occupied");
c01017e9:	85 f6                	test   %esi,%esi
c01017eb:	0f 84 b7 00 00 00    	je     c01018a8 <PhysicAllocatePages+0x178>
        
        /* last page of this block */
        Page *last = p + p->property - 1;
        if (p->property >= n) {
            /* find! */
            for (int i = 0; i < n; ++i) {
c01017f1:	83 c7 01             	add    $0x1,%edi
c01017f4:	3b 7d 08             	cmp    0x8(%ebp),%edi
}

static void ClearPageRef(Page *page) 
{
    assert(page && "null ptr exception.");
    page->ref = 0;
c01017f7:	c7 43 f4 00 00 00 00 	movl   $0x0,-0xc(%ebx)

static void SetPageReserved(Page *page)
{
    assert(page && "null ptr exception.");

    page->flags = PG_Reserved;
c01017fe:	c7 43 f8 00 00 00 00 	movl   $0x0,-0x8(%ebx)
                assert(node && "PhysicAllocatePages: error occupied");

                Page *tp = get_page_from_list_node(tmp);
                ClearPageRef(tp);
                SetPageReserved(tp);
                tp->property = 0;
c0101805:	c7 43 fc 00 00 00 00 	movl   $0x0,-0x4(%ebx)
        
        /* last page of this block */
        Page *last = p + p->property - 1;
        if (p->property >= n) {
            /* find! */
            for (int i = 0; i < n; ++i) {
c010180c:	74 52                	je     c0101860 <PhysicAllocatePages+0x130>
                struct list_node_t *tmp = node;
                node = list_node_next(node);
c010180e:	89 f3                	mov    %esi,%ebx
    return new_node;
}

static inline struct list_node_t *list_remove(struct list_node_t *node) {
    assert(node != NULL);
    struct list_t *list = list_from_node(node);
c0101810:	8b 43 08             	mov    0x8(%ebx),%eax
c0101813:	8b 73 04             	mov    0x4(%ebx),%esi
    if (list_size(list) == 1) {
c0101816:	83 78 08 01          	cmpl   $0x1,0x8(%eax)
c010181a:	75 9c                	jne    c01017b8 <PhysicAllocatePages+0x88>
    node->list = NULL;
}

static inline void list_init(struct list_t *list) {
    assert(list != NULL);
    list->head = NULL;
c010181c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    list->tail = NULL;
c0101822:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
static inline struct list_node_t *list_remove(struct list_node_t *node) {
    assert(node != NULL);
    struct list_t *list = list_from_node(node);
    if (list_size(list) == 1) {
        list_init(list);
        list->size = 1;
c0101829:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
c0101830:	eb 9f                	jmp    c01017d1 <PhysicAllocatePages+0xa1>
c0101832:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
    } else if (node == list_head(list)) {
        node->next->prev = list_end();
c0101838:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
        list->head = node->next;
c010183e:	8b 4b 04             	mov    0x4(%ebx),%ecx
c0101841:	89 08                	mov    %ecx,(%eax)
        tmpname != list_end();                  \
        tmpname = list_node_prev(tmpname))

static inline void list_node_init(struct list_node_t *node) {
    assert(node != NULL);
    node->prev = list_end();
c0101843:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
    node->next = list_end();
c0101849:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
    node->list = NULL;
c0101850:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    } else {
        node->prev->next = node->next;
        node->next->prev = node->prev;
    }
    list_node_init(node);
    --list->size;
c0101857:	83 68 08 01          	subl   $0x1,0x8(%eax)
c010185b:	eb 94                	jmp    c01017f1 <PhysicAllocatePages+0xc1>
c010185d:	8d 76 00             	lea    0x0(%esi),%esi
c0101860:	8b 7d e4             	mov    -0x1c(%ebp),%edi
c0101863:	8b 4d e0             	mov    -0x20(%ebp),%ecx
c0101866:	8b 75 dc             	mov    -0x24(%ebp),%esi
                Page *tp = get_page_from_list_node(tmp);
                ClearPageRef(tp);
                SetPageReserved(tp);
                tp->property = 0;
            }
            if (p->property > n) {
c0101869:	8b 46 fc             	mov    -0x4(%esi),%eax
c010186c:	39 45 08             	cmp    %eax,0x8(%ebp)
c010186f:	73 09                	jae    c010187a <PhysicAllocatePages+0x14a>
                Page *tp = get_page_from_list_node(list_node_next(&last->node));
c0101871:	8b 51 10             	mov    0x10(%ecx),%edx
                tp->property = p->property - n;
c0101874:	2b 45 08             	sub    0x8(%ebp),%eax
c0101877:	89 42 fc             	mov    %eax,-0x4(%edx)
            }
                
            freeArea.freeNumbers -= n;
c010187a:	8b 45 08             	mov    0x8(%ebp),%eax
c010187d:	29 05 7c b1 10 c0    	sub    %eax,0xc010b17c
            node = &last->node;
    }

    /* can't find proper block when progress visit here. */
    return NULL;
}
c0101883:	83 c4 1c             	add    $0x1c,%esp
c0101886:	5b                   	pop    %ebx

    if (n > SizeOfFreePhysicPage())
        return NULL;

    list_for_each(node, &freeArea.list) {
        Page *p = get_page_from_list_node(node);
c0101887:	89 f8                	mov    %edi,%eax
            node = &last->node;
    }

    /* can't find proper block when progress visit here. */
    return NULL;
}
c0101889:	5e                   	pop    %esi
c010188a:	5f                   	pop    %edi
c010188b:	5d                   	pop    %ebp
c010188c:	c3                   	ret    
c010188d:	8d 76 00             	lea    0x0(%esi),%esi
        list->size = 1;
    } else if (node == list_head(list)) {
        node->next->prev = list_end();
        list->head = node->next;
    } else if (node == list_tail(list)) {
        node->prev->next = list_end();
c0101890:	8b 0b                	mov    (%ebx),%ecx
c0101892:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
        list->tail = node->prev;
c0101899:	8b 0b                	mov    (%ebx),%ecx
c010189b:	89 48 04             	mov    %ecx,0x4(%eax)
c010189e:	e9 2e ff ff ff       	jmp    c01017d1 <PhysicAllocatePages+0xa1>
c01018a3:	90                   	nop
c01018a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
            /* find! */
            for (int i = 0; i < n; ++i) {
                struct list_node_t *tmp = node;
                node = list_node_next(node);
                list_remove(tmp);
                assert(node && "PhysicAllocatePages: error occupied");
c01018a8:	c7 04 24 d8 20 10 c0 	movl   $0xc01020d8,(%esp)
c01018af:	e8 9c f6 ff ff       	call   c0100f50 <panic>
c01018b4:	e9 38 ff ff ff       	jmp    c01017f1 <PhysicAllocatePages+0xc1>
c01018b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
/**
 * allocate & return Pages.
 */
Page* PhysicAllocatePages(size_t n)
{
    assert(n > 0 && "can not allocate zero pages.");
c01018c0:	c7 04 24 b0 20 10 c0 	movl   $0xc01020b0,(%esp)
c01018c7:	e8 84 f6 ff ff       	call   c0100f50 <panic>
c01018cc:	e9 73 fe ff ff       	jmp    c0101744 <PhysicAllocatePages+0x14>
c01018d1:	eb 0d                	jmp    c01018e0 <PhysicFreePages>
c01018d3:	90                   	nop
c01018d4:	90                   	nop
c01018d5:	90                   	nop
c01018d6:	90                   	nop
c01018d7:	90                   	nop
c01018d8:	90                   	nop
c01018d9:	90                   	nop
c01018da:	90                   	nop
c01018db:	90                   	nop
c01018dc:	90                   	nop
c01018dd:	90                   	nop
c01018de:	90                   	nop
c01018df:	90                   	nop

c01018e0 <PhysicFreePages>:
    /* can't find proper block when progress visit here. */
    return NULL;
}

void PhysicFreePages(Page *base, size_t n)
{
c01018e0:	55                   	push   %ebp
c01018e1:	89 e5                	mov    %esp,%ebp
c01018e3:	57                   	push   %edi
c01018e4:	56                   	push   %esi
c01018e5:	53                   	push   %ebx
c01018e6:	83 ec 2c             	sub    $0x2c,%esp
    assert((uint32_t)freeMemoryBeginAt <= (uint32_t)base 
c01018e9:	8b 45 08             	mov    0x8(%ebp),%eax
c01018ec:	39 05 6c b1 10 c0    	cmp    %eax,0xc010b16c
c01018f2:	0f 87 40 01 00 00    	ja     c0101a38 <PhysicFreePages+0x158>
c01018f8:	a1 80 b1 10 c0       	mov    0xc010b180,%eax
c01018fd:	39 45 08             	cmp    %eax,0x8(%ebp)
c0101900:	0f 83 32 01 00 00    	jae    c0101a38 <PhysicFreePages+0x158>
        && (uint32_t)base < memorySize
        && "please no free memory out of range.");
    assert(n > 0 && "can not free zero page");
c0101906:	8b 4d 0c             	mov    0xc(%ebp),%ecx
c0101909:	85 c9                	test   %ecx,%ecx
c010190b:	0f 8e 3e 01 00 00    	jle    c0101a4f <PhysicFreePages+0x16f>
    page->flags = PG_Free;
}

static bool IsPageReserved(Page *page) 
{
    assert(page && "null ptr exception.");
c0101911:	8b 55 08             	mov    0x8(%ebp),%edx
c0101914:	85 d2                	test   %edx,%edx
c0101916:	0f 84 ec 01 00 00    	je     c0101b08 <PhysicFreePages+0x228>
{
    assert((uint32_t)freeMemoryBeginAt <= (uint32_t)base 
        && (uint32_t)base < memorySize
        && "please no free memory out of range.");
    assert(n > 0 && "can not free zero page");
    assert(IsPageReserved(base) && "try to release unused memory.");
c010191c:	8b 45 08             	mov    0x8(%ebp),%eax
c010191f:	8b 40 04             	mov    0x4(%eax),%eax
c0101922:	85 c0                	test   %eax,%eax
c0101924:	0f 85 ae 01 00 00    	jne    c0101ad8 <PhysicFreePages+0x1f8>

    Page *p = NULL;
    list_for_each(node, &freeArea.list) {
c010192a:	a1 70 b1 10 c0       	mov    0xc010b170,%eax
c010192f:	85 c0                	test   %eax,%eax
c0101931:	0f 84 e2 01 00 00    	je     c0101b19 <PhysicFreePages+0x239>
        p = get_page_from_list_node(node);
c0101937:	8d 70 f4             	lea    -0xc(%eax),%esi
c010193a:	8b 55 08             	mov    0x8(%ebp),%edx
        if (p > base)
c010193d:	39 75 08             	cmp    %esi,0x8(%ebp)
c0101940:	73 0d                	jae    c010194f <PhysicFreePages+0x6f>
c0101942:	eb 12                	jmp    c0101956 <PhysicFreePages+0x76>
c0101944:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    assert(n > 0 && "can not free zero page");
    assert(IsPageReserved(base) && "try to release unused memory.");

    Page *p = NULL;
    list_for_each(node, &freeArea.list) {
        p = get_page_from_list_node(node);
c0101948:	8d 70 f4             	lea    -0xc(%eax),%esi
        if (p > base)
c010194b:	39 f2                	cmp    %esi,%edx
c010194d:	72 07                	jb     c0101956 <PhysicFreePages+0x76>
        && "please no free memory out of range.");
    assert(n > 0 && "can not free zero page");
    assert(IsPageReserved(base) && "try to release unused memory.");

    Page *p = NULL;
    list_for_each(node, &freeArea.list) {
c010194f:	8b 40 04             	mov    0x4(%eax),%eax
c0101952:	85 c0                	test   %eax,%eax
c0101954:	75 f2                	jne    c0101948 <PhysicFreePages+0x68>
        p = get_page_from_list_node(node);
        if (p > base)
            break;
    }

    for (Page *t = base; t < base + n; t++) {
c0101956:	8b 45 0c             	mov    0xc(%ebp),%eax
c0101959:	8b 7d 08             	mov    0x8(%ebp),%edi
c010195c:	8d 04 40             	lea    (%eax,%eax,2),%eax
c010195f:	8d 04 c7             	lea    (%edi,%eax,8),%eax
c0101962:	39 c7                	cmp    %eax,%edi
c0101964:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0101967:	0f 83 05 01 00 00    	jae    c0101a72 <PhysicFreePages+0x192>
c010196d:	89 f0                	mov    %esi,%eax
c010196f:	83 c0 0c             	add    $0xc,%eax
c0101972:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0101975:	8b 45 08             	mov    0x8(%ebp),%eax
c0101978:	0f 94 45 db          	sete   -0x25(%ebp)
c010197c:	89 c1                	mov    %eax,%ecx
c010197e:	8d 58 10             	lea    0x10(%eax),%ebx
c0101981:	89 cf                	mov    %ecx,%edi
c0101983:	89 f0                	mov    %esi,%eax
c0101985:	eb 5e                	jmp    c01019e5 <PhysicFreePages+0x105>
c0101987:	90                   	nop
}

// new node will be insert before at old node. 
static inline struct list_node_t *list_insert(
    struct list_node_t *old_node, struct list_node_t *new_node) {
    assert(old_node != NULL && new_node != NULL);
c0101988:	80 7d db 00          	cmpb   $0x0,-0x25(%ebp)
c010198c:	75 62                	jne    c01019f0 <PhysicFreePages+0x110>
    struct list_t *list = list_from_node(old_node);
c010198e:	8b 70 14             	mov    0x14(%eax),%esi
    struct list_node_t *head = list_head(list);
c0101991:	8b 16                	mov    (%esi),%edx
    list_node_init(new_node);
    if (head == old_node) {
c0101993:	39 55 e4             	cmp    %edx,-0x1c(%ebp)
        tmpname != list_end();                  \
        tmpname = list_node_prev(tmpname))

static inline void list_node_init(struct list_node_t *node) {
    assert(node != NULL);
    node->prev = list_end();
c0101996:	c7 43 fc 00 00 00 00 	movl   $0x0,-0x4(%ebx)
    node->next = list_end();
c010199d:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
    node->list = NULL;
c01019a3:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
    struct list_node_t *old_node, struct list_node_t *new_node) {
    assert(old_node != NULL && new_node != NULL);
    struct list_t *list = list_from_node(old_node);
    struct list_node_t *head = list_head(list);
    list_node_init(new_node);
    if (head == old_node) {
c01019aa:	0f 84 b0 00 00 00    	je     c0101a60 <PhysicFreePages+0x180>
        head->prev = new_node;
        new_node->next = head;
        list->head = new_node;
    } else {
        new_node->prev = old_node->prev;
c01019b0:	8b 50 0c             	mov    0xc(%eax),%edx
c01019b3:	89 53 fc             	mov    %edx,-0x4(%ebx)
        new_node->next = old_node;
c01019b6:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c01019b9:	89 13                	mov    %edx,(%ebx)
        old_node->prev->next = new_node;
c01019bb:	8b 50 0c             	mov    0xc(%eax),%edx
c01019be:	89 4a 04             	mov    %ecx,0x4(%edx)
        old_node->prev = new_node;
c01019c1:	89 48 0c             	mov    %ecx,0xc(%eax)
    }
    ++list->size;
c01019c4:	83 46 08 01          	addl   $0x1,0x8(%esi)
c01019c8:	83 c7 18             	add    $0x18,%edi
c01019cb:	83 c3 18             	add    $0x18,%ebx
 */
static void SetPageFree(Page *page)
{
    assert(page && "null ptr exception");

    page->flags = PG_Free;
c01019ce:	c7 47 ec 01 00 00 00 	movl   $0x1,-0x14(%edi)
}

static void ClearPageRef(Page *page) 
{
    assert(page && "null ptr exception.");
    page->ref = 0;
c01019d5:	c7 47 e8 00 00 00 00 	movl   $0x0,-0x18(%edi)
        p = get_page_from_list_node(node);
        if (p > base)
            break;
    }

    for (Page *t = base; t < base + n; t++) {
c01019dc:	3b 7d dc             	cmp    -0x24(%ebp),%edi
c01019df:	0f 83 8b 00 00 00    	jae    c0101a70 <PhysicFreePages+0x190>
}

// new node will be insert before at old node. 
static inline struct list_node_t *list_insert(
    struct list_node_t *old_node, struct list_node_t *new_node) {
    assert(old_node != NULL && new_node != NULL);
c01019e5:	89 f9                	mov    %edi,%ecx
c01019e7:	83 c1 0c             	add    $0xc,%ecx
c01019ea:	0f 94 45 e0          	sete   -0x20(%ebp)
c01019ee:	75 98                	jne    c0101988 <PhysicFreePages+0xa8>
c01019f0:	c7 04 24 dc 21 10 c0 	movl   $0xc01021dc,(%esp)
c01019f7:	89 45 d0             	mov    %eax,-0x30(%ebp)
c01019fa:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
c01019fd:	e8 4e f5 ff ff       	call   c0100f50 <panic>
    struct list_t *list = list_from_node(old_node);
c0101a02:	8b 45 d0             	mov    -0x30(%ebp),%eax
    for (struct list_node_t *tmpname = list_tail(list);    \
        tmpname != list_end();                  \
        tmpname = list_node_prev(tmpname))

static inline void list_node_init(struct list_node_t *node) {
    assert(node != NULL);
c0101a05:	80 7d e0 00          	cmpb   $0x0,-0x20(%ebp)
c0101a09:	8b 4d d4             	mov    -0x2c(%ebp),%ecx

// new node will be insert before at old node. 
static inline struct list_node_t *list_insert(
    struct list_node_t *old_node, struct list_node_t *new_node) {
    assert(old_node != NULL && new_node != NULL);
    struct list_t *list = list_from_node(old_node);
c0101a0c:	8b 70 14             	mov    0x14(%eax),%esi
    struct list_node_t *head = list_head(list);
c0101a0f:	8b 16                	mov    (%esi),%edx
    for (struct list_node_t *tmpname = list_tail(list);    \
        tmpname != list_end();                  \
        tmpname = list_node_prev(tmpname))

static inline void list_node_init(struct list_node_t *node) {
    assert(node != NULL);
c0101a11:	74 80                	je     c0101993 <PhysicFreePages+0xb3>
c0101a13:	c7 04 24 bd 1f 10 c0 	movl   $0xc0101fbd,(%esp)
c0101a1a:	89 55 d4             	mov    %edx,-0x2c(%ebp)
c0101a1d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
c0101a20:	e8 2b f5 ff ff       	call   c0100f50 <panic>
c0101a25:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0101a28:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0101a2b:	8b 4d e0             	mov    -0x20(%ebp),%ecx
c0101a2e:	e9 60 ff ff ff       	jmp    c0101993 <PhysicFreePages+0xb3>
c0101a33:	90                   	nop
c0101a34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
    return NULL;
}

void PhysicFreePages(Page *base, size_t n)
{
    assert((uint32_t)freeMemoryBeginAt <= (uint32_t)base 
c0101a38:	c7 04 24 08 21 10 c0 	movl   $0xc0102108,(%esp)
c0101a3f:	e8 0c f5 ff ff       	call   c0100f50 <panic>
        && (uint32_t)base < memorySize
        && "please no free memory out of range.");
    assert(n > 0 && "can not free zero page");
c0101a44:	8b 4d 0c             	mov    0xc(%ebp),%ecx
c0101a47:	85 c9                	test   %ecx,%ecx
c0101a49:	0f 8f c2 fe ff ff    	jg     c0101911 <PhysicFreePages+0x31>
c0101a4f:	c7 04 24 80 21 10 c0 	movl   $0xc0102180,(%esp)
c0101a56:	e8 f5 f4 ff ff       	call   c0100f50 <panic>
c0101a5b:	e9 b1 fe ff ff       	jmp    c0101911 <PhysicFreePages+0x31>
    struct list_t *list = list_from_node(old_node);
    struct list_node_t *head = list_head(list);
    list_node_init(new_node);
    if (head == old_node) {
        head->prev = new_node;
        new_node->next = head;
c0101a60:	8b 55 e4             	mov    -0x1c(%ebp),%edx
    assert(old_node != NULL && new_node != NULL);
    struct list_t *list = list_from_node(old_node);
    struct list_node_t *head = list_head(list);
    list_node_init(new_node);
    if (head == old_node) {
        head->prev = new_node;
c0101a63:	89 48 0c             	mov    %ecx,0xc(%eax)
        new_node->next = head;
c0101a66:	89 13                	mov    %edx,(%ebx)
        list->head = new_node;
c0101a68:	89 0e                	mov    %ecx,(%esi)
c0101a6a:	e9 55 ff ff ff       	jmp    c01019c4 <PhysicFreePages+0xe4>
c0101a6f:	90                   	nop
c0101a70:	89 c6                	mov    %eax,%esi
    for (Page *t = base; t < base + n; t++) {
        list_insert(&p->node, &t->node);
        SetPageFree(t);
        ClearPageRef(t);
    }
    base->property = n;
c0101a72:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a75:	8b 7d 0c             	mov    0xc(%ebp),%edi
    
    /* merge lst block */
    if (base + n == p) {
c0101a78:	3b 75 dc             	cmp    -0x24(%ebp),%esi
    for (Page *t = base; t < base + n; t++) {
        list_insert(&p->node, &t->node);
        SetPageFree(t);
        ClearPageRef(t);
    }
    base->property = n;
c0101a7b:	89 78 08             	mov    %edi,0x8(%eax)
    
    /* merge lst block */
    if (base + n == p) {
c0101a7e:	74 70                	je     c0101af0 <PhysicFreePages+0x210>
        base->property += p->property;
        p->property = 0;
    }

    /* merge fst block */
    struct list_node_t *prev = list_node_prev(&base->node),
c0101a80:	8b 45 08             	mov    0x8(%ebp),%eax
        *tail = list_tail(&freeArea.list);
c0101a83:	8b 1d 74 b1 10 c0    	mov    0xc010b174,%ebx
        base->property += p->property;
        p->property = 0;
    }

    /* merge fst block */
    struct list_node_t *prev = list_node_prev(&base->node),
c0101a89:	8b 40 0c             	mov    0xc(%eax),%eax
        *tail = list_tail(&freeArea.list);
    p = get_page_from_list_node(prev);
    if (prev != tail && p == base - 1) {
c0101a8c:	39 d8                	cmp    %ebx,%eax
    }

    /* merge fst block */
    struct list_node_t *prev = list_node_prev(&base->node),
        *tail = list_tail(&freeArea.list);
    p = get_page_from_list_node(prev);
c0101a8e:	8d 48 f4             	lea    -0xc(%eax),%ecx
    if (prev != tail && p == base - 1) {
c0101a91:	74 0a                	je     c0101a9d <PhysicFreePages+0x1bd>
c0101a93:	8b 7d 08             	mov    0x8(%ebp),%edi
c0101a96:	8d 57 e8             	lea    -0x18(%edi),%edx
c0101a99:	39 ca                	cmp    %ecx,%edx
c0101a9b:	74 1c                	je     c0101ab9 <PhysicFreePages+0x1d9>
            prev = list_node_prev(prev);
            p = get_page_from_list_node(prev);
        }
    }

    freeArea.freeNumbers += n;
c0101a9d:	8b 45 0c             	mov    0xc(%ebp),%eax
c0101aa0:	01 05 7c b1 10 c0    	add    %eax,0xc010b17c
}
c0101aa6:	83 c4 2c             	add    $0x2c,%esp
c0101aa9:	5b                   	pop    %ebx
c0101aaa:	5e                   	pop    %esi
c0101aab:	5f                   	pop    %edi
c0101aac:	5d                   	pop    %ebp
c0101aad:	c3                   	ret    
c0101aae:	66 90                	xchg   %ax,%ax
            if (p->property) {
                p->property += base->property;
                base->property = 0;
                break;
            }
            prev = list_node_prev(prev);
c0101ab0:	8b 00                	mov    (%eax),%eax
    /* merge fst block */
    struct list_node_t *prev = list_node_prev(&base->node),
        *tail = list_tail(&freeArea.list);
    p = get_page_from_list_node(prev);
    if (prev != tail && p == base - 1) {
        while (prev != tail) {
c0101ab2:	39 c3                	cmp    %eax,%ebx
                p->property += base->property;
                base->property = 0;
                break;
            }
            prev = list_node_prev(prev);
            p = get_page_from_list_node(prev);
c0101ab4:	8d 50 f4             	lea    -0xc(%eax),%edx
    /* merge fst block */
    struct list_node_t *prev = list_node_prev(&base->node),
        *tail = list_tail(&freeArea.list);
    p = get_page_from_list_node(prev);
    if (prev != tail && p == base - 1) {
        while (prev != tail) {
c0101ab7:	74 e4                	je     c0101a9d <PhysicFreePages+0x1bd>
            if (p->property) {
c0101ab9:	8b 4a 08             	mov    0x8(%edx),%ecx
c0101abc:	85 c9                	test   %ecx,%ecx
c0101abe:	74 f0                	je     c0101ab0 <PhysicFreePages+0x1d0>
                p->property += base->property;
c0101ac0:	8b 45 08             	mov    0x8(%ebp),%eax
c0101ac3:	03 48 08             	add    0x8(%eax),%ecx
c0101ac6:	89 4a 08             	mov    %ecx,0x8(%edx)
                base->property = 0;
c0101ac9:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
                break;
c0101ad0:	eb cb                	jmp    c0101a9d <PhysicFreePages+0x1bd>
c0101ad2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
{
    assert((uint32_t)freeMemoryBeginAt <= (uint32_t)base 
        && (uint32_t)base < memorySize
        && "please no free memory out of range.");
    assert(n > 0 && "can not free zero page");
    assert(IsPageReserved(base) && "try to release unused memory.");
c0101ad8:	c7 04 24 a4 21 10 c0 	movl   $0xc01021a4,(%esp)
c0101adf:	e8 6c f4 ff ff       	call   c0100f50 <panic>
c0101ae4:	e9 41 fe ff ff       	jmp    c010192a <PhysicFreePages+0x4a>
c0101ae9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
    }
    base->property = n;
    
    /* merge lst block */
    if (base + n == p) {
        base->property += p->property;
c0101af0:	8b 45 0c             	mov    0xc(%ebp),%eax
c0101af3:	8b 7d 08             	mov    0x8(%ebp),%edi
c0101af6:	03 46 08             	add    0x8(%esi),%eax
c0101af9:	89 47 08             	mov    %eax,0x8(%edi)
        p->property = 0;
c0101afc:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
c0101b03:	e9 78 ff ff ff       	jmp    c0101a80 <PhysicFreePages+0x1a0>
    page->flags = PG_Free;
}

static bool IsPageReserved(Page *page) 
{
    assert(page && "null ptr exception.");
c0101b08:	c7 04 24 9f 1f 10 c0 	movl   $0xc0101f9f,(%esp)
c0101b0f:	e8 3c f4 ff ff       	call   c0100f50 <panic>
c0101b14:	e9 03 fe ff ff       	jmp    c010191c <PhysicFreePages+0x3c>
        && (uint32_t)base < memorySize
        && "please no free memory out of range.");
    assert(n > 0 && "can not free zero page");
    assert(IsPageReserved(base) && "try to release unused memory.");

    Page *p = NULL;
c0101b19:	31 f6                	xor    %esi,%esi
c0101b1b:	e9 36 fe ff ff       	jmp    c0101956 <PhysicFreePages+0x76>
