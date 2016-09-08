#ifndef _DEBUG_H_
#define _DEBUG_H_

#define assert(condition)       \
    do {                        \
        if (!(condition))       \
            panic(#condition);  \
    } while (0)                 \

#define static_assert(condition)    \
    switch (x) { case 0: case (x):;}

void panic(const char *msg);
void print_stack_trace(void);
void print_current_status(void);


#endif /* _DEBUG_H_ */