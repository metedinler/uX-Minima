Option Explicit
#Lang "fb"
' UX-MINIMA x64 V3.1 FINAL COMPILER / TOOL
' Tek merkez: parse + diagnostics + UIR JSON + optimizer + interpreter + step trace + IDE protocol + ASM emitter
' Not: FreeBASIC 1.10+ hedeflenir. Windows x64 + NASM emitter dahildir.

Const UXM_VERSION As String = "UX-MINIMA x64 V3.1 FINAL-ARGE"
Const MAX_SRC As Long = 4000000
Const MAX_INSTR As Long = 300000
Const MAX_STRINGS As Long = 4096
Const MAX_MACROS As Long = 256
Const MAX_DIAG As Long = 8192
Const MAX_OPT As Long = 65536
Const MAX_WATCH As Long = 512
Const MEM_TOTAL_BYTES As Long = 65536

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

Type TInstr
    op As Long
    amount As Long
    addrKind As Long
    addrVal As Long
    addrVal2 As Long
    text As String
    pos As Long
    lineNo As Long
    colNo As Long
    metaId As Long
    metaDyn As Long
    metaForceHost As Long
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
    lineNo As Long
End Type

Type TDiag
    severity As String
    msg As String
    lineNo As Long
    colNo As Long
    pos As Long
End Type

Type TOpt
    msg As String
    beforeIp As Long
    afterIp As Long
End Type

Type TWatch
    spaceName As String
    startIdx As Long
    count As Long
End Type

Dim Shared src As String
Dim Shared inputFile As String
Dim Shared asmFile As String
Dim Shared uirFile As String
Dim Shared diagFile As String
Dim Shared traceFile As String
Dim Shared optFile As String
Dim Shared ideInFile As String
Dim Shared ideOutFile As String
Dim Shared outputText As String
Dim Shared runMode As String
Dim Shared compileAsm As Long
Dim Shared runInterpreter As Long
Dim Shared stepMode As Long
Dim Shared writeUIR As Long
Dim Shared writeDiagnostics As Long
Dim Shared writeTrace As Long
Dim Shared writeOptimizer As Long
Dim Shared noOptimize As Long
Dim Shared maxSteps As ULongInt
Dim Shared hadError As Long
Dim Shared errMsg As String
Dim Shared instr(1 To MAX_INSTR) As TInstr
Dim Shared instrCount As Long
Dim Shared strDef(1 To MAX_STRINGS) As TStringDef
Dim Shared strCount As Long
Dim Shared macroDef(1 To MAX_MACROS) As TMacroDef
Dim Shared macroCount As Long
Dim Shared diag(1 To MAX_DIAG) As TDiag
Dim Shared diagCount As Long
Dim Shared optEvent(1 To MAX_OPT) As TOpt
Dim Shared optCount As Long
Dim Shared watchList(1 To MAX_WATCH) As TWatch
Dim Shared watchCount As Long
Dim Shared needLabel(1 To MAX_INSTR) As Long
Dim Shared cellBits As Long
Dim Shared tapeKB As Long, stackKB As Long, dataKB As Long
Dim Shared tapeBytes As Long, stackBytes As Long, dataBytes As Long
Dim Shared tapeCells As Long, stackCells As Long, dataCells As Long
Dim Shared stackOffset As Long, dataOffset As Long
Dim Shared workMode As Long
Dim Shared boundsOn As Long
Dim Shared defaultSigned As Long
Dim Shared defaultEndian As Long
Dim Shared flags As ULongInt
Dim Shared statusByte As ULongInt
Dim Shared ptr As Long
Dim Shared sp As Long
Dim Shared fifoHead As Long, fifoTail As Long, fifoCount As Long
Dim Shared tape(0 To 65535) As ULongInt
Dim Shared dataMem(0 To 65535) As ULongInt
Dim Shared stackMem(0 To 65535) As ULongInt
Dim Shared fifoMem(0 To 65535) As ULongInt
Dim Shared stepCounter As ULongInt
Dim Shared traceFF As Integer
Dim Shared traceOpen As Long
Dim Shared outFF As Integer
Dim Shared asmLabelCounter As Long

Declare Sub Main()
Declare Sub InitDefaults()
Declare Sub ParseCLI()
Declare Sub PrintHelp()
Declare Sub ReadFile(ByVal fn As String)
Declare Function ReadAll(ByVal fn As String) As String
Declare Sub ParseIdeJson(ByVal fn As String)
Declare Function JsonValue(ByVal js As String, ByVal key As String) As String
Declare Sub ParsePragmasAndArge()
Declare Sub ApplyMemory()
Declare Sub FirstPassDefs()
Declare Sub ParseProgram(ByRef code As String, ByVal depth As Long)
Declare Sub ParseOne(ByRef code As String, ByRef p As Long, ByVal depth As Long)
Declare Sub ParseStringDef(ByRef code As String, ByRef p As Long)
Declare Sub ParseMacroDef(ByRef code As String, ByRef p As Long)
Declare Sub ParsePrintString(ByRef code As String, ByRef p As Long)
Declare Sub ParseMeta(ByRef code As String, ByRef p As Long, ByVal depth As Long)
Declare Sub ParseBranch(ByRef code As String, ByRef p As Long)
Declare Sub AddInstr(ByVal op As Long, ByVal amount As Long, ByVal ak As Long, ByVal av As Long, ByVal av2 As Long, ByVal txt As String, ByVal pos As Long)
Declare Sub AddMeta(ByVal id As Long, ByVal dyn As Long, ByVal forceHost As Long, ByVal txt As String, ByVal pos As Long)
Declare Sub AddBranch(ByVal cond As Long, ByVal dir As Long, ByVal dist As Long, ByVal txt As String, ByVal pos As Long)
Declare Sub AddString(ByVal id As Long, ByVal st As Long, ByVal txt As String, ByVal lineNo As Long)
Declare Sub AddMacro(ByVal id As Long, ByVal txt As String, ByVal lineNo As Long)
Declare Sub AddDiag(ByVal sev As String, ByVal msg As String, ByVal pos As Long)
Declare Sub AddOpt(ByVal msg As String, ByVal beforeIp As Long, ByVal afterIp As Long)
Declare Sub SyntaxError(ByVal msg As String, ByVal pos As Long)
Declare Sub SkipLine(ByRef code As String, ByRef p As Long)
Declare Sub ValidateProgram()
Declare Sub OptimizeProgram()
Declare Sub RunProgram()
Declare Sub ExecInstr(ByRef ip As Long, ByVal depth As Long)
Declare Sub CallRuntimeMacro(ByVal id As Long, ByVal depth As Long)
Declare Sub TraceStart()
Declare Sub TraceStop()
Declare Sub TraceEvent(ByVal ip As Long, ByVal opName As String, ByVal extra As String)
Declare Sub ExportUIR(ByVal fn As String)
Declare Sub ExportDiagnostics(ByVal fn As String)
Declare Sub ExportOpt(ByVal fn As String)
Declare Sub ExportIdeResult()
Declare Sub GenerateASM(ByVal fn As String)
Declare Sub EmitHeader()
Declare Sub EmitStringInitializers()
Declare Sub EmitInstr(ByVal i As Long)
Declare Sub EmitFooter()
Declare Sub EmitLine(ByVal s As String)
Declare Sub EmitAddrPtr(ByVal ak As Long, ByVal av As Long, ByVal av2 As Long, ByVal outReg As String)
Declare Sub EmitAddrLoad(ByVal ak As Long, ByVal av As Long, ByVal av2 As Long, ByVal regName As String)
Declare Sub EmitAddrStore(ByVal ak As Long, ByVal av As Long, ByVal av2 As Long, ByVal regName As String)
Declare Sub EmitSetFlagsFromRAX()
Declare Sub EmitMetaCall(ByVal id As Long, ByVal dyn As Long)
Declare Sub EmitBranch(ByVal i As Long)
Declare Sub RuntimeMeta(ByVal id As Long)
Declare Sub SetStatus(ByVal code As ULongInt)
Declare Sub SetLogicFlags(ByVal v As ULongInt)
Declare Sub SetZeroSign(ByVal v As ULongInt)
Declare Sub ClearArithFlags()
Declare Sub FifoPush(ByVal v As ULongInt)
Declare Function FifoPop() As ULongInt
Declare Function ReadAddr(ByVal ak As Long, ByVal av As Long, ByVal av2 As Long) As ULongInt
Declare Sub WriteAddr(ByVal ak As Long, ByVal av As Long, ByVal av2 As Long, ByVal v As ULongInt)
Declare Function ResolveIndex(ByVal ak As Long, ByVal av As Long, ByVal av2 As Long, ByRef spaceName As String, ByRef ok As Long) As Long
Declare Function CellMask() As ULongInt
Declare Function CellSize() As Long
Declare Function MemSizePrefix() As String
Declare Function Reg8(ByVal r As String) As String
Declare Function Reg16(ByVal r As String) As String
Declare Function Reg32(ByVal r As String) As String
Declare Function ParseUnsigned(ByRef code As String, ByRef p As Long, ByRef ok As Long) As Long
Declare Function ParseBraced(ByRef code As String, ByRef p As Long, ByRef ok As Long) As String
Declare Function ParseAddress(ByRef code As String, ByRef p As Long, ByRef ak As Long, ByRef av As Long, ByRef av2 As Long) As Long
Declare Function ParseAddrBody(ByVal body As String, ByRef ak As Long, ByRef av As Long, ByRef av2 As Long) As Long
Declare Function ParseTapeRelInside(ByVal s As String, ByRef rel As Long) As Long
Declare Function FindString(ByVal id As Long) As Long
Declare Function FindMacro(ByVal id As Long) As Long
Declare Function IsDigitC(ByVal c As String) As Long
Declare Function IsSpaceC(ByVal c As String) As Long
Declare Function IsCmdC(ByVal c As String) As Long
Declare Function RemoveBOM(ByVal s As String) As String
Declare Function TrimAll(ByVal s As String) As String
Declare Function LowerNoSpace(ByVal s As String) As String
Declare Function GetKeyValue(ByVal lineText As String, ByVal key As String) As String
Declare Function ParseKB(ByVal s As String, ByVal def As Long) As Long
Declare Function JsonEsc(ByVal s As String) As String
Declare Function OpName(ByVal op As Long) As String
Declare Function AddrText(ByVal ak As Long, ByVal av As Long, ByVal av2 As Long) As String
Declare Function LineOfPos(ByVal pos As Long) As Long
Declare Function ColOfPos(ByVal pos As Long) As Long
Declare Function NewAsmId() As Long

Main()
End

