/*** asmSort.s   ***/
#include <xc.h>
.syntax unified

@ Declare the following to be in data memory
.data
.align    

@ Define the globals so that the C code can access them
/* define and initialize global variables that C can access */
/* create a string */
.global nameStr
.type nameStr,%gnu_unique_object
    
/*** STUDENTS: Change the next line to your name!  **/
nameStr: .asciz "Matt Moore"  

.align   /* realign so that next mem allocations are on word boundaries */
 
/* initialize a global variable that C can access to print the nameStr */
.global nameStrPtr
.type nameStrPtr,%gnu_unique_object
nameStrPtr: .word nameStr   /* Assign the mem loc of nameStr to nameStrPtr */

@ Tell the assembler that what follows is in instruction memory    
.text
.align

/********************************************************************
function name: asmSwap(inpAddr,signed,elementSize)
function description:
    Checks magnitude of each of two input values 
    v1 and v2 that are stored in adjacent in 32bit memory words.
    v1 is located in memory location (inpAddr)
    v2 is located at mem location (inpAddr + M4 word size)
    
    If v1 or v2 is 0, this function immediately
    places -1 in r0 and returns to the caller.
    
    Else, if v1 <= v2, this function 
    does not modify memory, and returns 0 in r0. 

    Else, if v1 > v2, this function 
    swaps the values and returns 1 in r0

Inputs: r0: inpAddr: Address of v1 to be examined. 
	             Address of v2 is: inpAddr + M4 word size
	r1: signed: 1 indicates values are signed, 
	            0 indicates values are unsigned
	r2: size: number of bytes for each input value.
                  Valid values: 1, 2, 4
                  The values v1 and v2 are stored in
                  the least significant bits at locations
                  inpAddr and (inpAddr + M4 word size).
                  Any bits not used in the word may be
                  set to random values. They should be ignored
                  and must not be modified.
Outputs: r0 returns: -1 If either v1 or v2 is 0
                      0 If neither v1 or v2 is 0, 
                        and a swap WAS NOT made
                      1 If neither v1 or v2 is 0, 
                        and a swap WAS made             
             
         Memory: if v1>v2:
			swap v1 and v2.
                 Else, if v1 == 0 OR v2 == 0 OR if v1 <= v2:
			DO NOT swap values in memory.

NOTE: definitions: "greater than" means most positive number
********************************************************************/     
.global asmSwap
.type asmSwap,%function     
asmSwap:

    /* YOUR asmSwap CODE BELOW THIS LINE! VVVVVVVVVVVVVVVVVVVVV  */
    PUSH {r4-r11, LR}
    
    /* Writes the memory address in r0 to r5 (so we can work with it without
     changing it) and then writes that address offet by 4 bytes to r6, 
     because that would correspond to the next mem location (in the ARM M4) that 
     we want to compare with the original one in r0. 
     
     The mem locations we'll be updating are in r0 and r6. 
     
     Their corresponding values will be in r5 and r7 respectively
    */
    LDR r5, [r0]
    ADD r6, r0, 4
    LDR r7, [r6]
    
    /* 
     This is in case the value in the mem location in r0 or the one 4 bytes
     up that we're comparing it to == 0. This means the end of the 'array' has
     been reached.
    */
    CMP r5, 0
    BEQ zero
    CMP r7, 0
    BEQ zero
    
    /* 
     Compares r2 (size argument) to possible byte numbers (1,2,4) and branches 
     to the corresponding 'load' subroutine 
    */ 
    CMP r2, 1
    BEQ byte
    CMP r2, 2
    BEQ hw
    CMP r2, 4
    BEQ word
    
    /* 
     Writes either a byte or half-word value to corresponding
     v1 or v2 register depending on argument in r2 to 
     
     If the signed/unsigned argument is set, sign extend the byte or 
     halfword, branch to a subroutine (signed_byte or signed_hw) that will sign
     extend the signed byte or halfword before comparison.
     
     This is necessarybecause a 2s complement byte or halfword value, will be 
     compared as an entire word, with zeros extended (from when the rest of the 
     original word in memory was "chopped off" in order to 'extract' just 
     the first byte or half-word of the value) In order to convert the 2s 
     complement negative number in that byte or half word, those residual 0s 
     need to be flipped to 1s and this is done by sign extension.
    */
    byte:
    LDRB r5, [r0]
    LDRB r7, [r6]
    CMP r1, 1
    BEQ signed_byte
    CMP r5, r7
    BHI swap
    BLS continue
    
    signed_byte:
    LSL r5, r5, 24
    ASR r5, r5, 24
    LSL r7, r7, 24
    ASR r7, r7, 24
    
    CMP r5, r7
    BGT swap
    BLE continue
    
    hw:
    LDRH r5, [r0]
    LDRH r7, [r6]
    CMP r1, 1
    BEQ signed_hw
    CMP r5, r7
    BHI swap
    BLS continue
    
    signed_hw:
    LSL r5, r5, 16
    ASR r5, r5, 16
    LSL r7, r7, 16
    ASR r7, r7, 16
        
    CMP r5, r7
    BGT swap
    BLE continue

    /* 
	Word sized values are compared the same way whether they're signed or 
	not because there aren't any 'out-of-range' bits set to zero you'd have
	to flip
    */
    word:
    LDR r5, [r0]
    LDR r7, [r6]
    CMP r1, 1
    BEQ signed_hw
    CMP r5, r7
    BHI swap
    BLS continue
   
    signed_word:
    CMP r5, r7
    BGT swap
    BLE continue
    /*
	Writes v1 to v2 mem location and v2 to v1 mem location e.g. executing a
	'swap' then moves 1 to r0 as per instructions
    */
    
  
    swap:
    CMP r2, 1
    STRBEQ r5, [r6]
    STRBEQ r7, [r0]
    
    CMP r2, 2
    STRHEQ r5, [r6]
    STRHEQ r7, [r0]
    
    CMP r2, 4
    STREQ r5, [r6]
    STREQ r7, [r0]
    
    MOV r0, 1
    B swap_exit
    
    /* Just copies 0 into r0 as per the input instructions, no swap! */
    continue:
    MOV r0, 0
    B swap_exit
    
    /* Copies -1 into r0 as per the input instructions, this is the end of 
     the array
    */
    zero:
    MOV r0, -1
    B swap_exit

    swap_exit:
    POP {r4-r11, LR}
    BX LR
    
    /* YOUR asmSwap CODE ABOVE THIS LINE! ^^^^^^^^^^^^^^^^^^^^^  */
    
    
