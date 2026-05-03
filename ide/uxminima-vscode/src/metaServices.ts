export interface MetaServiceInfo {
  id: number;
  name: string;
  frame: string;
  description: string;
}

export const META_SERVICES: Record<number, MetaServiceInfo> = {
  0: { id: 0, name: "OK / no-op", frame: "none", description: "Status OK kabul edilir." },
  1: { id: 1, name: "CLS", frame: "none", description: "Ekranı temizler." },
  2: { id: 2, name: "LOCATE 1,1", frame: "none", description: "Cursor'u başlangıca alır." },
  3: { id: 3, name: "RANDOM BYTE", frame: "T+1=result", description: "Rastgele byte üretir." },
  4: { id: 4, name: "TIMER", frame: "T+1=result", description: "Timer tabanlı değer üretir." },
  5: { id: 5, name: "NEWLINE", frame: "none", description: "Yeni satır basar." },
  9: { id: 9, name: "STATUS READ", frame: "T+1=status", description: "Status değerini sonuç hücresine yazar." },
  10: { id: 10, name: "STATUS CLEAR", frame: "none", description: "Status/ERR bayrağını temizler." },
  12: { id: 12, name: "STATUS PRINT", frame: "none", description: "Status açıklamasını basar." },
  20: { id: 20, name: "ADD", frame: "T-2 + T-1 -> T+1", description: "Toplama yapar." },
  21: { id: 21, name: "SUB", frame: "T-2 - T-1 -> T+1", description: "Çıkarma yapar." },
  22: { id: 22, name: "MUL", frame: "T-2 * T-1 -> T+1", description: "Çarpma yapar." },
  23: { id: 23, name: "DIV", frame: "T-2 / T-1 -> T+1", description: "Bölme yapar. Sıfıra bölmede status=15." },
  24: { id: 24, name: "MOD", frame: "T-2 mod T-1 -> T+1", description: "Kalan hesaplar." },
  40: { id: 40, name: "SIN", frame: "sin(T-1) -> T+1", description: "Derece cinsinden sinüs. Byte ölçekte 100." },
  41: { id: 41, name: "COS", frame: "cos(T-1) -> T+1", description: "Derece cinsinden cos." },
  42: { id: 42, name: "TAN", frame: "tan(T-1) -> T+1", description: "Derece cinsinden tan." },
  43: { id: 43, name: "HYPOT", frame: "sqrt((T-2)^2+(T-1)^2) -> T+1", description: "Hipotenüs hesaplar." },
  60: { id: 60, name: "PRINT ARG2", frame: "T-1", description: "Arg2 değerini decimal basar." },
  61: { id: 61, name: "PRINT RESULT", frame: "T+1", description: "Sonuç hücresini decimal basar." },
  64: { id: 64, name: "PRINT SPACE", frame: "none", description: "Boşluk basar." },
  80: { id: 80, name: "SET POINTER", frame: "T-1 -> P", description: "Pointer'ı arg2 değerine taşır." },
  82: { id: 82, name: "GET POINTER", frame: "P -> T+1", description: "Pointer değerini sonuç hücresine yazar." },
  84: { id: 84, name: "TAPE CELLS", frame: "T+1", description: "Tape cell sayısını döndürür." },
  85: { id: 85, name: "DATA CELLS", frame: "T+1", description: "Data cell sayısını döndürür." },
  86: { id: 86, name: "STACK CELLS", frame: "T+1", description: "Stack cell sayısını döndürür." },
  89: { id: 89, name: "PRINT LAYOUT", frame: "none", description: "Bellek layout bilgisini basar." },
  90: { id: 90, name: "FIFO PUSH", frame: "T-1", description: "Arg2 değerini FIFO kuyruğuna atar." },
  91: { id: 91, name: "FIFO POP", frame: "T+1", description: "FIFO kuyruğundan ilk değeri alır." },
  92: { id: 92, name: "FIFO PEEK", frame: "T+1", description: "FIFO ilk değerini çıkarmadan okur." },
  93: { id: 93, name: "FIFO COUNT", frame: "T+1", description: "FIFO eleman sayısını döndürür." },
  94: { id: 94, name: "FIFO CLEAR", frame: "none", description: "FIFO kuyruğunu temizler." },
  95: { id: 95, name: "DATA READ", frame: "D[T-1] -> T+1", description: "Data alanından okur." },
  96: { id: 96, name: "DATA WRITE", frame: "D[T-2] = T-1", description: "Data alanına yazar." },
  97: { id: 97, name: "DATA DIGIT", frame: "D[T-1] ASCII digit -> T+1", description: "ASCII rakamı sayıya çevirir." },
  98: { id: 98, name: "DATA BLOCK COPY", frame: "src=T-2 dst=T-1 count=T", description: "Data blok kopyalar." },
  99: { id: 99, name: "DATA BLOCK CLEAR", frame: "dst=T-2 count=T-1", description: "Data blok temizler." },
  100: { id: 100, name: "TAPE SORT ASC", frame: "start=T-2 count=T-1", description: "Tape aralığını küçükten büyüğe sıralar." },
  101: { id: 101, name: "TAPE SORT DESC", frame: "start=T-2 count=T-1", description: "Tape aralığını büyükten küçüğe sıralar." },
  102: { id: 102, name: "DATA SORT ASC", frame: "start=T-2 count=T-1", description: "Data aralığını küçükten büyüğe sıralar." },
  103: { id: 103, name: "DATA SORT DESC", frame: "start=T-2 count=T-1", description: "Data aralığını büyükten küçüğe sıralar." },
  104: { id: 104, name: "TAPE SEARCH", frame: "start=T-2 count=T-1 target=T -> T+1", description: "Tape lineer arama." },
  105: { id: 105, name: "DATA SEARCH", frame: "start=T-2 count=T-1 target=T -> T+1", description: "Data lineer arama." },
  106: { id: 106, name: "TAPE BLOCK COPY", frame: "src=T-2 dst=T-1 count=T", description: "Tape blok kopyalar." },
  107: { id: 107, name: "TAPE BLOCK CLEAR", frame: "dst=T-2 count=T-1", description: "Tape blok temizler." },
  120: { id: 120, name: "UNSIGNED MODE", frame: "none", description: "Unsigned moda geçer." },
  121: { id: 121, name: "SIGNED MODE", frame: "none", description: "Signed moda geçer." },
  122: { id: 122, name: "SIGNED QUERY", frame: "T+1", description: "Signed mod açık mı döndürür." },
  123: { id: 123, name: "LITTLE ENDIAN", frame: "none", description: "Little endian moda geçer." },
  124: { id: 124, name: "BIG ENDIAN", frame: "none", description: "Big endian moda geçer." },
  125: { id: 125, name: "ENDIAN QUERY", frame: "T+1", description: "Endian bayrağını döndürür." },
  126: { id: 126, name: "FLAGS QUERY", frame: "T+1", description: "Flags word değerini döndürür." },
  127: { id: 127, name: "WILD LAYOUT CHANGE", frame: "tapeKB=T-2 stackKB=T-1 dataKB=T", description: "Sadece wild mode: bellek layout değiştirir." }
};

export function metaMarkdown(id: number): string {
  const m = META_SERVICES[id];
  if (!m) {
    if (id >= 128 && id <= 255) {
      return `@${id}: kullanıcı macro alanı. Native compiler tarafında compile-time inline, full tool tarafında runtime macro call-stack.`;
    }
    return `@${id}: tanımsız meta servis.`;
  }
  return `**@${m.id} ${m.name}**\n\nFrame: \`${m.frame}\`\n\n${m.description}`;
}
