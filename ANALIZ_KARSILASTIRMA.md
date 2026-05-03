# Karsilastirmali Kod Gercekligi Analizi

Klasor: calisilan/uxm31_FULL_FINAL_REAL

## Ozet
- MD/TXT dosya sayisi: 22
- Kod/komut dosya sayisi: 78
- MD/TXT icinden cikarilan referans sayisi: 464
- Tumden kayip referans sayisi: 149
- build_all.bat sonucu: HATA MESAJI URETIYOR (bat cikis kodu 0 donuyor)
- build_final_compiler.bat sonucu: HATA MESAJI URETIYOR (bat cikis kodu 0 donuyor)

## Kritik Bulgular
- VS Code eklentisi mevcut: ide/uxminima-vscode/package.json
- Math ve FP hatti mevcut: math_extensions/runtime/runtime_math_services.bas ve UX-FP V1/Decimal_FP_Sistemi.md
- Final compiler hatti mevcut: final/uxm31_compiler_final.bas ve final/UXM31_FINAL_ARGE_COMPILER.md
- Adresleme iyilestirme notu dokumanda mevcut: yeni tasarim eksiklikler.md icinde D@T, @!, @# tanimlari bulunuyor.
- Referans taramasindaki eksiklerin bir bolumu gercek dosya eksigi degil, dokuman satiri/paragraf parse yan etkisidir.

