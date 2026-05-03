Mete abi, bence karar şu olmalı:

**Ekrana basma işi UX-MINIMA’nın içine gömülmemeli; FreeBASIC runtime rutinleri tarafından yapılmalı.** UX-MINIMA generated ASM sadece “ne basılacağını” ve “nereden okunacağını” bilmeli. Windows terminali C64 gibi sabit ekran RAM adresiyle çalışmadığı için, ekrana basma/okuma/CLS gibi işler FreeBASIC tarafında kalırsa sistem çok daha sağlam olur.

**UX-MINIMA tarafında ise üç ayrı alan olmalı:**

```text
1. tape alanı       → aktif hücre işlemleri için
2. data alanı       → string, değişken, dizi, sabit veri için
3. user stack alanı → $ ve % ile çalışan kendi LIFO stack alanımız
```

İlk verdiğin UX-MINIMA kodundaki yaklaşımda `PHA/PLA` benzeri CPU stack mantığı vardı; x64 Windows tarafında bunu doğrudan kullanmak doğru değil, çünkü `push/pop` Windows x64 çağrı hizalamasını bozabilir. Bu yüzden `$` ve `%` komutları **CPU stack’i değil, UX-MINIMA’nın kendi user stack alanını** kullanmalı. Bu tasarım, ilk data-driven compiler fikrini bozmadan daha güvenli bir x64 mimariye taşıyor. 

Aşağıda yeniden toparlanmış **UX-MINIMA v2 compiler + runtime** veriyorum.

---

# 1. Tasarım raporu

## 1.1. Ekrana yazma nerede olmalı?

Ekrana yazma **FreeBASIC runtime’da** olmalı.

Generated NASM tarafı şunu yapmalı:

```asm
call ux_putc
call ux_print_cells
call ux_meta_call
```

FreeBASIC runtime ise şunları yapmalı:

```text
karakter basma
string basma
input alma
CLS
hata mesajları
programdan çıkış
```

Bu sayede UX-MINIMA generated ASM küçük ve temiz kalır.

---

## 1.2. Bellek alanları

Yeni model:

```text
ux_tape   → ana hücre şeridi
ux_data   → string/değişken/dizi alanı
ux_stack  → UX-MINIMA user stack alanı
```

Örnek:

```text
tape  = 32 KB
data  = 32 KB
stack = 8 KB
```

Stringler artık tape içine değil, **data alanına** yazılır.

Örneğin:

```text
s1=100,{Merhaba}
```

şu anlama gelir:

```text
data[100] = 'M'
data[101] = 'e'
data[102] = 'r'
...
data[107] = 0
```

Sonra:

```text
p1
```

şunu yapar:

```text
data[100]'den başlayarak 0 görene kadar yazdır.
```

---

## 1.3. Stack meselesi

İki stack varmış gibi düşünmeliyiz:

```text
1. CPU stack
   Windows x64 çağrıları için kullanılır.
   Biz buna mümkün olduğunca dokunmayız.

2. UX-MINIMA user stack
   $ ve % komutları bunu kullanır.
   Bu bizim özel LIFO alanımızdır.
```

Komutlar:

```text
$ = aktif tape hücresini UX stack'e push et
% = UX stack'ten pop et ve aktif tape hücresine yaz
```

Bu, Windows’un kendi stack’inden bağımsızdır. Böylece ABI bozulmaz.

---

# 2. Yeni dil ekleri

## 2.1. Repeat macro

```text
+k65  → 65 tane +
-k10  → 10 tane -
>k20  → 20 tane >
<k5   → 5 tane <
```

Örnek:

```text
+k65.
```

çıktı:

```text
A
```

---

## 2.2. String tanımı

```text
s<string_no>=<data_start_cell>,{metin}
```

Örnek:

```text
s1=100,{Merhaba Mete abi}
```

---

## 2.3. String basma

```text
p<string_no>
```

Örnek:

```text
s1=100,{Merhaba}
p1
```

çıktı:

```text
Merhaba
```

---

# 3. Dosya 1 — `uxm_v2_compiler.bas`

