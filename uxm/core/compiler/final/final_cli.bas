' Auto-split by V3 modularization
Sub InitDefaults()
    ReDim needLabel(1 To MAX_INSTR)
    needLabelReady=-1
    inputFile="":asmFile="build\program.asm":uirFile="build\program.uir.json":diagFile="build\program.diag.json":traceFile="build\program.trace.ndjson":optFile="build\program.opt.json"
    ideInFile="":ideOutFile=""
    runMode="compile"
    compileAsm=1:runInterpreter=0:stepMode=0
    writeUIR=1:writeDiagnostics=1:writeTrace=0:writeOptimizer=1:noOptimize=0
    maxSteps=1000000
    cellBits=8:tapeKB=32:stackKB=8:dataKB=24
    workMode=MODE_NORMAL:boundsOn=1:defaultSigned=0:defaultEndian=0
    pragmaSeedEnabled=0:pragmaSeedValue=0
    flags=FLAG_BND:statusByte=0:tapePtr=0:stackPtr=0:fifoHead=0:fifoTail=0:fifoCount=0
    outputText="":stepCounter=0:traceOpen=0
End Sub


Sub PrintHelp()
    Print UXM_VERSION
    Print "Kullanim:"
    Print "  uxm31_compiler_final.exe --input file.uxm --mode compile --asm out.asm --uir out.uir.json --diag out.diag.json --opt out.opt.json"
    Print "  uxm31_compiler_final.exe --input file.uxm --mode interpret --trace out.trace.ndjson"
    Print "  uxm31_compiler_final.exe --input file.uxm --mode step --trace out.trace.ndjson --max-steps 1000"
    Print "  uxm31_compiler_final.exe --ide-in request.json --ide-out response.json"
    Print "ARGE source komutlari:"
    Print "  #arge version"
    Print "  #arge json on"
    Print "  #arge interpreter on"
    Print "  #arge step on"
    Print "  #arge trace on"
    Print "  #arge optimize off"
    Print "  #arge watch tape=0:32"
    Print "  #arge watch data=100:40"
    Print "Dil ekleri: (D@T+N), (D@(T-2)+N), @!N host meta."
End Sub


Sub ParseCLI()
    Dim i As Long, a As String
    If Command(1)="--version" Or Command(1)="-v" Then Print UXM_VERSION: End
    If Command(1)="--help" Or Command(1)="-h" Then PrintHelp(): End
    i=1
    Do While Command(i)<>""
        a=Command(i)
        Select Case LCase(a)
        Case "--input","-i": i+=1: inputFile=Command(i)
        Case "--asm": i+=1: asmFile=Command(i): compileAsm=1
        Case "--uir": i+=1: uirFile=Command(i): writeUIR=1
        Case "--diag": i+=1: diagFile=Command(i): writeDiagnostics=1
        Case "--trace": i+=1: traceFile=Command(i): writeTrace=1
        Case "--opt": i+=1: optFile=Command(i): writeOptimizer=1
        Case "--ide-in": i+=1: ideInFile=Command(i)
        Case "--ide-out": i+=1: ideOutFile=Command(i)
        Case "--max-steps": i+=1: maxSteps=Val(Command(i))
        Case "--no-opt": noOptimize=1
        Case "--mode"
            i+=1: runMode=LCase(Command(i))
            compileAsm=0:runInterpreter=0:stepMode=0
            If runMode="compile" Then compileAsm=1
            If runMode="interpret" Or runMode="run" Then runInterpreter=1:writeTrace=1
            If runMode="step" Then stepMode=1:writeTrace=1
            If runMode="all" Then compileAsm=1:runInterpreter=1:writeTrace=1
        Case Else
            If inputFile="" And Left(a,2)<>"--" Then inputFile=a
        End Select
        i+=1
    Loop
End Sub


Sub ParseIdeJson(ByVal fn As String)
    Dim js As String, cmd As String, v As String
    js=ReadAll(fn)
    cmd=LCase(JsonValue(js,"command"))
    inputFile=JsonValue(js,"source")
    v=JsonValue(js,"asm"):If v<>"" Then asmFile=v
    v=JsonValue(js,"uir"):If v<>"" Then uirFile=v
    v=JsonValue(js,"diag"):If v<>"" Then diagFile=v
    v=JsonValue(js,"trace"):If v<>"" Then traceFile=v
    v=JsonValue(js,"opt"):If v<>"" Then optFile=v
    If cmd="run" Or cmd="interpret" Then compileAsm=0:runInterpreter=1:writeTrace=1
    If cmd="step" Then compileAsm=0:stepMode=1:writeTrace=1
    If cmd="compile" Or cmd="build" Then compileAsm=1:runInterpreter=0
    If cmd="all" Then compileAsm=1:runInterpreter=1:writeTrace=1
End Sub


Function JsonValue(ByVal js As String, ByVal key As String) As String
    Dim p As Long, q As Long, r As Long
    p=InStr(js,Chr(34)+key+Chr(34)): If p=0 Then Return ""
    p=InStr(p,js,":"): If p=0 Then Return ""
    q=InStr(p+1,js,Chr(34)): If q=0 Then Return ""
    r=InStr(q+1,js,Chr(34)): If r=0 Then Return ""
    Return Mid(js,q+1,r-q-1)
End Function


