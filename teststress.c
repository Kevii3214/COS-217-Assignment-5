#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main(void)
{
    int i;
    int iChar;

    srand((unsigned int)time(NULL));

    for (i = 0; i < 500000; i++)
    {
        iChar = rand() % 0x7F;

        if (iChar == 0x09 || iChar == 0x0A ||
            (iChar >= 0x20 && iChar <= 0x7E))
        {
            putchar(iChar);
        }
    }

    return 0;
}