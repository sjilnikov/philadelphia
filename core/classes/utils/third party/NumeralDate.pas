unit NumeralDate;

interface

  function NumeralStr(Num : Extended; Mask : String;
                      Pad : Word;
                      Rod1, Rod2 : Word;   //падеж (1..6) и род (1..3) целой и дроброй
                      Dpl : Word;          //кол. знаков после запятой
                      N1, N2, N3,          //три формы наименования в соотв. падеже
                      D1, D2, D3 : String  //три формы наименования дробной ед.
                      ) : String;

          { в маске служебные символы:
              чч - место размещения число прописью
              цц - место размещения числа цифрами
              нн - место наименования целой части числа
              дд - место расположения дробной части числа цифрами
              пп - место дробной единицы прописью,
                   если кол.знаков после зап. больше 3,
                   то выводится все равно цифрами
              ии - место вывода наименования дробной ед.
           заглавные-строчные различаются;
           любые другие символы, встречающиеся в маске выводятся как есть.

           Три формы наименования определяются по правилу: 1-2-5.
              Для рублей: 1 рубль, 2 рубля, 5 рублей, тогда в параметрах
              N1 = "рубль", N2 = "рубля" и N3 = "рублей".
           Если все три формы наименования совпадают, то в N2 и N3 передаются
           пустые строки, если две последние формы совпадают, то в N3 передается
           пустая строка.
           Эти же правила распространяются и на наименования дробной части числа.

           Примеры вызова функции:
  NumeralStr(25.01, 'ЧЧ нн ПП ии', 1, 1, 2, 2, 'рубль', 'рубля', 'рублей', 'копейка', 'копейки', 'копеек');
      Именительный падеж, результат: "ДВАДЦАТЬ ПЯТЬ рублей ОДНА копейка"
ДВАДЦАТЬЮ ПЯТЬЮ километрами и ПЯТЬЮСТАМИ метрами

  NumeralStr(59.26, 'У нас нет ЧЧ нн ПП ии', 2, 1, 2, 2, 'рубля', 'рублей', '', 'копейки', 'копеек', '');
      Родительный падеж, результат: "У нас нет ПЯТЬДЕСЯТИ ДЕВЯТИ рублей ДВАДЦАТИ ШЕСТИ копеек"
  NumeralStr(25.01, 'Отправить ЧЧ нн ПП ии', 3, 1, 2, 2, 'рубль', 'рубля', 'рублей', 'копейку', 'копейки', 'копеек');
      Винительный падеж, результат: "Отправить ДВАДЦАТЬ ПЯТЬ рублей ОДНУ копейку"

  NumeralStr(129.22, 'Предпочтение ЧЧ нн ПП ии', 4, 1, 2, 2, 'рублю', 'рублям', '', 'копейке', 'копейкам', '');
      Дательный падеж, результат: "Предпочтение CТА ДВАДЦАТИ ДЕВЯТИ рублям ДВАДЦАТИ ДВУМ копейкам"
  NumeralStr(25.51, 'Расплатился ЧЧ нн и ПП ии', 5, 1, 2, 2, 'рублем', 'рублями', '', 'копейкой', 'копейками', '');
      Творительный падеж, результат: "Расплатился ДВАДЦАТЬЮ ПЯТЬЮ рублями и ПЯТИДЕСЯТЬЮ ОДНОЙ копейкой"
  NumeralStr(25.41, 'Расскажем о ЧЧ нн ПП ии', 6, 1, 2, 2, 'рубле', 'рублях', '', 'копейке', 'копейках', '');
      Предложный падеж, результат "Расскажем о ДВАДЦАТИ ПЯТИ рублях СОРОКА ОДНОЙ копейке"

  NumeralStr(21, 'Представлено на ЧЧ нн', 6, 1, 2, 0, 'листе', 'листах', '', '', '', '');
      Вывод целочисленного числительного, результат: "Представлено на ДВАДЦАТИ ОДНОМ листе"

  NumeralStr(25.500, 'ЧЧ нн и ПП ии', 5, 1, 1, 3, 'километром', 'километрами', '', 'метром', 'метрами', '');

           }

  //прописью с одним наименованием, например:
  //Одна целая и две десятых километра
  function NumeralStrOneName(Num : Extended; Mask : String;
                 Pad : Word;
                 Dpl : Word;          {кол. знаков после запятой}
                 RoditPad : String) : String; {род.падеж наименования}

  function DateTime2String(Dt : TDateTime; const Mask : String) : String;
     {гг - год 2 цифры
      гггг - год 4 цифры
      мм - месяц цифрами с лидир. нулем
      Мм - месяц цифрами без нуля
      ммм - месяц сокращенно 3-мя буквами
      мммм - месяц буквами полностью
      ррр - месяц буквами сокращенно, родительный падеж
      рррр - месяц полностью, родительный падеж
      дд - день цифрами с лидир. нулем
      Дд - день цифрами без нуля
      ддд - день прописью
      нн - день недели двумя буквами
      ннн - день недели тремя буквами
      нннн - день недели полностью
        при:
          мммм, ммм, ррр, ддд, нн, ннн, нннн - в выходной строке буквы строчные
          если в маске строчные, первая заглавная, если в маске
          первая заглавная и все заглавные, если в маске все заглавные
      чч - часы
      тт - минуты
     }

