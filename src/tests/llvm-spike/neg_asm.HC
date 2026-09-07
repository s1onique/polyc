I64 AsmDemo(I64 a)
{
    asm {
        mov rax, rdi
    }
    return a;
}