Sub Main()
    InitDefaults()
    ParseCLI()
    If inputFile="" And ideInFile="" Then PrintHelp(): End
    If ideInFile<>"" Then ParseIdeJson(ideInFile)
    If inputFile="" Then Print "HATA: input eksik": End
    ReadFile inputFile
    If hadError Then Print errMsg: End
    ParsePragmasAndArge()
    ApplyMemory()
    FirstPassDefs()
    ParseProgram src,0
    ValidateProgram()
    If noOptimize=0 Then OptimizeProgram(): ValidateProgram()
    If writeDiagnostics Then ExportDiagnostics diagFile
    If writeUIR Then ExportUIR uirFile
    If writeOptimizer Then ExportOpt optFile
    If runInterpreter Or stepMode Then RunProgram()
    If compileAsm Then GenerateASM asmFile
    If ideOutFile<>"" Then ExportIdeResult()
    If diagCount>0 Then Print "Diagnostics: ";diagCount;" adet."
    If hadError Then Print errMsg: End
    If runInterpreter Or stepMode Then Print outputText
    If compileAsm Then Print "ASM: ";asmFile
    If writeUIR Then Print "UIR: ";uirFile
    If writeTrace Then Print "TRACE: ";traceFile
End Sub

Sub InitDefaults()
    inputFile="":asmFile="build\program.asm":uirFile="build\program.uir.json":diagFile="build\program.diag.json":traceFile="build\program.trace.ndjson":optFile="build\program.opt.json"
    ideInFile="":ideOutFile=""
    runMode="compile"
    compileAsm=1:runInterpreter=0:stepMode=0
    writeUIR=1:writeDiagnostics=1:writeTrace=0:writeOptimizer=1:noOptimize=0
    maxSteps=1000000
    cellBits=8:tapeKB=32:stackKB=8:dataKB=24
    workMode=MODE_NORMAL:boundsOn=1:defaultSigned=0:defaultEndian=0
    flags=FLAG_BND:statusByte=0:ptr=0:sp=0:fifoHead=0:fifoTail=0:fifoCount=0
    outputText="":stepCounter=0:traceOpen=0
End Sub

Sub PrintHelp()
    Print UXM_VERSION
    Print "Kullanim:"
    Print "  uxm31_compiler_final.exe --input file.uxm --mode compile --asm out.asm --uir out.uir.json --diag out.diag.json --opt out.opt.json"
    Print "  uxm31_compiler_final.exe --input file.uxm --mode interpret --trace out.trace.ndjson"
    Print "  uxm31_compiler_final.exe --input file.uxm --mode step --trace out.trace.ndjson --max-steps 1000"
    Print "  uxm31_compiler_final.exe --ide-in request.json --ide-out response.json"
    Print "ARGE source komutlari:"
    Print "  #arge version"
    Print "  #arge json on"
    Print "  #arge interpreter on"
    Print "  #arge step on"
    Print "  #arge trace on"
    Print "  #arge optimize off"
    Print "  #arge watch tape=0:32"
    Print "  #arge watch data=100:40"
    Print "Dil ekleri: (D@T+N), (D@(T-2)+N), @!N host meta."
End Sub

Sub ParseCLI()
    Dim i As Long, a As String
    If Command(1)="--version" Or Command(1)="-v" Then Print UXM_VERSION: End
    If Command(1)="--help" Or Command(1)="-h" Then PrintHelp(): End
    i=1
    Do While Command(i)<>""
        a=Command(i)
        Select Case LCase(a)
        Case "--input","-i": i+=1: inputFile=Command(i)
        Case "--asm": i+=1: asmFile=Command(i): compileAsm=1
        Case "--uir": i+=1: uirFile=Command(i): writeUIR=1
        Case "--diag": i+=1: diagFile=Command(i): writeDiagnostics=1
        Case "--trace": i+=1: traceFile=Command(i): writeTrace=1
        Case "--opt": i+=1: optFile=Command(i): writeOptimizer=1
        Case "--ide-in": i+=1: ideInFile=Command(i)
        Case "--ide-out": i+=1: ideOutFile=Command(i)
        Case "--max-steps": i+=1: maxSteps=Val(Command(i))
        Case "--no-opt": noOptimize=1
        Case "--mode"
            i+=1: runMode=LCase(Command(i))
            compileAsm=0:runInterpreter=0:stepMode=0
            If runMode="compile" Then compileAsm=1
            If runMode="interpret" Or runMode="run" Then runInterpreter=1:writeTrace=1
            If runMode="step" Then stepMode=1:writeTrace=1
            If runMode="all" Then compileAsm=1:runInterpreter=1:writeTrace=1
        Case Else
            If inputFile="" And Left(a,2)<>"--" Then inputFile=a
        End Select
        i+=1
    Loop
End Sub

Sub ParseIdeJson(ByVal fn As String)
    Dim js As String, cmd As String, v As String
    js=ReadAll(fn)
    cmd=LCase(JsonValue(js,"command"))
    inputFile=JsonValue(js,"source")
    v=JsonValue(js,"asm"):If v<>"" Then asmFile=v
    v=JsonValue(js,"uir"):If v<>"" Then uirFile=v
    v=JsonValue(js,"diag"):If v<>"" Then diagFile=v
    v=JsonValue(js,"trace"):If v<>"" Then traceFile=v
    v=JsonValue(js,"opt"):If v<>"" Then optFile=v
    If cmd="run" Or cmd="interpret" Then compileAsm=0:runInterpreter=1:writeTrace=1
    If cmd="step" Then compileAsm=0:stepMode=1:writeTrace=1
    If cmd="compile" Or cmd="build" Then compileAsm=1:runInterpreter=0
    If cmd="all" Then compileAsm=1:runInterpreter=1:writeTrace=1
End Sub

Function JsonValue(ByVal js As String, ByVal key As String) As String
    Dim p As Long, q As Long, r As Long
    p=InStr(js,Chr(34)+key+Chr(34)): If p=0 Then Return ""
    p=InStr(p,js,":"): If p=0 Then Return ""
    q=InStr(p+1,js,Chr(34)): If q=0 Then Return ""
    r=InStr(q+1,js,Chr(34)): If r=0 Then Return ""
    Return Mid(js,q+1,r-q-1)
End Function

Sub ReadFile(ByVal fn As String)
    If Len(Dir(fn))=0 Then hadError=1:errMsg="HATA: dosya yok: "+fn:Exit Sub
    src=RemoveBOM(ReadAll(fn))
End Sub

Function ReadAll(ByVal fn As String) As String
    Dim ff As Integer, sz As Long, s As String
    If Len(Dir(fn))=0 Then Return ""
    ff=FreeFile: Open fn For Binary Access Read As #ff
    sz=Lof(ff)
    If sz>0 Then s=Space(sz): Get #ff,,s Else s=""
    Close #ff
    Return s
End Function

Sub ParsePragmasAndArge()
    Dim p As Long, st As Long, lineText As String, low As String, v As String
    p=1
    Do While p<=Len(src)
        st=p
        Do While p<=Len(src) And Mid(src,p,1)<>Chr(10): p+=1: Loop
        lineText=TrimAll(Mid(src,st,p-st))
        low=LowerNoSpace(lineText)
        If Left(low,5)="#mode" Then
            If InStr(low,"safe")>0 Then workMode=MODE_SAFE
            If InStr(low,"normal")>0 Then workMode=MODE_NORMAL
            If InStr(low,"wild")>0 Then workMode=MODE_WILD
        ElseIf Left(low,5)="#cell" Then
            If InStr(low,"byte")>0 Then cellBits=8
            If InStr(low,"word")>0 Then cellBits=16
            If InStr(low,"dword")>0 Then cellBits=32
        ElseIf Left(low,7)="#memory" Then
            v=GetKeyValue(low,"tape"):If v<>"" Then tapeKB=ParseKB(v,tapeKB)
            v=GetKeyValue(low,"stack"):If v<>"" Then stackKB=ParseKB(v,stackKB)
            v=GetKeyValue(low,"data"):If v<>"" Then dataKB=ParseKB(v,dataKB)
        ElseIf Left(low,7)="#bounds" Then
            If InStr(low,"off")>0 Then boundsOn=0
            If InStr(low,"on")>0 Then boundsOn=1
        ElseIf Left(low,8)="#compare" Then
            If InStr(low,"signed")>0 Then defaultSigned=1
            If InStr(low,"unsigned")>0 Then defaultSigned=0
        ElseIf Left(low,7)="#endian" Then
            If InStr(low,"big")>0 Then defaultEndian=1
            If InStr(low,"little")>0 Then defaultEndian=0
        ElseIf Left(low,6)="#arge" Then
            If InStr(low,"version")>0 Then AddDiag "info","ARGE version: "+UXM_VERSION,st
            If InStr(low,"jsonon")>0 Then writeUIR=1:writeDiagnostics=1
            If InStr(low,"interpreteron")>0 Then runInterpreter=1
            If InStr(low,"stepon")>0 Then stepMode=1:writeTrace=1
            If InStr(low,"traceon")>0 Then writeTrace=1
            If InStr(low,"optimizeoff")>0 Then noOptimize=1
            If InStr(low,"watchtape=")>0 Then watchCount+=1:watchList(watchCount).spaceName="T":watchList(watchCount).startIdx=Val(Mid(low,InStr(low,"watchtape=")+10)):watchList(watchCount).count=32
            If InStr(low,"watchdata=")>0 Then watchCount+=1:watchList(watchCount).spaceName="D":watchList(watchCount).startIdx=Val(Mid(low,InStr(low,"watchdata=")+10)):watchList(watchCount).count=32
            If InStr(low,"watchstack=")>0 Then watchCount+=1:watchList(watchCount).spaceName="S":watchList(watchCount).startIdx=Val(Mid(low,InStr(low,"watchstack=")+11)):watchList(watchCount).count=32
        End If
        p+=1
    Loop
End Sub

Sub ApplyMemory()
    tapeBytes=tapeKB*1024: stackBytes=stackKB*1024: dataBytes=dataKB*1024
    If tapeBytes+stackBytes+dataBytes<>MEM_TOTAL_BYTES Then AddDiag "error","Tape+Stack+Data toplamı 64KB olmalı",1:hadError=1:errMsg="Bellek modeli hatalı":Exit Sub
    If cellBits<>8 And cellBits<>16 And cellBits<>32 Then AddDiag "error","cell byte/word/dword olmalı",1:hadError=1:errMsg="Cell tipi hatalı":Exit Sub
    stackOffset=tapeBytes: dataOffset=tapeBytes+stackBytes
    tapeCells=tapeBytes\CellSize(): stackCells=stackBytes\CellSize(): dataCells=dataBytes\CellSize()
    flags=0
    If boundsOn Then flags Or=FLAG_BND
    If defaultSigned Then flags Or=FLAG_SGN
    If defaultEndian Then flags Or=FLAG_END
    If workMode=MODE_WILD Then flags Or=FLAG_WILD