implementation

uses SysUtils, DateUtils;

type
  TNumeralRec = record
    es : array[1..19] of String;
    ds : array[2..9] of String;
    cs : array[1..9] of String;
    ts : array[1..5] of String;
    ms : array[1..3] of String;
    ok : array[1..3] of String;
  end;

resourcestring
  es1i = 'один'; es2i = 'два'; es3i = 'три'; es4i = 'четыре'; es5i = 'пять';
  es6i = 'шесть'; es7i = 'семь'; es8i = 'восемь'; es9i = 'девять';
  es10i = 'десять'; es11i = 'одиннадцать'; es12i = 'двенадцать';
  es13i = 'тринадцать'; es14i = 'четырнадцать'; es15i = 'пятнадцать';
  es16i = 'шестнадцать'; es17i = 'семнадцать'; es18i = 'восемнадцать';
  es19i = 'девятнадцать';

  es1r = 'одного'; es2r = 'двух'; es3r = 'трех'; es4r = 'четырех'; es5r = 'пяти';
  es6r = 'шести'; es7r = 'семи'; es8r = 'восеми'; es9r = 'девяти'; es10r = 'десяти';
  es11r = 'одиннадцати'; es12r = 'двенадцати'; es13r = 'тринадцати';
  es14r = 'четырнадцати'; es15r = 'пятнадцати'; es16r = 'шестнадцати';
  es17r = 'семнадцати'; es18r = 'восемнадцати'; es19r = 'девятнадцати';

  es1d = 'одному'; es2d = 'двум'; es3d = 'трем'; es4d = 'четырем';

  es1t = 'одним'; es2t = 'двумя'; es3t = 'тремя'; es4t = 'четырьмя'; es5t = 'пятью';
  es6t = 'шестью'; es7t = 'семью'; es8t = 'восемью'; es9t = 'девятью';
  es10t = 'десятью'; es11t = 'одиннадцатью'; es12t = 'двенадцатью';
  es13t = 'тринадцатью'; es14t = 'четырнадцатью'; es15t = 'пятнадцатью';
  es16t = 'шестнадцатью'; es17t = 'семнадцатью'; es18t = 'восемнадцатью';
  es19t = 'девятнадцатью';

  ds20i = 'двадцать'; ds30i = 'тридцать'; ds40i = 'сорок'; ds50i = 'пятьдесят';
  ds60i = 'шестьдесят'; ds70i = 'семьдесят'; ds80i = 'восемьдесят'; ds90i = 'девяносто';

  ds20r = 'двадцати'; ds30r = 'тридцати'; ds40r = 'сорока'; ds50r = 'пятьдесяти';
  ds60r = 'шестьдесяти'; ds70r = 'семьдесяти'; ds80r = 'восьмидесяти';
  ds90r = 'девяноста';

  ds20t = 'двадцатью'; ds30t = 'тридцатью'; ds40t = 'сорока'; ds50t = 'пятидесятью';
  ds60t = 'шестидесятью'; ds70t = 'семидесятью'; ds80t = 'восьмидесятью';
  ds90t = 'девяноста';

  cs100i = 'cто'; cs200i = 'двести'; cs300i = 'триста'; cs400i = 'четыреста';
  cs500i = 'пятьсот'; cs600i = 'шестьсот'; cs700i = 'семьсот'; cs800i = 'восемьсот';
  cs900i = 'девятьсот';

  cs100r = 'cта'; cs200r = 'двухсот'; cs300r = 'трехсот'; cs400r = 'четырехсот';
  cs500r = 'пятисот'; cs600r = 'шестисот'; cs700r = 'семисот'; cs800r = 'восмисот';
  cs900r = 'девятисот';

  cs100d = 'cта'; cs200d = 'двумстам'; cs300d = 'тремстам'; cs400d = 'четырехстам';
  cs500d = 'пятистам'; cs600d = 'шестистам'; cs700d = 'семистам';
  cs800d = 'восьмистам'; cs900d = 'девятистам';

  cs200t = 'двумястами'; cs300t = 'тремястами'; cs400t = 'четырехстами';
  cs500t = 'пятьюстами'; cs600t = 'шестьюстами'; cs700t = 'семьюстами';
  cs800t = 'восмьюстами'; cs900t = 'девятьюстами';

  cs200p = 'двухстах'; cs300p = 'трехстах'; cs400p = 'четырехстах';
  cs500p = 'пятистах'; cs600p = 'шестистах'; cs700p = 'семистах';
  cs800p = 'восмистах'; cs900p = 'девятистах';

  ts1i = 'одна тысяча'; ts2i = 'две тысячи'; ts3i = 'тысячи';
  ts4i = 'тысячи'; ts5i = 'тысяч';

  ts1r = 'одной тысячи'; ts2r = 'двух тысяч';
  ts1v = 'одну тысячу';

  ts1d = 'одной тысяче'; ts2d = 'двум тысячам'; ts3d = 'тысячам';

  ts1t = 'одной тысячью'; ts2t = 'двум тысячами'; ts3t = 'тысячами';
  ts2p = 'двух тысячах'; ts3p = 'тысячах';

  ms1i = 'триллион'; ms2i = 'миллиард'; ms3i = 'миллион';
{
('миллион','миллиона','миллионов'),
('миллиард','миллиарда','миллиардов'),
('триллион','триллиона','триллионов'),
('квадриллион','квадриллиона','квадриллионов'),
('квинтиллион','квинтиллиона','квинтиллионов'),
('секстиллион','секстиллиона','секстиллионов'),
('сентиллион','сентиллиона','сентиллионов'),
('октиллион','октиллиона','октиллионов'),
('нониллион','нониллиона','нониллионов'),
('дециллион','дециллиона','дециллионов'),
('ундециллион','ундециллиона','ундециллионов'),
('додециллион','додециллиона','додециллионов'));
}
  ok1 = ''; ok2 = 'а'; ok3 = 'ов';
  ok1d = 'у'; ok2d = 'ам'; ok3d = 'ам';
  ok1t = 'ом'; ok2t = 'ами';
  ok1p = 'е'; ok2p = 'ах';


