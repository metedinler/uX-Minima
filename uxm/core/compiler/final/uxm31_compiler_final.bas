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
Const PI_D As Double = 3.1415926535897932384626433832795

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
Dim Shared pragmaSeedEnabled As Long
Dim Shared pragmaSeedValue As Long

#Include Once "../extensions/arge_parse_math_additions.bas"
#Include Once "../extensions/arge_parse_matrix_additions.bas"

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
Declare Function FifoPeek() As ULongInt
Declare Sub DataBlockCopy(ByVal src As Long, ByVal dst As Long, ByVal cnt As Long)
Declare Sub DataBlockClear(ByVal dst As Long, ByVal cnt As Long)
Declare Sub TapeBlockCopy(ByVal src As Long, ByVal dst As Long, ByVal cnt As Long)
Declare Sub TapeBlockClear(ByVal dst As Long, ByVal cnt As Long)
Declare Sub SortTape(ByVal startIdx As Long, ByVal cnt As Long, ByVal ascending As Long)
Declare Sub SortData(ByVal startIdx As Long, ByVal cnt As Long, ByVal ascending As Long)
Declare Function LinearSearchTape(ByVal startIdx As Long, ByVal cnt As Long, ByVal target As ULongInt) As Long
Declare Function LinearSearchData(ByVal startIdx As Long, ByVal cnt As Long, ByVal target As ULongInt) As Long
Declare Function ReadAddr(ByVal ak As Long, ByVal av As Long, ByVal av2 As Long) As ULongInt
Declare Sub WriteAddr(ByVal ak As Long, ByVal av As Long, ByVal av2 As Long, ByVal v As ULongInt)
Declare Function ResolveIndex(ByVal ak As Long, ByVal av As Long, ByVal av2 As Long, ByRef spaceName As String, ByRef ok As Long) As Long
Declare Function CellMask() As ULongInt
Declare Function ScaleFactor() As LongInt
Declare Function ToSignedCell(ByVal v As ULongInt) As LongInt
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
Declare Function MatrixCellIndex(ByVal baseAddr As Long, ByVal r As Long, ByVal c As Long, ByRef ok As Long) As Long
Declare Sub MatrixInit(ByVal baseAddr As Long, ByVal rows As Long, ByVal cols As Long, ByVal typ As Long, ByVal scale As Long)
Declare Function MatIsValid(ByVal baseAddr As Long) As Long
Declare Function FPScaleConst() As LongInt
Declare Function FPReadScaled(ByVal baseAddr As Long) As LongInt
Declare Sub FPWriteScaled(ByVal baseAddr As Long, ByVal v As LongInt)
Declare Function ReadDataString(ByVal startCell As Long) As String
Declare Sub WriteDataString(ByVal startCell As Long, ByVal s As String)
Declare Function ExprEvalRpn(ByVal exprBase As Long, ByVal x As LongInt) As LongInt


#Include Once "final_cli.bas"
#Include Once "final_parser.bas"
#Include Once "final_math_bridge.bas"
#Include Once "final_trace_json.bas"
#Include Once "final_interpreter.bas"
#Include Once "final_asm_emit.bas"
#Include Once "final_main.bas"

Main()
End