```vbnet
' *****************************************************************
' PROJECT      : UX-MINIMA V2 COMPILER
' HOST         : FreeBASIC
' TARGET       : Windows x64 NASM
' INPUT        : .uxm veya .txt
' OUTPUT       : .asm
'
' FEATURES:
'   - Tape memory
'   - Data memory for strings / future variables / arrays
'   - User stack memory for $ and %
'   - Repeat macro: +k65, >k10, -k3
'   - String directive: s1=100,{Merhaba}
'   - Print string directive: p1
'   - Pattern optimizer
'   - Windows x64 NASM output
'   - FreeBASIC runtime link model
' *****************************************************************

OPTION EXPLICIT

CONST MAX_TOKENS       = 300000
CONST MAX_PATTERNS     = 4096
CONST MAX_LOOP_STACK   = 4096
CONST MAX_STRINGS      = 1024
CONST MAX_REPEAT_COUNT = 1000000

CONST COMMAND_CHARS = "><+-0.,[]@$%!?&|^"

CONST ACT_NOP                  = 0
CONST ACT_ADD_CUR              = 1
CONST ACT_SUB_CUR              = 2
CONST ACT_MOVE_PTR             = 3
CONST ACT_CLEAR_CUR            = 4
CONST ACT_SET_CUR              = 5
CONST ACT_META_CONST           = 6
CONST ACT_MOVE_ADD_RIGHT_CLEAR = 7
CONST ACT_MOVE_ADD_LEFT_CLEAR  = 8
CONST ACT_DOUBLE_CUR           = 9
CONST ACT_HALF_CUR             = 10

CONST OV_WRAP  = 0
CONST OV_CHECK = 1

DECLARE SUB AskOptions()
DECLARE SUB ReadSourceFile()
DECLARE SUB Lexer()
DECLARE SUB AddToken(ByVal t As String)
DECLARE SUB AddRepeatedToken(ByVal c As String, ByVal countVal As ULongInt)

DECLARE SUB LoadPatterns()
DECLARE SUB AddPattern(ByVal p As String, ByVal actionId As Integer, ByVal argVal As LongInt)
DECLARE SUB SortPatternsByPriority()

DECLARE SUB GenerateASM()
DECLARE SUB EmitHeader()
DECLARE SUB EmitFooter()
DECLARE SUB EmitLine(ByVal s As String)
DECLARE SUB EmitStringInitializers()
DECLARE SUB EmitPattern(ByVal pIdx As Integer)
DECLARE SUB EmitSingleToken(ByVal t As String)

DECLARE SUB EmitPointerCheck()
DECLARE SUB EmitNeighborCheck(ByVal offCells As LongInt)
DECLARE SUB EmitMovePtr(ByVal delta As LongInt)
DECLARE SUB EmitSetCell(ByVal offCells As LongInt, ByVal value As ULongInt)
DECLARE SUB EmitClearCell(ByVal offCells As LongInt)
DECLARE SUB EmitAddCell(ByVal offCells As LongInt, ByVal amount As ULongInt)
DECLARE SUB EmitSubCell(ByVal offCells As LongInt, ByVal amount As ULongInt)
DECLARE SUB EmitPutChar()
DECLARE SUB EmitGetChar()
DECLARE SUB EmitMetaFromCell()
DECLARE SUB EmitMetaConst(ByVal metaId As LongInt)
DECLARE SUB EmitPushCell()
DECLARE SUB EmitPopCell()
DECLARE SUB EmitMoveAddClear(ByVal offCells As LongInt)
DECLARE SUB EmitDoubleCell()
DECLARE SUB EmitHalfCell()
DECLARE SUB EmitLoopStart()
DECLARE SUB EmitLoopEnd()
DECLARE SUB EmitPrintStringById(ByVal sid As Integer)

DECLARE SUB AddStringDecl(ByVal sid As Integer, ByVal startCell As ULongInt, ByVal txt As String)
DECLARE SUB SkipSpaces(ByRef pos As Integer)
DECLARE SUB CompileError(ByVal msg As String)

DECLARE FUNCTION TryParseStringDecl(ByRef pos As Integer) As Integer
DECLARE FUNCTION TryParsePrintString(ByRef pos As Integer) As Integer
DECLARE FUNCTION ParseUnsignedNumber(ByRef pos As Integer, ByRef ok As Integer) As ULongInt
DECLARE FUNCTION ParseBracedString(ByRef pos As Integer, ByRef ok As Integer) As String
DECLARE FUNCTION FindStringIndexById(ByVal sid As Integer) As Integer

DECLARE FUNCTION IsDigitChar(ByVal c As String) As Integer
DECLARE FUNCTION IsTokenPrintString(ByVal t As String) As Integer
DECLARE FUNCTION PrintStringIdFromToken(ByVal t As String) As Integer
DECLARE FUNCTION RepeatChar(ByVal ch As String, ByVal n As Integer) As String
DECLARE FUNCTION NormalizePattern(ByVal s As String) As String
DECLARE FUNCTION PatternIsBalanced(ByVal s As String) As Integer
DECLARE FUNCTION SpecificityScore(ByVal p As String) As Integer
DECLARE FUNCTION PatternCompare(ByVal a As Integer, ByVal b As Integer) As Integer
DECLARE FUNCTION MatchPattern(ByVal startIdx As Integer) As Integer

DECLARE FUNCTION SizePrefix() As String
DECLARE FUNCTION StoreReg() As String
DECLARE FUNCTION MaxValue() As ULongInt
DECLARE FUNCTION MaxValueText() As String
DECLARE FUNCTION ReduceValue(ByVal v As ULongInt) As ULongInt
DECLARE FUNCTION IndexExpr(ByVal baseReg As String, ByVal indexReg As String, ByVal offCells As LongInt) As String
DECLARE FUNCTION CellOp(ByVal offCells As LongInt) As String
DECLARE FUNCTION StackOp() As String
DECLARE FUNCTION DataCellOpConst(ByVal cellNo As ULongInt) As String
DECLARE FUNCTION DataByteOffset(ByVal cellNo As ULongInt) As ULongInt
DECLARE FUNCTION DefaultASMName(ByVal srcName As String) As String

DIM SHARED Src AS String
DIM SHARED InFileName AS String
DIM SHARED OutASMName AS String

DIM SHARED Tokens(1 TO MAX_TOKENS) AS String
DIM SHARED TokenCount AS Integer

DIM SHARED Pat(1 TO MAX_PATTERNS) AS String
DIM SHARED PatAction(1 TO MAX_PATTERNS) AS Integer
DIM SHARED PatArg(1 TO MAX_PATTERNS) AS LongInt
DIM SHARED PatPriority(1 TO MAX_PATTERNS) AS Integer
DIM SHARED PatOrder(1 TO MAX_PATTERNS) AS Integer
DIM SHARED PatCount AS Integer

DIM SHARED LoopStack(1 TO MAX_LOOP_STACK) AS Integer
DIM SHARED LoopSP AS Integer
DIM SHARED LoopCount AS Integer

DIM SHARED StrId(1 TO MAX_STRINGS) AS Integer
DIM SHARED StrStartCell(1 TO MAX_STRINGS) AS ULongInt
DIM SHARED StrText(1 TO MAX_STRINGS) AS String
DIM SHARED StrCount AS Integer

DIM SHARED OutFF AS Integer
DIM SHARED HadError AS Integer
DIM SHARED WarningCount AS Integer

DIM SHARED CellBits AS Integer
DIM SHARED CellBytes AS Integer

DIM SHARED TapeBytes AS ULongInt
DIM SHARED TapeCells AS ULongInt

DIM SHARED DataBytes AS ULongInt
DIM SHARED DataCells AS ULongInt

DIM SHARED StackBytes AS ULongInt
DIM SHARED StackCells AS ULongInt

DIM SHARED BoundsCheck AS Integer
DIM SHARED OverflowMode AS Integer

CLS
PRINT "=============================================================="
PRINT " UX-MINIMA V2 COMPILER"
PRINT " FreeBASIC host -> Windows x64 NASM ASM"
PRINT "=============================================================="
PRINT

AskOptions

IF HadError = 0 THEN ReadSourceFile
IF HadError = 0 THEN Lexer
IF HadError = 0 THEN LoadPatterns
IF HadError = 0 THEN GenerateASM

PRINT

IF HadError <> 0 THEN
    PRINT "Derleme hatali bitti."
ELSE
    PRINT "ASM uretildi: "; OutASMName
    PRINT
    PRINT "NASM:"
    PRINT "  nasm -f win64 "; OutASMName; " -o build.obj"
    PRINT
    PRINT "FreeBASIC link:"
    PRINT "  fbc uxm_v2_runtime.bas build.obj -x program.exe"
END IF

END

' *****************************************************************
' OPTIONS
' *****************************************************************

SUB AskOptions()
    DIM s AS String
    DIM n AS Integer

    PRINT "Kaynak dosya (.uxm veya .txt): ";
    LINE INPUT InFileName

    IF LEN(TRIM(InFileName)) = 0 THEN
        CompileError "Kaynak dosya adi bos."
        EXIT SUB
    END IF

    PRINT "ASM cikis dosyasi [otomatik]: ";
    LINE INPUT s

    IF LEN(TRIM(s)) = 0 THEN
        OutASMName = DefaultASMName(InFileName)
    ELSE
        OutASMName = TRIM(s)
    END IF

    PRINT
    PRINT "Hucre tipi:"
    PRINT "  8  = byte"
    PRINT "  16 = word"
    PRINT "  32 = dword"
    PRINT "Secim [8]: ";
    LINE INPUT s

    IF LEN(TRIM(s)) = 0 THEN
        CellBits = 8
    ELSE
        CellBits = VAL(s)
    END IF

    SELECT CASE CellBits
        CASE 8
            CellBytes = 1
        CASE 16
            CellBytes = 2
        CASE 32
            CellBytes = 4
        CASE ELSE
            CompileError "Gecersiz hucre tipi. 8, 16 veya 32 secilmeli."
            EXIT SUB
    END SELECT

    PRINT "Tape boyutu KB [32]: ";
    LINE INPUT s
    IF LEN(TRIM(s)) = 0 THEN n = 32 ELSE n = VAL(s)
    IF n < 1 THEN n = 32
    TapeBytes = CULNGINT(n) * 1024
    TapeCells = TapeBytes \ CellBytes

    PRINT "Data alani KB [32]: ";
    LINE INPUT s
    IF LEN(TRIM(s)) = 0 THEN n = 32 ELSE n = VAL(s)
    IF n < 1 THEN n = 32
    DataBytes = CULNGINT(n) * 1024
    DataCells = DataBytes \ CellBytes

    PRINT "User stack alani KB [8]: ";
    LINE INPUT s
    IF LEN(TRIM(s)) = 0 THEN n = 8 ELSE n = VAL(s)
    IF n < 1 THEN n = 8
    StackBytes = CULNGINT(n) * 1024
    StackCells = StackBytes \ CellBytes

    PRINT
    PRINT "Overflow modu:"
    PRINT "  0 = wrap / dogal tasma"
    PRINT "  1 = check / tasma hatasi"
    PRINT "Secim [0]: ";
    LINE INPUT s

    IF LEN(TRIM(s)) = 0 THEN
        OverflowMode = OV_WRAP
    ELSE
        OverflowMode = VAL(s)
    END IF

    IF OverflowMode <> OV_WRAP AND OverflowMode <> OV_CHECK THEN
        CompileError "Gecersiz overflow modu."
        EXIT SUB
    END IF

    PRINT "Pointer sinir kontrolu:"
    PRINT "  1 = acik"
    PRINT "  0 = kapali"
    PRINT "Secim [1]: ";
    LINE INPUT s

    IF LEN(TRIM(s)) = 0 THEN
        BoundsCheck = 1
    ELSE
        BoundsCheck = VAL(s)
    END IF

    IF BoundsCheck <> 0 THEN BoundsCheck = 1

    PRINT
    PRINT "Ayarlar:"
    PRINT "  Cell bits     : "; CellBits
    PRINT "  Cell bytes    : "; CellBytes
    PRINT "  Tape bytes    : "; TapeBytes
    PRINT "  Tape cells    : "; TapeCells
    PRINT "  Data bytes    : "; DataBytes
    PRINT "  Data cells    : "; DataCells
    PRINT "  Stack bytes   : "; StackBytes
    PRINT "  Stack cells   : "; StackCells

    IF OverflowMode = OV_WRAP THEN
        PRINT "  Overflow      : wrap"
    ELSE
        PRINT "  Overflow      : check"
    END IF

    IF BoundsCheck <> 0 THEN
        PRINT "  Bounds check  : on"
    ELSE
        PRINT "  Bounds check  : off"
    END IF

    PRINT
END SUB

FUNCTION DefaultASMName(ByVal srcName As String) As String
    DIM i AS Integer
    DIM dotPos AS Integer

    dotPos = 0

    FOR i = LEN(srcName) TO 1 STEP -1
        IF MID(srcName, i, 1) = "." THEN
            dotPos = i
            EXIT FOR
        END IF
    NEXT i

    IF dotPos > 0 THEN
        DefaultASMName = LEFT(srcName, dotPos - 1) + ".asm"
    ELSE
        DefaultASMName = srcName + ".asm"
    END IF
END FUNCTION

' *****************************************************************
' SOURCE
' *****************************************************************

SUB ReadSourceFile()
    DIM ff AS Integer
    DIM sz AS LongInt

    ff = FREEFILE

    OPEN InFileName FOR BINARY AS #ff
    sz = LOF(ff)

    IF sz <= 0 THEN
        Src = ""
    ELSE
        Src = SPACE(sz)
        GET #ff, , Src
    END IF

    CLOSE #ff

    ' UTF-8 BOM temizle: EF BB BF
    IF LEN(Src) >= 3 THEN
        IF (ASC(MID(Src, 1, 1)) AND &HFF) = &HEF AND _
           (ASC(MID(Src, 2, 1)) AND &HFF) = &HBB AND _
           (ASC(MID(Src, 3, 1)) AND &HFF) = &HBF THEN
            Src = MID(Src, 4)
        END IF
    END IF
END SUB

' *****************************************************************
' LEXER + DIRECTIVE PARSER
' *****************************************************************

SUB Lexer()
    DIM i AS Integer
    DIM j AS Integer
    DIM c AS String
    DIM nextC AS String
    DIM numText AS String
    DIM repeatCount AS ULongInt

    TokenCount = 0
    StrCount = 0

    i = 1

    DO WHILE i <= LEN(Src) AND HadError = 0

        c = MID(Src, i, 1)

        IF c = "s" OR c = "S" THEN
            IF TryParseStringDecl(i) <> 0 THEN
                CONTINUE DO
            END IF
        END IF

        IF c = "p" OR c = "P" THEN
            IF TryParsePrintString(i) <> 0 THEN
                CONTINUE DO
            END IF
        END IF

        IF INSTR(COMMAND_CHARS, c) > 0 THEN

            IF i + 2 <= LEN(Src) THEN
                nextC = MID(Src, i + 1, 1)

                IF (nextC = "k" OR nextC = "K") AND IsDigitChar(MID(Src, i + 2, 1)) <> 0 THEN

                    j = i + 2
                    numText = ""

                    DO WHILE j <= LEN(Src)
                        IF IsDigitChar(MID(Src, j, 1)) = 0 THEN EXIT DO
                        numText = numText + MID(Src, j, 1)
                        j = j + 1
                    LOOP

                    repeatCount = CULNGINT(VAL(numText))

                    IF repeatCount > MAX_REPEAT_COUNT THEN
                        CompileError "Repeat macro cok buyuk: " + c + "k" + numText
                        EXIT SUB
                    END IF

                    AddRepeatedToken c, repeatCount
                    i = j

                ELSE
                    AddToken c
                    i = i + 1
                END IF

            ELSE
                AddToken c
                i = i + 1
            END IF

        ELSE
            i = i + 1
        END IF

    LOOP

    PRINT "Token sayisi : "; TokenCount
    PRINT "String sayisi: "; StrCount
END SUB

SUB AddToken(ByVal t As String)
    IF HadError <> 0 THEN EXIT SUB

    IF TokenCount >= MAX_TOKENS THEN
        CompileError "Token dizisi doldu. MAX_TOKENS artirilmali."
        EXIT SUB
    END IF

    TokenCount = TokenCount + 1
    Tokens(TokenCount) = t
END SUB

SUB AddRepeatedToken(ByVal c As String, ByVal countVal As ULongInt)
    DIM n AS ULongInt

    IF HadError <> 0 THEN EXIT SUB
    IF countVal = 0 THEN EXIT SUB

    IF TokenCount + countVal > MAX_TOKENS THEN
        CompileError "Repeat macro token limitini asti: " + c + "k" + STR(countVal)
        EXIT SUB
    END IF

    FOR n = 1 TO countVal
        TokenCount = TokenCount + 1
        Tokens(TokenCount) = c
    NEXT n
END SUB

FUNCTION TryParseStringDecl(ByRef pos As Integer) As Integer
    DIM p AS Integer
    DIM ok AS Integer
    DIM sid AS ULongInt
    DIM startCell AS ULongInt
    DIM txt AS String

    p = pos

    IF p > LEN(Src) THEN
        TryParseStringDecl = 0
        EXIT FUNCTION
    END IF

    IF MID(Src, p, 1) <> "s" AND MID(Src, p, 1) <> "S" THEN
        TryParseStringDecl = 0
        EXIT FUNCTION
    END IF

    p = p + 1

    IF p > LEN(Src) THEN
        TryParseStringDecl = 0
        EXIT FUNCTION
    END IF

    IF IsDigitChar(MID(Src, p, 1)) = 0 THEN
        TryParseStringDecl = 0
        EXIT FUNCTION
    END IF

    sid = ParseUnsignedNumber(p, ok)
    IF ok = 0 THEN
        CompileError "String numarasi okunamadi."
        TryParseStringDecl = 1
        EXIT FUNCTION
    END IF

    SkipSpaces p

    IF p > LEN(Src) OR MID(Src, p, 1) <> "=" THEN
        CompileError "String taniminda '=' bekleniyor."
        TryParseStringDecl = 1
        EXIT FUNCTION
    END IF

    p = p + 1
    SkipSpaces p

    startCell = ParseUnsignedNumber(p, ok)
    IF ok = 0 THEN
        CompileError "String baslangic data hucre no okunamadi."
        TryParseStringDecl = 1
        EXIT FUNCTION
    END IF

    SkipSpaces p

    IF p > LEN(Src) OR MID(Src, p, 1) <> "," THEN
        CompileError "String taniminda ',' bekleniyor."
        TryParseStringDecl = 1
        EXIT FUNCTION
    END IF

    p = p + 1
    SkipSpaces p

    txt = ParseBracedString(p, ok)
    IF ok = 0 THEN
        CompileError "String metni { ... } arasinda okunamadi."
        TryParseStringDecl = 1
        EXIT FUNCTION
    END IF

    AddStringDecl CINT(sid), startCell, txt

    pos = p
    TryParseStringDecl = 1
END FUNCTION

FUNCTION TryParsePrintString(ByRef pos As Integer) As Integer
    DIM p AS Integer
    DIM ok AS Integer
    DIM sid AS ULongInt

    p = pos

    IF p > LEN(Src) THEN
        TryParsePrintString = 0
        EXIT FUNCTION
    END IF

    IF MID(Src, p, 1) <> "p" AND MID(Src, p, 1) <> "P" THEN
        TryParsePrintString = 0
        EXIT FUNCTION
    END IF

    p = p + 1

    IF p > LEN(Src) THEN
        TryParsePrintString = 0
        EXIT FUNCTION
    END IF

    IF IsDigitChar(MID(Src, p, 1)) = 0 THEN
        TryParsePrintString = 0
        EXIT FUNCTION
    END IF

    sid = ParseUnsignedNumber(p, ok)
    IF ok = 0 THEN
        CompileError "p komutunda string numarasi okunamadi."
        TryParsePrintString = 1
        EXIT FUNCTION
    END IF

    AddToken "P:" + LTRIM(STR(sid))

    pos = p
    TryParsePrintString = 1
END FUNCTION

FUNCTION ParseUnsignedNumber(ByRef pos As Integer, ByRef ok As Integer) As ULongInt
    DIM s AS String

    s = ""
    ok = 0

    DO WHILE pos <= LEN(Src)
        IF IsDigitChar(MID(Src, pos, 1)) = 0 THEN EXIT DO
        s = s + MID(Src, pos, 1)
        pos = pos + 1
    LOOP

    IF LEN(s) = 0 THEN
        ParseUnsignedNumber = 0
        EXIT FUNCTION
    END IF

    ok = 1
    ParseUnsignedNumber = CULNGINT(VAL(s))
END FUNCTION

FUNCTION ParseBracedString(ByRef pos As Integer, ByRef ok As Integer) As String
    DIM r AS String
    DIM c AS String
    DIM n AS String

    r = ""
    ok = 0

    IF pos > LEN(Src) THEN EXIT FUNCTION
    IF MID(Src, pos, 1) <> "{" THEN EXIT FUNCTION

    pos = pos + 1

    DO WHILE pos <= LEN(Src)
        c = MID(Src, pos, 1)

        IF c = "\" THEN
            IF pos + 1 <= LEN(Src) THEN
                n = MID(Src, pos + 1, 1)

                SELECT CASE n
                    CASE "n"
                        r = r + CHR(10)
                    CASE "r"
                        r = r + CHR(13)
                    CASE "t"
                        r = r + CHR(9)
                    CASE "{"
                        r = r + "{"
                    CASE "}"
                        r = r + "}"
                    CASE "\"
                        r = r + "\"
                    CASE ELSE
                        r = r + n
                END SELECT

                pos = pos + 2
            ELSE
                r = r + c
                pos = pos + 1
            END IF

        ELSEIF c = "}" THEN
            pos = pos + 1
            ok = 1
            ParseBracedString = r
            EXIT FUNCTION

        ELSE
            r = r + c
            pos = pos + 1
        END IF
    LOOP

    ParseBracedString = r
END FUNCTION

SUB SkipSpaces(ByRef pos As Integer)
    DO WHILE pos <= LEN(Src)
        SELECT CASE MID(Src, pos, 1)
            CASE " ", CHR(9), CHR(13), CHR(10)
                pos = pos + 1
            CASE ELSE
                EXIT DO
        END SELECT
    LOOP
END SUB

SUB AddStringDecl(ByVal sid As Integer, ByVal startCell As ULongInt, ByVal txt As String)
    DIM i AS Integer

    IF HadError <> 0 THEN EXIT SUB

    IF sid < 0 THEN
        CompileError "String numarasi negatif olamaz."
        EXIT SUB
    END IF

    IF StrCount >= MAX_STRINGS THEN
        CompileError "String tablosu doldu."
        EXIT SUB
    END IF

    FOR i = 1 TO StrCount
        IF StrId(i) = sid THEN
            CompileError "Ayni string numarasi tekrar kullanildi: s" + LTRIM(STR(sid))
            EXIT SUB
        END IF
    NEXT i

    IF startCell + LEN(txt) + 1 >= DataCells THEN
        CompileError "String data alanini asiyor: s" + LTRIM(STR(sid))
        EXIT SUB
    END IF

    StrCount = StrCount + 1
    StrId(StrCount) = sid
    StrStartCell(StrCount) = startCell
    StrText(StrCount) = txt
END SUB

FUNCTION FindStringIndexById(ByVal sid As Integer) As Integer
    DIM i AS Integer

    FOR i = 1 TO StrCount
        IF StrId(i) = sid THEN
            FindStringIndexById = i
            EXIT FUNCTION
        END IF
    NEXT i

    FindStringIndexById = 0
END FUNCTION

FUNCTION IsDigitChar(ByVal c As String) As Integer
    IF LEN(c) = 0 THEN
        IsDigitChar = 0
    ELSEIF c >= "0" AND c <= "9" THEN
        IsDigitChar = 1
    ELSE
        IsDigitChar = 0
    END IF
END FUNCTION

FUNCTION IsTokenPrintString(ByVal t As String) As Integer
    IF LEFT(t, 2) = "P:" THEN
        IsTokenPrintString = 1
    ELSE
        IsTokenPrintString = 0
    END IF
END FUNCTION

FUNCTION PrintStringIdFromToken(ByVal t As String) As Integer
    PrintStringIdFromToken = VAL(MID(t, 3))
END FUNCTION

' *****************************************************************
' PATTERN BANK
' *****************************************************************

SUB LoadPatterns()
    DIM n AS Integer

    PatCount = 0
    WarningCount = 0

    AddPattern "[->+<]", ACT_MOVE_ADD_RIGHT_CLEAR, 1
    AddPattern "[>+<-]", ACT_MOVE_ADD_RIGHT_CLEAR, 1
    AddPattern "[<+>-]", ACT_MOVE_ADD_LEFT_CLEAR, -1
    AddPattern "[-]", ACT_CLEAR_CUR, 0
    AddPattern "[+]", ACT_CLEAR_CUR, 0

    FOR n = 1 TO 128
        AddPattern "0" + RepeatChar("+", n), ACT_SET_CUR, n
    NEXT n

    FOR n = 1 TO 32
        AddPattern "0" + RepeatChar("+", n) + "@", ACT_META_CONST, n
    NEXT n

    FOR n = 2 TO 512
        AddPattern RepeatChar("+", n), ACT_ADD_CUR, n
        AddPattern RepeatChar("-", n), ACT_SUB_CUR, n
        AddPattern RepeatChar(">", n), ACT_MOVE_PTR, n
        AddPattern RepeatChar("<", n), ACT_MOVE_PTR, -n
    NEXT n

    AddPattern "$%", ACT_NOP, 0
    AddPattern "+-", ACT_NOP, 0
    AddPattern "-+", ACT_NOP, 0
    AddPattern "<>", ACT_NOP, 0
    AddPattern "><", ACT_NOP, 0

    AddPattern "&&", ACT_DOUBLE_CUR, 0
    AddPattern "||", ACT_HALF_CUR, 0

    SortPatternsByPriority

    PRINT "Pattern sayisi: "; PatCount
END SUB

SUB AddPattern(ByVal p As String, ByVal actionId As Integer, ByVal argVal As LongInt)
    DIM i AS Integer
    DIM q AS String

    q = NormalizePattern(p)

    IF LEN(q) = 0 THEN EXIT SUB

    IF PatternIsBalanced(q) = 0 THEN
        WarningCount = WarningCount + 1
        EXIT SUB
    END IF

    FOR i = 1 TO PatCount
        IF Pat(i) = q THEN EXIT SUB
    NEXT i

    IF PatCount >= MAX_PATTERNS THEN
        CompileError "Pattern dizisi doldu."
        EXIT SUB
    END IF

    PatCount = PatCount + 1
    Pat(PatCount) = q
    PatAction(PatCount) = actionId
    PatArg(PatCount) = argVal
    PatPriority(PatCount) = SpecificityScore(q)
    PatOrder(PatCount) = PatCount
END SUB

FUNCTION RepeatChar(ByVal ch As String, ByVal n As Integer) As String
    DIM i AS Integer
    DIM r AS String

    r = ""

    FOR i = 1 TO n
        r = r + ch
    NEXT i

    RepeatChar = r
END FUNCTION

FUNCTION NormalizePattern(ByVal s As String) As String
    DIM i AS Integer
    DIM c AS String
    DIM r AS String

    r = ""

    FOR i = 1 TO LEN(s)
        c = MID(s, i, 1)

        IF c <> " " AND c <> CHR(9) THEN
            r = r + c
        END IF
    NEXT i

    NormalizePattern = r
END FUNCTION

FUNCTION PatternIsBalanced(ByVal s As String) As Integer
    DIM i AS Integer
    DIM bal AS Integer
    DIM c AS String

    bal = 0

    FOR i = 1 TO LEN(s)
        c = MID(s, i, 1)

        IF c = "[" THEN
            bal = bal + 1
        ELSEIF c = "]" THEN
            bal = bal - 1
            IF bal < 0 THEN
                PatternIsBalanced = 0
                EXIT FUNCTION
            END IF
        END IF
    NEXT i

    IF bal = 0 THEN
        PatternIsBalanced = 1
    ELSE
        PatternIsBalanced = 0
    END IF
END FUNCTION

FUNCTION SpecificityScore(ByVal p As String) As Integer
    DIM i AS Integer
    DIM c AS String
    DIM score AS Integer
    DIM seen AS String
    DIM uniqueChars AS Integer
    DIM allSame AS Integer

    score = 0
    seen = ""
    uniqueChars = 0
    allSame = 1

    FOR i = 1 TO LEN(p)
        c = MID(p, i, 1)

        IF INSTR(seen, c) = 0 THEN
            seen = seen + c
            uniqueChars = uniqueChars + 1
        END IF

        IF i > 1 THEN
            IF c <> MID(p, 1, 1) THEN allSame = 0
        END IF

        SELECT CASE c
            CASE "[", "]"
                score = score + 100
            CASE "@"
                score = score + 90
            CASE "$", "%"
                score = score + 80
            CASE "!", "?", "&", "|", "^"
                score = score + 60
            CASE ".", ","
                score = score + 50
            CASE "0"
                score = score + 40
            CASE ">", "<"
                score = score + 20
            CASE "+", "-"
                score = score + 15
            CASE ELSE
                score = score + 1
        END SELECT
    NEXT i

    score = score + uniqueChars * 25
    IF allSame <> 0 THEN score = score - 40

    SpecificityScore = score
END FUNCTION

FUNCTION PatternCompare(ByVal a As Integer, ByVal b As Integer) As Integer
    IF LEN(Pat(a)) > LEN(Pat(b)) THEN
        PatternCompare = 1
        EXIT FUNCTION
    END IF

    IF LEN(Pat(a)) < LEN(Pat(b)) THEN
        PatternCompare = 0
        EXIT FUNCTION
    END IF

    IF PatPriority(a) > PatPriority(b) THEN
        PatternCompare = 1
        EXIT FUNCTION
    END IF

    IF PatPriority(a) < PatPriority(b) THEN
        PatternCompare = 0
        EXIT FUNCTION
    END IF

    IF PatOrder(a) < PatOrder(b) THEN
        PatternCompare = 1
    ELSE
        PatternCompare = 0
    END IF
END FUNCTION

SUB SortPatternsByPriority()
    DIM i AS Integer
    DIM j AS Integer

    DIM tp AS String
    DIM ta AS Integer
    DIM targ AS LongInt
    DIM tpri AS Integer
    DIM tord AS Integer

    FOR i = 1 TO PatCount - 1
        FOR j = i + 1 TO PatCount
            IF PatternCompare(j, i) <> 0 THEN
                tp = Pat(i)
                ta = PatAction(i)
                targ = PatArg(i)
                tpri = PatPriority(i)
                tord = PatOrder(i)

                Pat(i) = Pat(j)
                PatAction(i) = PatAction(j)
                PatArg(i) = PatArg(j)
                PatPriority(i) = PatPriority(j)
                PatOrder(i) = PatOrder(j)

                Pat(j) = tp
                PatAction(j) = ta
                PatArg(j) = targ
                PatPriority(j) = tpri
                PatOrder(j) = tord
            END IF
        NEXT j
    NEXT i
END SUB

FUNCTION MatchPattern(ByVal startIdx As Integer) As Integer
    DIM p AS Integer
    DIM j AS Integer
    DIM pLen AS Integer
    DIM ok AS Integer

    IF IsTokenPrintString(Tokens(startIdx)) <> 0 THEN
        MatchPattern = 0
        EXIT FUNCTION
    END IF

    FOR p = 1 TO PatCount
        pLen = LEN(Pat(p))

        IF startIdx + pLen - 1 <= TokenCount THEN
            ok = 1

            FOR j = 0 TO pLen - 1
                IF IsTokenPrintString(Tokens(startIdx + j)) <> 0 THEN
                    ok = 0
                    EXIT FOR
                END IF

                IF Tokens(startIdx + j) <> MID(Pat(p), j + 1, 1) THEN
                    ok = 0
                    EXIT FOR
                END IF
            NEXT j

            IF ok <> 0 THEN
                MatchPattern = p
                EXIT FUNCTION
            END IF
        END IF
    NEXT p

    MatchPattern = 0
END FUNCTION

' *****************************************************************
' ASM HELPERS
' *****************************************************************

FUNCTION SizePrefix() As String
    SELECT CASE CellBits
        CASE 8
            SizePrefix = "byte"
        CASE 16
            SizePrefix = "word"
        CASE 32
            SizePrefix = "dword"
        CASE ELSE
            SizePrefix = "byte"
    END SELECT
END FUNCTION

FUNCTION StoreReg() As String
    SELECT CASE CellBits
        CASE 8
            StoreReg = "al"
        CASE 16
            StoreReg = "ax"
        CASE 32
            StoreReg = "eax"
        CASE ELSE
            StoreReg = "al"
    END SELECT
END FUNCTION

FUNCTION MaxValue() As ULongInt
    SELECT CASE CellBits
        CASE 8
            MaxValue = 255
        CASE 16
            MaxValue = 65535
        CASE 32
            MaxValue = 4294967295ULL
        CASE ELSE
            MaxValue = 255
    END SELECT
END FUNCTION

FUNCTION MaxValueText() As String
    SELECT CASE CellBits
        CASE 8
            MaxValueText = "255"
        CASE 16
            MaxValueText = "65535"
        CASE 32
            MaxValueText = "4294967295"
        CASE ELSE
            MaxValueText = "255"
    END SELECT
END FUNCTION

FUNCTION ReduceValue(ByVal v As ULongInt) As ULongInt
    SELECT CASE CellBits
        CASE 8
            ReduceValue = v MOD 256
        CASE 16
            ReduceValue = v MOD 65536
        CASE 32
            ReduceValue = v MOD 4294967296ULL
        CASE ELSE
            ReduceValue = v MOD 256
    END SELECT
END FUNCTION

FUNCTION IndexExpr(ByVal baseReg As String, ByVal indexReg As String, ByVal offCells As LongInt) As String
    DIM s AS String
    DIM disp AS LongInt

    SELECT CASE CellBytes
        CASE 1
            s = baseReg + " + " + indexReg
        CASE 2
            s = baseReg + " + " + indexReg + "*2"
        CASE 4
            s = baseReg + " + " + indexReg + "*4"
        CASE ELSE
            s = baseReg + " + " + indexReg
    END SELECT

    disp = offCells * CellBytes

    IF disp > 0 THEN
        s = s + " + " + LTRIM(STR(disp))
    ELSEIF disp < 0 THEN
        s = s + " - " + LTRIM(STR(ABS(disp)))
    END IF

    IndexExpr = "[" + s + "]"
END FUNCTION

FUNCTION CellOp(ByVal offCells As LongInt) As String
    CellOp = SizePrefix() + " " + IndexExpr("r12", "rbx", offCells)
END FUNCTION

FUNCTION StackOp() As String
    StackOp = SizePrefix() + " " + IndexExpr("r13", "r14", 0)
END FUNCTION

FUNCTION DataByteOffset(ByVal cellNo As ULongInt) As ULongInt
    DataByteOffset = cellNo * CellBytes
END FUNCTION

FUNCTION DataCellOpConst(ByVal cellNo As ULongInt) As String
    DataCellOpConst = SizePrefix() + " [ux_data + " + LTRIM(STR(DataByteOffset(cellNo))) + "]"
END FUNCTION

' *****************************************************************
' ASM GENERATOR
' *****************************************************************

SUB GenerateASM()
    DIM i AS Integer
    DIM pIdx AS Integer

    OutFF = FREEFILE
    OPEN OutASMName FOR OUTPUT AS #OutFF

    EmitHeader
    EmitStringInitializers

    i = 1

    DO WHILE i <= TokenCount AND HadError = 0

        IF IsTokenPrintString(Tokens(i)) <> 0 THEN
            EmitPrintStringById PrintStringIdFromToken(Tokens(i))
            i = i + 1
        ELSE
            pIdx = MatchPattern(i)

            IF pIdx > 0 THEN
                EmitLine "    ; pattern: " + Pat(pIdx)
                EmitPattern pIdx
                i = i + LEN(Pat(pIdx))
            ELSE
                EmitSingleToken Tokens(i)
                i = i + 1
            END IF
        END IF

    LOOP

    IF LoopSP <> 0 THEN
        CompileError "Eksik ']' var. Acilan loop kapatilmamis."
        EmitLine "    ; ERROR: unclosed loop"
    END IF

    EmitFooter

    CLOSE #OutFF
END SUB

SUB EmitHeader()
    EmitLine "; *****************************************************************"
    EmitLine "; UX-MINIMA V2 generated Windows x64 NASM output"
    EmitLine "; Assemble:"
    EmitLine ";   nasm -f win64 this_file.asm -o build.obj"
    EmitLine "; Link:"
    EmitLine ";   fbc uxm_v2_runtime.bas build.obj -x program.exe"
    EmitLine "; *****************************************************************"
    EmitLine ""
    EmitLine "default rel"
    EmitLine ""
    EmitLine "global uxm_entry"
    EmitLine ""
    EmitLine "extern ux_putc"
    EmitLine "extern ux_getc"
    EmitLine "extern ux_print_cells"
    EmitLine "extern ux_meta_call"
    EmitLine "extern ux_ptr_oob"
    EmitLine "extern ux_stack_overflow"
    EmitLine "extern ux_stack_underflow"
    EmitLine "extern ux_overflow_error"
    EmitLine "extern ux_exit"
    EmitLine ""
    EmitLine "%define TAPE_BYTES  " + LTRIM(STR(TapeBytes))
    EmitLine "%define TAPE_CELLS  " + LTRIM(STR(TapeCells))
    EmitLine "%define DATA_BYTES  " + LTRIM(STR(DataBytes))
    EmitLine "%define DATA_CELLS  " + LTRIM(STR(DataCells))
    EmitLine "%define STACK_BYTES " + LTRIM(STR(StackBytes))
    EmitLine "%define STACK_CELLS " + LTRIM(STR(StackCells))
    EmitLine "%define CELL_BITS   " + LTRIM(STR(CellBits))
    EmitLine "%define CELL_BYTES  " + LTRIM(STR(CellBytes))
    EmitLine ""
    EmitLine "section .bss"
    EmitLine "align 16"
    EmitLine "ux_tape:   resb TAPE_BYTES"
    EmitLine "ux_data:   resb DATA_BYTES"
    EmitLine "ux_stack:  resb STACK_BYTES"
    EmitLine ""
    EmitLine "section .text"
    EmitLine ""
    EmitLine "uxm_entry:"
    EmitLine "    push rbp"
    EmitLine "    mov rbp, rsp"
    EmitLine "    push rbx"
    EmitLine "    push r12"
    EmitLine "    push r13"
    EmitLine "    push r14"
    EmitLine "    push r15"
    EmitLine ""
    EmitLine "    ; Windows x64 shadow space + alignment"
    EmitLine "    sub rsp, 40"
    EmitLine ""
    EmitLine "    lea r12, [ux_tape]"
    EmitLine "    xor rbx, rbx"
    EmitLine "    lea r13, [ux_stack]"
    EmitLine "    xor r14, r14"
    EmitLine ""
    EmitLine "    ; string/data initializers and generated code start"
    EmitLine ""
END SUB

SUB EmitFooter()
    EmitLine ""
    EmitLine "    ; generated code end"
    EmitLine "    xor ecx, ecx"
    EmitLine "    call ux_exit"
    EmitLine ""
    EmitLine "__ux_return:"
    EmitLine "    add rsp, 40"
    EmitLine "    pop r15"
    EmitLine "    pop r14"
    EmitLine "    pop r13"
    EmitLine "    pop r12"
    EmitLine "    pop rbx"
    EmitLine "    pop rbp"
    EmitLine "    ret"
    EmitLine ""
    EmitLine "__ux_ptr_oob:"
    EmitLine "    call ux_ptr_oob"
    EmitLine "    jmp __ux_return"
    EmitLine ""
    EmitLine "__ux_stack_overflow:"
    EmitLine "    call ux_stack_overflow"
    EmitLine "    jmp __ux_return"
    EmitLine ""
    EmitLine "__ux_stack_underflow:"
    EmitLine "    call ux_stack_underflow"
    EmitLine "    jmp __ux_return"
    EmitLine ""
    EmitLine "__ux_overflow:"
    EmitLine "    call ux_overflow_error"
    EmitLine "    jmp __ux_return"
END SUB

SUB EmitLine(ByVal s As String)
    PRINT #OutFF, s
END SUB

SUB EmitStringInitializers()
    DIM i AS Integer
    DIM j AS Integer
    DIM chVal AS Integer
    DIM startCell AS ULongInt
    DIM txt AS String

    IF StrCount = 0 THEN EXIT SUB

    EmitLine "    ; string initializers into ux_data"

    FOR i = 1 TO StrCount
        startCell = StrStartCell(i)
        txt = StrText(i)

        EmitLine "    ; s" + LTRIM(STR(StrId(i))) + " data cell " + LTRIM(STR(startCell))

        FOR j = 1 TO LEN(txt)
            chVal = ASC(MID(txt, j, 1)) AND &HFF
            EmitLine "    mov " + DataCellOpConst(startCell + j - 1) + ", " + LTRIM(STR(chVal))
        NEXT j

        EmitLine "    mov " + DataCellOpConst(startCell + LEN(txt)) + ", 0"
    NEXT i

    EmitLine ""
END SUB

SUB EmitPattern(ByVal pIdx As Integer)
    SELECT CASE PatAction(pIdx)
        CASE ACT_NOP
            EmitLine "    nop"

        CASE ACT_ADD_CUR
            EmitAddCell 0, CULNGINT(PatArg(pIdx))

        CASE ACT_SUB_CUR
            EmitSubCell 0, CULNGINT(PatArg(pIdx))

        CASE ACT_MOVE_PTR
            EmitMovePtr PatArg(pIdx)

        CASE ACT_CLEAR_CUR
            EmitClearCell 0

        CASE ACT_SET_CUR
            EmitSetCell 0, CULNGINT(PatArg(pIdx))

        CASE ACT_META_CONST
            EmitMetaConst PatArg(pIdx)

        CASE ACT_MOVE_ADD_RIGHT_CLEAR
            EmitMoveAddClear 1

        CASE ACT_MOVE_ADD_LEFT_CLEAR
            EmitMoveAddClear -1

        CASE ACT_DOUBLE_CUR
            EmitDoubleCell

        CASE ACT_HALF_CUR
            EmitHalfCell

        CASE ELSE
            EmitLine "    ; unknown pattern action"
    END SELECT
END SUB

SUB EmitSingleToken(ByVal t As String)
    SELECT CASE t
        CASE ">"
            EmitMovePtr 1
        CASE "<"
            EmitMovePtr -1
        CASE "+"
            EmitAddCell 0, 1
        CASE "-"
            EmitSubCell 0, 1
        CASE "0"
            EmitClearCell 0
        CASE "."
            EmitPutChar
        CASE ","
            EmitGetChar
        CASE "["
            EmitLoopStart
        CASE "]"
            EmitLoopEnd
        CASE "@"
            EmitMetaFromCell
        CASE "$"
            EmitPushCell
        CASE "%"
            EmitPopCell
        CASE "&"
            EmitDoubleCell
        CASE "|"
            EmitHalfCell
        CASE "!", "?", "^"
            EmitLine "    ; reserved token: " + t
        CASE ELSE
            EmitLine "    ; ignored token: " + t
    END SELECT
END SUB

' *****************************************************************
' LOW LEVEL EMIT
' *****************************************************************

SUB EmitPointerCheck()
    IF BoundsCheck = 0 THEN EXIT SUB

    EmitLine "    cmp rbx, TAPE_CELLS"
    EmitLine "    jae __ux_ptr_oob"
END SUB

SUB EmitNeighborCheck(ByVal offCells As LongInt)
    IF BoundsCheck = 0 THEN EXIT SUB

    IF offCells > 0 THEN
        EmitLine "    cmp rbx, " + LTRIM(STR(TapeCells - offCells))
        EmitLine "    jae __ux_ptr_oob"
    ELSEIF offCells < 0 THEN
        EmitLine "    cmp rbx, " + LTRIM(STR(ABS(offCells)))
        EmitLine "    jb __ux_ptr_oob"
    END IF
END SUB

SUB EmitMovePtr(ByVal delta As LongInt)
    IF delta = 0 THEN EXIT SUB

    IF delta = 1 THEN
        EmitLine "    inc rbx"
    ELSEIF delta = -1 THEN
        EmitLine "    dec rbx"
    ELSEIF delta > 0 THEN
        EmitLine "    add rbx, " + LTRIM(STR(delta))
    ELSE
        EmitLine "    sub rbx, " + LTRIM(STR(ABS(delta)))
    END IF

    EmitPointerCheck
END SUB

SUB EmitSetCell(ByVal offCells As LongInt, ByVal value As ULongInt)
    DIM v AS ULongInt

    EmitNeighborCheck offCells

    IF OverflowMode = OV_CHECK THEN
        EmitLine "    mov rax, " + LTRIM(STR(value))
        EmitLine "    cmp rax, " + MaxValueText()
        EmitLine "    ja __ux_overflow"
        EmitLine "    mov " + CellOp(offCells) + ", " + StoreReg()
    ELSE
        v = ReduceValue(value)
        EmitLine "    mov " + CellOp(offCells) + ", " + LTRIM(STR(v))
    END IF
END SUB

SUB EmitClearCell(ByVal offCells As LongInt)
    EmitNeighborCheck offCells
    EmitLine "    mov " + CellOp(offCells) + ", 0"
END SUB

SUB EmitAddCell(ByVal offCells As LongInt, ByVal amount As ULongInt)
    DIM v AS ULongInt

    IF amount = 0 THEN EXIT SUB
    EmitNeighborCheck offCells

    IF OverflowMode = OV_WRAP THEN
        v = ReduceValue(amount)
        IF v = 0 THEN EXIT SUB

        IF v = 1 THEN
            EmitLine "    inc " + CellOp(offCells)
        ELSE
            EmitLine "    add " + CellOp(offCells) + ", " + LTRIM(STR(v))
        END IF
    ELSE
        SELECT CASE CellBits
            CASE 8
                EmitLine "    movzx eax, " + CellOp(offCells)
            CASE 16
                EmitLine "    movzx eax, " + CellOp(offCells)
            CASE 32
                EmitLine "    mov eax, " + CellOp(offCells)
        END SELECT

        EmitLine "    add rax, " + LTRIM(STR(amount))
        EmitLine "    cmp rax, " + MaxValueText()
        EmitLine "    ja __ux_overflow"
        EmitLine "    mov " + CellOp(offCells) + ", " + StoreReg()
    END IF
END SUB

SUB EmitSubCell(ByVal offCells As LongInt, ByVal amount As ULongInt)
    DIM v AS ULongInt

    IF amount = 0 THEN EXIT SUB
    EmitNeighborCheck offCells

    IF OverflowMode = OV_WRAP THEN
        v = ReduceValue(amount)
        IF v = 0 THEN EXIT SUB

        IF v = 1 THEN
            EmitLine "    dec " + CellOp(offCells)
        ELSE
            EmitLine "    sub " + CellOp(offCells) + ", " + LTRIM(STR(v))
        END IF
    ELSE
        SELECT CASE CellBits
            CASE 8
                EmitLine "    movzx eax, " + CellOp(offCells)
            CASE 16
                EmitLine "    movzx eax, " + CellOp(offCells)
            CASE 32
                EmitLine "    mov eax, " + CellOp(offCells)
        END SELECT

        EmitLine "    cmp rax, " + LTRIM(STR(amount))
        EmitLine "    jb __ux_overflow"
        EmitLine "    sub rax, " + LTRIM(STR(amount))
        EmitLine "    mov " + CellOp(offCells) + ", " + StoreReg()
    END IF
END SUB

SUB EmitPutChar()
    SELECT CASE CellBits
        CASE 8
            EmitLine "    movzx ecx, " + CellOp(0)
        CASE 16
            EmitLine "    movzx ecx, " + CellOp(0)
        CASE 32
            EmitLine "    mov ecx, " + CellOp(0)
    END SELECT

    EmitLine "    call ux_putc"
END SUB

SUB EmitGetChar()
    EmitLine "    call ux_getc"
    EmitLine "    mov " + CellOp(0) + ", " + StoreReg()
END SUB

SUB EmitMetaFromCell()
    SELECT CASE CellBits
        CASE 8
            EmitLine "    movzx ecx, " + CellOp(0)
        CASE 16
            EmitLine "    movzx ecx, " + CellOp(0)
        CASE 32
            EmitLine "    mov ecx, " + CellOp(0)
    END SELECT

    EmitLine "    call ux_meta_call"
    EmitLine "    mov " + CellOp(0) + ", " + StoreReg()
END SUB

SUB EmitMetaConst(ByVal metaId As LongInt)
    EmitLine "    mov ecx, " + LTRIM(STR(metaId))
    EmitLine "    call ux_meta_call"
    EmitLine "    mov " + CellOp(0) + ", " + StoreReg()
END SUB

SUB EmitPushCell()
    EmitLine "    cmp r14, STACK_CELLS"
    EmitLine "    jae __ux_stack_overflow"

    SELECT CASE CellBits
        CASE 8
            EmitLine "    movzx eax, " + CellOp(0)
        CASE 16
            EmitLine "    movzx eax, " + CellOp(0)
        CASE 32
            EmitLine "    mov eax, " + CellOp(0)
    END SELECT

    EmitLine "    mov " + StackOp() + ", " + StoreReg()
    EmitLine "    inc r14"
END SUB

SUB EmitPopCell()
    EmitLine "    cmp r14, 0"
    EmitLine "    je __ux_stack_underflow"
    EmitLine "    dec r14"

    SELECT CASE CellBits
        CASE 8
            EmitLine "    movzx eax, " + StackOp()
        CASE 16
            EmitLine "    movzx eax, " + StackOp()
        CASE 32
            EmitLine "    mov eax, " + StackOp()
    END SELECT

    EmitLine "    mov " + CellOp(0) + ", " + StoreReg()
END SUB

SUB EmitMoveAddClear(ByVal offCells As LongInt)
    EmitNeighborCheck offCells

    IF OverflowMode = OV_WRAP THEN
        SELECT CASE CellBits
            CASE 8
                EmitLine "    mov al, " + CellOp(0)
            CASE 16
                EmitLine "    mov ax, " + CellOp(0)
            CASE 32
                EmitLine "    mov eax, " + CellOp(0)
        END SELECT

        EmitLine "    add " + CellOp(offCells) + ", " + StoreReg()
        EmitLine "    mov " + CellOp(0) + ", 0"
    ELSE
        SELECT CASE CellBits
            CASE 8
                EmitLine "    movzx eax, " + CellOp(0)
            CASE 16
                EmitLine "    movzx eax, " + CellOp(0)
            CASE 32
                EmitLine "    mov eax, " + CellOp(0)
        END SELECT

        EmitLine "    mov r15, rax"

        SELECT CASE CellBits
            CASE 8
                EmitLine "    movzx eax, " + CellOp(offCells)
            CASE 16
                EmitLine "    movzx eax, " + CellOp(offCells)
            CASE 32
                EmitLine "    mov eax, " + CellOp(offCells)
        END SELECT

        EmitLine "    add rax, r15"
        EmitLine "    cmp rax, " + MaxValueText()
        EmitLine "    ja __ux_overflow"
        EmitLine "    mov " + CellOp(offCells) + ", " + StoreReg()
        EmitLine "    mov " + CellOp(0) + ", 0"
    END IF
END SUB

SUB EmitDoubleCell()
    IF OverflowMode = OV_WRAP THEN
        EmitLine "    shl " + CellOp(0) + ", 1"
    ELSE
        SELECT CASE CellBits
            CASE 8
                EmitLine "    movzx eax, " + CellOp(0)
            CASE 16
                EmitLine "    movzx eax, " + CellOp(0)
            CASE 32
                EmitLine "    mov eax, " + CellOp(0)
        END SELECT

        EmitLine "    shl rax, 1"
        EmitLine "    cmp rax, " + MaxValueText()
        EmitLine "    ja __ux_overflow"
        EmitLine "    mov " + CellOp(0) + ", " + StoreReg()
    END IF
END SUB

SUB EmitHalfCell()
    EmitLine "    shr " + CellOp(0) + ", 1"
END SUB

SUB EmitLoopStart()
    IF LoopSP >= MAX_LOOP_STACK THEN
        CompileError "Loop stack doldu."
        EXIT SUB
    END IF

    LoopCount = LoopCount + 1
    LoopSP = LoopSP + 1
    LoopStack(LoopSP) = LoopCount

    EmitLine "L" + LTRIM(STR(LoopCount)) + ":"
    EmitLine "    cmp " + CellOp(0) + ", 0"
    EmitLine "    je E" + LTRIM(STR(LoopCount))
END SUB

SUB EmitLoopEnd()
    DIM id AS Integer

    IF LoopSP <= 0 THEN
        CompileError "Fazla ']' bulundu. Eslesen '[' yok."
        EXIT SUB
    END IF

    id = LoopStack(LoopSP)
    LoopSP = LoopSP - 1

    EmitLine "    jmp L" + LTRIM(STR(id))
    EmitLine "E" + LTRIM(STR(id)) + ":"
END SUB

SUB EmitPrintStringById(ByVal sid As Integer)
    DIM idx AS Integer
    DIM offsetBytes AS ULongInt

    idx = FindStringIndexById(sid)

    IF idx = 0 THEN
        CompileError "Tanimlanmamis string basiliyor: p" + LTRIM(STR(sid))
        EXIT SUB
    END IF

    offsetBytes = DataByteOffset(StrStartCell(idx))

    EmitLine "    ; print string p" + LTRIM(STR(sid))
    EmitLine "    lea rcx, [ux_data + " + LTRIM(STR(offsetBytes)) + "]"
    EmitLine "    mov edx, CELL_BITS"
    EmitLine "    call ux_print_cells"
END SUB

' *****************************************************************
' ERROR
' *****************************************************************

SUB CompileError(ByVal msg As String)
    HadError = 1
    PRINT "HATA: "; msg
END SUB
```