End Sub

Sub FirstPassDefs()
    Dim p As Long, c As String
    p=1
    Do While p<=Len(src) And hadError=0
        c=Mid(src,p,1)
        If c="#" Then SkipLine src,p ElseIf c="s" Or c="S" Then ParseStringDef src,p ElseIf c="m" Or c="M" Then ParseMacroDef src,p Else p+=1
    Loop
End Sub

Sub ParseProgram(ByRef code As String, ByVal depth As Long)
    Dim p As Long
    If depth>64 Then SyntaxError "macro expansion derinliği 64'u aştı",1:Exit Sub
    p=1
    Do While p<=Len(code) And hadError=0
        If IsSpaceC(Mid(code,p,1)) Then p+=1 ElseIf Mid(code,p,1)="#" Then SkipLine code,p ElseIf Mid(code,p,1)="s" Or Mid(code,p,1)="S" Then ParseStringDef code,p ElseIf Mid(code,p,1)="m" Or Mid(code,p,1)="M" Then ParseMacroDef code,p Else ParseOne code,p,depth
    Loop
End Sub

Sub ParseOne(ByRef code As String, ByRef p As Long, ByVal depth As Long)
    Dim c As String, st As Long, ak As Long, av As Long, av2 As Long, amt As Long, ok As Long, hasAddr As Long, c2 As String, p2 As Long, amt2 As Long, ok2 As Long
    st=p:c=Mid(code,p,1)
    If c="p" Or c="P" Then ParsePrintString code,p:Exit Sub
    If c="@" Then ParseMeta code,p,depth:Exit Sub
    If c=":" Then ParseBranch code,p:Exit Sub
    If IsCmdC(c)=0 Then SyntaxError "geçersiz komut: "+c,p:Exit Sub
    p+=1:ak=ADDR_T:av=0:av2=0:amt=1
    If c="+" Or c="-" Then If p<=Len(code) Then If Mid(code,p,1)="k" Or Mid(code,p,1)="K" Then p+=1:amt=ParseUnsigned(code,p,ok):If ok=0 Then SyntaxError "k sonrası sayı bekleniyor",p:Exit Sub
    hasAddr=ParseAddress(code,p,ak,av,av2)
    Select Case c
    Case ">": If hasAddr Then SyntaxError "> adresleme alamaz",st:Exit Sub Else AddInstr OP_RIGHT,amt,ADDR_T,0,0,Mid(code,st,p-st),st
    Case "<": If hasAddr Then SyntaxError "< adresleme alamaz",st:Exit Sub Else AddInstr OP_LEFT,amt,ADDR_T,0,0,Mid(code,st,p-st),st
    Case "+": AddInstr OP_INC,amt,ak,av,av2,Mid(code,st,p-st),st
    Case "-": AddInstr OP_DEC,amt,ak,av,av2,Mid(code,st,p-st),st
    Case "0"
        AddInstr OP_CLEAR,0,ak,av,av2,Mid(code,st,p-st),st
        If p<=Len(code) Then
            If Mid(code,p,1)="+" Or Mid(code,p,1)="-" Then
                c2=Mid(code,p,1):p2=p+1
                If p2<=Len(code) Then If Mid(code,p2,1)="k" Or Mid(code,p2,1)="K" Then p2+=1:amt2=ParseUnsigned(code,p2,ok2):If ok2=0 Then SyntaxError "0+kN için N bekleniyor",p2:Exit Sub Else If c2="+" Then AddInstr OP_INC,amt2,ak,av,av2,"+k"+Str(amt2)+" inherit",st Else AddInstr OP_DEC,amt2,ak,av,av2,"-k"+Str(amt2)+" inherit",st:p=p2
            End If
        End If
    Case ".": AddInstr OP_PUTC,0,ak,av,av2,Mid(code,st,p-st),st
    Case ",": AddInstr OP_GETC,0,ak,av,av2,Mid(code,st,p-st),st
    Case "[": If hasAddr Then SyntaxError "[ adresleme alamaz",st:Exit Sub Else AddInstr OP_LOOP_BEG,0,ADDR_T,0,0,Mid(code,st,p-st),st
    Case "]": If hasAddr Then SyntaxError "] adresleme alamaz",st:Exit Sub Else AddInstr OP_LOOP_END,0,ADDR_T,0,0,Mid(code,st,p-st),st
    Case "$": AddInstr OP_PUSH,0,ak,av,av2,Mid(code,st,p-st),st
    Case "%": AddInstr OP_POP,0,ak,av,av2,Mid(code,st,p-st),st
    Case "?": AddInstr OP_EQ,0,ak,av,av2,Mid(code,st,p-st),st
    Case "!": AddInstr OP_GT,0,ak,av,av2,Mid(code,st,p-st),st
    Case ";": AddInstr OP_LT,0,ak,av,av2,Mid(code,st,p-st),st
    Case "&": AddInstr OP_AND,0,ak,av,av2,Mid(code,st,p-st),st
    Case "|": AddInstr OP_OR,0,ak,av,av2,Mid(code,st,p-st),st
    Case "^": AddInstr OP_XOR,0,ak,av,av2,Mid(code,st,p-st),st
    Case "~": AddInstr OP_NOT,0,ak,av,av2,Mid(code,st,p-st),st
    Case "{": AddInstr OP_SHL,0,ak,av,av2,Mid(code,st,p-st),st
    Case "}": AddInstr OP_SHR,0,ak,av,av2,Mid(code,st,p-st),st
    Case "e","E": AddInstr OP_STATUS,0,ak,av,av2,Mid(code,st,p-st),st
    End Select
End Sub

Sub ParseStringDef(ByRef code As String, ByRef p As Long)
    Dim ok As Long,id As Long,stCell As Long,txt As String, st As Long
    st=p:p+=1:id=ParseUnsigned(code,p,ok):If ok=0 Then SyntaxError "sN için N bekleniyor",p:Exit Sub
    If p>Len(code) Or Mid(code,p,1)<>"=" Then SyntaxError "sN için = bekleniyor",p:Exit Sub
    p+=1:stCell=ParseUnsigned(code,p,ok):If ok=0 Then SyntaxError "string başlangıç hücresi bekleniyor",p:Exit Sub
    If p>Len(code) Or Mid(code,p,1)<>"," Then SyntaxError "sN için virgül bekleniyor",p:Exit Sub
    p+=1:txt=ParseBraced(code,p,ok):If ok=0 Then SyntaxError "sN için {metin} bekleniyor",p:Exit Sub
    AddString id,stCell,txt,LineOfPos(st)
End Sub

Sub ParseMacroDef(ByRef code As String, ByRef p As Long)
    Dim ok As Long,id As Long,txt As String, st As Long
    st=p:p+=1:id=ParseUnsigned(code,p,ok):If ok=0 Then SyntaxError "mN için N bekleniyor",p:Exit Sub
    If id<128 Or id>255 Then SyntaxError "mN id 128..255 olmalı",st:Exit Sub
    If p>Len(code) Or Mid(code,p,1)<>"=" Then SyntaxError "mN için = bekleniyor",p:Exit Sub
    p+=1:txt=ParseBraced(code,p,ok):If ok=0 Then SyntaxError "mN için {kod} bekleniyor",p:Exit Sub
    AddMacro id,txt,LineOfPos(st)
End Sub

Sub ParsePrintString(ByRef code As String, ByRef p As Long)
    Dim ok As Long,id As Long,idx As Long,st As Long
    st=p:p+=1:id=ParseUnsigned(code,p,ok):If ok=0 Then SyntaxError "pN için N bekleniyor",p:Exit Sub
    idx=FindString(id):If idx=0 Then SyntaxError "tanımsız string p"+Str(id),st:Exit Sub
    AddInstr OP_PRINT_STRING,id,ADDR_T,0,0,Mid(code,st,p-st),st
End Sub

Sub ParseMeta(ByRef code As String, ByRef p As Long, ByVal depth As Long)
    Dim ok As Long,id As Long,idx As Long,st As Long,forceHost As Long
    st=p:p+=1:forceHost=0
    If p<=Len(code) And Mid(code,p,1)="!" Then forceHost=1:p+=1
    If p>Len(code) Then SyntaxError "@ sonrası id bekleniyor",p:Exit Sub
    If Mid(code,p,1)="#" Then p+=1:AddMeta -1,1,0,"@#",st:Exit Sub
    id=ParseUnsigned(code,p,ok):If ok=0 Then SyntaxError "@ sonrası sayı bekleniyor",p:Exit Sub
    If id<0 Or id>255 Then SyntaxError "meta id 0..255 olmalı",st:Exit Sub
    If forceHost=0 Then idx=FindMacro(id):If idx<>0 Then ParseProgram macroDef(idx).txt,depth+1:Exit Sub
    AddMeta id,0,forceHost,Mid(code,st,p-st),st
End Sub

Sub ParseBranch(ByRef code As String, ByRef p As Long)
    Dim st As Long,cond As Long,dir As Long,dist As Long,ok As Long,c As String
    st=p:p+=1:If p>Len(code) Then SyntaxError ": sonrası branch bekleniyor",p:Exit Sub
    c=Mid(code,p,1)
    If c=":" Then cond=BR_ALWAYS:p+=1 ElseIf c="0" Then cond=BR_CUR_Z:p+=1 ElseIf c="z" Then cond=BR_Z_SET:p+=1 ElseIf c="Z" Then cond=BR_Z_CLR:p+=1 ElseIf c="c" Then cond=BR_C_SET:p+=1 ElseIf c="C" Then cond=BR_C_CLR:p+=1 ElseIf c="o" Then cond=BR_O_SET:p+=1 ElseIf c="O" Then cond=BR_O_CLR:p+=1 ElseIf c="s" Then cond=BR_S_SET:p+=1 ElseIf c="S" Then cond=BR_S_CLR:p+=1 ElseIf c="+" Or c="-" Then cond=BR_CUR_NZ Else SyntaxError "geçersiz branch tipi",p:Exit Sub
    c=Mid(code,p,1):If c="+" Then dir=1 ElseIf c="-" Then dir=-1 Else SyntaxError "branch için + veya - gerekli",p:Exit Sub
    p+=1:dist=ParseUnsigned(code,p,ok):If ok=0 Or dist<=0 Then SyntaxError "branch mesafesi gerekli",p:Exit Sub
    AddBranch cond,dir,dist,Mid(code,st,p-st),st