const
  NumeralArr : array[1..6, 1..3] of TNumeralRec =
{M} ( //именительный
     ((es:(es1i,es2i,es3i,es4i,es5i,es6i,es7i,es8i,es9i, es10i,es11i,es12i,es13i,es14i,es15i,es16i,es17i,es18i,es19i);
       ds:(ds20i,ds30i,ds40i,ds50i,ds60i,ds70i,ds80i,ds90i);
       cs:(cs100i,cs200i,cs300i,cs400i,cs500i,cs600i,cs700i,cs800i,cs900i);
       ts:(ts1i, ts2i, ts3i, ts4i, ts5i);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1, ok2, ok3)
       ),
{Ж}    (es:('одна','две',es3i,es4i,es5i,es6i,es7i,es8i,es9i, es10i,es11i,es12i,es13i,es14i,es15i,es16i,es17i,es18i,es19i);
       ds:(ds20i,ds30i,ds40i,ds50i,ds60i,ds70i,ds80i,ds90i);
       cs:(cs100i,cs200i,cs300i,cs400i,cs500i,cs600i,cs700i,cs800i,cs900i);
       ts:(ts1i, ts2i, ts3i, ts4i, ts5i);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1, ok2, ok3)
       ),
{C}    (es:('одно',es2i,es3i,es4i,es5i,es6i,es7i,es8i,es9i, es10i,es11i,es12i,es13i,es14i,es15i,es16i,es17i,es18i,es19i);
       ds:(ds20i,ds30i,ds40i,ds50i,ds60i,ds70i,ds80i,ds90i);
       cs:(cs100i,cs200i,cs300i,cs400i,cs500i,cs600i,cs700i,cs800i,cs900i);
       ts:(ts1i, ts2i, ts3i, ts4i, ts5i);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1, ok2, ok3)
       )),
       //родительный
{M}   ((es:(es1r,es2r,es3r,es4r,es5r,es6r,es7r,es8r,es9r, es10r,es11r,es12r,es13r,es14r,es15r,es16r,es17r,es18r,es19r);
       ds:(ds20r,ds30r,ds40r,ds50r,ds60r,ds70r,ds80r,ds90r);
       cs:(cs100r,cs200r,cs300r,cs400r,cs500r,cs600r,cs700r,cs800r,cs900r);
       ts:(ts1r, ts2r, ts5i, ts5i, ts5i);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok2, ok3, ok3)
       ),
{Ж}    (es:('одной',es2r,es3r,es4r,es5r,es6r,es7r,es8r,es9r, es10r,es11r,es12r,es13r,es14r,es15r,es16r,es17r,es18r,es19r);
       ds:(ds20r,ds30r,ds40r,ds50r,ds60r,ds70r,ds80r,ds90r);
       cs:(cs100r,cs200r,cs300r,cs400r,cs500r,cs600r,cs700r,cs800r,cs900r);
       ts:(ts1r, ts2r, ts5i, ts5i, ts5i);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok2, ok3, ok3)
       ),
{C}    (es:(es1r,es2r,es3r,es4r,es5r,es6r,es7r,es8r,es9r, es10r,es11r,es12r,es13r,es14r,es15r,es16r,es17r,es18r,es19r);
       cs:(cs100r,cs200r,cs300r,cs400r,cs500r,cs600r,cs700r,cs800r,cs900r);
       ts:(ts1r, ts2r, ts5i, ts5i, ts5i);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok2, ok3, ok3)
       )),
       //винительный
{M}   ((es:(es1i,es2i,es3i,es4i,es5i,es6i,es7i,es8i,es9i, es10i,es11i,es12i,es13i,es14i,es15i,es16i,es17i,es18i,es19i);
       ds:(ds20i,ds30i,ds40i,ds50i,ds60i,ds70i,ds80i,ds90i);
       cs:(cs100i,cs200i,cs300i,cs400i,cs500i,cs600i,cs700i,cs800i,cs900i);
       ts:(ts1v, ts2i, ts3i, ts4i, ts5i);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1, ok2, ok3)
       ),
{Ж}    (es:('одну','две',es3i,es4i,es5i,es6i,es7i,es8i,es9i, es10i,es11i,es12i,es13i,es14i,es15i,es16i,es17i,es18i,es19i);
       ds:(ds20i,ds30i,ds40i,ds50i,ds60i,ds70i,ds80i,ds90i);
       cs:(cs100i,cs200i,cs300i,cs400i,cs500i,cs600i,cs700i,cs800i,cs900i);
       ts:(ts1v, ts2i, ts3i, ts4i, ts5i);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1, ok2, ok3)
       ),
{C}    (es:('одно',es2i,es3i,es4i,es5i,es6i,es7i,es8i,es9i, es10i,es11i,es12i,es13i,es14i,es15i,es16i,es17i,es18i,es19i);
       ds:(ds20i,ds30i,ds40i,ds50i,ds60i,ds70i,ds80i,ds90i);
       cs:(cs100i,cs200i,cs300i,cs400i,cs500i,cs600i,cs700i,cs800i,cs900i);
       ts:(ts1v, ts2i, ts3i, ts4i, ts5i);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1, ok2, ok3)
       )),
       //дательный
{M}  ((es:(es1d,es2d,es3d,es4d,es5r,es6r,es7r,es8r,es9r, es10r,es11r,es12r,es13r,es14r,es15r,es16r,es17r,es18r,es19r);
       ds:(ds20r,ds30r,ds40r,ds50r,ds60r,ds70r,ds80r,ds90r);
       cs:(cs100d,cs200d,cs300d,cs400d,cs500d,cs600d,cs700d,cs800d,cs900d);
       ts:(ts1d, ts2d, ts3d, ts3d, ts3d);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1d, ok2d, ok3d)
       ),
{Ж}   (es:('одной',es2d,es3d,es4d,es5r,es6r,es7r,es8r,es9r, es10r,es11r,es12r,es13r,es14r,es15r,es16r,es17r,es18r,es19r);
       ds:(ds20r,ds30r,ds40r,ds50r,ds60r,ds70r,ds80r,ds90r);
       cs:(cs100d,cs200d,cs300d,cs400d,cs500d,cs600d,cs700d,cs800d,cs900d);
       ts:(ts1d, ts2d, ts3d, ts3d, ts3d);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1d, ok2d, ok3d)
       ),
{C}   (es:(es1d,es2d,es3d,es4d,es5r,es6r,es7r,es8r,es9r, es10r,es11r,es12r,es13r,es14r,es15r,es16r,es17r,es18r,es19r);
       ds:(ds20r,ds30r,ds40r,ds50r,ds60r,ds70r,ds80r,ds90r);
       cs:(cs100d,cs200d,cs300d,cs400d,cs500d,cs600d,cs700d,cs800d,cs900d);
       ts:(ts1d, ts2d, ts3d, ts3d, ts3d);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1d, ok2d, ok3d)
       )),
       //творительный
{M}   ((es:(es1t,es2t,es3t,es4t,es5t,es6t,es7t,es8t,es9t, es10t,es11t,es12t,es13t,es14t,es15t,es16t,es17t,es18t,es19t);
       ds:(ds20t,ds30t,ds40t,ds50t,ds60t,ds70t,ds80t,ds90t);
       cs:(cs100d, cs200t,cs300t,cs400t,cs500t,cs600t,cs700t,cs800t,cs900t);
       ts:(ts1t, ts2t, ts3t, ts3t, ts3t);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1t, ok2t, ok2t)
       ),
{Ж}    (es:('одной',es2t,es3t,es4t,es5t,es6t,es7t,es8t,es9t, es10t,es11t,es12t,es13t,es14t,es15t,es16t,es17t,es18t,es19t);
       ds:(ds20t,ds30t,ds40t,ds50t,ds60t,ds70t,ds80t,ds90t);
       cs:(cs100d, cs200t,cs300t,cs400t,cs500t,cs600t,cs700t,cs800t,cs900t);
       ts:(ts1t, ts2t, ts3t, ts3t, ts3t);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1t, ok2t, ok2t)
       ),
{C}    (es:('одним',es2t,es3t,es4t,es5t,es6t,es7t,es8t,es9t, es10t,es11t,es12t,es13t,es14t,es15t,es16t,es17t,es18t,es19t);
       ds:(ds20t,ds30t,ds40t,ds50t,ds60t,ds70t,ds80t,ds90t);
       cs:(cs100d, cs200t,cs300t,cs400t,cs500t,cs600t,cs700t,cs800t,cs900t);
       ts:(ts1t, ts2t, ts3t, ts3t, ts3t);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1t, ok2t, ok2t)
       )),
       //предложный
{M}   ((es:('одном',es2r,es3r,es4r,es5r,es6r,es7r,es8r,es9r, es10r,es11r,es12r,es13r,es14r,es15r,es16r,es17r,es18r,es19r);
       ds:(ds20r,ds30r,ds40r,ds50r,ds60r,ds70r,ds80r,ds90r);
       cs:(cs100d, cs200p,cs300p,cs400p,cs500p,cs600p,cs700p,cs800p,cs900p);
       ts:(ts1d, ts2p, ts3p, ts3p, ts3p);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1p, ok2p, ok2p)
       ),
{Ж}    (es:('одной',es2r,es3r,es4r,es5r,es6r,es7r,es8r,es9r, es10r,es11r,es12r,es13r,es14r,es15r,es16r,es17r,es18r,es19r);
       ds:(ds20r,ds30r,ds40r,ds50r,ds60r,ds70r,ds80r,ds90r);
       cs:(cs100d, cs200p,cs300p,cs400p,cs500p,cs600p,cs700p,cs800p,cs900p);
       ts:(ts1d, ts2p, ts3p, ts3p, ts3p);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1p, ok2p, ok2p)
       ),
{C}    (es:('одном',es2r,es3r,es4r,es5r,es6r,es7r,es8r,es9r, es10r,es11r,es12r,es13r,es14r,es15r,es16r,es17r,es18r,es19r);
       ds:(ds20r,ds30r,ds40r,ds50r,ds60r,ds70r,ds80r,ds90r);
       cs:(cs100d, cs200p,cs300p,cs400p,cs500p,cs600p,cs700p,cs800p,cs900p);
       ts:(ts1d, ts2p, ts3p, ts3p, ts3p);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1p, ok2p, ok2p)
       ))
    );