---

# 4. Dosya 2 — `uxm_v2_runtime.bas`

```vbnet
' *****************************************************************
' UX-MINIMA V2 RUNTIME
' HOST: FreeBASIC
' LINK: fbc uxm_v2_runtime.bas build.obj -x program.exe
' *****************************************************************

OPTION EXPLICIT

#INCLUDE "windows.bi"

Extern "C"
    Declare Sub uxm_entry Alias "uxm_entry"()
End Extern

Sub ux_putc Cdecl Alias "ux_putc" (ByVal ch As ULong)
    PRINT CHR(ch AND &HFF);
End Sub

Function ux_getc Cdecl Alias "ux_getc" () As ULong
    DIM s AS String

    s = INPUT(1)

    IF LEN(s) = 0 THEN
        ux_getc = 0
    ELSE
        ux_getc = ASC(s, 1) AND &HFF
    END IF
End Function

Sub ux_print_cells Cdecl Alias "ux_print_cells" (ByVal p As Any Ptr, ByVal cellBits As ULong)
    DIM v AS ULong
    DIM pb AS UByte Ptr
    DIM pw AS UShort Ptr
    DIM pd AS UInteger Ptr

    SELECT CASE cellBits

        CASE 8
            pb = CAST(UByte Ptr, p)

            DO
                v = *pb
                IF v = 0 THEN EXIT DO
                PRINT CHR(v AND &HFF);
                pb = pb + 1
            LOOP

        CASE 16
            pw = CAST(UShort Ptr, p)

            DO
                v = *pw
                IF v = 0 THEN EXIT DO
                PRINT CHR(v AND &HFF);
                pw = pw + 1
            LOOP

        CASE 32
            pd = CAST(UInteger Ptr, p)

            DO
                v = *pd
                IF v = 0 THEN EXIT DO
                PRINT CHR(v AND &HFF);
                pd = pd + 1
            LOOP

        CASE ELSE
            PRINT "[UX-MINIMA ERROR] Gecersiz cellBits: "; cellBits

    END SELECT
End Sub

Function ux_meta_call Cdecl Alias "ux_meta_call" (ByVal id As ULong) As ULong
    SELECT CASE id

        CASE 0
            ux_meta_call = 0

        CASE 1
            CLS
            ux_meta_call = 0

        CASE 2
            LOCATE 1, 1
            ux_meta_call = 0

        CASE 3
            RANDOMIZE TIMER
            ux_meta_call = CULNG(INT(RND * 256)) AND &HFF

        CASE 4
            ux_meta_call = CULNG(TIMER * 1000) AND &HFFFFFFFF

        CASE 5
            PRINT
            ux_meta_call = 10

        CASE 6
            PRINT "[UX-MINIMA META]"
            ux_meta_call = 0

        CASE 7
            ux_meta_call = 7

        CASE 8
            ux_meta_call = 8

        CASE ELSE
            PRINT
            PRINT "[UX-MINIMA] Bilinmeyen meta komut: "; id
            ux_meta_call = id

    END SELECT
End Function

Sub ux_ptr_oob Cdecl Alias "ux_ptr_oob" ()
    PRINT
    PRINT "[UX-MINIMA ERROR] Tape pointer sinir disina cikti."
    END 10
End Sub

Sub ux_stack_overflow Cdecl Alias "ux_stack_overflow" ()
    PRINT
    PRINT "[UX-MINIMA ERROR] UX user stack doldu."
    END 11
End Sub

Sub ux_stack_underflow Cdecl Alias "ux_stack_underflow" ()
    PRINT
    PRINT "[UX-MINIMA ERROR] UX user stack bosken pop yapildi."
    END 12
End Sub

Sub ux_overflow_error Cdecl Alias "ux_overflow_error" ()
    PRINT
    PRINT "[UX-MINIMA ERROR] Hucre overflow/underflow hatasi."
    END 13
End Sub

Sub ux_exit Cdecl Alias "ux_exit" (ByVal code As ULong)
    END code
End Sub

' UTF-8 terminal denemesi.
' Windows terminal destekliyorsa Turkce karakterler daha duzgun gorunur.
SetConsoleOutputCP(65001)
SetConsoleCP(65001)

PRINT "UX-MINIMA V2 runtime started."
uxm_entry
PRINT
PRINT "UX-MINIMA V2 runtime finished."
```

