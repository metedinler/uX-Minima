' Auto-split by V3 modularization
Function CellMask() As ULongInt
    If cellBits=8 Then
        Return &HFFull
    ElseIf cellBits=16 Then
        Return &HFFFFull
    Else
        Return &HFFFFFFFFull
    End If
End Function

Function ScaleFactor() As LongInt
    If cellBits=8 Then
        Return 100
    ElseIf cellBits=16 Then
        Return 1000
    Else
        Return 10000
    End If
End Function

Function ToSignedCell(ByVal v As ULongInt) As LongInt
    Dim masked As ULongInt
    masked=v And CellMask()
    If (flags And FLAG_SGN)=0 Then Return CLngInt(masked)
    If cellBits=8 Then
        If (masked And &H80ull)<>0 Then Return CLngInt(masked)-256 Else Return CLngInt(masked)
    ElseIf cellBits=16 Then
        If (masked And &H8000ull)<>0 Then Return CLngInt(masked)-65536 Else Return CLngInt(masked)
    Else
        If (masked And &H80000000ull)<>0 Then Return CLngInt(masked)-4294967296 Else Return CLngInt(masked)
    End If
End Function

Function MatIsValid(ByVal baseAddr As Long) As Long
    If baseAddr<0 Or baseAddr+15>=dataCells Then Return 0
    If dataMem(baseAddr+0)<>77 Then Return 0
    If dataMem(baseAddr+1)<>1 Then Return 0
    If dataMem(baseAddr+2)<>2 Then Return 0
    Return -1
End Function


Function MatrixCellIndex(ByVal baseAddr As Long, ByVal r As Long, ByVal c As Long, ByRef ok As Long) As Long
    Dim rows As Long, cols As Long, idx As Long
    ok=0
    If MatIsValid(baseAddr)=0 Then Return 0
    rows=CLng(dataMem(baseAddr+5))
    cols=CLng(dataMem(baseAddr+6))
    If r<0 Or c<0 Or r>=rows Or c>=cols Then Return 0
    idx=baseAddr+CLng(dataMem(baseAddr+9))+r*CLng(dataMem(baseAddr+12))+c*CLng(dataMem(baseAddr+13))
    If idx<0 Or idx>=dataCells Then Return 0
    ok=-1
    Return idx
End Function


Sub MatrixInit(ByVal baseAddr As Long, ByVal rows As Long, ByVal cols As Long, ByVal typ As Long, ByVal scale As Long)
    Dim total As Long, i As Long, flg As Long
    If baseAddr<0 Or rows<=0 Or cols<=0 Then SetStatus STATUS_DATA_BOUNDS:Exit Sub
    total=rows*cols
    If baseAddr+16+total-1>=dataCells Then SetStatus STATUS_DATA_BOUNDS:Exit Sub
    flg=0:If typ=1 Then flg=1 Else : If typ=2 Then flg=2
    dataMem(baseAddr+0)=77:dataMem(baseAddr+1)=1:dataMem(baseAddr+2)=2:dataMem(baseAddr+3)=typ
    dataMem(baseAddr+4)=flg:dataMem(baseAddr+5)=rows:dataMem(baseAddr+6)=cols:dataMem(baseAddr+7)=scale
    dataMem(baseAddr+8)=1:dataMem(baseAddr+9)=16:dataMem(baseAddr+10)=total:dataMem(baseAddr+11)=16+total
    dataMem(baseAddr+12)=cols:dataMem(baseAddr+13)=1:dataMem(baseAddr+14)=0:dataMem(baseAddr+15)=0
    For i=0 To total-1:dataMem(baseAddr+16+i)=0:Next
    SetStatus STATUS_OK
End Sub


Function FPScaleConst() As LongInt
    Return 1000000
End Function


Function FPReadScaled(ByVal baseAddr As Long) As LongInt
    If baseAddr<0 Or baseAddr>=dataCells Then Return 0
    Return ToSignedCell(dataMem(baseAddr))