function RoundNum(Num :Double; DecPos :Integer) :Double;
var
  I :Integer;
begin
  if DecPos > 0 then for I:=1 to DecPos do Num := Num*10
  else for I:=-1 downto DecPos do Num := Num/10;
  if Num >= 0 then Num := Int(Num+0.500000001)
              else Num := Int(Num-0.500000001);
  if DecPos > 0 then for I:=1 to DecPos do Num := Num/10
  else for I:=-1 downto DecPos do Num := Num*10;
  RoundNum := Num;
end;

function FirstUpperCase(const S : String) : String;
begin
  if Length(S) = 0 then Result := S;
  Result := AnsiUpperCase(Copy(S, 1, 1))+Copy(S, 2, Length(S));
end;

  function Convert(NumSt : String; TR : TNumeralRec) : String;
  var
    Temp   : String;
    St     : String;
    Th     : array[1..5] of word;
    I, J   : Integer;
    K      : Word;

    procedure AssignSt;
    begin
      if Temp = '' then Exit;
      If Temp[1] = ' ' Then Delete(Temp, 1,1);
      St := St + Temp;
      if St[Length(St)] <> ' ' then St := St + ' ';
      Temp := '';
    end;

  begin
    St := ''; J := 0; K := 5;
    FillChar(Th, SizeOf(Th), 0);
    for I := Length(NumSt) downto 1 do begin
      Inc(J);
      St := NumSt[I] + St;
      if (J mod 3 = 0) and (J <> 0) then begin
        Th[K] := StrToInt(St); Dec(K); St := '';
      end;
    end;
    if St <> '' then Th[K] := StrToInt(St);

    Temp := ''; St := '';
    for I := 1 to 5 do Begin
      if Th[I] = 0 then continue;
      K := Trunc(Th[I]/100);
      if K >= 1 then begin
        Temp := TR.cs[K]; AssignSt;
        Th[I] := Th[I] - K * 100;
      end;
      if Th[I] >= 20 then begin
        K := Trunc(Th[I]/10);
        Temp := TR.ds[K];  AssignSt;
        Th[I] := Th[I] - K * 10;
      end;
      if Th[I] > 0 then Temp := TR.es[Th[I]];

      if I = 4 then begin
        case Th[I] of
          1 : Temp := TR.ts[1];
          2 : Temp := TR.ts[2];
          3, 4 : Temp := Temp + ' ' + TR.ts[Th[I]];
          else Temp := Temp + ' ' + TR.ts[5];
        end;
      end;
      if I < 5 then AssignSt;

      if I in [1..3] then begin
        if Th[I] = 1 then Temp := Temp + ' ' + TR.ms[I] + TR.ok[1]
        else if Th[I] in [2..4] then Temp := Temp + ' ' + TR.ms[I] + TR.ok[2]
        else Temp := Temp + ' ' + TR.ms[I] + TR.ok[3];
      end;
      if I < 5 then AssignSt;
    end;

    St := St + Temp;
    if St[Length(St)] = ' ' then Delete(St, Length(St), 1);
    Convert := St;
  end;

