#Lang "fb"
Const UXM_VERSION As String="3.1"
Const MAX_SRC As Long=2000000
Const MAX_INSTR As Long=200000
Const MAX_STRINGS As Long=1024
Const MAX_MACROS As Long=128
Const MAX_LOOP As Long=8192
Const MAX_LABELS As Long=200000
Const UXM_TOTAL_BYTES As Long=65536
Const OP_NOP As Long=0
Const OP_RIGHT As Long=1
Const OP_LEFT As Long=2
Const OP_INC As Long=3
Const OP_DEC As Long=4
Const OP_CLEAR As Long=5
Const OP_PUTC As Long=6
Const OP_GETC As Long=7
Const OP_LOOP_BEG As Long=8
Const OP_LOOP_END As Long=9
Const OP_PUSH As Long=10
Const OP_POP As Long=11
Const OP_EQ As Long=12
Const OP_GT As Long=13
Const OP_LT As Long=14
Const OP_AND As Long=15
Const OP_OR As Long=16
Const OP_XOR As Long=17
Const OP_NOT As Long=18
Const OP_SHL As Long=19
Const OP_SHR As Long=20
Const OP_STATUS As Long=21
Const OP_META As Long=22
Const OP_BRANCH As Long=23
Const OP_PRINT_STRING As Long=24
Const ADDR_T As Long=0
Const ADDR_T_REL As Long=1
Const ADDR_T_ABS As Long=2
Const ADDR_D_ABS As Long=3
Const ADDR_S_ABS As Long=4
Const ADDR_SP As Long=5
Const ADDR_P As Long=6
Const ADDR_E As Long=7
Const ADDR_F As Long=8
Const ADDR_IND_T As Long=9
Const ADDR_IND_T_REL As Long=10
Const ADDR_D_AT_T_REL As Long=11
Const ADDR_D_AT_TBASE_REL As Long=12
Const BR_CUR_NZ As Long=1
Const BR_CUR_Z As Long=2
Const BR_ALWAYS As Long=3
Const BR_Z_SET As Long=4
Const BR_Z_CLR As Long=5
Const BR_C_SET As Long=6
Const BR_C_CLR As Long=7
Const BR_O_SET As Long=8
Const BR_O_CLR As Long=9
Const BR_S_SET As Long=10
Const BR_S_CLR As Long=11
Const MODE_SAFE As Long=0
Const MODE_NORMAL As Long=1
Const MODE_WILD As Long=2
Declare Sub Main()
Declare Sub InitDefaults()
Declare Sub ReadFileToSrc(ByVal fileName As String)
Declare Sub FirstPassDefinitions()
Declare Sub ParsePragmas()
Declare Sub ApplyMemoryModel()
Declare Sub ParseProgram(ByRef code As String, ByVal depth As Long)
Declare Sub ParseOneInstruction(ByRef code As String, ByRef p As Long, ByVal depth As Long)
Declare Sub ParseStringDef(ByRef code As String, ByRef p As Long)
Declare Sub ParseMacroDef(ByRef code As String, ByRef p As Long)
Declare Sub ParsePrintString(ByRef code As String, ByRef p As Long)
Declare Sub ParseMeta(ByRef code As String, ByRef p As Long, ByVal depth As Long)
Declare Sub ParseBranch(ByRef code As String, ByRef p As Long)
Declare Sub AddInstr(ByVal op As Long, ByVal amount As Long, ByVal addrKind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long, ByVal txt As String)
Declare Sub AddMetaInstr(ByVal metaId As Long, ByVal dynamicFlag As Long, ByVal forceHost As Long, ByVal txt As String)
Declare Sub AddBranchInstr(ByVal cond As Long, ByVal brDir As Long, ByVal dist As Long, ByVal txt As String)
Declare Sub AddStringDef(ByVal id As Long, ByVal startCell As Long, ByVal txt As String)
Declare Sub AddMacroDef(ByVal id As Long, ByVal txt As String)
Declare Sub SkipLine(ByRef code As String, ByRef p As Long)
Declare Sub SyntaxError(ByVal msg As String, ByVal p As Long)
Declare Sub ValidateBranches()
Declare Sub GenerateASM()
Declare Sub EmitHeader()
Declare Sub EmitStringInitializers()
Declare Sub EmitInstr(ByVal i As Long)
Declare Sub EmitFooter()
Declare Sub EmitLine(ByVal s As String)
Declare Sub EmitAddrLoad(ByVal addrKind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long, ByVal regName As String)
Declare Sub EmitAddrStore(ByVal addrKind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long, ByVal regName As String)
Declare Sub EmitAddrPtr(ByVal addrKind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long, ByVal outReg As String)
Declare Sub EmitSetFlagsFromRAX()
Declare Sub EmitMetaCall(ByVal metaId As Long, ByVal dynamicFlag As Long, ByVal forceHost As Long)
Declare Sub EmitBranch(ByVal i As Long)
Declare Sub EmitLoopBegin(ByVal i As Long)
Declare Sub EmitLoopEnd(ByVal i As Long)
Declare Sub EmitAsmLabelIfNeeded(ByVal i As Long)
Declare Function ParseUnsignedLong(ByRef code As String, ByRef p As Long, ByRef ok As Long) As Long
Declare Function ParseBracedText(ByRef code As String, ByRef p As Long, ByRef ok As Long) As String
Declare Function ParseAddress(ByRef code As String, ByRef p As Long, ByRef kind As Long, ByRef addrVal As Long, ByRef addrVal2 As Long) As Long
Declare Function ParseAddressBody(ByVal body As String, ByRef kind As Long, ByRef addrVal As Long, ByRef addrVal2 As Long) As Long
Declare Function ParseTapeRelInside(ByVal s As String, ByRef baseRel As Long) As Long
Declare Function FindStringIndex(ByVal id As Long) As Long
Declare Function FindMacroIndex(ByVal id As Long) As Long
Declare Function IsDigitChar(ByVal c As String) As Long
Declare Function IsSpaceChar(ByVal c As String) As Long
Declare Function IsCommandChar(ByVal c As String) As Long
Declare Function CellSize() As Long
Declare Function MemSizePrefix() As String
Declare Function Reg8(ByVal regName As String) As String
Declare Function Reg16(ByVal regName As String) As String
Declare Function Reg32(ByVal regName As String) As String
Declare Function TrimAll(ByVal s As String) As String
Declare Function AddressText(ByVal kind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long) As String
Declare Function RemoveBOM(ByVal s As String) As String
Declare Function NewAsmId() As Long
Declare Function LowerNoSpace(ByVal s As String) As String
Declare Function GetPragmaValue(ByVal lineText As String, ByVal keyName As String) As String
Declare Function ParseSizeKB(ByVal s As String, ByVal defaultKB As Long) As Long
Dim Shared Src As String
Dim Shared InFile As String
Dim Shared OutAsm As String
Dim Shared HadError As Long
Dim Shared ErrMsg As String
Dim Shared InstrCount As Long
Dim Shared IOp(1 To MAX_INSTR) As Long
Dim Shared IAmt(1 To MAX_INSTR) As Long
Dim Shared IAddrKind(1 To MAX_INSTR) As Long
Dim Shared IAddrVal(1 To MAX_INSTR) As Long
Dim Shared IAddrVal2(1 To MAX_INSTR) As Long
Dim Shared IText(1 To MAX_INSTR) As String
Dim Shared IMetaId(1 To MAX_INSTR) As Long
Dim Shared IMetaDyn(1 To MAX_INSTR) As Long
Dim Shared IMetaForce(1 To MAX_INSTR) As Long
Dim Shared IBrCond(1 To MAX_INSTR) As Long
Dim Shared IBrDir(1 To MAX_INSTR) As Long
Dim Shared IBrDist(1 To MAX_INSTR) As Long
Dim Shared IBrTarget(1 To MAX_INSTR) As Long
Dim Shared NeedLabel(1 To MAX_LABELS) As Long
Dim Shared StrCount As Long
Dim Shared StrId(1 To MAX_STRINGS) As Long
Dim Shared StrStart(1 To MAX_STRINGS) As Long
Dim Shared StrText(1 To MAX_STRINGS) As String
Dim Shared MacroCount As Long
Dim Shared MacroId(1 To MAX_MACROS) As Long
Dim Shared MacroText(1 To MAX_MACROS) As String
Dim Shared LoopStack(1 To MAX_LOOP) As Long
Dim Shared LoopSP As Long
Dim Shared LoopId(1 To MAX_INSTR) As Long
Dim Shared LoopCounter As Long
Dim Shared CellBits As Long
Dim Shared TapeKB As Long
Dim Shared StackKB As Long
Dim Shared DataKB As Long
Dim Shared TapeCells As Long
Dim Shared StackCells As Long
Dim Shared DataCells As Long
Dim Shared TapeBytes As Long
Dim Shared StackBytes As Long
Dim Shared DataBytes As Long
Dim Shared DataOffset As Long
Dim Shared StackOffset As Long
Dim Shared Mode As Long
Dim Shared BoundsOn As Long
Dim Shared OverflowCheck As Long
Dim Shared DefaultSigned As Long
Dim Shared DefaultBigEndian As Long
Dim Shared OutFF As Long
Dim Shared EmitLabelCounter As Long
#Include Once "math_extensions/compiler/arge_parse_math_additions.bas"
Main()
End
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
    If HadError Then Print ErrMsg:End
    ParsePragmas()
    If HadError Then Print ErrMsg:End
    ApplyMemoryModel()
    If HadError Then Print ErrMsg:End
    FirstPassDefinitions()
    If HadError Then Print ErrMsg:End
    ParseProgram(Src,0)
    If HadError Then Print ErrMsg:End
    ValidateBranches()
    If HadError Then Print ErrMsg:End
    GenerateASM()
    If HadError Then Print ErrMsg:End
    Print "ASM uretildi: ";OutAsm
    Print "NASM:"
    Print "nasm -f win64 ";OutAsm;" -o program.obj"
    Print "FreeBASIC runtime ile link:"
    Print "fbc uxm31_runtime_fb.bas program.obj -x program.exe"