End Function


Sub FPWriteScaled(ByVal baseAddr As Long, ByVal v As LongInt)
    If baseAddr<0 Or baseAddr>=dataCells Then Exit Sub
    dataMem(baseAddr)=v And CellMask()
End Sub


Function ReadDataString(ByVal startCell As Long) As String
    Dim s As String, i As Long, ch As ULongInt
    s=""
    If startCell<0 Then Return s
    For i=startCell To dataCells-1
        ch=dataMem(i) And &HFF
        If ch=0 Then Exit For
        s+=Chr(ch)
    Next
    Return s
End Function


Sub WriteDataString(ByVal startCell As Long, ByVal s As String)
    Dim i As Long
    If startCell<0 Or startCell>=dataCells Then Exit Sub
    For i=1 To Len(s)
        If startCell+i-1>=dataCells Then Exit For
        dataMem(startCell+i-1)=Asc(Mid(s,i,1)) And CellMask()
    Next
    If startCell+Len(s)<dataCells Then dataMem(startCell+Len(s))=0
End Sub


Function ExprEvalRpn(ByVal exprBase As Long, ByVal x As LongInt) As LongInt
    Dim tokenCount As Long, ip As Long, tok As LongInt, st(0 To 255) As LongInt, spx As Long
    Dim a As LongInt, b As LongInt
    If exprBase<0 Or exprBase+4>=dataCells Then Return 0
    If dataMem(exprBase)<>69 Then Return 0
    tokenCount=CLng(dataMem(exprBase+2))
    ip=exprBase+4:spx=0
    Do While ip<exprBase+4+tokenCount And ip<dataCells
        tok=ToSignedCell(dataMem(ip)):ip+=1
        Select Case tok
        Case 1
            st(spx)=ToSignedCell(dataMem(ip)):spx+=1:ip+=1
        Case 2
            st(spx)=x:spx+=1
        Case 10
            If spx<2 Then Return 0
            b=st(spx-1):a=st(spx-2):spx-=2:st(spx)=a+b:spx+=1
        Case 11
            If spx<2 Then Return 0
            b=st(spx-1):a=st(spx-2):spx-=2:st(spx)=a-b:spx+=1
        Case 12
            If spx<2 Then Return 0
            b=st(spx-1):a=st(spx-2):spx-=2:st(spx)=a*b:spx+=1
        Case 13
            If spx<2 Then Return 0
            b=st(spx-1):a=st(spx-2):spx-=2:If b=0 Then st(spx)=0 Else st(spx)=a\b:spx+=1
        Case 14
            If spx<2 Then Return 0
            b=st(spx-1):a=st(spx-2):spx-=2:st(spx)=CLngInt((CDbl(a)^CDbl(b))):spx+=1
        Case 20
            If spx<1 Then Return 0
            a=st(spx-1):st(spx-1)=CLngInt(Sin(a))
        Case 21
            If spx<1 Then Return 0
            a=st(spx-1):st(spx-1)=CLngInt(Cos(a))
        Case 22
            If spx<1 Then Return 0
            a=st(spx-1):st(spx-1)=CLngInt(Tan(a))
        Case 23
            If spx<1 Then Return 0
            a=st(spx-1):st(spx-1)=CLngInt(Exp(a))
        Case 24
            If spx<1 Then Return 0
            a=st(spx-1):If a<=0 Then st(spx-1)=0 Else st(spx-1)=CLngInt(Log(a))
        Case 25
            If spx<1 Then Return 0
            a=st(spx-1):If a<0 Then st(spx-1)=0 Else st(spx-1)=CLngInt(Sqr(a))
        Case 30
            If spx<1 Then Return 0
            st(spx-1)=-st(spx-1)
        Case 31
            If spx<1 Then Return 0
            If st(spx-1)<0 Then st(spx-1)=-st(spx-1)
        Case 99
            Exit Do
        End Select
    Loop
    If spx<=0 Then Return 0
    Return st(spx-1)
End Function


