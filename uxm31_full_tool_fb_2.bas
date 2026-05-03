# Dosya: `uxm31_compiler_fb_full.bas`

```freebasic
Option Explicit
Const UXM_VERSION As String="3.1-full-native"
Const MAX_SRC As Long=2000000
Const MAX_INSTR As Long=300000
Const MAX_STRINGS As Long=4096
Const MAX_MACROS As Long=256
Const MAX_LOOP As Long=16384
Const MAX_LABELS As Long=300000
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
Const OP_SET As Long=25
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
Const FLAG_Z As Long=&H0001
Const FLAG_C As Long=&H0002
Const FLAG_O As Long=&H0004
Const FLAG_S As Long=&H0008
Const FLAG_SGN As Long=&H0010
Const FLAG_END As Long=&H0020
Const FLAG_WILD As Long=&H0040
Const FLAG_BND As Long=&H0080
Const FLAG_TRC As Long=&H0100
Const FLAG_FIFO As Long=&H0200
Const FLAG_ERR As Long=&H0400
Const FLAG_DIRTY As Long=&H0800
Const FLAG_PCHG As Long=&H1000
Type TInstr
    op As Long
    amount As Long
    addrKind As Long
    addrVal As Long
    text As String
    metaId As Long
    metaDyn As Long
    brCond As Long
    brDir As Long
    brDist As Long
    brTarget As Long
    mate As Long
End Type
Type TStringDef
    id As Long
    startCell As Long
    txt As String
End Type
Type TMacroDef
    id As Long
    txt As String
End Type
Type TOptEvent
    msg As String
End Type
Declare Sub Main()
Declare Sub InitDefaults()
Declare Sub ReadFileToSrc(ByVal fileName As String)
Declare Sub ParsePragmas()
Declare Sub ApplyMemoryModel()
Declare Sub FirstPassDefinitions()
Declare Sub ParseProgram(ByRef code As String, ByVal depth As Long)
Declare Sub ParseOneInstruction(ByRef code As String, ByRef p As Long, ByVal depth As Long)
Declare Sub ParseStringDef(ByRef code As String, ByRef p As Long)
Declare Sub ParseMacroDef(ByRef code As String, ByRef p As Long)
Declare Sub ParsePrintString(ByRef code As String, ByRef p As Long)
Declare Sub ParseMeta(ByRef code As String, ByRef p As Long, ByVal depth As Long)
Declare Sub ParseBranch(ByRef code As String, ByRef p As Long)
Declare Sub AddInstr(ByVal op As Long, ByVal amount As Long, ByVal addrKind As Long, ByVal addrVal As Long, ByVal txt As String)
Declare Sub AddMetaInstr(ByVal metaId As Long, ByVal dynamicFlag As Long, ByVal txt As String)
Declare Sub AddBranchInstr(ByVal cond As Long, ByVal dir As Long, ByVal dist As Long, ByVal txt As String)
Declare Sub AddStringDef(ByVal id As Long, ByVal startCell As Long, ByVal txt As String)
Declare Sub AddMacroDef(ByVal id As Long, ByVal txt As String)
Declare Sub SkipLine(ByRef code As String, ByRef p As Long)
Declare Sub SyntaxError(ByVal msg As String, ByVal p As Long)
Declare Sub ValidateProgram()
Declare Sub OptimizeProgram()
Declare Sub AddOpt(ByVal msg As String)
Declare Sub GenerateASM()
Declare Sub ExportUIR(ByVal fn As String)
Declare Sub ExportOpt(ByVal fn As String)
Declare Sub EmitHeader()
Declare Sub EmitStringInitializers()
Declare Sub EmitInstr(ByVal i As Long)
Declare Sub EmitFooter()
Declare Sub EmitLine(ByVal s As String)
Declare Sub EmitAddrLoad(ByVal addrKind As Long, ByVal addrVal As Long, ByVal regName As String)
Declare Sub EmitAddrStore(ByVal addrKind As Long, ByVal addrVal As Long, ByVal regName As String)
Declare Sub EmitAddrPtr(ByVal addrKind As Long, ByVal addrVal As Long, ByVal outReg As String)
Declare Sub EmitSetFlagsFromRAX()
Declare Sub EmitMetaCall(ByVal metaId As Long, ByVal dynamicFlag As Long)
Declare Sub EmitBranch(ByVal i As Long)
Declare Sub EmitLoopBegin(ByVal i As Long)
Declare Sub EmitLoopEnd(ByVal i As Long)
Declare Sub EmitAsmLabelIfNeeded(ByVal i As Long)
Declare Function ParseUnsignedLong(ByRef code As String, ByRef p As Long, ByRef ok As Long) As Long
Declare Function ParseBracedText(ByRef code As String, ByRef p As Long, ByRef ok As Long) As String
Declare Function ParseAddress(ByRef code As String, ByRef p As Long, ByRef kind As Long, ByRef val As Long) As Long
Declare Function ParseAddressBody(ByVal body As String, ByRef kind As Long, ByRef val As Long) As Long
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
Declare Function AddressText(ByVal kind As Long, ByVal val As Long) As String
Declare Function RemoveBOM(ByVal s As String) As String
Declare Function NewAsmId() As Long
Declare Function JsonEsc(ByVal s As String) As String
Declare Function OpName(ByVal op As Long) As String
Declare Function LowerNoSpace(ByVal s As String) As String
Declare Function GetPragmaValue(ByVal lineText As String, ByVal keyName As String) As String
Declare Function ParseSizeKB(ByVal s As String, ByVal defaultKB As Long) As Long
Dim Shared Src As String
Dim Shared InFile As String
Dim Shared OutAsm As String
Dim Shared OutUIR As String
Dim Shared OutOPT As String
Dim Shared HadError As Long
Dim Shared ErrMsg As String
Dim Shared Instr(1 To MAX_INSTR) As TInstr
Dim Shared InstrCount As Long
Dim Shared NeedLabel(1 To MAX_LABELS) As Long
Dim Shared StrDef(1 To MAX_STRINGS) As TStringDef
Dim Shared StrCount As Long
Dim Shared MacroDef(1 To MAX_MACROS) As TMacroDef
Dim Shared MacroCount As Long
Dim Shared OptEvent(1 To MAX_INSTR) As TOptEvent
Dim Shared OptCount As Long
Dim Shared LoopStack(1 To MAX_LOOP) As Long
Dim Shared LoopSP As Long
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
Main()
End
Sub Main()
    InitDefaults()
    If Command(1)="" Then
        Print "UX-MINIMA x64 V3.1 FULL NATIVE COMPILER"
        Print "Kullanim:"
        Print "  uxm31_compiler_fb_full.exe kaynak.uxm cikis.asm"
        Print "  uxm31_compiler_fb_full.exe kaynak.uxm cikis.asm cikis.uir.json cikis.opt.json"
        End
    End If
    InFile=TrimAll(Command(1))
    If Command(2)<>"" Then OutAsm=TrimAll(Command(2)) Else OutAsm=InFile+".asm"
    If Command(3)<>"" Then OutUIR=TrimAll(Command(3)) Else OutUIR=InFile+".uir.json"
    If Command(4)<>"" Then OutOPT=TrimAll(Command(4)) Else OutOPT=InFile+".opt.json"
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
    ValidateProgram()
    If HadError Then Print ErrMsg:End
    OptimizeProgram()
    If HadError Then Print ErrMsg:End
    ValidateProgram()
    If HadError Then Print ErrMsg:End
    ExportUIR(OutUIR)
    ExportOpt(OutOPT)
    GenerateASM()
    If HadError Then Print ErrMsg:End
    Print "ASM yazildi: ";OutAsm
    Print "UIR yazildi: ";OutUIR
    Print "OPT yazildi: ";OutOPT
    Print "NASM:"
    Print "  nasm -f win64 ";OutAsm;" -o program.obj"
    Print "Link:"
    Print "  fbc uxm31_runtime_fb_full.bas program.obj -x program.exe"
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
        If (Asc(Mid(s,1,1)) And &HFF)=&HEF And (Asc(Mid(s,2,1)) And &HFF)=&HBB And (Asc(Mid(s,3,1)) And &HFF)=&HBF Then Return Mid(s,4)
    End If
    Return s
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
        lineText=TrimAll(Mid(Src,startP,p-startP))
        low=LowerNoSpace(lineText)
        If Left(low,5)="#mode" Then
            If InStr(low,"safe")>0 Then Mode=MODE_SAFE
            If InStr(low,"normal")>0 Then Mode=MODE_NORMAL
            If InStr(low,"wild")>0 Then Mode=MODE_WILD
        ElseIf Left(low,5)="#cell" Then
            If InStr(low,"byte")>0 Then CellBits=8
            If InStr(low,"word")>0 Then CellBits=16
            If InStr(low,"dword")>0 Then CellBits=32
        ElseIf Left(low,7)="#bounds" Then
            If InStr(low,"off")>0 Then BoundsOn=0
            If InStr(low,"on")>0 Then BoundsOn=1
        ElseIf Left(low,9)="#overflow" Then
            If InStr(low,"check")>0 Then OverflowCheck=1
            If InStr(low,"wrap")>0 Then OverflowCheck=0
        ElseIf Left(low,8)="#compare" Then
            If InStr(low,"signed")>0 Then DefaultSigned=1
            If InStr(low,"unsigned")>0 Then DefaultSigned=0
        ElseIf Left(low,7)="#endian" Then
            If InStr(low,"big")>0 Then DefaultBigEndian=1
            If InStr(low,"little")>0 Then DefaultBigEndian=0
        ElseIf Left(low,7)="#memory" Then
            v=GetPragmaValue(low,"tape")
            If v<>"" Then TapeKB=ParseSizeKB(v,TapeKB)
            v=GetPragmaValue(low,"stack")
            If v<>"" Then StackKB=ParseSizeKB(v,StackKB)
            v=GetPragmaValue(low,"data")
            If v<>"" Then DataKB=ParseSizeKB(v,DataKB)
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
    Next
    Return r
End Function
Function GetPragmaValue(ByVal lineText As String, ByVal keyName As String) As String
    Dim pos As Long
    Dim p As Long
    Dim r As String
    pos=InStr(lineText,keyName+"=")
    If pos=0 Then Return ""
    p=pos+Len(keyName)+1
    r=""
    Do While p<=Len(lineText)
        If Mid(lineText,p,1)="," Then Exit Do
        r=r+Mid(lineText,p,1)
        p=p+1
    Loop
    Return r
End Function
Function ParseSizeKB(ByVal s As String, ByVal defaultKB As Long) As Long
    Dim n As Long
    s=LCase(TrimAll(s))
    n=Val(s)
    If n<=0 Then Return defaultKB
    Return n
End Function
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
    TapeCells=TapeBytes\(CellBits\8)
    StackCells=StackBytes\(CellBits\8)
    DataCells=DataBytes\(CellBits\8)
End Sub
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
    If depth>64 Then
        HadError=1
        ErrMsg="HATA: macro expansion derinligi 64'u asti."
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
    Dim val As Long
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
    val=0
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
    hasAddr=ParseAddress(code,p,kind,val)
    If HadError Then Exit Sub
    Select Case c
    Case ">"
        If hasAddr Then SyntaxError("> adresleme alamaz",startP):Exit Sub
        AddInstr(OP_RIGHT,amt,ADDR_T,0,Mid(code,startP,p-startP))
    Case "<"
        If hasAddr Then SyntaxError("< adresleme alamaz",startP):Exit Sub
        AddInstr(OP_LEFT,amt,ADDR_T,0,Mid(code,startP,p-startP))
    Case "+"
        AddInstr(OP_INC,amt,kind,val,Mid(code,startP,p-startP))
    Case "-"
        AddInstr(OP_DEC,amt,kind,val,Mid(code,startP,p-startP))
    Case "0"
        AddInstr(OP_CLEAR,0,kind,val,Mid(code,startP,p-startP))
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
                            AddInstr(OP_INC,amt2,kind,val,"+k"+LTrim(Str(amt2))+" inherit "+AddressText(kind,val))
                        Else
                            AddInstr(OP_DEC,amt2,kind,val,"-k"+LTrim(Str(amt2))+" inherit "+AddressText(kind,val))
                        End If
                        p=p2
                    End If
                End If
            End If
        End If
    Case "."
        AddInstr(OP_PUTC,0,kind,val,Mid(code,startP,p-startP))
    Case ","
        AddInstr(OP_GETC,0,kind,val,Mid(code,startP,p-startP))
    Case "["
        If hasAddr Then SyntaxError("[ adresleme alamaz; loop aktif hucreye gore calisir",startP):Exit Sub
        AddInstr(OP_LOOP_BEG,0,kind,val,Mid(code,startP,p-startP))
    Case "]"
        If hasAddr Then SyntaxError("] adresleme alamaz",startP):Exit Sub
        AddInstr(OP_LOOP_END,0,kind,val,Mid(code,startP,p-startP))
    Case "$"
        AddInstr(OP_PUSH,0,kind,val,Mid(code,startP,p-startP))
    Case "%"
        AddInstr(OP_POP,0,kind,val,Mid(code,startP,p-startP))
    Case "?"
        AddInstr(OP_EQ,0,kind,val,Mid(code,startP,p-startP))
    Case "!"
        AddInstr(OP_GT,0,kind,val,Mid(code,startP,p-startP))
    Case ";"
        AddInstr(OP_LT,0,kind,val,Mid(code,startP,p-startP))
    Case "&"
        AddInstr(OP_AND,0,kind,val,Mid(code,startP,p-startP))
    Case "|"
        AddInstr(OP_OR,0,kind,val,Mid(code,startP,p-startP))
    Case "^"
        AddInstr(OP_XOR,0,kind,val,Mid(code,startP,p-startP))
    Case "~"
        AddInstr(OP_NOT,0,kind,val,Mid(code,startP,p-startP))
    Case "{"
        AddInstr(OP_SHL,0,kind,val,Mid(code,startP,p-startP))
    Case "}"
        AddInstr(OP_SHR,0,kind,val,Mid(code,startP,p-startP))
    Case "e","E"
        AddInstr(OP_STATUS,0,kind,val,Mid(code,startP,p-startP))
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
    AddInstr(OP_PRINT_STRING,id,ADDR_T,0,Mid(code,startP,p-startP))
End Sub
Sub ParseMeta(ByRef code As String, ByRef p As Long, ByVal depth As Long)
    Dim startP As Long
    Dim ok As Long
    Dim id As Long
    Dim idx As Long
    startP=p
    p=p+1
    If p>Len(code) Then SyntaxError("@ sonrasi meta id veya # bekleniyor",p):Exit Sub
    If Mid(code,p,1)="#" Then
        p=p+1
        AddMetaInstr(-1,1,"@#")
        Exit Sub
    End If
    id=ParseUnsignedLong(code,p,ok)
    If ok=0 Then SyntaxError("@ sonrasi meta id bekleniyor",p):Exit Sub
    If id<0 Or id>255 Then SyntaxError("meta id 0..255 araliginda olmali",startP):Exit Sub
    idx=FindMacroIndex(id)
    If idx<>0 Then
        ParseProgram(MacroDef(idx).txt,depth+1)
    Else
        AddMetaInstr(id,0,Mid(code,startP,p-startP))
    End If
End Sub
Sub ParseBranch(ByRef code As String, ByRef p As Long)
    Dim startP As Long
    Dim cond As Long
    Dim dir As Long
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
        dir=1
    ElseIf c="-" Then
        dir=-1
    Else
        SyntaxError("branch icin + veya - yonu bekleniyor",p)
        Exit Sub
    End If
    p=p+1
    dist=ParseUnsignedLong(code,p,ok)
    If ok=0 Then SyntaxError("branch mesafesi bekleniyor",p):Exit Sub
    If dist<=0 Then SyntaxError("branch mesafesi 1 veya daha buyuk olmali",p):Exit Sub
    AddBranchInstr(cond,dir,dist,Mid(code,startP,p-startP))
End Sub
Sub AddInstr(ByVal op As Long, ByVal amount As Long, ByVal addrKind As Long, ByVal addrVal As Long, ByVal txt As String)
    If InstrCount>=MAX_INSTR Then SyntaxError("instruction limiti doldu",1):Exit Sub
    InstrCount=InstrCount+1
    Instr(InstrCount).op=op
    Instr(InstrCount).amount=amount
    Instr(InstrCount).addrKind=addrKind
    Instr(InstrCount).addrVal=addrVal
    Instr(InstrCount).text=txt
End Sub
Sub AddMetaInstr(ByVal metaId As Long, ByVal dynamicFlag As Long, ByVal txt As String)
    AddInstr(OP_META,0,ADDR_T,0,txt)
    Instr(InstrCount).metaId=metaId
    Instr(InstrCount).metaDyn=dynamicFlag
End Sub
Sub AddBranchInstr(ByVal cond As Long, ByVal dir As Long, ByVal dist As Long, ByVal txt As String)
    AddInstr(OP_BRANCH,0,ADDR_T,0,txt)
    Instr(InstrCount).brCond=cond
    Instr(InstrCount).brDir=dir
    Instr(InstrCount).brDist=dist
End Sub
Sub AddStringDef(ByVal id As Long, ByVal startCell As Long, ByVal txt As String)
    Dim i As Long
    For i=1 To StrCount
        If StrDef(i).id=id Then Exit Sub
    Next i
    StrCount=StrCount+1
    If StrCount>MAX_STRINGS Then SyntaxError("string tablosu doldu",1):Exit Sub
    StrDef(StrCount).id=id
    StrDef(StrCount).startCell=startCell
    StrDef(StrCount).txt=txt
End Sub
Sub AddMacroDef(ByVal id As Long, ByVal txt As String)
    Dim i As Long
    For i=1 To MacroCount
        If MacroDef(i).id=id Then
            MacroDef(i).txt=txt
            Exit Sub
        End If
    Next i
    MacroCount=MacroCount+1
    If MacroCount>MAX_MACROS Then SyntaxError("macro tablosu doldu",1):Exit Sub
    MacroDef(MacroCount).id=id
    MacroDef(MacroCount).txt=txt
End Sub
Function FindStringIndex(ByVal id As Long) As Long
    Dim i As Long
    For i=1 To StrCount
        If StrDef(i).id=id Then Return i
    Next i
    Return 0
End Function
Function FindMacroIndex(ByVal id As Long) As Long
    Dim i As Long
    For i=1 To MacroCount
        If MacroDef(i).id=id Then Return i
    Next i
    Return 0
End Function
Sub SkipLine(ByRef code As String, ByRef p As Long)
    Do While p<=Len(code)
        If Mid(code,p,1)=Chr(10) Then p=p+1:Exit Sub
        p=p+1
    Loop
End Sub
Sub SyntaxError(ByVal msg As String, ByVal p As Long)
    HadError=1
    ErrMsg="SYNTAX ERROR @"+LTrim(Str(p))+": "+msg
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
    If Len(s)=0 Then Return 0
    ok=1
    Return Val(s)
End Function
Function ParseBracedText(ByRef code As String, ByRef p As Long, ByRef ok As Long) As String
    Dim r As String
    Dim c As String
    Dim n As String
    r=""
    ok=0
    If p>Len(code) Then Return ""
    If Mid(code,p,1)<>"{" Then Return ""
    p=p+1
    Do While p<=Len(code)
        c=Mid(code,p,1)
        If c="\" And p+1<=Len(code) Then
            n=Mid(code,p+1,1)
            Select Case n
            Case "n":r=r+Chr(10)
            Case "r":r=r+Chr(13)
            Case "t":r=r+Chr(9)
            Case "{":r=r+"{"
            Case "}":r=r+"}"
            Case "\":r=r+"\"
            Case Else:r=r+n
            End Select
            p=p+2
        ElseIf c="}" Then
            p=p+1
            ok=1
            Return r
        Else
            r=r+c
            p=p+1
        End If
    Loop
    Return r
End Function
Function ParseAddress(ByRef code As String, ByRef p As Long, ByRef kind As Long, ByRef val As Long) As Long
    Dim startP As Long
    Dim body As String
    Dim bal As Long
    Dim c As String
    If p>Len(code) Then Return 0
    If Mid(code,p,1)<>"(" Then Return 0
    startP=p
    bal=0
    Do While p<=Len(code)
        c=Mid(code,p,1)
        If IsSpaceChar(c) Then
            SyntaxError("adresleme ifadesi icinde bosluk yasak",p)
            Return 0
        End If
        If c="(" Then bal=bal+1
        If c=")" Then
            bal=bal-1
            If bal=0 Then Exit Do
        End If
        p=p+1
    Loop
    If p>Len(code) Or Mid(code,p,1)<>")" Then SyntaxError("adresleme parantezi kapanmadi",startP):Return 0
    body=Mid(code,startP+1,p-startP-1)
    p=p+1
    If ParseAddressBody(body,kind,val)=0 Then
        SyntaxError("gecersiz adresleme: ("+body+")",startP)
        Return 0
    End If
    Return 1
End Function
Function ParseAddressBody(ByVal body As String, ByRef kind As Long, ByRef val As Long) As Long
    Dim b As String
    b=UCase(TrimAll(body))
    val=0
    If b="T" Then kind=ADDR_T:Return 1
    If b="SP" Then kind=ADDR_SP:Return 1
    If b="P" Then kind=ADDR_P:Return 1
    If b="E" Then kind=ADDR_E:Return 1
    If b="F" Then kind=ADDR_F:Return 1
    If b="*T" Then kind=ADDR_IND_T:Return 1
    If Left(b,2)="T+" Then kind=ADDR_T_REL:val=Val(Mid(b,3)):Return 1
    If Left(b,2)="T-" Then kind=ADDR_T_REL:val=-Val(Mid(b,3)):Return 1
    If Left(b,2)="T:" Then kind=ADDR_T_ABS:val=Val(Mid(b,3)):Return 1
    If Left(b,2)="D:" Then kind=ADDR_D_ABS:val=Val(Mid(b,3)):Return 1
    If Left(b,2)="S:" Then kind=ADDR_S_ABS:val=Val(Mid(b,3)):Return 1
    If Left(b,4)="*(T+" And Right(b,1)=")" Then kind=ADDR_IND_T_REL:val=Val(Mid(b,5,Len(b)-5)):Return 1
    If Left(b,4)="*(T-" And Right(b,1)=")" Then kind=ADDR_IND_T_REL:val=-Val(Mid(b,5,Len(b)-5)):Return 1
    Return 0
End Function
Function IsDigitChar(ByVal c As String) As Long
    If Len(c)=0 Then Return 0
    If c>="0" And c<="9" Then Return 1
    Return 0
End Function
Function IsSpaceChar(ByVal c As String) As Long
    If c=" " Or c=Chr(9) Or c=Chr(10) Or c=Chr(13) Then Return 1
    Return 0
End Function
Function IsCommandChar(ByVal c As String) As Long
    If InStr("><+-0.,[]$%?!;&|^~{}eE",c)>0 Then Return 1
    Return 0
End Function
Function TrimAll(ByVal s As String) As String
    Return LTrim(RTrim(s))
End Function
Function CellSize() As Long
    If CellBits=8 Then Return 1
    If CellBits=16 Then Return 2
    If CellBits=32 Then Return 4
    Return 1
End Function
Function MemSizePrefix() As String
    If CellBits=8 Then Return "byte"
    If CellBits=16 Then Return "word"
    If CellBits=32 Then Return "dword"
    Return "byte"
End Function
Function Reg8(ByVal regName As String) As String
    Select Case LCase(regName)
    Case "rax":Return "al"
    Case "rbx":Return "bl"
    Case "rcx":Return "cl"
    Case "rdx":Return "dl"
    Case "rsi":Return "sil"
    Case "rdi":Return "dil"
    Case "r8":Return "r8b"
    Case "r9":Return "r9b"
    Case "r10":Return "r10b"
    Case "r11":Return "r11b"
    Case "r12":Return "r12b"
    Case "r13":Return "r13b"
    Case "r14":Return "r14b"
    Case "r15":Return "r15b"
    End Select
    Return "al"
End Function
Function Reg16(ByVal regName As String) As String
    Select Case LCase(regName)
    Case "rax":Return "ax"
    Case "rbx":Return "bx"
    Case "rcx":Return "cx"
    Case "rdx":Return "dx"
    Case "rsi":Return "si"
    Case "rdi":Return "di"
    Case "r8":Return "r8w"
    Case "r9":Return "r9w"
    Case "r10":Return "r10w"
    Case "r11":Return "r11w"
    Case "r12":Return "r12w"
    Case "r13":Return "r13w"
    Case "r14":Return "r14w"
    Case "r15":Return "r15w"
    End Select
    Return "ax"
End Function
Function Reg32(ByVal regName As String) As String
    Select Case LCase(regName)
    Case "rax":Return "eax"
    Case "rbx":Return "ebx"
    Case "rcx":Return "ecx"
    Case "rdx":Return "edx"
    Case "rsi":Return "esi"
    Case "rdi":Return "edi"
    Case "r8":Return "r8d"
    Case "r9":Return "r9d"
    Case "r10":Return "r10d"
    Case "r11":Return "r11d"
    Case "r12":Return "r12d"
    Case "r13":Return "r13d"
    Case "r14":Return "r14d"
    Case "r15":Return "r15d"
    End Select
    Return "eax"
End Function
Function AddressText(ByVal kind As Long, ByVal val As Long) As String
    Select Case kind
    Case ADDR_T:Return "(T)"
    Case ADDR_T_REL:If val>=0 Then Return "(T+"+LTrim(Str(val))+")" Else Return "(T"+LTrim(Str(val))+")"
    Case ADDR_T_ABS:Return "(T:"+LTrim(Str(val))+")"
    Case ADDR_D_ABS:Return "(D:"+LTrim(Str(val))+")"
    Case ADDR_S_ABS:Return "(S:"+LTrim(Str(val))+")"
    Case ADDR_SP:Return "(SP)"
    Case ADDR_P:Return "(P)"
    Case ADDR_E:Return "(E)"
    Case ADDR_F:Return "(F)"
    Case ADDR_IND_T:Return "(*T)"
    Case ADDR_IND_T_REL:If val>=0 Then Return "(*(T+"+LTrim(Str(val))+"))" Else Return "(*(T"+LTrim(Str(val))+"))"
    End Select
    Return "(?)"
End Function
Function NewAsmId() As Long
    EmitLabelCounter=EmitLabelCounter+1
    Return EmitLabelCounter
End Function
Function JsonEsc(ByVal s As String) As String
    Dim i As Long
    Dim c As String
    Dim r As String
    r=""
    For i=1 To Len(s)
        c=Mid(s,i,1)
        If c=Chr(34) Then
            r=r+"\"+Chr(34)
        ElseIf c="\" Then
            r=r+"\\"
        ElseIf c=Chr(10) Then
            r=r+"\n"
        ElseIf c=Chr(13) Then
            r=r+"\r"
        Else
            r=r+c
        End If
    Next
    Return r
End Function
Function OpName(ByVal op As Long) As String
    Select Case op
    Case OP_RIGHT:Return "RIGHT"
    Case OP_LEFT:Return "LEFT"
    Case OP_INC:Return "INC"
    Case OP_DEC:Return "DEC"
    Case OP_CLEAR:Return "CLEAR"
    Case OP_PUTC:Return "PUTC"
    Case OP_GETC:Return "GETC"
    Case OP_LOOP_BEG:Return "LOOP_BEGIN"
    Case OP_LOOP_END:Return "LOOP_END"
    Case OP_PUSH:Return "PUSH"
    Case OP_POP:Return "POP"
    Case OP_EQ:Return "EQ"
    Case OP_GT:Return "GT"
    Case OP_LT:Return "LT"
    Case OP_AND:Return "AND"
    Case OP_OR:Return "OR"
    Case OP_XOR:Return "XOR"
    Case OP_NOT:Return "NOT"
    Case OP_SHL:Return "SHL"
    Case OP_SHR:Return "SHR"
    Case OP_STATUS:Return "STATUS"
    Case OP_META:Return "META"
    Case OP_BRANCH:Return "BRANCH"
    Case OP_PRINT_STRING:Return "PRINT_STRING"
    Case OP_SET:Return "SET"
    End Select
    Return "NOP"
End Function
Sub ValidateProgram()
    Dim i As Long
    Dim target As Long
    LoopSP=0
    LoopCounter=0
    For i=1 To InstrCount
        If Instr(i).op=OP_LOOP_BEG Then
            LoopCounter=LoopCounter+1
            LoopSP=LoopSP+1
            If LoopSP>MAX_LOOP Then HadError=1:ErrMsg="HATA: loop stack doldu.":Exit Sub
            LoopStack(LoopSP)=i
        ElseIf Instr(i).op=OP_LOOP_END Then
            If LoopSP<=0 Then HadError=1:ErrMsg="HATA: fazla ] bulundu.":Exit Sub
            Instr(i).mate=LoopStack(LoopSP)
            Instr(LoopStack(LoopSP)).mate=i
            LoopSP=LoopSP-1
        End If
    Next
    If LoopSP<>0 Then HadError=1:ErrMsg="HATA: kapanmamis [ var.":Exit Sub
    For i=1 To InstrCount
        If Instr(i).op=OP_BRANCH Then
            target=i+(Instr(i).brDir*Instr(i).brDist)
            If target<1 Or target>InstrCount Then HadError=1:ErrMsg="HATA: branch hedefi token disina cikiyor: "+Instr(i).text:Exit Sub
            Instr(i).brTarget=target
            NeedLabel(target)=1
        End If
    Next
End Sub
Sub AddOpt(ByVal msg As String)
    OptCount=OptCount+1
    If OptCount<=MAX_INSTR Then OptEvent(OptCount).msg=msg
End Sub
Sub OptimizeProgram()
    Dim newI(1 To MAX_INSTR) As TInstr
    Dim n As Long
    Dim i As Long
    Dim a As TInstr
    Dim b As TInstr
    Dim delta As LongInt
    i=1
    n=0
    Do While i<=InstrCount
        a=Instr(i)
        If i<InstrCount Then
            b=Instr(i+1)
            If a.op=OP_CLEAR And (b.op=OP_INC Or b.op=OP_DEC) And a.addrKind=b.addrKind And a.addrVal=b.addrVal Then
                n=n+1
                newI(n)=b
                newI(n).op=OP_SET
                If b.op=OP_DEC Then newI(n).amount=((2^(CellBits))-b.amount) Else newI(n).amount=b.amount
                newI(n).text="optimized_set_from_clear_arith"
                AddOpt("CLEAR + INC/DEC -> SET @"+Str(i))
                i=i+2
                Continue Do
            End If
            If (a.op=OP_INC Or a.op=OP_DEC) And (b.op=OP_INC Or b.op=OP_DEC) And a.addrKind=b.addrKind And a.addrVal=b.addrVal Then
                delta=0
                If a.op=OP_INC Then delta=delta+a.amount Else delta=delta-a.amount
                If b.op=OP_INC Then delta=delta+b.amount Else delta=delta-b.amount
                If delta=0 Then
                    AddOpt("INC/DEC cancel @"+Str(i))
                    i=i+2
                    Continue Do
                End If
                n=n+1
                newI(n)=a
                If delta>0 Then newI(n).op=OP_INC:newI(n).amount=delta Else newI(n).op=OP_DEC:newI(n).amount=Abs(delta)
                newI(n).text="optimized_arith_merge"
                AddOpt("INC/DEC merge @"+Str(i))
                i=i+2
                Continue Do
            End If
            If a.op=OP_RIGHT And b.op=OP_LEFT Then
                delta=a.amount-b.amount
                If delta=0 Then
                    AddOpt("pointer move cancel @"+Str(i))
                    i=i+2
                    Continue Do
                End If
                n=n+1
                newI(n)=a
                If delta>0 Then newI(n).op=OP_RIGHT:newI(n).amount=delta Else newI(n).op=OP_LEFT:newI(n).amount=Abs(delta)
                newI(n).text="optimized_pointer_merge"
                AddOpt("pointer move merge @"+Str(i))
                i=i+2
                Continue Do
            End If
            If a.op=OP_LEFT And b.op=OP_RIGHT Then
                delta=b.amount-a.amount
                If delta=0 Then
                    AddOpt("pointer move cancel @"+Str(i))
                    i=i+2
                    Continue Do
                End If
                n=n+1
                newI(n)=a
                If delta>0 Then newI(n).op=OP_RIGHT:newI(n).amount=delta Else newI(n).op=OP_LEFT:newI(n).amount=Abs(delta)
                newI(n).text="optimized_pointer_merge"
                AddOpt("pointer move merge @"+Str(i))
                i=i+2
                Continue Do
            End If
        End If
        n=n+1
        newI(n)=a
        i=i+1
    Loop
    InstrCount=n
    For i=1 To InstrCount
        Instr(i)=newI(i)
    Next
End Sub
Sub ExportUIR(ByVal fn As String)
    Dim ff As Integer
    Dim i As Long
    ff=FreeFile
    Open fn For Output As #ff
    Print #ff,"{"
    Print #ff,"""version"":"""+UXM_VERSION+""","
    Print #ff,"""cell_bits"":"+Str(CellBits)+","
    Print #ff,"""memory"":{""tape_kb"":"+Str(TapeKB)+",""stack_kb"":"+Str(StackKB)+",""data_kb"":"+Str(DataKB)+",""tape_cells"":"+Str(TapeCells)+",""stack_cells"":"+Str(StackCells)+",""data_cells"":"+Str(DataCells)+"},"
    Print #ff,"""instructions"":["
    For i=1 To InstrCount
        Print #ff,"{""ip"":"+Str(i)+",""op"":"""+OpName(Instr(i).op)+""",""amount"":"+Str(Instr(i).amount)+",""addr_kind"":"+Str(Instr(i).addrKind)+",""addr_val"":"+Str(Instr(i).addrVal)+",""addr"":"""+JsonEsc(AddressText(Instr(i).addrKind,Instr(i).addrVal))+""",""meta_id"":"+Str(Instr(i).metaId)+",""meta_dynamic"":"+Str(Instr(i).metaDyn)+",""branch_target"":"+Str(Instr(i).brTarget)+",""mate"":"+Str(Instr(i).mate)+",""text"":"""+JsonEsc(Instr(i).text)+"""}";
        If i<InstrCount Then Print #ff,",";
        Print #ff,""
    Next
    Print #ff,"]"
    Print #ff,"}"
    Close #ff
End Sub
Sub ExportOpt(ByVal fn As String)
    Dim ff As Integer
    Dim i As Long
    ff=FreeFile
    Open fn For Output As #ff
    Print #ff,"{""version"":"""+UXM_VERSION+""",""optimizer_events"":["
    For i=1 To OptCount
        Print #ff,"{""msg"":"""+JsonEsc(OptEvent(i).msg)+"""}";
        If i<OptCount Then Print #ff,",";
        Print #ff,""
    Next
    Print #ff,"]}"
    Close #ff
End Sub
Sub GenerateASM()
    Dim i As Long
    OutFF=FreeFile
    Open OutAsm For Output As #OutFF
    EmitHeader()
    EmitStringInitializers()
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
    EmitLine("; UX-MINIMA x64 V3.1 FULL generated NASM")
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
        For j=1 To Len(StrDef(i).txt)
            ch=Asc(Mid(StrDef(i).txt,j,1)) And &HFF
            byteOff=DataOffset+(StrDef(i).startCell+j-1)*CellSize()
            EmitLine("    mov "+MemSizePrefix()+" [ux_mem + "+LTrim(Str(byteOff))+"], "+LTrim(Str(ch)))
        Next j
        byteOff=DataOffset+(StrDef(i).startCell+Len(StrDef(i).txt))*CellSize()
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
    Select Case Instr(i).op
    Case OP_RIGHT
        EmitLine("    ; "+Instr(i).text)
        If Instr(i).amount=1 Then EmitLine("    inc rbx") Else EmitLine("    add rbx, "+LTrim(Str(Instr(i).amount)))
        If BoundsOn Then EmitLine("    cmp rbx, TAPE_CELLS"):EmitLine("    jae __ux_err_ptr")
    Case OP_LEFT
        EmitLine("    ; "+Instr(i).text)
        If Instr(i).amount=1 Then EmitLine("    dec rbx") Else EmitLine("    sub rbx, "+LTrim(Str(Instr(i).amount)))
        If BoundsOn Then EmitLine("    cmp rbx, TAPE_CELLS"):EmitLine("    jae __ux_err_ptr")
    Case OP_INC
        EmitLine("    ; "+Instr(i).text)
        EmitAddrLoad(Instr(i).addrKind,Instr(i).addrVal,"rax")
        EmitLine("    add rax, "+LTrim(Str(Instr(i).amount)))
        EmitAddrStore(Instr(i).addrKind,Instr(i).addrVal,"rax")
        EmitSetFlagsFromRAX()
    Case OP_DEC
        EmitLine("    ; "+Instr(i).text)
        EmitAddrLoad(Instr(i).addrKind,Instr(i).addrVal,"rax")
        EmitLine("    sub rax, "+LTrim(Str(Instr(i).amount)))
        EmitAddrStore(Instr(i).addrKind,Instr(i).addrVal,"rax")
        EmitSetFlagsFromRAX()
    Case OP_SET
        EmitLine("    ; "+Instr(i).text)
        EmitLine("    mov rax, "+LTrim(Str(Instr(i).amount)))
        EmitAddrStore(Instr(i).addrKind,Instr(i).addrVal,"rax")
        EmitSetFlagsFromRAX()
    Case OP_CLEAR
        EmitLine("    ; "+Instr(i).text)
        EmitLine("    xor rax, rax")
        EmitAddrStore(Instr(i).addrKind,Instr(i).addrVal,"rax")
        EmitSetFlagsFromRAX()
    Case OP_PUTC
        EmitLine("    ; "+Instr(i).text)
        EmitAddrLoad(Instr(i).addrKind,Instr(i).addrVal,"rax")
        EmitLine("    mov ecx, eax")
        EmitLine("    call ux_putc")
    Case OP_GETC
        EmitLine("    ; "+Instr(i).text)
        EmitLine("    call ux_getc")
        EmitAddrStore(Instr(i).addrKind,Instr(i).addrVal,"rax")
        EmitSetFlagsFromRAX()
    Case OP_PUSH
        EmitLine("    ; "+Instr(i).text)
        EmitLine("    cmp r14, STACK_CELLS")
        EmitLine("    jae __ux_err_stack_over")
        EmitAddrLoad(Instr(i).addrKind,Instr(i).addrVal,"rax")
        Select Case CellBits
        Case 8:EmitLine("    mov byte [r13 + r14], al")
        Case 16:EmitLine("    mov word [r13 + r14*2], ax")
        Case 32:EmitLine("    mov dword [r13 + r14*4], eax")
        End Select
        EmitLine("    inc r14")
    Case OP_POP
        EmitLine("    ; "+Instr(i).text)
        EmitLine("    cmp r14, 0")
        EmitLine("    je __ux_err_stack_under")
        EmitLine("    dec r14")
        Select Case CellBits
        Case 8:EmitLine("    movzx rax, byte [r13 + r14]")
        Case 16:EmitLine("    movzx rax, word [r13 + r14*2]")
        Case 32:EmitLine("    mov eax, dword [r13 + r14*4]")
        End Select
        EmitAddrStore(Instr(i).addrKind,Instr(i).addrVal,"rax")
        EmitSetFlagsFromRAX()
    Case OP_EQ,OP_GT,OP_LT,OP_AND,OP_OR,OP_XOR
        EmitLine("    ; "+Instr(i).text)
        EmitLine("    cmp r14, 0")
        EmitLine("    je __ux_err_stack_under")
        EmitLine("    dec r14")
        Select Case CellBits
        Case 8:EmitLine("    movzx r15, byte [r13 + r14]")
        Case 16:EmitLine("    movzx r15, word [r13 + r14*2]")
        Case 32:EmitLine("    mov r15d, dword [r13 + r14*4]")
        End Select
        EmitAddrLoad(Instr(i).addrKind,Instr(i).addrVal,"rax")
        If Instr(i).op=OP_EQ Then
            EmitLine("    cmp r15, rax")
            EmitLine("    sete al")
            EmitLine("    movzx rax, al")
        ElseIf Instr(i).op=OP_GT Then
            EmitLine("    cmp r15, rax")
            EmitLine("    seta al")
            EmitLine("    movzx rax, al")
        ElseIf Instr(i).op=OP_LT Then
            EmitLine("    cmp r15, rax")
            EmitLine("    setb al")
            EmitLine("    movzx rax, al")
        ElseIf Instr(i).op=OP_AND Then
            EmitLine("    and rax, r15")
        ElseIf Instr(i).op=OP_OR Then
            EmitLine("    or rax, r15")
        ElseIf Instr(i).op=OP_XOR Then
            EmitLine("    xor rax, r15")
        End If
        EmitAddrStore(Instr(i).addrKind,Instr(i).addrVal,"rax")
        EmitSetFlagsFromRAX()
    Case OP_NOT
        EmitLine("    ; "+Instr(i).text)
        EmitAddrLoad(Instr(i).addrKind,Instr(i).addrVal,"rax")
        EmitLine("    not rax")
        EmitAddrStore(Instr(i).addrKind,Instr(i).addrVal,"rax")
        EmitSetFlagsFromRAX()
    Case OP_SHL
        EmitLine("    ; "+Instr(i).text)
        EmitAddrLoad(Instr(i).addrKind,Instr(i).addrVal,"rax")
        EmitLine("    shl rax, 1")
        EmitAddrStore(Instr(i).addrKind,Instr(i).addrVal,"rax")
        EmitSetFlagsFromRAX()
    Case OP_SHR
        EmitLine("    ; "+Instr(i).text)
        EmitAddrLoad(Instr(i).addrKind,Instr(i).addrVal,"rax")
        EmitLine("    shr rax, 1")
        EmitAddrStore(Instr(i).addrKind,Instr(i).addrVal,"rax")
        EmitSetFlagsFromRAX()
    Case OP_STATUS
        EmitLine("    ; "+Instr(i).text)
        EmitLine("    movzx rax, byte [ux_status]")
        EmitAddrStore(Instr(i).addrKind,Instr(i).addrVal,"rax")
        EmitSetFlagsFromRAX()
    Case OP_LOOP_BEG
        EmitLoopBegin(i)
    Case OP_LOOP_END
        EmitLoopEnd(i)
    Case OP_META
        EmitLine("    ; "+Instr(i).text)
        EmitMetaCall(Instr(i).metaId,Instr(i).metaDyn)
    Case OP_BRANCH
        EmitBranch(i)
    Case OP_PRINT_STRING
        idx=FindStringIndex(Instr(i).amount)
        EmitLine("    ; "+Instr(i).text)
        EmitLine("    mov ecx, "+LTrim(Str(StrDef(idx).startCell)))
        EmitLine("    mov edx, CELL_BITS")
        EmitLine("    call ux_print_data_string")
    End Select
End Sub
Sub EmitAddrLoad(ByVal addrKind As Long, ByVal addrVal As Long, ByVal regName As String)
    EmitAddrPtr(addrKind,addrVal,"r11")
    Select Case CellBits
    Case 8:EmitLine("    movzx "+regName+", byte [r11]")
    Case 16:EmitLine("    movzx "+regName+", word [r11]")
    Case 32:If LCase(regName)="rax" Then EmitLine("    mov eax, dword [r11]") Else EmitLine("    mov "+Reg32(regName)+", dword [r11]")
    End Select
End Sub
Sub EmitAddrStore(ByVal addrKind As Long, ByVal addrVal As Long, ByVal regName As String)
    EmitAddrPtr(addrKind,addrVal,"r11")
    Select Case CellBits
    Case 8:EmitLine("    mov byte [r11], "+Reg8(regName))
    Case 16:EmitLine("    mov word [r11], "+Reg16(regName))
    Case 32:EmitLine("    mov dword [r11], "+Reg32(regName))
    End Select
End Sub
Sub EmitAddrPtr(ByVal addrKind As Long, ByVal addrVal As Long, ByVal outReg As String)
    Select Case addrKind
    Case ADDR_T
        Select Case CellBits
        Case 8:EmitLine("    lea "+outReg+", [r12 + rbx]")
        Case 16:EmitLine("    lea "+outReg+", [r12 + rbx*2]")
        Case 32:EmitLine("    lea "+outReg+", [r12 + rbx*4]")
        End Select
    Case ADDR_T_REL
        EmitLine("    mov r10, rbx")
        If addrVal>=0 Then EmitLine("    add r10, "+LTrim(Str(addrVal))) Else EmitLine("    sub r10, "+LTrim(Str(Abs(addrVal))))
        If BoundsOn Then EmitLine("    cmp r10, TAPE_CELLS"):EmitLine("    jae __ux_err_ptr")
        Select Case CellBits
        Case 8:EmitLine("    lea "+outReg+", [r12 + r10]")
        Case 16:EmitLine("    lea "+outReg+", [r12 + r10*2]")
        Case 32:EmitLine("    lea "+outReg+", [r12 + r10*4]")
        End Select
    Case ADDR_T_ABS
        If BoundsOn Then If addrVal<0 Or addrVal>=TapeCells Then EmitLine("    jmp __ux_err_ptr")
        EmitLine("    lea "+outReg+", [r12 + "+LTrim(Str(addrVal*CellSize()))+"]")
    Case ADDR_D_ABS
        If BoundsOn Then If addrVal<0 Or addrVal>=DataCells Then EmitLine("    jmp __ux_err_data")
        EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + "+LTrim(Str(addrVal*CellSize()))+"]")
    Case ADDR_S_ABS
        If BoundsOn Then If addrVal<0 Or addrVal>=StackCells Then EmitLine("    jmp __ux_err_stack_over")
        EmitLine("    lea "+outReg+", [r13 + "+LTrim(Str(addrVal*CellSize()))+"]")
    Case ADDR_SP
        EmitLine("    cmp r14, 0")
        EmitLine("    je __ux_err_stack_under")
        EmitLine("    mov r10, r14")
        EmitLine("    dec r10")
        Select Case CellBits
        Case 8:EmitLine("    lea "+outReg+", [r13 + r10]")
        Case 16:EmitLine("    lea "+outReg+", [r13 + r10*2]")
        Case 32:EmitLine("    lea "+outReg+", [r13 + r10*4]")
        End Select
    Case ADDR_E
        EmitLine("    lea "+outReg+", [ux_status]")
    Case ADDR_F
        EmitLine("    lea "+outReg+", [ux_flags]")
    Case ADDR_P
        EmitLine("    lea "+outReg+", [ux_ptr]")
    Case ADDR_IND_T
        EmitAddrLoad(ADDR_T,0,"rax")
        If BoundsOn Then EmitLine("    cmp rax, TAPE_CELLS"):EmitLine("    jae __ux_err_ptr")
        Select Case CellBits
        Case 8:EmitLine("    lea "+outReg+", [r12 + rax]")
        Case 16:EmitLine("    lea "+outReg+", [r12 + rax*2]")
        Case 32:EmitLine("    lea "+outReg+", [r12 + rax*4]")
        End Select
    Case ADDR_IND_T_REL
        EmitAddrLoad(ADDR_T_REL,addrVal,"rax")
        If BoundsOn Then EmitLine("    cmp rax, TAPE_CELLS"):EmitLine("    jae __ux_err_ptr")
        Select Case CellBits
        Case 8:EmitLine("    lea "+outReg+", [r12 + rax]")
        Case 16:EmitLine("    lea "+outReg+", [r12 + rax*2]")
        Case 32:EmitLine("    lea "+outReg+", [r12 + rax*4]")
        End Select
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
    Case 8:EmitLine("    test al, 80h")
    Case 16:EmitLine("    test ax, 8000h")
    Case 32:EmitLine("    test eax, 80000000h")
    End Select
    EmitLine("    jz __ux_nos_"+LTrim(Str(id)))
    EmitLine("    or dx, FLAG_S")
    EmitLine("__ux_nos_"+LTrim(Str(id))+":")
    EmitLine("    mov word [ux_flags], dx")
    EmitLine("    pop rax")
End Sub
Sub EmitMetaCall(ByVal metaId As Long, ByVal dynamicFlag As Long)
    EmitLine("    mov qword [ux_ptr], rbx")
    EmitLine("    mov qword [ux_sp], r14")
    If dynamicFlag Then
        EmitAddrLoad(ADDR_T,0,"rax")
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
    target=Instr(i).brTarget
    EmitLine("    ; "+Instr(i).text+" -> __ux_ip_"+LTrim(Str(target)))
    Select Case Instr(i).brCond
    Case BR_CUR_NZ
        EmitAddrLoad(ADDR_T,0,"rax")
        EmitLine("    cmp rax, 0")
        EmitLine("    jne __ux_ip_"+LTrim(Str(target)))
    Case BR_CUR_Z
        EmitAddrLoad(ADDR_T,0,"rax")
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
    id=i
    EmitLine("__ux_loop_beg_"+LTrim(Str(id))+":")
    EmitAddrLoad(ADDR_T,0,"rax")
    EmitLine("    cmp rax, 0")
    EmitLine("    je __ux_loop_end_"+LTrim(Str(id)))
End Sub
Sub EmitLoopEnd(ByVal i As Long)
    Dim id As Long
    id=Instr(i).mate
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
```

