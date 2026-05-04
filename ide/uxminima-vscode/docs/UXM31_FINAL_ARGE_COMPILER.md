# UX-MINIMA V3.1 Final ARGE Compiler

Bu paket tek merkezli compiler/tool tasarımıdır.

## Modlar

```bat
uxm31_compiler_final.exe --input program.uxm --mode compile --asm build\program.asm --uir build\program.uir.json --diag build\program.diag.json
uxm31_compiler_final.exe --input program.uxm --mode interpret --trace build\program.trace.ndjson
uxm31_compiler_final.exe --input program.uxm --mode step --trace build\program.trace.ndjson --max-steps 1000
uxm31_compiler_final.exe --ide-in request.json --ide-out response.json
```

## ARGE komutları

Kaynak içinde:

```text
#arge version
#arge json on
#arge interpreter on
#arge step on
#arge trace on
#arge optimize off
#arge watch tape=0:32
#arge watch data=100:40
#arge watch stack=0:16
```

## Dil standardına alınan ekler

```text
(D@T)
(D@T+N)
(D@T-N)
(D@(T-2)+N)
@!N    host meta zorla çağırma
@#     dinamik meta
```

## IDE bağlantısı

IDE request örneği:

```json
{"command":"step","source":"examples/final_probe.uxm","trace":"build/final_probe.trace.ndjson","uir":"build/final_probe.uir.json","diag":"build/final_probe.diag.json"}
```

Compiler response örneği:

```json
{"version":"UX-MINIMA x64 V3.1 FINAL-ARGE","status":0,"diagnostics":0,"instructions":42,"output":"AB"}
```