function NumeralStr(Num : Extended; Mask : String; Pad, Rod1, Rod2,
                    Dpl : Word; N1, N2, N3, D1, D2, D3 : String) : String;
var I,j  : Integer;
    sLen : Byte;
    s, s1: String;
    NumS, Tran : String[20];
    Tr1, TR2 : TNumeralRec;
begin
  Result := '';
  if not (Pad in [1..6]) then Pad := 1;
  if not (Rod1 in [1..3]) then Rod1 := 1;
  if not (Rod2 in [1..3]) then Rod2 := 1;
  TR1 := NumeralArr[Pad, Rod1];
  TR2 := NumeralArr[Pad, Rod2];
  sLen := Length(Mask);

  NumS := FloatToStrF(Num, ffFixed, 18, Dpl);

  j := Pos('.', NumS);
  if j = 0 then j := Pos(',', NumS);
  if j > 0 then begin
    Tran := Copy(NumS, j+1, Length(NumS)-j);
    NumS := Copy(NumS, 1, j-1);
  end else Tran := '';

  s := ''; I := 1;
  if NumS[1] = '-' then begin
    s := 'минус ';
    Delete(NumS, 1, 1);
  end;
  if Mask <> '' then begin
    while I <= sLen do begin
      if AnsiUpperCase(Copy(Mask, I, 2)) = 'ЧЧ' then begin
        if NumS = '0' then s1 := 'ноль' else s1 := Convert(NumS, TR1);
        if Mask[I] = 'Ч' then s1 := FirstUpperCase(s1);
        if Mask[I+1] = 'Ч' then s1 := AnsiUpperCase(s1);
        s := s + s1;
        Inc(I, 2);
        continue;
      end;

      if (AnsiUpperCase(Copy(Mask, I, 2)) = 'ЦЦ') then begin
        s := s + NumS;
        Inc(I, 2);
        continue;
      end;

      if AnsiUpperCase(Copy(Mask, I, 2)) = 'НН' then begin
        if (Length(NumS) = 1) or (NumS[Length(NumS)-1] <> '1') then begin
          case NumS[Length(NumS)] of
            '1'      : s1 := N1;
            '2'..'4' : if N2 <> '' then s1 := N2 else s1 := N1;
            else
              if N3 <> '' then s1 := N3
                          else
                            if N2 <> '' then s1 := N2 else s1 := N1;
          end;
        end else
          if N3 <> '' then s1 := N3
                      else
                        if N2 <> '' then s1 := N2 else s1 := N1;

        if Mask[I] = 'Н' then s1 := FirstUpperCase(s1);
        if Mask[I+1] = 'Н' then s1 := AnsiUpperCase(s1);
        s := s + s1;
        Inc(I, 2);
        continue;
      end;

      if AnsiUpperCase(Copy(Mask, I, 2)) = 'ИИ' then begin
        if (Length(Tran) = 1) or (Tran[Length(Tran)-1] <> '1') then begin
          case Tran[Length(Tran)] of
            '1' : s1 := D1;
            '2'..'4' : if D2 <> '' then s1 := D2 else s1 := D1;
            else
              if D3 <> '' then s1 := D3
                          else
                            if D2 <> '' then s1 := D2 else s1 := D1;
          end;
        end else
          if D3 <> '' then s1 := D3
                      else
                        if D2 <> '' then s1 := D2 else s1 := D1;

        if Mask[I] = 'И' then s1 := FirstUpperCase(s1);
        if Mask[I+1] = 'И' then s1 := AnsiUpperCase(s1);
        s := s + s1;
        Inc(I, 2);
        continue;
      end;

      if (AnsiUpperCase(Copy(Mask, I, 2)) = 'ДД') then begin
        if (Mask[I] = 'Д') and (Length(Tran) > 0) and (Tran[1] = '0') then
          s := s + Copy(Tran, 2, 100)
        else
          s := s + Tran;
        Inc(I, 2);
        continue;
      end;

      if (AnsiUpperCase(Copy(Mask, I, 2)) = 'ПП') then begin
        if Dpl <= 3 then begin
          if (Tran <> '') and (Pos(StringOfChar('0', Dpl), Tran) = 0) then begin
            s1 := Convert(Tran, TR2);
            if Mask[I] = 'П' then s1 := FirstUpperCase(s1);
            if Mask[I+1] = 'П' then s1 := AnsiUpperCase(s1);
          end else s1 := Tran;
          s := s + s1;
        end else s := s + Tran;
        Inc(I, 2);
        continue;
      end;

      s := s + Mask[I];
      Inc(I);
    end;
  end;

  Result := s;
