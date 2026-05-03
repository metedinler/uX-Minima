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

# Dosya: `uxm31_runtime_fb_full.bas`

```freebasic
Option Explicit
#Lang "fb"
Extern "C"
Declare Sub uxm_entry()
Declare Sub ux_putc(ByVal ch As ULongInt)
Declare Function ux_getc() As ULongInt
Declare Sub ux_print_data_string(ByVal startCell As ULongInt, ByVal cellBits As ULongInt)
Declare Sub ux_meta_call_ex(ByVal metaId As ULongInt, ByVal memPtr As UByte Ptr)
Declare Sub ux_runtime_error(ByVal code As ULongInt)
Extern ux_mem As UByte
Extern ux_status As UByte
Extern ux_flags As UShort
Extern ux_ptr As ULongInt
Extern ux_sp As ULongInt
Extern ux_cell_bits As ULong
Extern ux_cell_bytes As ULong
Extern ux_tape_cells As ULong
Extern ux_stack_cells As ULong
Extern ux_data_cells As ULong
Extern ux_stack_offset As ULong
Extern ux_data_offset As ULong
End Extern
Const FLAG_Z As UShort=&H0001
Const FLAG_C As UShort=&H0002
Const FLAG_O As UShort=&H0004
Const FLAG_S As UShort=&H0008
Const FLAG_SGN As UShort=&H0010
Const FLAG_END As UShort=&H0020
Const FLAG_WILD As UShort=&H0040
Const FLAG_BND As UShort=&H0080
Const FLAG_TRC As UShort=&H0100
Const FLAG_FIFO As UShort=&H0200
Const FLAG_ERR As UShort=&H0400
Const FLAG_DIRTY As UShort=&H0800
Const FLAG_PCHG As UShort=&H1000
Const STATUS_OK As UByte=0
Const STATUS_INVALID_META As UByte=5
Const STATUS_PTR_BOUNDS As UByte=10
Const STATUS_STACK_OVERFLOW As UByte=11
Const STATUS_STACK_UNDERFLOW As UByte=12
Const STATUS_OVERFLOW As UByte=13
Const STATUS_UNDERFLOW As UByte=14
Const STATUS_DIV_ZERO As UByte=15
Const STATUS_DATA_BOUNDS As UByte=16
Const STATUS_SAFE_DENY As UByte=23
Const STATUS_PROTECTED_META As UByte=24
Const STATUS_EOF As UByte=26
Const PI_D As Double=3.1415926535897932384626433832795
Const FIFO_MAX As ULongInt=65536
Dim Shared fifoMem(0 To 65535) As ULongInt
Dim Shared fifoHead As ULongInt
Dim Shared fifoTail As ULongInt
Dim Shared fifoCount As ULongInt
Declare Function MemBase() As UByte Ptr
Declare Function TapeBase() As UByte Ptr
Declare Function StackBase() As UByte Ptr
Declare Function DataBase() As UByte Ptr
Declare Function CellMask() As ULongInt
Declare Function CellSignBit() As ULongInt
Declare Function CellMaxSigned() As LongInt
Declare Function CellMinSigned() As LongInt
Declare Function CellBytes() As ULong
Declare Function ReadCell(ByVal basePtr As UByte Ptr, ByVal cellIndex As ULongInt) As ULongInt
Declare Sub WriteCell(ByVal basePtr As UByte Ptr, ByVal cellIndex As ULongInt, ByVal value As ULongInt)
Declare Function ReadTape(ByVal cellIndex As LongInt) As ULongInt
Declare Sub WriteTape(ByVal cellIndex As LongInt, ByVal value As ULongInt)
Declare Function ReadData(ByVal cellIndex As LongInt) As ULongInt
Declare Sub WriteData(ByVal cellIndex As LongInt, ByVal value As ULongInt)
Declare Function ReadTapeRel(ByVal rel As LongInt) As ULongInt
Declare Sub WriteTapeRel(ByVal rel As LongInt, ByVal value As ULongInt)
Declare Function ToSignedValue(ByVal value As ULongInt) As LongInt
Declare Function FromSignedValue(ByVal value As LongInt) As ULongInt
Declare Function IsSignedMode() As Long
Declare Function IsBigEndian() As Long
Declare Function IsWildMode() As Long
Declare Sub SetStatus(ByVal code As UByte)
Declare Sub ClearArithFlags()
Declare Sub SetZeroSignFlags(ByVal value As ULongInt)
Declare Sub SetLogicFlags(ByVal resultMasked As ULongInt)
Declare Sub SetAddFlags(ByVal a As ULongInt, ByVal b As ULongInt, ByVal resultFull As ULongInt, ByVal resultMasked As ULongInt)
Declare Sub SetSubFlags(ByVal a As ULongInt, ByVal b As ULongInt, ByVal resultMasked As ULongInt)
Declare Sub SetMulFlags(ByVal a As ULongInt, ByVal b As ULongInt, ByVal resultFull As ULongInt, ByVal resultMasked As ULongInt)
Declare Sub SetCompareFlags(ByVal a As ULongInt, ByVal b As ULongInt)
Declare Function Arg1() As ULongInt
Declare Function Arg2() As ULongInt
Declare Function Arg0() As ULongInt
Declare Sub SetResult(ByVal value As ULongInt)
Declare Function ResultValue() As ULongInt
Declare Function StackRead(ByVal idx As ULongInt) As ULongInt
Declare Sub StackWrite(ByVal idx As ULongInt, ByVal value As ULongInt)
Declare Sub StackPush(ByVal value As ULongInt)
Declare Function StackPop() As ULongInt
Declare Sub FifoPush(ByVal value As ULongInt)
Declare Function FifoPop() As ULongInt
Declare Function FifoPeek() As ULongInt
Declare Sub FifoClear()
Declare Sub PrintStatusMessage(ByVal code As ULongInt)
Declare Function ScaleFactor() As LongInt
Declare Function SinScaled(ByVal degree As Double) As LongInt
Declare Function CosScaled(ByVal degree As Double) As LongInt
Declare Function TanScaled(ByVal degree As Double) As LongInt
Declare Function SinhLocal(ByVal x As Double) As Double
Declare Function CoshLocal(ByVal x As Double) As Double
Declare Function TanhLocal(ByVal x As Double) As Double
Declare Function AsinLocal(ByVal x As Double) As Double
Declare Function AcosLocal(ByVal x As Double) As Double
Declare Function AsinhLocal(ByVal x As Double) As Double
Declare Function AcoshLocal(ByVal x As Double) As Double
Declare Function AtanhLocal(ByVal x As Double) As Double
Declare Function RandomByte() As ULongInt
Declare Sub PrintDecimalValue(ByVal value As ULongInt)
Declare Function ReadDecimalValue() As ULongInt
Declare Function ClampToCell(ByVal v As LongInt) As ULongInt
Declare Function ClampDoubleToCell(ByVal v As Double) As ULongInt
Declare Sub DataBlockCopy(ByVal src As LongInt, ByVal dst As LongInt, ByVal count As LongInt)
Declare Sub DataBlockClear(ByVal dst As LongInt, ByVal count As LongInt)
Declare Sub TapeBlockCopy(ByVal src As LongInt, ByVal dst As LongInt, ByVal count As LongInt)
Declare Sub TapeBlockClear(ByVal dst As LongInt, ByVal count As LongInt)
Declare Sub SortTape(ByVal startIdx As LongInt, ByVal count As LongInt, ByVal ascending As Long)
Declare Sub SortData(ByVal startIdx As LongInt, ByVal count As LongInt, ByVal ascending As Long)
Declare Function LinearSearchTape(ByVal startIdx As LongInt, ByVal count As LongInt, ByVal target As ULongInt) As LongInt
Declare Function LinearSearchData(ByVal startIdx As LongInt, ByVal count As LongInt, ByVal target As ULongInt) As LongInt
Declare Sub WildLayoutChange()
Declare Sub MetaCore(ByVal metaId As ULongInt)
Declare Sub MetaArithmetic(ByVal metaId As ULongInt)
Declare Sub MetaMath(ByVal metaId As ULongInt)
Declare Sub MetaIO(ByVal metaId As ULongInt)
Declare Sub MetaPointerMemory(ByVal metaId As ULongInt)
Declare Sub MetaFifoDataSortWild(ByVal metaId As ULongInt)
Function MemBase() As UByte Ptr
Return @ux_mem
End Function
Function TapeBase() As UByte Ptr
Return @ux_mem
End Function
Function StackBase() As UByte Ptr
Return @ux_mem+ux_stack_offset
End Function
Function DataBase() As UByte Ptr
Return @ux_mem+ux_data_offset
End Function
Function CellBytes() As ULong
Select Case ux_cell_bits
Case 8
Return 1
Case 16
Return 2
Case 32
Return 4
Case Else
Return 1
End Select
End Function
Function CellMask() As ULongInt
Select Case ux_cell_bits
Case 8
Return &HFFull
Case 16
Return &HFFFFull
Case 32
Return &HFFFFFFFFull
Case Else
Return &HFFull
End Select
End Function
Function CellSignBit() As ULongInt
Select Case ux_cell_bits
Case 8
Return &H80ull
Case 16
Return &H8000ull
Case 32
Return &H80000000ull
Case Else
Return &H80ull
End Select
End Function
Function CellMaxSigned() As LongInt
Select Case ux_cell_bits
Case 8
Return 127
Case 16
Return 32767
Case 32
Return 2147483647
Case Else
Return 127
End Select
End Function
Function CellMinSigned() As LongInt
Select Case ux_cell_bits
Case 8
Return -128
Case 16
Return -32768
Case 32
Return -2147483648
Case Else
Return -128
End Select
End Function
Function ReadCell(ByVal basePtr As UByte Ptr, ByVal cellIndex As ULongInt) As ULongInt
Select Case ux_cell_bits
Case 8
Return CULngInt(basePtr[cellIndex])
Case 16
Return CULngInt(*Cast(UShort Ptr,basePtr+cellIndex*2))
Case 32
Return CULngInt(*Cast(ULong Ptr,basePtr+cellIndex*4))
Case Else
Return CULngInt(basePtr[cellIndex])
End Select
End Function
Sub WriteCell(ByVal basePtr As UByte Ptr, ByVal cellIndex As ULongInt, ByVal value As ULongInt)
value=value And CellMask()
Select Case ux_cell_bits
Case 8
basePtr[cellIndex]=CUByte(value And &HFF)
Case 16
*Cast(UShort Ptr,basePtr+cellIndex*2)=CUShort(value And &HFFFF)
Case 32
*Cast(ULong Ptr,basePtr+cellIndex*4)=CULng(value And &HFFFFFFFF)
Case Else
basePtr[cellIndex]=CUByte(value And &HFF)
End Select
ux_flags=ux_flags Or FLAG_DIRTY
End Sub
Function ReadTape(ByVal cellIndex As LongInt) As ULongInt
If cellIndex<0 Or cellIndex>=CLngInt(ux_tape_cells) Then
SetStatus STATUS_PTR_BOUNDS
Return 0
End If
Return ReadCell(TapeBase(),CULngInt(cellIndex))
End Function
Sub WriteTape(ByVal cellIndex As LongInt, ByVal value As ULongInt)
If cellIndex<0 Or cellIndex>=CLngInt(ux_tape_cells) Then
SetStatus STATUS_PTR_BOUNDS
Exit Sub
End If
WriteCell TapeBase(),CULngInt(cellIndex),value
End Sub
Function ReadData(ByVal cellIndex As LongInt) As ULongInt
If cellIndex<0 Or cellIndex>=CLngInt(ux_data_cells) Then
SetStatus STATUS_DATA_BOUNDS
Return 0
End If
Return ReadCell(DataBase(),CULngInt(cellIndex))
End Function
Sub WriteData(ByVal cellIndex As LongInt, ByVal value As ULongInt)
If cellIndex<0 Or cellIndex>=CLngInt(ux_data_cells) Then
SetStatus STATUS_DATA_BOUNDS
Exit Sub
End If
WriteCell DataBase(),CULngInt(cellIndex),value
End Sub
Function ReadTapeRel(ByVal rel As LongInt) As ULongInt
Return ReadTape(CLngInt(ux_ptr)+rel)
End Function
Sub WriteTapeRel(ByVal rel As LongInt, ByVal value As ULongInt)
WriteTape CLngInt(ux_ptr)+rel,value
End Sub
Function ToSignedValue(ByVal value As ULongInt) As LongInt
value=value And CellMask()
If (value And CellSignBit())<>0 Then
Return CLngInt(value)-CLngInt(CellMask()+1)
Else
Return CLngInt(value)
End If
End Function
Function FromSignedValue(ByVal value As LongInt) As ULongInt
Return CULngInt(value) And CellMask()
End Function
Function IsSignedMode() As Long
If (ux_flags And FLAG_SGN)<>0 Then Return -1 Else Return 0
End Function
Function IsBigEndian() As Long
If (ux_flags And FLAG_END)<>0 Then Return -1 Else Return 0
End Function
Function IsWildMode() As Long
If (ux_flags And FLAG_WILD)<>0 Then Return -1 Else Return 0
End Function
Sub SetStatus(ByVal code As UByte)
ux_status=code
If code=0 Then
ux_flags=ux_flags And Not FLAG_ERR
Else
ux_flags=ux_flags Or FLAG_ERR
End If
End Sub
Sub ClearArithFlags()
ux_flags=ux_flags And Not (FLAG_Z Or FLAG_C Or FLAG_O Or FLAG_S)
End Sub
Sub SetZeroSignFlags(ByVal value As ULongInt)
ux_flags=ux_flags And Not (FLAG_Z Or FLAG_S)
value=value And CellMask()
If value=0 Then ux_flags=ux_flags Or FLAG_Z
If (value And CellSignBit())<>0 Then ux_flags=ux_flags Or FLAG_S
End Sub
Sub SetLogicFlags(ByVal resultMasked As ULongInt)
ClearArithFlags()
SetZeroSignFlags resultMasked
End Sub
Sub SetAddFlags(ByVal a As ULongInt, ByVal b As ULongInt, ByVal resultFull As ULongInt, ByVal resultMasked As ULongInt)
Dim sa As LongInt
Dim sb As LongInt
Dim sr As LongInt
ClearArithFlags()
SetZeroSignFlags resultMasked
If resultFull>CellMask() Then ux_flags=ux_flags Or FLAG_C
sa=ToSignedValue(a)
sb=ToSignedValue(b)
sr=ToSignedValue(resultMasked)
If ((sa>=0 And sb>=0 And sr<0) Or (sa<0 And sb<0 And sr>=0)) Then ux_flags=ux_flags Or FLAG_O
End Sub
Sub SetSubFlags(ByVal a As ULongInt, ByVal b As ULongInt, ByVal resultMasked As ULongInt)
Dim sa As LongInt
Dim sb As LongInt
Dim sr As LongInt
ClearArithFlags()
SetZeroSignFlags resultMasked
If a>=b Then ux_flags=ux_flags Or FLAG_C
sa=ToSignedValue(a)
sb=ToSignedValue(b)
sr=ToSignedValue(resultMasked)
If ((sa>=0 And sb<0 And sr<0) Or (sa<0 And sb>=0 And sr>=0)) Then ux_flags=ux_flags Or FLAG_O
End Sub
Sub SetMulFlags(ByVal a As ULongInt, ByVal b As ULongInt, ByVal resultFull As ULongInt, ByVal resultMasked As ULongInt)
ClearArithFlags()
SetZeroSignFlags resultMasked
If resultFull>CellMask() Then ux_flags=ux_flags Or FLAG_C Or FLAG_O
End Sub
Sub SetCompareFlags(ByVal a As ULongInt, ByVal b As ULongInt)
Dim r As ULongInt
r=(a-b) And CellMask()
ClearArithFlags()
If a=b Then ux_flags=ux_flags Or FLAG_Z
If a>=b Then ux_flags=ux_flags Or FLAG_C
If (r And CellSignBit())<>0 Then ux_flags=ux_flags Or FLAG_S
End Sub
Function Arg1() As ULongInt
Return ReadTape(CLngInt(ux_ptr)-2)
End Function
Function Arg2() As ULongInt
Return ReadTape(CLngInt(ux_ptr)-1)
End Function
Function Arg0() As ULongInt
Return ReadTape(CLngInt(ux_ptr))
End Function
Sub SetResult(ByVal value As ULongInt)
WriteTape CLngInt(ux_ptr)+1,value
End Sub
Function ResultValue() As ULongInt
Return ReadTape(CLngInt(ux_ptr)+1)
End Function
Function StackRead(ByVal idx As ULongInt) As ULongInt
If idx>=ux_stack_cells Then
SetStatus STATUS_STACK_UNDERFLOW
Return 0
End If
Return ReadCell(StackBase(),idx)
End Function
Sub StackWrite(ByVal idx As ULongInt, ByVal value As ULongInt)
If idx>=ux_stack_cells Then
SetStatus STATUS_STACK_OVERFLOW
Exit Sub
End If
WriteCell StackBase(),idx,value
End Sub
Sub StackPush(ByVal value As ULongInt)
If ux_sp>=ux_stack_cells Then
SetStatus STATUS_STACK_OVERFLOW
Exit Sub
End If
StackWrite ux_sp,value
ux_sp=ux_sp+1
SetStatus STATUS_OK
End Sub
Function StackPop() As ULongInt
If ux_sp=0 Then
SetStatus STATUS_STACK_UNDERFLOW
Return 0
End If
ux_sp=ux_sp-1
SetStatus STATUS_OK
Return StackRead(ux_sp)
End Function
Sub FifoPush(ByVal value As ULongInt)
If fifoCount>=FIFO_MAX Then
SetStatus STATUS_STACK_OVERFLOW
Exit Sub
End If
fifoMem(fifoTail)=value And CellMask()
fifoTail=(fifoTail+1) Mod FIFO_MAX
fifoCount=fifoCount+1
ux_flags=ux_flags Or FLAG_FIFO
SetStatus STATUS_OK
End Sub
Function FifoPop() As ULongInt
Dim v As ULongInt
If fifoCount=0 Then
SetStatus STATUS_STACK_UNDERFLOW
Return 0
End If
v=fifoMem(fifoHead)
fifoHead=(fifoHead+1) Mod FIFO_MAX
fifoCount=fifoCount-1
SetStatus STATUS_OK
Return v
End Function
Function FifoPeek() As ULongInt
If fifoCount=0 Then
SetStatus STATUS_STACK_UNDERFLOW
Return 0
End If
SetStatus STATUS_OK
Return fifoMem(fifoHead)
End Function
Sub FifoClear()
fifoHead=0
fifoTail=0
fifoCount=0
SetStatus STATUS_OK
End Sub
Sub PrintStatusMessage(ByVal code As ULongInt)
Select Case code
Case 0
Print "OK"
Case 5
Print "Invalid meta id"
Case 10
Print "Pointer out of bounds"
Case 11
Print "Stack overflow"
Case 12
Print "Stack underflow"
Case 13
Print "Arithmetic overflow"
Case 14
Print "Arithmetic underflow"
Case 15
Print "Division by zero"
Case 16
Print "Data bounds error"
Case 23
Print "Operation denied outside wild mode"
Case 24
Print "Protected meta id"
Case 26
Print "EOF"
Case Else
Print "Unknown status"
End Select
End Sub
Function ScaleFactor() As LongInt
Select Case ux_cell_bits
Case 8
Return 100
Case 16
Return 1000
Case 32
Return 10000
Case Else
Return 100
End Select
End Function
Function SinScaled(ByVal degree As Double) As LongInt
Return CLngInt(Sin(degree*PI_D/180.0)*ScaleFactor())
End Function
Function CosScaled(ByVal degree As Double) As LongInt
Return CLngInt(Cos(degree*PI_D/180.0)*ScaleFactor())
End Function
Function TanScaled(ByVal degree As Double) As LongInt
Return CLngInt(Tan(degree*PI_D/180.0)*ScaleFactor())
End Function
Function SinhLocal(ByVal x As Double) As Double
Return (Exp(x)-Exp(-x))/2.0
End Function
Function CoshLocal(ByVal x As Double) As Double
Return (Exp(x)+Exp(-x))/2.0
End Function
Function TanhLocal(ByVal x As Double) As Double
Dim c As Double
c=CoshLocal(x)
If c=0.0 Then Return 0.0
Return SinhLocal(x)/c
End Function
Function AsinLocal(ByVal x As Double) As Double
If x>=1.0 Then Return PI_D/2.0
If x<=-1.0 Then Return -PI_D/2.0
Return Atn(x/Sqr(1.0-x*x))
End Function
Function AcosLocal(ByVal x As Double) As Double
Return PI_D/2.0-AsinLocal(x)
End Function
Function AsinhLocal(ByVal x As Double) As Double
Return Log(x+Sqr(x*x+1.0))
End Function
Function AcoshLocal(ByVal x As Double) As Double
If x<1.0 Then Return 0.0
Return Log(x+Sqr(x*x-1.0))
End Function
Function AtanhLocal(ByVal x As Double) As Double
If x>=1.0 Or x<=-1.0 Then Return 0.0
Return 0.5*Log((1.0+x)/(1.0-x))
End Function
Function RandomByte() As ULongInt
Return CULngInt(Int(Rnd*256)) And &HFF
End Function
Sub PrintDecimalValue(ByVal value As ULongInt)
If IsSignedMode() Then
Print LTrim(Str(ToSignedValue(value)));
Else
Print LTrim(Str(value And CellMask()));
End If
End Sub
Function ReadDecimalValue() As ULongInt
Dim s As String
Line Input s
If IsSignedMode() Then
Return FromSignedValue(CLngInt(Val(s)))
Else
Return CULngInt(Val(s)) And CellMask()
End If
End Function
Function ClampToCell(ByVal v As LongInt) As ULongInt
If IsSignedMode() Then
If v>CellMaxSigned() Then
ux_flags=ux_flags Or FLAG_O
SetStatus STATUS_OVERFLOW
v=CellMaxSigned()
ElseIf v<CellMinSigned() Then
ux_flags=ux_flags Or FLAG_O
SetStatus STATUS_UNDERFLOW
v=CellMinSigned()
End If
Return FromSignedValue(v)
Else
If v<0 Then
ux_flags=ux_flags Or FLAG_O
SetStatus STATUS_UNDERFLOW
v=0
ElseIf CULngInt(v)>CellMask() Then
ux_flags=ux_flags Or FLAG_O Or FLAG_C
SetStatus STATUS_OVERFLOW
v=CLngInt(CellMask())
End If
Return CULngInt(v) And CellMask()
End If
End Function
Function ClampDoubleToCell(ByVal v As Double) As ULongInt
If v>CDbl(CellMask()) Then
ux_flags=ux_flags Or FLAG_O Or FLAG_C
SetStatus STATUS_OVERFLOW
Return CellMask()
End If
If v<0 And IsSignedMode()=0 Then
ux_flags=ux_flags Or FLAG_O
SetStatus STATUS_UNDERFLOW
Return 0
End If
Return ClampToCell(CLngInt(v))
End Function
Sub DataBlockCopy(ByVal src As LongInt, ByVal dst As LongInt, ByVal count As LongInt)
Dim i As LongInt
If src<0 Or dst<0 Or count<0 Or src+count>CLngInt(ux_data_cells) Or dst+count>CLngInt(ux_data_cells) Then
SetStatus STATUS_DATA_BOUNDS
Exit Sub
End If
For i=0 To count-1
WriteData dst+i,ReadData(src+i)
Next i
SetStatus STATUS_OK
End Sub
Sub DataBlockClear(ByVal dst As LongInt, ByVal count As LongInt)
Dim i As LongInt
If dst<0 Or count<0 Or dst+count>CLngInt(ux_data_cells) Then
SetStatus STATUS_DATA_BOUNDS
Exit Sub
End If
For i=0 To count-1
WriteData dst+i,0
Next i
SetStatus STATUS_OK
End Sub
Sub TapeBlockCopy(ByVal src As LongInt, ByVal dst As LongInt, ByVal count As LongInt)
Dim i As LongInt
If src<0 Or dst<0 Or count<0 Or src+count>CLngInt(ux_tape_cells) Or dst+count>CLngInt(ux_tape_cells) Then
SetStatus STATUS_PTR_BOUNDS
Exit Sub
End If
For i=0 To count-1
WriteTape dst+i,ReadTape(src+i)
Next i
SetStatus STATUS_OK
End Sub
Sub TapeBlockClear(ByVal dst As LongInt, ByVal count As LongInt)
Dim i As LongInt
If dst<0 Or count<0 Or dst+count>CLngInt(ux_tape_cells) Then
SetStatus STATUS_PTR_BOUNDS
Exit Sub
End If
For i=0 To count-1
WriteTape dst+i,0
Next i
SetStatus STATUS_OK
End Sub
Sub SortTape(ByVal startIdx As LongInt, ByVal count As LongInt, ByVal ascending As Long)
Dim i As LongInt
Dim j As LongInt
Dim a As ULongInt
Dim b As ULongInt
If startIdx<0 Or count<0 Or startIdx+count>CLngInt(ux_tape_cells) Then
SetStatus STATUS_PTR_BOUNDS
Exit Sub
End If
For i=0 To count-2
For j=0 To count-2-i
a=ReadTape(startIdx+j)
b=ReadTape(startIdx+j+1)
If (ascending<>0 And a>b) Or (ascending=0 And a<b) Then
WriteTape startIdx+j,b
WriteTape startIdx+j+1,a
End If
Next j
Next i
SetStatus STATUS_OK
End Sub
Sub SortData(ByVal startIdx As LongInt, ByVal count As LongInt, ByVal ascending As Long)
Dim i As LongInt
Dim j As LongInt
Dim a As ULongInt
Dim b As ULongInt
If startIdx<0 Or count<0 Or startIdx+count>CLngInt(ux_data_cells) Then
SetStatus STATUS_DATA_BOUNDS
Exit Sub
End If
For i=0 To count-2
For j=0 To count-2-i
a=ReadData(startIdx+j)
b=ReadData(startIdx+j+1)
If (ascending<>0 And a>b) Or (ascending=0 And a<b) Then
WriteData startIdx+j,b
WriteData startIdx+j+1,a
End If
Next j
Next i
SetStatus STATUS_OK
End Sub
Function LinearSearchTape(ByVal startIdx As LongInt, ByVal count As LongInt, ByVal target As ULongInt) As LongInt
Dim i As LongInt
If startIdx<0 Or count<0 Or startIdx+count>CLngInt(ux_tape_cells) Then
SetStatus STATUS_PTR_BOUNDS
Return -1
End If
For i=0 To count-1
If ReadTape(startIdx+i)=target Then
SetStatus STATUS_OK
Return i
End If
Next i
SetStatus STATUS_OK
Return -1
End Function
Function LinearSearchData(ByVal startIdx As LongInt, ByVal count As LongInt, ByVal target As ULongInt) As LongInt
Dim i As LongInt
If startIdx<0 Or count<0 Or startIdx+count>CLngInt(ux_data_cells) Then
SetStatus STATUS_DATA_BOUNDS
Return -1
End If
For i=0 To count-1
If ReadData(startIdx+i)=target Then
SetStatus STATUS_OK
Return i
End If
Next i
SetStatus STATUS_OK
Return -1
End Function
Sub WildLayoutChange()
Dim t As ULongInt
Dim s As ULongInt
Dim d As ULongInt
If IsWildMode()=0 Then
SetStatus STATUS_SAFE_DENY
Exit Sub
End If
t=Arg1()
s=Arg2()
d=Arg0()
If t+s+d<>64 Then
SetStatus STATUS_DATA_BOUNDS
Exit Sub
End If
If t=0 Or s=0 Or d=0 Then
SetStatus STATUS_DATA_BOUNDS
Exit Sub
End If
ux_tape_cells=(t*1024)\CellBytes()
ux_stack_cells=(s*1024)\CellBytes()
ux_data_cells=(d*1024)\CellBytes()
ux_stack_offset=t*1024
ux_data_offset=(t+s)*1024
If ux_ptr>=ux_tape_cells Then ux_ptr=0
If ux_sp>=ux_stack_cells Then ux_sp=0
ux_flags=ux_flags Or FLAG_PCHG
SetStatus STATUS_OK
End Sub
Extern "C"
Sub ux_putc(ByVal ch As ULongInt) Export
Print Chr(ch And &HFF);
End Sub
Function ux_getc() As ULongInt Export
Dim s As String
s=Inkey
Do While Len(s)=0
Sleep 10
s=Inkey
Loop
ux_status=0
Return CULngInt(Asc(Left(s,1))) And &HFF
End Function
Sub ux_print_data_string(ByVal startCell As ULongInt, ByVal cellBits As ULongInt) Export
Dim oldBits As ULong
Dim i As ULongInt
Dim v As ULongInt
oldBits=ux_cell_bits
If cellBits=8 Or cellBits=16 Or cellBits=32 Then ux_cell_bits=cellBits
i=startCell
Do
If i>=ux_data_cells Then
SetStatus STATUS_DATA_BOUNDS
Exit Do
End If
v=ReadCell(DataBase(),i)
If v=0 Then Exit Do
Print Chr(v And &HFF);
i=i+1
Loop
ux_cell_bits=oldBits
End Sub
Sub ux_runtime_error(ByVal code As ULongInt) Export
ux_status=code And &HFF
ux_flags=ux_flags Or FLAG_ERR
Print
Print "[UXM runtime error ";Str(code);"] ";
PrintStatusMessage code
End Sub
Sub ux_meta_call_ex(ByVal metaId As ULongInt, ByVal memPtr As UByte Ptr) Export
If metaId<20 Then
MetaCore metaId
ElseIf metaId<40 Then
MetaArithmetic metaId
ElseIf metaId<60 Then
MetaMath metaId
ElseIf metaId<80 Then
MetaIO metaId
ElseIf metaId<90 Then
MetaPointerMemory metaId
ElseIf metaId<128 Then
MetaFifoDataSortWild metaId
Else
SetStatus STATUS_INVALID_META
End If
End Sub
End Extern
Sub MetaCore(ByVal metaId As ULongInt)
Select Case metaId
Case 0
SetStatus STATUS_OK
Case 1
Cls
SetStatus STATUS_OK
Case 2
Locate 1,1
SetStatus STATUS_OK
Case 3
SetResult RandomByte()
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 4
SetResult CULngInt(Timer*1000) And CellMask()
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 5
Print
SetStatus STATUS_OK
Case 6
Print "[UXM META]";
SetStatus STATUS_OK
Case 7
SetResult 7
SetLogicFlags 7
SetStatus STATUS_OK
Case 8
SetResult 8
SetLogicFlags 8
SetStatus STATUS_OK
Case 9
SetResult ux_status
SetLogicFlags ux_status
Case 10
SetStatus STATUS_OK
Case 11
ux_status=Arg1() And &HFF
If ux_status=0 Then ux_flags=ux_flags And Not FLAG_ERR Else ux_flags=ux_flags Or FLAG_ERR
Case 12
PrintStatusMessage ux_status
Case Else
SetStatus STATUS_INVALID_META
End Select
End Sub
Sub MetaArithmetic(ByVal metaId As ULongInt)
Dim a As ULongInt
Dim b As ULongInt
Dim r As ULongInt
Dim full As ULongInt
Dim sf As LongInt
Dim sb As LongInt
a=Arg1()
b=Arg2()
Select Case metaId
Case 20
full=a+b
r=full And CellMask()
SetResult r
SetAddFlags a,b,full,r
SetStatus STATUS_OK
Case 21
r=(a-b) And CellMask()
SetResult r
SetSubFlags a,b,r
SetStatus STATUS_OK
Case 22
full=a*b
r=full And CellMask()
SetResult r
SetMulFlags a,b,full,r
If full>CellMask() Then SetStatus STATUS_OVERFLOW Else SetStatus STATUS_OK
Case 23
If b=0 Then
SetResult 0
ux_flags=ux_flags Or FLAG_O Or FLAG_C Or FLAG_Z Or FLAG_ERR
SetStatus STATUS_DIV_ZERO
Else
If IsSignedMode() Then
sf=ToSignedValue(a)
sb=ToSignedValue(b)
If sb=0 Then
SetResult 0
SetStatus STATUS_DIV_ZERO
Else
r=FromSignedValue(sf\sb)
SetResult r
SetLogicFlags r
SetStatus STATUS_OK
End If
Else
r=(a\b) And CellMask()
SetResult r
SetLogicFlags r
SetStatus STATUS_OK
End If
End If
Case 24
If b=0 Then
SetResult 0
ux_flags=ux_flags Or FLAG_O Or FLAG_C Or FLAG_Z Or FLAG_ERR
SetStatus STATUS_DIV_ZERO
Else
If IsSignedMode() Then
sf=ToSignedValue(a)
sb=ToSignedValue(b)
If sb=0 Then
SetResult 0
SetStatus STATUS_DIV_ZERO
Else
r=FromSignedValue(sf Mod sb)
SetResult r
SetLogicFlags r
SetStatus STATUS_OK
End If
Else
r=(a Mod b) And CellMask()
SetResult r
SetLogicFlags r
SetStatus STATUS_OK
End If
End If
Case 25
If a<b Then r=a Else r=b
SetResult r
SetLogicFlags r
SetStatus STATUS_OK
Case 26
If a>b Then r=a Else r=b
SetResult r
SetLogicFlags r
SetStatus STATUS_OK
Case 27
If IsSignedMode() Then
sf=ToSignedValue(b)
If sf<0 Then sf=-sf
r=FromSignedValue(sf)
Else
r=b
End If
SetResult r
SetLogicFlags r
SetStatus STATUS_OK
Case 28
sf=ToSignedValue(b)
r=FromSignedValue(-sf)
SetResult r
SetLogicFlags r
SetStatus STATUS_OK
Case 29
SetCompareFlags a,b
If a=b Then
r=0
ElseIf a>b Then
r=1
Else
r=CellMask()
End If
SetResult r
SetStatus STATUS_OK
Case 33
If b=0 Then SetResult 0:SetStatus STATUS_DIV_ZERO Else r=(a\b) And CellMask():SetResult r:SetLogicFlags r:SetStatus STATUS_OK
Case 34
If b=0 Then SetResult 0:SetStatus STATUS_DIV_ZERO Else r=FromSignedValue(ToSignedValue(a)\ToSignedValue(b)):SetResult r:SetLogicFlags r:SetStatus STATUS_OK
Case 35
If b=0 Then SetResult 0:SetStatus STATUS_DIV_ZERO Else r=(a Mod b) And CellMask():SetResult r:SetLogicFlags r:SetStatus STATUS_OK
Case 36
If b=0 Then SetResult 0:SetStatus STATUS_DIV_ZERO Else r=FromSignedValue(ToSignedValue(a) Mod ToSignedValue(b)):SetResult r:SetLogicFlags r:SetStatus STATUS_OK
Case Else
SetStatus STATUS_INVALID_META
End Select
End Sub
Sub MetaMath(ByVal metaId As ULongInt)
Dim a As ULongInt
Dim b As ULongInt
Dim x As Double
a=Arg1()
b=Arg2()
Select Case metaId
Case 40
SetResult ClampToCell(SinScaled(CDbl(b)))
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 41
SetResult ClampToCell(CosScaled(CDbl(b)))
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 42
If (b Mod 180)=90 Then
SetResult 0
ux_flags=ux_flags Or FLAG_O
SetStatus STATUS_OVERFLOW
Else
SetResult ClampToCell(TanScaled(CDbl(b)))
SetLogicFlags ResultValue()
SetStatus STATUS_OK
End If
Case 43
SetResult ClampDoubleToCell(Sqr(CDbl(a)*CDbl(a)+CDbl(b)*CDbl(b)))
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 44
x=CDbl(ToSignedValue(b))/CDbl(ScaleFactor())
SetResult ClampToCell(CLngInt(AsinLocal(x)*180.0/PI_D))
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 45
x=CDbl(ToSignedValue(b))/CDbl(ScaleFactor())
SetResult ClampToCell(CLngInt(AcosLocal(x)*180.0/PI_D))
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 46
SetResult ClampDoubleToCell(Sqr(CDbl(b)))
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 47
SetResult ClampDoubleToCell(SinhLocal(CDbl(b)*PI_D/180.0)*ScaleFactor())
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 48
SetResult ClampDoubleToCell(CoshLocal(CDbl(b)*PI_D/180.0)*ScaleFactor())
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 49
SetResult ClampDoubleToCell(TanhLocal(CDbl(b)*PI_D/180.0)*ScaleFactor())
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 52
x=CDbl(ToSignedValue(b))/CDbl(ScaleFactor())
SetResult ClampDoubleToCell(AsinhLocal(x)*ScaleFactor())
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 53
x=CDbl(b)/CDbl(ScaleFactor())
If x<1.0 Then
SetResult 0
SetStatus STATUS_UNDERFLOW
Else
SetResult ClampDoubleToCell(AcoshLocal(x)*ScaleFactor())
SetLogicFlags ResultValue()
SetStatus STATUS_OK
End If
Case 54
x=CDbl(ToSignedValue(b))/CDbl(ScaleFactor())
If Abs(x)>=1.0 Then
SetResult 0
SetStatus STATUS_OVERFLOW
Else
SetResult ClampDoubleToCell(AtanhLocal(x)*ScaleFactor())
SetLogicFlags ResultValue()
SetStatus STATUS_OK
End If
Case 55
If b=0 Then
SetResult 0
SetStatus STATUS_UNDERFLOW
Else
SetResult ClampDoubleToCell(Log(CDbl(b))*ScaleFactor())
SetLogicFlags ResultValue()
SetStatus STATUS_OK
End If
Case 56
SetResult ClampDoubleToCell(Exp(CDbl(ToSignedValue(b))/CDbl(ScaleFactor()))*ScaleFactor())
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 57
SetResult ClampDoubleToCell(CDbl(a)^CDbl(b))
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 58
SetResult ClampDoubleToCell(CDbl(b)*PI_D/180.0*ScaleFactor())
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 59
SetResult ClampDoubleToCell(CDbl(b)/CDbl(ScaleFactor())*180.0/PI_D)
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case Else
SetStatus STATUS_INVALID_META
End Select
End Sub
Sub MetaIO(ByVal metaId As ULongInt)
Select Case metaId
Case 60
PrintDecimalValue Arg2()
SetStatus STATUS_OK
Case 61
PrintDecimalValue ResultValue()
SetStatus STATUS_OK
Case 62
PrintDecimalValue StackPop()
Case 63
SetResult ReadDecimalValue()
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 64
Print " ";
SetStatus STATUS_OK
Case 67
Print Hex(Arg2());
SetStatus STATUS_OK
Case 68
Print Bin(Arg2());
SetStatus STATUS_OK
Case Else
SetStatus STATUS_INVALID_META
End Select
End Sub
Sub MetaPointerMemory(ByVal metaId As ULongInt)
Dim a As ULongInt
a=Arg2()
Select Case metaId
Case 80
If a>=ux_tape_cells Then
SetStatus STATUS_PTR_BOUNDS
Else
ux_ptr=a
ux_flags=ux_flags Or FLAG_PCHG
SetStatus STATUS_OK
End If
Case 81
If ux_ptr+a>=ux_tape_cells Then
SetStatus STATUS_PTR_BOUNDS
Else
ux_ptr=ux_ptr+a
ux_flags=ux_flags Or FLAG_PCHG
SetStatus STATUS_OK
End If
Case 82
SetResult ux_ptr
SetLogicFlags ux_ptr
SetStatus STATUS_OK
Case 83
If ux_ptr<ux_tape_cells Then SetResult 1 Else SetResult 0
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 84
SetResult ux_tape_cells
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 85
SetResult ux_data_cells
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 86
SetResult ux_stack_cells
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 87
SetResult ux_cell_bits
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 88
SetResult ux_cell_bytes
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 89
Print "[UXM layout tape=";ux_tape_cells;" stack=";ux_stack_cells;" data=";ux_data_cells;" cellbits=";ux_cell_bits;"]"
SetStatus STATUS_OK
Case Else
SetStatus STATUS_INVALID_META
End Select
End Sub
Sub MetaFifoDataSortWild(ByVal metaId As ULongInt)
Dim a As ULongInt
Dim b As ULongInt
Dim c As ULongInt
Dim r As LongInt
a=Arg1()
b=Arg2()
c=Arg0()
Select Case metaId
Case 90
FifoPush b
Case 91
SetResult FifoPop()
SetLogicFlags ResultValue()
Case 92
SetResult FifoPeek()
SetLogicFlags ResultValue()
Case 93
SetResult fifoCount
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 94
FifoClear()
Case 95
SetResult ReadData(b)
SetLogicFlags ResultValue()
Case 96
WriteData a,b
SetStatus STATUS_OK
Case 97
b=ReadData(b)
If b>=48 And b<=57 Then
SetResult b-48
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Else
SetResult 0
SetStatus STATUS_UNDERFLOW
End If
Case 98
DataBlockCopy a,b,c
Case 99
DataBlockClear a,b
Case 100
SortTape a,b,1
Case 101
SortTape a,b,0
Case 102
SortData a,b,1
Case 103
SortData a,b,0
Case 104
r=LinearSearchTape(a,b,c)
If r<0 Then SetResult CellMask() Else SetResult CULngInt(r)
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 105
r=LinearSearchData(a,b,c)
If r<0 Then SetResult CellMask() Else SetResult CULngInt(r)
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 106
TapeBlockCopy a,b,c
Case 107
TapeBlockClear a,b
Case 120
ux_flags=ux_flags And Not FLAG_SGN
SetStatus STATUS_OK
Case 121
ux_flags=ux_flags Or FLAG_SGN
SetStatus STATUS_OK
Case 122
If IsSignedMode() Then SetResult 1 Else SetResult 0
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 123
ux_flags=ux_flags And Not FLAG_END
SetStatus STATUS_OK
Case 124
ux_flags=ux_flags Or FLAG_END
SetStatus STATUS_OK
Case 125
If IsBigEndian() Then SetResult 1 Else SetResult 0
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 126
SetResult ux_flags
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 127
WildLayoutChange()
Case Else
SetStatus STATUS_INVALID_META
End Select
End Sub
Randomize Timer
fifoHead=0
fifoTail=0
fifoCount=0
ux_cell_bits=8
ux_cell_bytes=1
ux_tape_cells=32768
ux_stack_cells=8192
ux_data_cells=24576
ux_stack_offset=32768
ux_data_offset=40960
ux_flags=FLAG_BND
ux_status=0
ux_ptr=0
ux_sp=0
uxm_entry()
Print
Print "[UXM program finished]"
If ux_status<>0 Then
Print "Final status: ";ux_status;" ";
PrintStatusMessage ux_status
End If
```

