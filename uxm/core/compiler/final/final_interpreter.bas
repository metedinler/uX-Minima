' Auto-split by V3 modularization
Sub RunProgram()
    Dim i As Long
    Dim j As Long
    Dim ip As Long

    tapePtr=0
    stackPtr=0
    statusByte=0
    outputText=""
    stepCounter=0
    If pragmaSeedEnabled<>0 Then Randomize CInt(pragmaSeedValue)

    For i=1 To strCount
        For j=1 To Len(strDef(i).txt)
            If strDef(i).startCell+j-1<dataCells Then
                dataMem(strDef(i).startCell+j-1)=Asc(Mid(strDef(i).txt,j,1)) And CellMask()
            End If
        Next
        If strDef(i).startCell+Len(strDef(i).txt)<dataCells Then
            dataMem(strDef(i).startCell+Len(strDef(i).txt))=0
        End If
    Next

    For i=1 To DataInitCount
        If DataInit(i).idx>=0 And DataInit(i).idx<dataCells Then
            dataMem(DataInit(i).idx)=DataInit(i).value And CellMask()
        End If
    Next

    TraceStart()
    ip=1
    Do While ip>=1 And ip<=instrCount
        ExecInstr ip,0
        If stepCounter>=maxSteps Then
            AddDiag "error","max step limit aşıldı",1
            SetStatus STATUS_OVERFLOW
            Exit Do
        End If
        If hadError<>0 Then Exit Do
    Loop
    TraceStop()
End Sub