end;

const
  okc1 = 'ая'; okc2 = 'ых'; okc1r = 'ой'; okc1d = 'ым'; okc1t = 'ыми';
  okc1v = 'ую';
  NumeralONArr : array[1..6] of
    record c1, c2, d1, d2 : string; end =
      ((c1:okc1; c2:okc2; d1:okc1; d2:okc2),
       (c1:okc1r; c2:okc2; d1:okc1r; d2:okc2),
       (c1:okc1v; c2:okc2; d1:okc1v; d2:okc2),
       (c1:okc1r; c2:okc1d; d1:okc1r; d2:okc1d),
       (c1:okc1r; c2:okc1t; d1:okc1r; d2:okc1t),
       (c1:okc1r; c2:okc2; d1:okc1r; d2:okc2));

function NumeralStrOneName(Num : Extended; Mask : String;
                           Pad, Dpl : Word;
                           RoditPad : String) : String;
var I, F : Extended;
    NS, S : String;
    K : Integer;
begin
  I := Int(Num);
  F := Frac(Num);
  Result := '';
  if Dpl > 3 then Dpl := 3;
  Result := NumeralStr(I, Mask, Pad, 2, 2, 0, '', '', '', '', '', '');
  NS := FloatToStrF(I, ffGeneral, 18, 0);
  if NS[Length(NS)] = '1' then S := 'цел'+NumeralONArr[Pad].c1
                          else S := 'цел'+NumeralONArr[Pad].c2;
  S := ' ' + S + ' и ';
  Result := TrimRight(Result) + S;
  if F <> 0 then
    S := NumeralStr(Abs(F), 'пп', Pad, 2, 2, Dpl,
                    '', '', '', '', '', '')
  else S := 'ноль';

  F := RoundNum(Abs(F), Dpl);
  NS := FloatToStrF(F, ffFixed, 18, Dpl);
  K := Pos('.', NS);
  if K = 0 then begin
    K := Pos(',', NS);
  end;
  if K = 0 then Exit;
  NS := Copy(NS, K+1, 255);
  S := S + ' ';
  case Length(NS) of
    1 : if NS[Length(NS)] = '1' then S := S + 'десят'+NumeralONArr[Pad].d1
                                else S := S + 'десят'+NumeralONArr[Pad].d2;
    2 : if NS[Length(NS)] = '1' then S := S + 'сот'+NumeralONArr[Pad].d1
                                else S := S + 'сот'+NumeralONArr[Pad].d2;
    3 : if NS[Length(NS)] = '1' then S := S + 'тысячн'+NumeralONArr[Pad].d1
                                else S := S + 'тысячн'+NumeralONArr[Pad].d2;
  end;
  Result := Result + S + ' ' + RoditPad;
