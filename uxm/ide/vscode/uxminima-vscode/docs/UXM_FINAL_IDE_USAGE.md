# UX-MINIMA Final ARGE IDE Kullanımı

Final compiler tek merkezli çalışır:

```bat
uxm31_compiler_final.exe --input program.uxm --mode all --asm build\program.asm --uir build\program.uir.json --diag build\program.diag.json --trace build\program.trace.ndjson --opt build\program.opt.json
```

VS Code eklentisi bu komutu otomatik üretir.

## Step modu

```bat
uxm31_compiler_final.exe --input program.uxm --mode step --trace build\program.trace.ndjson --max-steps 1000
```

Trace dosyası NDJSON biçimindedir. Memory Watch paneli bu dosyadan `step`, `ip`, `op`, `ptr`, `sp`, `fifo_count`, `status`, `flags`, `current` alanlarını okur.

## ARGE pragma örneği

```text
#arge version
#arge json on
#arge step on
#arge trace on
#arge watch tape=0:32
#arge watch data=100:40
```

## Dinamik data adresleme

```text
0(T-2)+k100
0(D@(T-2)+8)+k65
.(D@(T-2)+8)
```

## Host meta zorlama

```text
m210={@!210}
```

`@!210`, macro genişletmesini bypass edip runtime/host meta servisini çağırır.
