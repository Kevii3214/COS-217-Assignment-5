//----------------------------------------------------------------------
// bigintadd.s
// Author: Kevin Tran
//----------------------------------------------------------------------

//----------------------------------------------------------------------

        .section .text

//constants

        .equ FALSE, 0

        .equ TRUE, 1

        .equ MAX_DIGITS, 32768

        // struct field offsets in struct BigInt
        .equ LLENGTH, 0

        .equ AULDIGITS, 8

//----------------------------------------------------------------------        
// BigInt_larger stack layout
        // Must be a multiple of 16
        // parameters and local variables must go on stack = 32 bytes
        .equ    LARGER_STACK_BYTECOUNT, 32 
//----------------------------------------------------------------------
// BigInt_add stack layout      
        // Must be a multiple of 16
        // parameters and local variables must go on stack = 64 bytes
        .equ    LARGER_STACK_BYTECOUNT, 64 

        .equ    OADDEND1, 8

        .equ    OADDEND2, 16

        .equ    OSUM, 24

        .equ    ULCARRY, 32

        .equ    ULSUM, 40

        .equ    LINDEX, 48

        .equ    LSUMLENGTH, 56

//----------------------------------------------------------------------
BigInt_larger:
        // Prolog
        sub     sp, sp, LARGER_STACK_BYTECOUNT
        str     x30, [sp]
        str     x0, [sp, 8] // store lLength1
        str     x1, [sp, 16] // store lLength2

        // if (lLength1 <= lLength2) goto else1
        ldr     x0, [sp, 8] // x0 = lLength1
        ldr     x1, [sp, 16] // x1 = lLength2
        cmp     x0, x1
        ble     larger_else1 // signed: lLength1 <= lLength2

        // lLarger = 1Length1
        ldr     x0, [sp, 8]
        str     x0, [sp, 24] // lLarger = lLength1
        b       larger_endif1

larger_else1:
        // lLarger = lLength2
        ldr     x0, [sp,16]
        str     x0, [sp, 24]

larger_endif1:
        // return lLarger
        ldr     x0, [sp, 24] // x0 = lLarger 

        // Epilog and return 0
        ldr     x30, [sp]
        add     sp, sp, LARGER_STACK_BYTECOUNT
        ret

        .size   BigInt_larger, (. - BigInt_larger)

//----------------------------------------------------------------------
        .global BigInt_add // not static

BigInt_add:
        // Prolog
        sub     sp, sp, LARGER_STACK_BYTECOUNT
        str     x30, [sp]
        str     x0, [sp,OADDEND1] // store oAddend1
        str     x1, [sp, OADDEND2] // store oAddend2
        str     x2, [sp, OSUM] // store OSUM

        // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->
        // 1length)
        ldr     x0, [sp, OADDEND1] // x0 = oAddend1
        ldr     x0, [x0, LLENGTH] // x0 = oAddend1 ->1length
        ldr     x1, [sp, OADDEND2] // x1 = oAddend2
        ldr     x1, [x1, LLENGTH] // x1 = oAddend2->lLength
        bl      BigInt_larger // x0 = larger of the two
        str     x0, [sp, LSUMLENGTH] //lSumLength = result

        // if (oSum->lLength <= lSumLength) goto skipMemset
        ldr     x0, [sp, OSUM] // x0 = oSum
        ldr     x0, [x0 LLENGTH] // x0 = oSum->lLength
        ldr     x1, [sp, LSUMLENGTH] // x1 = lSumLength
        cmp     x0, x1
        ble skipMemset

        // memset(oSum->aulDigits, 0, MAX_DIGITS * 
        // sizeof(unsigned long))
        ldr     x0, [sp, OSUM] // x0 = oSum
        add     x0, x0, AULDIGITS // x0 = oSum->aulDigits
        mov     w1, 0 // fill with 0
        mov     x2, MAX_DIGITS // number of elements
        lsl     x2, x2, 3 // x2 = MAX_DIGITS * 8
        bl      memset

skipMemset:
        // ulCarry = 0
        // lIndex = 0
        mov     x0, 0
        str     x0, [sp, ULCARRY] // ulCarry = 0
        str     x0, [sp, LINDEX] // lIndex = 0