end;

{ DateTime2String }

const
  UpperChars : set of Char = ['Г','М','Р','Д','Н','Ч','Т'];
  LowerChars : set of Char = ['г','м','р','д','н','ч','т'];

const
  MJan = 'янв'; MFeb = 'фев'; MMar = 'мар'; MApr = 'апр';
  MMay = 'май'; MJun = 'июн'; MJul = 'июл'; MAug = 'авг';
  MSep = 'сен'; MOct = 'окт'; MNov = 'ноя'; MDec = 'дек'; MMayR = 'мая';

  MFJan = 'январ'; MFFeb = 'феврал'; MFMar = 'март'; MFApr = 'апрел';
  MFAug = 'август'; MFSep = 'сентябр'; MFOct = 'октябр'; MFNov = 'ноябр';
  MFDec = 'декабр';

const
  Month3Arr : array[1..12] of String =
    (MJan, MFeb, MMar, MApr, MMay, MJun, MJul, MAug, MSep, MOct, MNov, MDec);
  Month3ArrR : array[1..12] of String =
    (MJan, MFeb, MMar, MApr, MMayR, MJun, MJul, MAug, MSep, MOct, MNov, MDec);
  MonthFullArr : array[1..12] of String =
    (MFJan+'ь', MFFeb+'ь', MFMar, MFApr+'ь', MMay, MJun+'ь', MJul+'ь',
     MFAug, MFSep+'ь', MFOct+'ь', MFNov+'ь', MFDec+'ь');
  MonthFullArrR : array[1..12] of String =
    (MFJan+'я', MFFeb+'я', MFMar+'а', MFApr+'я', MMayR, MJun+'я', MJul+'я',
     MFAug+'а', MFSep+'я', MFOct+'я', MFNov+'я', MFDec+'я');
  DaysString : array[1..20] of string =
    ('первое','второе','третье','четвертое','пятое','цестое','седьмое',
     'восьмое','девятое','десятое','одиннадцатое','двенадцатое',
     'тринадцатое','четырнадцатое','пятнадцатое','шестнадцатое',
     'семнадцатое','восемнадцатое','девятнадцатое','двадцатое');

  WeekString : array[1..7, 2..4] of string =
    (('пн','пон','понедельник'),('вт','втр','вторник'),
     ('ср','срд','среда'),('чт','чтв','четверг'),
     ('пт','птн','пятница'),('сб','суб','суббота'),
     ('вс','вск','воскресенье'));