End Sub

Sub AddInstr(ByVal op As Long, ByVal amount As Long, ByVal ak As Long, ByVal av As Long, ByVal av2 As Long, ByVal txt As String, ByVal pos As Long)
    instrCount+=1:If instrCount>MAX_INSTR Then SyntaxError "instruction limiti doldu",pos:Exit Sub
    instr(instrCount).op=op:instr(instrCount).amount=amount:instr(instrCount).addrKind=ak:instr(instrCount).addrVal=av:instr(instrCount).addrVal2=av2:instr(instrCount).text=txt:instr(instrCount).pos=pos:instr(instrCount).lineNo=LineOfPos(pos):instr(instrCount).colNo=ColOfPos(pos)
End Sub
Sub AddMeta(ByVal id As Long, ByVal dyn As Long, ByVal forceHost As Long, ByVal txt As String, ByVal pos As Long)
    AddInstr OP_META,0,ADDR_T,0,0,txt,pos:instr(instrCount).metaId=id:instr(instrCount).metaDyn=dyn:instr(instrCount).metaForceHost=forceHost
End Sub
Sub AddBranch(ByVal cond As Long, ByVal dir As Long, ByVal dist As Long, ByVal txt As String, ByVal pos As Long)
    AddInstr OP_BRANCH,0,ADDR_T,0,0,txt,pos:instr(instrCount).brCond=cond:instr(instrCount).brDir=dir:instr(instrCount).brDist=dist
End Sub
Sub AddString(ByVal id As Long, ByVal st As Long, ByVal txt As String, ByVal lineNo As Long)
    strCount+=1:If strCount>MAX_STRINGS Then AddDiag "error","string tablosu doldu",1:Exit Sub
    strDef(strCount).id=id:strDef(strCount).startCell=st:strDef(strCount).txt=txt
End Sub
Sub AddMacro(ByVal id As Long, ByVal txt As String, ByVal lineNo As Long)
    Dim i As Long
    For i=1 To macroCount:If macroDef(i).id=id Then macroDef(i).txt=txt:Exit Sub
    Next
    macroCount+=1:If macroCount>MAX_MACROS Then AddDiag "error","macro tablosu doldu",1:Exit Sub
    macroDef(macroCount).id=id:macroDef(macroCount).txt=txt:macroDef(macroCount).lineNo=lineNo
End Sub
Sub AddDiag(ByVal sev As String, ByVal msg As String, ByVal pos As Long)
    diagCount+=1:If diagCount>MAX_DIAG Then Exit Sub
    diag(diagCount).severity=sev:diag(diagCount).msg=msg:diag(diagCount).pos=pos:diag(diagCount).lineNo=LineOfPos(pos):diag(diagCount).colNo=ColOfPos(pos)
End Sub
Sub SyntaxError(ByVal msg As String, ByVal pos As Long)
    AddDiag "error",msg,pos:hadError=1:errMsg="SYNTAX ERROR: "+msg
End Sub
Sub AddOpt(ByVal msg As String, ByVal beforeIp As Long, ByVal afterIp As Long)
    optCount+=1:If optCount>MAX_OPT Then Exit Sub
    optEvent(optCount).msg=msg:optEvent(optCount).beforeIp=beforeIp:optEvent(optCount).afterIp=afterIp
End Sub
Sub SkipLine(ByRef code As String, ByRef p As Long)
    Do While p<=Len(code):If Mid(code,p,1)=Chr(10) Then p+=1:Exit Sub Else p+=1
    Loop
End Sub

Sub ValidateProgram()
    Dim st(1 To 65536) As Long, spx As Long, i As Long, j As Long
    spx=0
    For i=1 To instrCount
        If instr(i).op=OP_LOOP_BEG Then spx+=1:st(spx)=i
        If instr(i).op=OP_LOOP_END Then If spx<=0 Then SyntaxError "fazla ]",instr(i).pos:Exit Sub Else j=st(spx):spx-=1:instr(i).mate=j:instr(j).mate=i
    Next
    If spx<>0 Then SyntaxError "kapanmamış [",instr(st(spx)).pos:Exit Sub
    For i=1 To instrCount
        If instr(i).op=OP_BRANCH Then j=i+instr(i).brDir*instr(i).brDist:If j<1 Or j>instrCount Then SyntaxError "branch hedefi program dışında",instr(i).pos:Exit Sub Else instr(i).brTarget=j:needLabel(j)=1
    Next
End Sub

Sub OptimizeProgram()
    Dim n As Long,i As Long, delta As LongInt
    Dim newI(1 To MAX_INSTR) As TInstr
    i=1:n=0
    Do While i<=instrCount
        If i<instrCount Then
            If instr(i).op=OP_CLEAR And (instr(i+1).op=OP_INC Or instr(i+1).op=OP_DEC) And instr(i).addrKind=instr(i+1).addrKind And instr(i).addrVal=instr(i+1).addrVal And instr(i).addrVal2=instr(i+1).addrVal2 Then
                n+=1:newI(n)=instr(i+1):newI(n).op=OP_SET:newI(n).text="optimized_set"
                If instr(i+1).op=OP_DEC Then newI(n).amount=(CellMask()-instr(i+1).amount+1) And CellMask()
                AddOpt "CLEAR + INC/DEC -> SET",i,n:i+=2:Continue Do
            End If
            If (instr(i).op=OP_INC Or instr(i).op=OP_DEC) And (instr(i+1).op=OP_INC Or instr(i+1).op=OP_DEC) And instr(i).addrKind=instr(i+1).addrKind And instr(i).addrVal=instr(i+1).addrVal And instr(i).addrVal2=instr(i+1).addrVal2 Then
                delta=0:If instr(i).op=OP_INC Then delta+=instr(i).amount Else delta-=instr(i).amount
                If instr(i+1).op=OP_INC Then delta+=instr(i+1).amount Else delta-=instr(i+1).amount
                If delta=0 Then AddOpt "INC/DEC cancel",i,n:i+=2:Continue Do
                n+=1:newI(n)=instr(i):If delta>0 Then newI(n).op=OP_INC:newI(n).amount=delta Else newI(n).op=OP_DEC:newI(n).amount=Abs(delta)
                newI(n).text="optimized_arith_merge":AddOpt "INC/DEC merge",i,n:i+=2:Continue Do
            End If
        End If
        n+=1:newI(n)=instr(i):i+=1
    Loop
    instrCount=n:For i=1 To instrCount:instr(i)=newI(i):Next
End Sub

Sub RunProgram()
    Dim i As Long,j As Long
    ptr=0:sp=0:statusByte=0:outputText="":stepCounter=0
    For i=1 To strCount
        For j=1 To Len(strDef(i).txt):If strDef(i).startCell+j-1<dataCells Then dataMem(strDef(i).startCell+j-1)=Asc(Mid(strDef(i).txt,j,1)) And CellMask()
        Next:If strDef(i).startCell+Len(strDef(i).txt)<dataCells Then dataMem(strDef(i).startCell+Len(strDef(i).txt))=0
    Next
    TraceStart()
    Dim ip As Long:ip=1
    Do While ip>=1 And ip<=instrCount
        ExecInstr ip,0
        If stepCounter>=maxSteps Then AddDiag "error","max step limit aşıldı",1:SetStatus STATUS_OVERFLOW:Exit Do
        If hadError Then Exit Do
    Loop
    TraceStop()
End Sub