## Bu runtime’daki yeni meta servisler

```text
@90   FIFO push: arg2 = (T-1)
@91   FIFO pop -> (T+1)
@92   FIFO peek -> (T+1)
@93   FIFO count -> (T+1)
@94   FIFO clear
@95   data read: index=(T-1) -> (T+1)
@96   data write: index=(T-2), value=(T-1)
@97   data digit read: index=(T-1), ASCII digit -> sayı
@98   data block copy: src=(T-2), dst=(T-1), count=(T)
@99   data block clear: dst=(T-2), count=(T-1)
@100  tape sort ascending: start=(T-2), count=(T-1)
@101  tape sort descending
@102  data sort ascending
@103  data sort descending
@104  tape linear search: start=(T-2), count=(T-1), target=(T)
@105  data linear search
@106  tape block copy: src=(T-2), dst=(T-1), count=(T)
@107  tape block clear: dst=(T-2), count=(T-1)
@120  unsigned mode
@121  signed mode
@122  signed flag query
@123  little endian
@124  big endian
@125  endian query
@126  flags query
@127  wild layout change: tapeKB=(T-2), stackKB=(T-1), dataKB=(T)
```

**devam** yazarsan şimdi `uxm31_compiler_fb_full.bas` dosyasını, yani bu runtime’a bağlı **tam native x64 compiler** dosyasını vereceğim.

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