End Sub
Sub InitDefaults()
    CellBits=8
    TapeKB=32
    StackKB=8
    DataKB=24
    Mode=MODE_NORMAL
    BoundsOn=1
    OverflowCheck=0
    DefaultSigned=0
    DefaultBigEndian=0
    ApplyMemoryModel()
End Sub
Sub ApplyMemoryModel()
    TapeBytes=TapeKB*1024
    StackBytes=StackKB*1024
    DataBytes=DataKB*1024
    If TapeBytes+StackBytes+DataBytes<>UXM_TOTAL_BYTES Then
        HadError=1
        ErrMsg="HATA: bellek toplamı 64 KB olmali. Tape+Stack+Data="+Str(TapeBytes+StackBytes+DataBytes)
        Exit Sub
    End If
    If CellBits<>8 And CellBits<>16 And CellBits<>32 Then
        HadError=1
        ErrMsg="HATA: cell byte/word/dword olmali."
        Exit Sub
    End If
    StackOffset=TapeBytes
    DataOffset=TapeBytes+StackBytes
    TapeCells=TapeBytes\CellSize()
    StackCells=StackBytes\CellSize()
    DataCells=DataBytes\CellSize()
End Sub
Sub ReadFileToSrc(ByVal fileName As String)
    Dim ff As Integer
    Dim sz As Long
    If Len(Dir(fileName))=0 Then
        HadError=1
        ErrMsg="HATA: kaynak dosya bulunamadi: "+fileName
        Exit Sub
    End If
    ff=FreeFile
    Open fileName For Binary Access Read As #ff
    sz=Lof(ff)
    If sz>MAX_SRC Then
        Close #ff
        HadError=1
        ErrMsg="HATA: kaynak dosya cok buyuk."
        Exit Sub
    End If
    If sz>0 Then
        Src=Space(sz)
        Get #ff,,Src
    Else
        Src=""
    End If
    Close #ff
    Src=RemoveBOM(Src)
End Sub
Function RemoveBOM(ByVal s As String) As String
    If Len(s)>=3 Then
        If (Asc(Mid(s,1,1)) And &HFF)=&HEF And (Asc(Mid(s,2,1)) And &HFF)=&HBB And (Asc(Mid(s,3,1)) And &HFF)=&HBF Then
            RemoveBOM=Mid(s,4)
            Exit Function
        End If
    End If
    RemoveBOM=s
End Function
Sub ParsePragmas()
    Dim p As Long
    Dim startP As Long
    Dim lineText As String
    Dim low As String
    Dim v As String
    p=1
    Do While p<=Len(Src)
        startP=p
        Do While p<=Len(Src)
            If Mid(Src,p,1)=Chr(10) Then Exit Do
            p=p+1
        Loop
        lineText=Mid(Src,startP,p-startP)
        If Left(TrimAll(lineText),1)="#" Then
            low=LowerNoSpace(lineText)
            If InStr(low,"#mode")=1 Then
                If InStr(low,"safe")>0 Then Mode=MODE_SAFE
                If InStr(low,"normal")>0 Then Mode=MODE_NORMAL
                If InStr(low,"wild")>0 Then Mode=MODE_WILD
            ElseIf InStr(low,"#cell")=1 Then
                If InStr(low,"byte")>0 Then CellBits=8
                If InStr(low,"word")>0 Then CellBits=16
                If InStr(low,"dword")>0 Then CellBits=32
            ElseIf InStr(low,"#bounds")=1 Then
                If InStr(low,"off")>0 Then BoundsOn=0
                If InStr(low,"on")>0 Then BoundsOn=1
            ElseIf InStr(low,"#overflow")=1 Then
                If InStr(low,"check")>0 Then OverflowCheck=1
                If InStr(low,"wrap")>0 Then OverflowCheck=0
            ElseIf InStr(low,"#compare")=1 Then
                If InStr(low,"signed")>0 Then DefaultSigned=1
                If InStr(low,"unsigned")>0 Then DefaultSigned=0
            ElseIf InStr(low,"#endian")=1 Then
                If InStr(low,"big")>0 Then DefaultBigEndian=1
                If InStr(low,"little")>0 Then DefaultBigEndian=0
            ElseIf InStr(low,"#memory")=1 Then
                v=GetPragmaValue(low,"tape")
                If v<>"" Then TapeKB=ParseSizeKB(v,TapeKB)
                v=GetPragmaValue(low,"stack")
                If v<>"" Then StackKB=ParseSizeKB(v,StackKB)
                v=GetPragmaValue(low,"data")
                If v<>"" Then DataKB=ParseSizeKB(v,DataKB)
            ElseIf InStr(low,"#poly")=1 Or InStr(low,"#expr-rpn")=1 Then
                ParseArgeMathLine lineText
            End If
        End If
        p=p+1
    Loop
End Sub
Function LowerNoSpace(ByVal s As String) As String
    Dim i As Long
    Dim c As String
    Dim r As String
    r=""
    For i=1 To Len(s)
        c=LCase(Mid(s,i,1))
        If c<>" " And c<>Chr(9) And c<>Chr(13) Then r=r+c
    Next i
    LowerNoSpace=r
End Function
Function GetPragmaValue(ByVal lineText As String, ByVal keyName As String) As String
    Dim hitPos As Long
    Dim p As Long
    Dim r As String
    hitPos=InStr(lineText,keyName+"=")
    If hitPos=0 Then
        GetPragmaValue=""
        Exit Function
    End If
    p=hitPos+Len(keyName)+1
    r=""
    Do While p<=Len(lineText)
        If Mid(lineText,p,1)="," Then Exit Do
        r=r+Mid(lineText,p,1)
        p=p+1
    Loop
    GetPragmaValue=r
End Function
Function ParseSizeKB(ByVal s As String, ByVal defaultKB As Long) As Long
    Dim n As Long
    s=LCase(TrimAll(s))
    n=Val(s)
    If n<=0 Then
        ParseSizeKB=defaultKB
    Else
        ParseSizeKB=n
    End If
End Function
Sub FirstPassDefinitions()
    Dim p As Long
    Dim c As String
    p=1
    Do While p<=Len(Src) And HadError=0
        c=Mid(Src,p,1)
        If c="#" Then
            SkipLine(Src,p)
        ElseIf c="s" Or c="S" Then
            ParseStringDef(Src,p)
        ElseIf c="m" Or c="M" Then
            ParseMacroDef(Src,p)
        Else
            p=p+1
        End If
    Loop
End Sub
Sub ParseProgram(ByRef code As String, ByVal depth As Long)
    Dim p As Long
    If depth>32 Then
        HadError=1
        ErrMsg="HATA: macro expansion derinligi 32'yi asti."
        Exit Sub
    End If
    p=1
    Do While p<=Len(code) And HadError=0
        If IsSpaceChar(Mid(code,p,1)) Then
            p=p+1
        ElseIf Mid(code,p,1)="#" Then
            SkipLine(code,p)
        ElseIf Mid(code,p,1)="s" Or Mid(code,p,1)="S" Then
            ParseStringDef(code,p)
        ElseIf Mid(code,p,1)="m" Or Mid(code,p,1)="M" Then
            ParseMacroDef(code,p)
        Else
            ParseOneInstruction(code,p,depth)
        End If
    Loop
