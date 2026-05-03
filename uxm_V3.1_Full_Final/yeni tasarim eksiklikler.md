Haklısın Mete abi. Bu adresleme **normal modda olmalı**:

```text
(D@T)
(D@T+N)
(D@T-N)
(D@(T-2)+N)
(D@(T-1)+N)
(D@(T)+N)
```

Bunlar wild mode işi değil. Wild sadece `@127` gibi **runtime memory layout değiştirme** işlerinde kalmalı.

Bir de önemli düzeltme: FP işlemlerini macro olarak kullanacaksak, macro içinden host meta servisi çağırmak için yeni bir zorunlu sözdizimi gerekiyor. Çünkü `m210={@210}` yazarsak compiler `@210` görünce yine `m210` macro’sunu açmaya çalışır ve sonsuz macro expansion olur. Bu yüzden şu kuralı ekliyoruz:

```text
@210     kullanıcı macro varsa macro çağırır, yoksa host meta çağırır
@!210    zorla host meta servisi çağırır
@#       aktif hücredeki değeri dinamik meta kabul eder
```

Aşağıdaki kodları V3.1 Full yapısına ekle.

---

# 1. Yeni adresleme sabitleri

`ADDR_...` sabitlerinin sonuna ekle:

```freebasic
Const ADDR_D_AT_T As Long=11
Const ADDR_D_AT_T_REL As Long=12
Const ADDR_D_AT_TBASE_REL As Long=13
```

`TInstr` içine ikinci adres değeri ekle:

```freebasic
Type TInstr
    op As Long
    amount As Long
    addrKind As Long
    addrVal As Long
    addrVal2 As Long
    text As String
    metaId As Long
    metaDyn As Long
    metaForceHost As Long
    brCond As Long
    brDir As Long
    brDist As Long
    brTarget As Long
    mate As Long
End Type
```

Bunun anlamı:

```text
addrVal  = base tape offset
addrVal2 = data offset
```

Örnek:

```text
(D@(T-2)+8)
```

şu olur:

```text
addrKind = ADDR_D_AT_TBASE_REL
addrVal  = -2
addrVal2 = 8
```

---

# 2. `AddInstr` fonksiyonunu genişlet

Eski:

```freebasic
Declare Sub AddInstr(ByVal op As Long, ByVal amount As Long, ByVal addrKind As Long, ByVal addrVal As Long, ByVal txt As String)
```

Yeni:

```freebasic
Declare Sub AddInstr(ByVal op As Long, ByVal amount As Long, ByVal addrKind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long, ByVal txt As String)
```

Gövdedeki yeni hali:

```freebasic
Sub AddInstr(ByVal op As Long, ByVal amount As Long, ByVal addrKind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long, ByVal txt As String)
    If InstrCount>=MAX_INSTR Then SyntaxError("instruction limiti doldu",1):Exit Sub
    InstrCount=InstrCount+1
    Instr(InstrCount).op=op
    Instr(InstrCount).amount=amount
    Instr(InstrCount).addrKind=addrKind
    Instr(InstrCount).addrVal=addrVal
    Instr(InstrCount).addrVal2=addrVal2
    Instr(InstrCount).text=txt
End Sub
```

Eski `AddInstr(...)` çağrılarında `addrVal2` için `0` geç:

```freebasic
AddInstr(OP_INC,amt,kind,val,0,Mid(code,startP,p-startP))
```

---

# 3. `ParseAddress` imzasını genişlet

Eski:

```freebasic
Declare Function ParseAddress(ByRef code As String, ByRef p As Long, ByRef kind As Long, ByRef val As Long) As Long
Declare Function ParseAddressBody(ByVal body As String, ByRef kind As Long, ByRef val As Long) As Long
```

Yeni:

```freebasic
Declare Function ParseAddress(ByRef code As String, ByRef p As Long, ByRef kind As Long, ByRef val As Long, ByRef val2 As Long) As Long
Declare Function ParseAddressBody(ByVal body As String, ByRef kind As Long, ByRef val As Long, ByRef val2 As Long) As Long
Declare Function ParseSignedOffsetAfter(ByVal s As String, ByVal startPos As Long, ByRef outVal As Long) As Long
Declare Function ParseTapeRelInside(ByVal s As String, ByRef baseRel As Long) As Long
```

`ParseOneInstruction` içinde:

```freebasic
Dim val2 As Long
...
kind=ADDR_T
val=0
val2=0
...
hasAddr=ParseAddress(code,p,kind,val,val2)
```

ve bütün `AddInstr` çağrılarında:

```freebasic
AddInstr(OP_INC,amt,kind,val,val2,Mid(code,startP,p-startP))
```

---

# 4. Yeni `ParseAddress` ve `ParseAddressBody`

Bunu mevcut `ParseAddress` / `ParseAddressBody` yerine koy:

```freebasic
Function ParseAddress(ByRef code As String, ByRef p As Long, ByRef kind As Long, ByRef val As Long, ByRef val2 As Long) As Long
    Dim startP As Long
    Dim body As String
    Dim bal As Long
    Dim c As String
    If p>Len(code) Then Return 0
    If Mid(code,p,1)<>"(" Then Return 0
    startP=p
    bal=0
    Do While p<=Len(code)
        c=Mid(code,p,1)
        If IsSpaceChar(c) Then
            SyntaxError("adresleme ifadesi icinde bosluk yasak",p)
            Return 0
        End If
        If c="(" Then bal=bal+1
        If c=")" Then
            bal=bal-1
            If bal=0 Then Exit Do
        End If
        p=p+1
    Loop
    If p>Len(code) Or Mid(code,p,1)<>")" Then SyntaxError("adresleme parantezi kapanmadi",startP):Return 0
    body=Mid(code,startP+1,p-startP-1)
    p=p+1
    If ParseAddressBody(body,kind,val,val2)=0 Then
        SyntaxError("gecersiz adresleme: ("+body+")",startP)
        Return 0
    End If
    Return 1
End Function
Function ParseAddressBody(ByVal body As String, ByRef kind As Long, ByRef val As Long, ByRef val2 As Long) As Long
    Dim b As String
    Dim pos As Long
    Dim inner As String
    Dim rest As String
    Dim rel As Long
    Dim off As Long
    b=UCase(TrimAll(body))
    val=0
    val2=0
    If b="T" Then kind=ADDR_T:Return 1
    If b="SP" Then kind=ADDR_SP:Return 1
    If b="P" Then kind=ADDR_P:Return 1
    If b="E" Then kind=ADDR_E:Return 1
    If b="F" Then kind=ADDR_F:Return 1
    If b="*T" Then kind=ADDR_IND_T:Return 1
    If Left(b,2)="T+" Then kind=ADDR_T_REL:val=Val(Mid(b,3)):Return 1
    If Left(b,2)="T-" Then kind=ADDR_T_REL:val=-Val(Mid(b,3)):Return 1
    If Left(b,2)="T:" Then kind=ADDR_T_ABS:val=Val(Mid(b,3)):Return 1
    If Left(b,2)="D:" Then kind=ADDR_D_ABS:val=Val(Mid(b,3)):Return 1
    If Left(b,2)="S:" Then kind=ADDR_S_ABS:val=Val(Mid(b,3)):Return 1
    If Left(b,4)="*(T+" And Right(b,1)=")" Then kind=ADDR_IND_T_REL:val=Val(Mid(b,5,Len(b)-5)):Return 1
    If Left(b,4)="*(T-" And Right(b,1)=")" Then kind=ADDR_IND_T_REL:val=-Val(Mid(b,5,Len(b)-5)):Return 1
    If Left(b,3)="D@T" Then
        kind=ADDR_D_AT_T_REL
        val=0
        If Len(b)>3 Then
            If Mid(b,4,1)="+" Then val2=Val(Mid(b,5)):Return 1
            If Mid(b,4,1)="-" Then val2=-Val(Mid(b,5)):Return 1
            Return 0
        End If
        val2=0
        Return 1
    End If
    If Left(b,4)="D@(" Then
        pos=InStr(4,b,")")
        If pos=0 Then Return 0
        inner=Mid(b,4,pos-4)
        rest=Mid(b,pos+1)
        If ParseTapeRelInside(inner,rel)=0 Then Return 0
        off=0
        If rest<>"" Then
            If Left(rest,1)="+" Then off=Val(Mid(rest,2))
            If Left(rest,1)="-" Then off=-Val(Mid(rest,2))
            If Left(rest,1)<>"+" And Left(rest,1)<>"-" Then Return 0
        End If
        kind=ADDR_D_AT_TBASE_REL
        val=rel
        val2=off
        Return 1
    End If
    Return 0
End Function
Function ParseTapeRelInside(ByVal s As String, ByRef baseRel As Long) As Long
    s=UCase(TrimAll(s))
    baseRel=0
    If s="T" Then baseRel=0:Return 1
    If Left(s,2)="T+" Then baseRel=Val(Mid(s,3)):Return 1
    If Left(s,2)="T-" Then baseRel=-Val(Mid(s,3)):Return 1
    Return 0
End Function
```

Artık şu yazımlar geçerli:

```text
0(D@T)+k70
0(D@T+8)+k12
0(D@(T-2)+0)+k70
0(D@(T-2)+1)+k16
0(D@(T-1)+8)+k34
.(D@(T)+8)
```

---

# 5. `@!N` host meta çağrısı

`ParseMeta` fonksiyonunu şu mantıkla değiştir:

```freebasic
Sub ParseMeta(ByRef code As String, ByRef p As Long, ByVal depth As Long)
    Dim startP As Long
    Dim ok As Long
    Dim id As Long
    Dim idx As Long
    Dim forceHost As Long
    startP=p
    p=p+1
    forceHost=0
    If p>Len(code) Then SyntaxError("@ sonrasi meta id veya # bekleniyor",p):Exit Sub
    If Mid(code,p,1)="!" Then
        forceHost=1
        p=p+1
    End If
    If p>Len(code) Then SyntaxError("@! sonrasi host meta id bekleniyor",p):Exit Sub
    If Mid(code,p,1)="#" Then
        p=p+1
        AddMetaInstr(-1,1,0,"@#")
        Exit Sub
    End If
    id=ParseUnsignedLong(code,p,ok)
    If ok=0 Then SyntaxError("@ sonrasi meta id bekleniyor",p):Exit Sub
    If id<0 Or id>255 Then SyntaxError("meta id 0..255 araliginda olmali",startP):Exit Sub
    If forceHost=0 Then
        idx=FindMacroIndex(id)
        If idx<>0 Then
            ParseProgram(MacroDef(idx).txt,depth+1)
            Exit Sub
        End If
    End If
    AddMetaInstr(id,0,forceHost,Mid(code,startP,p-startP))
End Sub
```

`AddMetaInstr` imzası:

```freebasic
Declare Sub AddMetaInstr(ByVal metaId As Long, ByVal dynamicFlag As Long, ByVal forceHost As Long, ByVal txt As String)
```

Gövde:

```freebasic
Sub AddMetaInstr(ByVal metaId As Long, ByVal dynamicFlag As Long, ByVal forceHost As Long, ByVal txt As String)
    AddInstr(OP_META,0,ADDR_T,0,0,txt)
    Instr(InstrCount).metaId=metaId
    Instr(InstrCount).metaDyn=dynamicFlag
    Instr(InstrCount).metaForceHost=forceHost
End Sub
```

---

# 6. Native emitter içine dinamik data adresleme ekle

`EmitAddrPtr` içine şu case’leri ekle:

```freebasic
Case ADDR_D_AT_T_REL
    EmitAddrLoad(ADDR_T,0,"rax")
    If addrVal2>=0 Then
        If addrVal2<>0 Then EmitLine("    add rax, "+LTrim(Str(addrVal2)))
    Else
        EmitLine("    sub rax, "+LTrim(Str(Abs(addrVal2))))
    End If
    If BoundsOn Then
        EmitLine("    cmp rax, DATA_CELLS")
        EmitLine("    jae __ux_err_data")
    End If
    Select Case CellBits
    Case 8
        EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax]")
    Case 16
        EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax*2]")
    Case 32
        EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax*4]")
    End Select
Case ADDR_D_AT_TBASE_REL
    EmitAddrLoad(ADDR_T_REL,addrVal,"rax")
    If addrVal2>=0 Then
        If addrVal2<>0 Then EmitLine("    add rax, "+LTrim(Str(addrVal2)))
    Else
        EmitLine("    sub rax, "+LTrim(Str(Abs(addrVal2))))
    End If
    If BoundsOn Then
        EmitLine("    cmp rax, DATA_CELLS")
        EmitLine("    jae __ux_err_data")
    End If
    Select Case CellBits
    Case 8
        EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax]")
    Case 16
        EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax*2]")
    Case 32
        EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax*4]")
    End Select
```

Böylece native ASM tarafında:

```text
(D@(T-2)+8)
```

şuna dönüşür:

```text
rax = Tape[Ptr-2]
rax = rax + 8
r11 = ux_mem + DATA_OFFSET + rax * cellsize
```

---

# 7. Full tool interpreter içine aynı adreslemeyi ekle

`ResolveIndex` fonksiyonuna ekle:

```freebasic
Case ADDR_D_AT_T_REL
    spaceName="D"
    idx=Tape(Ptr)+av2
Case ADDR_D_AT_TBASE_REL
    spaceName="D"
    idx=Tape(Ptr+av)+av2
```

Bunun için `ResolveIndex` imzası da `av2` almalı:

```freebasic
Declare Function ResolveIndex(ByVal ak As Long, ByVal av As Long, ByVal av2 As Long, ByRef spaceName As String, ByRef ok As Long) As Long
```

Yeni gövde mantığı:

```freebasic
Function ResolveIndex(ByVal ak As Long, ByVal av As Long, ByVal av2 As Long, ByRef spaceName As String, ByRef ok As Long) As Long
    Dim idx As Long
    ok=1
    Select Case ak
    Case ADDR_T
        spaceName="T":idx=Ptr
    Case ADDR_T_REL
        spaceName="T":idx=Ptr+av
    Case ADDR_T_ABS
        spaceName="T":idx=av
    Case ADDR_D_ABS
        spaceName="D":idx=av
    Case ADDR_S_ABS
        spaceName="S":idx=av
    Case ADDR_SP
        spaceName="S":idx=SP-1
    Case ADDR_P
        spaceName="P":idx=0
    Case ADDR_E
        spaceName="E":idx=0
    Case ADDR_F
        spaceName="F":idx=0
    Case ADDR_IND_T
        spaceName="T":idx=Tape(Ptr)
    Case ADDR_IND_T_REL
        spaceName="T":idx=Tape(Ptr+av)
    Case ADDR_D_AT_T_REL
        spaceName="D":idx=Tape(Ptr)+av2
    Case ADDR_D_AT_TBASE_REL
        spaceName="D":idx=Tape(Ptr+av)+av2
    Case Else
        ok=0:idx=0
    End Select
    If BoundsOn Then
        If spaceName="T" And (idx<0 Or idx>=TapeCells) Then ok=0:SetStatus STATUS_PTR_BOUNDS
        If spaceName="D" And (idx<0 Or idx>=DataCells) Then ok=0:SetStatus STATUS_DATA_BOUNDS
        If spaceName="S" And (idx<0 Or idx>=StackCells) Then ok=0:SetStatus STATUS_STACK_UNDERFLOW
    End If
    Return idx
End Function
```

`ReadAddr` ve `WriteAddr` çağrılarını da şöyle değiştir:

```freebasic
idx=ResolveIndex(ak,av,av2,spn,ok)
```

---

# 8. UX-FP V1 macro kütüphanesi

Bunu ayrı dosya yap:

```text
ux_fp_v1.uxm
```

İlk sürümde temel işlemler macro arayüzü olarak tanımlanıyor. Basit header işlemleri saf UXM ile yapılır. Ağır işlemler `@!N` ile host hızlandırıcıya gider. Böylece programcı hep macro çağırır; istersek sonra `m210` içeriğini saf UXM ADD algoritmasına çevirebiliriz.

```text
# UX-FP V1 decimal floating point macro library
# Gerekli adresleme:
#   (D@T)
#   (D@T+N)
#   (D@(T-2)+N)
#   (D@(T-1)+N)
#   (D@(T)+N)
# Genel FP frame:
#   T-2 = result/destination base
#   T-1 = A/source base veya integer input
#   T   = B/source base veya parametre
#   T+1 = status/result

# m200 FP_INIT16
# T-2 = base
m200={
0(D@(T-2)+0)+k70
0(D@(T-2)+1)+k16
0(D@(T-2)+2)
0(D@(T-2)+3)
0(D@(T-2)+4)
0(D@(T-2)+5)+k1
0(D@(T-2)+6)
0(D@(T-2)+7)
0(D@(T-2)+8)
}

# m201 FP_INIT32
# T-2 = base
m201={
0(D@(T-2)+0)+k70
0(D@(T-2)+1)+k32
0(D@(T-2)+2)
0(D@(T-2)+3)
0(D@(T-2)+4)
0(D@(T-2)+5)+k1
0(D@(T-2)+6)
0(D@(T-2)+7)
0(D@(T-2)+8)
}

# m202 FP_ZERO / FP_CLEAR_VALUE
# T-2 = base
# Header korunur, sayı 0 yapılır.
m202={
0(D@(T-2)+2)
0(D@(T-2)+3)
0(D@(T-2)+4)
0(D@(T-2)+5)+k1
0(D@(T-2)+6)
0(D@(T-2)+8)
}

# m203 FP_COPY
# T-2 = destination base
# T-1 = source base
# T   = cell count, FP16 için 24, FP32 için 40
# Data block copy host servis ile yapılır.
m203={
@!98
}

# m204 FP_NORMALIZE
# T-2 = base
m204={
@!204
}

# m205 FP_SET_SIGN
# T-2 = base
# T-1 = sign, 0 pozitif, 1 negatif
m205={
0(D@(T-2)+2)
+(D@(T-2)+2)
}

# m206 FP_SET_EXP
# T-2 = base
# T-1 = exponent sign
# T   = exponent abs
m206={
0(D@(T-2)+3)
+(D@(T-2)+3)
0(D@(T-2)+4)
+(D@(T-2)+4)
}

# m207 FP_SET_LIMB_HOST
# T-2 = base
# T-1 = limb index
# T   = limb value
m207={
@!207
}

# m208 FP_GET_LIMB_HOST
# T-2 = base
# T-1 = limb index
# T+1 = limb value
m208={
@!208
}

# m209 FP_PRINT_RAW
# T-1 = base
m209={
@!209
}

# m210 FP_ADD
# T-2 = result base
# T-1 = A base
# T   = B base
m210={
@!210
}

# m211 FP_SUB
# T-2 = result base
# T-1 = A base
# T   = B base
m211={
@!211
}

# m212 FP_MUL
# T-2 = result base
# T-1 = A base
# T   = B base
m212={
@!212
}

# m213 FP_DIV
# T-2 = result base
# T-1 = A base
# T   = B base
m213={
@!213
}

# m214 FP_COMPARE
# T-1 = A base
# T   = B base
# T+1 = 0 equal, 1 A>B, maxcell A<B
m214={
@!214
}

# m215 FP_ABS
# T-2 = destination base
# T-1 = source base
m215={
@!215
}

# m216 FP_NEG
# T-2 = destination base
# T-1 = source base
m216={
@!216
}

# m217 FP_ROUND16
# T-2 = base
m217={
@!217
}

# m218 FP_ROUND32
# T-2 = base
m218={
@!218
}

# m219 FP_TRUNC
# T-2 = base
m219={
@!219
}

# m220 FP_FROM_INT
# T-2 = destination base
# T-1 = integer value
m220={
@!220
}

# m221 FP_FROM_DEC_STRING
# T-2 = destination base
# T-1 = data string start
m221={
@!221
}

# m222 FP_TO_DEC_STRING
# T-2 = source base
# T-1 = output data string start
m222={
@!222
}

# m223 FP_PRINT_DEC
# T-1 = source base
m223={
@!223
}

# m224 FP_SCALE10
# T-2 = base
# T-1 = signed decimal shift
m224={
@!224
}

# m225 FP_ALIGN_EXP
m225={
@!225
}

# m226 FP_SHIFT_LEFT_DEC
m226={
@!226
}

# m227 FP_SHIFT_RIGHT_DEC
m227={
@!227
}

# m230 FP_SQRT
m230={
@!230
}

# m231 FP_HYPOT
m231={
@!231
}

# m232 FP_SIN
m232={
@!232
}

# m233 FP_COS
m233={
@!233
}

# m234 FP_TAN
m234={
@!234
}
```

