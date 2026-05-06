' Auto-split by V3 modularization
Sub FirstPassDefs()
    Dim p As Long, c As String
    p=1
    Do While p<=Len(src) And hadError=0
        c=Mid(src,p,1)
        If c="#" Then SkipLine src,p Else : If c="s" Or c="S" Then ParseStringDef src,p Else : If c="m" Or c="M" Then ParseMacroDef src,p Else p+=1
    Loop
End Sub


Sub ParseProgram(ByRef code As String, ByVal depth As Long)
    Dim p As Long
    If depth>64 Then SyntaxError "macro expansion derinliği 64'u aştı",1:Exit Sub
    p=1
    Do While p<=Len(code) And hadError=0
        If IsSpaceC(Mid(code,p,1)) Then p+=1 Else : If Mid(code,p,1)="#" Then SkipLine code,p Else : If Mid(code,p,1)="s" Or Mid(code,p,1)="S" Then ParseStringDef code,p Else : If Mid(code,p,1)="m" Or Mid(code,p,1)="M" Then ParseMacroDef code,p Else ParseOne code,p,depth
    Loop
End Sub


Sub ParseOne(ByRef code As String, ByRef p As Long, ByVal depth As Long)
    Dim c As String, st As Long, ak As Long, av As Long, av2 As Long, amt As Long, ok As Long, hasAddr As Long, c2 As String, p2 As Long, amt2 As Long, ok2 As Long
    st=p
    c=Mid(code,p,1)
    If c="p" Or c="P" Then
        ParsePrintString code,p
        Exit Sub
    End If
    If c="@" Then
        ParseMeta code,p,depth
        Exit Sub
    End If
    If c=":" Then
        ParseBranch code,p
        Exit Sub
    End If
    If IsCmdC(c)=0 Then
        SyntaxError "geçersiz komut: "+c,p
        Exit Sub
    End If
    p+=1
    ak=ADDR_T
    av=0
    av2=0
    amt=1
    If c="+" Or c="-" Then
        If p<=Len(code) Then
            If Mid(code,p,1)="k" Or Mid(code,p,1)="K" Then
                p+=1
                amt=ParseUnsigned(code,p,ok)
                If ok=0 Then
                    SyntaxError "k sonrası sayı bekleniyor",p
                    Exit Sub
                End If
            End If
        End If
    End If
    hasAddr=ParseAddress(code,p,ak,av,av2)
    Select Case c
    Case ">"
        If hasAddr Then
            SyntaxError "> adresleme alamaz",st
            Exit Sub
        End If
        AddInstr OP_RIGHT,amt,ADDR_T,0,0,Mid(code,st,p-st),st
    Case "<"
        If hasAddr Then
            SyntaxError "< adresleme alamaz",st
            Exit Sub
        End If
        AddInstr OP_LEFT,amt,ADDR_T,0,0,Mid(code,st,p-st),st
    Case "+"
        AddInstr OP_INC,amt,ak,av,av2,Mid(code,st,p-st),st
    Case "-"
        AddInstr OP_DEC,amt,ak,av,av2,Mid(code,st,p-st),st
    Case "0"
        AddInstr OP_CLEAR,0,ak,av,av2,Mid(code,st,p-st),st
        If p<=Len(code) Then
            If Mid(code,p,1)="+" Or Mid(code,p,1)="-" Then
                c2=Mid(code,p,1)
                p2=p+1
                If p2<=Len(code) Then
                    If Mid(code,p2,1)="k" Or Mid(code,p2,1)="K" Then
                        p2+=1
                        amt2=ParseUnsigned(code,p2,ok2)
                        If ok2=0 Then
                            SyntaxError "0+kN için N bekleniyor",p2
                            Exit Sub
                        End If
                        If c2="+" Then
                            AddInstr OP_INC,amt2,ak,av,av2,"+k"+Str(amt2)+" inherit",st
                        Else
                            AddInstr OP_DEC,amt2,ak,av,av2,"-k"+Str(amt2)+" inherit",st
                        End If
                        p=p2
                    End If
                End If
            End If
        End If
    Case "."
        AddInstr OP_PUTC,0,ak,av,av2,Mid(code,st,p-st),st
    Case ","
        AddInstr OP_GETC,0,ak,av,av2,Mid(code,st,p-st),st
    Case "["
        If hasAddr Then
            SyntaxError "[ adresleme alamaz",st
            Exit Sub
        End If
        AddInstr OP_LOOP_BEG,0,ADDR_T,0,0,Mid(code,st,p-st),st
    Case "]"
        If hasAddr Then
            SyntaxError "] adresleme alamaz",st
            Exit Sub
        End If
        AddInstr OP_LOOP_END,0,ADDR_T,0,0,Mid(code,st,p-st),st
    Case "$"
        AddInstr OP_PUSH,0,ak,av,av2,Mid(code,st,p-st),st
    Case "%"
        AddInstr OP_POP,0,ak,av,av2,Mid(code,st,p-st),st
    Case "?"
        AddInstr OP_EQ,0,ak,av,av2,Mid(code,st,p-st),st
    Case "!"
        AddInstr OP_GT,0,ak,av,av2,Mid(code,st,p-st),st
    Case ";"
        AddInstr OP_LT,0,ak,av,av2,Mid(code,st,p-st),st
    Case "&"
        AddInstr OP_AND,0,ak,av,av2,Mid(code,st,p-st),st
    Case "|"
        AddInstr OP_OR,0,ak,av,av2,Mid(code,st,p-st),st
    Case "^"
        AddInstr OP_XOR,0,ak,av,av2,Mid(code,st,p-st),st
    Case "~"
        AddInstr OP_NOT,0,ak,av,av2,Mid(code,st,p-st),st
    Case "{"
        AddInstr OP_SHL,0,ak,av,av2,Mid(code,st,p-st),st
    Case "}"
        AddInstr OP_SHR,0,ak,av,av2,Mid(code,st,p-st),st
    Case "e","E"
        AddInstr OP_STATUS,0,ak,av,av2,Mid(code,st,p-st),st
    End Select
