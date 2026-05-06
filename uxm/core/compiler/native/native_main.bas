' Auto-split by V3 modularization
Sub Main()
    Dim s As String
    InitDefaults()
    If Command(1)<>"" Then
        InFile=TrimAll(Command(1))
    Else
        Print "UX-MINIMA x64 V3.1 FreeBASIC compiler"
        Print "Kaynak .uxm dosyasi: ";
        Line Input InFile
        InFile=TrimAll(InFile)
    End If
    If InFile="" Then
        Print "HATA: kaynak dosya verilmedi."
        End
    End If
    If Command(2)<>"" Then
        OutAsm=TrimAll(Command(2))
    Else
        OutAsm=InFile+".asm"
    End If
    ReadFileToSrc(InFile)
    If HadError Then Print ErrMsg:End 1
    ParsePragmas()
    If HadError Then Print ErrMsg:End 1
    ApplyMemoryModel()
    If HadError Then Print ErrMsg:End 1
    FirstPassDefinitions()
    If HadError Then Print ErrMsg:End 1
    ParseProgram(Src,0)
    If HadError Then Print ErrMsg:End 1
    ValidateBranches()
    If HadError Then Print ErrMsg:End 1
    GenerateASM()
    If HadError Then Print ErrMsg:End 1
    Print "ASM uretildi: ";OutAsm
    Print "NASM:"
    Print "nasm -f win64 ";OutAsm;" -o program.obj"
    Print "FreeBASIC runtime ile link:"
    Print "fbc uxm31_runtime_fb.bas program.obj -x program.exe"
End Sub