`uxm31_full_tool_fb.bas` tarafında runtime macro call-stack gerçek çalışır. `uxm31_compiler_fb_full.bas` tarafında macro’lar derleme zamanında inline açılır; native EXE tarafında `@128..255` kullanıcı macro call-stack değil, derlenmiş kod olarak bulunur.

Tamam Mete abi. Aşağıdaki testler **öncekilerden farklıdır** ve beklenen çıktılar dosyanın içinde `# EXPECT_OUTPUT:` yorum satırı olarak yazılmıştır.

Klasör adı önerisi:

```bat
mkdir tests_full
```

## `tests_full\test20_fifo_char_order.uxm`

```text
# TEST: FIFO push/pop karakter sırası
# EXPECT_OUTPUT: AB
>>
0(T-1)+k65
@90
0(T-1)+k66
@90
@91
.(T+1)
@91
.(T+1)
```

## `tests_full\test21_fifo_count_peek.uxm`

```text
# TEST: FIFO count ve peek
# EXPECT_OUTPUT:
# 2
# 10
>>
0(T-1)+k10
@90
0(T-1)+k20
@90
@93
@61
@5
@92
@61
```

## `tests_full\test22_data_write_read_char.uxm`

```text
# TEST: data alanına yaz ve oku
# EXPECT_OUTPUT: X
>>
0(T-2)+k5
0(T-1)+k88
@96
0(T-1)+k5
@95
.(T+1)
```

