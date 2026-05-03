# UX-MINIMA Math Extensions V1
Bu ek paket UX-MINIMA V3.1 için polinom ve RPN expression matematik katmanını tanımlar.
## Macro servisleri
```text
m240 / @!240 POLY_DERIV
m241 / @!241 POLY_INTEGRAL
m242 / @!242 POLY_EVAL
m243 / @!243 POLY_PRINT
m244 / @!244 POLY_CLEAR
m250 / @!250 EXPR_EVAL
m251 / @!251 NUM_DERIV
m252 / @!252 NUM_INTEGRAL_TRAP
m253 / @!253 NUM_INTEGRAL_SIMPSON
m254 / @!254 EXPR_PRINT_RPN
```
## ARGE parse komutları
```text
#poly BASE = c0,c1,c2,c3,...
#expr-rpn BASE = x 2 pow 3 x mul add 2 add
```
`#poly` küçük dereceden büyük dereceye katsayı kabul eder. Örnek: `#poly 100 = 2,4,6,8` ifadesi `2 + 4x + 6x^2 + 8x^3` demektir.
`#expr-rpn` RPN token listesi kabul eder. Sayılar otomatik `CONST` tokenına çevrilir.
## Expression tokenları
```text
x
add veya +
sub veya -
mul veya *
div veya /
pow
sin
cos
tan
exp
log
sqrt
neg
abs
```
## Frame kuralları
Polinom türev:
```text
T-2 = destination poly base
T-1 = source poly base
@240
```
Polinom integral:
```text
T-2 = destination poly base
T-1 = source poly base
T   = integration constant C
@241
```
Polinom eval:
```text
T-2 = poly base
T-1 = x
@242 -> T+1 result
```
Expression eval:
```text
T-2 = expr base
T-1 = x
@250 -> T+1 result
```
Sayısal türev:
```text
T-2 = expr base
T-1 = x
T   = h
@251 -> T+1 result
```
Trapez/Simpson integral:
```text
T-4 = expr base
T-3 = a
T-2 = b
T-1 = n
@252 veya @253 -> T+1 result
```
## Not
Bu ilk sürüm integer/fixed-point eğitim sürümüdür. Daha hassas hesap için UX-FP V1 decimal floating point katmanı ile bağlanmalıdır.