Sub ReadFile(ByVal fn As String)
    If Len(Dir(fn))=0 Then hadError=1:errMsg="HATA: dosya yok: "+fn:Exit Sub
    src=RemoveBOM(ReadAll(fn))
End Sub


Function ReadAll(ByVal fn As String) As String
    Dim ff As Integer, sz As Long, s As String
    If Len(Dir(fn))=0 Then Return ""
    ff=FreeFile: Open fn For Binary Access Read As #ff
    sz=Lof(ff)
    If sz>0 Then s=Space(sz): Get #ff,,s Else s=""
    Close #ff
    Return s
End Function


Sub ParsePragmasAndArge()
    Dim p As Long, st As Long, lineText As String, low As String, v As String
    p=1
    Do While p<=Len(src)
        st=p
        Do While p<=Len(src) And Mid(src,p,1)<>Chr(10): p+=1: Loop
        lineText=TrimAll(Mid(src,st,p-st))
        low=LowerNoSpace(lineText)
        If Left(low,5)="#mode" Then
            If InStr(low,"safe")>0 Then workMode=MODE_SAFE
            If InStr(low,"normal")>0 Then workMode=MODE_NORMAL
            If InStr(low,"wild")>0 Then workMode=MODE_WILD
        ElseIf Left(low,5)="#cell" Then
            If InStr(low,"byte")>0 Then cellBits=8
            If InStr(low,"word")>0 Then cellBits=16
            If InStr(low,"dword")>0 Then cellBits=32
        ElseIf Left(low,7)="#memory" Then
            v=GetKeyValue(low,"tape"):If v<>"" Then tapeKB=ParseKB(v,tapeKB)
            v=GetKeyValue(low,"stack"):If v<>"" Then stackKB=ParseKB(v,stackKB)
            v=GetKeyValue(low,"data"):If v<>"" Then dataKB=ParseKB(v,dataKB)
        ElseIf Left(low,7)="#bounds" Then
            If InStr(low,"off")>0 Then boundsOn=0
            If InStr(low,"on")>0 Then boundsOn=1
        ElseIf Left(low,8)="#compare" Then
            If InStr(low,"signed")>0 Then defaultSigned=1
            If InStr(low,"unsigned")>0 Then defaultSigned=0
        ElseIf Left(low,7)="#endian" Then
            If InStr(low,"big")>0 Then defaultEndian=1
            If InStr(low,"little")>0 Then defaultEndian=0
        ElseIf Left(low,5)="#seed" Then
            pragmaSeedEnabled=1
            pragmaSeedValue=Val(Mid(low,6))
            If pragmaSeedValue=0 Then pragmaSeedValue=1
        ElseIf Left(low,5)="#poly" Or Left(low,9)="#expr-rpn" Then
            ParseArgeMathLine lineText
        ElseIf Left(low,7)="#matrix" Or Left(low,14)="#matrix-signed" Or Left(low,13)="#matrix-fixed" Or Left(low,9)="#identity" Or Left(low,6)="#zeros" Or Left(low,5)="#ones" Then
            ParseArgeMatrixLine lineText
        ElseIf Left(low,6)="#arge" Then
            If InStr(low,"version")>0 Then AddDiag "info","ARGE version: "+UXM_VERSION,st
            If InStr(low,"jsonon")>0 Then writeUIR=1:writeDiagnostics=1
            If InStr(low,"interpreteron")>0 Then runInterpreter=1
            If InStr(low,"stepon")>0 Then stepMode=1:writeTrace=1
            If InStr(low,"traceon")>0 Then writeTrace=1
            If InStr(low,"optimizeoff")>0 Then noOptimize=1
            If InStr(low,"watchtape=")>0 Then watchCount+=1:watchList(watchCount).spaceName="T":watchList(watchCount).startIdx=Val(Mid(low,InStr(low,"watchtape=")+10)):watchList(watchCount).count=32
            If InStr(low,"watchdata=")>0 Then watchCount+=1:watchList(watchCount).spaceName="D":watchList(watchCount).startIdx=Val(Mid(low,InStr(low,"watchdata=")+10)):watchList(watchCount).count=32
            If InStr(low,"watchstack=")>0 Then watchCount+=1:watchList(watchCount).spaceName="S":watchList(watchCount).startIdx=Val(Mid(low,InStr(low,"watchstack=")+11)):watchList(watchCount).count=32
        End If
        p+=1
    Loop
End Sub


Sub ApplyMemory()
    tapeBytes=tapeKB*1024: stackBytes=stackKB*1024: dataBytes=dataKB*1024
    If tapeBytes+stackBytes+dataBytes<>MEM_TOTAL_BYTES Then AddDiag "error","Tape+Stack+Data toplamı 64KB olmalı",1:hadError=1:errMsg="Bellek modeli hatalı":Exit Sub
    If cellBits<>8 And cellBits<>16 And cellBits<>32 Then AddDiag "error","cell byte/word/dword olmalı",1:hadError=1:errMsg="Cell tipi hatalı":Exit Sub
    stackOffset=tapeBytes: dataOffset=tapeBytes+stackBytes
    tapeCells=tapeBytes\CellSize(): stackCells=stackBytes\CellSize(): dataCells=dataBytes\CellSize()
    flags=0
    If boundsOn Then flags Or=FLAG_BND
    If defaultSigned Then flags Or=FLAG_SGN
    If defaultEndian Then flags Or=FLAG_END
    If workMode=MODE_WILD Then flags Or=FLAG_WILD
End Sub