## `tests_full\test23_data_digit_ascii_to_number.uxm`

```text
# TEST: data alanındaki ASCII rakamı sayıya çevir
# EXPECT_OUTPUT: 8
s1=10,{987}
>>
0(T-1)+k11
@97
@61
```

## `tests_full\test24_data_block_copy_print.uxm`

```text
# TEST: data block copy
# EXPECT_OUTPUT: HELLO
s1=0,{HELLO}
>>
0(T-2)
0(T-1)+k100
0(T)+k5
@98
0(T-1)+k100
@95
.(T+1)
0(T-1)+k101
@95
.(T+1)
0(T-1)+k102
@95
.(T+1)
0(T-1)+k103
@95
.(T+1)
0(T-1)+k104
@95
.(T+1)
```

## `tests_full\test25_data_sort_ascending.uxm`

```text
# TEST: data sort ascending
# EXPECT_OUTPUT: ABC
>>
0(T-2)
0(T-1)+k67
@96
0(T-2)+k1
0(T-1)+k65
@96
0(T-2)+k2
0(T-1)+k66
@96
0(T-2)
0(T-1)+k3
@102
0(T-1)
@95
.(T+1)
0(T-1)+k1
@95
.(T+1)
0(T-1)+k2
@95
.(T+1)
```

## `tests_full\test26_tape_sort_descending_chars.uxm`

