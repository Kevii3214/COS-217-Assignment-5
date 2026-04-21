//----------------------------------------------------------------------
// bigintaddoptopt.s
// Author: Kevin Tran
//----------------------------------------------------------------------

//--------------------------------------------------------------

        .section .text

// Constants
        .equ    FALSE, 0
        .equ    TRUE, 1
        .equ    MAX_DIGITS, 32768

// Struct field offsets
        .equ    LLENGTH, 0
        .equ    AULDIGITS, 8
// remove BigInt_larger to be inline
//--------------------------------------------------------------
// BigInt_add register assignments

OADDEND1   .req x19
OADDEND2   .req x20
OSUM       .req x21
ULSUM      .req x22 // we can remove ULCARRY
LINDEX     .req x23
LSUMLENGTH .req x24

        // Stack: save x30, x19-x25 = 8 * 8 = 64 bytes
        .equ    ADD_STACK_BYTECOUNT, 64

        .global BigInt_add

BigInt_add:
        // Prolog: save x30 and all callee-saved registers we use
        sub     sp, sp, ADD_STACK_BYTECOUNT
        str     x30, [sp]
        str     x19, [sp, 8]
        str     x20, [sp, 16]
        str     x21, [sp, 24]
        str     x22, [sp, 32]
        str     x23, [sp, 40]
        str     x24, [sp, 48]
        str     x25, [sp, 56]

        // Store parameters in callee-saved registers
        mov     OADDEND1, x0 // x19 = oAddend1
        mov     OADDEND2, x1 // x20 = oAddend2
        mov     OSUM, x2 // x21 = oSum

        // inline BigInt_larger
        // lSumLength = BigInt_larger(oAddend1->lLength,
        //                            oAddend2->lLength)
         // lSumLength = lLength1
        ldr     LSUMLENGTH, [OADDEND1, LLENGTH]
        ldr     x0, [OADDEND2, LLENGTH] // x0 = lLength2
        cmp     LSUMLENGTH, x0
        bge     skipUpdate
        mov     LSUMLENGTH, x0 // lSumLength = result

skipUpdate:

        // if (oSum->lLength <= lSumLength) goto skipMemset
        ldr     x0, [OSUM, LLENGTH] // x0 = oSum->lLength
        cmp     x0, LSUMLENGTH
        ble     skipMemset

        // memset(oSum->aulDigits, 0, MAX_DIGITS * 8)
        add     x0, OSUM, AULDIGITS // x0 = oSum->aulDigits
        mov     w1, 0
        mov     x2, MAX_DIGITS
        lsl     x2, x2, 3 // x2 = MAX_DIGITS * 8
        bl      memset

skipMemset:
        // lIndex = 0
        mov     LINDEX, 0

        // guard: if (lIndex >= lSumLength) skip loop entirely
        cmp     LINDEX, LSUMLENGTH
        bge     endForLoop

        // Clear the carry flag (C = 0) before first iteration
        adds xzr, xzr, 0

forLoop:
        // Load oAddend1->aulDigits[lIndex]
        add     x0, OADDEND1, AULDIGITS
        ldr     x0, [x0, LINDEX, lsl 3]

        // Load oAddend2->aulDigits[lIndex]
        add     x1, OADDEND2, AULDIGITS
        ldr     x1, [x1, LINDEX, lsl 3]

        // ulSum = oAddend1->aulDigits[lIndex]
        //        + oAddend2->aulDigits[lIndex]
        //        + carry flag
        // adcs sets the carry flag automatically
        adcs    ULSUM, x0, x1

        // oSum->aulDigits[lIndex] = ulSum
        add     x0, OSUM, AULDIGITS
        str     ULSUM, [x0, LINDEX, lsl 3]

        // lIndex++
        // Guarded loop: test at bottom
        // we must NOT clobber the carry flag here
        // "add" does NOT set flags, "adds" WOULD set flags
        // So we use "add" for the increment
        add     LINDEX, LINDEX, 1

        // now we need to compare lIndex to lSumLength
        // without destroying the carry flag
        // sub + blt would destroy flags
        // save and restore the carry flag using cset/cmp
        // Save carry flag into a temp register
        cset    x2, cs // x2 = 1 if carry set, 0 if not
        cmp     LINDEX, LSUMLENGTH // safely compare
        bge     endForLoopCarry

        // Restore carry flag: if x2 == 1, set carry; if 0, clear it
        cmp     x2, 1 // sets C if x2 >= 1 (unsigned)
        b       forLoop

endForLoopCarry:
        // Carry flag was saved in x2, use for final carry check
        // x2 = 1 means there was a carry out of the last column
        cmp     x2, 0
        beq     noFinalCarry
        b       handleCarry

endForLoop:
        // We got here from the guard (empty loop), no carry
        b       noFinalCarry

handleCarry:
        // if (lSumLength == MAX_DIGITS) goto returnFalse
        mov     x0, MAX_DIGITS
        cmp     LSUMLENGTH, x0
        beq     returnFalse

        // oSum->aulDigits[lSumLength] = 1
        add     x0, OSUM, AULDIGITS
        mov     x1, 1
        str     x1, [x0, LSUMLENGTH, lsl 3]

        // lSumLength++
        add     LSUMLENGTH, LSUMLENGTH, 1

noFinalCarry:
        // oSum->lLength = lSumLength
        str     LSUMLENGTH, [OSUM, LLENGTH]

        // return TRUE
        mov     w0, TRUE

        // Epilog: restore all callee-saved registers
        ldr     x25, [sp, 56]
        ldr     x24, [sp, 48]
        ldr     x23, [sp, 40]
        ldr     x22, [sp, 32]
        ldr     x21, [sp, 24]
        ldr     x20, [sp, 16]
        ldr     x19, [sp, 8]
        ldr     x30, [sp]
        add     sp, sp, ADD_STACK_BYTECOUNT
        ret

returnFalse:
        // return FALSE
        mov     w0, FALSE

        // Epilog: restore all callee-saved registers
        ldr     x25, [sp, 56]
        ldr     x24, [sp, 48]
        ldr     x23, [sp, 40]
        ldr     x22, [sp, 32]
        ldr     x21, [sp, 24]
        ldr     x20, [sp, 16]
        ldr     x19, [sp, 8]
        ldr     x30, [sp]
        add     sp, sp, ADD_STACK_BYTECOUNT
        ret

        .size   BigInt_add, (. - BigInt_add)
        