Burada temel işlemler programcı açısından macro’dur:

```text
@210 değil, @210 yazınca m210 varsa macro açılır.
m210 içinde @!210 ile host hızlandırıcı çağrılır.
```

Bu tasarımın avantajı şu:

```text
Kullanıcı FP_ADD işlemini macro olarak kullanır.
İstersek sonra m210 gövdesini tamamen saf UXM uzun toplama algoritmasına çeviririz.
Host hızlandırıcı değişse bile kullanıcı kodu değişmez.
```

---

# 9. Örnek FP programı

Bu örnek `ux_fp_v1.uxm` macro kütüphanesi kaynak dosyanın başına eklendi varsayımıyla çalışır.

```text
# FP example
# EXPECT_OUTPUT: 46.0000000000000000
# A = 12
# B = 34
# R = A + B

>>
0(T-2)+k100
@200

0(T-2)+k140
@200

0(T-2)+k180
@200

0(T-2)+k100
0(T-1)+k12
@220

0(T-2)+k140
0(T-1)+k34
@220

0(T-2)+k180
0(T-1)+k100
0(T)+k140
@210

0(T-1)+k180
@223
```

Burada `@200`, `@220`, `@210`, `@223` aslında macro varsa macro çağırır. Macro içinde `@!200`, `@!220`, `@!210`, `@!223` host servislerine gider.

---

# 10. Runtime’a eklenecek FP meta yönlendirme

`ux_meta_call_ex` içine şu aralığı ekle:

```freebasic
ElseIf metaId>=200 And metaId<=239 Then
    MetaFloatingPoint metaId
```

Declare:

```freebasic
Declare Sub MetaFloatingPoint(ByVal metaId As ULongInt)
Declare Sub FPInit(ByVal base As LongInt, ByVal prec As LongInt)
Declare Sub FPZero(ByVal base As LongInt)
Declare Sub FPFromInt(ByVal base As LongInt, ByVal value As LongInt)
Declare Sub FPPrintDecimal(ByVal base As LongInt)
Declare Function FPSignedExp(ByVal base As LongInt) As LongInt
Declare Sub FPSetSignedExp(ByVal base As LongInt, ByVal e As LongInt)
Declare Function FPMantissaString(ByVal base As LongInt) As String
Declare Sub FPStoreMantExp(ByVal base As LongInt, ByVal sign As LongInt, ByVal mant As String, ByVal exp10 As LongInt)
Declare Function BigTrim(ByVal s As String) As String
Declare Function BigCmp(ByVal a As String, ByVal b As String) As LongInt
Declare Function BigAdd(ByVal a As String, ByVal b As String) As String
Declare Function BigSubAbs(ByVal a As String, ByVal b As String) As String
Declare Function BigMul(ByVal a As String, ByVal b As String) As String
```

İlk çalışan FP runtime çekirdeği:

```freebasic
Sub MetaFloatingPoint(ByVal metaId As ULongInt)
    Dim rBase As LongInt
    Dim aBase As LongInt
    Dim bBase As LongInt
    Dim aMant As String
    Dim bMant As String
    Dim rMant As String
    Dim expA As LongInt
    Dim expB As LongInt
    Dim expR As LongInt
    Dim signA As LongInt
    Dim signB As LongInt
    Dim signR As LongInt
    Dim cmp As LongInt
    rBase=CLngInt(Arg1())
    aBase=CLngInt(Arg2())
    bBase=CLngInt(Arg0())
    Select Case metaId
    Case 200
        FPInit rBase,16
        SetResult 0
    Case 201
        FPInit rBase,32
        SetResult 0
    Case 202
        FPZero rBase
        SetResult 0
    Case 204
        FPStoreMantExp rBase,ReadData(rBase+2),FPMantissaString(rBase),FPSignedExp(rBase)
        SetResult 0
    Case 210
        aMant=FPMantissaString(aBase)
        bMant=FPMantissaString(bBase)
        expA=FPSignedExp(aBase)
        expB=FPSignedExp(bBase)
        signA=ReadData(aBase+2)
        signB=ReadData(bBase+2)
        If expA>expB Then
            aMant=aMant+String(expA-expB,"0")
            expR=expB
        ElseIf expB>expA Then
            bMant=bMant+String(expB-expA,"0")
            expR=expA
        Else
            expR=expA
        End If
        If signA=signB Then
            rMant=BigAdd(aMant,bMant)
            signR=signA
        Else
            cmp=BigCmp(aMant,bMant)
            If cmp=0 Then
                rMant="0"
                signR=0
                expR=0
            ElseIf cmp>0 Then
                rMant=BigSubAbs(aMant,bMant)
                signR=signA
            Else
                rMant=BigSubAbs(bMant,aMant)
                signR=signB
            End If
        End If
        FPStoreMantExp rBase,signR,rMant,expR
        SetResult 0
    Case 212
        aMant=FPMantissaString(aBase)
        bMant=FPMantissaString(bBase)
        expA=FPSignedExp(aBase)
        expB=FPSignedExp(bBase)
        signA=ReadData(aBase+2)
        signB=ReadData(bBase+2)
        rMant=BigMul(aMant,bMant)
        expR=expA+expB
        signR=signA Xor signB
        FPStoreMantExp rBase,signR,rMant,expR
        SetResult 0
    Case 220
        FPFromInt rBase,aBase
        SetResult 0
    Case 223
        FPPrintDecimal aBase
        SetResult 0
    Case Else
        SetStatus STATUS_INVALID_META
        SetResult STATUS_INVALID_META
    End Select
End Sub
```

Dikkat: Burada `@220` frame’i şöyledir:

```text
T-2 = destination base
T-1 = integer value
```

Runtime tarafında `rBase=Arg1()` ve `aBase=Arg2()` olduğu için `FPFromInt rBase,aBase` doğrudur.

---

# 11. FP yardımcıları

Bunları runtime’a ekle:

```freebasic
Sub FPInit(ByVal base As LongInt, ByVal prec As LongInt)
    If base<0 Or base+40>=CLngInt(ux_data_cells) Then SetStatus STATUS_DATA_BOUNDS:Exit Sub
    WriteData base+0,70
    WriteData base+1,prec
    WriteData base+2,0
    WriteData base+3,0
    WriteData base+4,0
    WriteData base+5,1
    WriteData base+6,0
    WriteData base+7,0
    WriteData base+8,0
    SetStatus STATUS_OK
End Sub
Sub FPZero(ByVal base As LongInt)
    WriteData base+2,0
    WriteData base+3,0
    WriteData base+4,0
    WriteData base+5,1
    WriteData base+6,0
    WriteData base+8,0
    SetStatus STATUS_OK
End Sub
Sub FPFromInt(ByVal base As LongInt, ByVal value As LongInt)
    Dim sign As LongInt
    Dim v As LongInt
    Dim mant As String
    sign=0
    v=value
    If v<0 Then sign=1:v=-v
    mant=LTrim(Str(v))
    FPStoreMantExp base,sign,mant,0
End Sub
Function FPSignedExp(ByVal base As LongInt) As LongInt
    Dim es As LongInt
    Dim ea As LongInt
    es=ReadData(base+3)
    ea=ReadData(base+4)
    If es<>0 Then Return -ea
    Return ea
End Function
Sub FPSetSignedExp(ByVal base As LongInt, ByVal e As LongInt)
    If e<0 Then
        WriteData base+3,1
        WriteData base+4,Abs(e)
    Else
        WriteData base+3,0
        WriteData base+4,e
    End If
End Sub
Function FPMantissaString(ByVal base As LongInt) As String
    Dim used As LongInt
    Dim i As LongInt
    Dim limb As LongInt
    Dim s As String
    Dim part As String
    used=ReadData(base+5)
    If used<=0 Then Return "0"
    s=""
    For i=used-1 To 0 Step -1
        limb=ReadData(base+8+i)
        If i=used-1 Then
            s=s+LTrim(Str(limb))
        Else
            part=LTrim(Str(limb))
            If Len(part)=1 Then part="0"+part
            s=s+part
        End If
    Next
    Return BigTrim(s)
End Function
Sub FPStoreMantExp(ByVal base As LongInt, ByVal sign As LongInt, ByVal mant As String, ByVal exp10 As LongInt)
    Dim prec As LongInt
    Dim maxLimbs As LongInt
    Dim maxDigits As LongInt
    Dim used As LongInt
    Dim i As LongInt
    Dim part As String
    mant=BigTrim(mant)
    Do While Len(mant)>1 And Right(mant,1)="0"
        mant=Left(mant,Len(mant)-1)
        exp10=exp10+1
    Loop
    prec=ReadData(base+1)
    If prec<>16 And prec<>32 Then prec=16
    If prec=16 Then maxLimbs=16 Else maxLimbs=32
    maxDigits=maxLimbs*2
    If Len(mant)>maxDigits Then
        mant=Left(mant,maxDigits)
        WriteData base+6,6
    Else
        WriteData base+6,0
    End If
    For i=0 To maxLimbs-1
        WriteData base+8+i,0
    Next
    used=0
    Do While Len(mant)>0
        If Len(mant)>=2 Then
            part=Right(mant,2)
            mant=Left(mant,Len(mant)-2)
        Else
            part=mant
            mant=""
        End If
        WriteData base+8+used,Val(part)
        used=used+1
        If used>=maxLimbs Then Exit Do
    Loop
    If used=0 Then used=1
    WriteData base+0,70
    WriteData base+1,prec
    If mant="0" Then sign=0
    WriteData base+2,sign
    FPSetSignedExp base,exp10
    WriteData base+5,used
    SetStatus STATUS_OK
End Sub
Sub FPPrintDecimal(ByVal base As LongInt)
    Dim mant As String
    Dim exp10 As LongInt
    Dim sign As LongInt
    Dim prec As LongInt
    Dim pointPos As LongInt
    Dim intPart As String
    Dim fracPart As String
    mant=FPMantissaString(base)
    exp10=FPSignedExp(base)
    sign=ReadData(base+2)
    prec=ReadData(base+1)
    If prec<>16 And prec<>32 Then prec=16
    If sign<>0 And mant<>"0" Then Print "-";
    If exp10>=0 Then
        Print mant+String(exp10,"0");
        If prec>0 Then Print "."+String(prec,"0");
        Exit Sub
    End If
    pointPos=Len(mant)+exp10
    If pointPos>0 Then
        intPart=Left(mant,pointPos)
        fracPart=Mid(mant,pointPos+1)
    Else
        intPart="0"
        fracPart=String(Abs(pointPos),"0")+mant
    End If
    If Len(fracPart)<prec Then fracPart=fracPart+String(prec-Len(fracPart),"0")
    If Len(fracPart)>prec Then fracPart=Left(fracPart,prec)
    Print intPart+"."+fracPart;
End Sub
```

---

# 12. Big integer string yardımcıları

```freebasic
Function BigTrim(ByVal s As String) As String
    Do While Len(s)>1 And Left(s,1)="0"
        s=Mid(s,2)
    Loop
    If s="" Then s="0"
    Return s
End Function
Function BigCmp(ByVal a As String, ByVal b As String) As LongInt
    a=BigTrim(a)
    b=BigTrim(b)
    If Len(a)>Len(b) Then Return 1
    If Len(a)<Len(b) Then Return -1
    If a>b Then Return 1
    If a<b Then Return -1
    Return 0
End Function
Function BigAdd(ByVal a As String, ByVal b As String) As String
    Dim ia As LongInt
    Dim ib As LongInt
    Dim carry As LongInt
    Dim da As LongInt
    Dim db As LongInt
    Dim sum As LongInt
    Dim r As String
    a=BigTrim(a)
    b=BigTrim(b)
    ia=Len(a)
    ib=Len(b)
    carry=0
    r=""
    Do While ia>0 Or ib>0 Or carry>0
        da=0:db=0
        If ia>0 Then da=Val(Mid(a,ia,1)):ia=ia-1
        If ib>0 Then db=Val(Mid(b,ib,1)):ib=ib-1
        sum=da+db+carry
        r=Chr(48+(sum Mod 10))+r
        carry=sum\10
    Loop
    Return BigTrim(r)
End Function
Function BigSubAbs(ByVal a As String, ByVal b As String) As String
    Dim ia As LongInt
    Dim ib As LongInt
    Dim borrow As LongInt
    Dim da As LongInt
    Dim db As LongInt
    Dim d As LongInt
    Dim r As String
    If BigCmp(a,b)<0 Then Return "0"
    a=BigTrim(a)
    b=BigTrim(b)
    ia=Len(a)
    ib=Len(b)
    borrow=0
    r=""
    Do While ia>0
        da=Val(Mid(a,ia,1))-borrow
        db=0
        If ib>0 Then db=Val(Mid(b,ib,1)):ib=ib-1
        If da<db Then
            da=da+10
            borrow=1
        Else
            borrow=0
        End If
        d=da-db
        r=Chr(48+d)+r
        ia=ia-1
    Loop
    Return BigTrim(r)
End Function
Function BigMul(ByVal a As String, ByVal b As String) As String
    Dim la As LongInt
    Dim lb As LongInt
    Dim i As LongInt
    Dim j As LongInt
    Dim ai As LongInt
    Dim bj As LongInt
    Dim p As LongInt
    Dim carry As LongInt
    Dim arr(0 To 255) As LongInt
    Dim r As String
    a=BigTrim(a)
    b=BigTrim(b)
    If a="0" Or b="0" Then Return "0"
    la=Len(a)
    lb=Len(b)
    For i=0 To 255
        arr(i)=0
    Next
    For i=la To 1 Step -1
        ai=Val(Mid(a,i,1))
        carry=0
        For j=lb To 1 Step -1
            bj=Val(Mid(b,j,1))
            p=(la-i)+(lb-j)
            arr(p)=arr(p)+ai*bj+carry
            carry=arr(p)\10
            arr(p)=arr(p) Mod 10
        Next
        p=(la-i)+lb
        Do While carry>0
            arr(p)=arr(p)+carry
            carry=arr(p)\10
            arr(p)=arr(p) Mod 10
            p=p+1
        Loop
    Next
    r=""
    For i=255 To 0 Step -1
        If r<>"" Or arr(i)<>0 Then r=r+Chr(48+arr(i))
    Next
    If r="" Then r="0"
    Return BigTrim(r)
End Function
```

---

# 13. Şimdilik çalışan FP kapsamı

Bu ilk FP koduyla gerçek çalışan temel şunlar olur:

```text
m200 / @!200   FP_INIT16
m201 / @!201   FP_INIT32
m202           FP_ZERO
m210 / @!210   FP_ADD
m212 / @!212   FP_MUL
m220 / @!220   FP_FROM_INT
m223 / @!223   FP_PRINT_DEC
```

Bölme için `m213 / @!213` servis yerini ayırdık. Onu ikinci aşamada `BigDiv` ile eklemek doğru olur; division en uzun ve test isteyen parça.

Net karar:

```text
(D@...) adresleme normal mod standardıdır.
@!N host meta zorla çağırma sözdizimi olmalıdır.
Temel floating point API macro olmalıdır.
Ağır hesap host hızlandırıcı ile başlar.
İleride aynı m210/m212/m213 gövdeleri saf UXM algoritmalara çevrilebilir.
```

Böylece UX-MINIMA programcısı hep şu tarzda çalışır:

```text
@200  FP_INIT16 macro
@220  FP_FROM_INT macro
@210  FP_ADD macro
@212  FP_MUL macro
@223  FP_PRINT_DEC macro
```

ama macro içinde gerçek motor şimdilik:

```text
@!200
@!220
@!210
@!212
@!223
```

ile host FP runtime’a gider.
Aşağıdaki parça, önceki FP başlangıcının devamıdır. Bunu **`uxm31_runtime_fb_full.bas`** içine ekleyeceğiz.

Bu aşamada `@200..@239` floating point servisleri gerçek çalışır hale geliyor.

---

# 1. Declare listesine eklenecekler

Runtime dosyasındaki declare bölümüne şunları ekle:

```freebasic id="8tw2xo"
Declare Sub MetaFloatingPoint(ByVal metaId As ULongInt)
Declare Sub FPInit(ByVal base As LongInt, ByVal prec As LongInt)
Declare Sub FPZero(ByVal base As LongInt)
Declare Sub FPCopy(ByVal dstBase As LongInt, ByVal srcBase As LongInt)
Declare Sub FPFromInt(ByVal base As LongInt, ByVal value As LongInt)
Declare Sub FPFromDecString(ByVal base As LongInt, ByVal dataStart As LongInt)
Declare Sub FPToDecString(ByVal base As LongInt, ByVal dataStart As LongInt)
Declare Sub FPPrintDecimal(ByVal base As LongInt)
Declare Function FPFormatDecimal(ByVal base As LongInt) As String
Declare Function FPSignedExp(ByVal base As LongInt) As LongInt
Declare Sub FPSetSignedExp(ByVal base As LongInt, ByVal e As LongInt)
Declare Function FPMantissaString(ByVal base As LongInt) As String
Declare Sub FPStoreMantExp(ByVal base As LongInt, ByVal sign As LongInt, ByVal mant As String, ByVal exp10 As LongInt)
Declare Sub FPRoundFrac(ByVal base As LongInt, ByVal prec As LongInt)
Declare Sub FPTrunc(ByVal base As LongInt)
Declare Function FPCompareAbs(ByVal aBase As LongInt, ByVal bBase As LongInt) As LongInt
Declare Function FPCompare(ByVal aBase As LongInt, ByVal bBase As LongInt) As LongInt
Declare Function BigTrim(ByVal s As String) As String
Declare Function BigCmp(ByVal a As String, ByVal b As String) As LongInt
Declare Function BigAdd(ByVal a As String, ByVal b As String) As String
Declare Function BigSubAbs(ByVal a As String, ByVal b As String) As String
Declare Function BigMul(ByVal a As String, ByVal b As String) As String
Declare Function BigDivInt(ByVal numer As String, ByVal denom As String) As String
Declare Function BigShift10(ByVal s As String, ByVal n As LongInt) As String
Declare Function DataString(ByVal startCell As LongInt) As String
Declare Sub WriteDataString(ByVal startCell As LongInt, ByVal s As String)
```

