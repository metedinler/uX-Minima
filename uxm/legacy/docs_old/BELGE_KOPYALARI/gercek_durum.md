# Önemli gerçek durum

Bu FreeBASIC sürümde şu parçalar gerçek olarak var:

```
.uxm kaynak okuma
UTF-8 BOM temizleme
#mode, #cell, #memory, #bounds, #overflow, #compare, #endian pragma okuma
64 KB memory layout kontrolü
byte/word/dword hücre modeli
sN string tanımı
pN string basma
m128..m255 macro tanımı
@N sabit meta çağrı
@# dinamik meta çağrı
() adresleme
: branch
[] loop
stack push/pop
status byte
flags word
NASM x64 ASM üretimi
FreeBASIC runtime linkleme
```

## Şu parçalar hâlâ sonraki gerçek geliştirme adımıdır:

```
JSON trace
UIR dışa aktarma
pattern optimizer
IDE protokolü
runtime macro call stack
FIFO meta servisleri
data block copy / sort servisleri
wild mode memory layout değiştirme
```

## Bu noktada elindeki gerçek dosya seti:
```
uxm31_compiler_fb.bas
uxm31_runtime_fb.bas
build_all.bat
build_one.bat
run_tests.bat
tests\*.uxm
```

Derleme sırası:

```
build_all.bat
run_tests.bat
```

İlk elle deneme:

```code
build_all.bat
build_one.bat tests\test05_meta_add.uxm
```

Buradan sonraki sağlam adım, bu FreeBASIC compiler dosyasına gerçek JSON trace + UIR export eklemek olur.