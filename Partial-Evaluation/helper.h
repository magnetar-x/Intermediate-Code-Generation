#ifndef HELPER_H
#define HELPER_H

#include <stdio.h>
#include <string.h>

extern char code[1000][100];

typedef struct {
    int items[20];
    int count;
} List;

static List makelist(int i) {
    List temp;
    temp.items[0] = i;
    temp.count = 1;
    return temp;
}

static List emptylist() {
    List temp;
    temp.count = 0;
    return temp;
}

static List merge(List l1, List l2) {
    List temp = l1;
    for (int i = 0; i < l2.count; i++) {
        temp.items[temp.count++] = l2.items[i];
    }
    return temp;
}

static void backpatch(List l, int target) {
    if (l.count == 0) return;
    printf("backpatch ");
    for (int i = 0; i < l.count; i++) {
        printf("%d, ", l.items[i]);
        char buf[20];
        sprintf(buf, " %d", target);
        strcat(code[l.items[i]], buf);
    }
    printf("with target %d\n", target);
}

static void print_lists(List t, List f) {
    printf("truelist : ");
    for (int i = 0; i < t.count; i++) {
        printf("%d, ", t.items[i]);
    }
    printf("\nfalselist : ");
    for (int i = 0; i < f.count; i++) {
        printf("%d, ", f.items[i]);
    }
    printf("\n");
}

#endif