forLoop:
        // if(lIndex >= lSumLength) goto endForLoop
        ldr     x0, [sp, LINDEX] // x0 = lIndex
        ldr     x1, [sp, LSUMLENGTH] // x1 = lSumLength
        cmp     x0, x1
        bge     endForLoop  // signed compare

        // ulSum = ulCarry
        // ulCarry = 0
        ldr     x0, [sp, ULCARRY] // x0 = ulCarry
        str     x0, [sp, ULSUM] ulSum = x0 = ulCarry
        mov     x0, 0
        str     x0, [sp, ULCARRY] // ulCarry = 0

        // ulSum += oAddend1->aulDigits[lIndex]
        ldr     x0, [sp, OADDEND1] // x0 = oAddend1
        add     x0, x0, AULDIGITS  // x0 = oAddend1->aulDigits
        ldr     x1, [sp, LINDEX] // x1 = lIndex
        ldr     x2, [x0, x1, lsl 3] // x2 = oAddend1->
        // aulDigits[lIndex]
        ldr     x0, [sp, ULSUM] // x0 = ulSum
        add     x0, x0, x2 // x0 = ulSum + aulDigits[lIndex]
        str     x0, [sp, ULSUM] // ulSum = new sum

        // if (ulSum >= oAddend->aulDigits[lIndex]) goto noCarry1
        // ulCarry = 1
        ldr     x0, [sp, ULSUM] // x0 = ulSum
        ldr     x1, [sp, OADDEND1] // x1 = oAddend1
        add     x1, x1, AULDIGITS // x1 = oAddend1->aulDigits
        ldr     x2, [sp, LINDEX] // x2 = lIndex
        ldr     x1, [x1, x2, lsl 3] // x1 = oAddend1->aulDigits[lIndex]
        cmp     x0, x1
        bhs     noCarry1 // UNSIGNED: higher or same

        mov     x0, 1
        str     x0, [sp, ULCARRY] // ulCarry = 1

noCarry1:
        // ulSum += oAddend2->aulDigits[lIndex]
        ldr     x0, [sp, OADDEND2]     // x0 = oAddend2
        add     x0, x0, AULDIGITS      // x0 = oAddend2->aulDigits
        ldr     x1, [sp, LINDEX]       // x1 = lIndex
        ldr     x2, [x0, x1, lsl 3]    // x2 = oAddend2->aulDigits[lIndex]
        ldr     x0, [sp, ULSUM]        // x0 = ulSum
        add     x0, x0, x2             // x0 = ulSum + aulDigits[lIndex]
        str     x0, [sp, ULSUM]        // ulSum = new sum

        // if (ulSum >= oAddend2->aulDigits[lIndex]) goto noCarry2
        // ulCarry = 1
        ldr     x0, [sp, ULSUM]        // x0 = ulSum
        ldr     x1, [sp, OADDEND2]     // x1 = oAddend2
        add     x1, x1, AULDIGITS      // x1 = oAddend2->aulDigits
        ldr     x2, [sp, LINDEX]       // x2 = lIndex
        ldr     x1, [x1, x2, lsl 3]    // x1 = oAddend2->aulDigits[lIndex]
        cmp     x0, x1
        bhs     noCarry2                // UNSIGNED: higher or same

        mov     x0, 1
        str     x0, [sp, ULCARRY]      // ulCarry = 1

noCarry2:
        // oSum->aulDigits[lIndex] = ulSum
         ldr     x0, [sp, OSUM]         // x0 = oSum
        add     x0, x0, AULDIGITS      // x0 = oSum->aulDigits
        ldr     x1, [sp, LINDEX]       // x1 = lIndex
        ldr     x2, [sp, ULSUM]        // x2 = ulSum
        str     x2, [x0, x1, lsl 3] // oSum->aulDigits[lIndex] = ulSum

        // lIndex++
        // goto forLoop
        ldr     x0, [sp, LINDEX]       // x0 = lIndex
        add     x0, x0, 1              // x0++
        str     x0, [sp, LINDEX]       // lIndex = x0
        b       forLoop

endForLoop:
        // if (ulCarry != 1) goto noFinalCarry
        ldr     x0, [sp, ULCARRY]      // x0 = ulCarry
        cmp     x0, 1
        bne     noFinalCarry

        //if (lSumLength == MAX_DIGITS) goto returnFalse
        ldr     x0, [sp, LSUMLENGTH]   // x0 = lSumLength
        mov     x1, MAX_DIGITS
        cmp     x0, x1
        beq     returnFalse

        // oSum->aulDigits[lSumLength] = 1
        ldr     x0, [sp, OSUM]         // x0 = oSum
        add     x0, x0, AULDIGITS      // x0 = oSum->aulDigits
        ldr     x1, [sp, LSUMLENGTH]   // x1 = lSumLength
        mov     x2, 1
        str     x2, [x0, x1, lsl 3] // oSum->aulDigits[lSumLength] = 1

        // lSumLength++
        ldr     x0, [sp, LSUMLENGTH]
        add     x0, x0, 1
        str     x0, [sp, LSUMLENGTH]   // lSumLength++

noFinalCarry:
        // oSum->lLength = lSumLength
        ldr     x0, [sp, OSUM]         // x0 = oSum
        ldr     x1, [sp, LSUMLENGTH]   // x1 = lSumLength
        str     x1, [x0, LLENGTH]      // oSum->lLength = lSumLength

        // return TRUE
        mov     w0, TRUE // return value = 1

         // Epilog
        ldr     x30, [sp]
        add     sp, sp, ADD_STACK_BYTECOUNT
        ret

returnFalse:
        // return FALSE
        mov     w0, FALSE // return value = 0

        // Epilog
        ldr     x30, [sp]
        add     sp, sp, ADD_STACK_BYTECOUNT
        ret

        .size   BigInt_add, (. - BigInt_add)