```text
# TEST: tape sort descending
# EXPECT_OUTPUT: 321
0(T:10)+k49
0(T:11)+k51
0(T:12)+k50
>>
0(T-2)+k10
0(T-1)+k3
@101
.(T:10)
.(T:11)
.(T:12)
```

## `tests_full\test27_tape_linear_search.uxm`

```text
# TEST: tape linear search
# EXPECT_OUTPUT: 2
0(T:20)+k7
0(T:21)+k8
0(T:22)+k9
>>
0(T-2)+k20
0(T-1)+k3
0(T)+k9
@104
@61
```

## `tests_full\test28_dynamic_meta_fifo.uxm`

```text
# TEST: @# ile dinamik meta çağrı
# EXPECT_OUTPUT: A
>>
0(T-1)+k65
0(T)+k90
@#
0(T)+k91
@#
.(T+1)
```

## `tests_full\test29_nested_macro_call.uxm`

```text
# TEST: nested macro call
# EXPECT_OUTPUT: HI!
m128={0+k72. @129 0+k33.}
m129={0+k73.}
@128
```

## `tests_full\test30_word_mode_add.uxm`

```text
# TEST: word cell mode toplama
# EXPECT_OUTPUT: 700
#cell word
>>
0(T-2)+k300
0(T-1)+k400
@20
@61
```

