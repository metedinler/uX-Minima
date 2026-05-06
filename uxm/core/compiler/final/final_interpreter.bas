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
    Dim p4 As ULongInt
    Dim p3 As ULongInt
    Dim p2 As ULongInt
    Dim p1 As ULongInt
    Dim p0 As ULongInt
    Dim i As Long
    Dim j As Long
    Dim k As Long
    Dim ok As Long
    Dim idx As Long
    Dim n As Long
    Dim rows As Long
    Dim cols As Long
    Dim rowsB As Long
    Dim colsB As Long
    Dim r As LongInt
    Dim v As LongInt
    Dim av As LongInt
    Dim bv As LongInt
    Dim sum As LongInt
    Dim x As LongInt
    Dim h As LongInt
    Dim a0 As LongInt
    Dim b0 As LongInt
    Dim f1 As LongInt
    Dim f2 As LongInt
    Dim sign As LongInt
    Dim pow10 As LongInt
    Dim s As String

    p4=ReadAddr(ADDR_T_REL,-4,0)
    p3=ReadAddr(ADDR_T_REL,-3,0)
    p2=ReadAddr(ADDR_T_REL,-2,0)
    p1=ReadAddr(ADDR_T_REL,-1,0)
    p0=ReadAddr(ADDR_T,0,0)

    Select Case id
    Case 0
        SetStatus STATUS_OK
    Case 5
        outputText+=Chr(10)
        SetStatus STATUS_OK
    Case 20
        WriteAddr ADDR_T_REL,1,0,(p2+p1) And CellMask()
        SetLogicFlags (p2+p1)
        SetStatus STATUS_OK
    Case 21
        WriteAddr ADDR_T_REL,1,0,(p2-p1) And CellMask()
        SetLogicFlags (p2-p1)
        SetStatus STATUS_OK
    Case 22
        WriteAddr ADDR_T_REL,1,0,(p2*p1) And CellMask()
        SetLogicFlags (p2*p1)
        SetStatus STATUS_OK
    Case 23
        If p1=0 Then
            WriteAddr ADDR_T_REL,1,0,0
            SetStatus STATUS_DIV_ZERO
        Else
            WriteAddr ADDR_T_REL,1,0,(p2\p1) And CellMask()
            SetStatus STATUS_OK
        End If
    Case 24
        If p1=0 Then
            WriteAddr ADDR_T_REL,1,0,0
            SetStatus STATUS_DIV_ZERO
        Else
            WriteAddr ADDR_T_REL,1,0,(p2 Mod p1) And CellMask()
            SetStatus STATUS_OK
        End If
    Case 60
        outputText+=LTrim(Str(p1))
        SetStatus STATUS_OK
    Case 61
        outputText+=LTrim(Str(ReadAddr(ADDR_T_REL,1,0)))
        SetStatus STATUS_OK
    Case 64
        outputText+=" "
        SetStatus STATUS_OK
    Case 80
        If p1>=tapeCells Then
            SetStatus STATUS_PTR_BOUNDS
        Else
            tapePtr=p1
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
        FifoPush p1
    Case 91
        WriteAddr ADDR_T_REL,1,0,FifoPop()
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
    Case 92
        WriteAddr ADDR_T_REL,1,0,FifoPeek()
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
    Case 93
        WriteAddr ADDR_T_REL,1,0,fifoCount
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
        SetStatus STATUS_OK
    Case 94
        fifoHead=0
        fifoTail=0
        fifoCount=0
        SetStatus STATUS_OK
    Case 95
        If p1>=dataCells Then
            SetStatus STATUS_DATA_BOUNDS
        Else
            WriteAddr ADDR_T_REL,1,0,dataMem(p1)
            SetStatus STATUS_OK
        End If
    Case 96
        If p2>=dataCells Then
            SetStatus STATUS_DATA_BOUNDS
        Else
            dataMem(p2)=p1 And CellMask()
            SetStatus STATUS_OK
        End If
    Case 97
        If p1>=dataCells Then
            SetStatus STATUS_DATA_BOUNDS
            WriteAddr ADDR_T_REL,1,0,0
        Else
            If dataMem(p1)>=48 And dataMem(p1)<=57 Then
                WriteAddr ADDR_T_REL,1,0,dataMem(p1)-48
                SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
                SetStatus STATUS_OK
            Else
                WriteAddr ADDR_T_REL,1,0,0
                SetStatus STATUS_UNDERFLOW
            End If
        End If
    Case 98
        DataBlockCopy p2,p1,p0
    Case 99
        DataBlockClear p2,p1
    Case 100
        SortTape p2,p1,1
    Case 101
        SortTape p2,p1,0
    Case 102
        SortData p2,p1,1
    Case 103
        SortData p2,p1,0
    Case 104
        WriteAddr ADDR_T_REL,1,0,LinearSearchTape(p2,p1,p0)
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
        SetStatus STATUS_OK
    Case 105
        WriteAddr ADDR_T_REL,1,0,LinearSearchData(p2,p1,p0)
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
        SetStatus STATUS_OK
    Case 106
        TapeBlockCopy p2,p1,p0
    Case 107
        TapeBlockClear p2,p1
    Case 120
        flags And=Not FLAG_SGN
        SetStatus STATUS_OK
    Case 121
        flags Or=FLAG_SGN
        SetStatus STATUS_OK
    Case 122
        If (flags And FLAG_SGN)<>0 Then
            WriteAddr ADDR_T_REL,1,0,1
        Else
            WriteAddr ADDR_T_REL,1,0,0
        End If
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
        SetStatus STATUS_OK
    Case 123
        flags And=Not FLAG_END
        SetStatus STATUS_OK
    Case 124
        flags Or=FLAG_END
        SetStatus STATUS_OK
    Case 125
        If (flags And FLAG_END)<>0 Then
            WriteAddr ADDR_T_REL,1,0,1
        Else
            WriteAddr ADDR_T_REL,1,0,0
        End If
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
        SetStatus STATUS_OK
    Case 126
        WriteAddr ADDR_T_REL,1,0,flags
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
        SetStatus STATUS_OK

    Case 160
        MatrixInit p4,p3,p2,p1,p0
        WriteAddr ADDR_T_REL,1,0,statusByte
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
    Case 161
        If MatIsValidI(p4)=0 Then
            SetStatus STATUS_DATA_BOUNDS
        Else
            n=dataMem(p4+10)
            For i=0 To n-1
                dataMem(p4+16+i)=0
            Next
            SetStatus STATUS_OK
        End If
        WriteAddr ADDR_T_REL,1,0,statusByte
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
    Case 162
        idx=MatCellIndexI(p4,p3,p2,ok)
        If ok=0 Then
            SetStatus STATUS_DATA_BOUNDS
        Else
            dataMem(idx)=p1 And CellMask()
            SetStatus STATUS_OK
        End If
        WriteAddr ADDR_T_REL,1,0,statusByte
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
    Case 163
        idx=MatCellIndexI(p4,p3,p2,ok)
        If ok=0 Then
            SetStatus STATUS_DATA_BOUNDS
            WriteAddr ADDR_T_REL,1,0,0
        Else
            WriteAddr ADDR_T_REL,1,0,dataMem(idx)
            SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
            SetStatus STATUS_OK
        End If
    Case 164
        If MatIsValidI(p4)=0 Then
            SetStatus STATUS_DATA_BOUNDS
        Else
            n=dataMem(p4+10)
            For i=0 To n-1
                dataMem(p4+16+i)=p3 And CellMask()
            Next
            SetStatus STATUS_OK
        End If
        WriteAddr ADDR_T_REL,1,0,statusByte
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
    Case 165
        If MatIsValidI(p4)=0 Or MatIsValidI(p3)=0 Then
            SetStatus STATUS_DATA_BOUNDS
        Else
            rows=MatRowsI(p3)
            cols=MatColsI(p3)
            MatrixInit p4,rows,cols,dataMem(p3+3),dataMem(p3+7)
            If statusByte=STATUS_OK Then
                n=dataMem(p3+10)
                For i=0 To n-1
                    dataMem(p4+16+i)=dataMem(p3+16+i)
                Next
            End If
        End If
        WriteAddr ADDR_T_REL,1,0,statusByte
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
    Case 166
        If MatIsValidI(p3)=0 Then
            SetStatus STATUS_DATA_BOUNDS
        Else
            rows=MatRowsI(p3)
            cols=MatColsI(p3)
            For i=0 To rows-1
                s="["
                For j=0 To cols-1
                    idx=MatCellIndexI(p3,i,j,ok)
                    If j>0 Then s+=" "
                    s+=LTrim(Str(SignedCellI(dataMem(idx))))
                Next
                s+="]"
                outputText+=s+Chr(10)
            Next
            SetStatus STATUS_OK
        End If
        WriteAddr ADDR_T_REL,1,0,statusByte
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
    Case 167,168
        If MatIsValidI(p4)=0 Or MatIsValidI(p3)=0 Or MatIsValidI(p2)=0 Then
            SetStatus STATUS_DATA_BOUNDS
        Else
            n=dataMem(p3+10)
            If dataMem(p2+10)<>n Or dataMem(p4+10)<>n Then
                SetStatus STATUS_DATA_BOUNDS
            Else
                For i=0 To n-1
                    av=SignedCellI(dataMem(p3+16+i))
                    bv=SignedCellI(dataMem(p2+16+i))
                    If id=167 Then
                        dataMem(p4+16+i)=(av+bv) And CellMask()
                    Else
                        dataMem(p4+16+i)=(av-bv) And CellMask()
                    End If
                Next
                SetStatus STATUS_OK
            End If
        End If
        WriteAddr ADDR_T_REL,1,0,statusByte
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
    Case 169
        If MatIsValidI(p4)=0 Or MatIsValidI(p3)=0 Then
            SetStatus STATUS_DATA_BOUNDS
        Else
            n=dataMem(p3+10)
            If dataMem(p4+10)<>n Then
                SetStatus STATUS_DATA_BOUNDS
            Else
                For i=0 To n-1
                    av=SignedCellI(dataMem(p3+16+i))
                    If dataMem(p3+3)=2 Then
                        dataMem(p4+16+i)=MatFixedMulI(av,SignedCellI(p2),dataMem(p3+7)) And CellMask()
                    Else
                        dataMem(p4+16+i)=(av*SignedCellI(p2)) And CellMask()
                    End If
                Next
                SetStatus STATUS_OK
            End If
        End If
        WriteAddr ADDR_T_REL,1,0,statusByte
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
    Case 170
        If MatIsValidI(p4)=0 Or MatIsValidI(p3)=0 Or MatIsValidI(p2)=0 Then
            SetStatus STATUS_DATA_BOUNDS
        Else
            rows=MatRowsI(p3)
            cols=MatColsI(p3)
            rowsB=MatRowsI(p2)
            colsB=MatColsI(p2)
            If cols<>rowsB Or MatRowsI(p4)<>rows Or MatColsI(p4)<>colsB Then
                SetStatus STATUS_DATA_BOUNDS
            Else
                For i=0 To rows-1
                    For j=0 To colsB-1
                        sum=0
                        For k=0 To cols-1
                            sum+=SignedCellI(MatGetI(p3,i,k))*SignedCellI(MatGetI(p2,k,j))
                        Next
                        MatSetI p4,i,j,sum
                    Next
                Next
                SetStatus STATUS_OK
            End If
        End If
        WriteAddr ADDR_T_REL,1,0,statusByte
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
    Case 171
        If MatIsValidI(p4)=0 Or MatIsValidI(p3)=0 Then
            SetStatus STATUS_DATA_BOUNDS
        Else
            rows=MatRowsI(p3)
            cols=MatColsI(p3)
            If MatRowsI(p4)<>cols Or MatColsI(p4)<>rows Then
                SetStatus STATUS_DATA_BOUNDS
            Else
                For i=0 To rows-1
                    For j=0 To cols-1
                        MatSetI p4,j,i,MatGetI(p3,i,j)
                    Next
                Next
                SetStatus STATUS_OK
            End If
        End If
        WriteAddr ADDR_T_REL,1,0,statusByte
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
    Case 172
        MatrixInit p4,p3,p3,p2,p1
        If statusByte=STATUS_OK Then
            For i=0 To p3-1
                If p2=2 Then
                    MatSetI p4,i,i,Pow10I(p1)
                Else
                    MatSetI p4,i,i,1
                End If
            Next
            SetStatus STATUS_OK
        End If
        WriteAddr ADDR_T_REL,1,0,statusByte
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
    Case 173
        If MatIsValidI(p3)=0 Or MatRowsI(p3)<>MatColsI(p3) Then
            SetStatus STATUS_DATA_BOUNDS
            WriteAddr ADDR_T_REL,1,0,0
        Else
            sum=0
            For i=0 To MatRowsI(p3)-1
                sum+=SignedCellI(MatGetI(p3,i,i))
            Next
            WriteAddr ADDR_T_REL,1,0,sum And CellMask()
            SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
            SetStatus STATUS_OK
        End If
    Case 174
        If MatIsValidI(p3)=0 Then
            SetStatus STATUS_DATA_BOUNDS
        Else
            WriteAddr ADDR_T_REL,1,0,MatRowsI(p3)
            WriteAddr ADDR_T_REL,2,0,MatColsI(p3)
            SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
            SetStatus STATUS_OK
        End If
        WriteAddr ADDR_T_REL,1,0,statusByte
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
    Case 175
        If MatIsValidI(p3)=0 Or MatRowsI(p3)<>2 Or MatColsI(p3)<>2 Then
            SetStatus STATUS_DATA_BOUNDS
            WriteAddr ADDR_T_REL,1,0,0
        Else
            av=SignedCellI(MatGetI(p3,0,0))
            bv=SignedCellI(MatGetI(p3,0,1))
            x=SignedCellI(MatGetI(p3,1,0))
            h=SignedCellI(MatGetI(p3,1,1))
            If dataMem(p3+3)=2 Then
                sum=MatFixedMulI(av,h,dataMem(p3+7))-MatFixedMulI(bv,x,dataMem(p3+7))
            Else
                sum=av*h-bv*x
            End If
            WriteAddr ADDR_T_REL,1,0,sum And CellMask()
            SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
            SetStatus STATUS_OK
        End If
    Case 176
        If MatIsValidI(p3)=0 Then
            SetStatus STATUS_DATA_BOUNDS
        Else
            n=dataMem(p3+10)
            s=""
            For i=0 To n-1
                If i>0 Then s+=","
                s+=LTrim(Str(SignedCellI(dataMem(p3+16+i))))
            Next
            outputText+=s+Chr(10)
            SetStatus STATUS_OK
        End If
        WriteAddr ADDR_T_REL,1,0,statusByte
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)

    Case 200
        FPWriteScaled p2,0
        If p2+1<dataCells Then dataMem(p2+1)=16
        SetStatus STATUS_OK
        WriteAddr ADDR_T_REL,1,0,0
    Case 201
        FPWriteScaled p2,0
        If p2+1<dataCells Then dataMem(p2+1)=32
        SetStatus STATUS_OK
        WriteAddr ADDR_T_REL,1,0,0
    Case 202
        FPWriteScaled p2,0
        SetStatus STATUS_OK
        WriteAddr ADDR_T_REL,1,0,0
    Case 203
        FPWriteScaled p2,FPReadScaled(p1)
        SetStatus STATUS_OK
        WriteAddr ADDR_T_REL,1,0,0
    Case 204
        FPWriteScaled p2,FPReadScaled(p2)
        SetStatus STATUS_OK
        WriteAddr ADDR_T_REL,1,0,0
    Case 205
        WriteAddr ADDR_T_REL,1,0,(Cast(ULongInt, CLngInt(FPReadScaled(p1)\FPScaleConst())) And CellMask())
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
        SetStatus STATUS_OK
    Case 206
        If FPReadScaled(p1)=0 Then
            WriteAddr ADDR_T_REL,1,0,1
        Else
            WriteAddr ADDR_T_REL,1,0,0
        End If
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
        SetStatus STATUS_OK
    Case 207
        If FPReadScaled(p1)=0 Then
            WriteAddr ADDR_T_REL,1,0,0
        ElseIf FPReadScaled(p1)<0 Then
            WriteAddr ADDR_T_REL,1,0,CellMask()
        Else
            WriteAddr ADDR_T_REL,1,0,1
        End If
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
        SetStatus STATUS_OK
    Case 208
        WriteAddr ADDR_T_REL,1,0,(Cast(ULongInt, Abs(CLngInt(FPReadScaled(p1)\FPScaleConst()))) And CellMask())
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
        SetStatus STATUS_OK
    Case 209
        outputText+="FP RAW base="+LTrim(Str(p1))+" v="+LTrim(Str(FPReadScaled(p1)))
        SetStatus STATUS_OK
        WriteAddr ADDR_T_REL,1,0,0
    Case 210
        FPWriteScaled p2,FPReadScaled(p1)+FPReadScaled(p0)
        SetStatus STATUS_OK
        WriteAddr ADDR_T_REL,1,0,0
    Case 211
        FPWriteScaled p2,FPReadScaled(p1)-FPReadScaled(p0)
        SetStatus STATUS_OK
        WriteAddr ADDR_T_REL,1,0,0
    Case 212
        FPWriteScaled p2,(FPReadScaled(p1)*FPReadScaled(p0))\FPScaleConst()
        SetStatus STATUS_OK
        WriteAddr ADDR_T_REL,1,0,0
    Case 213
        If FPReadScaled(p0)=0 Then
            SetStatus STATUS_DIV_ZERO
            WriteAddr ADDR_T_REL,1,0,STATUS_DIV_ZERO
        Else
            FPWriteScaled p2,(FPReadScaled(p1)*FPScaleConst())\FPReadScaled(p0)
            SetStatus STATUS_OK
            WriteAddr ADDR_T_REL,1,0,0
        End If
    Case 214
        If FPReadScaled(p1)=FPReadScaled(p0) Then
            WriteAddr ADDR_T_REL,1,0,0
        ElseIf FPReadScaled(p1)>FPReadScaled(p0) Then
            WriteAddr ADDR_T_REL,1,0,1
        Else
            WriteAddr ADDR_T_REL,1,0,CellMask()
        End If
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
        SetStatus STATUS_OK
    Case 215
        FPWriteScaled p2,Abs(FPReadScaled(p1))
        SetStatus STATUS_OK
        WriteAddr ADDR_T_REL,1,0,0
    Case 216
        FPWriteScaled p2,-FPReadScaled(p1)
        SetStatus STATUS_OK
        WriteAddr ADDR_T_REL,1,0,0
    Case 217
        FPWriteScaled p2,FPReadScaled(p2)
        SetStatus STATUS_OK
        WriteAddr ADDR_T_REL,1,0,0
    Case 218
        FPWriteScaled p2,FPReadScaled(p2)
        SetStatus STATUS_OK
        WriteAddr ADDR_T_REL,1,0,0
    Case 219
        FPWriteScaled p2,(FPReadScaled(p2)\FPScaleConst())*FPScaleConst()
        SetStatus STATUS_OK
        WriteAddr ADDR_T_REL,1,0,0
    Case 220
        FPWriteScaled p2,SignedCellI(p1)*FPScaleConst()
        SetStatus STATUS_OK
        WriteAddr ADDR_T_REL,1,0,0
    Case 221
        FPWriteScaled p2,CLngInt(Val(ReadDataString(p1))*FPScaleConst())
        SetStatus STATUS_OK
        WriteAddr ADDR_T_REL,1,0,0
    Case 222
        WriteDataString p1,LTrim(Str(FPReadScaled(p2)/FPScaleConst()))
        SetStatus STATUS_OK
        WriteAddr ADDR_T_REL,1,0,0
    Case 223
        outputText+=LTrim(Str(FPReadScaled(p1)/FPScaleConst()))
        SetStatus STATUS_OK
        WriteAddr ADDR_T_REL,1,0,0
    Case 224
        sign=SignedCellI(p1)
        pow10=1
        If sign>=0 Then
            For i=1 To sign
                pow10*=10
            Next
            FPWriteScaled p2,FPReadScaled(p2)*pow10
        Else
            For i=1 To -sign
                pow10*=10
            Next
            If pow10<>0 Then FPWriteScaled p2,FPReadScaled(p2)\pow10
        End If
        SetStatus STATUS_OK
        WriteAddr ADDR_T_REL,1,0,0

    Case 230,231,232,233,234
        SetStatus STATUS_INVALID_META
        WriteAddr ADDR_T_REL,1,0,STATUS_INVALID_META

    Case 240
        If p1<0 Or p1+4>=dataCells Or dataMem(p1)<>80 Then
            SetStatus STATUS_DATA_BOUNDS
        Else
            n=dataMem(p1+2)
            dataMem(p2+0)=80
            dataMem(p2+1)=1
            dataMem(p2+3)=dataMem(p1+3)
            If n<=0 Then
                dataMem(p2+2)=0
                dataMem(p2+4)=0
            Else
                dataMem(p2+2)=n-1
                For i=1 To n
                    dataMem(p2+3+i)=(SignedCellI(dataMem(p1+4+i))*i) And CellMask()
                Next
            End If
            SetStatus STATUS_OK
        End If
        WriteAddr ADDR_T_REL,1,0,statusByte
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
    Case 241
        If p1<0 Or p1+4>=dataCells Or dataMem(p1)<>80 Then
            SetStatus STATUS_DATA_BOUNDS
        Else
            n=dataMem(p1+2)
            dataMem(p2+0)=80
            dataMem(p2+1)=1
            dataMem(p2+2)=n+1
            dataMem(p2+3)=dataMem(p1+3)
            dataMem(p2+4)=p0 And CellMask()
            For i=0 To n
                dataMem(p2+5+i)=(SignedCellI(dataMem(p1+4+i))\(i+1)) And CellMask()
            Next
            SetStatus STATUS_OK
        End If
        WriteAddr ADDR_T_REL,1,0,statusByte
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
    Case 242
        If p2<0 Or p2+4>=dataCells Or dataMem(p2)<>80 Then
            SetStatus STATUS_DATA_BOUNDS
            WriteAddr ADDR_T_REL,1,0,0
        Else
            n=dataMem(p2+2)
            sum=0
            For i=n To 0 Step -1
                sum=sum*SignedCellI(p1)+SignedCellI(dataMem(p2+4+i))
            Next
            WriteAddr ADDR_T_REL,1,0,sum And CellMask()
            SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
            SetStatus STATUS_OK
        End If
    Case 243
        If p1<0 Or p1+4>=dataCells Or dataMem(p1)<>80 Then
            SetStatus STATUS_DATA_BOUNDS
        Else
            n=dataMem(p1+2)
            s=""
            For i=0 To n
                If i=0 Then
                    s+=LTrim(Str(SignedCellI(dataMem(p1+4+i))))
                Else
                    s+=" + "+LTrim(Str(SignedCellI(dataMem(p1+4+i))))+"x"
                    If i>1 Then s+="^"+LTrim(Str(i))
                End If
            Next
            outputText+=s
            SetStatus STATUS_OK
        End If
        WriteAddr ADDR_T_REL,1,0,statusByte
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
    Case 244
        For i=0 To p1-1
            If p2+i>=0 And p2+i<dataCells Then dataMem(p2+i)=0
        Next
        SetStatus STATUS_OK
        WriteAddr ADDR_T_REL,1,0,statusByte
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
    Case 250
        WriteAddr ADDR_T_REL,1,0,ExprEvalRpn(p2,SignedCellI(p1)) And CellMask()
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
        SetStatus STATUS_OK
    Case 251
        h=SignedCellI(p0)
        If h=0 Then h=1
        f1=ExprEvalRpn(p2,SignedCellI(p1)+h)
        f2=ExprEvalRpn(p2,SignedCellI(p1)-h)
        WriteAddr ADDR_T_REL,1,0,((f1-f2)\(2*h)) And CellMask()
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
        SetStatus STATUS_OK
    Case 252
        a0=SignedCellI(p3)
        b0=SignedCellI(p2)
        n=SignedCellI(p1)
        If n<=0 Then
            SetStatus STATUS_DIV_ZERO
            WriteAddr ADDR_T_REL,1,0,0
        Else
            h=(b0-a0)\n
            If h=0 Then h=1
            sum=(ExprEvalRpn(p4,a0)+ExprEvalRpn(p4,b0))\2
            For i=1 To n-1
                x=a0+i*h
                sum+=ExprEvalRpn(p4,x)
            Next
            WriteAddr ADDR_T_REL,1,0,(sum*h) And CellMask()
            SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
            SetStatus STATUS_OK
        End If
    Case 253
        a0=SignedCellI(p3)
        b0=SignedCellI(p2)
        n=SignedCellI(p1)
        If n<=0 Or (n Mod 2)<>0 Then
            SetStatus STATUS_INVALID_META
            WriteAddr ADDR_T_REL,1,0,0
        Else
            h=(b0-a0)\n
            If h=0 Then h=1
            sum=ExprEvalRpn(p4,a0)+ExprEvalRpn(p4,b0)
            For i=1 To n-1
                x=a0+i*h
                If (i Mod 2)=0 Then
                    sum+=2*ExprEvalRpn(p4,x)
                Else
                    sum+=4*ExprEvalRpn(p4,x)
                End If
            Next
            WriteAddr ADDR_T_REL,1,0,((sum*h)\3) And CellMask()
            SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
            SetStatus STATUS_OK
        End If
    Case 254
        ExprPrintRpnI p1
        SetStatus STATUS_OK
        WriteAddr ADDR_T_REL,1,0,statusByte
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0)
    Case Else
        SetStatus STATUS_INVALID_META
    End Select
