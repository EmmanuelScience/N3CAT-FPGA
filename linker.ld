ENTRY(_start)
MEMORY {
    /* Change ORIGIN to the core's execution start address */
    RAM : ORIGIN = 0x80000000, LENGTH = 64K
}
SECTIONS {
    .text : {
        *(.text)
        *(.text.*)
    } > RAM

    /* The rest of your sections... */
    .rodata : { *(.rodata .rodata.*) } > RAM
    .data   : { *(.data .data.*) } > RAM
    .bss    : { *(.bss .bss.* COMMON) } > RAM

    /DISCARD/ : {
        *(.note.gnu.build-id)
        *(.comment)
        *(.eh_frame)
    }
}