Bu native compiler artık şu çıktıları verir:

```text
1. .asm        native x64 NASM kaynak
2. .uir.json   compiler instruction ara gösterimi
3. .opt.json   pattern optimizer raporu
```

Derleme:

```bat
fbc uxm31_compiler_fb_full.bas -x uxm31_compiler_full.exe
uxm31_compiler_full.exe tests\test05_meta_add.uxm build\test05.asm build\test05.uir.json build\test05.opt.json
nasm -f win64 build\test05.asm -o build\test05.obj
fbc uxm31_runtime_fb_full.bas build\test05.obj -x build\test05.exe
build\test05.exe
```

Bu noktada dosya seti şöyle oldu:

```text
uxm31_full_tool_fb.bas          yorumlayıcı + JSON trace + IDE + UIR + optimizer + macro call-stack
uxm31_runtime_fb_full.bas       native ASM ile linklenen full runtime
uxm31_compiler_fb_full.bas      native ASM üreten full compiler
```

`uxm31_full_tool_fb.bas` tarafında runtime macro call-stack gerçek çalışır. 
`uxm31_compiler_fb_full.bas` tarafında macro’lar derleme zamanında inline açılır; 
native EXE tarafında `@128..255` kullanıcı macro call-stack değil, derlenmiş kod olarak bulunur.