End Sub


Sub ParseStringDef(ByRef code As String, ByRef p As Long)
    Dim ok As Long,id As Long,stCell As Long,txt As String, st As Long
    st=p
    p+=1
    id=ParseUnsigned(code,p,ok)
    If ok=0 Then
        SyntaxError "sN için N bekleniyor",p
        Exit Sub
    End If
    If p>Len(code) Or Mid(code,p,1)<>"=" Then
        SyntaxError "sN için = bekleniyor",p
        Exit Sub
    End If
    p+=1
    stCell=ParseUnsigned(code,p,ok)
    If ok=0 Then
        SyntaxError "string başlangıç hücresi bekleniyor",p
        Exit Sub
    End If
    If p>Len(code) Or Mid(code,p,1)<>"," Then
        SyntaxError "sN için virgül bekleniyor",p
        Exit Sub
    End If
    p+=1
    txt=ParseBraced(code,p,ok)
    If ok=0 Then
        SyntaxError "sN için {metin} bekleniyor",p
        Exit Sub
    End If
    AddString id,stCell,txt,LineOfPos(st)
End Sub


Sub ParseMacroDef(ByRef code As String, ByRef p As Long)
    Dim ok As Long,id As Long,txt As String, st As Long
    st=p
    p+=1
    id=ParseUnsigned(code,p,ok)
    If ok=0 Then
        SyntaxError "mN için N bekleniyor",p
        Exit Sub
    End If
    If id<128 Or id>255 Then
        SyntaxError "mN id 128..255 olmalı",st
        Exit Sub
    End If
    If p>Len(code) Or Mid(code,p,1)<>"=" Then
        SyntaxError "mN için = bekleniyor",p
        Exit Sub
    End If
    p+=1
    txt=ParseBraced(code,p,ok)
    If ok=0 Then
        SyntaxError "mN için {kod} bekleniyor",p
        Exit Sub
    End If
    AddMacro id,txt,LineOfPos(st)
End Sub


Sub ParsePrintString(ByRef code As String, ByRef p As Long)
    Dim ok As Long,id As Long,idx As Long,st As Long
    st=p
    p+=1
    id=ParseUnsigned(code,p,ok)
    If ok=0 Then
        SyntaxError "pN için N bekleniyor",p
        Exit Sub
    End If
    idx=FindString(id)
    If idx=0 Then
        SyntaxError "tanımsız string p"+Str(id),st
        Exit Sub
    End If
    AddInstr OP_PRINT_STRING,id,ADDR_T,0,0,Mid(code,st,p-st),st
End Sub


Sub ParseMeta(ByRef code As String, ByRef p As Long, ByVal depth As Long)
    Dim ok As Long,id As Long,idx As Long,st As Long,forceHost As Long
    st=p
    p+=1
    forceHost=0
    If p<=Len(code) And Mid(code,p,1)="!" Then
        forceHost=1
        p+=1
    End If
    If p>Len(code) Then
        SyntaxError "@ sonrası id bekleniyor",p
        Exit Sub
    End If
    If Mid(code,p,1)="#" Then
        p+=1
        AddMeta -1,1,forceHost,Mid(code,st,p-st),st
        Exit Sub
    End If
    id=ParseUnsigned(code,p,ok)
    If ok=0 Then
        SyntaxError "@ sonrası sayı bekleniyor",p
        Exit Sub
    End If
    If id<0 Or id>255 Then
        SyntaxError "meta id 0..255 olmalı",st
        Exit Sub
    End If
    If forceHost=0 Then
        idx=FindMacro(id)
        If idx<>0 Then
            ParseProgram macroDef(idx).txt,depth+1
            Exit Sub
        End If
    End If
    AddMeta id,0,forceHost,Mid(code,st,p-st),st
