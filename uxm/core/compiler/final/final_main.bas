' Auto-split by V3 modularization
Sub Main()
    InitDefaults()
    ParseCLI()
    If inputFile="" And ideInFile="" Then PrintHelp(): End
    If ideInFile<>"" Then ParseIdeJson(ideInFile)
    If inputFile="" Then Print "HATA: input eksik": End
    ReadFile inputFile
    If hadError Then Print errMsg: End
    ParsePragmasAndArge()
    If pragmaSeedEnabled<>0 Then Randomize CInt(pragmaSeedValue)
    ApplyMemory()
    FirstPassDefs()
    ParseProgram src,0
    ValidateProgram()
    If noOptimize=0 Then OptimizeProgram(): ValidateProgram()
    If writeDiagnostics Then ExportDiagnostics diagFile
    If writeUIR Then ExportUIR uirFile
    If writeOptimizer Then ExportOpt optFile
    If runInterpreter Or stepMode Then RunProgram()
    If compileAsm Then GenerateASM asmFile
    If ideOutFile<>"" Then ExportIdeResult()
    If diagCount>0 Then Print "Diagnostics: ";diagCount;" adet."
    If hadError Then Print errMsg: End
    If runInterpreter Or stepMode Then Print outputText
    If compileAsm Then Print "ASM: ";asmFile
    If writeUIR Then Print "UIR: ";uirFile
    If writeTrace Then Print "TRACE: ";traceFile
End Sub


