#include <mm/pmm.h>
#include <mm/vmm.h>
#include <libs/types.h>
#include <libs/stdio.h>
#include <libs/debug.h>
#include <libs/list.h>

struct TList {
    char c;
    struct list_node_t node;
};

static void TListInit(struct TList *t, char c) 
{
    t->c = c;
    list_node_init(&t->node);
}

static char TListGetChar(struct list_node_t *node) 
{
    struct TList *list = list_get(node, struct TList, node);
    return list->c;
}

static void DumpTList(struct list_t *list)
{
    int count = 10;
    list_for_each(node, list) {
        printk("%c", TListGetChar(node));
        assert(count--);
    }
    printk("\n");
}

static void DumpTListR(struct list_t *list)
{
    int count = 10;
    list_for_each_r(node, list) {
        printk("%c", TListGetChar(node));
        assert(count--);
    }
    printk("\n");
}

static void TestList(void)
{
    struct TList a[10];
    struct list_t list;
    list_init(&list);
    for (int i = 0; i < 10; ++i) {
        TListInit(&a[i], '0'+i);
        list_append(&list, &(a[i].node));
    }
    DumpTList(&list);
    DumpTListR(&list);
    
    list_remove(&(a[0].node));
    DumpTList(&list);
    DumpTListR(&list);

    list_insert(&(a[1].node), &(a[0].node));
    DumpTList(&list);
    DumpTListR(&list);

    list_remove(&(a[0].node));
    DumpTList(&list);
    DumpTListR(&list);

    list_prepend(&list, &(a[0].node));
    DumpTList(&list);
    DumpTListR(&list);

    list_remove(&(a[9].node));
    DumpTList(&list);
    DumpTListR(&list);

    list_append(&list, &(a[9].node));
    DumpTList(&list);
    DumpTListR(&list);

    list_remove(&(a[8].node));
    DumpTList(&list);
    DumpTListR(&list);

    list_insert(&(a[9].node), &(a[8].node));
    DumpTList(&list);
    DumpTListR(&list);

    list_remove(&(a[9].node));
    DumpTList(&list);
    DumpTListR(&list);

    list_replace(&(a[8].node), &(a[9].node));
    DumpTList(&list);
    DumpTListR(&list);
}

static void TestMM(void) 
{
    Page * page = PhysicAllocatePage();
    printk("page : 0x%08x\n", page);
    PhysicFreePage(page);

    void * area = kmalloc(10);
    printk("area : 0x%08x\n", area);
    kfree(area);
    
}

void Test(void)
{
    printk("=========== Begin test ============\n");
    TestList();
    TestMM();
    printk("=========== End test   ============\n");
}