---

# 2. `ux_meta_call_ex` içine FP aralığını ekle

Mevcut `ux_meta_call_ex` içinde şu kontrol olmalı:

```freebasic id="2fd7sd"
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
ElseIf metaId>=200 And metaId<=239 Then
MetaFloatingPoint metaId
Else
SetStatus STATUS_INVALID_META
End If
End Sub
```

---

# 3. Tam `MetaFloatingPoint` servisi

Bunu runtime dosyasına ekle:

```freebasic id="4ewy06"
Sub MetaFloatingPoint(ByVal metaId As ULongInt)
Dim rBase As LongInt
Dim aBase As LongInt
Dim bBase As LongInt
Dim aMant As String
Dim bMant As String
Dim rMant As String
Dim expA As LongInt
Dim expB As LongInt
Dim expR As LongInt
Dim signA As LongInt
Dim signB As LongInt
Dim signR As LongInt
Dim cmp As LongInt
Dim scaleDigits As LongInt
Dim q As String
rBase=CLngInt(Arg1())
aBase=CLngInt(Arg2())
bBase=CLngInt(Arg0())
Select Case metaId
Case 200
FPInit rBase,16
SetResult 0
Case 201
FPInit rBase,32
SetResult 0
Case 202
FPZero rBase
SetResult 0
Case 203
FPCopy rBase,aBase
SetResult 0
Case 204
FPStoreMantExp rBase,ReadData(rBase+2),FPMantissaString(rBase),FPSignedExp(rBase)
SetResult 0
Case 209
Print "FP RAW base=";aBase;" sign=";ReadData(aBase+2);" exp=";FPSignedExp(aBase);" mant=";FPMantissaString(aBase)
SetResult 0
Case 210
aMant=FPMantissaString(aBase)
bMant=FPMantissaString(bBase)
expA=FPSignedExp(aBase)
expB=FPSignedExp(bBase)
signA=ReadData(aBase+2)
signB=ReadData(bBase+2)
If expA>expB Then
aMant=BigShift10(aMant,expA-expB)
expR=expB
ElseIf expB>expA Then
bMant=BigShift10(bMant,expB-expA)
expR=expA
Else
expR=expA
End If
If signA=signB Then
rMant=BigAdd(aMant,bMant)
signR=signA
Else
cmp=BigCmp(aMant,bMant)
If cmp=0 Then
rMant="0"
signR=0
expR=0
ElseIf cmp>0 Then
rMant=BigSubAbs(aMant,bMant)
signR=signA
Else
rMant=BigSubAbs(bMant,aMant)
signR=signB
End If
End If
FPStoreMantExp rBase,signR,rMant,expR
SetResult 0
Case 211
aMant=FPMantissaString(aBase)
bMant=FPMantissaString(bBase)
expA=FPSignedExp(aBase)
expB=FPSignedExp(bBase)
signA=ReadData(aBase+2)
signB=ReadData(bBase+2) Xor 1
If expA>expB Then
aMant=BigShift10(aMant,expA-expB)
expR=expB
ElseIf expB>expA Then
bMant=BigShift10(bMant,expB-expA)
expR=expA
Else
expR=expA
End If
If signA=signB Then
rMant=BigAdd(aMant,bMant)
signR=signA
Else
cmp=BigCmp(aMant,bMant)
If cmp=0 Then
rMant="0"
signR=0
expR=0
ElseIf cmp>0 Then
rMant=BigSubAbs(aMant,bMant)
signR=signA
Else
rMant=BigSubAbs(bMant,aMant)
signR=signB
End If
End If
FPStoreMantExp rBase,signR,rMant,expR
SetResult 0
Case 212
aMant=FPMantissaString(aBase)
bMant=FPMantissaString(bBase)
expA=FPSignedExp(aBase)
expB=FPSignedExp(bBase)
signA=ReadData(aBase+2)
signB=ReadData(bBase+2)
rMant=BigMul(aMant,bMant)
expR=expA+expB
signR=signA Xor signB
FPStoreMantExp rBase,signR,rMant,expR
SetResult 0
Case 213
aMant=FPMantissaString(aBase)
bMant=FPMantissaString(bBase)
If bMant="0" Then
WriteData rBase+6,4
SetStatus STATUS_DIV_ZERO
SetResult STATUS_DIV_ZERO
Exit Sub
End If
expA=FPSignedExp(aBase)
expB=FPSignedExp(bBase)
signA=ReadData(aBase+2)
signB=ReadData(bBase+2)
If ReadData(rBase+1)=32 Then
scaleDigits=64
Else
scaleDigits=32
End If
q=BigDivInt(BigShift10(aMant,scaleDigits),bMant)
expR=expA-expB-scaleDigits
signR=signA Xor signB
FPStoreMantExp rBase,signR,q,expR
If ReadData(rBase+1)=32 Then FPRoundFrac rBase,32 Else FPRoundFrac rBase,16
SetResult 0
Case 214
cmp=FPCompare(aBase,bBase)
If cmp=0 Then
SetResult 0
ElseIf cmp>0 Then
SetResult 1
Else
SetResult CellMask()
End If
SetLogicFlags ResultValue()
Case 215
FPCopy rBase,aBase
WriteData rBase+2,0
SetResult 0
Case 216
FPCopy rBase,aBase
If FPMantissaString(rBase)<>"0" Then WriteData rBase+2,ReadData(rBase+2) Xor 1
SetResult 0
Case 217
FPRoundFrac rBase,16
SetResult 0
Case 218
FPRoundFrac rBase,32
SetResult 0
Case 219
FPTrunc rBase
SetResult 0
Case 220
FPFromInt rBase,aBase
SetResult 0
Case 221
FPFromDecString rBase,aBase
SetResult 0
Case 222
FPToDecString rBase,aBase
SetResult 0
Case 223
FPPrintDecimal aBase
SetResult 0
Case 224
FPStoreMantExp rBase,ReadData(rBase+2),FPMantissaString(rBase),FPSignedExp(rBase)+aBase
SetResult 0
Case 230
SetStatus STATUS_INVALID_META
SetResult STATUS_INVALID_META
Case 231
SetStatus STATUS_INVALID_META
SetResult STATUS_INVALID_META
Case 232
SetStatus STATUS_INVALID_META
SetResult STATUS_INVALID_META
Case 233
SetStatus STATUS_INVALID_META
SetResult STATUS_INVALID_META
Case 234
SetStatus STATUS_INVALID_META
SetResult STATUS_INVALID_META
Case Else
SetStatus STATUS_INVALID_META
SetResult STATUS_INVALID_META
End Select
End Sub
```

Not: `@230..@234` için yer ayrıldı ama bu aşamada bilerek `STATUS_INVALID_META` dönüyor. Çünkü `SQRT/SIN/COS/TAN` için ya Newton metodu ya da tablo/seri yöntemi ayrıca yazılmalı.

---

# 4. FP blok yardımcıları

Bunları runtime dosyasına ekle:

```freebasic id="cvs48p"
Sub FPInit(ByVal base As LongInt, ByVal prec As LongInt)
Dim maxCells As LongInt
If prec=32 Then maxCells=40 Else maxCells=24
If base<0 Or base+maxCells>=CLngInt(ux_data_cells) Then SetStatus STATUS_DATA_BOUNDS:Exit Sub
WriteData base+0,70
WriteData base+1,prec
WriteData base+2,0
WriteData base+3,0
WriteData base+4,0
WriteData base+5,1
WriteData base+6,0
WriteData base+7,0
WriteData base+8,0
SetStatus STATUS_OK
End Sub
Sub FPZero(ByVal base As LongInt)
WriteData base+2,0
WriteData base+3,0
WriteData base+4,0
WriteData base+5,1
WriteData base+6,0
WriteData base+8,0
SetStatus STATUS_OK
End Sub
Sub FPCopy(ByVal dstBase As LongInt, ByVal srcBase As LongInt)
Dim prec As LongInt
Dim maxCells As LongInt
Dim i As LongInt
prec=ReadData(srcBase+1)
If prec=32 Then maxCells=40 Else maxCells=24
If dstBase<0 Or srcBase<0 Or dstBase+maxCells>=CLngInt(ux_data_cells) Or srcBase+maxCells>=CLngInt(ux_data_cells) Then
SetStatus STATUS_DATA_BOUNDS
Exit Sub
End If
For i=0 To maxCells-1
WriteData dstBase+i,ReadData(srcBase+i)
Next i
SetStatus STATUS_OK
End Sub
Sub FPFromInt(ByVal base As LongInt, ByVal value As LongInt)
Dim sign As LongInt
Dim v As LongInt
Dim mant As String
sign=0
v=value
If v<0 Then sign=1:v=-v
mant=LTrim(Str(v))
FPStoreMantExp base,sign,mant,0
End Sub
Function FPSignedExp(ByVal base As LongInt) As LongInt
Dim es As LongInt
Dim ea As LongInt
es=ReadData(base+3)
ea=ReadData(base+4)
If es<>0 Then Return -ea
Return ea
End Function
Sub FPSetSignedExp(ByVal base As LongInt, ByVal e As LongInt)
If e<0 Then
WriteData base+3,1
WriteData base+4,Abs(e)
Else
WriteData base+3,0
WriteData base+4,e
End If
End Sub
Function FPMantissaString(ByVal base As LongInt) As String
Dim used As LongInt
Dim i As LongInt
Dim limb As LongInt
Dim s As String
Dim part As String
used=ReadData(base+5)
If used<=0 Then Return "0"
s=""
For i=used-1 To 0 Step -1
limb=ReadData(base+8+i)
If i=used-1 Then
s=s+LTrim(Str(limb))
Else
part=LTrim(Str(limb))
If Len(part)=1 Then part="0"+part
s=s+part
End If
Next i
Return BigTrim(s)
End Function
Sub FPStoreMantExp(ByVal base As LongInt, ByVal sign As LongInt, ByVal mant As String, ByVal exp10 As LongInt)
Dim prec As LongInt
Dim maxLimbs As LongInt
Dim maxDigits As LongInt
Dim used As LongInt
Dim i As LongInt
Dim part As String
mant=BigTrim(mant)
Do While Len(mant)>1 And Right(mant,1)="0"
mant=Left(mant,Len(mant)-1)
exp10=exp10+1
Loop
prec=ReadData(base+1)
If prec<>16 And prec<>32 Then prec=16
If prec=16 Then maxLimbs=16 Else maxLimbs=32
maxDigits=maxLimbs*2
If Len(mant)>maxDigits Then
mant=Left(mant,maxDigits)
WriteData base+6,6
Else
WriteData base+6,0
End If
For i=0 To maxLimbs-1
WriteData base+8+i,0
Next i
used=0
Do While Len(mant)>0
If Len(mant)>=2 Then
part=Right(mant,2)
mant=Left(mant,Len(mant)-2)
Else
part=mant
mant=""
End If
WriteData base+8+used,Val(part)
used=used+1
If used>=maxLimbs Then Exit Do
Loop
If used=0 Then used=1
WriteData base+0,70
WriteData base+1,prec
If BigTrim(FPMantissaString(base))="0" Then sign=0
WriteData base+2,sign
FPSetSignedExp base,exp10
WriteData base+5,used
SetStatus STATUS_OK
End Sub
```

Burada küçük bir not var: `FPStoreMantExp` içinde `FPMantissaString(base)` çağrısı henüz yeni yazılan mantissa’yı okuyacağı için sıfır kontrolünü daha temiz yapmak istersek şu satırı:

```freebasic id="qzlq87"
If BigTrim(FPMantissaString(base))="0" Then sign=0
```

şununla değiştirmek daha doğrudur:

```freebasic id="wogznd"
If BigTrim(mant)="0" Then sign=0
```

Ama `mant` döngüde boşaltıldığı için bunun için başta `origMant` tutmak gerekir. Daha sağlam sürüm aşağıdaki gibidir.

Yukarıdaki `FPStoreMantExp` yerine bunu kullan:

```freebasic id="g5nkme"
Sub FPStoreMantExp(ByVal base As LongInt, ByVal sign As LongInt, ByVal mant As String, ByVal exp10 As LongInt)
Dim prec As LongInt
Dim maxLimbs As LongInt
Dim maxDigits As LongInt
Dim used As LongInt
Dim i As LongInt
Dim part As String
Dim origMant As String
mant=BigTrim(mant)
Do While Len(mant)>1 And Right(mant,1)="0"
mant=Left(mant,Len(mant)-1)
exp10=exp10+1
Loop
origMant=mant
prec=ReadData(base+1)
If prec<>16 And prec<>32 Then prec=16
If prec=16 Then maxLimbs=16 Else maxLimbs=32
maxDigits=maxLimbs*2
If Len(mant)>maxDigits Then
mant=Left(mant,maxDigits)
origMant=mant
WriteData base+6,6
Else
WriteData base+6,0
End If
For i=0 To maxLimbs-1
WriteData base+8+i,0
Next i
used=0
Do While Len(mant)>0
If Len(mant)>=2 Then
part=Right(mant,2)
mant=Left(mant,Len(mant)-2)
Else
part=mant
mant=""
End If
WriteData base+8+used,Val(part)
used=used+1
If used>=maxLimbs Then Exit Do
Loop
If used=0 Then used=1
WriteData base+0,70
WriteData base+1,prec
If BigTrim(origMant)="0" Then sign=0
WriteData base+2,sign
FPSetSignedExp base,exp10
WriteData base+5,used
SetStatus STATUS_OK
End Sub
```

---

# 5. Decimal string okuma/yazma

```freebasic id="k1ydp6"
Function DataString(ByVal startCell As LongInt) As String
Dim s As String
Dim i As LongInt
Dim v As ULongInt
s=""
i=startCell
Do While i>=0 And i<CLngInt(ux_data_cells)
v=ReadData(i)
If v=0 Then Exit Do
s=s+Chr(v And &HFF)
i=i+1
Loop
Return s
End Function
Sub WriteDataString(ByVal startCell As LongInt, ByVal s As String)
Dim i As LongInt
If startCell<0 Or startCell+Len(s)>=CLngInt(ux_data_cells) Then
SetStatus STATUS_DATA_BOUNDS
Exit Sub
End If
For i=1 To Len(s)
WriteData startCell+i-1,Asc(Mid(s,i,1)) And &HFF
Next i
WriteData startCell+Len(s),0
SetStatus STATUS_OK
End Sub
Sub FPFromDecString(ByVal base As LongInt, ByVal dataStart As LongInt)
Dim s As String
Dim i As LongInt
Dim c As String
Dim sign As LongInt
Dim mant As String
Dim fracCount As LongInt
Dim afterDot As Long
s=DataString(dataStart)
s=Trim(s)
sign=0
mant=""
fracCount=0
afterDot=0
If Left(s,1)="-" Then
sign=1
s=Mid(s,2)
ElseIf Left(s,1)="+" Then
s=Mid(s,2)
End If
For i=1 To Len(s)
c=Mid(s,i,1)
If c="." Or c="," Then
afterDot=1
ElseIf c>="0" And c<="9" Then
mant=mant+c
If afterDot<>0 Then fracCount=fracCount+1
End If
Next i
If mant="" Then mant="0"
FPStoreMantExp base,sign,mant,-fracCount
End Sub
Sub FPToDecString(ByVal base As LongInt, ByVal dataStart As LongInt)
WriteDataString dataStart,FPFormatDecimal(base)
End Sub
Sub FPPrintDecimal(ByVal base As LongInt)
Print FPFormatDecimal(base);
End Sub
Function FPFormatDecimal(ByVal base As LongInt) As String
Dim mant As String
Dim exp10 As LongInt
Dim sign As LongInt
Dim prec As LongInt
Dim pointPos As LongInt
Dim intPart As String
Dim fracPart As String
Dim out As String
mant=FPMantissaString(base)
exp10=FPSignedExp(base)
sign=ReadData(base+2)
prec=ReadData(base+1)
If prec<>16 And prec<>32 Then prec=16
out=""
If sign<>0 And mant<>"0" Then out="-"
If exp10>=0 Then
out=out+mant+String(exp10,"0")
If prec>0 Then out=out+"."+String(prec,"0")
Return out
End If
pointPos=Len(mant)+exp10
If pointPos>0 Then
intPart=Left(mant,pointPos)
fracPart=Mid(mant,pointPos+1)
Else
intPart="0"
fracPart=String(Abs(pointPos),"0")+mant
End If
If Len(fracPart)<prec Then fracPart=fracPart+String(prec-Len(fracPart),"0")
If Len(fracPart)>prec Then fracPart=Left(fracPart,prec)
out=out+intPart+"."+fracPart
Return out
End Function
```

---

# 6. Rounding ve truncation

```freebasic id="p5khxf"
Sub FPRoundFrac(ByVal base As LongInt, ByVal prec As LongInt)
Dim mant As String
Dim exp10 As LongInt
Dim sign As LongInt
Dim drop As LongInt
Dim keepLen As LongInt
Dim kept As String
Dim nextDigit As LongInt
mant=FPMantissaString(base)
exp10=FPSignedExp(base)
sign=ReadData(base+2)
If exp10>=-prec Then
WriteData base+1,prec
Exit Sub
End If
drop=(-prec)-exp10
If drop<=0 Then
WriteData base+1,prec
Exit Sub
End If
If drop>=Len(mant) Then
mant="0"
exp10=-prec
FPStoreMantExp base,0,mant,exp10
WriteData base+1,prec
Exit Sub
End If
keepLen=Len(mant)-drop
kept=Left(mant,keepLen)
nextDigit=Val(Mid(mant,keepLen+1,1))
If nextDigit>=5 Then kept=BigAdd(kept,"1")
exp10=exp10+drop
FPStoreMantExp base,sign,kept,exp10
WriteData base+1,prec
SetStatus STATUS_OK
End Sub
Sub FPTrunc(ByVal base As LongInt)
Dim mant As String
Dim exp10 As LongInt
Dim sign As LongInt
Dim drop As LongInt
Dim keepLen As LongInt
mant=FPMantissaString(base)
exp10=FPSignedExp(base)
sign=ReadData(base+2)
If exp10>=0 Then Exit Sub
drop=-exp10
If drop>=Len(mant) Then
FPStoreMantExp base,0,"0",0
Exit Sub
End If
keepLen=Len(mant)-drop
mant=Left(mant,keepLen)
FPStoreMantExp base,sign,mant,0
SetStatus STATUS_OK
End Sub
```