Sub ExecInstr(ByRef ip As Long, ByVal depth As Long)
    Dim oldIp As Long,v As ULongInt,a As ULongInt,b As ULongInt,taken As Long,id As Long
    oldIp=ip:stepCounter+=1
    Select Case instr(ip).op
    Case OP_RIGHT:ptr+=instr(ip).amount:If boundsOn And (ptr<0 Or ptr>=tapeCells) Then SetStatus STATUS_PTR_BOUNDS:ip=instrCount+1 Else TraceEvent oldIp,"RIGHT","":ip+=1
    Case OP_LEFT:ptr-=instr(ip).amount:If boundsOn And (ptr<0 Or ptr>=tapeCells) Then SetStatus STATUS_PTR_BOUNDS:ip=instrCount+1 Else TraceEvent oldIp,"LEFT","":ip+=1
    Case OP_INC:v=(ReadAddr(instr(ip).addrKind,instr(ip).addrVal,instr(ip).addrVal2)+instr(ip).amount) And CellMask():WriteAddr instr(ip).addrKind,instr(ip).addrVal,instr(ip).addrVal2,v:SetLogicFlags v:TraceEvent oldIp,"INC","":ip+=1
    Case OP_DEC:v=(ReadAddr(instr(ip).addrKind,instr(ip).addrVal,instr(ip).addrVal2)-instr(ip).amount) And CellMask():WriteAddr instr(ip).addrKind,instr(ip).addrVal,instr(ip).addrVal2,v:SetLogicFlags v:TraceEvent oldIp,"DEC","":ip+=1
    Case OP_SET:v=instr(ip).amount And CellMask():WriteAddr instr(ip).addrKind,instr(ip).addrVal,instr(ip).addrVal2,v:SetLogicFlags v:TraceEvent oldIp,"SET","":ip+=1
    Case OP_CLEAR:WriteAddr instr(ip).addrKind,instr(ip).addrVal,instr(ip).addrVal2,0:SetLogicFlags 0:TraceEvent oldIp,"CLEAR","":ip+=1
    Case OP_PUTC:v=ReadAddr(instr(ip).addrKind,instr(ip).addrVal,instr(ip).addrVal2):outputText+=Chr(v And &HFF):TraceEvent oldIp,"PUTC","""char"":"+Str(v And &HFF):ip+=1
    Case OP_GETC:WriteAddr instr(ip).addrKind,instr(ip).addrVal,instr(ip).addrVal2,0:SetStatus STATUS_EOF:TraceEvent oldIp,"GETC","":ip+=1
    Case OP_PUSH:If sp>=stackCells Then SetStatus STATUS_STACK_OVERFLOW:ip=instrCount+1 Else stackMem(sp)=ReadAddr(instr(ip).addrKind,instr(ip).addrVal,instr(ip).addrVal2):sp+=1:TraceEvent oldIp,"PUSH","":ip+=1
    Case OP_POP:If sp<=0 Then SetStatus STATUS_STACK_UNDERFLOW:ip=instrCount+1 Else sp-=1:WriteAddr instr(ip).addrKind,instr(ip).addrVal,instr(ip).addrVal2,stackMem(sp):SetLogicFlags stackMem(sp):TraceEvent oldIp,"POP","":ip+=1
    Case OP_EQ,OP_GT,OP_LT,OP_AND,OP_OR,OP_XOR
        If sp<=0 Then SetStatus STATUS_STACK_UNDERFLOW:ip=instrCount+1 Else sp-=1:a=stackMem(sp):b=ReadAddr(instr(ip).addrKind,instr(ip).addrVal,instr(ip).addrVal2):If instr(ip).op=OP_EQ Then v=IIf(a=b,1,0) ElseIf instr(ip).op=OP_GT Then v=IIf(a>b,1,0) ElseIf instr(ip).op=OP_LT Then v=IIf(a<b,1,0) ElseIf instr(ip).op=OP_AND Then v=a And b ElseIf instr(ip).op=OP_OR Then v=a Or b Else v=a Xor b:WriteAddr instr(ip).addrKind,instr(ip).addrVal,instr(ip).addrVal2,v And CellMask():SetLogicFlags v:TraceEvent oldIp,OpName(instr(ip).op),"":ip+=1
    Case OP_NOT:v=(Not ReadAddr(instr(ip).addrKind,instr(ip).addrVal,instr(ip).addrVal2)) And CellMask():WriteAddr instr(ip).addrKind,instr(ip).addrVal,instr(ip).addrVal2,v:SetLogicFlags v:TraceEvent oldIp,"NOT","":ip+=1
    Case OP_SHL:v=(ReadAddr(instr(ip).addrKind,instr(ip).addrVal,instr(ip).addrVal2) Shl 1) And CellMask():WriteAddr instr(ip).addrKind,instr(ip).addrVal,instr(ip).addrVal2,v:SetLogicFlags v:TraceEvent oldIp,"SHL","":ip+=1
    Case OP_SHR:v=(ReadAddr(instr(ip).addrKind,instr(ip).addrVal,instr(ip).addrVal2) Shr 1) And CellMask():WriteAddr instr(ip).addrKind,instr(ip).addrVal,instr(ip).addrVal2,v:SetLogicFlags v:TraceEvent oldIp,"SHR","":ip+=1
    Case OP_STATUS:WriteAddr instr(ip).addrKind,instr(ip).addrVal,instr(ip).addrVal2,statusByte:SetLogicFlags statusByte:TraceEvent oldIp,"STATUS","":ip+=1
    Case OP_LOOP_BEG:If tape(ptr)=0 Then ip=instr(ip).mate+1 Else ip+=1:TraceEvent oldIp,"LOOP_BEGIN",""
    Case OP_LOOP_END:If tape(ptr)<>0 Then ip=instr(ip).mate+1 Else ip+=1:TraceEvent oldIp,"LOOP_END",""
    Case OP_META
        If instr(ip).metaDyn Then id=tape(ptr) Else id=instr(ip).metaId
        If id>=128 And id<=255 And instr(ip).metaForceHost=0 Then CallRuntimeMacro id,depth+1 Else RuntimeMeta id
        TraceEvent oldIp,"META","""meta_id"":"+Str(id)+",""force_host"":"+Str(instr(ip).metaForceHost):ip+=1
    Case OP_BRANCH
        taken=0
        Select Case instr(ip).brCond
        Case BR_CUR_NZ:If tape(ptr)<>0 Then taken=1
        Case BR_CUR_Z:If tape(ptr)=0 Then taken=1
        Case BR_ALWAYS:taken=1
        Case BR_Z_SET:If (flags And FLAG_Z)<>0 Then taken=1
        Case BR_Z_CLR:If (flags And FLAG_Z)=0 Then taken=1
        Case BR_C_SET:If (flags And FLAG_C)<>0 Then taken=1
        Case BR_C_CLR:If (flags And FLAG_C)=0 Then taken=1
        Case BR_O_SET:If (flags And FLAG_O)<>0 Then taken=1
        Case BR_O_CLR:If (flags And FLAG_O)=0 Then taken=1
        Case BR_S_SET:If (flags And FLAG_S)<>0 Then taken=1
        Case BR_S_CLR:If (flags And FLAG_S)=0 Then taken=1
        End Select
        If taken Then ip=instr(oldIp).brTarget Else ip+=1
        TraceEvent oldIp,"BRANCH","""taken"":"+Str(taken)+",""target"":"+Str(instr(oldIp).brTarget)
    Case OP_PRINT_STRING
        id=FindString(instr(ip).amount):If id>0 Then outputText+=strDef(id).txt
        TraceEvent oldIp,"PRINT_STRING","":ip+=1
    Case Else:ip+=1
    End Select
End Sub

Sub CallRuntimeMacro(ByVal id As Long, ByVal depth As Long)
    Dim idx As Long, savedSrc As String, savedCount As Long, saved(1 To 2048) As TInstr, i As Long
    idx=FindMacro(id):If idx=0 Then SetStatus STATUS_INVALID_META:Exit Sub
    If depth>64 Then SetStatus STATUS_STACK_OVERFLOW:Exit Sub
    savedSrc=src:savedCount=instrCount
    If savedCount>2048 Then SetStatus STATUS_OVERFLOW:Exit Sub
    For i=1 To savedCount:saved(i)=instr(i):Next
    instrCount=0:src=macroDef(idx).txt:ParseProgram src,depth:ValidateProgram()
    Dim ip As Long:ip=1
    Do While ip>=1 And ip<=instrCount:ExecInstr ip,depth:If statusByte<>0 Then Exit Do:Loop
    src=savedSrc:instrCount=savedCount:For i=1 To savedCount:instr(i)=saved(i):Next
End Sub

Sub RuntimeMeta(ByVal id As Long)
    Dim a As ULongInt,b As ULongInt,c As ULongInt
    a=ReadAddr(ADDR_T_REL,-2,0):b=ReadAddr(ADDR_T_REL,-1,0):c=ReadAddr(ADDR_T,0,0)
    Select Case id
    Case 0:SetStatus STATUS_OK
    Case 5:outputText+=Chr(10):SetStatus STATUS_OK
    Case 20:WriteAddr ADDR_T_REL,1,0,(a+b) And CellMask():SetLogicFlags (a+b):SetStatus STATUS_OK
    Case 21:WriteAddr ADDR_T_REL,1,0,(a-b) And CellMask():SetLogicFlags (a-b):SetStatus STATUS_OK
    Case 22:WriteAddr ADDR_T_REL,1,0,(a*b) And CellMask():SetLogicFlags (a*b):SetStatus STATUS_OK
    Case 23:If b=0 Then WriteAddr ADDR_T_REL,1,0,0:SetStatus STATUS_DIV_ZERO Else WriteAddr ADDR_T_REL,1,0,(a\b) And CellMask():SetStatus STATUS_OK
    Case 24:If b=0 Then WriteAddr ADDR_T_REL,1,0,0:SetStatus STATUS_DIV_ZERO Else WriteAddr ADDR_T_REL,1,0,(a Mod b) And CellMask():SetStatus STATUS_OK
    Case 60:outputText+=LTrim(Str(b)):SetStatus STATUS_OK
    Case 61:outputText+=LTrim(Str(ReadAddr(ADDR_T_REL,1,0))):SetStatus STATUS_OK
    Case 64:outputText+=" ":SetStatus STATUS_OK
    Case 80:If b>=tapeCells Then SetStatus STATUS_PTR_BOUNDS Else ptr=b:flags Or=FLAG_PCHG:SetStatus STATUS_OK
    Case 84:WriteAddr ADDR_T_REL,1,0,tapeCells:SetStatus STATUS_OK
    Case 85:WriteAddr ADDR_T_REL,1,0,dataCells:SetStatus STATUS_OK
    Case 86:WriteAddr ADDR_T_REL,1,0,stackCells:SetStatus STATUS_OK
    Case 90:FifoPush b
    Case 91:WriteAddr ADDR_T_REL,1,0,FifoPop():SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
    Case 93:WriteAddr ADDR_T_REL,1,0,fifoCount:SetStatus STATUS_OK
    Case 95:If b>=dataCells Then SetStatus STATUS_DATA_BOUNDS Else WriteAddr ADDR_T_REL,1,0,dataMem(b):SetStatus STATUS_OK
    Case 96:If a>=dataCells Then SetStatus STATUS_DATA_BOUNDS Else dataMem(a)=b And CellMask():SetStatus STATUS_OK
    Case 98:Dim i As Long:For i=0 To c-1:If a+i<dataCells And b+i<dataCells Then dataMem(b+i)=dataMem(a+i):Next:SetStatus STATUS_OK
    Case 99:For i As Long=0 To b-1:If a+i<dataCells Then dataMem(a+i)=0:Next:SetStatus STATUS_OK
    Case 120:flags And=Not FLAG_SGN:SetStatus STATUS_OK
    Case 121:flags Or=FLAG_SGN:SetStatus STATUS_OK
    Case 126:WriteAddr ADDR_T_REL,1,0,flags:SetStatus STATUS_OK
    Case Else:SetStatus STATUS_INVALID_META
    End Select
End Sub

Sub FifoPush(ByVal v As ULongInt)
    If fifoCount>=65536 Then SetStatus STATUS_STACK_OVERFLOW:Exit Sub
    fifoMem(fifoTail)=v And CellMask():fifoTail=(fifoTail+1) Mod 65536:fifoCount+=1:flags Or=FLAG_FIFO:SetStatus STATUS_OK
End Sub
Function FifoPop() As ULongInt
    Dim v As ULongInt
    If fifoCount=0 Then SetStatus STATUS_STACK_UNDERFLOW:Return 0
    v=fifoMem(fifoHead):fifoHead=(fifoHead+1) Mod 65536:fifoCount-=1:SetStatus STATUS_OK:Return v
End Function

Function ResolveIndex(ByVal ak As Long, ByVal av As Long, ByVal av2 As Long, ByRef spaceName As String, ByRef ok As Long) As Long
    Dim idx As Long:ok=1
    Select Case ak
    Case ADDR_T:spaceName="T":idx=ptr
    Case ADDR_T_REL:spaceName="T":idx=ptr+av
    Case ADDR_T_ABS:spaceName="T":idx=av
    Case ADDR_D_ABS:spaceName="D":idx=av
    Case ADDR_S_ABS:spaceName="S":idx=av
    Case ADDR_SP:spaceName="S":idx=sp-1
    Case ADDR_P:spaceName="P":idx=0
    Case ADDR_E:spaceName="E":idx=0
    Case ADDR_F:spaceName="F":idx=0
    Case ADDR_IND_T:spaceName="T":idx=tape(ptr)
    Case ADDR_IND_T_REL:spaceName="T":idx=tape(ptr+av)
    Case ADDR_D_AT_T_REL:spaceName="D":idx=tape(ptr)+av2
    Case ADDR_D_AT_TBASE_REL:spaceName="D":idx=tape(ptr+av)+av2
    Case Else:ok=0:idx=0
    End Select
    If boundsOn Then
        If spaceName="T" And (idx<0 Or idx>=tapeCells) Then ok=0:SetStatus STATUS_PTR_BOUNDS
        If spaceName="D" And (idx<0 Or idx>=dataCells) Then ok=0:SetStatus STATUS_DATA_BOUNDS
        If spaceName="S" And (idx<0 Or idx>=stackCells) Then ok=0:SetStatus STATUS_STACK_UNDERFLOW
    End If
    Return idx
End Function
Function ReadAddr(ByVal ak As Long, ByVal av As Long, ByVal av2 As Long) As ULongInt
    Dim spn As String,ok As Long,idx As Long
    idx=ResolveIndex(ak,av,av2,spn,ok):If ok=0 Then Return 0
    If spn="T" Then Return tape(idx) And CellMask()
    If spn="D" Then Return dataMem(idx) And CellMask()
    If spn="S" Then Return stackMem(idx) And CellMask()
    If spn="P" Then Return ptr And CellMask()
    If spn="E" Then Return statusByte And CellMask()
    If spn="F" Then Return flags And CellMask()
    Return 0
End Function
Sub WriteAddr(ByVal ak As Long, ByVal av As Long, ByVal av2 As Long, ByVal v As ULongInt)
    Dim spn As String,ok As Long,idx As Long
    idx=ResolveIndex(ak,av,av2,spn,ok):If ok=0 Then Exit Sub
    v=v And CellMask()
    If spn="T" Then tape(idx)=v
    If spn="D" Then dataMem(idx)=v
    If spn="S" Then stackMem(idx)=v
    If spn="P" Then ptr=v:flags Or=FLAG_PCHG
    If spn="E" Then SetStatus v
    If spn="F" Then flags=v
    flags Or=FLAG_DIRTY
End Sub
Sub SetStatus(ByVal code As ULongInt)
    statusByte=code And &HFF:If statusByte=0 Then flags And=Not FLAG_ERR Else flags Or=FLAG_ERR
End Sub
Sub ClearArithFlags():flags And=Not (FLAG_Z Or FLAG_C Or FLAG_O Or FLAG_S):End Sub
Sub SetZeroSign(ByVal v As ULongInt)
    flags And=Not (FLAG_Z Or FLAG_S):v And=CellMask():If v=0 Then flags Or=FLAG_Z
    If cellBits=8 And (v And &H80)<>0 Then flags Or=FLAG_S
    If cellBits=16 And (v And &H8000)<>0 Then flags Or=FLAG_S
    If cellBits=32 And (v And &H80000000)<>0 Then flags Or=FLAG_S
End Sub
Sub SetLogicFlags(ByVal v As ULongInt):ClearArithFlags():SetZeroSign v:End Sub

Sub TraceStart()
    If writeTrace=0 Then Exit Sub
    traceFF=FreeFile:Open traceFile For Output As #traceFF:traceOpen=1
    Print #traceFF,"{""type"":""start"",""version"":"""+JsonEsc(UXM_VERSION)+""",""cell_bits"":"+Str(cellBits)+",""tape_cells"":"+Str(tapeCells)+",""stack_cells"":"+Str(stackCells)+",""data_cells"":"+Str(dataCells)+"}"
End Sub
Sub TraceStop()
    If traceOpen Then Print #traceFF,"{""type"":""end"",""steps"":"+Str(stepCounter)+",""status"":"+Str(statusByte)+",""output"":"""+JsonEsc(outputText)+"""}" : Close #traceFF
    traceOpen=0
End Sub
Sub TraceEvent(ByVal ip As Long, ByVal opName As String, ByVal extra As String)
    If traceOpen=0 Then Exit Sub
    Print #traceFF,"{""type"":""step"",""step"":"+Str(stepCounter)+",""ip"":"+Str(ip)+",""op"":"""+opName+""",""src"":"""+JsonEsc(instr(ip).text)+""",""ptr"":"+Str(ptr)+",""sp"":"+Str(sp)+",""fifo_count"":"+Str(fifoCount)+",""status"":"+Str(statusByte)+",""flags"":"+Str(flags)+",""current"":"+Str(tape(ptr));
    If extra<>"" Then Print #traceFF,","+extra;
    Print #traceFF,"}"
End Sub

Sub ExportUIR(ByVal fn As String)
    Dim ff As Integer,i As Long
    ff=FreeFile:Open fn For Output As #ff
    Print #ff,"{""version"":"""+JsonEsc(UXM_VERSION)+""",""memory"":{""cell_bits"":"+Str(cellBits)+",""tape_kb"":"+Str(tapeKB)+",""stack_kb"":"+Str(stackKB)+",""data_kb"":"+Str(dataKB)+"},""instructions"":"
    Print #ff,"["
    For i=1 To instrCount
        Print #ff,"{""ip"":"+Str(i)+",""op"":"""+OpName(instr(i).op)+""",""amount"":"+Str(instr(i).amount)+",""addr"":"""+JsonEsc(AddrText(instr(i).addrKind,instr(i).addrVal,instr(i).addrVal2))+""",""meta_id"":"+Str(instr(i).metaId)+",""meta_dynamic"":"+Str(instr(i).metaDyn)+",""meta_force_host"":"+Str(instr(i).metaForceHost)+",""branch_target"":"+Str(instr(i).brTarget)+",""mate"":"+Str(instr(i).mate)+",""line"":"+Str(instr(i).lineNo)+",""col"":"+Str(instr(i).colNo)+",""text"":"""+JsonEsc(instr(i).text)+"""}";
        If i<instrCount Then Print #ff,"," Else Print #ff,""
    Next
    Print #ff,"]}"
    Close #ff
End Sub
Sub ExportDiagnostics(ByVal fn As String)
    Dim ff As Integer,i As Long
    ff=FreeFile:Open fn For Output As #ff:Print #ff,"{""diagnostics"":";Print #ff,"["
    For i=1 To diagCount
        Print #ff,"{""severity"":"""+diag(i).severity+""",""message"":"""+JsonEsc(diag(i).msg)+""",""line"":"+Str(diag(i).lineNo)+",""col"":"+Str(diag(i).colNo)+"}";
        If i<diagCount Then Print #ff,"," Else Print #ff,""
    Next:Print #ff,"]}":Close #ff
End Sub
Sub ExportOpt(ByVal fn As String)
    Dim ff As Integer,i As Long
    ff=FreeFile:Open fn For Output As #ff:Print #ff,"{""optimizer_events"":";Print #ff,"["
    For i=1 To optCount
        Print #ff,"{""msg"":"""+JsonEsc(optEvent(i).msg)+""",""before_ip"":"+Str(optEvent(i).beforeIp)+",""after_ip"":"+Str(optEvent(i).afterIp)+"}";
        If i<optCount Then Print #ff,"," Else Print #ff,""
    Next:Print #ff,"]}":Close #ff
End Sub
Sub ExportIdeResult()
    Dim ff As Integer
    ff=FreeFile:Open ideOutFile For Output As #ff
    Print #ff,"{""version"":"""+JsonEsc(UXM_VERSION)+""",""status"":"+Str(statusByte)+",""diagnostics"":"+Str(diagCount)+",""instructions"":"+Str(instrCount)+",""output"":"""+JsonEsc(outputText)+""",""asm"":"""+JsonEsc(asmFile)+""",""uir"":"""+JsonEsc(uirFile)+""",""trace"":"""+JsonEsc(traceFile)+"""}"
    Close #ff
End Sub

Sub GenerateASM(ByVal fn As String)
    outFF=FreeFile:Open fn For Output As #outFF
    EmitHeader():EmitStringInitializers()
    For i As Long=1 To instrCount:If needLabel(i) Then EmitLine "__ux_ip_"+LTrim(Str(i))+":"
        EmitInstr i
    Next
    EmitFooter():Close #outFF
End Sub
Sub EmitLine(ByVal s As String):Print #outFF,s:End Sub
Sub EmitHeader()
    EmitLine "; generated by "+UXM_VERSION
    EmitLine "default rel":EmitLine "global uxm_entry":EmitLine "global ux_mem":EmitLine "global ux_status":EmitLine "global ux_flags":EmitLine "global ux_ptr":EmitLine "global ux_sp"
    EmitLine "global ux_cell_bits":EmitLine "global ux_cell_bytes":EmitLine "global ux_tape_cells":EmitLine "global ux_stack_cells":EmitLine "global ux_data_cells":EmitLine "global ux_stack_offset":EmitLine "global ux_data_offset"
    EmitLine "extern ux_putc":EmitLine "extern ux_getc":EmitLine "extern ux_print_data_string":EmitLine "extern ux_meta_call_ex":EmitLine "extern ux_runtime_error"
    EmitLine "%define UXM_TOTAL_BYTES 65536":EmitLine "%define TAPE_CELLS "+LTrim(Str(tapeCells)):EmitLine "%define STACK_CELLS "+LTrim(Str(stackCells)):EmitLine "%define DATA_CELLS "+LTrim(Str(dataCells)):EmitLine "%define STACK_OFFSET "+LTrim(Str(stackOffset)):EmitLine "%define DATA_OFFSET "+LTrim(Str(dataOffset)):EmitLine "%define CELL_BITS "+LTrim(Str(cellBits)):EmitLine "%define CELL_BYTES "+LTrim(Str(CellSize()))
    EmitLine "%define FLAG_Z 1":EmitLine "%define FLAG_C 2":EmitLine "%define FLAG_O 4":EmitLine "%define FLAG_S 8":EmitLine "%define FLAG_SGN 16":EmitLine "%define FLAG_END 32":EmitLine "%define FLAG_WILD 64":EmitLine "%define FLAG_BND 128"
    EmitLine "section .bss":EmitLine "align 16":EmitLine "ux_mem: resb UXM_TOTAL_BYTES":EmitLine "ux_status: resb 1":EmitLine "ux_flags: resw 1":EmitLine "ux_ptr: resq 1":EmitLine "ux_sp: resq 1":EmitLine "ux_cell_bits: resd 1":EmitLine "ux_cell_bytes: resd 1":EmitLine "ux_tape_cells: resd 1":EmitLine "ux_stack_cells: resd 1":EmitLine "ux_data_cells: resd 1":EmitLine "ux_stack_offset: resd 1":EmitLine "ux_data_offset: resd 1"
    EmitLine "section .text":EmitLine "uxm_entry:":EmitLine "    push rbp":EmitLine "    mov rbp, rsp":EmitLine "    push rbx":EmitLine "    push r12":EmitLine "    push r13":EmitLine "    push r14":EmitLine "    push r15":EmitLine "    sub rsp, 40":EmitLine "    mov dword [ux_cell_bits], CELL_BITS":EmitLine "    mov dword [ux_cell_bytes], CELL_BYTES":EmitLine "    mov dword [ux_tape_cells], TAPE_CELLS":EmitLine "    mov dword [ux_stack_cells], STACK_CELLS":EmitLine "    mov dword [ux_data_cells], DATA_CELLS":EmitLine "    mov dword [ux_stack_offset], STACK_OFFSET":EmitLine "    mov dword [ux_data_offset], DATA_OFFSET":EmitLine "    lea r12, [ux_mem]":EmitLine "    lea r13, [ux_mem + STACK_OFFSET]":EmitLine "    xor rbx, rbx":EmitLine "    xor r14, r14":EmitLine "    mov qword [ux_ptr], rbx":EmitLine "    mov qword [ux_sp], r14":EmitLine "    mov byte [ux_status], 0":EmitLine "    mov word [ux_flags], "+LTrim(Str(flags And &HFFFF))
End Sub
Sub EmitStringInitializers()
    Dim i As Long,j As Long,bo As Long,ch As Long
    For i=1 To strCount
        For j=1 To Len(strDef(i).txt)
            ch=Asc(Mid(strDef(i).txt,j,1)) And &HFF:bo=dataOffset+(strDef(i).startCell+j-1)*CellSize():EmitLine "    mov "+MemSizePrefix()+" [ux_mem + "+LTrim(Str(bo))+"], "+LTrim(Str(ch))
        Next
        bo=dataOffset+(strDef(i).startCell+Len(strDef(i).txt))*CellSize():EmitLine "    mov "+MemSizePrefix()+" [ux_mem + "+LTrim(Str(bo))+"], 0"
    Next
End Sub
Sub EmitInstr(ByVal i As Long)
    Select Case instr(i).op
    Case OP_RIGHT:If instr(i).amount=1 Then EmitLine "    inc rbx" Else EmitLine "    add rbx, "+LTrim(Str(instr(i).amount))
    Case OP_LEFT:If instr(i).amount=1 Then EmitLine "    dec rbx" Else EmitLine "    sub rbx, "+LTrim(Str(instr(i).amount))
    Case OP_INC:EmitAddrLoad instr(i).addrKind,instr(i).addrVal,instr(i).addrVal2,"rax":EmitLine "    add rax, "+LTrim(Str(instr(i).amount)):EmitAddrStore instr(i).addrKind,instr(i).addrVal,instr(i).addrVal2,"rax":EmitSetFlagsFromRAX()
    Case OP_DEC:EmitAddrLoad instr(i).addrKind,instr(i).addrVal,instr(i).addrVal2,"rax":EmitLine "    sub rax, "+LTrim(Str(instr(i).amount)):EmitAddrStore instr(i).addrKind,instr(i).addrVal,instr(i).addrVal2,"rax":EmitSetFlagsFromRAX()
    Case OP_SET:EmitLine "    mov rax, "+LTrim(Str(instr(i).amount)):EmitAddrStore instr(i).addrKind,instr(i).addrVal,instr(i).addrVal2,"rax":EmitSetFlagsFromRAX()
    Case OP_CLEAR:EmitLine "    xor rax, rax":EmitAddrStore instr(i).addrKind,instr(i).addrVal,instr(i).addrVal2,"rax":EmitSetFlagsFromRAX()
    Case OP_PUTC:EmitAddrLoad instr(i).addrKind,instr(i).addrVal,instr(i).addrVal2,"rax":EmitLine "    mov ecx, eax":EmitLine "    call ux_putc"
    Case OP_GETC:EmitLine "    call ux_getc":EmitAddrStore instr(i).addrKind,instr(i).addrVal,instr(i).addrVal2,"rax":EmitSetFlagsFromRAX()
    Case OP_PUSH:EmitLine "    cmp r14, STACK_CELLS":EmitLine "    jae __ux_err_stack_over":EmitAddrLoad instr(i).addrKind,instr(i).addrVal,instr(i).addrVal2,"rax":If cellBits=8 Then EmitLine "    mov byte [r13+r14], al" ElseIf cellBits=16 Then EmitLine "    mov word [r13+r14*2], ax" Else EmitLine "    mov dword [r13+r14*4], eax":EmitLine "    inc r14"
    Case OP_POP:EmitLine "    cmp r14,0":EmitLine "    je __ux_err_stack_under":EmitLine "    dec r14":If cellBits=8 Then EmitLine "    movzx rax, byte [r13+r14]" ElseIf cellBits=16 Then EmitLine "    movzx rax, word [r13+r14*2]" Else EmitLine "    mov eax, dword [r13+r14*4]":EmitAddrStore instr(i).addrKind,instr(i).addrVal,instr(i).addrVal2,"rax":EmitSetFlagsFromRAX()
    Case OP_META:EmitMetaCall instr(i).metaId,instr(i).metaDyn
    Case OP_PRINT_STRING:Dim idx As Long=FindString(instr(i).amount):EmitLine "    mov ecx, "+LTrim(Str(strDef(idx).startCell)):EmitLine "    mov edx, CELL_BITS":EmitLine "    call ux_print_data_string"
    Case OP_LOOP_BEG:EmitLine "__ux_loop_beg_"+LTrim(Str(i))+":":EmitAddrLoad ADDR_T,0,0,"rax":EmitLine "    cmp rax,0":EmitLine "    je __ux_loop_end_"+LTrim(Str(i))
    Case OP_LOOP_END:EmitLine "    jmp __ux_loop_beg_"+LTrim(Str(instr(i).mate)):EmitLine "__ux_loop_end_"+LTrim(Str(instr(i).mate))+":"
    Case OP_BRANCH:EmitBranch i
    Case OP_STATUS:EmitLine "    movzx rax, byte [ux_status]":EmitAddrStore instr(i).addrKind,instr(i).addrVal,instr(i).addrVal2,"rax"
    Case Else:EmitLine "    nop"
    End Select
End Sub
Sub EmitAddrLoad(ByVal ak As Long, ByVal av As Long, ByVal av2 As Long, ByVal regName As String)
    EmitAddrPtr ak,av,av2,"r11":If cellBits=8 Then EmitLine "    movzx "+regName+", byte [r11]" ElseIf cellBits=16 Then EmitLine "    movzx "+regName+", word [r11]" Else EmitLine "    mov eax, dword [r11]"
End Sub
Sub EmitAddrStore(ByVal ak As Long, ByVal av As Long, ByVal av2 As Long, ByVal regName As String)
    EmitAddrPtr ak,av,av2,"r11":If cellBits=8 Then EmitLine "    mov byte [r11], "+Reg8(regName) ElseIf cellBits=16 Then EmitLine "    mov word [r11], "+Reg16(regName) Else EmitLine "    mov dword [r11], "+Reg32(regName)
End Sub
Sub EmitAddrPtr(ByVal ak As Long, ByVal av As Long, ByVal av2 As Long, ByVal outReg As String)
    Select Case ak
    Case ADDR_T:If cellBits=8 Then EmitLine "    lea "+outReg+", [r12+rbx]" ElseIf cellBits=16 Then EmitLine "    lea "+outReg+", [r12+rbx*2]" Else EmitLine "    lea "+outReg+", [r12+rbx*4]"
    Case ADDR_T_REL:EmitLine "    mov r10, rbx":If av>=0 Then EmitLine "    add r10, "+LTrim(Str(av)) Else EmitLine "    sub r10, "+LTrim(Str(Abs(av))):If cellBits=8 Then EmitLine "    lea "+outReg+", [r12+r10]" ElseIf cellBits=16 Then EmitLine "    lea "+outReg+", [r12+r10*2]" Else EmitLine "    lea "+outReg+", [r12+r10*4]"
    Case ADDR_T_ABS:EmitLine "    lea "+outReg+", [r12+"+LTrim(Str(av*CellSize()))+"]"
    Case ADDR_D_ABS:EmitLine "    lea "+outReg+", [r12+DATA_OFFSET+"+LTrim(Str(av*CellSize()))+"]"
    Case ADDR_S_ABS:EmitLine "    lea "+outReg+", [r13+"+LTrim(Str(av*CellSize()))+"]"
    Case ADDR_D_AT_T_REL:EmitAddrLoad ADDR_T,0,0,"rax":If av2>=0 Then EmitLine "    add rax, "+LTrim(Str(av2)) Else EmitLine "    sub rax, "+LTrim(Str(Abs(av2))):If cellBits=8 Then EmitLine "    lea "+outReg+", [r12+DATA_OFFSET+rax]" ElseIf cellBits=16 Then EmitLine "    lea "+outReg+", [r12+DATA_OFFSET+rax*2]" Else EmitLine "    lea "+outReg+", [r12+DATA_OFFSET+rax*4]"
    Case ADDR_D_AT_TBASE_REL:EmitAddrLoad ADDR_T_REL,av,0,"rax":If av2>=0 Then EmitLine "    add rax, "+LTrim(Str(av2)) Else EmitLine "    sub rax, "+LTrim(Str(Abs(av2))):If cellBits=8 Then EmitLine "    lea "+outReg+", [r12+DATA_OFFSET+rax]" ElseIf cellBits=16 Then EmitLine "    lea "+outReg+", [r12+DATA_OFFSET+rax*2]" Else EmitLine "    lea "+outReg+", [r12+DATA_OFFSET+rax*4]"
    Case Else:EmitLine "    lea "+outReg+", [r12+rbx]"
    End Select
End Sub
Sub EmitSetFlagsFromRAX():EmitLine "    ; flags update minimal":End Sub
Sub EmitMetaCall(ByVal id As Long, ByVal dyn As Long)
    EmitLine "    mov qword [ux_ptr], rbx":EmitLine "    mov qword [ux_sp], r14":If dyn Then EmitAddrLoad ADDR_T,0,0,"rax":EmitLine "    mov ecx, eax" Else EmitLine "    mov ecx, "+LTrim(Str(id))
    EmitLine "    lea rdx, [ux_mem]":EmitLine "    call ux_meta_call_ex":EmitLine "    mov rbx, qword [ux_ptr]":EmitLine "    mov r14, qword [ux_sp]"
End Sub
Sub EmitBranch(ByVal i As Long)
    Dim t As Long:t=instr(i).brTarget:EmitLine "    ; branch -> "+Str(t)
    Select Case instr(i).brCond
    Case BR_ALWAYS:EmitLine "    jmp __ux_ip_"+LTrim(Str(t))
    Case BR_CUR_NZ:EmitAddrLoad ADDR_T,0,0,"rax":EmitLine "    cmp rax,0":EmitLine "    jne __ux_ip_"+LTrim(Str(t))
    Case BR_CUR_Z:EmitAddrLoad ADDR_T,0,0,"rax":EmitLine "    cmp rax,0":EmitLine "    je __ux_ip_"+LTrim(Str(t))
    Case Else:EmitLine "    ; flag branch not expanded in minimal emitter"
    End Select
End Sub
Sub EmitFooter()
    EmitLine "__ux_ok_exit:":EmitLine "    add rsp,40":EmitLine "    pop r15":EmitLine "    pop r14":EmitLine "    pop r13":EmitLine "    pop r12":EmitLine "    pop rbx":EmitLine "    pop rbp":EmitLine "    ret":EmitLine "__ux_err_stack_over:":EmitLine "    mov ecx,11":EmitLine "    call ux_runtime_error":EmitLine "    jmp __ux_ok_exit":EmitLine "__ux_err_stack_under:":EmitLine "    mov ecx,12":EmitLine "    call ux_runtime_error":EmitLine "    jmp __ux_ok_exit"
End Sub

Function ParseUnsigned(ByRef code As String, ByRef p As Long, ByRef ok As Long) As Long
    Dim s As String="":ok=0:Do While p<=Len(code) And IsDigitC(Mid(code,p,1)):s+=Mid(code,p,1):p+=1:Loop:If s="" Then Return 0 Else ok=1:Return Val(s)
End Function
Function ParseBraced(ByRef code As String, ByRef p As Long, ByRef ok As Long) As String
    Dim r As String="",c As String,n As String:ok=0:If p>Len(code) Or Mid(code,p,1)<>"{" Then Return ""
    p+=1:Do While p<=Len(code):c=Mid(code,p,1):If c="\" And p+1<=Len(code) Then n=Mid(code,p+1,1):If n="n" Then r+=Chr(10) ElseIf n="r" Then r+=Chr(13) ElseIf n="t" Then r+=Chr(9) Else r+=n:p+=2 ElseIf c="}" Then p+=1:ok=1:Return r Else r+=c:p+=1
    Loop:Return r
End Function
Function ParseAddress(ByRef code As String, ByRef p As Long, ByRef ak As Long, ByRef av As Long, ByRef av2 As Long) As Long
    Dim st As Long,body As String,bal As Long,c As String:If p>Len(code) Or Mid(code,p,1)<>"(" Then Return 0
    st=p:Do While p<=Len(code):c=Mid(code,p,1):If IsSpaceC(c) Then SyntaxError "adresleme içinde boşluk yasak",p:Return 0
        If c="(" Then bal+=1
        If c=")" Then bal-=1:If bal=0 Then Exit Do
        p+=1
    Loop
    If p>Len(code) Then SyntaxError "adres parantezi kapanmadı",st:Return 0
    body=Mid(code,st+1,p-st-1):p+=1:If ParseAddrBody(body,ak,av,av2)=0 Then SyntaxError "geçersiz adres: "+body,st:Return 0
    Return 1
End Function
Function ParseAddrBody(ByVal body As String, ByRef ak As Long, ByRef av As Long, ByRef av2 As Long) As Long
    Dim b As String,pos As Long,inner As String,rest As String,rel As Long,off As Long
    b=UCase(TrimAll(body)):av=0:av2=0
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
    If Left(b,3)="D@T" Then ak=ADDR_D_AT_T_REL:If Len(b)>3 Then If Mid(b,4,1)="+" Then av2=Val(Mid(b,5)) ElseIf Mid(b,4,1)="-" Then av2=-Val(Mid(b,5)) Else Return 0:Return 1
    If Left(b,4)="D@(" Then pos=InStr(4,b,")"):If pos=0 Then Return 0 Else inner=Mid(b,4,pos-4):rest=Mid(b,pos+1):If ParseTapeRelInside(inner,rel)=0 Then Return 0 Else If rest<>"" Then If Left(rest,1)="+" Then off=Val(Mid(rest,2)) ElseIf Left(rest,1)="-" Then off=-Val(Mid(rest,2)) Else Return 0:ak=ADDR_D_AT_TBASE_REL:av=rel:av2=off:Return 1
    Return 0
End Function
Function ParseTapeRelInside(ByVal s As String, ByRef rel As Long) As Long
    s=UCase(TrimAll(s)):rel=0:If s="T" Then Return 1
    If Left(s,2)="T+" Then rel=Val(Mid(s,3)):Return 1
    If Left(s,2)="T-" Then rel=-Val(Mid(s,3)):Return 1
    Return 0
End Function
Function FindString(ByVal id As Long) As Long:For i As Long=1 To strCount:If strDef(i).id=id Then Return i:Next:Return 0:End Function
Function FindMacro(ByVal id As Long) As Long:For i As Long=1 To macroCount:If macroDef(i).id=id Then Return i:Next:Return 0:End Function
Function IsDigitC(ByVal c As String) As Long:Return IIf(c>="0" And c<="9",1,0):End Function
Function IsSpaceC(ByVal c As String) As Long:Return IIf(c=" " Or c=Chr(9) Or c=Chr(10) Or c=Chr(13),1,0):End Function
Function IsCmdC(ByVal c As String) As Long:Return IIf(InStr("><+-0.,[]$%?!;&|^~{}eE",c)>0,1,0):End Function
Function RemoveBOM(ByVal s As String) As String:If Len(s)>=3 Then If (Asc(Mid(s,1,1)) And &HFF)=&HEF And (Asc(Mid(s,2,1)) And &HFF)=&HBB And (Asc(Mid(s,3,1)) And &HFF)=&HBF Then Return Mid(s,4):Return s:End Function
Function TrimAll(ByVal s As String) As String:Return LTrim(RTrim(s)):End Function
Function LowerNoSpace(ByVal s As String) As String:Dim r As String="":For i As Long=1 To Len(s):Dim c As String=LCase(Mid(s,i,1)):If c<>" " And c<>Chr(9) And c<>Chr(13) Then r+=c:Next:Return r:End Function
Function GetKeyValue(ByVal lineText As String, ByVal key As String) As String:Dim p As Long=InStr(lineText,key+"="):If p=0 Then Return "" Else p+=Len(key)+1:Dim r As String="":Do While p<=Len(lineText) And Mid(lineText,p,1)<>",":r+=Mid(lineText,p,1):p+=1:Loop:Return r:End Function
Function ParseKB(ByVal s As String, ByVal def As Long) As Long:Dim n As Long=Val(s):If n<=0 Then Return def Else Return n:End Function
Function CellMask() As ULongInt:If cellBits=8 Then Return &HFFull ElseIf cellBits=16 Then Return &HFFFFull Else Return &HFFFFFFFFull:End Function
Function CellSize() As Long:If cellBits=8 Then Return 1 ElseIf cellBits=16 Then Return 2 Else Return 4:End Function
Function MemSizePrefix() As String:If cellBits=8 Then Return "byte" ElseIf cellBits=16 Then Return "word" Else Return "dword":End Function
Function Reg8(ByVal r As String) As String:If LCase(r)="rax" Then Return "al" Else Return "al":End Function
Function Reg16(ByVal r As String) As String:If LCase(r)="rax" Then Return "ax" Else Return "ax":End Function
Function Reg32(ByVal r As String) As String:If LCase(r)="rax" Then Return "eax" Else Return "eax":End Function
Function JsonEsc(ByVal s As String) As String:Dim r As String="":For i As Long=1 To Len(s):Dim c As String=Mid(s,i,1):If c=Chr(34) Then r+="\"+Chr(34) ElseIf c="\" Then r+="\\" ElseIf c=Chr(10) Then r+="\n" ElseIf c=Chr(13) Then r+="\r" Else r+=c:Next:Return r:End Function
Function OpName(ByVal op As Long) As String
    Select Case op
    Case OP_RIGHT:Return "RIGHT":Case OP_LEFT:Return "LEFT":Case OP_INC:Return "INC":Case OP_DEC:Return "DEC":Case OP_CLEAR:Return "CLEAR":Case OP_PUTC:Return "PUTC":Case OP_GETC:Return "GETC":Case OP_LOOP_BEG:Return "LOOP_BEGIN":Case OP_LOOP_END:Return "LOOP_END":Case OP_PUSH:Return "PUSH":Case OP_POP:Return "POP":Case OP_EQ:Return "EQ":Case OP_GT:Return "GT":Case OP_LT:Return "LT":Case OP_AND:Return "AND":Case OP_OR:Return "OR":Case OP_XOR:Return "XOR":Case OP_NOT:Return "NOT":Case OP_SHL:Return "SHL":Case OP_SHR:Return "SHR":Case OP_STATUS:Return "STATUS":Case OP_META:Return "META":Case OP_BRANCH:Return "BRANCH":Case OP_PRINT_STRING:Return "PRINT_STRING":Case OP_SET:Return "SET"
    End Select:Return "NOP"
End Function
Function AddrText(ByVal ak As Long, ByVal av As Long, ByVal av2 As Long) As String
    Select Case ak
    Case ADDR_T:Return "(T)":Case ADDR_T_REL:If av>=0 Then Return "(T+"+LTrim(Str(av))+")" Else Return "(T"+LTrim(Str(av))+")"
    Case ADDR_T_ABS:Return "(T:"+LTrim(Str(av))+")":Case ADDR_D_ABS:Return "(D:"+LTrim(Str(av))+")":Case ADDR_D_AT_T_REL:If av2>=0 Then Return "(D@T+"+LTrim(Str(av2))+")" Else Return "(D@T"+LTrim(Str(av2))+")"
    Case ADDR_D_AT_TBASE_REL:If av2>=0 Then Return "(D@(T"+IIf(av>=0,"+","")+LTrim(Str(av))+")+"+LTrim(Str(av2))+")" Else Return "(D@(T"+IIf(av>=0,"+","")+LTrim(Str(av))+")"+LTrim(Str(av2))+")"
    End Select:Return "(?)"
End Function
Function LineOfPos(ByVal pos As Long) As Long:Dim l As Long=1:For i As Long=1 To pos-1:If Mid(src,i,1)=Chr(10) Then l+=1:Next:Return l:End Function
Function ColOfPos(ByVal pos As Long) As Long:Dim c As Long=1:For i As Long=pos-1 To 1 Step -1:If Mid(src,i,1)=Chr(10) Then Exit For Else c+=1:Next:Return c:End Function
Function NewAsmId() As Long:asmLabelCounter+=1:Return asmLabelCounter:End Function