## Olasi Plan-Gerceklik Ayrismalari
- Eksik referans: - .uxm (kaynak: C:\Users\mete\Downloads\uxminima\calisilan\uxm31_FULL_FINAL_REAL\ux_minima_IDE_vscode.md:222)
- Eksik referans: -o program.obj (kaynak: C:\Users\mete\Downloads\uxminima\calisilan\uxm31_FULL_FINAL_REAL\ux_minima_full v31.md:3080)
- Eksik referans: .asmmap.json (kaynak: C:\Users\mete\Downloads\uxminima\calisilan\uxm31_FULL_FINAL_REAL\tests\UX-MINIMA x64 V3.1 Tasar#U0131m Belgesi.md:6781)
- Eksik referans: .compile.json (kaynak: C:\Users\mete\Downloads\uxminima\calisilan\uxm31_FULL_FINAL_REAL\tests\UX-MINIMA x64 V3.1 Tasar#U0131m Belgesi.md:6778)
- Eksik referans: .expect.json (kaynak: C:\Users\mete\Downloads\uxminima\calisilan\uxm31_FULL_FINAL_REAL\tests\UX-MINIMA x64 V3.1 Tasar#U0131m Belgesi.md:6126)
- Eksik referans: .final_state.json (kaynak: C:\Users\mete\Downloads\uxminima\calisilan\uxm31_FULL_FINAL_REAL\tests\UX-MINIMA x64 V3.1 Tasar#U0131m Belgesi.md:6780)
- Eksik referans: .opt.json (kaynak: C:\Users\mete\Downloads\uxminima\calisilan\uxm31_FULL_FINAL_REAL\ux_minima_full v31.md:3055)
- Eksik referans: .uir.json (kaynak: C:\Users\mete\Downloads\uxminima\calisilan\uxm31_FULL_FINAL_REAL\ux_minima_full v31.md:3054)
- Eksik referans: .uxm (kaynak: C:\Users\mete\Downloads\uxminima\calisilan\uxm31_FULL_FINAL_REAL\tests\UX-MINIMA x64 V3.1 Tasar#U0131m Belgesi.md:791)
- Eksik referans: 0..bas (kaynak: C:\Users\mete\Downloads\uxminima\calisilan\uxm31_FULL_FINAL_REAL\UX-FP V1\Decimal_FP_Sistemi.md:790)
- Eksik referans: 1. .asm (kaynak: C:\Users\mete\Downloads\uxminima\calisilan\uxm31_FULL_FINAL_REAL\ux_minima_full v31.md:4445)
- Eksik referans: 1. .uxm (kaynak: C:\Users\mete\Downloads\uxminima\calisilan\uxm31_FULL_FINAL_REAL\ux_minima_IDE_vscode.md:274)
- Eksik referans: 10400  5d5201839a19b382  ux_minima_IDE_vscode.md (kaynak: C:\Users\mete\Downloads\uxminima\calisilan\uxm31_FULL_FINAL_REAL\FILE_MANIFEST.txt:91)
- Eksik referans: 11057  9e1458d65a94f5c6  ux_minimax_ide_tasarimi_dusuncesi.md (kaynak: C:\Users\mete\Downloads\uxminima\calisilan\uxm31_FULL_FINAL_REAL\FILE_MANIFEST.txt:93)
- Eksik referans: 1207  283d1c01b3ef5bc4  gercek_durum.md (kaynak: C:\Users\mete\Downloads\uxminima\calisilan\uxm31_FULL_FINAL_REAL\FILE_MANIFEST.txt:12)
- Eksik referans: 155210  29abd52e016def3e  ux_minima_full v31.md (kaynak: C:\Users\mete\Downloads\uxminima\calisilan\uxm31_FULL_FINAL_REAL\FILE_MANIFEST.txt:92)
- Eksik referans: 1890  04b6bf87f6e77948  GERCEK_DURUM.md (kaynak: C:\Users\mete\Downloads\uxminima\calisilan\uxm31_FULL_FINAL_REAL\FILE_MANIFEST.txt:1)
- Eksik referans: 2. .uir.json (kaynak: C:\Users\mete\Downloads\uxminima\calisilan\uxm31_FULL_FINAL_REAL\ux_minima_full v31.md:4446)
- Eksik referans: 261  b267c042a054274a  build_final_compiler.bat (kaynak: C:\Users\mete\Downloads\uxminima\calisilan\uxm31_FULL_FINAL_REAL\FILE_MANIFEST.txt:4)
- Eksik referans: 26911  d688e200393b559e  uX_Minima_Kullanim Klavuzu.md (kaynak: C:\Users\mete\Downloads\uxminima\calisilan\uxm31_FULL_FINAL_REAL\FILE_MANIFEST.txt:90)

## Anahtar Kelime Varligi (Kod Gercekligi)

## Derleme Cikti Ozetleri
### build_all.bat
```text
[1/4] Compiler derleniyor...
uxm31_compiler_fb.bas(1) error 42: Variable not declared, Tamam in 'Tamam Mete abi. **Önceki QB64 + FreeBASIC runtime sürümü ilk çalışan iskelet seviyesinde bitti**, ama V3.1’in bütün kurallarını tam taşıyan son sürüm değildi. Şimdi bunu **tamamen FreeBASIC tarafına çekiyorum**. İlk dosya: **FreeBASIC ile yazılmış compiler**. Bu dosya `.uxm` okur, V3.1 kurallarına göre parse eder ve Windows x64 NASM `.asm` üretir.'
uxm31_compiler_fb.bas(3) error 42: Variable not declared, Kod in 'Kod uzun olduğu için önce compiler dosyasını veriyorum. Sonraki mesajda runtime’ı vereceğim.'
uxm31_compiler_fb.bas(5) error 17: Syntax error, found 'Dosya' in '# Dosya 1: `uxm31_compiler_fb.bas`'
uxm31_compiler_fb.bas(7) error 3: Expected End-of-Line, found '`' in '```freebasic'
uxm31_compiler_fb.bas(8) error 146: Only valid in -lang deprecated or fblite or qb, found 'Option' in 'Option Explicit'
uxm31_compiler_fb.bas(341) error 4: Duplicated definition, pos in 'Dim pos As Long'
uxm31_compiler_fb.bas(344) error 317: Function result assignment outside of the function, found '=' in 'pos=InStr(lineText,keyName+"=")'
uxm31_compiler_fb.bas(410) error 4: Duplicated definition, val in 'Dim val As Long'
uxm31_compiler_fb.bas(439) error 317: Function result assignment outside of the function, found '=' in 'val=0'
uxm31_compiler_fb.bas(450) error 99: No matching overloaded function, VAL() in 'hasAddr=ParseAddress(code,p,kind,val)'
uxm31_compiler_fb.bas(450) error 133: Too many errors, exiting
HATA: build_all.bat basarisiz oldu.

```
### build_final_compiler.bat
```text
final\uxm31_compiler_final.bas(1) error 146: Only valid in -lang deprecated or fblite or qb, found 'Option' in 'Option Explicit'
final\uxm31_compiler_final.bas(174) error 4: Duplicated definition, found 'instr' in 'Dim Shared instr(1 To MAX_INSTR) As TInstr'
final\uxm31_compiler_final.bas(198) error 4: Duplicated definition, found 'ptr' in 'Dim Shared ptr As Long'
final\uxm31_compiler_final.bas(199) warning 47(1): Use of reserved global or backend symbol, sp
final\uxm31_compiler_final.bas(340) error 3: Expected End-of-Line, found 'ptr' in 'flags=FLAG_BND:statusByte=0:ptr=0:sp=0:fifoHead=0:fifoTail=0:fifoCount=0'
final\uxm31_compiler_final.bas(497) error 3: Expected End-of-Line, found 'ElseIf' in 'If c="#" Then SkipLine src,p ElseIf c="s" Or c="S" Then ParseStringDef src,p ElseIf c="m" Or c="M" Then ParseMacroDef src,p Else p+=1'
final\uxm31_compiler_final.bas(506) error 3: Expected End-of-Line, found 'ElseIf' in 'If IsSpaceC(Mid(code,p,1)) Then p+=1 ElseIf Mid(code,p,1)="#" Then SkipLine code,p ElseIf Mid(code,p,1)="s" Or Mid(code,p,1)="S" Then ParseStringDef code,p ElseIf Mid(code,p,1)="m" Or Mid(code,p,1)="M" Then ParseMacroDef code,p Else ParseOne code,p,depth'
final\uxm31_compiler_final.bas(591) error 4: Duplicated definition, dir in 'Dim st As Long,cond As Long,dir As Long,dist As Long,ok As Long,c As String'
final\uxm31_compiler_final.bas(594) error 3: Expected End-of-Line, found 'ElseIf' in 'If c=":" Then cond=BR_ALWAYS:p+=1 ElseIf c="0" Then cond=BR_CUR_Z:p+=1 ElseIf c="z" Then cond=BR_Z_SET:p+=1 ElseIf c="Z" Then cond=BR_Z_CLR:p+=1 ElseIf c="c" Then cond=BR_C_SET:p+=1 ElseIf c="C" Then cond=BR_C_CLR:p+=1 ElseIf c="o" Then cond=BR_O_SET:p+=1 ElseIf c="O" Then cond=BR_O_CLR:p+=1 ElseIf c="s" Then cond=BR_S_SET:p+=1 ElseIf c="S" Then cond=BR_S_CLR:p+=1 ElseIf c="+" Or c="-" Then cond=BR_CUR_NZ Else SyntaxError "geçersiz branch tipi",p:Exit Sub'
final\uxm31_compiler_final.bas(595) error 317: Function result assignment outside of the function, found '=' in 'c=Mid(code,p,1):If c="+" Then dir=1 ElseIf c="-" Then dir=-1 Else SyntaxError "branch için + veya - gerekli",p:Exit Sub'
final\uxm31_compiler_final.bas(597) error 58: Type mismatch, at parameter 2 of ADDBRANCH() in 'AddBranch cond,dir,dist,Mid(code,st,p-st),st'
final\uxm31_compiler_final.bas(597) error 133: Too many errors, exiting
HATA: final compiler derlenemedi.

```
