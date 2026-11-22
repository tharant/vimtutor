/* lang-demo.c -- a C playground for Lesson 12 (needs :CocInstall coc-clangd).
 * Its TODO markers also give Lesson 6's quickfix something to find. */

#include <stdio.h>

/* TODO: hover over printf with K once coc-clangd is installed */
static int add(int a, int b)
{
    return a + b;
}

int main(void)
{
    printf("sum=%d\n", add(2, 3));
    /* TODO: try gr on add() -- references across the whole file */
    return 0;
}
