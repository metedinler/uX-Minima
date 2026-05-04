# UX-MINIMA Toolchain

Bu klasörde final ARGE compiler kaynağı vardır:

```text
uxm31_compiler_final.bas
```

VS Code komutu ile derlenir:

```text
UX-MINIMA: Build Final ARGE Compiler
```

Veya elle:

```bat
fbc uxm31_compiler_final.bas -x uxm31_compiler_final.exe
```

Native EXE üretmek için ayrıca `uxm31_runtime_fb_full.bas`, `nasm` ve `fbc` gerekir.
