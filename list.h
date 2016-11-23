#ifndef _LIST_H_
#define _LIST_H_

#include "types.h"
#include "debug.h"

#ifndef offsetof
#define offsetof(type, member) ((size_t) &((type*)0)->member)
#endif

#ifndef container_of
#define container_of(ptr, type, member) \
    ({ const typeof(((type*)0)->member) *__mptr = (ptr); \
        (type*)((char*)__mptr - offsetof(type, member)); })
#endif

struct list_node_t {
    struct list_node_t *prev;
    struct list_node_t *next;
    struct list_t *list;
};

struct list_t {
    struct list_node_t *head;
    struct list_node_t *tail;
    size_t size;
};

#define list_get(ptr, type, member) container_of(ptr, type, member)
#define list_from_node(node) ((node)->list)
// get
#define list_head(list) ((list)->head)
#define list_tail(list) ((list)->tail)
#define list_size(list) ((list)->size)
#define list_empty(list) (list_size(list) == 0)
#define list_end() ((struct list_node_t *)(NULL))

// node get
#define list_node_prev(node) ((node)->prev)
#define list_node_next(node) ((node)->next)

// itertor
#define list_for_each(tmpname, list)            \
    for (struct list_node_t *tmpname = list_head(list);   \
        tmpname != list_end();                  \
        tmpname = list_node_next(tmpname))
#define list_for_each_r(tmpname, list)          \
    for (struct list_node_t *tmpname = list_tail(list);    \
        tmpname != list_end();                  \
        tmpname = list_node_prev(tmpname))

static inline void list_node_init(struct list_node_t *node) {
    assert(node != NULL);
    node->prev = list_end();
    node->next = list_end();
    node->list = NULL;
}

static inline void list_init(struct list_t *list) {
    assert(list != NULL);
    list->head = NULL;
    list->tail = NULL;
    list->size = 0;
}

static inline struct list_node_t *list_append(
    struct list_t *list, struct list_node_t *node) {
    assert(list != NULL && node != NULL);
    list_node_init(node);
    node->list = list;
    if (!list_empty(list)) {
        struct list_node_t *tail = list_tail(list);
        tail->next = node;
        node->prev = tail;
        list->tail = node;
    } else {
        list->head = node;
        list->tail = node;
    }
    ++list->size;
    return node;
}

static inline struct list_node_t *list_prepend(
    struct list_t *list, struct list_node_t *node) {
    assert(list != NULL && node != NULL);
    list_node_init(node);
    node->list = list;
    if (!list_empty(list)) {
        struct list_node_t *head = list_head(list);
        head->prev = node;
        node->next = head;
        list->head = node;
    } else {
        list->head = node;
        list->tail = node;
    }
    ++list->size;
    return node;
}

// new node will be insert before at old node. 
static inline struct list_node_t *list_insert(
    struct list_node_t *old_node, struct list_node_t *new_node) {
    assert(old_node != NULL && new_node != NULL);
    struct list_t *list = list_from_node(old_node);
    struct list_node_t *head = list_head(list);
    list_node_init(new_node);
    if (head == old_node) {
        head->prev = new_node;
        new_node->next = head;
        list->head = new_node;
    } else {
        new_node->prev = old_node->prev;
        new_node->next = old_node;
        old_node->prev->next = new_node;
        old_node->prev = new_node;
    }
    ++list->size;
    return new_node;
}

static inline struct list_node_t *list_remove(struct list_node_t *node) {
    assert(node != NULL);
    struct list_t *list = list_from_node(node);
    if (list_size(list) == 1) {
        list_init(list);
        list->size = 1;
    } else if (node == list_head(list)) {
        node->next->prev = list_end();
        list->head = node->next;
    } else if (node == list_tail(list)) {
        node->prev->next = list_end();
        list->tail = node->prev;
    } else {
        node->prev->next = node->next;
        node->next->prev = node->prev;
    }
    list_node_init(node);
    --list->size;
    return node;
}

static inline struct list_node_t *list_replace(
    struct list_node_t *old_node, struct list_node_t *new_node) {
    assert(old_node != NULL && new_node != NULL);
    struct list_t *list = list_from_node(old_node);
    list_node_init(new_node);
    if (list_size(list) == 1) {
        list->head = new_node;
        list->tail = new_node;
    } else if (old_node == list_head(list)) {
        old_node->next->prev = new_node;
        new_node->next = old_node->next;
        list->head = new_node;
    } else if (old_node == list_tail(list)) {
        old_node->prev->next = new_node;
        new_node->prev = old_node->prev;
        list->tail = new_node;
    } else {
        new_node->prev = old_node->prev;
        new_node->next = old_node->next;
        new_node->prev->next = new_node;
        new_node->next->prev = new_node;
    }
    list_node_init(old_node);
    return old_node;
}

static inline void list_move(struct list_t *dest, struct list_t *src) {
    assert(dest != NULL && src != NULL);
    list_init(dest);
    dest->head = list_head(src);
    dest->tail = list_tail(src);
    dest->size = list_size(src);
    list_for_each(node, src) {
        node->list = dest;
    }
    list_init(src);
}

#endif /* _LIST_H_ */