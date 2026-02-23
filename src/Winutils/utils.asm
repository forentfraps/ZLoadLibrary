global UniversalStub
global pebGrabba

section .text

    pebGrabba:
        mov rax, gs:0x60
        ret

    UniversalStub:
       ret 