End Sub


Sub ParseBranch(ByRef code As String, ByRef p As Long)
    Dim st As Long,cond As Long,brDir As Long,dist As Long,ok As Long,c As String
    st=p
    p+=1
    If p>Len(code) Then
        SyntaxError ": sonrası branch bekleniyor",p
        Exit Sub
    End If
    c=Mid(code,p,1)
    Select Case c
    Case ":"
        cond=BR_ALWAYS
        p+=1
    Case "0"
        cond=BR_CUR_Z
        p+=1
    Case "z"
        cond=BR_Z_SET
        p+=1
    Case "Z"
        cond=BR_Z_CLR
        p+=1
    Case "c"
        cond=BR_C_SET
        p+=1
    Case "C"
        cond=BR_C_CLR
        p+=1
    Case "o"
        cond=BR_O_SET
        p+=1
    Case "O"
        cond=BR_O_CLR
        p+=1
    Case "s"
        cond=BR_S_SET
        p+=1
    Case "S"
        cond=BR_S_CLR
        p+=1
    Case "+", "-"
        cond=BR_CUR_NZ
    Case Else
        SyntaxError "geçersiz branch tipi",p
        Exit Sub
    End Select

    c=Mid(code,p,1)
    Select Case c
    Case "+"
        brDir=1
    Case "-"
        brDir=-1
    Case Else
        SyntaxError "branch için + veya - gerekli",p
        Exit Sub
    End Select
    p+=1
    dist=ParseUnsigned(code,p,ok)
    If ok=0 Or dist<=0 Then
        SyntaxError "branch mesafesi gerekli",p
        Exit Sub
    End If
    AddBranch cond,brDir,dist,Mid(code,st,p-st),st
End Sub


Sub SkipLine(ByRef code As String, ByRef p As Long)
    Do While p<=Len(code)
        If Mid(code,p,1)=Chr(10) Then
            p+=1
            Exit Sub
        Else
            p+=1
        End If
    Loop
End Sub


Function ParseUnsigned(ByRef code As String, ByRef p As Long, ByRef ok As Long) As Long
    Dim s As String=""
    ok=0
    Do While p<=Len(code) And IsDigitC(Mid(code,p,1))
        s+=Mid(code,p,1)
        p+=1
    Loop
    If s="" Then
        Return 0
    End If
    ok=1
    Return Val(s)
End Function

Function ParseBraced(ByRef code As String, ByRef p As Long, ByRef ok As Long) As String
    Dim r As String=""
    Dim c As String
    Dim n As String
    ok=0
    If p>Len(code) Or Mid(code,p,1)<>"{" Then Return ""
    p+=1
    Do While p<=Len(code)
        c=Mid(code,p,1)
        If c="\" And p+1<=Len(code) Then
            n=Mid(code,p+1,1)
            Select Case n
            Case "n"
                r+=Chr(10)
            Case "r"
                r+=Chr(13)
            Case "t"
                r+=Chr(9)
            Case Else
                r+=n
            End Select
            p+=2
        ElseIf c="}" Then
            p+=1
            ok=1
            Return r
        Else
            r+=c
            p+=1
        End If
    Loop
    Return r
End Function

Function ParseAddress(ByRef code As String, ByRef p As Long, ByRef ak As Long, ByRef av As Long, ByRef av2 As Long) As Long
    Dim st As Long,body As String,bal As Long,c As String
    If p>Len(code) Or Mid(code,p,1)<>"(" Then Return 0
    st=p
    Do While p<=Len(code)
        c=Mid(code,p,1)
        If IsSpaceC(c) Then
            SyntaxError "adresleme içinde boşluk yasak",p
            Return 0
        End If
        If c="(" Then bal+=1
        If c=")" Then
            bal-=1
            If bal=0 Then Exit Do
        End If
        p+=1
    Loop
    If p>Len(code) Then
        SyntaxError "adres parantezi kapanmadı",st
        Return 0
    End If
    body=Mid(code,st+1,p-st-1)
    p+=1
    If ParseAddrBody(body,ak,av,av2)=0 Then
        SyntaxError "geçersiz adres: "+body,st
        Return 0
    End If
    Return 1
End Function

