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
