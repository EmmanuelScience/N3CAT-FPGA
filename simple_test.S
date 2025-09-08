# fpga_processor.S - Sargantana core processing program
# Reads value from 0x1000, doubles it, writes to 0x1010

.section .text
.global _start
.option norvc

_start:
    li t0, 0x80001000    # Input address
    li t1, 0x80001010    # Output address
    
processing_loop:
    lw t2, 0(t0)         # Read input value
    slli t3, t2, 1       # Multiply by 2 (shift left)
    sw t3, 0(t1)         # Write result to output
    j processing_loop    # Continue processing

# Padding to ensure reliable program size
    nop; nop; nop; nop; nop; nop; nop; nop