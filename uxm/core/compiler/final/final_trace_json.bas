' Auto-split by V3 modularization
Sub AddInstr(ByVal op As Long, ByVal amount As Long, ByVal ak As Long, ByVal av As Long, ByVal av2 As Long, ByVal txt As String, ByVal atPos As Long)
    instrCount += 1
    If instrCount > MAX_INSTR Then
        SyntaxError "instruction limiti doldu", atPos
        Exit Sub
    End If

    progInstr(instrCount).op = op
    progInstr(instrCount).amount = amount
    progInstr(instrCount).addrKind = ak
    progInstr(instrCount).addrVal = av
    progInstr(instrCount).addrVal2 = av2
    progInstr(instrCount).text = txt
    progInstr(instrCount).pos = atPos
    progInstr(instrCount).lineNo = LineOfPos(atPos)
    progInstr(instrCount).colNo = ColOfPos(atPos)
End Sub

Sub AddMeta(ByVal id As Long, ByVal dyn As Long, ByVal forceHost As Long, ByVal txt As String, ByVal atPos As Long)
    AddInstr OP_META, 0, ADDR_T, 0, 0, txt, atPos
    progInstr(instrCount).metaId = id
    progInstr(instrCount).metaDyn = dyn
    progInstr(instrCount).metaForceHost = forceHost
End Sub

Sub AddBranch(ByVal cond As Long, ByVal brDir As Long, ByVal dist As Long, ByVal txt As String, ByVal atPos As Long)
    AddInstr OP_BRANCH, 0, ADDR_T, 0, 0, txt, atPos
    progInstr(instrCount).brCond = cond
    progInstr(instrCount).brDir = brDir
    progInstr(instrCount).brDist = dist
End Sub

Sub AddString(ByVal id As Long, ByVal st As Long, ByVal txt As String, ByVal lineNo As Long)
    strCount += 1
    If strCount > MAX_STRINGS Then
        AddDiag "error", "string tablosu doldu", 1
        Exit Sub
    End If
    strDef(strCount).id = id
    strDef(strCount).startCell = st
    strDef(strCount).txt = txt
End Sub

Sub AddMacro(ByVal id As Long, ByVal txt As String, ByVal lineNo As Long)
    Dim i As Long
    For i = 1 To macroCount
        If macroDef(i).id = id Then
            macroDef(i).txt = txt
            Exit Sub
        End If
    Next

    macroCount += 1
    If macroCount > MAX_MACROS Then
        AddDiag "error", "macro tablosu doldu", 1
        Exit Sub
    End If
    macroDef(macroCount).id = id
    macroDef(macroCount).txt = txt
    macroDef(macroCount).lineNo = lineNo
End Sub

Sub AddDiag(ByVal sev As String, ByVal msg As String, ByVal atPos As Long)
    diagCount += 1
    If diagCount > MAX_DIAG Then Exit Sub
    diag(diagCount).severity = sev
    diag(diagCount).msg = msg
    diag(diagCount).pos = atPos
    diag(diagCount).lineNo = LineOfPos(atPos)
    diag(diagCount).colNo = ColOfPos(atPos)
End Sub

Sub SyntaxError(ByVal msg As String, ByVal atPos As Long)
    AddDiag "error", msg, atPos
    hadError = 1
    errMsg = "SYNTAX ERROR: " + msg
End Sub

Sub AddOpt(ByVal msg As String, ByVal beforeIp As Long, ByVal afterIp As Long)
    optCount += 1
    If optCount > MAX_OPT Then Exit Sub
    optEvent(optCount).msg = msg
    optEvent(optCount).beforeIp = beforeIp
    optEvent(optCount).afterIp = afterIp
End Sub

