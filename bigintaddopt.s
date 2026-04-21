//--------------------------------------------------------------------
// bigintaddopt.s
// Author: Kevin Tran
//--------------------------------------------------------------------

//--------------------------------------------------------------

        .section .text

// Constants
        .equ    FALSE, 0
        .equ    TRUE, 1
        .equ    MAX_DIGITS, 32768

// Struct field offsets
        .equ    LLENGTH, 0
        .equ    AULDIGITS, 8

//--------------------------------------------------------------
// BigInt_larger
        // Stack: save x30, x19, x20, x21 = 4 * 8 = 32 bytes
        .equ    LARGER_STACK_BYTECOUNT, 32
// BigInt_larger
// Return the larger of lLength1 and lLength2.
// Parameters: x0 = lLength1 (long), x1 = lLength2 (long)
// Returns: x0 = the larger of the two values
BigInt_larger:
        // Prolog
        sub     sp, sp, LARGER_STACK_BYTECOUNT
        str     x30, [sp]
        str     x19, [sp, 8]
        str     x20, [sp, 16]
        str     x21, [sp, 24]

        // Store parameters in callee-saved registers
        mov     x19, x0 // x19 = lLength1
        mov     x20, x1 // x20 = lLength2

        // if (lLength1 <= lLength2) goto larger_else1
        cmp     x19, x20
        ble     larger_else1

        // lLarger = lLength1
        mov     x21, x19
        b       larger_endif1

larger_else1:
        // lLarger = lLength2
        mov     x21, x20

larger_endif1:
        // return lLarger
        mov     x0, x21

        // Epilog
        ldr     x21, [sp, 24]
        ldr     x20, [sp, 16]
        ldr     x19, [sp, 8]
        ldr     x30, [sp]
        add     sp, sp, LARGER_STACK_BYTECOUNT
        ret

        .size   BigInt_larger, (. - BigInt_larger)

//--------------------------------------------------------------
// BigInt_add register assignments

OADDEND1   .req x19
OADDEND2   .req x20
OSUM       .req x21
ULCARRY    .req x22
ULSUM      .req x23
LINDEX     .req x24
LSUMLENGTH .req x25

        // Stack: save x30, x19-x25 = 8 * 8 = 64 bytes
        .equ    ADD_STACK_BYTECOUNT, 64

        .global BigInt_add
// BigInt_add
// Assign the sum of oAddend1 and oAddend2 to oSum.
// Parameters: x0 = oAddend1 (BigInt_T), x1 = oAddend2 (BigInt_T),
//             x2 = oSum (BigInt_T)
// Returns: w0 = TRUE (1) if successful, FALSE (0) if overflow
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

        // lSumLength = BigInt_larger(oAddend1->lLength,
        //                            oAddend2->lLength)
        ldr     x0, [OADDEND1, LLENGTH] // x0 = oAddend1->lLength
        ldr     x1, [OADDEND2, LLENGTH] // x1 = oAddend2->lLength
        bl      BigInt_larger
        mov     LSUMLENGTH, x0 // lSumLength = result

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
        // ulCarry = 0
        // lIndex = 0
        mov     ULCARRY, 0
        mov     LINDEX, 0

forLoop:
        // if (lIndex >= lSumLength) goto endForLoop
        cmp     LINDEX, LSUMLENGTH
        bge     endForLoop

        // ulSum = ulCarry
        // ulCarry = 0
        mov     ULSUM, ULCARRY
        mov     ULCARRY, 0

        // ulSum += oAddend1->aulDigits[lIndex]
        add     x0, OADDEND1, AULDIGITS
        ldr     x1, [x0, LINDEX, lsl 3]
        add     ULSUM, ULSUM, x1

        // if (ulSum >= oAddend1->aulDigits[lIndex]) goto noCarry1
        // ulCarry = 1
        cmp     ULSUM, x1
        bhs     noCarry1
        mov     ULCARRY, 1

noCarry1:
        // ulSum += oAddend2->aulDigits[lIndex]
        add     x0, OADDEND2, AULDIGITS
        ldr     x1, [x0, LINDEX, lsl 3]
        add     ULSUM, ULSUM, x1

        // if (ulSum >= oAddend2->aulDigits[lIndex]) goto noCarry2
        // ulCarry = 1
        cmp     ULSUM, x1
        bhs     noCarry2
        mov     ULCARRY, 1

noCarry2:
        // oSum->aulDigits[lIndex] = ulSum
        add     x0, OSUM, AULDIGITS
        str     ULSUM, [x0, LINDEX, lsl 3]

        // lIndex++
        // goto forLoop
        add     LINDEX, LINDEX, 1
        b       forLoop

endForLoop:
        // if (ulCarry != 1) goto noFinalCarry
        cmp     ULCARRY, 1
        bne     noFinalCarry

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
