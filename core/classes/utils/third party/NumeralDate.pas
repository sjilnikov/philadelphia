unit NumeralDate;

interface

  function NumeralStr(Num : Extended; Mask : String;
                      Pad : Word;
                      Rod1, Rod2 : Word;   //����� (1..6) � ��� (1..3) ����� � �������
                      Dpl : Word;          //���. ������ ����� �������
                      N1, N2, N3,          //��� ����� ������������ � �����. ������
                      D1, D2, D3 : String  //��� ����� ������������ ������� ��.
                      ) : String;

          { � ����� ��������� �������:
              �� - ����� ���������� ����� ��������
              �� - ����� ���������� ����� �������
              �� - ����� ������������ ����� ����� �����
              �� - ����� ������������ ������� ����� ����� �������
              �� - ����� ������� ������� ��������,
                   ���� ���.������ ����� ���. ������ 3,
                   �� ��������� ��� ����� �������
              �� - ����� ������ ������������ ������� ��.
           ���������-�������� �����������;
           ����� ������ �������, ������������� � ����� ��������� ��� ����.

           ��� ����� ������������ ������������ �� �������: 1-2-5.
              ��� ������: 1 �����, 2 �����, 5 ������, ����� � ����������
              N1 = "�����", N2 = "�����" � N3 = "������".
           ���� ��� ��� ����� ������������ ���������, �� � N2 � N3 ����������
           ������ ������, ���� ��� ��������� ����� ���������, �� � N3 ����������
           ������ ������.
           ��� �� ������� ���������������� � �� ������������ ������� ����� �����.

           ������� ������ �������:
  NumeralStr(25.01, '�� �� �� ��', 1, 1, 2, 2, '�����', '�����', '������', '�������', '�������', '������');
      ������������ �����, ���������: "�������� ���� ������ ���� �������"
��������� ����� ����������� � ���������� �������

  NumeralStr(59.26, '� ��� ��� �� �� �� ��', 2, 1, 2, 2, '�����', '������', '', '�������', '������', '');
      ����������� �����, ���������: "� ��� ��� ���������� ������ ������ �������� ����� ������"
  NumeralStr(25.01, '��������� �� �� �� ��', 3, 1, 2, 2, '�����', '�����', '������', '�������', '�������', '������');
      ����������� �����, ���������: "��������� �������� ���� ������ ���� �������"

  NumeralStr(129.22, '������������ �� �� �� ��', 4, 1, 2, 2, '�����', '������', '', '�������', '��������', '');
      ��������� �����, ���������: "������������ C�� �������� ������ ������ �������� ���� ��������"
  NumeralStr(25.51, '����������� �� �� � �� ��', 5, 1, 2, 2, '������', '�������', '', '��������', '���������', '');
      ������������ �����, ���������: "����������� ��������� ����� ������� � ����������� ����� ��������"
  NumeralStr(25.41, '��������� � �� �� �� ��', 6, 1, 2, 2, '�����', '������', '', '�������', '��������', '');
      ���������� �����, ��������� "��������� � �������� ���� ������ ������ ����� �������"

  NumeralStr(21, '������������ �� �� ��', 6, 1, 2, 0, '�����', '������', '', '', '', '');
      ����� �������������� �������������, ���������: "������������ �� �������� ����� �����"

  NumeralStr(25.500, '�� �� � �� ��', 5, 1, 1, 3, '����������', '�����������', '', '������', '�������', '');

           }

  //�������� � ����� �������������, ��������:
  //���� ����� � ��� ������� ���������
  function NumeralStrOneName(Num : Extended; Mask : String;
                 Pad : Word;
                 Dpl : Word;          {���. ������ ����� �������}
                 RoditPad : String) : String; {���.����� ������������}

  function DateTime2String(Dt : TDateTime; const Mask : String) : String;
     {�� - ��� 2 �����
      ���� - ��� 4 �����
      �� - ����� ������� � �����. �����
      �� - ����� ������� ��� ����
      ��� - ����� ���������� 3-�� �������
      ���� - ����� ������� ���������
      ��� - ����� ������� ����������, ����������� �����
      ���� - ����� ���������, ����������� �����
      �� - ���� ������� � �����. �����
      �� - ���� ������� ��� ����
      ��� - ���� ��������
      �� - ���� ������ ����� �������
      ��� - ���� ������ ����� �������
      ���� - ���� ������ ���������
        ���:
          ����, ���, ���, ���, ��, ���, ���� - � �������� ������ ����� ��������
          ���� � ����� ��������, ������ ���������, ���� � �����
          ������ ��������� � ��� ���������, ���� � ����� ��� ���������
      �� - ����
      �� - ������
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
  es1i = '����'; es2i = '���'; es3i = '���'; es4i = '������'; es5i = '����';
  es6i = '�����'; es7i = '����'; es8i = '������'; es9i = '������';
  es10i = '������'; es11i = '�����������'; es12i = '����������';
  es13i = '����������'; es14i = '������������'; es15i = '����������';
  es16i = '�����������'; es17i = '����������'; es18i = '������������';
  es19i = '������������';

  es1r = '������'; es2r = '����'; es3r = '����'; es4r = '�������'; es5r = '����';
  es6r = '�����'; es7r = '����'; es8r = '������'; es9r = '������'; es10r = '������';
  es11r = '�����������'; es12r = '����������'; es13r = '����������';
  es14r = '������������'; es15r = '����������'; es16r = '�����������';
  es17r = '����������'; es18r = '������������'; es19r = '������������';

  es1d = '������'; es2d = '����'; es3d = '����'; es4d = '�������';

  es1t = '�����'; es2t = '�����'; es3t = '�����'; es4t = '��������'; es5t = '�����';
  es6t = '������'; es7t = '�����'; es8t = '�������'; es9t = '�������';
  es10t = '�������'; es11t = '������������'; es12t = '�����������';
  es13t = '�����������'; es14t = '�������������'; es15t = '�����������';
  es16t = '������������'; es17t = '�����������'; es18t = '�������������';
  es19t = '�������������';

  ds20i = '��������'; ds30i = '��������'; ds40i = '�����'; ds50i = '���������';
  ds60i = '����������'; ds70i = '���������'; ds80i = '�����������'; ds90i = '���������';

  ds20r = '��������'; ds30r = '��������'; ds40r = '������'; ds50r = '����������';
  ds60r = '�����������'; ds70r = '����������'; ds80r = '������������';
  ds90r = '���������';

  ds20t = '���������'; ds30t = '���������'; ds40t = '������'; ds50t = '�����������';
  ds60t = '������������'; ds70t = '�����������'; ds80t = '�������������';
  ds90t = '���������';

  cs100i = 'c��'; cs200i = '������'; cs300i = '������'; cs400i = '���������';
  cs500i = '�������'; cs600i = '��������'; cs700i = '�������'; cs800i = '���������';
  cs900i = '���������';

  cs100r = 'c��'; cs200r = '�������'; cs300r = '�������'; cs400r = '����������';
  cs500r = '�������'; cs600r = '��������'; cs700r = '�������'; cs800r = '��������';
  cs900r = '���������';

  cs100d = 'c��'; cs200d = '��������'; cs300d = '��������'; cs400d = '�����������';
  cs500d = '��������'; cs600d = '���������'; cs700d = '��������';
  cs800d = '����������'; cs900d = '����������';

  cs200t = '����������'; cs300t = '����������'; cs400t = '������������';
  cs500t = '����������'; cs600t = '�����������'; cs700t = '����������';
  cs800t = '�����������'; cs900t = '������������';

  cs200p = '��������'; cs300p = '��������'; cs400p = '�����������';
  cs500p = '��������'; cs600p = '���������'; cs700p = '��������';
  cs800p = '���������'; cs900p = '����������';

  ts1i = '���� ������'; ts2i = '��� ������'; ts3i = '������';
  ts4i = '������'; ts5i = '�����';

  ts1r = '����� ������'; ts2r = '���� �����';
  ts1v = '���� ������';

  ts1d = '����� ������'; ts2d = '���� �������'; ts3d = '�������';

  ts1t = '����� �������'; ts2t = '���� ��������'; ts3t = '��������';
  ts2p = '���� �������'; ts3p = '�������';

  ms1i = '��������'; ms2i = '��������'; ms3i = '�������';
{
('�������','��������','���������'),
('��������','���������','����������'),
('��������','���������','����������'),
('�����������','������������','�������������'),
('�����������','������������','�������������'),
('�����������','������������','�������������'),
('����������','�����������','������������'),
('���������','����������','�����������'),
('���������','����������','�����������'),
('���������','����������','�����������'),
('�����������','������������','�������������'),
('�����������','������������','�������������'));
}
  ok1 = ''; ok2 = '�'; ok3 = '��';
  ok1d = '�'; ok2d = '��'; ok3d = '��';
  ok1t = '��'; ok2t = '���';
  ok1p = '�'; ok2p = '��';


