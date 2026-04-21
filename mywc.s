//----------------------------------------------------------------------
// mywc.s
// Author: Kevin Tran
//----------------------------------------------------------------------

        .section .rodata

printfFormatStr:
        .string "%7ld %7ld %7ld\n"

//----------------------------------------------------------------------

        .section .data
// long lLineCount = 0    
lLineCount: 
        .quad 0
// long lWordCount = 0
lWordCount:
        .quad 0
// long lCharCount = 0
lCharCount: 
        .quad 0
// int iInWord = 0
iInWord: 
        .word 0


//----------------------------------------------------------------------

        .section .bss

// int iChar
iChar: 
        .skip 4

//----------------------------------------------------------------------

        .section .text

        // Must be a multiple of 16
        .equ    MAIN_STACK_BYTECOUNT, 16

        .global main

main:

        // Prolog
        sub     sp, sp, MAIN_STACK_BYTECOUNT
        str     x30, [sp]

         

whileLoop:
        // if ((iChar = getChar()) == EOF) goto endWhileLoop
        // iChar = getchar()
        bl      getchar // w0 = getchar()
        adr     x1, iChar
        str     w0, [x1] // stores w0 to address of x1 which is iChar

        adr     x0, iChar
        ldr     w0, [x0] // w0 = iChar
        cmp     w0, -1 // compares iChar to -1 (EOF)
        beq     endWhileLoop // iff iChar == EOF, exit loop

        // lCharCount++
        adr     x0, lCharCount
        ldr     x1, [x0] // x1 = lCharCount
        add     x1, x1, 1 // x1++
        str     x1, [x0] // store incremented x1 to lCharCount

        // if (isspace(iChar)) goto notSpace
        adr     x0, iChar
        ldr     w0, [x0] // w0 = iChar
        bl      isspace // w0 = isspace(iChar)
        cmp     w0, 0 // compares to see if its not a notSpace
        beq     notSpace // goes to notSpace if not a notSpace

        // if (!iInWord) goto isNewLine
        adr     x0, iInWord
        ldr     w0, [x0] // w0 = iInWord
        cmp     w0, 0 
        beq     isNewLine // if iInWord == 0, skip 

        //lWordCount++
        adr     x0, lWordCount
        ldr     x1, [x0] // x1 = lWordCount
        add     x1, x1, 1 // x1++
        str     x1, [x0] // lWordCount = x1

        // iInWord = 0 (FALSE)
        adr     x0, iInWord
        mov     w1, 0 // w1 = 0
        str     w1, [x0] //iInWord = w1 = 0

        // goto isNewLine
        b       isNewLine

notSpace:
        // from the else of isSpace (so if notSpace)
        adr     x0, iInWord
        ldr     w0, [x0] // w0 = iInWord
        cmp     w0, 0 // if (!iInWord)
        bne     isNewLine // if iInWord != 0, skip

        // iInWord = 1
        adr x0, iInWord
        mov w1, 1 // w1 = 1, write to w1 to not overwrite x0
        str w1, [x0] // w0 = iInWord = 1

isNewLine:
        // if (iChar != '\n') goto notNewLine
        adr     x0, iChar
        ldr     w0, [x0] // w0 = iChar
        cmp     w0, '\n' //compare to new line
        bne     whileLoop  // if not new line, skip

        //lLineCount++
        adr     x0, lLineCount
        ldr     x1, [x0] // x1 = lLineCount
        add     x1, x1, 1 // x1++
        str     x1, [x0] // lLineCount = x1

        // goto whileLoop
        b       whileLoop

endWhileLoop:
        // if (!iInWord) goto skipLastWord
        adr     x0, iInWord
        ldr     w0, [x0]
        cmp     w0, 0
        beq     skipLastWord // if not ending in a word, skip

        // lWordCount++
        adr     x0, lWordCount
        ldr     x1, [x0] // x1 = lWordCount
        add     x1, x1, 1 // x1++
        str     x1, [x0] // lWordCount = x1

skipLastWord:
        adr     x0, printfFormatStr // arg 1: format string
        adr     x1, lLineCount // arg 2: lLineCount 
        ldr     x1, [x1] 
        adr     x2, lWordCount // arg 3: lWordCount 
        ldr     x2, [x2]
        adr     x3, lCharCount // arg 4: lCharCount 
        ldr     x3, [x3]
        bl      printf

        // Epilog and return 0
        mov     w0, 0
        ldr     x30, [sp]
        add     sp, sp, MAIN_STACK_BYTECOUNT
        ret

        .size   main, (. - main)