## `tests_full\test31_safe_mode_wild_denied.uxm`

```text
# TEST: safe mode içinde wild layout change reddedilmeli
# EXPECT_OUTPUT: 23
#mode safe
>>
0(T-2)+k48
0(T-1)+k4
0(T)+k12
@127
e(T+1)
@61
```

## `tests_full\test32_wild_layout_change.uxm`

```text
# TEST: wild mode memory layout change
# EXPECT_OUTPUT: 49152
#mode wild
>>
0(T-2)+k48
0(T-1)+k4
0(T)+k12
@127
@84
@61
```

## `tests_full\test33_bitwise_and_stack.uxm`

```text
# TEST: stack üzerinden AND işlemi
# EXPECT_OUTPUT: 8
0+k12
$(T)
0+k10
&
$(T)
%(T+1)
@61
```

## `tests_full\test34_data_block_clear.uxm`

```text
# TEST: data block clear
# EXPECT_OUTPUT: AC
s1=0,{ABC}
>>
0(T-2)+k1
0(T-1)+k1
@99
0(T-1)
@95
.(T+1)
0(T-1)+k1
@95
.(T+1)
0(T-1)+k2
@95
.(T+1)
```

## `tests_full\test35_optimizer_visible_result.uxm`

```text
# TEST: optimizer clear/inc-dec merge/cancel
# EXPECT_OUTPUT: B
0
+k10
-k10
0+k66
.
```