---

# 7. Compare fonksiyonları

```freebasic id="p2ddv7"
Function FPCompareAbs(ByVal aBase As LongInt, ByVal bBase As LongInt) As LongInt
Dim aMant As String
Dim bMant As String
Dim expA As LongInt
Dim expB As LongInt
aMant=FPMantissaString(aBase)
bMant=FPMantissaString(bBase)
expA=FPSignedExp(aBase)
expB=FPSignedExp(bBase)
If expA>expB Then
aMant=BigShift10(aMant,expA-expB)
ElseIf expB>expA Then
bMant=BigShift10(bMant,expB-expA)
End If
Return BigCmp(aMant,bMant)
End Function
Function FPCompare(ByVal aBase As LongInt, ByVal bBase As LongInt) As LongInt
Dim signA As LongInt
Dim signB As LongInt
Dim cmp As LongInt
signA=ReadData(aBase+2)
signB=ReadData(bBase+2)
If FPMantissaString(aBase)="0" And FPMantissaString(bBase)="0" Then Return 0
If signA=0 And signB<>0 Then Return 1
If signA<>0 And signB=0 Then Return -1
cmp=FPCompareAbs(aBase,bBase)
If signA<>0 Then cmp=-cmp
Return cmp
End Function
```

---

# 8. Big integer yardımcıları

```freebasic id="1rubj3"
Function BigTrim(ByVal s As String) As String
Do While Len(s)>1 And Left(s,1)="0"
s=Mid(s,2)
Loop
If s="" Then s="0"
Return s
End Function
Function BigShift10(ByVal s As String, ByVal n As LongInt) As String
s=BigTrim(s)
If s="0" Then Return "0"
If n<=0 Then Return s
Return s+String(n,"0")
End Function
Function BigCmp(ByVal a As String, ByVal b As String) As LongInt
a=BigTrim(a)
b=BigTrim(b)
If Len(a)>Len(b) Then Return 1
If Len(a)<Len(b) Then Return -1
If a>b Then Return 1
If a<b Then Return -1
Return 0
End Function
Function BigAdd(ByVal a As String, ByVal b As String) As String
Dim ia As LongInt
Dim ib As LongInt
Dim carry As LongInt
Dim da As LongInt
Dim db As LongInt
Dim sum As LongInt
Dim r As String
a=BigTrim(a)
b=BigTrim(b)
ia=Len(a)
ib=Len(b)
carry=0
r=""
Do While ia>0 Or ib>0 Or carry>0
da=0
db=0
If ia>0 Then da=Val(Mid(a,ia,1)):ia=ia-1
If ib>0 Then db=Val(Mid(b,ib,1)):ib=ib-1
sum=da+db+carry
r=Chr(48+(sum Mod 10))+r
carry=sum\10
Loop
Return BigTrim(r)
End Function
Function BigSubAbs(ByVal a As String, ByVal b As String) As String
Dim ia As LongInt
Dim ib As LongInt
Dim borrow As LongInt
Dim da As LongInt
Dim db As LongInt
Dim d As LongInt
Dim r As String
If BigCmp(a,b)<0 Then Return "0"
a=BigTrim(a)
b=BigTrim(b)
ia=Len(a)
ib=Len(b)
borrow=0
r=""
Do While ia>0
da=Val(Mid(a,ia,1))-borrow
db=0
If ib>0 Then db=Val(Mid(b,ib,1)):ib=ib-1
If da<db Then
da=da+10
borrow=1
Else
borrow=0
End If
d=da-db
r=Chr(48+d)+r
ia=ia-1
Loop
Return BigTrim(r)
End Function
Function BigMul(ByVal a As String, ByVal b As String) As String
Dim la As LongInt
Dim lb As LongInt
Dim i As LongInt
Dim j As LongInt
Dim ai As LongInt
Dim bj As LongInt
Dim p As LongInt
Dim carry As LongInt
Dim arr(0 To 511) As LongInt
Dim r As String
a=BigTrim(a)
b=BigTrim(b)
If a="0" Or b="0" Then Return "0"
la=Len(a)
lb=Len(b)
For i=0 To 511
arr(i)=0
Next i
For i=la To 1 Step -1
ai=Val(Mid(a,i,1))
carry=0
For j=lb To 1 Step -1
bj=Val(Mid(b,j,1))
p=(la-i)+(lb-j)
arr(p)=arr(p)+ai*bj+carry
carry=arr(p)\10
arr(p)=arr(p) Mod 10
Next j
p=(la-i)+lb
Do While carry>0
arr(p)=arr(p)+carry
carry=arr(p)\10
arr(p)=arr(p) Mod 10
p=p+1
Loop
Next i
r=""
For i=511 To 0 Step -1
If r<>"" Or arr(i)<>0 Then r=r+Chr(48+arr(i))
Next i
If r="" Then r="0"
Return BigTrim(r)
End Function
Function BigDivInt(ByVal numer As String, ByVal denom As String) As String
Dim i As LongInt
Dim digit As LongInt
Dim rems As String
Dim q As String
Dim c As String
numer=BigTrim(numer)
denom=BigTrim(denom)
If denom="0" Then Return "0"
If BigCmp(numer,denom)<0 Then Return "0"
rems="0"
q=""
For i=1 To Len(numer)
c=Mid(numer,i,1)
If rems="0" Then
rems=c
Else
rems=rems+c
End If
rems=BigTrim(rems)
digit=0
Do While BigCmp(rems,denom)>=0
rems=BigSubAbs(rems,denom)
digit=digit+1
Loop
q=q+Chr(48+digit)
Next i
Return BigTrim(q)
End Function
```

---

# 9. Macro kütüphanesinde güncelleme

`ux_fp_v1.uxm` içinde `m211`, `m213`, `m214`, `m217`, `m218`, `m219`, `m221`, `m222` artık gerçek host servislere gider:

```text id="g05n03"
m211={@!211}
m213={@!213}
m214={@!214}
m217={@!217}
m218={@!218}
m219={@!219}
m221={@!221}
m222={@!222}
```

Tam minimum FP macro başlığı şöyle olsun:

```text id="aj4pst"
# UX-FP V1 macro header
m200={@!200}
m201={@!201}
m202={@!202}
m203={@!203}
m204={@!204}
m209={@!209}
m210={@!210}
m211={@!211}
m212={@!212}
m213={@!213}
m214={@!214}
m215={@!215}
m216={@!216}
m217={@!217}
m218={@!218}
m219={@!219}
m220={@!220}
m221={@!221}
m222={@!222}
m223={@!223}
m224={@!224}
```

Bu şekilde kullanıcı açısından hepsi macro’dur. Macro içinde host çağrısı vardır.

---

# 10. Yeni FP testleri

## `tests_fp\test_fp01_add_int.uxm`

```text id="y2ux31"
# EXPECT_OUTPUT: 46.0000000000000000
# UX-FP V1 header burada include edilmiş varsayılır
>>
0(T-2)+k100
@200
0(T-2)+k140
@200
0(T-2)+k180
@200
0(T-2)+k100
0(T-1)+k12
@220
0(T-2)+k140
0(T-1)+k34
@220
0(T-2)+k180
0(T-1)+k100
0(T)+k140
@210
0(T-1)+k180
@223
```

## `tests_fp\test_fp02_sub_int.uxm`

```text id="s7pz6k"
# EXPECT_OUTPUT: 25.0000000000000000
>>
0(T-2)+k100
@200
0(T-2)+k140
@200
0(T-2)+k180
@200
0(T-2)+k100
0(T-1)+k100
@220
0(T-2)+k140
0(T-1)+k75
@220
0(T-2)+k180
0(T-1)+k100
0(T)+k140
@211
0(T-1)+k180
@223
```

## `tests_fp\test_fp03_mul_int.uxm`

```text id="0qap6p"
# EXPECT_OUTPUT: 408.0000000000000000
>>
0(T-2)+k100
@200
0(T-2)+k140
@200
0(T-2)+k180
@200
0(T-2)+k100
0(T-1)+k12
@220
0(T-2)+k140
0(T-1)+k34
@220
0(T-2)+k180
0(T-1)+k100
0(T)+k140
@212
0(T-1)+k180
@223
```

## `tests_fp\test_fp04_div_int.uxm`

```text id="jv1x92"
# EXPECT_OUTPUT: 3.3333333333333333
>>
0(T-2)+k100
@200
0(T-2)+k140
@200
0(T-2)+k180
@200
0(T-2)+k100
0(T-1)+k10
@220
0(T-2)+k140
0(T-1)+k3
@220
0(T-2)+k180
0(T-1)+k100
0(T)+k140
@213
0(T-1)+k180
@223
```

## `tests_fp\test_fp05_from_string.uxm`

```text id="49am5p"
# EXPECT_OUTPUT: 12.3400000000000000
s1=0,{12.34}
>>
0(T-2)+k100
@200
0(T-2)+k100
0(T-1)
@221
0(T-1)+k100
@223
```

## `tests_fp\test_fp06_add_dec_string.uxm`

```text id="7vlgld"
# EXPECT_OUTPUT: 17.9400000000000000
s1=0,{12.34}
s2=20,{5.6}
>>
0(T-2)+k100
@200
0(T-2)+k140
@200
0(T-2)+k180
@200
0(T-2)+k100
0(T-1)
@221
0(T-2)+k140
0(T-1)+k20
@221
0(T-2)+k180
0(T-1)+k100
0(T)+k140
@210
0(T-1)+k180
@223
```

