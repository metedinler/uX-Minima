# V3 Kod Gerçekliği Planı

Bu plan belgeye göre değil, dosya gerçekliğine göre yazılmıştır.

## V2 geçerlilik kararı

V2'nin ana çalışma ağacı, legacy taşıma ve test/build ayrımı geçerlidir. Fakat V2 şu noktalarda eksikti:

- Benzer isimli dosyalar arasında kesin kanonik dosya seçimi yoktu.
- Kullanıcının izlediği iki matris klasörü aktif sistem olarak korunmamıştı.
- Büyük kodların parçalanma sırası ve hedef modül adları yoktu.
- Full tool dosyalarının kırık/markdown karışık olduğu yeterince sert ayrılmamıştı.

V3 bunları düzeltir.

## Kök gerçeklik

Kanonik çalışma kökü `uxm/` olacaktır. Eski kök bir depo çöp kutusu gibi kalmayacak.

## Kanonik kod gerçekliği

Native çalışan hat:

- `uxm31_compiler_fb.bas`
- `uxm31_runtime_fb_full.bas`
- `runtime/runtime_fp_services.bas`
- `math_extensions/runtime/runtime_matrix_services.bas`
- `math_extensions/runtime/runtime_math_services.bas`

Final/ARGE onarım hattı:

- `final/uxm31_compiler_final.bas`
- `math_extensions/compiler/arge_parse_math_additions.bas`
- `math_extensions/compiler/arge_parse_matrix_additions.bas`

IDE hattı:

- `ide/uxminima-vscode/package.json`
- `ide/uxminima-vscode/src/*.ts`
- `ide/uxminima-vscode/syntaxes`, `snippets`, `docs`, `examples`

Karantina:

- `uxm31_full_tool_fb.bas`
- `uxm31_full_tool_fb_2.bas`
- `legacy/duplicates/tools/uxm31_full_tool_fb.bas`

## Çalışma sırası

1. Çalışma klasörü temizlenir.
2. Kanonik kod taşınır.
3. Eski belgeler legacy'ye alınır.
4. Matris klasörleri aktif rapor klasörüne alınır.
5. Native build/test ayağa kaldırılır.
6. Runtime full servis bağlantıları düzeltilir.
7. Final compiler derleme hataları onarılır.
8. VSCode pathleri yeni düzene bağlanır.
9. Büyük dosyalar modüllere bölünür.
10. Her adımda matrisler güncellenir.
