' Auto-split by V3 modularization
Sub RunProgram()
    Dim i As Long,j As Long
    ptr=0:sp=0:statusByte=0:outputText="":stepCounter=0
    If pragmaSeedEnabled<>0 Then Randomize CInt(pragmaSeedValue)
    For i=1 To strCount
        For j=1 To Len(strDef(i).txt):If strDef(i).startCell+j-1<dataCells Then dataMem(strDef(i).startCell+j-1)=Asc(Mid(strDef(i).txt,j,1)) And CellMask()
        Next:If strDef(i).startCell+Len(strDef(i).txt)<dataCells Then dataMem(strDef(i).startCell+Len(strDef(i).txt))=0
    Next
    For i=1 To DataInitCount
        If DataInit(i).idx>=0 And DataInit(i).idx<dataCells Then dataMem(DataInit(i).idx)=DataInit(i).value And CellMask()
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
    Dim a As ULongInt,b As ULongInt,c As ULongInt,r As ULongInt,msb As ULongInt
    a=ReadAddr(ADDR_T_REL,-2,0):b=ReadAddr(ADDR_T_REL,-1,0):c=ReadAddr(ADDR_T,0,0)
    Select Case id
    Case 0:SetStatus STATUS_OK
    Case 1:SetStatus STATUS_OK
    Case 2:SetStatus STATUS_OK
    Case 3:WriteAddr ADDR_T_REL,1,0,Int(Rnd*256) And CellMask():SetLogicFlags ReadAddr(ADDR_T_REL,1,0):SetStatus STATUS_OK
    Case 4:WriteAddr ADDR_T_REL,1,0,CULngInt(Timer*1000) And CellMask():SetLogicFlags ReadAddr(ADDR_T_REL,1,0):SetStatus STATUS_OK
    Case 5:outputText+=Chr(10):SetStatus STATUS_OK
    Case 6:outputText+="[UXM META]":SetStatus STATUS_OK
    Case 7:WriteAddr ADDR_T_REL,1,0,7:SetLogicFlags 7:SetStatus STATUS_OK
    Case 8:WriteAddr ADDR_T_REL,1,0,8:SetLogicFlags 8:SetStatus STATUS_OK
    Case 9:WriteAddr ADDR_T_REL,1,0,statusByte:SetLogicFlags statusByte
    Case 10:SetStatus STATUS_OK
    Case 11:SetStatus ReadAddr(ADDR_T_REL,-2,0) And &HFF
    Case 12:outputText+="STATUS="+Str(statusByte):SetStatus STATUS_OK
    Case 13:If statusByte=0 Then SetStatus 1 Else SetStatus statusByte
    Case 14:SetStatus STATUS_OK
    Case 15
        If (flags And FLAG_ERR)<>0 Then
            WriteAddr ADDR_T_REL,1,0,1
    Case 160
        MatrixInit CLng(a),CLng(b),CLng(c),0,0
    Case 161
        Dim i161 As Long
        If MatIsValid(CLng(a))=0 Then SetStatus STATUS_DATA_BOUNDS Else
            For i161=0 To dataMem(CLng(a)+10)-1:dataMem(CLng(a)+16+i161)=0:Next:SetStatus STATUS_OK
    Case 162
        Dim idx162 As Long, ok162 As Long
        idx162=MatrixCellIndex(CLng(a),CLng(b),CLng(c),ok162)
        If ok162=0 Then SetStatus STATUS_DATA_BOUNDS Else dataMem(idx162)=ReadAddr(ADDR_T_REL,-3,0) And CellMask():SetStatus STATUS_OK
    Case 163
        Dim idx163 As Long, ok163 As Long
        idx163=MatrixCellIndex(CLng(a),CLng(b),CLng(c),ok163)
        If ok163=0 Then SetStatus STATUS_DATA_BOUNDS Else WriteAddr ADDR_T_REL,1,0,dataMem(idx163):SetLogicFlags ReadAddr(ADDR_T_REL,1,0):SetStatus STATUS_OK
    Case 164
        Dim i164 As Long, v164 As ULongInt
        If MatIsValid(CLng(a))=0 Then SetStatus STATUS_DATA_BOUNDS Else
            v164=ReadAddr(ADDR_T_REL,-3,0)
            For i164=0 To dataMem(CLng(a)+10)-1:dataMem(CLng(a)+16+i164)=v164 And CellMask():Next:SetStatus STATUS_OK
    Case 165
        Dim i165 As Long, n165 As Long
        If MatIsValid(CLng(a))=0 Or MatIsValid(CLng(b))=0 Then SetStatus STATUS_DATA_BOUNDS Else
            n165=dataMem(CLng(b)+10)
            If dataMem(CLng(a)+10)<>n165 Then SetStatus STATUS_DATA_BOUNDS Else
                For i165=0 To n165-1:dataMem(CLng(a)+16+i165)=dataMem(CLng(b)+16+i165):Next:SetStatus STATUS_OK
    Case 166
        Dim rr166 As Long, cc166 As Long, r166 As Long, c166 As Long, idx166 As Long, ok166 As Long
        If MatIsValid(CLng(a))=0 Then SetStatus STATUS_DATA_BOUNDS Else
            rr166=dataMem(CLng(a)+5):cc166=dataMem(CLng(a)+6)
            For r166=0 To rr166-1
                outputText+="["
                For c166=0 To cc166-1
                    idx166=MatrixCellIndex(CLng(a),r166,c166,ok166)
                    If c166>0 Then outputText+=" "
                    outputText+=LTrim(Str(ToSignedCell(dataMem(idx166))))
                Next
                outputText+="]"+Chr(10)
            Next
            SetStatus STATUS_OK
    Case 167
        Dim i167 As Long, n167 As Long
        If MatIsValid(CLng(a))=0 Or MatIsValid(CLng(b))=0 Or MatIsValid(CLng(c))=0 Then SetStatus STATUS_DATA_BOUNDS Else
            n167=dataMem(CLng(a)+10)
            If dataMem(CLng(b)+10)<>n167 Or dataMem(CLng(c)+10)<>n167 Then SetStatus STATUS_DATA_BOUNDS Else
                For i167=0 To n167-1:dataMem(CLng(a)+16+i167)=(ToSignedCell(dataMem(CLng(b)+16+i167))+ToSignedCell(dataMem(CLng(c)+16+i167))) And CellMask():Next:SetStatus STATUS_OK
    Case 168
        Dim i168 As Long, n168 As Long
        If MatIsValid(CLng(a))=0 Or MatIsValid(CLng(b))=0 Or MatIsValid(CLng(c))=0 Then SetStatus STATUS_DATA_BOUNDS Else
            n168=dataMem(CLng(a)+10)
            If dataMem(CLng(b)+10)<>n168 Or dataMem(CLng(c)+10)<>n168 Then SetStatus STATUS_DATA_BOUNDS Else
                For i168=0 To n168-1:dataMem(CLng(a)+16+i168)=(ToSignedCell(dataMem(CLng(b)+16+i168))-ToSignedCell(dataMem(CLng(c)+16+i168))) And CellMask():Next:SetStatus STATUS_OK
    Case 169
        Dim i169 As Long, n169 As Long, s169 As LongInt
        If MatIsValid(CLng(a))=0 Or MatIsValid(CLng(b))=0 Then SetStatus STATUS_DATA_BOUNDS Else
            n169=dataMem(CLng(a)+10)
            If dataMem(CLng(b)+10)<>n169 Then SetStatus STATUS_DATA_BOUNDS Else
                s169=ToSignedCell(c)
                For i169=0 To n169-1:dataMem(CLng(a)+16+i169)=(ToSignedCell(dataMem(CLng(b)+16+i169))*s169) And CellMask():Next:SetStatus STATUS_OK
    Case 170
        Dim ar170 As Long, ac170 As Long, br170 As Long, bc170 As Long, r170 As Long, c170 As Long, k170 As Long
        Dim acc170 As LongInt, ia170 As Long, ib170 As Long, io170 As Long, oka170 As Long, okb170 As Long, oko170 As Long
        If MatIsValid(CLng(a))=0 Or MatIsValid(CLng(b))=0 Or MatIsValid(CLng(c))=0 Then SetStatus STATUS_DATA_BOUNDS Else
            ar170=dataMem(CLng(b)+5):ac170=dataMem(CLng(b)+6):br170=dataMem(CLng(c)+5):bc170=dataMem(CLng(c)+6)
            If ac170<>br170 Or dataMem(CLng(a)+5)<>ar170 Or dataMem(CLng(a)+6)<>bc170 Then SetStatus STATUS_DATA_BOUNDS Else
                For r170=0 To ar170-1
                    For c170=0 To bc170-1
                        acc170=0
                        For k170=0 To ac170-1
                            ia170=MatrixCellIndex(CLng(b),r170,k170,oka170)
                            ib170=MatrixCellIndex(CLng(c),k170,c170,okb170)
                            acc170+=ToSignedCell(dataMem(ia170))*ToSignedCell(dataMem(ib170))
                        Next
                        io170=MatrixCellIndex(CLng(a),r170,c170,oko170)
                        dataMem(io170)=acc170 And CellMask()
                    Next
                Next
                SetStatus STATUS_OK
    Case 171
        Dim rs171 As Long, cs171 As Long, r171 As Long, c171 As Long, is171 As Long, id171 As Long, oks171 As Long, okd171 As Long
        If MatIsValid(CLng(a))=0 Or MatIsValid(CLng(b))=0 Then SetStatus STATUS_DATA_BOUNDS Else
            rs171=dataMem(CLng(b)+5):cs171=dataMem(CLng(b)+6)
            If dataMem(CLng(a)+5)<>cs171 Or dataMem(CLng(a)+6)<>rs171 Then SetStatus STATUS_DATA_BOUNDS Else
                For r171=0 To rs171-1
                    For c171=0 To cs171-1
                        is171=MatrixCellIndex(CLng(b),r171,c171,oks171):id171=MatrixCellIndex(CLng(a),c171,r171,okd171):dataMem(id171)=dataMem(is171)
                    Next
                Next
                SetStatus STATUS_OK
    Case 172
        Dim n172 As Long, i172 As Long, idx172 As Long, ok172 As Long
        n172=CLng(b)
        MatrixInit CLng(a),n172,n172,0,0
        If statusByte=0 Then
            For i172=0 To n172-1
                idx172=MatrixCellIndex(CLng(a),i172,i172,ok172):If ok172<>0 Then dataMem(idx172)=1
            Next
        End If
    Case 173
        Dim n173 As Long, i173 As Long, idx173 As Long, ok173 As Long, tr173 As LongInt
        If MatIsValid(CLng(a))=0 Then SetStatus STATUS_DATA_BOUNDS Else
            If dataMem(CLng(a)+5)<>dataMem(CLng(a)+6) Then SetStatus STATUS_DATA_BOUNDS Else
                n173=dataMem(CLng(a)+5):tr173=0
                For i173=0 To n173-1:idx173=MatrixCellIndex(CLng(a),i173,i173,ok173):tr173+=ToSignedCell(dataMem(idx173)):Next
                WriteAddr ADDR_T_REL,1,0,tr173 And CellMask():SetLogicFlags ReadAddr(ADDR_T_REL,1,0):SetStatus STATUS_OK
    Case 174
        Dim m00 As LongInt,m01 As LongInt,m10 As LongInt,m11 As LongInt,ok174 As Long
        If MatIsValid(CLng(a))=0 Then SetStatus STATUS_DATA_BOUNDS Else
            If dataMem(CLng(a)+5)<>2 Or dataMem(CLng(a)+6)<>2 Then SetStatus STATUS_DATA_BOUNDS Else
                m00=ToSignedCell(dataMem(MatrixCellIndex(CLng(a),0,0,ok174)))
                m01=ToSignedCell(dataMem(MatrixCellIndex(CLng(a),0,1,ok174)))
                m10=ToSignedCell(dataMem(MatrixCellIndex(CLng(a),1,0,ok174)))
                m11=ToSignedCell(dataMem(MatrixCellIndex(CLng(a),1,1,ok174)))
                WriteAddr ADDR_T_REL,1,0,(m00*m11-m01*m10) And CellMask():SetLogicFlags ReadAddr(ADDR_T_REL,1,0):SetStatus STATUS_OK
    Case 175
        If MatIsValid(CLng(a))=0 Then SetStatus STATUS_DATA_BOUNDS Else outputText+=Str(dataMem(CLng(a)+5))+"x"+Str(dataMem(CLng(a)+6)):SetStatus STATUS_OK
    Case 176
        Dim i176 As Long, n176 As Long
        If MatIsValid(CLng(a))=0 Then SetStatus STATUS_DATA_BOUNDS Else
            n176=dataMem(CLng(a)+10)
            For i176=0 To n176-1
                If i176>0 Then outputText+=" "
                outputText+=LTrim(Str(ToSignedCell(dataMem(CLng(a)+16+i176))))
            Next
            SetStatus STATUS_OK
    Case 200,201
        FPWriteScaled CLng(a),0:dataMem(CLng(a)+1)=IIf(id=201,32,16):SetStatus STATUS_OK
    Case 202
        FPWriteScaled CLng(a),0:SetStatus STATUS_OK
    Case 203
        FPWriteScaled CLng(a),FPReadScaled(CLng(b)):SetStatus STATUS_OK
    Case 204
        If CLng(a)+2>=dataCells Then SetStatus STATUS_DATA_BOUNDS Else
            dataMem(CLng(a)+2)=FPReadScaled(CLng(a)) And CellMask():SetStatus STATUS_OK
    Case 205
        WriteAddr ADDR_T_REL,1,0,(FPReadScaled(CLng(a))\FPScaleConst()) And CellMask()
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0):SetStatus STATUS_OK
    Case 206
        If FPReadScaled(CLng(a))=0 Then WriteAddr ADDR_T_REL,1,0,1 Else WriteAddr ADDR_T_REL,1,0,0
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0):SetStatus STATUS_OK
    Case 207
        If FPReadScaled(CLng(a))=0 Then WriteAddr ADDR_T_REL,1,0,0 ElseIf FPReadScaled(CLng(a))<0 Then WriteAddr ADDR_T_REL,1,0,CellMask() Else WriteAddr ADDR_T_REL,1,0,1
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0):SetStatus STATUS_OK
    Case 208
        WriteAddr ADDR_T_REL,1,0,Abs(FPReadScaled(CLng(a))\FPScaleConst()) And CellMask()
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0):SetStatus STATUS_OK
    Case 209
        outputText+="FP RAW base="+LTrim(Str(a))+" v="+LTrim(Str(FPReadScaled(CLng(a)))):SetStatus STATUS_OK
    Case 210
        FPWriteScaled CLng(a),FPReadScaled(CLng(b))+FPReadScaled(CLng(c)):SetStatus STATUS_OK
    Case 211
        FPWriteScaled CLng(a),FPReadScaled(CLng(b))-FPReadScaled(CLng(c)):SetStatus STATUS_OK
    Case 212
        FPWriteScaled CLng(a),(FPReadScaled(CLng(b))*FPReadScaled(CLng(c)))\FPScaleConst():SetStatus STATUS_OK
    Case 213
        If FPReadScaled(CLng(c))=0 Then SetStatus STATUS_DIV_ZERO Else FPWriteScaled CLng(a),(FPReadScaled(CLng(b))*FPScaleConst())\FPReadScaled(CLng(c)):SetStatus STATUS_OK
    Case 214
        If FPReadScaled(CLng(b))=FPReadScaled(CLng(c)) Then WriteAddr ADDR_T_REL,1,0,0 ElseIf FPReadScaled(CLng(b))>FPReadScaled(CLng(c)) Then WriteAddr ADDR_T_REL,1,0,1 Else WriteAddr ADDR_T_REL,1,0,CellMask()
        SetLogicFlags ReadAddr(ADDR_T_REL,1,0):SetStatus STATUS_OK
    Case 215
        FPWriteScaled CLng(a),Abs(FPReadScaled(CLng(b))):SetStatus STATUS_OK
    Case 216
        FPWriteScaled CLng(a),-FPReadScaled(CLng(b)):SetStatus STATUS_OK
    Case 217
        FPWriteScaled CLng(a),FPReadScaled(CLng(a)):SetStatus STATUS_OK
    Case 218
        FPWriteScaled CLng(a),FPReadScaled(CLng(a)):SetStatus STATUS_OK
    Case 219
        FPWriteScaled CLng(a),(FPReadScaled(CLng(a))\FPScaleConst())*FPScaleConst():SetStatus STATUS_OK
    Case 220
        FPWriteScaled CLng(a),ToSignedCell(b)*FPScaleConst():SetStatus STATUS_OK
    Case 221
        FPWriteScaled CLng(a),CLngInt(Val(ReadDataString(CLng(b)))*FPScaleConst()):SetStatus STATUS_OK
    Case 222
        WriteDataString CLng(b),Str(CDbl(FPReadScaled(CLng(a)))/CDbl(FPScaleConst())):SetStatus STATUS_OK
    Case 223
        outputText+=Str(CDbl(FPReadScaled(CLng(b)))/CDbl(FPScaleConst())):SetStatus STATUS_OK
    Case 224
        FPWriteScaled CLng(a),FPReadScaled(CLng(a))*CLngInt(10^CLng(b)):SetStatus STATUS_OK
    Case 230,231,232,233,234
        SetStatus STATUS_INVALID_META
    Case 240
        Dim deg240 As Long, i240 As Long
        If dataMem(CLng(b))<>80 Then SetStatus STATUS_DATA_BOUNDS Else
            deg240=dataMem(CLng(b)+2):dataMem(CLng(a)+0)=80:dataMem(CLng(a)+1)=1:dataMem(CLng(a)+3)=dataMem(CLng(b)+3)
            If deg240<=0 Then dataMem(CLng(a)+2)=0:dataMem(CLng(a)+4)=0 Else dataMem(CLng(a)+2)=deg240-1:For i240=1 To deg240:dataMem(CLng(a)+3+i240)=(ToSignedCell(dataMem(CLng(b)+4+i240))*i240) And CellMask():Next
            SetStatus STATUS_OK
    Case 241
        Dim deg241 As Long, i241 As Long
        If dataMem(CLng(b))<>80 Then SetStatus STATUS_DATA_BOUNDS Else
            deg241=dataMem(CLng(b)+2):dataMem(CLng(a)+0)=80:dataMem(CLng(a)+1)=1:dataMem(CLng(a)+2)=deg241+1:dataMem(CLng(a)+3)=dataMem(CLng(b)+3):dataMem(CLng(a)+4)=c And CellMask()
            For i241=0 To deg241:dataMem(CLng(a)+5+i241)=(ToSignedCell(dataMem(CLng(b)+4+i241))\(i241+1)) And CellMask():Next:SetStatus STATUS_OK
    Case 242
        Dim deg242 As Long, i242 As Long, acc242 As LongInt
        If dataMem(CLng(a))<>80 Then SetStatus STATUS_DATA_BOUNDS Else
            deg242=dataMem(CLng(a)+2):acc242=0
            For i242=deg242 To 0 Step -1:acc242=acc242*ToSignedCell(b)+ToSignedCell(dataMem(CLng(a)+4+i242)):Next
            WriteAddr ADDR_T_REL,1,0,acc242 And CellMask():SetLogicFlags ReadAddr(ADDR_T_REL,1,0):SetStatus STATUS_OK
    Case 243
        Dim deg243 As Long, i243 As Long
        If dataMem(CLng(a))<>80 Then SetStatus STATUS_DATA_BOUNDS Else
            deg243=dataMem(CLng(a)+2)
            For i243=0 To deg243
                If i243>0 Then outputText+=" + "
                outputText+=LTrim(Str(ToSignedCell(dataMem(CLng(a)+4+i243))))
                If i243>0 Then outputText+="x"
                If i243>1 Then outputText+="^"+LTrim(Str(i243))
            Next
            SetStatus STATUS_OK
    Case 244
        Dim i244 As Long
        For i244=0 To CLng(b)-1:dataMem(CLng(a)+i244)=0:Next:SetStatus STATUS_OK
    Case 245
        If dataMem(CLng(a))<>80 Then SetStatus STATUS_DATA_BOUNDS Else
            WriteAddr ADDR_T_REL,1,0,dataMem(CLng(a)+2):SetLogicFlags ReadAddr(ADDR_T_REL,1,0):SetStatus STATUS_OK
    Case 246
        If dataMem(CLng(a))<>80 Then SetStatus STATUS_DATA_BOUNDS Else
            WriteAddr ADDR_T_REL,1,0,dataMem(CLng(a)+3):SetLogicFlags ReadAddr(ADDR_T_REL,1,0):SetStatus STATUS_OK
    Case 247
        If dataMem(CLng(a))<>80 Then SetStatus STATUS_DATA_BOUNDS Else outputText+="POLY@"+LTrim(Str(a))+" deg="+LTrim(Str(dataMem(CLng(a)+2))):SetStatus STATUS_OK
    Case 248
        If dataMem(CLng(a))<>69 Then SetStatus STATUS_DATA_BOUNDS Else
            WriteAddr ADDR_T_REL,1,0,dataMem(CLng(a)+2):SetLogicFlags ReadAddr(ADDR_T_REL,1,0):SetStatus STATUS_OK
    Case 249
        If dataMem(CLng(a))<>69 Then SetStatus STATUS_DATA_BOUNDS Else outputText+="EXPR@"+LTrim(Str(a))+" tok="+LTrim(Str(dataMem(CLng(a)+2))):SetStatus STATUS_OK
    Case 250
        WriteAddr ADDR_T_REL,1,0,ExprEvalRpn(CLng(a),ToSignedCell(b)) And CellMask():SetLogicFlags ReadAddr(ADDR_T_REL,1,0):SetStatus STATUS_OK
    Case 251
        Dim h251 As LongInt, f1251 As LongInt, f2251 As LongInt
        h251=ToSignedCell(c):If h251=0 Then h251=1
        f1251=ExprEvalRpn(CLng(a),ToSignedCell(b)+h251):f2251=ExprEvalRpn(CLng(a),ToSignedCell(b)-h251)
        WriteAddr ADDR_T_REL,1,0,((f1251-f2251)\(2*h251)) And CellMask():SetLogicFlags ReadAddr(ADDR_T_REL,1,0):SetStatus STATUS_OK
    Case 252
        Dim aa252 As LongInt, bb252 As LongInt, n252 As Long, h252 As Double, x252 As Double, sum252 As Double, i252 As Long
        aa252=ToSignedCell(b):bb252=ToSignedCell(c):n252=16:If n252<=0 Then n252=1
        h252=(bb252-aa252)/n252:sum252=0
        For i252=0 To n252
            x252=aa252+i252*h252
            If i252=0 Or i252=n252 Then sum252+=ExprEvalRpn(CLng(a),CLngInt(x252)) Else sum252+=2*ExprEvalRpn(CLng(a),CLngInt(x252))
        Next
        WriteAddr ADDR_T_REL,1,0,CLngInt(sum252*h252/2.0) And CellMask():SetLogicFlags ReadAddr(ADDR_T_REL,1,0):SetStatus STATUS_OK
    Case 253
        Dim aa253 As LongInt, bb253 As LongInt, n253 As Long, h253 As Double, x253 As Double, sum253 As Double, i253 As Long
        aa253=ToSignedCell(b):bb253=ToSignedCell(c):n253=16:If (n253 Mod 2)=1 Then n253+=1
        h253=(bb253-aa253)/n253:sum253=ExprEvalRpn(CLng(a),aa253)+ExprEvalRpn(CLng(a),bb253)
        For i253=1 To n253-1
            x253=aa253+i253*h253
            If (i253 Mod 2)=0 Then sum253+=2*ExprEvalRpn(CLng(a),CLngInt(x253)) Else sum253+=4*ExprEvalRpn(CLng(a),CLngInt(x253))
        Next
        WriteAddr ADDR_T_REL,1,0,CLngInt(sum253*h253/3.0) And CellMask():SetLogicFlags ReadAddr(ADDR_T_REL,1,0):SetStatus STATUS_OK
    Case 254
        outputText+="[RPN @"+LTrim(Str(a))+"]":SetStatus STATUS_OK
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

Function FifoPeek() As ULongInt
    If fifoCount=0 Then SetStatus STATUS_STACK_UNDERFLOW:Return 0
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