Sub ValidateProgram()
    Dim st(1 To 65536) As Long
    Dim spx As Long
    Dim i As Long
    Dim j As Long

    spx = 0
    For i = 1 To instrCount
        If progInstr(i).op = OP_LOOP_BEG Then
            spx += 1
            st(spx) = i
        End If

        If progInstr(i).op = OP_LOOP_END Then
            If spx <= 0 Then
                SyntaxError "fazla ]", progInstr(i).pos
                Exit Sub
            End If
            j = st(spx)
            spx -= 1
            progInstr(i).mate = j
            progInstr(j).mate = i
        End If
    Next

    If spx <> 0 Then
        SyntaxError "kapanmamış [", progInstr(st(spx)).pos
        Exit Sub
    End If

    For i = 1 To instrCount
        If progInstr(i).op = OP_BRANCH Then
            j = i + progInstr(i).brDir * progInstr(i).brDist
            If j < 1 Or j > instrCount Then
                SyntaxError "branch hedefi program dışında", progInstr(i).pos
                Exit Sub
            End If
            progInstr(i).brTarget = j
            needLabel(j) = 1
        End If
    Next
End Sub

Sub OptimizeProgram()
    Dim n As Long
    Dim i As Long
    Dim delta As LongInt
    Dim newI(1 To MAX_INSTR) As TInstr

    i = 1
    n = 0
    Do While i <= instrCount
        If i < instrCount Then
            If progInstr(i).op = OP_CLEAR And (progInstr(i + 1).op = OP_INC Or progInstr(i + 1).op = OP_DEC) And progInstr(i).addrKind = progInstr(i + 1).addrKind And progInstr(i).addrVal = progInstr(i + 1).addrVal And progInstr(i).addrVal2 = progInstr(i + 1).addrVal2 Then
                n += 1
                newI(n) = progInstr(i + 1)
                newI(n).op = OP_SET
                newI(n).text = "optimized_set"
                If progInstr(i + 1).op = OP_DEC Then
                    newI(n).amount = (CellMask() - progInstr(i + 1).amount + 1) And CellMask()
                End If
                AddOpt "CLEAR + INC/DEC -> SET", i, n
                i += 2
                Continue Do
            End If

            If (progInstr(i).op = OP_INC Or progInstr(i).op = OP_DEC) And (progInstr(i + 1).op = OP_INC Or progInstr(i + 1).op = OP_DEC) And progInstr(i).addrKind = progInstr(i + 1).addrKind And progInstr(i).addrVal = progInstr(i + 1).addrVal And progInstr(i).addrVal2 = progInstr(i + 1).addrVal2 Then
                delta = 0
                If progInstr(i).op = OP_INC Then
                    delta += progInstr(i).amount
                Else
                    delta -= progInstr(i).amount
                End If
                If progInstr(i + 1).op = OP_INC Then
                    delta += progInstr(i + 1).amount
                Else
                    delta -= progInstr(i + 1).amount
                End If
                If delta = 0 Then
                    AddOpt "INC/DEC cancel", i, n
                    i += 2
                    Continue Do
                End If

                n += 1
                newI(n) = progInstr(i)
                If delta > 0 Then
                    newI(n).op = OP_INC
                    newI(n).amount = delta
                Else
                    newI(n).op = OP_DEC
                    newI(n).amount = Abs(delta)
                End If
                newI(n).text = "optimized_arith_merge"
                AddOpt "INC/DEC merge", i, n
                i += 2
                Continue Do
            End If
        End If

        n += 1
        newI(n) = progInstr(i)
        i += 1
    Loop

    instrCount = n
    For i = 1 To instrCount
        progInstr(i) = newI(i)
    Next
End Sub

Sub TraceStart()
    If writeTrace = 0 Then Exit Sub
    traceFF = FreeFile
    Open traceFile For Output As #traceFF
    traceOpen = 1
    Print #traceFF, "{""type"":""start"",""version"":""" + JsonEsc(UXM_VERSION) + """,""cell_bits"":" + Str(cellBits) + ",""tape_cells"":" + Str(tapeCells) + ",""stack_cells"":" + Str(stackCells) + ",""data_cells"":" + Str(dataCells) + "}"
End Sub

Sub TraceStop()
    If traceOpen <> 0 Then
        Print #traceFF, "{""type"":""end"",""steps"":" + Str(stepCounter) + ",""status"":" + Str(statusByte) + ",""output"":""" + JsonEsc(outputText) + """}"
        Close #traceFF
    End If
    traceOpen = 0