End Sub

Function SignedCellI(ByVal v As ULongInt) As LongInt
    v=v And CellMask()
    If cellBits=8 And (v And &H80)<>0 Then Return v-256
    If cellBits=16 And (v And &H8000)<>0 Then Return v-65536
    If cellBits=32 And (v And &H80000000)<>0 Then Return CLngInt(v)-4294967296
    Return CLngInt(v)
End Function

Function Pow10I(ByVal n As Long) As LongInt
    Dim i As Long
    Dim p As LongInt
    p=1
    If n<=0 Then Return 1
    For i=1 To n
        p*=10
    Next
    Return p
End Function

Function MatIsValidI(ByVal baseAddr As Long) As Long
    If baseAddr<0 Or baseAddr+15>=dataCells Then Return 0
    If dataMem(baseAddr+0)<>77 Then Return 0
    If dataMem(baseAddr+1)<>1 Then Return 0
    If dataMem(baseAddr+2)<>2 Then Return 0
    Return -1
End Function

Function MatRowsI(ByVal baseAddr As Long) As Long
    Return dataMem(baseAddr+5)
End Function

Function MatColsI(ByVal baseAddr As Long) As Long
    Return dataMem(baseAddr+6)
End Function

Function MatCellIndexI(ByVal baseAddr As Long, ByVal r As Long, ByVal c As Long, ByRef ok As Long) As Long
    Dim rows As Long
    Dim cols As Long
    Dim idx As Long
    ok=0
    If MatIsValidI(baseAddr)=0 Then Return 0
    rows=MatRowsI(baseAddr)
    cols=MatColsI(baseAddr)
    If r<0 Or c<0 Or r>=rows Or c>=cols Then Return 0
    idx=baseAddr+dataMem(baseAddr+9)+r*dataMem(baseAddr+12)+c*dataMem(baseAddr+13)
    If idx<0 Or idx>=dataCells Then Return 0
    ok=-1
    Return idx