/********************************************************************
function name: asmSort(startAddr,signed,elementSize)
function description:
    Sorts value in an array from lowest to highest.
    The end of the input array is marked by a value
    of 0.
    The values are sorted "in-place" (i.e. upon returning
    to the caller, the first element of the sorted array 
    is located at the original startAddr)
    The function returns the total number of swaps that were
    required to put the array in order in r0. 
    
         
Inputs: r0: startAddr: address of first value in array.
		      Next element will be located at:
                          inpAddr + M4 word size
	r1: signed: 1 indicates values are signed, 
	            0 indicates values are unsigned
	r2: elementSize: number of bytes for each input value.
                          Valid values: 1, 2, 4
Outputs: r0: number of swaps required to sort the array
         Memory: The original input values will be
                 sorted and stored in memory starting
		 at mem location startAddr
NOTE: definitions: "greater than" means most positive number    
********************************************************************/     
.global asmSort
.type asmSort,%function
asmSort:   

    /* Note to Profs: 
     Besides making the changes recommending in office hours (using HI and LS 
     with signed branch operations and doing shifts to sign extend instead of
     using built in SXT psudoinstruction) The main thing I had to do to get this
     running was initialize my accumulator register.
     
     I saw that I was getting what looked like a mem address in my accumulator 
     step, which indicated to me that I was accumulating a mem address instead
     of 0. Now I'll remember to initialize my accumulator to 0, just like I 
     would in a higher level langauge (e.g. "count = 0;" then "count ++;" )
     */

    /* YOUR asmSort CODE BELOW THIS LINE! VVVVVVVVVVVVVVVVVVVVV  */
    PUSH {r4-r11, LR}
    
   /* 
     increment this value by 1 later. Also initialize r11 and r9 accumulators.
    */
    MOV r9, 0 
    MOV r11, 0
    
    
    /* Save you 'outer' starting point for calling subsequent passes */
    MOV r8, r0
    
    loop:
    /* Save orignal r0 memory location to r10 for increment step */
    MOV r10, r0
    
    /* Calls swap function which will change r0 as output */
    BL asmSwap
    
    /* 
     Ends loop if asmSwap returns -1, e.g. it reached the end of the 'array'
     or sortable values in memory (one of the swap values == 0)
    */
    CMP r0, -1
    BEQ done 
    
    /* Increments 'inside' swap accum. by 1 if asmSwap returns an r0 set to 1
    (or 0 if r0 set to 0)
    */
    ADD r11, r11, r0
    
    /* Increments next mem location to be passed into asmSwap byte, 
    depending on whether it's 1,2,4 bytes as per what's passed in r2
    */
    ADD r0, r10, 4
    BL loop
    
  
    done: 
    /* Outside accumulator increments (total swaps) */
    ADD r9, r9, r11
    
    /* reset r0 to begining of array mem location */
    MOV r0, r8
    
    /* Back to loop if there were any swaps and reset 'swap' accumulator r11 to
     0. We want to run a final pass with zero swaps to confirm the array is 
     sorted. If that's the case, we're done looping
    */
    CMP r11, 0
    MOVNE r11, 0
    BNE loop
    
    /* Copies swap count from 'outside' swap incrementer r9 to r0, pops back 
     registers and branches back to caller
    */
    MOV r0, r9
    POP {r4-r11, LR}
    BX LR
    
    /* YOUR asmSort CODE ABOVE THIS LINE! ^^^^^^^^^^^^^^^^^^^^^  */
    

/**********************************************************************/   
.end  /* The assembler will not process anything after this directive!!! */
           