End Sub

Sub TraceEvent(ByVal ip As Long, ByVal opLabel As String, ByVal extraJson As String)
    Dim lineText As String
    If traceOpen = 0 Then Exit Sub

    lineText = "{""type"":""step"",""step"":" + Str(stepCounter) + ",""ip"":" + Str(ip) + ",""op"":""" + opLabel + """,""src"":""" + JsonEsc(progInstr(ip).text) + """,""ptr"":" + Str(tapePtr) + ",""sp"":" + Str(stackPtr) + ",""fifo_count"":" + Str(fifoCount) + ",""status"":" + Str(statusByte) + ",""flags"":" + Str(flags) + ",""current"":" + Str(tape(tapePtr))
    Print #traceFF, lineText;
    If extraJson <> "" Then
        Print #traceFF, "," + extraJson;
    End If
    Print #traceFF, "}"
End Sub

Sub ExportUIR(ByVal fn As String)
    Dim ff As Integer
    Dim i As Long

    ff = FreeFile
    Open fn For Output As #ff
    Print #ff, "{""version"":""" + JsonEsc(UXM_VERSION) + """,""memory"":{""cell_bits"":" + Str(cellBits) + ",""tape_kb"":" + Str(tapeKB) + ",""stack_kb"":" + Str(stackKB) + ",""data_kb"":" + Str(dataKB) + "},""instructions"":"
    Print #ff, "["
    For i = 1 To instrCount
        Print #ff, "{""ip"":" + Str(i) + ",""op"":""" + OpName(progInstr(i).op) + """,""amount"":" + Str(progInstr(i).amount) + ",""addr"":""" + JsonEsc(AddrText(progInstr(i).addrKind, progInstr(i).addrVal, progInstr(i).addrVal2)) + """,""meta_id"":" + Str(progInstr(i).metaId) + ",""meta_dynamic"":" + Str(progInstr(i).metaDyn) + ",""meta_force_host"":" + Str(progInstr(i).metaForceHost) + ",""branch_target"":" + Str(progInstr(i).brTarget) + ",""mate"":" + Str(progInstr(i).mate) + ",""line"":" + Str(progInstr(i).lineNo) + ",""col"":" + Str(progInstr(i).colNo) + ",""text"":""" + JsonEsc(progInstr(i).text) + """}";
        If i < instrCount Then
            Print #ff, ","
        Else
            Print #ff, ""
        End If
    Next
    Print #ff, "]}"
    Close #ff
End Sub

Sub ExportDiagnostics(ByVal fn As String)
    Dim ff As Integer
    Dim i As Long

    ff = FreeFile
    Open fn For Output As #ff
    Print #ff, "{""diagnostics"":"
    Print #ff, "["
    For i = 1 To diagCount
        Print #ff, "{""severity"":""" + diag(i).severity + """,""message"":""" + JsonEsc(diag(i).msg) + """,""line"":" + Str(diag(i).lineNo) + ",""col"":" + Str(diag(i).colNo) + "}";
        If i < diagCount Then
            Print #ff, ","
        Else
            Print #ff, ""
        End If
    Next
    Print #ff, "]}"
    Close #ff
End Sub

Sub ExportOpt(ByVal fn As String)
    Dim ff As Integer
    Dim i As Long

    ff = FreeFile
    Open fn For Output As #ff
    Print #ff, "{""optimizer_events"":"
    Print #ff, "["
    For i = 1 To optCount
        Print #ff, "{""msg"":""" + JsonEsc(optEvent(i).msg) + """,""before_ip"":" + Str(optEvent(i).beforeIp) + ",""after_ip"":" + Str(optEvent(i).afterIp) + "}";
        If i < optCount Then
            Print #ff, ","
        Else
            Print #ff, ""
        End If
    Next
    Print #ff, "]}"
    Close #ff
End Sub

Sub ExportIdeResult()
    Dim ff As Integer
    ff = FreeFile
    Open ideOutFile For Output As #ff
    Print #ff, "{""version"":""" + JsonEsc(UXM_VERSION) + """,""status"":" + Str(statusByte) + ",""diagnostics"":" + Str(diagCount) + ",""instructions"":" + Str(instrCount) + ",""output"":""" + JsonEsc(outputText) + """,""asm"":""" + JsonEsc(asmFile) + """,""uir"":""" + JsonEsc(uirFile) + """,""trace"":""" + JsonEsc(traceFile) + """}"
    Close #ff
End Sub

Function JsonEsc(ByVal s As String) As String
    Dim r As String
    Dim i As Long
    Dim c As String

    r = ""
    For i = 1 To Len(s)
        c = Mid(s, i, 1)
        If c = Chr(34) Then
            r += "\" + Chr(34)
        ElseIf c = "\" Then
            r += "\\"
        ElseIf c = Chr(10) Then
            r += "\n"
        ElseIf c = Chr(13) Then
            r += "\r"
        Else
            r += c
        End If
    Next
    Return r
End Function

Function OpName(ByVal op As Long) As String
    Select Case op
    Case OP_RIGHT:Return "RIGHT":Case OP_LEFT:Return "LEFT":Case OP_INC:Return "INC":Case OP_DEC:Return "DEC":Case OP_CLEAR:Return "CLEAR":Case OP_PUTC:Return "PUTC":Case OP_GETC:Return "GETC":Case OP_LOOP_BEG:Return "LOOP_BEGIN":Case OP_LOOP_END:Return "LOOP_END":Case OP_PUSH:Return "PUSH":Case OP_POP:Return "POP":Case OP_EQ:Return "EQ":Case OP_GT:Return "GT":Case OP_LT:Return "LT":Case OP_AND:Return "AND":Case OP_OR:Return "OR":Case OP_XOR:Return "XOR":Case OP_NOT:Return "NOT":Case OP_SHL:Return "SHL":Case OP_SHR:Return "SHR":Case OP_STATUS:Return "STATUS":Case OP_META:Return "META":Case OP_BRANCH:Return "BRANCH":Case OP_PRINT_STRING:Return "PRINT_STRING":Case OP_SET:Return "SET"
    End Select
    Return "NOP"
End Function

Function AddrText(ByVal ak As Long, ByVal av As Long, ByVal av2 As Long) As String
    Select Case ak
    Case ADDR_T:Return "(T)":Case ADDR_T_REL:If av >= 0 Then Return "(T+" + LTrim(Str(av)) + ")" Else Return "(T" + LTrim(Str(av)) + ")"
    Case ADDR_T_ABS:Return "(T:" + LTrim(Str(av)) + ")":Case ADDR_D_ABS:Return "(D:" + LTrim(Str(av)) + ")":Case ADDR_D_AT_T_REL:If av2 >= 0 Then Return "(D@T+" + LTrim(Str(av2)) + ")" Else Return "(D@T" + LTrim(Str(av2)) + ")"
    Case ADDR_D_AT_TBASE_REL:If av2 >= 0 Then Return "(D@(T" + IIf(av >= 0, "+", "") + LTrim(Str(av)) + ")+" + LTrim(Str(av2)) + ")" Else Return "(D@(T" + IIf(av >= 0, "+", "") + LTrim(Str(av)) + ")" + LTrim(Str(av2)) + ")"
    End Select
    Return "(?)"
End Function

Function LineOfPos(ByVal atPos As Long) As Long
    Dim l As Long
    Dim i As Long

    l = 1
    For i = 1 To atPos - 1
        If Mid(src, i, 1) = Chr(10) Then l += 1
    Next
    Return l
End Function

Function ColOfPos(ByVal atPos As Long) As Long
    Dim c As Long
    Dim i As Long

    c = 1
    For i = atPos - 1 To 1 Step -1
        If Mid(src, i, 1) = Chr(10) Then
            Exit For
        Else
            c += 1
        End If
    Next
    Return c
End Function