Sub ExecInstr(ByRef ip As Long, ByVal depth As Long)
    Dim oldIp As Long
    Dim v As ULongInt
    Dim a As ULongInt
    Dim b As ULongInt
    Dim taken As Long
    Dim id As Long

    oldIp=ip
    stepCounter+=1

    Select Case progInstr(ip).op
    Case OP_RIGHT
        tapePtr+=progInstr(ip).amount
        If boundsOn<>0 And (tapePtr<0 Or tapePtr>=tapeCells) Then
            SetStatus STATUS_PTR_BOUNDS
            ip=instrCount+1
        Else
            TraceEvent oldIp,"RIGHT",""
            ip+=1
        End If

    Case OP_LEFT
        tapePtr-=progInstr(ip).amount
        If boundsOn<>0 And (tapePtr<0 Or tapePtr>=tapeCells) Then
            SetStatus STATUS_PTR_BOUNDS
            ip=instrCount+1
        Else
            TraceEvent oldIp,"LEFT",""
            ip+=1
        End If

    Case OP_INC
        v=(ReadAddr(progInstr(ip).addrKind,progInstr(ip).addrVal,progInstr(ip).addrVal2)+progInstr(ip).amount) And CellMask()
        WriteAddr progInstr(ip).addrKind,progInstr(ip).addrVal,progInstr(ip).addrVal2,v
        SetLogicFlags v
        TraceEvent oldIp,"INC",""
        ip+=1

    Case OP_DEC
        v=(ReadAddr(progInstr(ip).addrKind,progInstr(ip).addrVal,progInstr(ip).addrVal2)-progInstr(ip).amount) And CellMask()
        WriteAddr progInstr(ip).addrKind,progInstr(ip).addrVal,progInstr(ip).addrVal2,v
        SetLogicFlags v
        TraceEvent oldIp,"DEC",""
        ip+=1

    Case OP_SET
        v=progInstr(ip).amount And CellMask()
        WriteAddr progInstr(ip).addrKind,progInstr(ip).addrVal,progInstr(ip).addrVal2,v
        SetLogicFlags v
        TraceEvent oldIp,"SET",""
        ip+=1

    Case OP_CLEAR
        WriteAddr progInstr(ip).addrKind,progInstr(ip).addrVal,progInstr(ip).addrVal2,0
        SetLogicFlags 0
        TraceEvent oldIp,"CLEAR",""
        ip+=1

    Case OP_PUTC
        v=ReadAddr(progInstr(ip).addrKind,progInstr(ip).addrVal,progInstr(ip).addrVal2)
        outputText+=Chr(v And &HFF)
        TraceEvent oldIp,"PUTC","""char"":"+Str(v And &HFF)
        ip+=1

    Case OP_GETC
        WriteAddr progInstr(ip).addrKind,progInstr(ip).addrVal,progInstr(ip).addrVal2,0
        SetStatus STATUS_EOF
        TraceEvent oldIp,"GETC",""
        ip+=1

    Case OP_PUSH
        If stackPtr>=stackCells Then
            SetStatus STATUS_STACK_OVERFLOW
            ip=instrCount+1
        Else
            stackMem(stackPtr)=ReadAddr(progInstr(ip).addrKind,progInstr(ip).addrVal,progInstr(ip).addrVal2)
            stackPtr+=1
            TraceEvent oldIp,"PUSH",""
            ip+=1
        End If

    Case OP_POP
        If stackPtr<=0 Then
            SetStatus STATUS_STACK_UNDERFLOW
            ip=instrCount+1
        Else
            stackPtr-=1
            WriteAddr progInstr(ip).addrKind,progInstr(ip).addrVal,progInstr(ip).addrVal2,stackMem(stackPtr)
            SetLogicFlags stackMem(stackPtr)
            TraceEvent oldIp,"POP",""
            ip+=1
        End If

    Case OP_EQ,OP_GT,OP_LT,OP_AND,OP_OR,OP_XOR
        If stackPtr<=0 Then
            SetStatus STATUS_STACK_UNDERFLOW
            ip=instrCount+1
        Else
            stackPtr-=1
            a=stackMem(stackPtr)
            b=ReadAddr(progInstr(ip).addrKind,progInstr(ip).addrVal,progInstr(ip).addrVal2)
            Select Case progInstr(ip).op
            Case OP_EQ
                v=IIf(a=b,1,0)
            Case OP_GT
                v=IIf(a>b,1,0)
            Case OP_LT
                v=IIf(a<b,1,0)
            Case OP_AND
                v=a And b
            Case OP_OR
                v=a Or b
            Case Else
                v=a Xor b
            End Select
            WriteAddr progInstr(ip).addrKind,progInstr(ip).addrVal,progInstr(ip).addrVal2,v And CellMask()
            SetLogicFlags v
            TraceEvent oldIp,OpName(progInstr(ip).op),""
            ip+=1
        End If

    Case OP_NOT
        v=(Not ReadAddr(progInstr(ip).addrKind,progInstr(ip).addrVal,progInstr(ip).addrVal2)) And CellMask()
        WriteAddr progInstr(ip).addrKind,progInstr(ip).addrVal,progInstr(ip).addrVal2,v
        SetLogicFlags v
        TraceEvent oldIp,"NOT",""
        ip+=1

    Case OP_SHL
        v=(ReadAddr(progInstr(ip).addrKind,progInstr(ip).addrVal,progInstr(ip).addrVal2) Shl 1) And CellMask()
        WriteAddr progInstr(ip).addrKind,progInstr(ip).addrVal,progInstr(ip).addrVal2,v
        SetLogicFlags v
        TraceEvent oldIp,"SHL",""
        ip+=1

    Case OP_SHR
        v=(ReadAddr(progInstr(ip).addrKind,progInstr(ip).addrVal,progInstr(ip).addrVal2) Shr 1) And CellMask()
        WriteAddr progInstr(ip).addrKind,progInstr(ip).addrVal,progInstr(ip).addrVal2,v
        SetLogicFlags v
        TraceEvent oldIp,"SHR",""
        ip+=1

    Case OP_STATUS
        WriteAddr progInstr(ip).addrKind,progInstr(ip).addrVal,progInstr(ip).addrVal2,statusByte
        SetLogicFlags statusByte
        TraceEvent oldIp,"STATUS",""
        ip+=1

    Case OP_LOOP_BEG
        If tape(tapePtr)=0 Then
            ip=progInstr(ip).mate+1
        Else
            ip+=1
        End If
        TraceEvent oldIp,"LOOP_BEGIN",""

    Case OP_LOOP_END
        If tape(tapePtr)<>0 Then
            ip=progInstr(ip).mate+1
        Else
            ip+=1
        End If
        TraceEvent oldIp,"LOOP_END",""

    Case OP_META
        If progInstr(ip).metaDyn<>0 Then
            id=tape(tapePtr)
        Else
            id=progInstr(ip).metaId
        End If
        If id>=128 And id<=255 And progInstr(ip).metaForceHost=0 Then
            CallRuntimeMacro id,depth+1
        Else
            RuntimeMeta id
        End If
        TraceEvent oldIp,"META","""meta_id"":"+Str(id)+",""force_host"":"+Str(progInstr(ip).metaForceHost)
        ip+=1

    Case OP_BRANCH
        taken=0
        Select Case progInstr(ip).brCond
        Case BR_CUR_NZ
            If tape(tapePtr)<>0 Then taken=1
        Case BR_CUR_Z
            If tape(tapePtr)=0 Then taken=1
        Case BR_ALWAYS
            taken=1
        Case BR_Z_SET
            If (flags And FLAG_Z)<>0 Then taken=1
        Case BR_Z_CLR
            If (flags And FLAG_Z)=0 Then taken=1
        Case BR_C_SET
            If (flags And FLAG_C)<>0 Then taken=1
        Case BR_C_CLR
            If (flags And FLAG_C)=0 Then taken=1
        Case BR_O_SET
            If (flags And FLAG_O)<>0 Then taken=1
        Case BR_O_CLR
            If (flags And FLAG_O)=0 Then taken=1
        Case BR_S_SET
            If (flags And FLAG_S)<>0 Then taken=1
        Case BR_S_CLR
            If (flags And FLAG_S)=0 Then taken=1
        End Select

        If taken<>0 Then
            ip=progInstr(oldIp).brTarget
        Else
            ip+=1
        End If
        TraceEvent oldIp,"BRANCH","""taken"":"+Str(taken)+",""target"":"+Str(progInstr(oldIp).brTarget)

    Case OP_PRINT_STRING
        id=FindString(progInstr(ip).amount)
        If id>0 Then outputText+=strDef(id).txt
        TraceEvent oldIp,"PRINT_STRING",""
        ip+=1

    Case Else
        ip+=1
    End Select
End Sub

Sub CallRuntimeMacro(ByVal id As Long, ByVal depth As Long)
    Dim idx As Long
    Dim savedSrc As String
    Dim savedCount As Long
    Dim saved(1 To 2048) As TInstr
    Dim i As Long
    Dim ip As Long

    idx=FindMacro(id)
    If idx=0 Then
        SetStatus STATUS_INVALID_META
        Exit Sub
    End If
    If depth>64 Then
        SetStatus STATUS_STACK_OVERFLOW
        Exit Sub
    End If

    savedSrc=src
    savedCount=instrCount
    If savedCount>2048 Then
        SetStatus STATUS_OVERFLOW
        Exit Sub
    End If

    For i=1 To savedCount
        saved(i)=progInstr(i)
    Next

    instrCount=0
    src=macroDef(idx).txt
    ParseProgram src,depth
    ValidateProgram()

    ip=1
    Do While ip>=1 And ip<=instrCount
        ExecInstr ip,depth
        If statusByte<>0 Then Exit Do
    Loop

    src=savedSrc
    instrCount=savedCount
    For i=1 To savedCount
        progInstr(i)=saved(i)
    Next
End Sub

Sub RuntimeMeta(ByVal id As Long)
    Dim a As ULongInt
    Dim b As ULongInt
    Dim c As ULongInt
    Dim i As Long

    a=ReadAddr(ADDR_T_REL,-2,0)
    b=ReadAddr(ADDR_T_REL,-1,0)
    c=ReadAddr(ADDR_T,0,0)

    Select Case id
    Case 0
        SetStatus STATUS_OK
    Case 5
        outputText+=Chr(10)
        SetStatus STATUS_OK
    Case 20
        WriteAddr ADDR_T_REL,1,0,(a+b) And CellMask()
        SetLogicFlags (a+b)
        SetStatus STATUS_OK
    Case 21
        WriteAddr ADDR_T_REL,1,0,(a-b) And CellMask()
        SetLogicFlags (a-b)
        SetStatus STATUS_OK
    Case 22
        WriteAddr ADDR_T_REL,1,0,(a*b) And CellMask()
        SetLogicFlags (a*b)
        SetStatus STATUS_OK
    Case 23
        If b=0 Then
            WriteAddr ADDR_T_REL,1,0,0
            SetStatus STATUS_DIV_ZERO
        Else
            WriteAddr ADDR_T_REL,1,0,(a\b) And CellMask()
            SetStatus STATUS_OK
        End If
    Case 24
        If b=0 Then
            WriteAddr ADDR_T_REL,1,0,0
            SetStatus STATUS_DIV_ZERO
        Else
            WriteAddr ADDR_T_REL,1,0,(a Mod b) And CellMask()
            SetStatus STATUS_OK
        End If
    Case 60
        outputText+=LTrim(Str(b))
        SetStatus STATUS_OK
    Case 61
        outputText+=LTrim(Str(ReadAddr(ADDR_T_REL,1,0)))
        SetStatus STATUS_OK
    Case 64
        outputText+=" "
        SetStatus STATUS_OK
    Case 80
        If b>=tapeCells Then
            SetStatus STATUS_PTR_BOUNDS
        Else
            tapePtr=b
            flags Or=FLAG_PCHG
            SetStatus STATUS_OK
        End If
    Case 84
        WriteAddr ADDR_T_REL,1,0,tapeCells
        SetStatus STATUS_OK
    Case 85
        WriteAddr ADDR_T_REL,1,0,dataCells
        SetStatus STATUS_OK
    Case 86
        WriteAddr ADDR_T_REL,1,0,stackCells
        SetStatus STATUS_OK
    Case 90
        FifoPush b
    Case 91
        WriteAddr ADDR_T_REL,1,0,FifoPop()
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
    Case 93
        WriteAddr ADDR_T_REL,1,0,fifoCount
        SetStatus STATUS_OK
    Case 95
        If b>=dataCells Then
            SetStatus STATUS_DATA_BOUNDS
        Else
            WriteAddr ADDR_T_REL,1,0,dataMem(b)
            SetStatus STATUS_OK
        End If
    Case 96
        If a>=dataCells Then
            SetStatus STATUS_DATA_BOUNDS
        Else
            dataMem(a)=b And CellMask()
            SetStatus STATUS_OK
        End If
    Case 98
        For i=0 To c-1
            If a+i<dataCells And b+i<dataCells Then
                dataMem(b+i)=dataMem(a+i)
            End If
        Next
        SetStatus STATUS_OK
    Case 99
        For i=0 To b-1
            If a+i<dataCells Then dataMem(a+i)=0
        Next
        SetStatus STATUS_OK
    Case 120
        flags And=Not FLAG_SGN
        SetStatus STATUS_OK
    Case 121
        flags Or=FLAG_SGN
        SetStatus STATUS_OK
    Case 126
        WriteAddr ADDR_T_REL,1,0,flags
        SetStatus STATUS_OK
    Case Else
        SetStatus STATUS_INVALID_META
    End Select
End Sub

Sub FifoPush(ByVal v As ULongInt)
    If fifoCount>=65536 Then
        SetStatus STATUS_STACK_OVERFLOW
        Exit Sub
    End If
    fifoMem(fifoTail)=v And CellMask()
    fifoTail=(fifoTail+1) Mod 65536
    fifoCount+=1
    flags Or=FLAG_FIFO
    SetStatus STATUS_OK
End Sub

Function FifoPop() As ULongInt
    Dim v As ULongInt
    If fifoCount=0 Then
        SetStatus STATUS_STACK_UNDERFLOW
        Return 0
    End If
    v=fifoMem(fifoHead)
    fifoHead=(fifoHead+1) Mod 65536
    fifoCount-=1
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

Sub DataBlockCopy(ByVal src As Long, ByVal dst As Long, ByVal cnt As Long)
    Dim i As Long
    If src<0 Or dst<0 Or src+cnt>dataCells Or dst+cnt>dataCells Then SetStatus STATUS_DATA_BOUNDS:Exit Sub
    For i=0 To cnt-1
        dataMem(dst+i)=dataMem(src+i)
    Next
    SetStatus STATUS_OK
End Sub

Sub DataBlockClear(ByVal dst As Long, ByVal cnt As Long)
    Dim i As Long
    If dst<0 Or dst+cnt>dataCells Then SetStatus STATUS_DATA_BOUNDS:Exit Sub
    For i=0 To cnt-1
        dataMem(dst+i)=0
    Next
    SetStatus STATUS_OK
End Sub

Sub TapeBlockCopy(ByVal src As Long, ByVal dst As Long, ByVal cnt As Long)
    Dim i As Long
    If src<0 Or dst<0 Or src+cnt>tapeCells Or dst+cnt>tapeCells Then SetStatus STATUS_PTR_BOUNDS:Exit Sub
    For i=0 To cnt-1
        tape(dst+i)=tape(src+i)
    Next
    SetStatus STATUS_OK
End Sub

Sub TapeBlockClear(ByVal dst As Long, ByVal cnt As Long)
    Dim i As Long
    If dst<0 Or dst+cnt>tapeCells Then SetStatus STATUS_PTR_BOUNDS:Exit Sub
    For i=0 To cnt-1
        tape(dst+i)=0
    Next
    SetStatus STATUS_OK
End Sub

Sub SortTape(ByVal startIdx As Long, ByVal cnt As Long, ByVal ascending As Long)
    Dim i As Long,j As Long,tmp As ULongInt
    If startIdx<0 Or startIdx+cnt>tapeCells Then SetStatus STATUS_PTR_BOUNDS:Exit Sub
    For i=0 To cnt-2
        For j=0 To cnt-2-i
            If (ascending<>0 And tape(startIdx+j)>tape(startIdx+j+1)) Or (ascending=0 And tape(startIdx+j)<tape(startIdx+j+1)) Then
                tmp=tape(startIdx+j)
                tape(startIdx+j)=tape(startIdx+j+1)
                tape(startIdx+j+1)=tmp
            End If
        Next
    Next
    SetStatus STATUS_OK
End Sub

Sub SortData(ByVal startIdx As Long, ByVal cnt As Long, ByVal ascending As Long)
    Dim i As Long,j As Long,tmp As ULongInt
    If startIdx<0 Or startIdx+cnt>dataCells Then SetStatus STATUS_DATA_BOUNDS:Exit Sub
    For i=0 To cnt-2
        For j=0 To cnt-2-i
            If (ascending<>0 And dataMem(startIdx+j)>dataMem(startIdx+j+1)) Or (ascending=0 And dataMem(startIdx+j)<dataMem(startIdx+j+1)) Then
                tmp=dataMem(startIdx+j)
                dataMem(startIdx+j)=dataMem(startIdx+j+1)
                dataMem(startIdx+j+1)=tmp
            End If
        Next
    Next
    SetStatus STATUS_OK
End Sub

Function LinearSearchTape(ByVal startIdx As Long, ByVal cnt As Long, ByVal target As ULongInt) As Long
    Dim i As Long
    If startIdx<0 Or startIdx+cnt>tapeCells Then SetStatus STATUS_PTR_BOUNDS:Return CellMask()
    For i=0 To cnt-1
        If tape(startIdx+i)=target Then Return i
    Next
    Return CellMask()
End Function

Function LinearSearchData(ByVal startIdx As Long, ByVal cnt As Long, ByVal target As ULongInt) As Long
    Dim i As Long
    If startIdx<0 Or startIdx+cnt>dataCells Then SetStatus STATUS_DATA_BOUNDS:Return CellMask()
    For i=0 To cnt-1
        If dataMem(startIdx+i)=target Then Return i
    Next
    Return CellMask()
End Function

Function ResolveIndex(ByVal ak As Long, ByVal av As Long, ByVal av2 As Long, ByRef spaceName As String, ByRef ok As Long) As Long
    Dim idx As Long
    ok=1
    Select Case ak
    Case ADDR_T:spaceName="T":idx=tapePtr
    Case ADDR_T_REL:spaceName="T":idx=tapePtr+av
    Case ADDR_T_ABS:spaceName="T":idx=av
    Case ADDR_D_ABS:spaceName="D":idx=av
    Case ADDR_S_ABS:spaceName="S":idx=av
    Case ADDR_SP:spaceName="S":idx=stackPtr-1
    Case ADDR_P:spaceName="P":idx=0
    Case ADDR_E:spaceName="E":idx=0
    Case ADDR_F:spaceName="F":idx=0
    Case ADDR_IND_T:spaceName="T":idx=tape(tapePtr)
    Case ADDR_IND_T_REL:spaceName="T":idx=tape(tapePtr+av)
    Case ADDR_D_AT_T_REL:spaceName="D":idx=tape(tapePtr)+av2
    Case ADDR_D_AT_TBASE_REL:spaceName="D":idx=tape(tapePtr+av)+av2
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
    If spn="P" Then Return tapePtr And CellMask()
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
    If spn="P" Then tapePtr=v:flags Or=FLAG_PCHG
    If spn="E" Then SetStatus v
    If spn="F" Then flags=v
    flags Or=FLAG_DIRTY
End Sub

Sub SetStatus(ByVal code As ULongInt)
    statusByte=code And &HFF
    If statusByte=0 Then
        flags And=Not FLAG_ERR
    Else
        flags Or=FLAG_ERR
    End If
End Sub

Sub ClearArithFlags()
    flags And=Not (FLAG_Z Or FLAG_C Or FLAG_O Or FLAG_S)
End Sub

Sub SetZeroSign(ByVal v As ULongInt)
    flags And=Not (FLAG_Z Or FLAG_S)
    v And=CellMask()
    If v=0 Then flags Or=FLAG_Z
    If cellBits=8 And (v And &H80)<>0 Then flags Or=FLAG_S
    If cellBits=16 And (v And &H8000)<>0 Then flags Or=FLAG_S
    If cellBits=32 And (v And &H80000000)<>0 Then flags Or=FLAG_S
End Sub

Sub SetLogicFlags(ByVal v As ULongInt)
    ClearArithFlags()
    SetZeroSign v
End Sub