function DateTime2String(Dt : TDateTime; const Mask : String) : String;
var P, LenM, LenT : Integer;
    MaskF, Token, Res, S : String;
    AYear, AMon, ADay, AHour, AMin, ASecond, AMilliSecond: Word;
    NoTime : Boolean;

  function ValidNext : Boolean;
  var I : Integer;
  begin
    I := P+1;
    while (I <= LenM) and (MaskF[I] = MaskF[P]) do Inc(I);
    Result := I > P+1;
    if Result then Token := Copy(Mask, P, I-P);
  end;

  function NextToken : Boolean;
  begin
    Token := '';
    while P <= LenM do begin
      if (MaskF[P] in LowerChars) and ValidNext then begin
        Inc(P, Length(Token)); break;
      end else begin
        Res := Res + Mask[P]; Inc(P);
      end;
    end;
    Result := Token <> '';
  end;

  function ULStr(const St : String) : String;
  begin
    Result := St;
    if (Token[1] in UpperChars) and (Token[2] in UpperChars) then
      Result := AnsiUpperCase(St);
    if (Token[1] in UpperChars) and (Token[2] in LowerChars) then
      Result := FirstUpperCase(St)
  end;

begin
  Res := '';
  if Mask = '' then begin
    if Round(Dt) <> 0 then Result := DateTimeToStr(Dt) else Result := '';
    Exit;
  end;
  DecodeDateTime(Dt, AYear, AMon, ADay, AHour, AMin, ASecond, AMilliSecond);
  MaskF := AnsiLowerCase(Mask);

  LenM := Length(Mask);
  P := 1; NoTime := True;
  while NextToken do begin
    LenT := Length(Token);
    case Token[1] of
      'г' : begin
        S := IntToStr(AYear);
        if LenT = 4 then Res := Res + S else Res := Res + Copy(S, 3, 255);
      end;
      'м', 'М', 'р', 'Р' : begin
        if LenT = 2 then begin
          S := IntToStr(AMon);
          if (Token[1] = 'м') and (AMon < 10) then S := '0'+S; Res := Res + S;
        end;
        if LenT = 3 then begin
          if Token[1] in ['м','М'] then
            S := ULStr(Month3Arr[AMon])
          else
            S := ULStr(Month3ArrR[AMon]);
          Res := Res + S;
        end;
        if LenT = 4 then begin
          if Token[1] in ['м','М'] then
            S := ULStr(MonthFullArr[AMon])
          else
            S := ULStr(MonthFullArrR[AMon]);
          Res := Res + S;
        end;
      end;
      'д', 'Д' : begin
        if LenT = 2 then begin
          S := IntToStr(ADay);
          if (Token[1] = 'д') and (ADay < 10) then S := '0'+S; Res := Res + S;
        end;
        if LenT = 3 then begin
          case ADay of
            1..20 : S := ULStr(DaysString[ADay]);
            21..29 : S := ULStr('двадцать '+DaysString[ADay-20]);
            30 : S := ULStr('тридцатое');
            31 : S := ULStr('тридцать '+DaysString[ADay-30]);
          end;
          Res := Res + S;
        end;
      end;
      'н', 'Н' : begin
        if LenT > 4 then LenT := 4;
        Res := Res + UlStr(WeekString[DayOfTheWeek(Dt), LenT])
      end;
      'ч','Ч' : begin
        S := IntToStr(AHour);
        if (Token[1] = 'ч') and (AHour < 10) then S := '0'+S; Res := Res + S;
        NoTime := False;
      end;
      'т','Т' : begin
        S := IntToStr(AMin);
        if (Token[1] = 'т') and (Amin < 10) then S := '0'+S; Res := Res + S;
        NoTime := False;
      end;
    end;
  end;
  if (Round(Dt) = 0) and NoTime then Res := '';

  Result := Res;
end;

end.
