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
Const STATUS_PROTECTED_META As UByte=24
Const STATUS_EOF As UByte=26
Const PI_D As Double=3.1415926535897932384626433832795
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
Declare Function ReadTapeRel(ByVal rel As LongInt) As ULongInt
Declare Sub WriteTapeRel(ByVal rel As LongInt, ByVal value As ULongInt)
Declare Function ToSignedValue(ByVal value As ULongInt) As LongInt
Declare Function FromSignedValue(ByVal value As LongInt) As ULongInt
Declare Function IsSignedMode() As Long
Declare Function IsBigEndian() As Long
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
Declare Sub SetResult(ByVal value As ULongInt)
Declare Function ResultValue() As ULongInt
Declare Function StackRead(ByVal idx As ULongInt) As ULongInt
Declare Sub StackWrite(ByVal idx As ULongInt, ByVal value As ULongInt)
Declare Sub StackPush(ByVal value As ULongInt)
Declare Function StackPop() As ULongInt
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
Declare Sub MetaCore(ByVal metaId As ULongInt)
Declare Sub MetaArithmetic(ByVal metaId As ULongInt)
Declare Sub MetaMath(ByVal metaId As ULongInt)
Declare Sub MetaIO(ByVal metaId As ULongInt)
Declare Sub MetaPointerMemory(ByVal metaId As ULongInt)
Declare Sub MetaFlagsEndian(ByVal metaId As ULongInt)
Declare Sub MetaData(ByVal metaId As ULongInt)
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
End Sub
Function StackPop() As ULongInt
If ux_sp=0 Then
SetStatus STATUS_STACK_UNDERFLOW
Return 0
End If
ux_sp=ux_sp-1
Return StackRead(ux_sp)
End Function
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
If x>=1.0 Then Return 0.0
If x<=-1.0 Then Return 0.0
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
If v>CDbl(2147483647) Then
ux_flags=ux_flags Or FLAG_O
SetStatus STATUS_OVERFLOW
Return CellMask()
End If
If v<CDbl(-2147483648.0) Then
ux_flags=ux_flags Or FLAG_O
SetStatus STATUS_UNDERFLOW
Return 0
End If
Return ClampToCell(CLngInt(v))
End Function
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
ElseIf metaId<120 Then
MetaPointerMemory metaId
ElseIf metaId<180 Then
MetaFlagsEndian metaId
ElseIf metaId<200 Then
MetaData metaId
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
ux_status=0
ux_flags=ux_flags And Not FLAG_ERR
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
Dim sr As LongInt
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
sr=sf\sb
r=FromSignedValue(sr)
SetResult r
SetZeroSignFlags r
ux_flags=ux_flags And Not FLAG_C
ux_flags=ux_flags And Not FLAG_O
SetStatus STATUS_OK
End If
Else
r=(a\b) And CellMask()
SetResult r
SetZeroSignFlags r
ux_flags=ux_flags And Not FLAG_C
ux_flags=ux_flags And Not FLAG_O
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
sr=sf Mod sb
r=FromSignedValue(sr)
SetResult r
SetZeroSignFlags r
ux_flags=ux_flags And Not FLAG_C
ux_flags=ux_flags And Not FLAG_O
SetStatus STATUS_OK
End If
Else
r=(a Mod b) And CellMask()
SetResult r
SetZeroSignFlags r
ux_flags=ux_flags And Not FLAG_C
ux_flags=ux_flags And Not FLAG_O
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
If b=0 Then
SetResult 0
SetStatus STATUS_DIV_ZERO
Else
SetResult (a\b) And CellMask()
SetLogicFlags ResultValue()
SetStatus STATUS_OK
End If
Case 34
If b=0 Then
SetResult 0
SetStatus STATUS_DIV_ZERO
Else
SetResult FromSignedValue(ToSignedValue(a)\ToSignedValue(b))
SetLogicFlags ResultValue()
SetStatus STATUS_OK
End If
Case 35
If b=0 Then
SetResult 0
SetStatus STATUS_DIV_ZERO
Else
SetResult (a Mod b) And CellMask()
SetLogicFlags ResultValue()
SetStatus STATUS_OK
End If
Case 36
If b=0 Then
SetResult 0
SetStatus STATUS_DIV_ZERO
Else
SetResult FromSignedValue(ToSignedValue(a) Mod ToSignedValue(b))
SetLogicFlags ResultValue()
SetStatus STATUS_OK
End If
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
Sub MetaFlagsEndian(ByVal metaId As ULongInt)
Dim a As ULongInt
Dim b As ULongInt
Dim r As ULongInt
a=Arg1()
b=Arg2()
Select Case metaId
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
Case 130
If a=b Then r=1 Else r=0
SetResult r
SetCompareFlags a,b
SetStatus STATUS_OK
Case 131
If a>b Then r=1 Else r=0
SetResult r
SetCompareFlags a,b
SetStatus STATUS_OK
Case 132
If a<b Then r=1 Else r=0
SetResult r
SetCompareFlags a,b
SetStatus STATUS_OK
Case 133
If ToSignedValue(a)=ToSignedValue(b) Then r=1 Else r=0
SetResult r
SetCompareFlags a,b
SetStatus STATUS_OK
Case 134
If ToSignedValue(a)>ToSignedValue(b) Then r=1 Else r=0
SetResult r
SetCompareFlags a,b
SetStatus STATUS_OK
Case 135
If ToSignedValue(a)<ToSignedValue(b) Then r=1 Else r=0
SetResult r
SetCompareFlags a,b
SetStatus STATUS_OK
Case 140
If (ux_flags And FLAG_C)<>0 Then SetResult 1 Else SetResult 0
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 141
ux_flags=ux_flags Or FLAG_C
SetStatus STATUS_OK
Case 142
ux_flags=ux_flags And Not FLAG_C
SetStatus STATUS_OK
Case 143
If (ux_flags And FLAG_O)<>0 Then SetResult 1 Else SetResult 0
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 144
ux_flags=ux_flags Or FLAG_O
SetStatus STATUS_OK
Case 145
ux_flags=ux_flags And Not FLAG_O
SetStatus STATUS_OK
Case 146
If (ux_flags And FLAG_Z)<>0 Then SetResult 1 Else SetResult 0
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 147
If (ux_flags And FLAG_S)<>0 Then SetResult 1 Else SetResult 0
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 148
ux_flags=ux_flags And Not (FLAG_Z Or FLAG_C Or FLAG_O Or FLAG_S)
SetStatus STATUS_OK
Case 149
SetResult ux_flags
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 150
ux_flags=ux_flags And Not FLAG_END
SetStatus STATUS_OK
Case 151
ux_flags=ux_flags Or FLAG_END
SetStatus STATUS_OK
Case 152
If IsBigEndian() Then SetResult 1 Else SetResult 0
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 153
If IsBigEndian() Then
WriteTapeRel 1,(b Shr 8) And &HFF
WriteTapeRel 2,b And &HFF
Else
WriteTapeRel 1,b And &HFF
WriteTapeRel 2,(b Shr 8) And &HFF
End If
SetStatus STATUS_OK
Case 154
If IsBigEndian() Then
r=((ReadTapeRel(1) And &HFF) Shl 8) Or (ReadTapeRel(2) And &HFF)
Else
r=(ReadTapeRel(1) And &HFF) Or ((ReadTapeRel(2) And &HFF) Shl 8)
End If
SetResult r
SetLogicFlags r
SetStatus STATUS_OK
Case 155
If IsBigEndian() Then
WriteTapeRel 1,(b Shr 24) And &HFF
WriteTapeRel 2,(b Shr 16) And &HFF
WriteTapeRel 3,(b Shr 8) And &HFF
WriteTapeRel 4,b And &HFF
Else
WriteTapeRel 1,b And &HFF
WriteTapeRel 2,(b Shr 8) And &HFF
WriteTapeRel 3,(b Shr 16) And &HFF
WriteTapeRel 4,(b Shr 24) And &HFF
End If
SetStatus STATUS_OK
Case 156
If IsBigEndian() Then
r=((ReadTapeRel(1) And &HFF) Shl 24) Or ((ReadTapeRel(2) And &HFF) Shl 16) Or ((ReadTapeRel(3) And &HFF) Shl 8) Or (ReadTapeRel(4) And &HFF)
Else
r=(ReadTapeRel(1) And &HFF) Or ((ReadTapeRel(2) And &HFF) Shl 8) Or ((ReadTapeRel(3) And &HFF) Shl 16) Or ((ReadTapeRel(4) And &HFF) Shl 24)
End If
SetResult r
SetLogicFlags r
SetStatus STATUS_OK
Case Else
SetStatus STATUS_INVALID_META
End Select
End Sub
Sub MetaData(ByVal metaId As ULongInt)
Dim a As ULongInt
Dim b As ULongInt
a=Arg1()
b=Arg2()
Select Case metaId
Case 180
If b>=ux_data_cells Then
SetStatus STATUS_DATA_BOUNDS
Else
SetResult ReadCell(DataBase(),b)
SetLogicFlags ResultValue()
SetStatus STATUS_OK
End If
Case 181
If a>=ux_data_cells Then
SetStatus STATUS_DATA_BOUNDS
Else
WriteCell DataBase(),a,b
SetStatus STATUS_OK
End If
Case 185
If b>=ux_data_cells Then
SetStatus STATUS_DATA_BOUNDS
Else
a=ReadCell(DataBase(),b)
If a>=48 And a<=57 Then
SetResult a-48
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Else
SetResult 0
SetStatus STATUS_UNDERFLOW
End If
End If
Case Else
SetStatus STATUS_INVALID_META
End Select
End Sub
Randomize Timer
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