---

# 11. Şu anda FP kapsamı

Bu devamla beraber UX-FP V1’in temel hali şunları yapar:

```text id="4y7mze"
FP_INIT16
FP_INIT32
FP_ZERO
FP_COPY
FP_NORMALIZE
FP_ADD
FP_SUB
FP_MUL
FP_DIV
FP_COMPARE
FP_ABS
FP_NEG
FP_ROUND16
FP_ROUND32
FP_TRUNC
FP_FROM_INT
FP_FROM_DEC_STRING
FP_TO_DEC_STRING
FP_PRINT_DEC
FP_SCALE10
```

Kalan büyük bilimsel fonksiyonlar:

```text id="11806d"
FP_SQRT
FP_HYPOT
FP_SIN
FP_COS
FP_TAN
FP_LOG
FP_EXP
```

Bunları bir sonraki aşamada iki yoldan yazabiliriz:

```text id="2mu66y"
1. FP_SQRT: Newton-Raphson
2. SIN/COS/TAN: Taylor serisi veya önceden üretilmiş sinüs tablosu
```

Ama temel floating point sistemi artık oluştu: mantissa, exponent, sign, 16/32 hane, macro API ve host hızlandırıcı aynı tasarım altında bağlandı.
Evet Mete abi, **çekirdek tasarım büyük ölçüde tamamlandı**, ama “sağlam ürün” olması için hâlâ kalan işler var. Bunları önem sırasına göre yazıyorum.

## 1. En kritik kalan iş: Kodların tek projede birleştirilmesi

Şu anda parçalar halinde tasarladık:

```text
uxm31_compiler_fb_full.bas
uxm31_runtime_fb_full.bas
uxm31_full_tool_fb.bas
ux_fp_v1.uxm
uxminima-vscode/
```

Bunların artık tek proje ağacında düzenlenmesi gerekiyor:

```text
uxminima/
├─ compiler/
│  └─ uxm31_compiler_fb_full.bas
├─ runtime/
│  └─ uxm31_runtime_fb_full.bas
├─ tools/
│  └─ uxm31_full_tool_fb.bas
├─ lib/
│  └─ ux_fp_v1.uxm
├─ vscode-extension/
├─ tests/
├─ tests_full/
├─ tests_fp/
├─ docs/
└─ build/
```

Bu yapılmadan proje büyüdükçe karışır.

---

## 2. `(D@...)` adresleme modu mutlaka gerçek koda gömülmeli

Bu çok önemli. Çünkü FP macro sistemi buna dayanıyor.

Standart adresleme artık şunları desteklemeli:

```text
(D@T)
(D@T+N)
(D@T-N)
(D@(T-2)+N)
(D@(T-1)+N)
(D@(T)+N)
```

Bu adresleme **normal modda çalışmalı**. Wild mode’a bağlı olmamalı.

Bunu hem şu dosyalara gömmek gerekiyor:

```text
uxm31_compiler_fb_full.bas
uxm31_full_tool_fb.bas
VS Code diagnostics
VS Code syntax highlighting
UXM_LANGUAGE_SPEC.md
```

---

## 3. `@!N` host meta çağrısı kesinleştirilmeli

Floating point macro sisteminde bu şart oldu.

Kural:

```text
@210   macro varsa macro açılır
@!210  macro’ya bakmadan host runtime meta servisi çağrılır
@#     aktif hücredeki değeri meta id kabul eder
```

Bu kural olmadan `m210={@210}` sonsuz macro expansion’a girer. O yüzden `@!N` artık dil standardına eklenmeli.

---

## 4. FP sistemi için kalan bilimsel fonksiyonlar

Temel decimal floating point sistemi oluştu:

```text
FP_INIT16
FP_INIT32
FP_FROM_INT
FP_FROM_DEC_STRING
FP_PRINT_DEC
FP_ADD
FP_SUB
FP_MUL
FP_DIV
FP_COMPARE
FP_ABS
FP_NEG
FP_ROUND16
FP_ROUND32
FP_TRUNC
```

Ama bilimsel hesap için şunlar kaldı:

```text
FP_SQRT
FP_HYPOT
FP_SIN
FP_COS
FP_TAN
FP_LOG
FP_EXP
FP_POW
```

Bunları iki yoldan yapabiliriz:

```text
1. Runtime host meta servisleriyle hızlı hesap
2. UXM macro olarak eğitim/deney amaçlı yavaş hesap
```

İlk önce `FP_SQRT` ve `FP_HYPOT` yazmak mantıklı. Sonra sin/cos/tan için tablo veya Taylor serisi gelir.

---

## 5. Division testleri genişletilmeli

`FP_DIV` en riskli yer. Şu testler eklenmeli:

```text
1 / 3
10 / 3
100 / 7
-10 / 3
10 / -3
0 / 5
5 / 0
1.25 / 0.5
123456789 / 987
```

Çünkü decimal floating sistemde hata en çok bölmede çıkar.

---

## 6. FP rounding mantığı daha sert test edilmeli

Şunlar test edilmeli:

```text
1.23456789012345674  → FP16
1.23456789012345675  → FP16
9.99999999999999995  → FP16
0.00000000000000009  → FP16
```

Özellikle `999...` yuvarlanınca taşma olabiliyor:

```text
9.9999999999999999 → 10.0000000000000000
```

Bunu ayrıca kontrol etmek gerekir.

---

## 7. Native compiler ile full tool aynı standarda getirilmeli

Şu an üç ayrı katman var:

```text
native compiler
runtime
full tool interpreter
```

Bunların desteklediği dil özellikleri birebir aynı olmalı.

Özellikle şunlar eşitlenmeli:

```text
(D@...) adresleme
@!N host meta
FP macro çağrıları
UIR formatı
optimizer davranışı
branch davranışı
status/flags isimleri
```

Yoksa IDE’de çalışan kod native build’de farklı davranabilir.

---

## 8. VS Code eklentisi güncellenmeli

VS Code eklentisine şu yeni özellikler eklenmeli:

```text
(D@T+N) syntax highlighting
@!N renklendirme
FP macro hover açıklamaları
FP blok görüntüleme
Data alanında FP sayılarını decimal gösterme
ux_fp_v1.uxm snippetleri
Copilot instructions içine UX-FP kuralları
```

Memory watch paneli sadece hücre göstermemeli; FP bloklarını da tanımalı:

```text
D:100  FP16  12.3400000000000000
D:140  FP16   5.6000000000000000
D:180  FP16  17.9400000000000000
```

Bu çok güzel olur.

---

## 9. Test runner yazılmalı

Test dosyalarında şunu koymuştuk:

```text
# EXPECT_OUTPUT: AB
```

Artık bir test runner lazım.

Görevi:

```text
tests_full/*.uxm çalıştır
tests_fp/*.uxm çalıştır
EXPECT_OUTPUT satırını oku
gerçek çıktı ile karşılaştır
PASS / FAIL raporu üret
```

Rapor:

```text
test20_fifo_char_order.uxm   PASS
test_fp04_div_int.uxm        PASS
test_fp06_add_dec_string.uxm PASS
```

Bu olmazsa proje büyüdükçe neyin bozulduğunu göremeyiz.

---

## 10. Dokümantasyon güncellenmeli

Kullanma kılavuzuna şu yeni bölümler eklenmeli:

```text
(D@...) dinamik data adresleme
@!N host meta çağrısı
UX-FP V1 decimal floating point sistemi
FP blok yapısı
FP macro listesi
FP örnekleri
FP hata/status kodları
VS Code eklentisi kullanımı
Copilot ile UXM kod yazdırma kuralları
```

---

## 11. Build scriptleri birleştirilmeli

Şu komutları elle yazmak yerine:

```bat
fbc uxm31_compiler_fb_full.bas -x uxm31_compiler_full.exe
uxm31_compiler_full.exe program.uxm build\program.asm build\program.uir.json build\program.opt.json
nasm -f win64 build\program.asm -o build\program.obj
fbc uxm31_runtime_fb_full.bas build\program.obj -x build\program.exe
```

tek script olmalı:

```bat
build_native.bat program.uxm
run_trace.bat program.uxm
run_tests.bat
```

---

## 12. En son yapılacak ama önemli konu: Lisans ve GitHub düzeni

GitHub’a koyacaksak şunlar gerekir:

```text
README.md
LICENSE
CHANGELOG.md
CONTRIBUTING.md
docs/
examples/
tests/
```

Lisans için muhtemelen **MIT** uygun olur. Ama runtime/compiler senin projen olduğu için istersen daha kontrollü bir lisans da seçilebilir.

---

# Kısa cevap

Evet, kalan işler var ama artık “fikir” değil, **entegrasyon ve sağlamlaştırma işleri** kaldı.

En önemli 5 iş şunlar:

```text
1. (D@...) adreslemeyi compiler + interpreter + VS Code eklentisine gömmek.
2. @!N host meta çağrısını kesin standarda almak.
3. UX-FP V1 servislerini runtime’a tam bağlamak.
4. FP testlerini ve genel test runner’ı yazmak.
5. VS Code eklentisine FP ve memory watch desteğini eklemek.
```

Bence sıradaki en doğru adım:

```text
uxm31_compiler_fb_full.bas
uxm31_runtime_fb_full.bas
uxm31_full_tool_fb.bas
```

üçünü **tek standarda göre yeniden toparlamak**. Yani parçaları artık yamalı anlatmak yerine, “V3.1 Full Final” dosyaları olarak düzenlemek.