const
  NumeralArr : array[1..6, 1..3] of TNumeralRec =
{M} ( //������������
     ((es:(es1i,es2i,es3i,es4i,es5i,es6i,es7i,es8i,es9i, es10i,es11i,es12i,es13i,es14i,es15i,es16i,es17i,es18i,es19i);
       ds:(ds20i,ds30i,ds40i,ds50i,ds60i,ds70i,ds80i,ds90i);
       cs:(cs100i,cs200i,cs300i,cs400i,cs500i,cs600i,cs700i,cs800i,cs900i);
       ts:(ts1i, ts2i, ts3i, ts4i, ts5i);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1, ok2, ok3)
       ),
{�}    (es:('����','���',es3i,es4i,es5i,es6i,es7i,es8i,es9i, es10i,es11i,es12i,es13i,es14i,es15i,es16i,es17i,es18i,es19i);
       ds:(ds20i,ds30i,ds40i,ds50i,ds60i,ds70i,ds80i,ds90i);
       cs:(cs100i,cs200i,cs300i,cs400i,cs500i,cs600i,cs700i,cs800i,cs900i);
       ts:(ts1i, ts2i, ts3i, ts4i, ts5i);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1, ok2, ok3)
       ),
{C}    (es:('����',es2i,es3i,es4i,es5i,es6i,es7i,es8i,es9i, es10i,es11i,es12i,es13i,es14i,es15i,es16i,es17i,es18i,es19i);
       ds:(ds20i,ds30i,ds40i,ds50i,ds60i,ds70i,ds80i,ds90i);
       cs:(cs100i,cs200i,cs300i,cs400i,cs500i,cs600i,cs700i,cs800i,cs900i);
       ts:(ts1i, ts2i, ts3i, ts4i, ts5i);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1, ok2, ok3)
       )),
       //�����������
{M}   ((es:(es1r,es2r,es3r,es4r,es5r,es6r,es7r,es8r,es9r, es10r,es11r,es12r,es13r,es14r,es15r,es16r,es17r,es18r,es19r);
       ds:(ds20r,ds30r,ds40r,ds50r,ds60r,ds70r,ds80r,ds90r);
       cs:(cs100r,cs200r,cs300r,cs400r,cs500r,cs600r,cs700r,cs800r,cs900r);
       ts:(ts1r, ts2r, ts5i, ts5i, ts5i);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok2, ok3, ok3)
       ),
{�}    (es:('�����',es2r,es3r,es4r,es5r,es6r,es7r,es8r,es9r, es10r,es11r,es12r,es13r,es14r,es15r,es16r,es17r,es18r,es19r);
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
       //�����������
{M}   ((es:(es1i,es2i,es3i,es4i,es5i,es6i,es7i,es8i,es9i, es10i,es11i,es12i,es13i,es14i,es15i,es16i,es17i,es18i,es19i);
       ds:(ds20i,ds30i,ds40i,ds50i,ds60i,ds70i,ds80i,ds90i);
       cs:(cs100i,cs200i,cs300i,cs400i,cs500i,cs600i,cs700i,cs800i,cs900i);
       ts:(ts1v, ts2i, ts3i, ts4i, ts5i);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1, ok2, ok3)
       ),
{�}    (es:('����','���',es3i,es4i,es5i,es6i,es7i,es8i,es9i, es10i,es11i,es12i,es13i,es14i,es15i,es16i,es17i,es18i,es19i);
       ds:(ds20i,ds30i,ds40i,ds50i,ds60i,ds70i,ds80i,ds90i);
       cs:(cs100i,cs200i,cs300i,cs400i,cs500i,cs600i,cs700i,cs800i,cs900i);
       ts:(ts1v, ts2i, ts3i, ts4i, ts5i);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1, ok2, ok3)
       ),
{C}    (es:('����',es2i,es3i,es4i,es5i,es6i,es7i,es8i,es9i, es10i,es11i,es12i,es13i,es14i,es15i,es16i,es17i,es18i,es19i);
       ds:(ds20i,ds30i,ds40i,ds50i,ds60i,ds70i,ds80i,ds90i);
       cs:(cs100i,cs200i,cs300i,cs400i,cs500i,cs600i,cs700i,cs800i,cs900i);
       ts:(ts1v, ts2i, ts3i, ts4i, ts5i);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1, ok2, ok3)
       )),
       //���������
{M}  ((es:(es1d,es2d,es3d,es4d,es5r,es6r,es7r,es8r,es9r, es10r,es11r,es12r,es13r,es14r,es15r,es16r,es17r,es18r,es19r);
       ds:(ds20r,ds30r,ds40r,ds50r,ds60r,ds70r,ds80r,ds90r);
       cs:(cs100d,cs200d,cs300d,cs400d,cs500d,cs600d,cs700d,cs800d,cs900d);
       ts:(ts1d, ts2d, ts3d, ts3d, ts3d);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1d, ok2d, ok3d)
       ),
{�}   (es:('�����',es2d,es3d,es4d,es5r,es6r,es7r,es8r,es9r, es10r,es11r,es12r,es13r,es14r,es15r,es16r,es17r,es18r,es19r);
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
       //������������
{M}   ((es:(es1t,es2t,es3t,es4t,es5t,es6t,es7t,es8t,es9t, es10t,es11t,es12t,es13t,es14t,es15t,es16t,es17t,es18t,es19t);
       ds:(ds20t,ds30t,ds40t,ds50t,ds60t,ds70t,ds80t,ds90t);
       cs:(cs100d, cs200t,cs300t,cs400t,cs500t,cs600t,cs700t,cs800t,cs900t);
       ts:(ts1t, ts2t, ts3t, ts3t, ts3t);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1t, ok2t, ok2t)
       ),
{�}    (es:('�����',es2t,es3t,es4t,es5t,es6t,es7t,es8t,es9t, es10t,es11t,es12t,es13t,es14t,es15t,es16t,es17t,es18t,es19t);
       ds:(ds20t,ds30t,ds40t,ds50t,ds60t,ds70t,ds80t,ds90t);
       cs:(cs100d, cs200t,cs300t,cs400t,cs500t,cs600t,cs700t,cs800t,cs900t);
       ts:(ts1t, ts2t, ts3t, ts3t, ts3t);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1t, ok2t, ok2t)
       ),
{C}    (es:('�����',es2t,es3t,es4t,es5t,es6t,es7t,es8t,es9t, es10t,es11t,es12t,es13t,es14t,es15t,es16t,es17t,es18t,es19t);
       ds:(ds20t,ds30t,ds40t,ds50t,ds60t,ds70t,ds80t,ds90t);
       cs:(cs100d, cs200t,cs300t,cs400t,cs500t,cs600t,cs700t,cs800t,cs900t);
       ts:(ts1t, ts2t, ts3t, ts3t, ts3t);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1t, ok2t, ok2t)
       )),
       //����������
{M}   ((es:('�����',es2r,es3r,es4r,es5r,es6r,es7r,es8r,es9r, es10r,es11r,es12r,es13r,es14r,es15r,es16r,es17r,es18r,es19r);
       ds:(ds20r,ds30r,ds40r,ds50r,ds60r,ds70r,ds80r,ds90r);
       cs:(cs100d, cs200p,cs300p,cs400p,cs500p,cs600p,cs700p,cs800p,cs900p);
       ts:(ts1d, ts2p, ts3p, ts3p, ts3p);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1p, ok2p, ok2p)
       ),
{�}    (es:('�����',es2r,es3r,es4r,es5r,es6r,es7r,es8r,es9r, es10r,es11r,es12r,es13r,es14r,es15r,es16r,es17r,es18r,es19r);
       ds:(ds20r,ds30r,ds40r,ds50r,ds60r,ds70r,ds80r,ds90r);
       cs:(cs100d, cs200p,cs300p,cs400p,cs500p,cs600p,cs700p,cs800p,cs900p);
       ts:(ts1d, ts2p, ts3p, ts3p, ts3p);
       ms:(ms1i, ms2i, ms3i);
       ok:(ok1p, ok2p, ok2p)
       ),
{C}    (es:('�����',es2r,es3r,es4r,es5r,es6r,es7r,es8r,es9r, es10r,es11r,es12r,es13r,es14r,es15r,es16r,es17r,es18r,es19r);
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
    s := '����� ';
    Delete(NumS, 1, 1);
  end;
  if Mask <> '' then begin
    while I <= sLen do begin
      if AnsiUpperCase(Copy(Mask, I, 2)) = '��' then begin
        if NumS = '0' then s1 := '����' else s1 := Convert(NumS, TR1);
        if Mask[I] = '�' then s1 := FirstUpperCase(s1);
        if Mask[I+1] = '�' then s1 := AnsiUpperCase(s1);
        s := s + s1;
        Inc(I, 2);
        continue;
      end;

      if (AnsiUpperCase(Copy(Mask, I, 2)) = '��') then begin
        s := s + NumS;
        Inc(I, 2);
        continue;
      end;

      if AnsiUpperCase(Copy(Mask, I, 2)) = '��' then begin
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

        if Mask[I] = '�' then s1 := FirstUpperCase(s1);
        if Mask[I+1] = '�' then s1 := AnsiUpperCase(s1);
        s := s + s1;
        Inc(I, 2);
        continue;
      end;

      if AnsiUpperCase(Copy(Mask, I, 2)) = '��' then begin
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

        if Mask[I] = '�' then s1 := FirstUpperCase(s1);
        if Mask[I+1] = '�' then s1 := AnsiUpperCase(s1);
        s := s + s1;
        Inc(I, 2);
        continue;
      end;

      if (AnsiUpperCase(Copy(Mask, I, 2)) = '��') then begin
        if (Mask[I] = '�') and (Length(Tran) > 0) and (Tran[1] = '0') then
          s := s + Copy(Tran, 2, 100)
        else
          s := s + Tran;
        Inc(I, 2);
        continue;
      end;

      if (AnsiUpperCase(Copy(Mask, I, 2)) = '��') then begin
        if Dpl <= 3 then begin
          if (Tran <> '') and (Pos(StringOfChar('0', Dpl), Tran) = 0) then begin
            s1 := Convert(Tran, TR2);
            if Mask[I] = '�' then s1 := FirstUpperCase(s1);
            if Mask[I+1] = '�' then s1 := AnsiUpperCase(s1);
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
  okc1 = '��'; okc2 = '��'; okc1r = '��'; okc1d = '��'; okc1t = '���';
  okc1v = '��';
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
  if NS[Length(NS)] = '1' then S := '���'+NumeralONArr[Pad].c1
                          else S := '���'+NumeralONArr[Pad].c2;
  S := ' ' + S + ' � ';
  Result := TrimRight(Result) + S;
  if F <> 0 then
    S := NumeralStr(Abs(F), '��', Pad, 2, 2, Dpl,
                    '', '', '', '', '', '')
  else S := '����';

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
    1 : if NS[Length(NS)] = '1' then S := S + '�����'+NumeralONArr[Pad].d1
                                else S := S + '�����'+NumeralONArr[Pad].d2;
    2 : if NS[Length(NS)] = '1' then S := S + '���'+NumeralONArr[Pad].d1
                                else S := S + '���'+NumeralONArr[Pad].d2;
    3 : if NS[Length(NS)] = '1' then S := S + '������'+NumeralONArr[Pad].d1
                                else S := S + '������'+NumeralONArr[Pad].d2;
  end;
  Result := Result + S + ' ' + RoditPad;
end;

{ DateTime2String }

const
  UpperChars : set of Char = ['�','�','�','�','�','�','�'];
  LowerChars : set of Char = ['�','�','�','�','�','�','�'];

const
  MJan = '���'; MFeb = '���'; MMar = '���'; MApr = '���';
  MMay = '���'; MJun = '���'; MJul = '���'; MAug = '���';
  MSep = '���'; MOct = '���'; MNov = '���'; MDec = '���'; MMayR = '���';

  MFJan = '�����'; MFFeb = '������'; MFMar = '����'; MFApr = '�����';
  MFAug = '������'; MFSep = '�������'; MFOct = '������'; MFNov = '�����';
  MFDec = '������';

const
  Month3Arr : array[1..12] of String =
    (MJan, MFeb, MMar, MApr, MMay, MJun, MJul, MAug, MSep, MOct, MNov, MDec);
  Month3ArrR : array[1..12] of String =
    (MJan, MFeb, MMar, MApr, MMayR, MJun, MJul, MAug, MSep, MOct, MNov, MDec);
  MonthFullArr : array[1..12] of String =
    (MFJan+'�', MFFeb+'�', MFMar, MFApr+'�', MMay, MJun+'�', MJul+'�',
     MFAug, MFSep+'�', MFOct+'�', MFNov+'�', MFDec+'�');
  MonthFullArrR : array[1..12] of String =
    (MFJan+'�', MFFeb+'�', MFMar+'�', MFApr+'�', MMayR, MJun+'�', MJul+'�',
     MFAug+'�', MFSep+'�', MFOct+'�', MFNov+'�', MFDec+'�');
  DaysString : array[1..20] of string =
    ('������','������','������','���������','�����','������','�������',
     '�������','�������','�������','������������','�����������',
     '�����������','�������������','�����������','������������',
     '�����������','�������������','�������������','���������');

  WeekString : array[1..7, 2..4] of string =
    (('��','���','�����������'),('��','���','�������'),
     ('��','���','�����'),('��','���','�������'),
     ('��','���','�������'),('��','���','�������'),
     ('��','���','�����������'));

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
      '�' : begin
        S := IntToStr(AYear);
        if LenT = 4 then Res := Res + S else Res := Res + Copy(S, 3, 255);
      end;
      '�', '�', '�', '�' : begin
        if LenT = 2 then begin
          S := IntToStr(AMon);
          if (Token[1] = '�') and (AMon < 10) then S := '0'+S; Res := Res + S;
        end;
        if LenT = 3 then begin
          if Token[1] in ['�','�'] then
            S := ULStr(Month3Arr[AMon])
          else
            S := ULStr(Month3ArrR[AMon]);
          Res := Res + S;
        end;
        if LenT = 4 then begin
          if Token[1] in ['�','�'] then
            S := ULStr(MonthFullArr[AMon])
          else
            S := ULStr(MonthFullArrR[AMon]);
          Res := Res + S;
        end;
      end;
      '�', '�' : begin
        if LenT = 2 then begin
          S := IntToStr(ADay);
          if (Token[1] = '�') and (ADay < 10) then S := '0'+S; Res := Res + S;
        end;
        if LenT = 3 then begin
          case ADay of
            1..20 : S := ULStr(DaysString[ADay]);
            21..29 : S := ULStr('�������� '+DaysString[ADay-20]);
            30 : S := ULStr('���������');
            31 : S := ULStr('�������� '+DaysString[ADay-30]);
          end;
          Res := Res + S;
        end;
      end;
      '�', '�' : begin
        if LenT > 4 then LenT := 4;
        Res := Res + UlStr(WeekString[DayOfTheWeek(Dt), LenT])
      end;
      '�','�' : begin
        S := IntToStr(AHour);
        if (Token[1] = '�') and (AHour < 10) then S := '0'+S; Res := Res + S;
        NoTime := False;
      end;
      '�','�' : begin
        S := IntToStr(AMin);
        if (Token[1] = '�') and (Amin < 10) then S := '0'+S; Res := Res + S;
        NoTime := False;
      end;
    end;
  end;
  if (Round(Dt) = 0) and NoTime then Res := '';

  Result := Res;
end;

end.
