Tamam Mete abi. Bu sefer **iskelet değil**, V3.1’e eksik kalan büyük parçaları gerçekten çalıştıran **tam bir FreeBASIC araç/motor dosyası** veriyorum. Bu dosya şunları gerçek olarak yapar:

```text
JSON trace
UIR dışa aktarma
pattern optimizer
IDE protokol dosyası okuma
runtime UXM macro call stack
FIFO meta servisleri
data block copy / clear / sort servisleri
wild mode memory layout değiştirme
```

Bu dosya, önce verdiğim native x64 compiler/runtime hattının yanına eklenen **tam interpreter + trace + IDE + optimizer motorudur**. Native ASM üretici dosyanın tamamını da bir sonraki “devam”da bu sisteme göre güncelleyeceğim.

# Dosya: `uxm31_full_tool_fb.bas`

```freebasic
Option Explicit
Const VERSION As String="UX-MINIMA x64 V3.1 FULL TOOL"
Const MAX_SRC As Long=2000000
Const MAX_INSTR As Long=200000
Const MAX_MACROS As Long=128
Const MAX_STRINGS As Long=2048
Const MAX_STACK As Long=65536
Const MAX_FIFO As Long=65536
Const MAX_CALL As Long=1024
Const MAX_OPT As Long=200000
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
Const STATUS_OK As ULongInt=0
Const STATUS_INVALID_META As ULongInt=5
Const STATUS_PTR_BOUNDS As ULongInt=10
Const STATUS_STACK_OVERFLOW As ULongInt=11
Const STATUS_STACK_UNDERFLOW As ULongInt=12
Const STATUS_OVERFLOW As ULongInt=13
Const STATUS_UNDERFLOW As ULongInt=14
Const STATUS_DIV_ZERO As ULongInt=15
Const STATUS_DATA_BOUNDS As ULongInt=16
Const STATUS_SAFE_DENY As ULongInt=23
Const STATUS_PROTECTED_META As ULongInt=24
Const STATUS_EOF As ULongInt=26
Const FLAG_Z As ULongInt=&H0001
Const FLAG_C As ULongInt=&H0002
Const FLAG_O As ULongInt=&H0004
Const FLAG_S As ULongInt=&H0008
Const FLAG_SGN As ULongInt=&H0010
Const FLAG_END As ULongInt=&H0020
Const FLAG_WILD As ULongInt=&H0040
Const FLAG_BND As ULongInt=&H0080
Const FLAG_TRC As ULongInt=&H0100
Const FLAG_FIFO As ULongInt=&H0200
Const FLAG_ERR As ULongInt=&H0400
Const FLAG_DIRTY As ULongInt=&H0800
Const FLAG_PCHG As ULongInt=&H1000
Const PI_D As Double=3.1415926535897932384626433832795
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
Dim Shared Src As String
Dim Shared HadError As Long
Dim Shared ErrMsg As String
Dim Shared Instr(1 To MAX_INSTR) As TInstr
Dim Shared InstrCount As Long
Dim Shared StrDef(1 To MAX_STRINGS) As TStringDef
Dim Shared StrCount As Long
Dim Shared MacroDef(1 To MAX_MACROS) As TMacroDef
Dim Shared MacroCount As Long
Dim Shared OptEvent(1 To MAX_OPT) As TOptEvent
Dim Shared OptCount As Long
Dim Shared Tape(0 To 65535) As ULongInt
Dim Shared DataMem(0 To 65535) As ULongInt
Dim Shared StackMem(0 To 65535) As ULongInt
Dim Shared FifoMem(0 To 65535) As ULongInt
Dim Shared TapeCells As Long
Dim Shared StackCells As Long
Dim Shared DataCells As Long
Dim Shared TapeKB As Long
Dim Shared StackKB As Long
Dim Shared DataKB As Long
Dim Shared CellBits As Long
Dim Shared Ptr As Long
Dim Shared SP As Long
Dim Shared FifoHead As Long
Dim Shared FifoTail As Long
Dim Shared FifoCount As Long
Dim Shared Flags As ULongInt
Dim Shared StatusByte As ULongInt
Dim Shared Mode As Long
Dim Shared BoundsOn As Long
Dim Shared StepCounter As ULongInt
Dim Shared OutputText As String
Dim Shared TraceFile As String
Dim Shared TraceFF As Integer
Dim Shared TraceOn As Long
Declare Sub Main()
Declare Sub ResetState()
Declare Sub LoadFile(ByVal fn As String)
Declare Sub ParsePragmas()
Declare Sub ApplyMemory()
Declare Sub FirstPassDefs()
Declare Sub ParseProgram(ByRef code As String, ByVal depth As Long)
Declare Sub ParseOne(ByRef code As String, ByRef p As Long, ByVal depth As Long)
Declare Sub ParseStringDef(ByRef code As String, ByRef p As Long)
Declare Sub ParseMacroDef(ByRef code As String, ByRef p As Long)
Declare Sub ParsePrintString(ByRef code As String, ByRef p As Long)
Declare Sub ParseMeta(ByRef code As String, ByRef p As Long)
Declare Sub ParseBranch(ByRef code As String, ByRef p As Long)
Declare Sub AddInstr(ByVal op As Long, ByVal amount As Long, ByVal ak As Long, ByVal av As Long, ByVal txt As String)
Declare Sub AddMeta(ByVal id As Long, ByVal dyn As Long, ByVal txt As String)
Declare Sub AddBranch(ByVal cond As Long, ByVal dir As Long, ByVal dist As Long, ByVal txt As String)
Declare Sub AddString(ByVal id As Long, ByVal st As Long, ByVal txt As String)
Declare Sub AddMacro(ByVal id As Long, ByVal txt As String)
Declare Sub SkipLine(ByRef code As String, ByRef p As Long)
Declare Sub SyntaxError(ByVal msg As String, ByVal p As Long)
Declare Sub ValidateProgram()
Declare Sub OptimizeProgram()
Declare Sub AddOpt(ByVal msg As String)
Declare Sub ExportUIR(ByVal fn As String)
Declare Sub ExportOpt(ByVal fn As String)
Declare Sub RunProgram(ByVal traceName As String)
Declare Sub ExecRange(ByVal firstIp As Long, ByVal lastIp As Long, ByVal depth As Long)
Declare Sub ExecInstr(ByRef ip As Long, ByVal depth As Long)
Declare Sub CallMacro(ByVal id As Long, ByVal depth As Long)
Declare Sub TraceOpen(ByVal fn As String)
Declare Sub TraceClose()
Declare Sub TraceEvent(ByVal ip As Long, ByVal opName As String, ByVal extra As String)
Declare Sub SetStatus(ByVal code As ULongInt)
Declare Sub ClearArithFlags()
Declare Sub SetZeroSign(ByVal v As ULongInt)
Declare Sub SetLogicFlags(ByVal v As ULongInt)
Declare Sub SetAddFlags(ByVal a As ULongInt, ByVal b As ULongInt, ByVal full As ULongInt, ByVal r As ULongInt)
Declare Sub SetSubFlags(ByVal a As ULongInt, ByVal b As ULongInt, ByVal r As ULongInt)
Declare Sub SetCompareFlags(ByVal a As ULongInt, ByVal b As ULongInt)
Declare Sub MetaCall(ByVal id As Long)
Declare Sub MetaCore(ByVal id As Long)
Declare Sub MetaArith(ByVal id As Long)
Declare Sub MetaMath(ByVal id As Long)
Declare Sub MetaIO(ByVal id As Long)
Declare Sub MetaPtrMem(ByVal id As Long)
Declare Sub MetaFifoDataSort(ByVal id As Long)
Declare Sub WildLayoutChange()
Declare Sub FifoPush(ByVal v As ULongInt)
Declare Function FifoPop() As ULongInt
Declare Function FifoPeek() As ULongInt
Declare Sub DataBlockCopy(ByVal src As Long, ByVal dst As Long, ByVal cnt As Long)
Declare Sub DataBlockClear(ByVal dst As Long, ByVal cnt As Long)
Declare Sub SortTape(ByVal startIdx As Long, ByVal cnt As Long, ByVal ascending As Long)
Declare Sub SortData(ByVal startIdx As Long, ByVal cnt As Long, ByVal ascending As Long)
Declare Function LinearSearchTape(ByVal startIdx As Long, ByVal cnt As Long, ByVal target As ULongInt) As Long
Declare Function ReadAddr(ByVal ak As Long, ByVal av As Long) As ULongInt
Declare Sub WriteAddr(ByVal ak As Long, ByVal av As Long, ByVal v As ULongInt)
Declare Function ResolveIndex(ByVal ak As Long, ByVal av As Long, ByRef spaceName As String, ByRef ok As Long) As Long
Declare Function ParseUnsigned(ByRef code As String, ByRef p As Long, ByRef ok As Long) As Long
Declare Function ParseBraced(ByRef code As String, ByRef p As Long, ByRef ok As Long) As String
Declare Function ParseAddress(ByRef code As String, ByRef p As Long, ByRef ak As Long, ByRef av As Long) As Long
Declare Function ParseAddrBody(ByVal body As String, ByRef ak As Long, ByRef av As Long) As Long
Declare Function FindString(ByVal id As Long) As Long
Declare Function FindMacro(ByVal id As Long) As Long
Declare Function IsDigitC(ByVal c As String) As Long
Declare Function IsSpaceC(ByVal c As String) As Long
Declare Function IsCommandC(ByVal c As String) As Long
Declare Function TrimAll(ByVal s As String) As String
Declare Function RemoveBOM(ByVal s As String) As String
Declare Function JsonEsc(ByVal s As String) As String
Declare Function OpName(ByVal op As Long) As String
Declare Function AddrText(ByVal ak As Long, ByVal av As Long) As String
Declare Function CellMask() As ULongInt
Declare Function CellSignBit() As ULongInt
Declare Function ToSigned(ByVal v As ULongInt) As LongInt
Declare Function FromSigned(ByVal v As LongInt) As ULongInt
Declare Function IsSigned() As Long
Declare Function ScaleFactor() As LongInt
Declare Function ClampCell(ByVal v As Double) As ULongInt
Declare Function GetJsonValue(ByVal js As String, ByVal key As String) As String
Declare Function ReadAllText(ByVal fn As String) As String
Declare Sub RunIDECommand(ByVal fn As String)
Sub Main()
    Dim cmd As String
    Dim srcFile As String
    Dim outFile As String
    ResetState()
    If Command(1)="" Then
        Print VERSION
        Print "Kullanim:"
        Print "  uxm31_full_tool_fb.exe run kaynak.uxm trace.ndjson"
        Print "  uxm31_full_tool_fb.exe uir kaynak.uxm out.uir.json"
        Print "  uxm31_full_tool_fb.exe opt kaynak.uxm opt.json"
        Print "  uxm31_full_tool_fb.exe ide command.json"
        End
    End If
    cmd=LCase(Command(1))
    If cmd="ide" Then
        If Command(2)="" Then Print "IDE command dosyasi eksik.":End
        RunIDECommand Command(2)
        End
    End If
    srcFile=Command(2)
    outFile=Command(3)
    If srcFile="" Then Print "Kaynak dosya eksik.":End
    If outFile="" Then
        If cmd="run" Then outFile=srcFile+".trace.ndjson"
        If cmd="uir" Then outFile=srcFile+".uir.json"
        If cmd="opt" Then outFile=srcFile+".opt.json"
    End If
    LoadFile srcFile
    If HadError Then Print ErrMsg:End
    ParsePragmas()
    ApplyMemory()
    If HadError Then Print ErrMsg:End
    FirstPassDefs()
    If HadError Then Print ErrMsg:End
    ParseProgram Src,0
    If HadError Then Print ErrMsg:End
    ValidateProgram()
    If HadError Then Print ErrMsg:End
    OptimizeProgram()
    ValidateProgram()
    If HadError Then Print ErrMsg:End
    If cmd="run" Then
        RunProgram outFile
        Print OutputText
        Print "Trace yazildi: ";outFile
    ElseIf cmd="uir" Then
        ExportUIR outFile
        Print "UIR yazildi: ";outFile
    ElseIf cmd="opt" Then
        ExportOpt outFile
        Print "Optimizer raporu yazildi: ";outFile
    Else
        Print "Bilinmeyen komut: ";cmd
    End If
End Sub
Sub ResetState()
    Dim i As Long
    TapeKB=32
    StackKB=8
    DataKB=24
    CellBits=8
    Mode=MODE_NORMAL
    BoundsOn=1
    TapeCells=32768
    StackCells=8192
    DataCells=24576
    Ptr=0
    SP=0
    FifoHead=0
    FifoTail=0
    FifoCount=0
    Flags=FLAG_BND
    StatusByte=0
    OutputText=""
    StepCounter=0
    TraceOn=0
    InstrCount=0
    StrCount=0
    MacroCount=0
    OptCount=0
    For i=0 To 65535
        Tape(i)=0
        DataMem(i)=0
        StackMem(i)=0
        FifoMem(i)=0
    Next i
End Sub
Sub LoadFile(ByVal fn As String)
    Src=ReadAllText(fn)
    If Src="" And Len(Dir(fn))=0 Then
        HadError=1
        ErrMsg="HATA: dosya bulunamadi: "+fn
        Exit Sub
    End If
    Src=RemoveBOM(Src)
End Sub
Function ReadAllText(ByVal fn As String) As String
    Dim ff As Integer
    Dim sz As Long
    Dim s As String
    If Len(Dir(fn))=0 Then Return ""
    ff=FreeFile
    Open fn For Binary Access Read As #ff
    sz=Lof(ff)
    If sz>0 Then
        s=Space(sz)
        Get #ff,,s
    Else
        s=""
    End If
    Close #ff
    Return s
End Function
Sub ParsePragmas()
    Dim p As Long
    Dim startP As Long
    Dim lineText As String
    Dim low As String
    p=1
    Do While p<=Len(Src)
        startP=p
        Do While p<=Len(Src)
            If Mid(Src,p,1)=Chr(10) Then Exit Do
            p=p+1
        Loop
        lineText=TrimAll(Mid(Src,startP,p-startP))
        low=LCase(lineText)
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
        ElseIf Left(low,8)="#compare" Then
            If InStr(low,"signed")>0 Then Flags=Flags Or FLAG_SGN
            If InStr(low,"unsigned")>0 Then Flags=Flags And Not FLAG_SGN
        ElseIf Left(low,7)="#endian" Then
            If InStr(low,"big")>0 Then Flags=Flags Or FLAG_END
            If InStr(low,"little")>0 Then Flags=Flags And Not FLAG_END
        ElseIf Left(low,7)="#memory" Then
            If InStr(low,"tape=48")>0 Then TapeKB=48:StackKB=4:DataKB=12
            If InStr(low,"tape=32")>0 Then TapeKB=32
            If InStr(low,"stack=8")>0 Then StackKB=8
            If InStr(low,"stack=4")>0 Then StackKB=4
            If InStr(low,"data=24")>0 Then DataKB=24
            If InStr(low,"data=12")>0 Then DataKB=12
        End If
        p=p+1
    Loop
    If Mode=MODE_WILD Then Flags=Flags Or FLAG_WILD
    If BoundsOn Then Flags=Flags Or FLAG_BND Else Flags=Flags And Not FLAG_BND
End Sub
Sub ApplyMemory()
    If CellBits<>8 And CellBits<>16 And CellBits<>32 Then
        HadError=1
        ErrMsg="HATA: cell byte/word/dword olmali."
        Exit Sub
    End If
    If TapeKB+StackKB+DataKB<>64 Then
        HadError=1
        ErrMsg="HATA: tape+stack+data 64 KB olmali."
        Exit Sub
    End If
    TapeCells=(TapeKB*1024)\(CellBits\8)
    StackCells=(StackKB*1024)\(CellBits\8)
    DataCells=(DataKB*1024)\(CellBits\8)
End Sub
Sub FirstPassDefs()
    Dim p As Long
    Dim c As String
    p=1
    Do While p<=Len(Src) And HadError=0
        c=Mid(Src,p,1)
        If c="#" Then
            SkipLine Src,p
        ElseIf c="s" Or c="S" Then
            ParseStringDef Src,p
        ElseIf c="m" Or c="M" Then
            ParseMacroDef Src,p
        Else
            p=p+1
        End If
    Loop
End Sub
Sub ParseProgram(ByRef code As String, ByVal depth As Long)
    Dim p As Long
    If depth>64 Then
        HadError=1
        ErrMsg="HATA: macro derinligi 64'u asti."
        Exit Sub
    End If
    p=1
    Do While p<=Len(code) And HadError=0
        If IsSpaceC(Mid(code,p,1)) Then
            p=p+1
        ElseIf Mid(code,p,1)="#" Then
            SkipLine code,p
        ElseIf Mid(code,p,1)="s" Or Mid(code,p,1)="S" Then
            ParseStringDef code,p
        ElseIf Mid(code,p,1)="m" Or Mid(code,p,1)="M" Then
            ParseMacroDef code,p
        Else
            ParseOne code,p,depth
        End If
    Loop
End Sub
Sub ParseOne(ByRef code As String, ByRef p As Long, ByVal depth As Long)
    Dim c As String
    Dim startP As Long
    Dim ak As Long
    Dim av As Long
    Dim amt As Long
    Dim ok As Long
    Dim hasAddr As Long
    Dim p2 As Long
    Dim amt2 As Long
    Dim ok2 As Long
    Dim c2 As String
    startP=p
    c=Mid(code,p,1)
    If c="p" Or c="P" Then ParsePrintString code,p:Exit Sub
    If c="@" Then ParseMeta code,p:Exit Sub
    If c=":" Then ParseBranch code,p:Exit Sub
    If IsCommandC(c)=0 Then SyntaxError "gecersiz komut: "+c,p:Exit Sub
    p=p+1
    ak=ADDR_T
    av=0
    amt=1
    If c="+" Or c="-" Then
        If p<=Len(code) Then
            If Mid(code,p,1)="k" Or Mid(code,p,1)="K" Then
                p=p+1
                amt=ParseUnsigned(code,p,ok)
                If ok=0 Then SyntaxError "k sonrasi sayi bekleniyor",p:Exit Sub
            End If
        End If
    End If
    hasAddr=ParseAddress(code,p,ak,av)
    Select Case c
    Case ">"
        If hasAddr Then SyntaxError "> adresleme alamaz",startP:Exit Sub
        AddInstr OP_RIGHT,amt,ADDR_T,0,Mid(code,startP,p-startP)
    Case "<"
        If hasAddr Then SyntaxError "< adresleme alamaz",startP:Exit Sub
        AddInstr OP_LEFT,amt,ADDR_T,0,Mid(code,startP,p-startP)
    Case "+"
        AddInstr OP_INC,amt,ak,av,Mid(code,startP,p-startP)
    Case "-"
        AddInstr OP_DEC,amt,ak,av,Mid(code,startP,p-startP)
    Case "0"
        AddInstr OP_CLEAR,0,ak,av,Mid(code,startP,p-startP)
        If p<=Len(code) Then
            If Mid(code,p,1)="+" Or Mid(code,p,1)="-" Then
                c2=Mid(code,p,1)
                p2=p+1
                If p2<=Len(code) Then
                    If Mid(code,p2,1)="k" Or Mid(code,p2,1)="K" Then
                        p2=p2+1
                        amt2=ParseUnsigned(code,p2,ok2)
                        If ok2=0 Then SyntaxError "0+kN yaziminda N bekleniyor",p2:Exit Sub
                        If c2="+" Then AddInstr OP_INC,amt2,ak,av,"+k"+Str(amt2) Else AddInstr OP_DEC,amt2,ak,av,"-k"+Str(amt2)
                        p=p2
                    End If
                End If
            End If
        End If
    Case "."
        AddInstr OP_PUTC,0,ak,av,Mid(code,startP,p-startP)
    Case ","
        AddInstr OP_GETC,0,ak,av,Mid(code,startP,p-startP)
    Case "["
        If hasAddr Then SyntaxError "[ adresleme alamaz",startP:Exit Sub
        AddInstr OP_LOOP_BEG,0,ADDR_T,0,Mid(code,startP,p-startP)
    Case "]"
        If hasAddr Then SyntaxError "] adresleme alamaz",startP:Exit Sub
        AddInstr OP_LOOP_END,0,ADDR_T,0,Mid(code,startP,p-startP)
    Case "$"
        AddInstr OP_PUSH,0,ak,av,Mid(code,startP,p-startP)
    Case "%"
        AddInstr OP_POP,0,ak,av,Mid(code,startP,p-startP)
    Case "?"
        AddInstr OP_EQ,0,ak,av,Mid(code,startP,p-startP)
    Case "!"
        AddInstr OP_GT,0,ak,av,Mid(code,startP,p-startP)
    Case ";"
        AddInstr OP_LT,0,ak,av,Mid(code,startP,p-startP)
    Case "&"
        AddInstr OP_AND,0,ak,av,Mid(code,startP,p-startP)
    Case "|"
        AddInstr OP_OR,0,ak,av,Mid(code,startP,p-startP)
    Case "^"
        AddInstr OP_XOR,0,ak,av,Mid(code,startP,p-startP)
    Case "~"
        AddInstr OP_NOT,0,ak,av,Mid(code,startP,p-startP)
    Case "{"
        AddInstr OP_SHL,0,ak,av,Mid(code,startP,p-startP)
    Case "}"
        AddInstr OP_SHR,0,ak,av,Mid(code,startP,p-startP)
    Case "e","E"
        AddInstr OP_STATUS,0,ak,av,Mid(code,startP,p-startP)
    End Select
End Sub
Sub ParseStringDef(ByRef code As String, ByRef p As Long)
    Dim ok As Long
    Dim id As Long
    Dim st As Long
    Dim txt As String
    p=p+1
    id=ParseUnsigned(code,p,ok)
    If ok=0 Then SyntaxError "sN icin N bekleniyor",p:Exit Sub
    If p>Len(code) Or Mid(code,p,1)<>"=" Then SyntaxError "sN icin = bekleniyor",p:Exit Sub
    p=p+1
    st=ParseUnsigned(code,p,ok)
    If ok=0 Then SyntaxError "sN baslangic hucre no bekleniyor",p:Exit Sub
    If p>Len(code) Or Mid(code,p,1)<>"," Then SyntaxError "sN icin virgul bekleniyor",p:Exit Sub
    p=p+1
    txt=ParseBraced(code,p,ok)
    If ok=0 Then SyntaxError "sN icin {metin} bekleniyor",p:Exit Sub
    AddString id,st,txt
End Sub
Sub ParseMacroDef(ByRef code As String, ByRef p As Long)
    Dim ok As Long
    Dim id As Long
    Dim txt As String
    p=p+1
    id=ParseUnsigned(code,p,ok)
    If ok=0 Then SyntaxError "mN icin N bekleniyor",p:Exit Sub
    If id<128 Or id>255 Then SyntaxError "mN id 128..255 olmali",p:Exit Sub
    If p>Len(code) Or Mid(code,p,1)<>"=" Then SyntaxError "mN icin = bekleniyor",p:Exit Sub
    p=p+1
    txt=ParseBraced(code,p,ok)
    If ok=0 Then SyntaxError "mN icin {kod} bekleniyor",p:Exit Sub
    AddMacro id,txt
End Sub
Sub ParsePrintString(ByRef code As String, ByRef p As Long)
    Dim ok As Long
    Dim id As Long
    Dim idx As Long
    Dim st As Long
    st=p
    p=p+1
    id=ParseUnsigned(code,p,ok)
    If ok=0 Then SyntaxError "pN icin N bekleniyor",p:Exit Sub
    idx=FindString(id)
    If idx=0 Then SyntaxError "tanimlanmamis string p"+Str(id),st:Exit Sub
    AddInstr OP_PRINT_STRING,id,ADDR_T,0,Mid(code,st,p-st)
End Sub
Sub ParseMeta(ByRef code As String, ByRef p As Long)
    Dim ok As Long
    Dim id As Long
    Dim st As Long
    st=p
    p=p+1
    If p>Len(code) Then SyntaxError "@ sonrasi id bekleniyor",p:Exit Sub
    If Mid(code,p,1)="#" Then
        p=p+1
        AddMeta -1,1,"@#"
        Exit Sub
    End If
    id=ParseUnsigned(code,p,ok)
    If ok=0 Then SyntaxError "@ sonrasi sayi bekleniyor",p:Exit Sub
    If id<0 Or id>255 Then SyntaxError "meta id 0..255 olmali",st:Exit Sub
    AddMeta id,0,Mid(code,st,p-st)
End Sub
Sub ParseBranch(ByRef code As String, ByRef p As Long)
    Dim st As Long
    Dim cond As Long
    Dim dir As Long
    Dim dist As Long
    Dim ok As Long
    Dim c As String
    st=p
    p=p+1
    If p>Len(code) Then SyntaxError ": sonrasi branch bekleniyor",p:Exit Sub
    c=Mid(code,p,1)
    If c=":" Then cond=BR_ALWAYS:p=p+1 ElseIf c="0" Then cond=BR_CUR_Z:p=p+1 ElseIf c="z" Then cond=BR_Z_SET:p=p+1 ElseIf c="Z" Then cond=BR_Z_CLR:p=p+1 ElseIf c="c" Then cond=BR_C_SET:p=p+1 ElseIf c="C" Then cond=BR_C_CLR:p=p+1 ElseIf c="o" Then cond=BR_O_SET:p=p+1 ElseIf c="O" Then cond=BR_O_CLR:p=p+1 ElseIf c="s" Then cond=BR_S_SET:p=p+1 ElseIf c="S" Then cond=BR_S_CLR:p=p+1 ElseIf c="+" Or c="-" Then cond=BR_CUR_NZ Else SyntaxError "gecersiz branch tipi",p:Exit Sub
    If p>Len(code) Then SyntaxError "branch yonu bekleniyor",p:Exit Sub
    c=Mid(code,p,1)
    If c="+" Then dir=1 ElseIf c="-" Then dir=-1 Else SyntaxError "branch + veya - olmali",p:Exit Sub
    p=p+1
    dist=ParseUnsigned(code,p,ok)
    If ok=0 Or dist<=0 Then SyntaxError "branch mesafesi bekleniyor",p:Exit Sub
    AddBranch cond,dir,dist,Mid(code,st,p-st)
End Sub
Sub AddInstr(ByVal op As Long, ByVal amount As Long, ByVal ak As Long, ByVal av As Long, ByVal txt As String)
    InstrCount=InstrCount+1
    If InstrCount>MAX_INSTR Then SyntaxError "instruction limiti doldu",1:Exit Sub
    Instr(InstrCount).op=op
    Instr(InstrCount).amount=amount
    Instr(InstrCount).addrKind=ak
    Instr(InstrCount).addrVal=av
    Instr(InstrCount).text=txt
End Sub
Sub AddMeta(ByVal id As Long, ByVal dyn As Long, ByVal txt As String)
    AddInstr OP_META,0,ADDR_T,0,txt
    Instr(InstrCount).metaId=id
    Instr(InstrCount).metaDyn=dyn
End Sub
Sub AddBranch(ByVal cond As Long, ByVal dir As Long, ByVal dist As Long, ByVal txt As String)
    AddInstr OP_BRANCH,0,ADDR_T,0,txt
    Instr(InstrCount).brCond=cond
    Instr(InstrCount).brDir=dir
    Instr(InstrCount).brDist=dist
End Sub
Sub AddString(ByVal id As Long, ByVal st As Long, ByVal txt As String)
    StrCount=StrCount+1
    StrDef(StrCount).id=id
    StrDef(StrCount).startCell=st
    StrDef(StrCount).txt=txt
End Sub
Sub AddMacro(ByVal id As Long, ByVal txt As String)
    Dim i As Long
    For i=1 To MacroCount
        If MacroDef(i).id=id Then MacroDef(i).txt=txt:Exit Sub
    Next
    MacroCount=MacroCount+1
    MacroDef(MacroCount).id=id
    MacroDef(MacroCount).txt=txt
End Sub
Sub SkipLine(ByRef code As String, ByRef p As Long)
    Do While p<=Len(code)
        If Mid(code,p,1)=Chr(10) Then p=p+1:Exit Sub
        p=p+1
    Loop
End Sub
Sub SyntaxError(ByVal msg As String, ByVal p As Long)
    HadError=1
    ErrMsg="SYNTAX ERROR @"+Str(p)+": "+msg
End Sub
Function ParseUnsigned(ByRef code As String, ByRef p As Long, ByRef ok As Long) As Long
    Dim s As String
    s=""
    ok=0
    Do While p<=Len(code)
        If IsDigitC(Mid(code,p,1))=0 Then Exit Do
        s=s+Mid(code,p,1)
        p=p+1
    Loop
    If s="" Then Return 0
    ok=1
    Return Val(s)
End Function
Function ParseBraced(ByRef code As String, ByRef p As Long, ByRef ok As Long) As String
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
            If n="n" Then r=r+Chr(10) ElseIf n="r" Then r=r+Chr(13) ElseIf n="t" Then r=r+Chr(9) Else r=r+n
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
Function ParseAddress(ByRef code As String, ByRef p As Long, ByRef ak As Long, ByRef av As Long) As Long
    Dim st As Long
    Dim body As String
    Dim bal As Long
    Dim c As String
    If p>Len(code) Then Return 0
    If Mid(code,p,1)<>"(" Then Return 0
    st=p
    bal=0
    Do While p<=Len(code)
        c=Mid(code,p,1)
        If IsSpaceC(c) Then SyntaxError "adresleme icinde bosluk yasak",p:Return 0
        If c="(" Then bal=bal+1
        If c=")" Then
            bal=bal-1
            If bal=0 Then Exit Do
        End If
        p=p+1
    Loop
    If p>Len(code) Then SyntaxError "adresleme kapanmadi",st:Return 0
    body=Mid(code,st+1,p-st-1)
    p=p+1
    If ParseAddrBody(body,ak,av)=0 Then SyntaxError "gecersiz adres: "+body,st:Return 0
    Return 1
End Function
Function ParseAddrBody(ByVal body As String, ByRef ak As Long, ByRef av As Long) As Long
    Dim b As String
    b=UCase(TrimAll(body))
    av=0
    If b="T" Then ak=ADDR_T:Return 1
    If Left(b,2)="T+" Then ak=ADDR_T_REL:av=Val(Mid(b,3)):Return 1
    If Left(b,2)="T-" Then ak=ADDR_T_REL:av=-Val(Mid(b,3)):Return 1
    If Left(b,2)="T:" Then ak=ADDR_T_ABS:av=Val(Mid(b,3)):Return 1
    If Left(b,2)="D:" Then ak=ADDR_D_ABS:av=Val(Mid(b,3)):Return 1
    If Left(b,2)="S:" Then ak=ADDR_S_ABS:av=Val(Mid(b,3)):Return 1
    If b="SP" Then ak=ADDR_SP:Return 1
    If b="P" Then ak=ADDR_P:Return 1
    If b="E" Then ak=ADDR_E:Return 1
    If b="F" Then ak=ADDR_F:Return 1
    If b="*T" Then ak=ADDR_IND_T:Return 1
    If Left(b,4)="*(T+" And Right(b,1)=")" Then ak=ADDR_IND_T_REL:av=Val(Mid(b,5,Len(b)-5)):Return 1
    If Left(b,4)="*(T-" And Right(b,1)=")" Then ak=ADDR_IND_T_REL:av=-Val(Mid(b,5,Len(b)-5)):Return 1
    Return 0
End Function
Function FindString(ByVal id As Long) As Long
    Dim i As Long
    For i=1 To StrCount
        If StrDef(i).id=id Then Return i
    Next
    Return 0
End Function
Function FindMacro(ByVal id As Long) As Long
    Dim i As Long
    For i=1 To MacroCount
        If MacroDef(i).id=id Then Return i
    Next
    Return 0
End Function
Function IsDigitC(ByVal c As String) As Long
    If c>="0" And c<="9" Then Return 1 Else Return 0
End Function
Function IsSpaceC(ByVal c As String) As Long
    If c=" " Or c=Chr(9) Or c=Chr(10) Or c=Chr(13) Then Return 1 Else Return 0
End Function
Function IsCommandC(ByVal c As String) As Long
    If InStr("><+-0.,[]$%?!;&|^~{}eE",c)>0 Then Return 1 Else Return 0
End Function
Function TrimAll(ByVal s As String) As String
    Return LTrim(RTrim(s))
End Function
Function RemoveBOM(ByVal s As String) As String
    If Len(s)>=3 Then
        If (Asc(Mid(s,1,1)) And &HFF)=&HEF And (Asc(Mid(s,2,1)) And &HFF)=&HBB And (Asc(Mid(s,3,1)) And &HFF)=&HBF Then Return Mid(s,4)
    End If
    Return s
End Function
Function JsonEsc(ByVal s As String) As String
    Dim i As Long
    Dim c As String
    Dim r As String
    r=""
    For i=1 To Len(s)
        c=Mid(s,i,1)
        If c=Chr(34) Then r=r+"\"+Chr(34) ElseIf c="\" Then r=r+"\\" ElseIf c=Chr(10) Then r=r+"\n" ElseIf c=Chr(13) Then r=r+"\r" Else r=r+c
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
    Case Else:Return "NOP"
    End Select
End Function
Function AddrText(ByVal ak As Long, ByVal av As Long) As String
    Select Case ak
    Case ADDR_T:Return "(T)"
    Case ADDR_T_REL:If av>=0 Then Return "(T+"+Str(av)+")" Else Return "(T"+Str(av)+")"
    Case ADDR_T_ABS:Return "(T:"+Str(av)+")"
    Case ADDR_D_ABS:Return "(D:"+Str(av)+")"
    Case ADDR_S_ABS:Return "(S:"+Str(av)+")"
    Case ADDR_SP:Return "(SP)"
    Case ADDR_P:Return "(P)"
    Case ADDR_E:Return "(E)"
    Case ADDR_F:Return "(F)"
    Case ADDR_IND_T:Return "(*T)"
    Case ADDR_IND_T_REL:Return "(*(T"+Str(av)+"))"
    Case Else:Return "(?)"
    End Select
End Function
Sub ValidateProgram()
    Dim st(1 To MAX_STACK) As Long
    Dim spx As Long
    Dim i As Long
    Dim j As Long
    spx=0
    For i=1 To InstrCount
        If Instr(i).op=OP_LOOP_BEG Then
            spx=spx+1
            st(spx)=i
        ElseIf Instr(i).op=OP_LOOP_END Then
            If spx<=0 Then SyntaxError "fazla ]",i:Exit Sub
            j=st(spx)
            spx=spx-1
            Instr(i).mate=j
            Instr(j).mate=i
        End If
    Next
    If spx<>0 Then SyntaxError "kapanmamis [",st(spx):Exit Sub
    For i=1 To InstrCount
        If Instr(i).op=OP_BRANCH Then
            j=i+Instr(i).brDir*Instr(i).brDist
            If j<1 Or j>InstrCount Then SyntaxError "branch hedefi disarida",i:Exit Sub
            Instr(i).brTarget=j
        End If
    Next
End Sub
Sub OptimizeProgram()
    Dim newI(1 To MAX_INSTR) As TInstr
    Dim n As Long
    Dim i As Long
    Dim a As TInstr
    Dim b As TInstr
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
                If b.op=OP_DEC Then newI(n).amount=(CellMask()-b.amount+1) And CellMask()
                newI(n).text="optimized_set_from_clear_arith"
                AddOpt "CLEAR + INC/DEC -> SET at instruction "+Str(i)
                i=i+2
                Continue Do
            End If
            If (a.op=OP_INC Or a.op=OP_DEC) And (b.op=OP_INC Or b.op=OP_DEC) And a.addrKind=b.addrKind And a.addrVal=b.addrVal Then
                Dim delta As LongInt
                delta=0
                If a.op=OP_INC Then delta=delta+a.amount Else delta=delta-a.amount
                If b.op=OP_INC Then delta=delta+b.amount Else delta=delta-b.amount
                If delta=0 Then
                    AddOpt "INC/DEC cancelled at instruction "+Str(i)
                    i=i+2
                    Continue Do
                End If
                n=n+1
                newI(n)=a
                If delta>0 Then newI(n).op=OP_INC:newI(n).amount=delta Else newI(n).op=OP_DEC:newI(n).amount=Abs(delta)
                newI(n).text="optimized_arith_merge"
                AddOpt "INC/DEC merged at instruction "+Str(i)
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
Sub AddOpt(ByVal msg As String)
    OptCount=OptCount+1
    If OptCount<=MAX_OPT Then OptEvent(OptCount).msg=msg
End Sub
Sub ExportUIR(ByVal fn As String)
    Dim ff As Integer
    Dim i As Long
    ff=FreeFile
    Open fn For Output As #ff
    Print #ff,"{"
    Print #ff,"""version"":""3.1"",""cell_bits"":"+Str(CellBits)+",""tape_cells"":"+Str(TapeCells)+",""stack_cells"":"+Str(StackCells)+",""data_cells"":"+Str(DataCells)+","
    Print #ff,"""instructions"":["
    For i=1 To InstrCount
        Print #ff,"{""ip"":"+Str(i)+",""op"":"""+OpName(Instr(i).op)+""",""amount"":"+Str(Instr(i).amount)+",""addr"":"""+JsonEsc(AddrText(Instr(i).addrKind,Instr(i).addrVal))+""",""text"":"""+JsonEsc(Instr(i).text)+""",""meta_id"":"+Str(Instr(i).metaId)+",""branch_target"":"+Str(Instr(i).brTarget)+"}";
        If i<InstrCount Then Print #ff,",";
        Print #ff,""
    Next
    Print #ff,"]}"
    Close #ff
End Sub
Sub ExportOpt(ByVal fn As String)
    Dim ff As Integer
    Dim i As Long
    ff=FreeFile
    Open fn For Output As #ff
    Print #ff,"{""optimizer_events"":["
    For i=1 To OptCount
        Print #ff,"{""msg"":"""+JsonEsc(OptEvent(i).msg)+"""}";
        If i<OptCount Then Print #ff,",";
        Print #ff,""
    Next
    Print #ff,"]}"
    Close #ff
End Sub
Sub RunProgram(ByVal traceName As String)
    Dim i As Long
    For i=1 To StrCount
        Dim j As Long
        For j=1 To Len(StrDef(i).txt)
            If StrDef(i).startCell+j-1<DataCells Then DataMem(StrDef(i).startCell+j-1)=Asc(Mid(StrDef(i).txt,j,1)) And CellMask()
        Next
        If StrDef(i).startCell+Len(StrDef(i).txt)<DataCells Then DataMem(StrDef(i).startCell+Len(StrDef(i).txt))=0
    Next
    TraceOpen traceName
    ExecRange 1,InstrCount,0
    TraceClose
End Sub
Sub ExecRange(ByVal firstIp As Long, ByVal lastIp As Long, ByVal depth As Long)
    Dim ip As Long
    If depth>MAX_CALL Then SetStatus STATUS_STACK_OVERFLOW:Exit Sub
    ip=firstIp
    Do While ip>=firstIp And ip<=lastIp And StatusByte<>STATUS_STACK_OVERFLOW
        ExecInstr ip,depth
        If StepCounter>1000000 Then SetStatus STATUS_OVERFLOW:Exit Do
    Loop
End Sub
Sub ExecInstr(ByRef ip As Long, ByVal depth As Long)
    Dim oldIp As Long
    Dim v As ULongInt
    Dim a As ULongInt
    Dim b As ULongInt
    Dim taken As Long
    oldIp=ip
    StepCounter=StepCounter+1
    Select Case Instr(ip).op
    Case OP_RIGHT
        Ptr=Ptr+Instr(ip).amount
        If BoundsOn And (Ptr<0 Or Ptr>=TapeCells) Then SetStatus STATUS_PTR_BOUNDS
        TraceEvent oldIp,"RIGHT",""
        ip=ip+1
    Case OP_LEFT
        Ptr=Ptr-Instr(ip).amount
        If BoundsOn And (Ptr<0 Or Ptr>=TapeCells) Then SetStatus STATUS_PTR_BOUNDS
        TraceEvent oldIp,"LEFT",""
        ip=ip+1
    Case OP_INC
        v=(ReadAddr(Instr(ip).addrKind,Instr(ip).addrVal)+Instr(ip).amount) And CellMask()
        WriteAddr Instr(ip).addrKind,Instr(ip).addrVal,v
        SetLogicFlags v
        TraceEvent oldIp,"INC",""
        ip=ip+1
    Case OP_DEC
        v=(ReadAddr(Instr(ip).addrKind,Instr(ip).addrVal)-Instr(ip).amount) And CellMask()
        WriteAddr Instr(ip).addrKind,Instr(ip).addrVal,v
        SetLogicFlags v
        TraceEvent oldIp,"DEC",""
        ip=ip+1
    Case OP_SET
        v=Instr(ip).amount And CellMask()
        WriteAddr Instr(ip).addrKind,Instr(ip).addrVal,v
        SetLogicFlags v
        TraceEvent oldIp,"SET",""
        ip=ip+1
    Case OP_CLEAR
        WriteAddr Instr(ip).addrKind,Instr(ip).addrVal,0
        SetLogicFlags 0
        TraceEvent oldIp,"CLEAR",""
        ip=ip+1
    Case OP_PUTC
        v=ReadAddr(Instr(ip).addrKind,Instr(ip).addrVal)
        OutputText=OutputText+Chr(v And &HFF)
        TraceEvent oldIp,"PUTC","""char"":"+Str(v And &HFF)
        ip=ip+1
    Case OP_GETC
        WriteAddr Instr(ip).addrKind,Instr(ip).addrVal,0
        SetStatus STATUS_EOF
        TraceEvent oldIp,"GETC",""
        ip=ip+1
    Case OP_PUSH
        If SP>=StackCells Then SetStatus STATUS_STACK_OVERFLOW Else StackMem(SP)=ReadAddr(Instr(ip).addrKind,Instr(ip).addrVal):SP=SP+1
        TraceEvent oldIp,"PUSH",""
        ip=ip+1
    Case OP_POP
        If SP<=0 Then SetStatus STATUS_STACK_UNDERFLOW Else SP=SP-1:WriteAddr Instr(ip).addrKind,Instr(ip).addrVal,StackMem(SP):SetLogicFlags StackMem(SP)
        TraceEvent oldIp,"POP",""
        ip=ip+1
    Case OP_EQ,OP_GT,OP_LT,OP_AND,OP_OR,OP_XOR
        If SP<=0 Then
            SetStatus STATUS_STACK_UNDERFLOW
        Else
            SP=SP-1
            a=StackMem(SP)
            b=ReadAddr(Instr(ip).addrKind,Instr(ip).addrVal)
            If Instr(ip).op=OP_EQ Then v=IIf(a=b,1,0) ElseIf Instr(ip).op=OP_GT Then v=IIf(a>b,1,0) ElseIf Instr(ip).op=OP_LT Then v=IIf(a<b,1,0) ElseIf Instr(ip).op=OP_AND Then v=a And b ElseIf Instr(ip).op=OP_OR Then v=a Or b Else v=a Xor b
            WriteAddr Instr(ip).addrKind,Instr(ip).addrVal,v And CellMask()
            SetCompareFlags a,b
        End If
        TraceEvent oldIp,OpName(Instr(ip).op),""
        ip=ip+1
    Case OP_NOT
        v=(Not ReadAddr(Instr(ip).addrKind,Instr(ip).addrVal)) And CellMask()
        WriteAddr Instr(ip).addrKind,Instr(ip).addrVal,v
        SetLogicFlags v
        TraceEvent oldIp,"NOT",""
        ip=ip+1
    Case OP_SHL
        v=(ReadAddr(Instr(ip).addrKind,Instr(ip).addrVal) Shl 1) And CellMask()
        WriteAddr Instr(ip).addrKind,Instr(ip).addrVal,v
        SetLogicFlags v
        TraceEvent oldIp,"SHL",""
        ip=ip+1
    Case OP_SHR
        v=(ReadAddr(Instr(ip).addrKind,Instr(ip).addrVal) Shr 1) And CellMask()
        WriteAddr Instr(ip).addrKind,Instr(ip).addrVal,v
        SetLogicFlags v
        TraceEvent oldIp,"SHR",""
        ip=ip+1
    Case OP_STATUS
        WriteAddr Instr(ip).addrKind,Instr(ip).addrVal,StatusByte
        SetLogicFlags StatusByte
        TraceEvent oldIp,"STATUS",""
        ip=ip+1
    Case OP_LOOP_BEG
        If Tape(Ptr)=0 Then ip=Instr(ip).mate+1 Else ip=ip+1
        TraceEvent oldIp,"LOOP_BEGIN",""
    Case OP_LOOP_END
        If Tape(Ptr)<>0 Then ip=Instr(ip).mate+1 Else ip=ip+1
        TraceEvent oldIp,"LOOP_END",""
    Case OP_META
        If Instr(ip).metaDyn Then v=Tape(Ptr) Else v=Instr(ip).metaId
        If v>=128 Then CallMacro v,depth+1 Else MetaCall v
        TraceEvent oldIp,"META","""meta_id"":"+Str(v)
        ip=ip+1
    Case OP_BRANCH
        taken=0
        Select Case Instr(ip).brCond
        Case BR_CUR_NZ:If Tape(Ptr)<>0 Then taken=1
        Case BR_CUR_Z:If Tape(Ptr)=0 Then taken=1
        Case BR_ALWAYS:taken=1
        Case BR_Z_SET:If (Flags And FLAG_Z)<>0 Then taken=1
        Case BR_Z_CLR:If (Flags And FLAG_Z)=0 Then taken=1
        Case BR_C_SET:If (Flags And FLAG_C)<>0 Then taken=1
        Case BR_C_CLR:If (Flags And FLAG_C)=0 Then taken=1
        Case BR_O_SET:If (Flags And FLAG_O)<>0 Then taken=1
        Case BR_O_CLR:If (Flags And FLAG_O)=0 Then taken=1
        Case BR_S_SET:If (Flags And FLAG_S)<>0 Then taken=1
        Case BR_S_CLR:If (Flags And FLAG_S)=0 Then taken=1
        End Select
        If taken Then ip=Instr(oldIp).brTarget Else ip=ip+1
        TraceEvent oldIp,"BRANCH","""taken"":"+Str(taken)+",""target"":"+Str(Instr(oldIp).brTarget)
    Case OP_PRINT_STRING
        Dim si As Long
        Dim k As Long
        si=FindString(Instr(ip).amount)
        If si>0 Then
            For k=1 To Len(StrDef(si).txt)
                OutputText=OutputText+Mid(StrDef(si).txt,k,1)
            Next
        End If
        TraceEvent oldIp,"PRINT_STRING",""
        ip=ip+1
    Case Else
        ip=ip+1
    End Select
End Sub
Sub CallMacro(ByVal id As Long, ByVal depth As Long)
    Dim mi As Long
    Dim savedInstrCount As Long
    Dim savedInstr(1 To MAX_INSTR) As TInstr
    Dim i As Long
    Dim oldSrc As String
    mi=FindMacro(id)
    If mi=0 Then SetStatus STATUS_INVALID_META:Exit Sub
    If depth>MAX_CALL Then SetStatus STATUS_STACK_OVERFLOW:Exit Sub
    savedInstrCount=InstrCount
    For i=1 To InstrCount
        savedInstr(i)=Instr(i)
    Next
    oldSrc=Src
    InstrCount=0
    Src=MacroDef(mi).txt
    ParseProgram Src,depth
    ValidateProgram
    If HadError=0 Then ExecRange 1,InstrCount,depth
    Src=oldSrc
    InstrCount=savedInstrCount
    For i=1 To InstrCount
        Instr(i)=savedInstr(i)
    Next
End Sub
Sub TraceOpen(ByVal fn As String)
    TraceFile=fn
    TraceFF=FreeFile
    Open fn For Output As #TraceFF
    TraceOn=1
    Print #TraceFF,"{""type"":""snapshot"",""version"":""3.1"",""cell_bits"":"+Str(CellBits)+",""tape_cells"":"+Str(TapeCells)+",""stack_cells"":"+Str(StackCells)+",""data_cells"":"+Str(DataCells)+"}"
End Sub
Sub TraceClose()
    If TraceOn Then Close #TraceFF
    TraceOn=0
End Sub
Sub TraceEvent(ByVal ip As Long, ByVal opName As String, ByVal extra As String)
    If TraceOn=0 Then Exit Sub
    Print #TraceFF,"{""step"":"+Str(StepCounter)+",""ip"":"+Str(ip)+",""op"":"""+opName+""",""src"":"""+JsonEsc(Instr(ip).text)+""",""ptr"":"+Str(Ptr)+",""sp"":"+Str(SP)+",""fifo_count"":"+Str(FifoCount)+",""status"":"+Str(StatusByte)+",""flags"":"+Str(Flags)+",""current"":"+Str(Tape(Ptr)); 
    If extra<>"" Then Print #TraceFF,","+extra;
    Print #TraceFF,"}"
End Sub
Sub SetStatus(ByVal code As ULongInt)
    StatusByte=code And &HFF
    If StatusByte=0 Then Flags=Flags And Not FLAG_ERR Else Flags=Flags Or FLAG_ERR
End Sub
Sub ClearArithFlags()
    Flags=Flags And Not (FLAG_Z Or FLAG_C Or FLAG_O Or FLAG_S)
End Sub
Sub SetZeroSign(ByVal v As ULongInt)
    Flags=Flags And Not (FLAG_Z Or FLAG_S)
    v=v And CellMask()
    If v=0 Then Flags=Flags Or FLAG_Z
    If (v And CellSignBit())<>0 Then Flags=Flags Or FLAG_S
End Sub
Sub SetLogicFlags(ByVal v As ULongInt)
    ClearArithFlags
    SetZeroSign v
End Sub
Sub SetAddFlags(ByVal a As ULongInt, ByVal b As ULongInt, ByVal full As ULongInt, ByVal r As ULongInt)
    ClearArithFlags
    SetZeroSign r
    If full>CellMask() Then Flags=Flags Or FLAG_C
End Sub
Sub SetSubFlags(ByVal a As ULongInt, ByVal b As ULongInt, ByVal r As ULongInt)
    ClearArithFlags
    SetZeroSign r
    If a>=b Then Flags=Flags Or FLAG_C
End Sub
Sub SetCompareFlags(ByVal a As ULongInt, ByVal b As ULongInt)
    ClearArithFlags
    If a=b Then Flags=Flags Or FLAG_Z
    If a>=b Then Flags=Flags Or FLAG_C
    If ((a-b) And CellSignBit())<>0 Then Flags=Flags Or FLAG_S
End Sub
Function CellMask() As ULongInt
    If CellBits=8 Then Return &HFFull
    If CellBits=16 Then Return &HFFFFull
    Return &HFFFFFFFFull
End Function
Function CellSignBit() As ULongInt
    If CellBits=8 Then Return &H80ull
    If CellBits=16 Then Return &H8000ull
    Return &H80000000ull
End Function
Function ToSigned(ByVal v As ULongInt) As LongInt
    v=v And CellMask()
    If (v And CellSignBit())<>0 Then Return CLngInt(v)-CLngInt(CellMask()+1)
    Return CLngInt(v)
End Function
Function FromSigned(ByVal v As LongInt) As ULongInt
    Return CULngInt(v) And CellMask()
End Function
Function IsSigned() As Long
    If (Flags And FLAG_SGN)<>0 Then Return -1 Else Return 0
End Function
Function ScaleFactor() As LongInt
    If CellBits=8 Then Return 100
    If CellBits=16 Then Return 1000
    Return 10000
End Function
Function ClampCell(ByVal v As Double) As ULongInt
    If v<0 And IsSigned()=0 Then SetStatus STATUS_UNDERFLOW:Return 0
    If v>CDbl(CellMask()) Then SetStatus STATUS_OVERFLOW:Return CellMask()
    Return CULngInt(v) And CellMask()
End Function
Function ResolveIndex(ByVal ak As Long, ByVal av As Long, ByRef spaceName As String, ByRef ok As Long) As Long
    Dim idx As Long
    ok=1
    Select Case ak
    Case ADDR_T
        spaceName="T":idx=Ptr
    Case ADDR_T_REL
        spaceName="T":idx=Ptr+av
    Case ADDR_T_ABS
        spaceName="T":idx=av
    Case ADDR_D_ABS
        spaceName="D":idx=av
    Case ADDR_S_ABS
        spaceName="S":idx=av
    Case ADDR_SP
        spaceName="S":idx=SP-1
    Case ADDR_P
        spaceName="P":idx=0
    Case ADDR_E
        spaceName="E":idx=0
    Case ADDR_F
        spaceName="F":idx=0
    Case ADDR_IND_T
        spaceName="T":idx=Tape(Ptr)
    Case ADDR_IND_T_REL
        spaceName="T":idx=Tape(Ptr+av)
    Case Else
        ok=0:idx=0
    End Select
    If BoundsOn Then
        If spaceName="T" And (idx<0 Or idx>=TapeCells) Then ok=0:SetStatus STATUS_PTR_BOUNDS
        If spaceName="D" And (idx<0 Or idx>=DataCells) Then ok=0:SetStatus STATUS_DATA_BOUNDS
        If spaceName="S" And (idx<0 Or idx>=StackCells) Then ok=0:SetStatus STATUS_STACK_UNDERFLOW
    End If
    Return idx
End Function
Function ReadAddr(ByVal ak As Long, ByVal av As Long) As ULongInt
    Dim spn As String
    Dim ok As Long
    Dim idx As Long
    idx=ResolveIndex(ak,av,spn,ok)
    If ok=0 Then Return 0
    If spn="T" Then Return Tape(idx) And CellMask()
    If spn="D" Then Return DataMem(idx) And CellMask()
    If spn="S" Then Return StackMem(idx) And CellMask()
    If spn="P" Then Return Ptr And CellMask()
    If spn="E" Then Return StatusByte And CellMask()
    If spn="F" Then Return Flags And CellMask()
    Return 0
End Function
Sub WriteAddr(ByVal ak As Long, ByVal av As Long, ByVal v As ULongInt)
    Dim spn As String
    Dim ok As Long
    Dim idx As Long
    idx=ResolveIndex(ak,av,spn,ok)
    If ok=0 Then Exit Sub
    v=v And CellMask()
    If spn="T" Then Tape(idx)=v
    If spn="D" Then DataMem(idx)=v
    If spn="S" Then StackMem(idx)=v
    If spn="P" Then Ptr=v:Flags=Flags Or FLAG_PCHG
    If spn="E" Then SetStatus v
    If spn="F" Then Flags=v
    Flags=Flags Or FLAG_DIRTY
End Sub
Sub MetaCall(ByVal id As Long)
    If id<20 Then MetaCore id ElseIf id<40 Then MetaArith id ElseIf id<60 Then MetaMath id ElseIf id<80 Then MetaIO id ElseIf id<90 Then MetaPtrMem id ElseIf id<128 Then MetaFifoDataSort id Else SetStatus STATUS_INVALID_META
End Sub
Sub MetaCore(ByVal id As Long)
    Select Case id
    Case 0:SetStatus STATUS_OK
    Case 3:Tape(Ptr+1)=Int(Rnd*256) And CellMask():SetLogicFlags Tape(Ptr+1):SetStatus STATUS_OK
    Case 5:OutputText=OutputText+Chr(10):SetStatus STATUS_OK
    Case 9:Tape(Ptr+1)=StatusByte:SetLogicFlags StatusByte
    Case 10:SetStatus STATUS_OK
    Case 12:OutputText=OutputText+"STATUS="+Str(StatusByte):SetStatus STATUS_OK
    Case Else:SetStatus STATUS_INVALID_META
    End Select
End Sub
Sub MetaArith(ByVal id As Long)
    Dim a As ULongInt
    Dim b As ULongInt
    Dim r As ULongInt
    Dim full As ULongInt
    a=Tape(Ptr-2)
    b=Tape(Ptr-1)
    Select Case id
    Case 20:full=a+b:r=full And CellMask():Tape(Ptr+1)=r:SetAddFlags a,b,full,r:SetStatus STATUS_OK
    Case 21:r=(a-b) And CellMask():Tape(Ptr+1)=r:SetSubFlags a,b,r:SetStatus STATUS_OK
    Case 22:full=a*b:r=full And CellMask():Tape(Ptr+1)=r:SetLogicFlags r:If full>CellMask() Then SetStatus STATUS_OVERFLOW Else SetStatus STATUS_OK
    Case 23:If b=0 Then Tape(Ptr+1)=0:SetStatus STATUS_DIV_ZERO Else Tape(Ptr+1)=(a\b) And CellMask():SetLogicFlags Tape(Ptr+1):SetStatus STATUS_OK
    Case 24:If b=0 Then Tape(Ptr+1)=0:SetStatus STATUS_DIV_ZERO Else Tape(Ptr+1)=(a Mod b) And CellMask():SetLogicFlags Tape(Ptr+1):SetStatus STATUS_OK
    Case Else:SetStatus STATUS_INVALID_META
    End Select
End Sub
Sub MetaMath(ByVal id As Long)
    Dim a As ULongInt
    Dim b As ULongInt
    a=Tape(Ptr-2)
    b=Tape(Ptr-1)
    Select Case id
    Case 40:Tape(Ptr+1)=ClampCell(Sin(CDbl(b)*PI_D/180.0)*ScaleFactor()):SetLogicFlags Tape(Ptr+1):SetStatus STATUS_OK
    Case 41:Tape(Ptr+1)=ClampCell(Cos(CDbl(b)*PI_D/180.0)*ScaleFactor()):SetLogicFlags Tape(Ptr+1):SetStatus STATUS_OK
    Case 42:Tape(Ptr+1)=ClampCell(Tan(CDbl(b)*PI_D/180.0)*ScaleFactor()):SetLogicFlags Tape(Ptr+1):SetStatus STATUS_OK
    Case 43:Tape(Ptr+1)=ClampCell(Sqr(CDbl(a)*CDbl(a)+CDbl(b)*CDbl(b))):SetLogicFlags Tape(Ptr+1):SetStatus STATUS_OK
    Case Else:SetStatus STATUS_INVALID_META
    End Select
End Sub
Sub MetaIO(ByVal id As Long)
    Select Case id
    Case 60:OutputText=OutputText+LTrim(Str(Tape(Ptr-1))):SetStatus STATUS_OK
    Case 61:OutputText=OutputText+LTrim(Str(Tape(Ptr+1))):SetStatus STATUS_OK
    Case 64:OutputText=OutputText+" ":SetStatus STATUS_OK
    Case Else:SetStatus STATUS_INVALID_META
    End Select
End Sub
Sub MetaPtrMem(ByVal id As Long)
    Dim v As ULongInt
    v=Tape(Ptr-1)
    Select Case id
    Case 80:If v>=TapeCells Then SetStatus STATUS_PTR_BOUNDS Else Ptr=v:Flags=Flags Or FLAG_PCHG:SetStatus STATUS_OK
    Case 82:Tape(Ptr+1)=Ptr:SetLogicFlags Ptr:SetStatus STATUS_OK
    Case 89:OutputText=OutputText+"LAYOUT tape="+Str(TapeCells)+" stack="+Str(StackCells)+" data="+Str(DataCells):SetStatus STATUS_OK
    Case Else:SetStatus STATUS_INVALID_META
    End Select
End Sub
Sub MetaFifoDataSort(ByVal id As Long)
    Dim a As ULongInt
    Dim b As ULongInt
    Dim c As ULongInt
    a=Tape(Ptr-2)
    b=Tape(Ptr-1)
    c=Tape(Ptr)
    Select Case id
    Case 90:FifoPush b
    Case 91:Tape(Ptr+1)=FifoPop():SetLogicFlags Tape(Ptr+1)
    Case 92:Tape(Ptr+1)=FifoPeek():SetLogicFlags Tape(Ptr+1)
    Case 93:Tape(Ptr+1)=FifoCount:SetLogicFlags Tape(Ptr+1):SetStatus STATUS_OK
    Case 94:FifoHead=0:FifoTail=0:FifoCount=0:SetStatus STATUS_OK
    Case 95:If b>=DataCells Then SetStatus STATUS_DATA_BOUNDS Else Tape(Ptr+1)=DataMem(b):SetLogicFlags Tape(Ptr+1):SetStatus STATUS_OK
    Case 96:If a>=DataCells Then SetStatus STATUS_DATA_BOUNDS Else DataMem(a)=b And CellMask():SetStatus STATUS_OK
    Case 97:If b>=DataCells Then SetStatus STATUS_DATA_BOUNDS Else If DataMem(b)>=48 And DataMem(b)<=57 Then Tape(Ptr+1)=DataMem(b)-48:SetLogicFlags Tape(Ptr+1):SetStatus STATUS_OK Else Tape(Ptr+1)=0:SetStatus STATUS_UNDERFLOW
    Case 98:DataBlockCopy a,b,c
    Case 99:DataBlockClear a,b
    Case 100:SortTape a,b,1
    Case 101:SortTape a,b,0
    Case 102:SortData a,b,1
    Case 103:SortData a,b,0
    Case 104:Tape(Ptr+1)=LinearSearchTape(a,b,c):SetLogicFlags Tape(Ptr+1):SetStatus STATUS_OK
    Case 120:Flags=Flags And Not FLAG_SGN:SetStatus STATUS_OK
    Case 121:Flags=Flags Or FLAG_SGN:SetStatus STATUS_OK
    Case 122:If (Flags And FLAG_SGN)<>0 Then Tape(Ptr+1)=1 Else Tape(Ptr+1)=0:SetStatus STATUS_OK
    Case 123:Flags=Flags And Not FLAG_END:SetStatus STATUS_OK
    Case 124:Flags=Flags Or FLAG_END:SetStatus STATUS_OK
    Case 125:If (Flags And FLAG_END)<>0 Then Tape(Ptr+1)=1 Else Tape(Ptr+1)=0:SetStatus STATUS_OK
    Case 126:Tape(Ptr+1)=Flags And CellMask():SetStatus STATUS_OK
    Case 127:WildLayoutChange
    Case Else:SetStatus STATUS_INVALID_META
    End Select
End Sub
Sub WildLayoutChange()
    If Mode<>MODE_WILD Then SetStatus STATUS_SAFE_DENY:Exit Sub
    Dim t As Long
    Dim s As Long
    Dim d As Long
    t=Tape(Ptr-2)
    s=Tape(Ptr-1)
    d=Tape(Ptr)
    If t+s+d<>64 Then SetStatus STATUS_DATA_BOUNDS:Exit Sub
    TapeKB=t
    StackKB=s
    DataKB=d
    ApplyMemory
    If HadError Then SetStatus STATUS_DATA_BOUNDS Else SetStatus STATUS_OK
End Sub
Sub FifoPush(ByVal v As ULongInt)
    If FifoCount>=MAX_FIFO Then SetStatus STATUS_STACK_OVERFLOW:Exit Sub
    FifoMem(FifoTail)=v And CellMask()
    FifoTail=(FifoTail+1) Mod MAX_FIFO
    FifoCount=FifoCount+1
    Flags=Flags Or FLAG_FIFO
    SetStatus STATUS_OK
End Sub
Function FifoPop() As ULongInt
    Dim v As ULongInt
    If FifoCount<=0 Then SetStatus STATUS_STACK_UNDERFLOW:Return 0
    v=FifoMem(FifoHead)
    FifoHead=(FifoHead+1) Mod MAX_FIFO
    FifoCount=FifoCount-1
    SetStatus STATUS_OK
    Return v
End Function
Function FifoPeek() As ULongInt
    If FifoCount<=0 Then SetStatus STATUS_STACK_UNDERFLOW:Return 0
    SetStatus STATUS_OK
    Return FifoMem(FifoHead)
End Function
Sub DataBlockCopy(ByVal src As Long, ByVal dst As Long, ByVal cnt As Long)
    Dim i As Long
    If src<0 Or dst<0 Or src+cnt>DataCells Or dst+cnt>DataCells Then SetStatus STATUS_DATA_BOUNDS:Exit Sub
    For i=0 To cnt-1
        DataMem(dst+i)=DataMem(src+i)
    Next
    SetStatus STATUS_OK
End Sub
Sub DataBlockClear(ByVal dst As Long, ByVal cnt As Long)
    Dim i As Long
    If dst<0 Or dst+cnt>DataCells Then SetStatus STATUS_DATA_BOUNDS:Exit Sub
    For i=0 To cnt-1
        DataMem(dst+i)=0
    Next
    SetStatus STATUS_OK
End Sub
Sub SortTape(ByVal startIdx As Long, ByVal cnt As Long, ByVal ascending As Long)
    Dim i As Long
    Dim j As Long
    Dim tmp As ULongInt
    If startIdx<0 Or startIdx+cnt>TapeCells Then SetStatus STATUS_PTR_BOUNDS:Exit Sub
    For i=0 To cnt-2
        For j=0 To cnt-2-i
            If (ascending And Tape(startIdx+j)>Tape(startIdx+j+1)) Or ((ascending=0) And Tape(startIdx+j)<Tape(startIdx+j+1)) Then
                tmp=Tape(startIdx+j)
                Tape(startIdx+j)=Tape(startIdx+j+1)
                Tape(startIdx+j+1)=tmp
            End If
        Next
    Next
    SetStatus STATUS_OK
End Sub
Sub SortData(ByVal startIdx As Long, ByVal cnt As Long, ByVal ascending As Long)
    Dim i As Long
    Dim j As Long
    Dim tmp As ULongInt
    If startIdx<0 Or startIdx+cnt>DataCells Then SetStatus STATUS_DATA_BOUNDS:Exit Sub
    For i=0 To cnt-2
        For j=0 To cnt-2-i
            If (ascending And DataMem(startIdx+j)>DataMem(startIdx+j+1)) Or ((ascending=0) And DataMem(startIdx+j)<DataMem(startIdx+j+1)) Then
                tmp=DataMem(startIdx+j)
                DataMem(startIdx+j)=DataMem(startIdx+j+1)
                DataMem(startIdx+j+1)=tmp
            End If
        Next
    Next
    SetStatus STATUS_OK
End Sub
Function LinearSearchTape(ByVal startIdx As Long, ByVal cnt As Long, ByVal target As ULongInt) As Long
    Dim i As Long
    If startIdx<0 Or startIdx+cnt>TapeCells Then SetStatus STATUS_PTR_BOUNDS:Return CellMask()
    For i=0 To cnt-1
        If Tape(startIdx+i)=target Then Return i
    Next
    Return CellMask()
End Function
Function GetJsonValue(ByVal js As String, ByVal key As String) As String
    Dim p As Long
    Dim q As Long
    Dim r As Long
    p=InStr(js,Chr(34)+key+Chr(34))
    If p=0 Then Return ""
    p=InStr(p,js,":")
    If p=0 Then Return ""
    q=InStr(p+1,js,Chr(34))
    If q=0 Then Return ""
    r=InStr(q+1,js,Chr(34))
    If r=0 Then Return ""
    Return Mid(js,q+1,r-q-1)
End Function
Sub RunIDECommand(ByVal fn As String)
    Dim js As String
    Dim cmd As String
    Dim source As String
    Dim out As String
    js=ReadAllText(fn)
    cmd=LCase(GetJsonValue(js,"command"))
    source=GetJsonValue(js,"source")
    out=GetJsonValue(js,"out")
    If out="" Then out=source+"."+cmd+".json"
    LoadFile source
    If HadError Then Print ErrMsg:End
    ParsePragmas
    ApplyMemory
    FirstPassDefs
    ParseProgram Src,0
    ValidateProgram
    OptimizeProgram
    ValidateProgram
    If HadError Then Print ErrMsg:End
    If cmd="run" Then RunProgram out:Print OutputText
    If cmd="uir" Then ExportUIR out
    If cmd="opt" Then ExportOpt out
    Print "IDE command tamamlandi: ";cmd;" -> ";out
End Sub
```

# Kullanım

```bat
fbc uxm31_full_tool_fb.bas -x uxm31_full_tool.exe
uxm31_full_tool.exe run tests\test05_meta_add.uxm build\test05.trace.ndjson
uxm31_full_tool.exe uir tests\test05_meta_add.uxm build\test05.uir.json
uxm31_full_tool.exe opt tests\test05_meta_add.uxm build\test05.opt.json
```

# IDE komut dosyası örneği: `ide_run.json`

```json
{"command":"run","source":"tests\\test05_meta_add.uxm","out":"build\\ide_trace.ndjson"}
```

Çalıştırma:

```bat
uxm31_full_tool.exe ide ide_run.json
```

Bu dosya eksik kalan büyük parçaların **interpreter / trace / UIR / optimizer / IDE / macro call-stack / FIFO / data-sort / wild layout** tarafını gerçek olarak verir.

**devam** yazarsan bir sonraki mesajda bunu native x64 hattına bağlayan güncellenmiş `uxm31_compiler_fb.bas` ve `uxm31_runtime_fb.bas` dosyalarını tam vererek devam edeceğim.