## Çalıştırma

Native full compiler hattı için:

```bat
fbc uxm31_compiler_fb_full.bas -x uxm31_compiler_full.exe
fbc uxm31_full_tool_fb.bas -x uxm31_full_tool.exe
```

Tek tek native derleme:

```bat
uxm31_compiler_full.exe tests_full\test20_fifo_char_order.uxm build\test20.asm build\test20.uir.json build\test20.opt.json
nasm -f win64 build\test20.asm -o build\test20.obj
fbc uxm31_runtime_fb_full.bas build\test20.obj -x build\test20.exe
build\test20.exe
```

Interpreter/IDE trace hattı için:

```bat
uxm31_full_tool.exe run tests_full\test20_fifo_char_order.uxm build\test20.trace.ndjson
uxm31_full_tool.exe uir tests_full\test20_fifo_char_order.uxm build\test20.uir.json
uxm31_full_tool.exe opt tests_full\test20_fifo_char_order.uxm build\test20.opt.json
```

Not: `test32_wild_layout_change.uxm` özellikle **native full runtime** tarafındaki `@84` tape cell sorgusunu kullanır. `uxm31_full_tool_fb.bas` içinde aynı sonucu istiyorsak `@84/@85/@86` servislerini interpreter motoruna da eklemek gerekir.
