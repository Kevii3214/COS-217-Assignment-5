#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main(void)
{
    int i;
    int iChar;
    int iLineCount = 0;
    int iCharCount = 0;

    srand((unsigned int)time(NULL));

    for (i = 0; i < 500000 && iCharCount < 50000; i++)
    {
        iChar = rand() % 0x7F;

        if (iChar == 0x09 ||
            (iChar >= 0x20 && iChar <= 0x7E))
        {
            putchar(iChar);
            iCharCount++;
        }
        else if (iChar == 0x0A && iLineCount < 999)
        {
            putchar(iChar);
            iCharCount++;
            iLineCount++;
        }
    }

    return 0;
}