Function ParseAddrBody(ByVal body As String, ByRef ak As Long, ByRef av As Long, ByRef av2 As Long) As Long
    Dim b As String,closePos As Long,inner As String,rest As String,rel As Long,off As Long
    b=UCase(TrimAll(body)):av=0:av2=0
    If b="T" Then ak=ADDR_T:Return 1
    If Left(b,2)="T+" Then ak=ADDR_T_REL:av=Val(Mid(b,3)):Return 1
    If Left(b,2)="T-" Then ak=ADDR_T_REL:av=-Val(Mid(b,3)):Return 1
    If Left(b,2)="T:" Then ak=ADDR_T_ABS:av=Val(Mid(b,3)):Return 1
    If Left(b,2)="D:" Then ak=ADDR_D_ABS:av=Val(Mid(b,3)):Return 1
    If Left(b,2)="S:" Then ak=ADDR_S_ABS:av=Val(Mid(b,3)):Return 1
    If b="SP" Then ak=ADDR_SP:Return 1
    If b="P" Then ak=ADDR_P:Return 1
    If b="E" Then ak=ADDR_E:Return 1
    If b="F" Then ak=ADDR_F:Return 1
    If b="*T" Then ak=ADDR_IND_T:Return 1
    If Left(b,3)="D@T" Then
        ak=ADDR_D_AT_T_REL
        If Len(b)>3 Then
            If Mid(b,4,1)="+" Then
                av2=Val(Mid(b,5))
            ElseIf Mid(b,4,1)="-" Then
                av2=-Val(Mid(b,5))
            Else
                Return 0
            End If
        End If
        Return 1
    End If
    If Left(b,4)="D@(" Then
        closePos=InStr(4,b,")")
        If closePos=0 Then Return 0
        inner=Mid(b,4,closePos-4)
        rest=Mid(b,closePos+1)
        If ParseTapeRelInside(inner,rel)=0 Then Return 0
        off=0
        If rest<>"" Then
            If Left(rest,1)="+" Then
                off=Val(Mid(rest,2))
            ElseIf Left(rest,1)="-" Then
                off=-Val(Mid(rest,2))
            Else
                Return 0
            End If
        End If
        ak=ADDR_D_AT_TBASE_REL
        av=rel
        av2=off
        Return 1
    End If
    Return 0
End Function

Function ParseTapeRelInside(ByVal s As String, ByRef rel As Long) As Long
    s=UCase(TrimAll(s))
    rel=0
    If s="T" Then Return 1
    If Left(s,2)="T+" Then
        rel=Val(Mid(s,3))
        Return 1
    End If
    If Left(s,2)="T-" Then
        rel=-Val(Mid(s,3))
        Return 1
    End If
    Return 0
End Function

Function FindString(ByVal id As Long) As Long
    Dim i As Long
    For i=1 To strCount
        If strDef(i).id=id Then Return i
    Next
    Return 0
End Function

Function FindMacro(ByVal id As Long) As Long
    Dim i As Long
    For i=1 To macroCount
        If macroDef(i).id=id Then Return i
    Next
    Return 0
End Function

Function IsDigitC(ByVal c As String) As Long
    Return IIf(c>="0" And c<="9",1,0)
End Function

Function IsSpaceC(ByVal c As String) As Long
    Return IIf(c=" " Or c=Chr(9) Or c=Chr(10) Or c=Chr(13),1,0)
End Function

Function IsCmdC(ByVal c As String) As Long
    Return IIf(InStr("><+-0.,[]$%?!;&|^~{}eE",c)>0,1,0)
End Function

Function RemoveBOM(ByVal s As String) As String
    If Len(s)>=3 Then
        If (Asc(Mid(s,1,1)) And &HFF)=&HEF And (Asc(Mid(s,2,1)) And &HFF)=&HBB And (Asc(Mid(s,3,1)) And &HFF)=&HBF Then
            Return Mid(s,4)
        End If
    End If
    Return s
End Function

Function TrimAll(ByVal s As String) As String
    Return LTrim(RTrim(s))
End Function

Function LowerNoSpace(ByVal s As String) As String
    Dim r As String=""
    Dim i As Long
    Dim c As String
    For i=1 To Len(s)
        c=LCase(Mid(s,i,1))
        If c<>" " And c<>Chr(9) And c<>Chr(13) Then r+=c
    Next
    Return r
End Function

Function GetKeyValue(ByVal lineText As String, ByVal key As String) As String
    Dim p As Long
    Dim r As String
    p=InStr(lineText,key+"=")
    If p=0 Then Return ""
    p+=Len(key)+1
    r=""
    Do While p<=Len(lineText) And Mid(lineText,p,1)<>","
        r+=Mid(lineText,p,1)
        p+=1
    Loop
    Return r
End Function

Function ParseKB(ByVal s As String, ByVal def As Long) As Long
    Dim n As Long
    n=Val(s)
    If n<=0 Then
        Return def
    End If
    Return n
End Function