End Function

Function MatGetI(ByVal baseAddr As Long, ByVal r As Long, ByVal c As Long) As ULongInt
    Dim idx As Long
    Dim ok As Long
    idx=MatCellIndexI(baseAddr,r,c,ok)
    If ok=0 Then Return 0
    Return dataMem(idx)
End Function

Sub MatSetI(ByVal baseAddr As Long, ByVal r As Long, ByVal c As Long, ByVal value As LongInt)
    Dim idx As Long
    Dim ok As Long
    idx=MatCellIndexI(baseAddr,r,c,ok)
    If ok=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    dataMem(idx)=value And CellMask()
End Sub

Function MatFixedMulI(ByVal a As LongInt, ByVal b As LongInt, ByVal scale As Long) As LongInt
    Dim d As LongInt
    d=Pow10I(scale)
    If d=0 Then d=1
    Return (a*b)\d
End Function

Sub ExprPrintRpnI(ByVal exprBase As Long)
    Dim tokenCount As Long
    Dim ip As Long
    Dim tok As LongInt
    If exprBase<0 Or exprBase+4>=dataCells Or dataMem(exprBase)<>69 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    tokenCount=dataMem(exprBase+2)
    ip=exprBase+4
    Do
        tok=SignedCellI(dataMem(ip))
        ip+=1
        Select Case tok
        Case 1
            outputText+="CONST("+LTrim(Str(SignedCellI(dataMem(ip))))+") "
            ip+=1
        Case 2
            outputText+="X "
        Case 10
            outputText+="ADD "
        Case 11
            outputText+="SUB "
        Case 12
            outputText+="MUL "
        Case 13
            outputText+="DIV "
        Case 14
            outputText+="POW "
        Case 20
            outputText+="SIN "
        Case 21
            outputText+="COS "
        Case 22
            outputText+="TAN "
        Case 23
            outputText+="EXP "
        Case 24
            outputText+="LOG "
        Case 25
            outputText+="SQRT "
        Case 30
            outputText+="NEG "
        Case 31
            outputText+="ABS "
        Case 99
            outputText+="END"
            Exit Do
        Case Else
            outputText+="? "
        End Select
        If ip>=exprBase+4+tokenCount+16 Then Exit Do
    Loop
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