End Sub
Sub ParseOneInstruction(ByRef code As String, ByRef p As Long, ByVal depth As Long)
    Dim c As String
    Dim kind As Long
    Dim addrVal As Long
    Dim addrVal2 As Long
    Dim hasAddr As Long
    Dim amt As Long
    Dim ok As Long
    Dim startP As Long
    Dim c2 As String
    Dim p2 As Long
    Dim amt2 As Long
    Dim ok2 As Long
    startP=p
    c=Mid(code,p,1)
    If c="p" Or c="P" Then
        ParsePrintString(code,p)
        Exit Sub
    End If
    If c="@" Then
        ParseMeta(code,p,depth)
        Exit Sub
    End If
    If c=":" Then
        ParseBranch(code,p)
        Exit Sub
    End If
    If IsCommandChar(c)=0 Then
        SyntaxError("gecersiz komut karakteri: "+c,p)
        Exit Sub
    End If
    p=p+1
    kind=ADDR_T
    addrVal=0
    addrVal2=0
    amt=1
    If c="+" Or c="-" Then
        If p<=Len(code) Then
            If Mid(code,p,1)="k" Or Mid(code,p,1)="K" Then
                p=p+1
                amt=ParseUnsignedLong(code,p,ok)
                If ok=0 Then SyntaxError("k sonrasi sayi bekleniyor",p):Exit Sub
            End If
        End If
    End If
    hasAddr=ParseAddress(code,p,kind,addrVal,addrVal2)
    If HadError Then Exit Sub
    Select Case c
        Case ">"
            If hasAddr Then SyntaxError("> adresleme alamaz",startP):Exit Sub
            AddInstr(OP_RIGHT,amt,ADDR_T,0,0,Mid(code,startP,p-startP))
        Case "<"
            If hasAddr Then SyntaxError("< adresleme alamaz",startP):Exit Sub
            AddInstr(OP_LEFT,amt,ADDR_T,0,0,Mid(code,startP,p-startP))
        Case "+"
            AddInstr(OP_INC,amt,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "-"
            AddInstr(OP_DEC,amt,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "0"
            AddInstr(OP_CLEAR,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
            If p<=Len(code) Then
                If Mid(code,p,1)="+" Or Mid(code,p,1)="-" Then
                    c2=Mid(code,p,1)
                    p2=p+1
                    amt2=1
                    ok2=0
                    If p2<=Len(code) Then
                        If Mid(code,p2,1)="k" Or Mid(code,p2,1)="K" Then
                            p2=p2+1
                            amt2=ParseUnsignedLong(code,p2,ok2)
                            If ok2=0 Then SyntaxError("0(addr)+kN kisminda sayi bekleniyor",p2):Exit Sub
                            If c2="+" Then
                                AddInstr(OP_INC,amt2,kind,addrVal,addrVal2,"+k"+LTrim(Str(amt2))+" inherit "+AddressText(kind,addrVal,addrVal2))
                            Else
                                AddInstr(OP_DEC,amt2,kind,addrVal,addrVal2,"-k"+LTrim(Str(amt2))+" inherit "+AddressText(kind,addrVal,addrVal2))
                            End If
                            p=p2
                        End If
                    End If
                End If
            End If
        Case "."
            AddInstr(OP_PUTC,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case ","
            AddInstr(OP_GETC,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "["
            If hasAddr Then SyntaxError("[ adresleme alamaz; loop aktif hucreye gore calisir",startP):Exit Sub
            AddInstr(OP_LOOP_BEG,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "]"
            If hasAddr Then SyntaxError("] adresleme alamaz",startP):Exit Sub
            AddInstr(OP_LOOP_END,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "$"
            AddInstr(OP_PUSH,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "%"
            AddInstr(OP_POP,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "?"
            AddInstr(OP_EQ,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "!"
            AddInstr(OP_GT,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case ";"
            AddInstr(OP_LT,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "&"
            AddInstr(OP_AND,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "|"
            AddInstr(OP_OR,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "^"
            AddInstr(OP_XOR,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "~"
            AddInstr(OP_NOT,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "{"
            AddInstr(OP_SHL,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "}"
            AddInstr(OP_SHR,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "e","E"
            AddInstr(OP_STATUS,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case Else
            SyntaxError("beklenmeyen komut: "+c,startP)
    End Select
End Sub
Sub ParseStringDef(ByRef code As String, ByRef p As Long)
    Dim ok As Long
    Dim id As Long
    Dim startCell As Long
    Dim txt As String
    p=p+1
    id=ParseUnsignedLong(code,p,ok)
    If ok=0 Then SyntaxError("sN taniminda N bekleniyor",p):Exit Sub
    If p>Len(code) Or Mid(code,p,1)<>"=" Then SyntaxError("sN taniminda '=' bekleniyor",p):Exit Sub
    p=p+1
    startCell=ParseUnsignedLong(code,p,ok)
    If ok=0 Then SyntaxError("sN baslangic hucre no bekleniyor",p):Exit Sub
    If p>Len(code) Or Mid(code,p,1)<>"," Then SyntaxError("sN taniminda ',' bekleniyor",p):Exit Sub
    p=p+1
    txt=ParseBracedText(code,p,ok)
    If ok=0 Then SyntaxError("sN taniminda {metin} bekleniyor",p):Exit Sub
    AddStringDef(id,startCell,txt)
End Sub
Sub ParseMacroDef(ByRef code As String, ByRef p As Long)
    Dim ok As Long
    Dim id As Long
    Dim txt As String
    p=p+1
    id=ParseUnsignedLong(code,p,ok)
    If ok=0 Then SyntaxError("mN taniminda N bekleniyor",p):Exit Sub
    If id<128 Or id>255 Then SyntaxError("mN kullanici macro id 128..255 araliginda olmali",p):Exit Sub
    If p>Len(code) Or Mid(code,p,1)<>"=" Then SyntaxError("mN taniminda '=' bekleniyor",p):Exit Sub
    p=p+1
    txt=ParseBracedText(code,p,ok)
    If ok=0 Then SyntaxError("mN taniminda {UXM kodu} bekleniyor",p):Exit Sub
    AddMacroDef(id,txt)
End Sub
Sub ParsePrintString(ByRef code As String, ByRef p As Long)
    Dim ok As Long
    Dim id As Long
    Dim idx As Long
    Dim startP As Long
    startP=p
    p=p+1
    id=ParseUnsignedLong(code,p,ok)
    If ok=0 Then SyntaxError("pN komutunda N bekleniyor",p):Exit Sub
    idx=FindStringIndex(id)
    If idx=0 Then SyntaxError("tanimlanmamis string: p"+LTrim(Str(id)),startP):Exit Sub
    AddInstr(OP_PRINT_STRING,id,ADDR_T,0,0,Mid(code,startP,p-startP))
End Sub
Sub ParseMeta(ByRef code As String, ByRef p As Long, ByVal depth As Long)
    Dim startP As Long
    Dim ok As Long
    Dim id As Long
    Dim idx As Long
    Dim forceHost As Long
    startP=p
    p=p+1
    forceHost=0
    If p<=Len(code) Then
        If Mid(code,p,1)="!" Then
            forceHost=1
            p=p+1
        End If
    End If
    If p>Len(code) Then SyntaxError("@ sonrasi meta id veya # bekleniyor",p):Exit Sub
    If Mid(code,p,1)="#" Then
        p=p+1
        AddMetaInstr(-1,1,forceHost,"@#")
        Exit Sub
    End If
    id=ParseUnsignedLong(code,p,ok)
    If ok=0 Then SyntaxError("@ sonrasi meta id bekleniyor",p):Exit Sub
    If id<0 Or id>255 Then SyntaxError("meta id 0..255 araliginda olmali",startP):Exit Sub
    idx=FindMacroIndex(id)
    If idx<>0 And forceHost=0 Then
        ParseProgram(MacroText(idx),depth+1)
    Else
        AddMetaInstr(id,0,forceHost,Mid(code,startP,p-startP))
    End If
End Sub
Sub ParseBranch(ByRef code As String, ByRef p As Long)
    Dim startP As Long
    Dim cond As Long
    Dim brDir As Long
    Dim dist As Long
    Dim ok As Long
    Dim c As String
    startP=p
    p=p+1
    If p>Len(code) Then SyntaxError(": sonrasi branch govdesi bekleniyor",p):Exit Sub
    c=Mid(code,p,1)
    If c=":" Then
        cond=BR_ALWAYS
        p=p+1
    ElseIf c="0" Then
        cond=BR_CUR_Z
        p=p+1
    ElseIf c="z" Then
        cond=BR_Z_SET
        p=p+1
    ElseIf c="Z" Then
        cond=BR_Z_CLR
        p=p+1
    ElseIf c="c" Then
        cond=BR_C_SET
        p=p+1
    ElseIf c="C" Then
        cond=BR_C_CLR
        p=p+1
    ElseIf c="o" Then
        cond=BR_O_SET
        p=p+1
    ElseIf c="O" Then
        cond=BR_O_CLR
        p=p+1
    ElseIf c="s" Then
        cond=BR_S_SET
        p=p+1
    ElseIf c="S" Then
        cond=BR_S_CLR
        p=p+1
    ElseIf c="+" Or c="-" Then
        cond=BR_CUR_NZ
    Else
        SyntaxError("gecersiz branch tipi",p)
        Exit Sub
    End If
    If p>Len(code) Then SyntaxError("branch yonu bekleniyor",p):Exit Sub
    c=Mid(code,p,1)
    If c="+" Then
        brDir=1
    ElseIf c="-" Then
        brDir=-1
    Else
        SyntaxError("branch icin + veya - yonu bekleniyor",p)
        Exit Sub
    End If
    p=p+1
    dist=ParseUnsignedLong(code,p,ok)
    If ok=0 Then SyntaxError("branch mesafesi bekleniyor",p):Exit Sub
    If dist<=0 Then SyntaxError("branch mesafesi 1 veya daha buyuk olmali",p):Exit Sub
    AddBranchInstr(cond,brDir,dist,Mid(code,startP,p-startP))
End Sub
Sub AddInstr(ByVal op As Long, ByVal amount As Long, ByVal addrKind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long, ByVal txt As String)
    If InstrCount>=MAX_INSTR Then SyntaxError("instruction limiti doldu",1):Exit Sub
    InstrCount=InstrCount+1
    IOp(InstrCount)=op
    IAmt(InstrCount)=amount
    IAddrKind(InstrCount)=addrKind
    IAddrVal(InstrCount)=addrVal
    IAddrVal2(InstrCount)=addrVal2
    IText(InstrCount)=txt
End Sub
Sub AddMetaInstr(ByVal metaId As Long, ByVal dynamicFlag As Long, ByVal forceHost As Long, ByVal txt As String)
    AddInstr(OP_META,0,ADDR_T,0,0,txt)
    IMetaId(InstrCount)=metaId
    IMetaDyn(InstrCount)=dynamicFlag
    IMetaForce(InstrCount)=forceHost
End Sub
Sub AddBranchInstr(ByVal cond As Long, ByVal brDir As Long, ByVal dist As Long, ByVal txt As String)
    AddInstr(OP_BRANCH,0,ADDR_T,0,0,txt)
    IBrCond(InstrCount)=cond
    IBrDir(InstrCount)=brDir
    IBrDist(InstrCount)=dist
End Sub
Sub AddStringDef(ByVal id As Long, ByVal startCell As Long, ByVal txt As String)
    Dim i As Long
    For i=1 To StrCount
        If StrId(i)=id Then Exit Sub
    Next i
    If StrCount>=MAX_STRINGS Then HadError=1:ErrMsg="HATA: string tablosu doldu.":Exit Sub
    StrCount=StrCount+1
    StrId(StrCount)=id
    StrStart(StrCount)=startCell
    StrText(StrCount)=txt
End Sub
Sub AddMacroDef(ByVal id As Long, ByVal txt As String)
    Dim i As Long
    For i=1 To MacroCount
        If MacroId(i)=id Then
            MacroText(i)=txt
            Exit Sub
        End If
    Next i
    If MacroCount>=MAX_MACROS Then HadError=1:ErrMsg="HATA: macro tablosu doldu.":Exit Sub
    MacroCount=MacroCount+1
    MacroId(MacroCount)=id
    MacroText(MacroCount)=txt
End Sub
Function FindStringIndex(ByVal id As Long) As Long
    Dim i As Long
    For i=1 To StrCount
        If StrId(i)=id Then FindStringIndex=i:Exit Function
    Next i
    FindStringIndex=0
End Function
Function FindMacroIndex(ByVal id As Long) As Long
    Dim i As Long
    For i=1 To MacroCount
        If MacroId(i)=id Then FindMacroIndex=i:Exit Function
    Next i
    FindMacroIndex=0
End Function
Sub SkipLine(ByRef code As String, ByRef p As Long)
    Do While p<=Len(code)
        If Mid(code,p,1)=Chr(10) Then
            p=p+1
            Exit Sub
        End If
        p=p+1
    Loop
End Sub
Function ParseUnsignedLong(ByRef code As String, ByRef p As Long, ByRef ok As Long) As Long
    Dim s As String
    s=""
    ok=0
    Do While p<=Len(code)
        If IsDigitChar(Mid(code,p,1))=0 Then Exit Do
        s=s+Mid(code,p,1)
        p=p+1
    Loop
    If Len(s)=0 Then
        ParseUnsignedLong=0
    Else
        ok=1
        ParseUnsignedLong=Val(s)
    End If
End Function
Function ParseBracedText(ByRef code As String, ByRef p As Long, ByRef ok As Long) As String
    Dim r As String
    Dim c As String
    Dim n As String
    r=""
    ok=0
    If p>Len(code) Then Exit Function
    If Mid(code,p,1)<>"{" Then Exit Function
    p=p+1
    Do While p<=Len(code)
        c=Mid(code,p,1)
        If c="\" Then
            If p+1<=Len(code) Then
                n=Mid(code,p+1,1)
                Select Case n
                    Case "n"
                        r=r+Chr(10)
                    Case "r"
                        r=r+Chr(13)
                    Case "t"
                        r=r+Chr(9)
                    Case "{"
                        r=r+"{"
                    Case "}"
                        r=r+"}"
                    Case "\"
                        r=r+"\"
                    Case Else
                        r=r+n
                End Select
                p=p+2
            Else
                r=r+c
                p=p+1
            End If
        ElseIf c="}" Then
            p=p+1
            ok=1
            ParseBracedText=r
            Exit Function
        Else
            r=r+c
            p=p+1
        End If
    Loop
    ParseBracedText=r
End Function
Function ParseAddress(ByRef code As String, ByRef p As Long, ByRef kind As Long, ByRef addrVal As Long, ByRef addrVal2 As Long) As Long
    Dim startP As Long
    Dim body As String
    Dim bal As Long
    Dim c As String
    If p>Len(code) Then ParseAddress=0:Exit Function
    If Mid(code,p,1)<>"(" Then ParseAddress=0:Exit Function
    startP=p
    bal=0
    Do While p<=Len(code)
        c=Mid(code,p,1)
        If IsSpaceChar(c) Then
            SyntaxError("adresleme ifadesi icinde bosluk yasak",p)
            Exit Function
        End If
        If c="(" Then bal=bal+1
        If c=")" Then
            bal=bal-1
            If bal=0 Then Exit Do
        End If
        p=p+1
    Loop
    If p>Len(code) Or Mid(code,p,1)<>")" Then SyntaxError("adresleme parantezi kapanmadi",startP):Exit Function
    body=Mid(code,startP+1,p-startP-1)
    p=p+1
    If ParseAddressBody(body,kind,addrVal,addrVal2)=0 Then
        SyntaxError("gecersiz adresleme: ("+body+")",startP)
        Exit Function
    End If
    ParseAddress=1
End Function
Function ParseAddressBody(ByVal body As String, ByRef kind As Long, ByRef addrVal As Long, ByRef addrVal2 As Long) As Long
    Dim b As String
    Dim posx As Long
    Dim inner As String
    Dim rest As String
    Dim rel As Long
    Dim off As Long
    b=UCase(TrimAll(body))
    addrVal=0
    addrVal2=0
    If b="T" Then kind=ADDR_T:ParseAddressBody=1:Exit Function
    If b="SP" Then kind=ADDR_SP:ParseAddressBody=1:Exit Function
    If b="P" Then kind=ADDR_P:ParseAddressBody=1:Exit Function
    If b="E" Then kind=ADDR_E:ParseAddressBody=1:Exit Function
    If b="F" Then kind=ADDR_F:ParseAddressBody=1:Exit Function
    If b="*T" Then kind=ADDR_IND_T:ParseAddressBody=1:Exit Function
    If Left(b,2)="T+" Then kind=ADDR_T_REL:addrVal=Val(Mid(b,3)):ParseAddressBody=1:Exit Function
    If Left(b,2)="T-" Then kind=ADDR_T_REL:addrVal=-Val(Mid(b,3)):ParseAddressBody=1:Exit Function
    If Left(b,2)="T:" Then kind=ADDR_T_ABS:addrVal=Val(Mid(b,3)):ParseAddressBody=1:Exit Function
    If Left(b,2)="D:" Then kind=ADDR_D_ABS:addrVal=Val(Mid(b,3)):ParseAddressBody=1:Exit Function
    If Left(b,2)="S:" Then kind=ADDR_S_ABS:addrVal=Val(Mid(b,3)):ParseAddressBody=1:Exit Function
    If Left(b,3)="D@T" Then
        kind=ADDR_D_AT_T_REL
        addrVal=0
        If Len(b)>3 Then
            If Mid(b,4,1)="+" Then addrVal2=Val(Mid(b,5)):ParseAddressBody=1:Exit Function
            If Mid(b,4,1)="-" Then addrVal2=-Val(Mid(b,5)):ParseAddressBody=1:Exit Function
            ParseAddressBody=0:Exit Function
        End If
        addrVal2=0
        ParseAddressBody=1
        Exit Function
    End If
    If Left(b,4)="D@(" Then
        posx=InStr(4,b,")")
        If posx=0 Then ParseAddressBody=0:Exit Function
        inner=Mid(b,4,posx-4)
        rest=Mid(b,posx+1)
        If ParseTapeRelInside(inner,rel)=0 Then ParseAddressBody=0:Exit Function
        off=0
        If rest<>"" Then
            If Left(rest,1)="+" Then
                off=Val(Mid(rest,2))
            ElseIf Left(rest,1)="-" Then
                off=-Val(Mid(rest,2))
            Else
                ParseAddressBody=0
                Exit Function
            End If
        End If
        kind=ADDR_D_AT_TBASE_REL
        addrVal=rel
        addrVal2=off
        ParseAddressBody=1
        Exit Function
    End If
    If Left(b,4)="*(T+" And Right(b,1)=")" Then kind=ADDR_IND_T_REL:addrVal=Val(Mid(b,5,Len(b)-5)):ParseAddressBody=1:Exit Function
    If Left(b,4)="*(T-" And Right(b,1)=")" Then kind=ADDR_IND_T_REL:addrVal=-Val(Mid(b,5,Len(b)-5)):ParseAddressBody=1:Exit Function
    ParseAddressBody=0
End Function
Function ParseTapeRelInside(ByVal s As String, ByRef baseRel As Long) As Long
    s=UCase(TrimAll(s))
    baseRel=0
    If s="T" Then baseRel=0:ParseTapeRelInside=1:Exit Function
    If Left(s,2)="T+" Then baseRel=Val(Mid(s,3)):ParseTapeRelInside=1:Exit Function
    If Left(s,2)="T-" Then baseRel=-Val(Mid(s,3)):ParseTapeRelInside=1:Exit Function
    ParseTapeRelInside=0
End Function
Sub SyntaxError(ByVal msg As String, ByVal p As Long)
    HadError=1
    ErrMsg="SYNTAX ERROR @"+LTrim(Str(p))+": "+msg
End Sub
Function IsDigitChar(ByVal c As String) As Long
    If Len(c)=0 Then
        IsDigitChar=0
    ElseIf c>="0" And c<="9" Then
        IsDigitChar=1
    Else
        IsDigitChar=0
    End If
End Function
Function IsSpaceChar(ByVal c As String) As Long
    If c=" " Or c=Chr(9) Or c=Chr(10) Or c=Chr(13) Then IsSpaceChar=1 Else IsSpaceChar=0
End Function
Function IsCommandChar(ByVal c As String) As Long
    If InStr("><+-0.,[]$%?!;&|^~{}eE",c)>0 Then IsCommandChar=1 Else IsCommandChar=0
End Function
Function TrimAll(ByVal s As String) As String
    TrimAll=LTrim(RTrim(s))
End Function
Function CellSize() As Long
    Select Case CellBits
        Case 8
            CellSize=1
        Case 16
            CellSize=2
        Case 32
            CellSize=4
        Case Else
            CellSize=1
    End Select
End Function
Function MemSizePrefix() As String
    Select Case CellBits
        Case 8
            MemSizePrefix="byte"
        Case 16
            MemSizePrefix="word"
        Case 32
            MemSizePrefix="dword"
        Case Else
            MemSizePrefix="byte"
    End Select
End Function
Function Reg8(ByVal regName As String) As String
    Select Case LCase(regName)
        Case "rax":Reg8="al"
        Case "rbx":Reg8="bl"
        Case "rcx":Reg8="cl"
        Case "rdx":Reg8="dl"
        Case "rsi":Reg8="sil"
        Case "rdi":Reg8="dil"
        Case "r8":Reg8="r8b"
        Case "r9":Reg8="r9b"
        Case "r10":Reg8="r10b"
        Case "r11":Reg8="r11b"
        Case "r12":Reg8="r12b"
        Case "r13":Reg8="r13b"
        Case "r14":Reg8="r14b"
        Case "r15":Reg8="r15b"
        Case Else:Reg8="al"
    End Select
End Function
Function Reg16(ByVal regName As String) As String
    Select Case LCase(regName)
        Case "rax":Reg16="ax"
        Case "rbx":Reg16="bx"
        Case "rcx":Reg16="cx"
        Case "rdx":Reg16="dx"
        Case "rsi":Reg16="si"
        Case "rdi":Reg16="di"
        Case "r8":Reg16="r8w"
        Case "r9":Reg16="r9w"
        Case "r10":Reg16="r10w"
        Case "r11":Reg16="r11w"
        Case "r12":Reg16="r12w"
        Case "r13":Reg16="r13w"
        Case "r14":Reg16="r14w"
        Case "r15":Reg16="r15w"
        Case Else:Reg16="ax"
    End Select
End Function
Function Reg32(ByVal regName As String) As String
    Select Case LCase(regName)
        Case "rax":Reg32="eax"
        Case "rbx":Reg32="ebx"
        Case "rcx":Reg32="ecx"
        Case "rdx":Reg32="edx"
        Case "rsi":Reg32="esi"
        Case "rdi":Reg32="edi"
        Case "r8":Reg32="r8d"
        Case "r9":Reg32="r9d"
        Case "r10":Reg32="r10d"
        Case "r11":Reg32="r11d"
        Case "r12":Reg32="r12d"
        Case "r13":Reg32="r13d"
        Case "r14":Reg32="r14d"
        Case "r15":Reg32="r15d"
        Case Else:Reg32="eax"
    End Select
End Function
Function AddressText(ByVal kind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long) As String
    Select Case kind
        Case ADDR_T
            AddressText="(T)"
        Case ADDR_T_REL
            If addrVal>=0 Then AddressText="(T+"+LTrim(Str(addrVal))+")" Else AddressText="(T"+LTrim(Str(addrVal))+")"
        Case ADDR_T_ABS
            AddressText="(T:"+LTrim(Str(addrVal))+")"
        Case ADDR_D_ABS
            AddressText="(D:"+LTrim(Str(addrVal))+")"
        Case ADDR_D_AT_T_REL
            If addrVal2=0 Then
                AddressText="(D@T)"
            ElseIf addrVal2>0 Then
                AddressText="(D@T+"+LTrim(Str(addrVal2))+")"
            Else
                AddressText="(D@T"+LTrim(Str(addrVal2))+")"
            End If
        Case ADDR_D_AT_TBASE_REL
            If addrVal2>=0 Then
                AddressText="(D@(T"+IIf(addrVal>=0,"+","")+LTrim(Str(addrVal))+")+"+LTrim(Str(addrVal2))+")"
            Else
                AddressText="(D@(T"+IIf(addrVal>=0,"+","")+LTrim(Str(addrVal))+")"+LTrim(Str(addrVal2))+")"
            End If
        Case ADDR_S_ABS
            AddressText="(S:"+LTrim(Str(addrVal))+")"
        Case ADDR_SP
            AddressText="(SP)"
        Case ADDR_P
            AddressText="(P)"
        Case ADDR_E
            AddressText="(E)"
        Case ADDR_F
            AddressText="(F)"
        Case ADDR_IND_T
            AddressText="(*T)"
        Case ADDR_IND_T_REL
            If addrVal>=0 Then AddressText="(*(T+"+LTrim(Str(addrVal))+"))" Else AddressText="(*(T"+LTrim(Str(addrVal))+"))"
        Case Else
            AddressText="(?)"
    End Select
End Function
Function NewAsmId() As Long
    EmitLabelCounter=EmitLabelCounter+1
    NewAsmId=EmitLabelCounter
End Function
Sub ValidateBranches()
    Dim i As Long
    Dim target As Long
    LoopSP=0
    LoopCounter=0
    For i=1 To InstrCount
        If IOp(i)=OP_LOOP_BEG Then
            LoopCounter=LoopCounter+1
            LoopId(i)=LoopCounter
            LoopSP=LoopSP+1
            If LoopSP>MAX_LOOP Then HadError=1:ErrMsg="HATA: loop stack doldu.":Exit Sub
            LoopStack(LoopSP)=i
        ElseIf IOp(i)=OP_LOOP_END Then
            If LoopSP<=0 Then HadError=1:ErrMsg="HATA: fazla ] bulundu.":Exit Sub
            LoopId(i)=LoopId(LoopStack(LoopSP))
            LoopSP=LoopSP-1
        End If
    Next i
    If LoopSP<>0 Then HadError=1:ErrMsg="HATA: kapanmamis [ var.":Exit Sub
    For i=1 To InstrCount
        If IOp(i)=OP_BRANCH Then
            target=i+(IBrDir(i)*IBrDist(i))
            If target<1 Or target>InstrCount Then HadError=1:ErrMsg="HATA: branch hedefi token disina cikiyor: "+IText(i):Exit Sub
            IBrTarget(i)=target
            NeedLabel(target)=1
        End If
    Next i
End Sub
Sub GenerateASM()
    Dim i As Long
    OutFF=FreeFile
    Open OutAsm For Output As #OutFF
    EmitHeader()
    EmitStringInitializers()
    EmitDataInitializers()
    For i=1 To InstrCount
        EmitAsmLabelIfNeeded(i)
        EmitInstr(i)
    Next i
    EmitFooter()
    Close #OutFF
End Sub
Sub EmitLine(ByVal s As String)
    Print #OutFF,s
End Sub
Sub EmitHeader()
    EmitLine("; UX-MINIMA x64 V3.1 generated NASM")
    EmitLine("default rel")
    EmitLine("global uxm_entry")
    EmitLine("global ux_mem")
    EmitLine("global ux_status")
    EmitLine("global ux_flags")
    EmitLine("global ux_ptr")
    EmitLine("global ux_sp")
    EmitLine("global ux_cell_bits")
    EmitLine("global ux_cell_bytes")
    EmitLine("global ux_tape_cells")
    EmitLine("global ux_stack_cells")
    EmitLine("global ux_data_cells")
    EmitLine("global ux_stack_offset")
    EmitLine("global ux_data_offset")
    EmitLine("extern ux_putc")
    EmitLine("extern ux_getc")
    EmitLine("extern ux_print_data_string")
    EmitLine("extern ux_meta_call_ex")
    EmitLine("extern ux_runtime_error")
    EmitLine("%define UXM_TOTAL_BYTES 65536")
    EmitLine("%define TAPE_BYTES "+LTrim(Str(TapeBytes)))
    EmitLine("%define STACK_BYTES "+LTrim(Str(StackBytes)))
    EmitLine("%define DATA_BYTES "+LTrim(Str(DataBytes)))
    EmitLine("%define STACK_OFFSET "+LTrim(Str(StackOffset)))
    EmitLine("%define DATA_OFFSET "+LTrim(Str(DataOffset)))
    EmitLine("%define TAPE_CELLS "+LTrim(Str(TapeCells)))
    EmitLine("%define STACK_CELLS "+LTrim(Str(StackCells)))
    EmitLine("%define DATA_CELLS "+LTrim(Str(DataCells)))
    EmitLine("%define CELL_BITS "+LTrim(Str(CellBits)))
    EmitLine("%define CELL_BYTES "+LTrim(Str(CellSize())))
    EmitLine("%define FLAG_Z 1")
    EmitLine("%define FLAG_C 2")
    EmitLine("%define FLAG_O 4")
    EmitLine("%define FLAG_S 8")
    EmitLine("%define FLAG_SGN 16")
    EmitLine("%define FLAG_END 32")
    EmitLine("%define FLAG_WILD 64")
    EmitLine("%define FLAG_BND 128")
    EmitLine("%define FLAG_TRC 256")
    EmitLine("%define FLAG_FIFO 512")
    EmitLine("%define FLAG_ERR 1024")
    EmitLine("%define FLAG_DIRTY 2048")
    EmitLine("%define FLAG_PCHG 4096")
    EmitLine("section .bss")
    EmitLine("align 16")
    EmitLine("ux_mem: resb UXM_TOTAL_BYTES")
    EmitLine("ux_status: resb 1")
    EmitLine("ux_flags: resw 1")
    EmitLine("ux_ptr: resq 1")
    EmitLine("ux_sp: resq 1")
    EmitLine("ux_cell_bits: resd 1")
    EmitLine("ux_cell_bytes: resd 1")
    EmitLine("ux_tape_cells: resd 1")
    EmitLine("ux_stack_cells: resd 1")
    EmitLine("ux_data_cells: resd 1")
    EmitLine("ux_stack_offset: resd 1")
    EmitLine("ux_data_offset: resd 1")
    EmitLine("section .text")
    EmitLine("uxm_entry:")
    EmitLine("    push rbp")
    EmitLine("    mov rbp, rsp")
    EmitLine("    push rbx")
    EmitLine("    push r12")
    EmitLine("    push r13")
    EmitLine("    push r14")
    EmitLine("    push r15")
    EmitLine("    sub rsp, 40")
    EmitLine("    mov dword [ux_cell_bits], CELL_BITS")
    EmitLine("    mov dword [ux_cell_bytes], CELL_BYTES")
    EmitLine("    mov dword [ux_tape_cells], TAPE_CELLS")
    EmitLine("    mov dword [ux_stack_cells], STACK_CELLS")
    EmitLine("    mov dword [ux_data_cells], DATA_CELLS")
    EmitLine("    mov dword [ux_stack_offset], STACK_OFFSET")
    EmitLine("    mov dword [ux_data_offset], DATA_OFFSET")
    EmitLine("    lea r12, [ux_mem]")
    EmitLine("    xor rbx, rbx")
    EmitLine("    lea r13, [ux_mem + STACK_OFFSET]")
    EmitLine("    xor r14, r14")
    EmitLine("    mov qword [ux_ptr], rbx")
    EmitLine("    mov qword [ux_sp], r14")
    EmitLine("    mov byte [ux_status], 0")
    EmitLine("    mov word [ux_flags], 0")
    If BoundsOn Then EmitLine("    or word [ux_flags], FLAG_BND")
    If DefaultSigned Then EmitLine("    or word [ux_flags], FLAG_SGN")
    If DefaultBigEndian Then EmitLine("    or word [ux_flags], FLAG_END")
    If Mode=MODE_WILD Then EmitLine("    or word [ux_flags], FLAG_WILD")
End Sub
Sub EmitStringInitializers()
    Dim i As Long
    Dim j As Long
    Dim ch As Long
    Dim byteOff As Long
    If StrCount=0 Then Exit Sub
    EmitLine("    ; data string initializers")
    For i=1 To StrCount
        For j=1 To Len(StrText(i))
            ch=Asc(Mid(StrText(i),j,1)) And &HFF
            byteOff=DataOffset+(StrStart(i)+j-1)*CellSize()
            EmitLine("    mov "+MemSizePrefix()+" [ux_mem + "+LTrim(Str(byteOff))+"], "+LTrim(Str(ch)))
        Next j
        byteOff=DataOffset+(StrStart(i)+Len(StrText(i)))*CellSize()
        EmitLine("    mov "+MemSizePrefix()+" [ux_mem + "+LTrim(Str(byteOff))+"], 0")
    Next i
End Sub
Sub EmitAsmLabelIfNeeded(ByVal i As Long)
    If i>=1 And i<=MAX_LABELS Then
        If NeedLabel(i)<>0 Then EmitLine("__ux_ip_"+LTrim(Str(i))+":")
    End If
End Sub
Sub EmitInstr(ByVal i As Long)
    Dim idx As Long
    Select Case IOp(i)
        Case OP_RIGHT
            EmitLine("    ; "+IText(i))
            If IAmt(i)=1 Then EmitLine("    inc rbx") Else EmitLine("    add rbx, "+LTrim(Str(IAmt(i))))
            If BoundsOn Then EmitLine("    cmp rbx, TAPE_CELLS"):EmitLine("    jae __ux_err_ptr")
        Case OP_LEFT
            EmitLine("    ; "+IText(i))
            If IAmt(i)=1 Then EmitLine("    dec rbx") Else EmitLine("    sub rbx, "+LTrim(Str(IAmt(i))))
            If BoundsOn Then EmitLine("    cmp rbx, TAPE_CELLS"):EmitLine("    jae __ux_err_ptr")
        Case OP_INC
            EmitLine("    ; "+IText(i))
            EmitAddrLoad(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitLine("    add rax, "+LTrim(Str(IAmt(i))))
            EmitAddrStore(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitSetFlagsFromRAX()
        Case OP_DEC
            EmitLine("    ; "+IText(i))
            EmitAddrLoad(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitLine("    sub rax, "+LTrim(Str(IAmt(i))))
            EmitAddrStore(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitSetFlagsFromRAX()
        Case OP_CLEAR
            EmitLine("    ; "+IText(i))
            EmitLine("    xor rax, rax")
            EmitAddrStore(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitSetFlagsFromRAX()
        Case OP_PUTC
            EmitLine("    ; "+IText(i))
            EmitAddrLoad(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitLine("    mov ecx, eax")
            EmitLine("    call ux_putc")
        Case OP_GETC
            EmitLine("    ; "+IText(i))
            EmitLine("    call ux_getc")
            EmitAddrStore(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitSetFlagsFromRAX()
        Case OP_PUSH
            EmitLine("    ; "+IText(i))
            EmitLine("    cmp r14, STACK_CELLS")
            EmitLine("    jae __ux_err_stack_over")
            EmitAddrLoad(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            Select Case CellBits
                Case 8
                    EmitLine("    mov byte [r13 + r14], al")
                Case 16
                    EmitLine("    mov word [r13 + r14*2], ax")
                Case 32
                    EmitLine("    mov dword [r13 + r14*4], eax")
            End Select
            EmitLine("    inc r14")
        Case OP_POP
            EmitLine("    ; "+IText(i))
            EmitLine("    cmp r14, 0")
            EmitLine("    je __ux_err_stack_under")
            EmitLine("    dec r14")
            Select Case CellBits
                Case 8
                    EmitLine("    movzx rax, byte [r13 + r14]")
                Case 16
                    EmitLine("    movzx rax, word [r13 + r14*2]")
                Case 32
                    EmitLine("    mov eax, dword [r13 + r14*4]")
            End Select
            EmitAddrStore(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitSetFlagsFromRAX()
        Case OP_EQ,OP_GT,OP_LT,OP_AND,OP_OR,OP_XOR
            EmitLine("    ; "+IText(i))
            EmitLine("    cmp r14, 0")
            EmitLine("    je __ux_err_stack_under")
            EmitLine("    dec r14")
            Select Case CellBits
                Case 8
                    EmitLine("    movzx r15, byte [r13 + r14]")
                Case 16
                    EmitLine("    movzx r15, word [r13 + r14*2]")
                Case 32
                    EmitLine("    mov r15d, dword [r13 + r14*4]")
            End Select
            EmitAddrLoad(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            If IOp(i)=OP_EQ Then
                EmitLine("    cmp r15, rax")
                EmitLine("    sete al")
                EmitLine("    movzx rax, al")
            ElseIf IOp(i)=OP_GT Then
                EmitLine("    cmp r15, rax")
                EmitLine("    seta al")
                EmitLine("    movzx rax, al")
            ElseIf IOp(i)=OP_LT Then
                EmitLine("    cmp r15, rax")
                EmitLine("    setb al")
                EmitLine("    movzx rax, al")
            ElseIf IOp(i)=OP_AND Then
                EmitLine("    and rax, r15")
            ElseIf IOp(i)=OP_OR Then
                EmitLine("    or rax, r15")
            ElseIf IOp(i)=OP_XOR Then
                EmitLine("    xor rax, r15")
            End If
            EmitAddrStore(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitSetFlagsFromRAX()
        Case OP_NOT
            EmitLine("    ; "+IText(i))
            EmitAddrLoad(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitLine("    not rax")
            EmitAddrStore(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitSetFlagsFromRAX()
        Case OP_SHL
            EmitLine("    ; "+IText(i))
            EmitAddrLoad(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitLine("    shl rax, 1")
            EmitAddrStore(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitSetFlagsFromRAX()
        Case OP_SHR
            EmitLine("    ; "+IText(i))
            EmitAddrLoad(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitLine("    shr rax, 1")
            EmitAddrStore(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitSetFlagsFromRAX()
        Case OP_STATUS
            EmitLine("    ; "+IText(i))
            EmitLine("    movzx rax, byte [ux_status]")
            EmitAddrStore(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitSetFlagsFromRAX()
        Case OP_LOOP_BEG
            EmitLoopBegin(i)
        Case OP_LOOP_END
            EmitLoopEnd(i)
        Case OP_META
            EmitLine("    ; "+IText(i))
            EmitMetaCall(IMetaId(i),IMetaDyn(i),IMetaForce(i))
        Case OP_BRANCH
            EmitBranch(i)
        Case OP_PRINT_STRING
            idx=FindStringIndex(IAmt(i))
            EmitLine("    ; "+IText(i))
            EmitLine("    mov ecx, "+LTrim(Str(StrStart(idx))))
            EmitLine("    mov edx, CELL_BITS")
            EmitLine("    call ux_print_data_string")
        Case Else
            EmitLine("    nop")
    End Select
End Sub
Sub EmitAddrLoad(ByVal addrKind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long, ByVal regName As String)
    EmitAddrPtr(addrKind,addrVal,addrVal2,"r11")
    Select Case CellBits
        Case 8
            EmitLine("    movzx "+regName+", byte [r11]")
        Case 16
            EmitLine("    movzx "+regName+", word [r11]")
        Case 32
            If LCase(regName)="rax" Then EmitLine("    mov eax, dword [r11]") Else EmitLine("    mov "+Reg32(regName)+", dword [r11]")
    End Select
End Sub
Sub EmitAddrStore(ByVal addrKind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long, ByVal regName As String)
    EmitAddrPtr(addrKind,addrVal,addrVal2,"r11")
    Select Case CellBits
        Case 8
            EmitLine("    mov byte [r11], "+Reg8(regName))
        Case 16
            EmitLine("    mov word [r11], "+Reg16(regName))
        Case 32
            EmitLine("    mov dword [r11], "+Reg32(regName))
    End Select
End Sub
Sub EmitAddrPtr(ByVal addrKind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long, ByVal outReg As String)
    Select Case addrKind
        Case ADDR_T
            Select Case CellBits
                Case 8
                    EmitLine("    lea "+outReg+", [r12 + rbx]")
                Case 16
                    EmitLine("    lea "+outReg+", [r12 + rbx*2]")
                Case 32
                    EmitLine("    lea "+outReg+", [r12 + rbx*4]")
            End Select
        Case ADDR_T_REL
            If BoundsOn Then
                EmitLine("    mov r10, rbx")
                If addrVal>=0 Then EmitLine("    add r10, "+LTrim(Str(addrVal))) Else EmitLine("    sub r10, "+LTrim(Str(Abs(addrVal))))
                EmitLine("    cmp r10, TAPE_CELLS")
                EmitLine("    jae __ux_err_ptr")
                Select Case CellBits
                    Case 8
                        EmitLine("    lea "+outReg+", [r12 + r10]")
                    Case 16
                        EmitLine("    lea "+outReg+", [r12 + r10*2]")
                    Case 32
                        EmitLine("    lea "+outReg+", [r12 + r10*4]")
                End Select
            Else
                Select Case CellBits
                    Case 8
                        If addrVal>=0 Then EmitLine("    lea "+outReg+", [r12 + rbx + "+LTrim(Str(addrVal))+"]") Else EmitLine("    lea "+outReg+", [r12 + rbx - "+LTrim(Str(Abs(addrVal)))+"]")
                    Case 16
                        If addrVal>=0 Then EmitLine("    lea "+outReg+", [r12 + rbx*2 + "+LTrim(Str(addrVal*2))+"]") Else EmitLine("    lea "+outReg+", [r12 + rbx*2 - "+LTrim(Str(Abs(addrVal*2)))+"]")
                    Case 32
                        If addrVal>=0 Then EmitLine("    lea "+outReg+", [r12 + rbx*4 + "+LTrim(Str(addrVal*4))+"]") Else EmitLine("    lea "+outReg+", [r12 + rbx*4 - "+LTrim(Str(Abs(addrVal*4)))+"]")
                End Select
            End If
        Case ADDR_T_ABS
            If BoundsOn Then
                If addrVal<0 Or addrVal>=TapeCells Then EmitLine("    jmp __ux_err_ptr")
            End If
            EmitLine("    lea "+outReg+", [r12 + "+LTrim(Str(addrVal*CellSize()))+"]")
        Case ADDR_D_ABS
            If BoundsOn Then
                If addrVal<0 Or addrVal>=DataCells Then EmitLine("    jmp __ux_err_data")
            End If
            EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + "+LTrim(Str(addrVal*CellSize()))+"]")
        Case ADDR_D_AT_T_REL
            EmitAddrLoad(ADDR_T,0,0,"rax")
            If addrVal2>=0 Then
                EmitLine("    add rax, "+LTrim(Str(addrVal2)))
            Else
                EmitLine("    sub rax, "+LTrim(Str(Abs(addrVal2))))
            End If
            If BoundsOn Then EmitLine("    cmp rax, DATA_CELLS"):EmitLine("    jae __ux_err_data")
            Select Case CellBits
                Case 8
                    EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax]")
                Case 16
                    EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax*2]")
                Case 32
                    EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax*4]")
            End Select
        Case ADDR_D_AT_TBASE_REL
            EmitAddrLoad(ADDR_T_REL,addrVal,0,"rax")
            If addrVal2>=0 Then
                EmitLine("    add rax, "+LTrim(Str(addrVal2)))
            Else
                EmitLine("    sub rax, "+LTrim(Str(Abs(addrVal2))))
            End If
            If BoundsOn Then EmitLine("    cmp rax, DATA_CELLS"):EmitLine("    jae __ux_err_data")
            Select Case CellBits
                Case 8
                    EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax]")
                Case 16
                    EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax*2]")
                Case 32
                    EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax*4]")
            End Select
        Case ADDR_S_ABS
            If BoundsOn Then
                If addrVal<0 Or addrVal>=StackCells Then EmitLine("    jmp __ux_err_stack_over")
            End If
            EmitLine("    lea "+outReg+", [r13 + "+LTrim(Str(addrVal*CellSize()))+"]")
        Case ADDR_SP
            EmitLine("    cmp r14, 0")
            EmitLine("    je __ux_err_stack_under")
            EmitLine("    mov r10, r14")
            EmitLine("    dec r10")
            Select Case CellBits
                Case 8
                    EmitLine("    lea "+outReg+", [r13 + r10]")
                Case 16
                    EmitLine("    lea "+outReg+", [r13 + r10*2]")
                Case 32
                    EmitLine("    lea "+outReg+", [r13 + r10*4]")
            End Select
        Case ADDR_E
            EmitLine("    lea "+outReg+", [ux_status]")
        Case ADDR_F
            EmitLine("    lea "+outReg+", [ux_flags]")
        Case ADDR_P
            EmitLine("    lea "+outReg+", [ux_ptr]")
        Case ADDR_IND_T
            EmitAddrLoad(ADDR_T,0,0,"rax")
            If BoundsOn Then EmitLine("    cmp rax, TAPE_CELLS"):EmitLine("    jae __ux_err_ptr")
            Select Case CellBits
                Case 8
                    EmitLine("    lea "+outReg+", [r12 + rax]")
                Case 16
                    EmitLine("    lea "+outReg+", [r12 + rax*2]")
                Case 32
                    EmitLine("    lea "+outReg+", [r12 + rax*4]")
            End Select
        Case ADDR_IND_T_REL
            EmitAddrLoad(ADDR_T_REL,addrVal,0,"rax")
            If BoundsOn Then EmitLine("    cmp rax, TAPE_CELLS"):EmitLine("    jae __ux_err_ptr")
            Select Case CellBits
                Case 8
                    EmitLine("    lea "+outReg+", [r12 + rax]")
                Case 16
                    EmitLine("    lea "+outReg+", [r12 + rax*2]")
                Case 32
                    EmitLine("    lea "+outReg+", [r12 + rax*4]")
            End Select
        Case Else
            EmitLine("    lea "+outReg+", [r12 + rbx]")
    End Select
End Sub
Sub EmitSetFlagsFromRAX()
    Dim id As Long
    id=NewAsmId()
    EmitLine("    push rax")
    EmitLine("    mov dx, word [ux_flags]")
    EmitLine("    and dx, 0FFF0h")
    EmitLine("    cmp rax, 0")
    EmitLine("    jne __ux_noz_"+LTrim(Str(id)))
    EmitLine("    or dx, FLAG_Z")
    EmitLine("__ux_noz_"+LTrim(Str(id))+":")
    Select Case CellBits
        Case 8
            EmitLine("    test al, 80h")
        Case 16
            EmitLine("    test ax, 8000h")
        Case 32
            EmitLine("    test eax, 80000000h")
    End Select
    EmitLine("    jz __ux_nos_"+LTrim(Str(id)))
    EmitLine("    or dx, FLAG_S")
    EmitLine("__ux_nos_"+LTrim(Str(id))+":")
    EmitLine("    mov word [ux_flags], dx")
    EmitLine("    pop rax")
End Sub
Sub EmitMetaCall(ByVal metaId As Long, ByVal dynamicFlag As Long, ByVal forceHost As Long)
    EmitLine("    mov qword [ux_ptr], rbx")
    EmitLine("    mov qword [ux_sp], r14")
    If dynamicFlag Then
        EmitAddrLoad(ADDR_T,0,0,"rax")
        EmitLine("    mov ecx, eax")
    Else
        EmitLine("    mov ecx, "+LTrim(Str(metaId)))
    End If
    EmitLine("    lea rdx, [ux_mem]")
    EmitLine("    call ux_meta_call_ex")
    EmitLine("    mov rbx, qword [ux_ptr]")
    EmitLine("    mov r14, qword [ux_sp]")
End Sub
Sub EmitBranch(ByVal i As Long)
    Dim target As Long
    target=IBrTarget(i)
    EmitLine("    ; "+IText(i)+" -> __ux_ip_"+LTrim(Str(target)))
    Select Case IBrCond(i)
        Case BR_CUR_NZ
            EmitAddrLoad(ADDR_T,0,0,"rax")
            EmitLine("    cmp rax, 0")
            EmitLine("    jne __ux_ip_"+LTrim(Str(target)))
        Case BR_CUR_Z
            EmitAddrLoad(ADDR_T,0,0,"rax")
            EmitLine("    cmp rax, 0")
            EmitLine("    je __ux_ip_"+LTrim(Str(target)))
        Case BR_ALWAYS
            EmitLine("    jmp __ux_ip_"+LTrim(Str(target)))
        Case BR_Z_SET
            EmitLine("    test word [ux_flags], FLAG_Z")
            EmitLine("    jnz __ux_ip_"+LTrim(Str(target)))
        Case BR_Z_CLR
            EmitLine("    test word [ux_flags], FLAG_Z")
            EmitLine("    jz __ux_ip_"+LTrim(Str(target)))
        Case BR_C_SET
            EmitLine("    test word [ux_flags], FLAG_C")
            EmitLine("    jnz __ux_ip_"+LTrim(Str(target)))
        Case BR_C_CLR
            EmitLine("    test word [ux_flags], FLAG_C")
            EmitLine("    jz __ux_ip_"+LTrim(Str(target)))
        Case BR_O_SET
            EmitLine("    test word [ux_flags], FLAG_O")
            EmitLine("    jnz __ux_ip_"+LTrim(Str(target)))
        Case BR_O_CLR
            EmitLine("    test word [ux_flags], FLAG_O")
            EmitLine("    jz __ux_ip_"+LTrim(Str(target)))
        Case BR_S_SET
            EmitLine("    test word [ux_flags], FLAG_S")
            EmitLine("    jnz __ux_ip_"+LTrim(Str(target)))
        Case BR_S_CLR
            EmitLine("    test word [ux_flags], FLAG_S")
            EmitLine("    jz __ux_ip_"+LTrim(Str(target)))
    End Select
End Sub
Sub EmitLoopBegin(ByVal i As Long)
    Dim id As Long
    id=LoopId(i)
    EmitLine("__ux_loop_beg_"+LTrim(Str(id))+":")
    EmitAddrLoad(ADDR_T,0,0,"rax")
    EmitLine("    cmp rax, 0")
    EmitLine("    je __ux_loop_end_"+LTrim(Str(id)))
End Sub
Sub EmitLoopEnd(ByVal i As Long)
    Dim id As Long
    id=LoopId(i)
    EmitLine("    jmp __ux_loop_beg_"+LTrim(Str(id)))
    EmitLine("__ux_loop_end_"+LTrim(Str(id))+":")
End Sub
Sub EmitFooter()
    EmitLine("__ux_ok_exit:")
    EmitLine("    add rsp, 40")
    EmitLine("    pop r15")
    EmitLine("    pop r14")
    EmitLine("    pop r13")
    EmitLine("    pop r12")
    EmitLine("    pop rbx")
    EmitLine("    pop rbp")
    EmitLine("    ret")
    EmitLine("__ux_err_ptr:")
    EmitLine("    mov byte [ux_status], 10")
    EmitLine("    mov ecx, 10")
    EmitLine("    call ux_runtime_error")
    EmitLine("    jmp __ux_ok_exit")
    EmitLine("__ux_err_stack_over:")
    EmitLine("    mov byte [ux_status], 11")
    EmitLine("    mov ecx, 11")
    EmitLine("    call ux_runtime_error")
    EmitLine("    jmp __ux_ok_exit")
    EmitLine("__ux_err_stack_under:")
    EmitLine("    mov byte [ux_status], 12")
    EmitLine("    mov ecx, 12")
    EmitLine("    call ux_runtime_error")
    EmitLine("    jmp __ux_ok_exit")
    EmitLine("__ux_err_data:")
    EmitLine("    mov byte [ux_status], 16")
    EmitLine("    mov ecx, 16")
    EmitLine("    call ux_runtime_error")
    EmitLine("    jmp __ux_ok_exit")
End Sub

