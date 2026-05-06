' Auto-split by V3 modularization
Sub ParseMeta(ByRef code As String, ByRef p As Long, ByVal depth As Long)
    Dim startP As Long
    Dim ok As Long
    Dim id As Long
    Dim idx As Long
    Dim forceHost As Long
    startP=p
    p=p+1
    forceHost=0
    If p<=Len(code) Then
        If Mid(code,p,1)="!" Then
            forceHost=1
            p=p+1
        End If
    End If
    If p>Len(code) Then SyntaxError("@ sonrasi meta id veya # bekleniyor",p):Exit Sub
    If Mid(code,p,1)="#" Then
        p=p+1
        AddMetaInstr(-1,1,forceHost,"@#")
        Exit Sub
    End If
    id=ParseUnsignedLong(code,p,ok)
    If ok=0 Then SyntaxError("@ sonrasi meta id bekleniyor",p):Exit Sub
    If id<0 Or id>255 Then SyntaxError("meta id 0..255 araliginda olmali",startP):Exit Sub
    idx=FindMacroIndex(id)
    If idx<>0 And forceHost=0 Then
        ParseProgram(MacroText(idx),depth+1)
    Else
        AddMetaInstr(id,0,forceHost,Mid(code,startP,p-startP))
    End If
End Sub

Sub AddMetaInstr(ByVal metaId As Long, ByVal dynamicFlag As Long, ByVal forceHost As Long, ByVal txt As String)
    AddInstr(OP_META,0,ADDR_T,0,0,txt)
    IMetaId(InstrCount)=metaId
    IMetaDyn(InstrCount)=dynamicFlag
    IMetaForce(InstrCount)=forceHost
End Sub

