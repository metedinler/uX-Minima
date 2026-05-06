# UXM V31 Guvenli Kurtarma Komutlari
# Klasor: calisilan\uxm31_FULL_FINAL_REAL icinde calistir.

New-Item -ItemType Directory -Force reports | Out-Null
git status --short | Set-Content reports\00_before_status.txt -Encoding UTF8
git diff --stat | Set-Content reports\00_before_diffstat.txt -Encoding UTF8
git branch --show-current | Set-Content reports\00_branch.txt -Encoding UTF8

# Aktif .bas dosyalarinda markdown/prose kirliligi ara
rg -n "```|Tamam Mete abi|# Dosya|devam yazarsan|Blogger|Markdown" --glob "*.bas" | Set-Content reports\01_bas_markdown_kirlilik.txt -Encoding UTF8

# Kritik build komutlari - duzeltmelerden sonra calistirilacak
# fbc -lang fb uxm31_compiler_fb.bas -x uxm.exe
# fbc -lang fb uxm31_full_tool_fb.bas -x uxm31_full_tool.exe
# fbc -lang fb final\uxm31_compiler_final.bas -x build\uxm31_compiler_final.exe
# .\run_tests.bat