---

# 5. Derleme sırası

```bash
fbc uxm_v2_compiler.bas -x uxm_v2_compiler.exe
```

Sonra compiler’ı çalıştır:

```bash
uxm_v2_compiler.exe
```

ASM üretildikten sonra:

```bash
nasm -f win64 test.asm -o build.obj
```

Link:

```bash
fbc uxm_v2_runtime.bas build.obj -x program.exe
```

Çalıştır:

```bash
program.exe
```

---

# 6. Örnek `.uxm` programları

## 6.1. A harfi basma

```text
+k65.
```

---

## 6.2. String basma

```text
s1=0,{Merhaba Mete abi}
p1
```

---

## 6.3. İki satır string

```text
s1=0,{Merhaba}
s2=100,{UX-MINIMA V2 calisiyor}

p1
0+++++@
p2
```

---

## 6.4. String + hücre karakteri

```text
s1=0,{Harf: }
p1
+k65.
```

Çıktı:

```text
Harf: A
```

---

## 6.5. Stack testi

```text
s1=0,{Stack testi: }
p1
+k65$>%.
```

Açıklama:

```text
+k65 = tape[0] = 65
$    = UX user stack'e push
>    = tape[1]'e geç
%    = stack'ten pop
.    = A bas
```

---

## 6.6. Hücre taşıma pattern testi

```text
s1=0,{Move pattern: }
p1
+k65[->+<]>.
```

Bu `[->+<]` pattern olarak optimize edilir.

---

# 7. Net hüküm

Bu yeni tasarımda:

```text
Ekrana basma     → FreeBASIC runtime
Tape işlemleri   → generated x64 ASM
String/değişken  → ux_data alanı
Push/pop         → UX-MINIMA user stack
CPU stack        → sadece Windows x64 çağrı düzeni için
```

Bence bu, UX-MINIMA’yı çok daha doğru bir noktaya taşıyor. Artık sadece sembolik Brainfuck benzeri bir deney değil; **tape + data segment + user stack + string directive + x64 NASM backend** olan gerçek bir mini compiler laboratuvarı haline geliyor.
