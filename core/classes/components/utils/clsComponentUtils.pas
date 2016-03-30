unit clsComponentUtils;

interface
uses
  windows,
  math,
  classes,
  sysUtils,
  extCtrls,
  controls,
  graphics,
  stdCtrls;

type
  cComponentUtils = class
  public
    class function  getWidthForString(aFont: tFont; aString: string): integer;
    class function  getControlByName(aControl: tWinControl; aName: string): tControl;
    class function  getMemoTextHeight(aMemo: tMemo): integer;
    class function  getMemoTextWidth(aMemo: tMemo): integer;

    class procedure copyCanvasFields(aSource: tCanvas; aDestination: tCanvas);
    class function  getWidthForStrings(aCanvas: tCanvas; aStrings: tStrings): integer;
  end;


implementation

class function cComponentUtils.getMemoTextHeight(aMemo: tMemo): integer;
const
  MARGIN = 10;
var
  lineHeight: integer;
  DC: HDC;
  saveFont : hFont;
  metrics : tTextMetric;
  lineCount: integer;
begin
  result:= 0;

  DC := getDC(aMemo.handle);
  saveFont := selectObject(DC, aMemo.font.handle);
  getTextMetrics(DC, metrics);
  selectObject(DC, saveFont);
  releaseDC(aMemo.handle, DC);
  lineHeight := metrics.tmHeight;

  lineCount := aMemo.lines.count;
  if lineCount < 1 then
    lineCount := 1;
  result:= lineCount * lineHeight + 2 * MARGIN;
end;

class function cComponentUtils.getMemoTextWidth(aMemo: tMemo): integer;
const
  margin = 5;
var
  tmpCanvas: tControlCanvas;
  i: integer;
  maxWidth: integer;
begin
  result:= 0;
  tmpCanvas:= tControlCanvas.create;
  try
    tmpCanvas.handle:= getWindowDC(aMemo.handle);
    tmpCanvas.font.assign(aMemo.font);
    tmpCanvas.control:= aMemo;

    tmpCanvas.updateTextFlags;

    maxWidth:= 0;
    for i:= 0 to aMemo.lines.count - 1 do begin
      maxWidth:= max(maxWidth, tmpCanvas.textWidth(aMemo.lines[i]));
    end;

    result:= maxWidth + 2 * margin;

  finally
    freeAndNil(tmpCanvas);
  end;
end;

class function cComponentUtils.getWidthForStrings(aCanvas: tCanvas; aStrings: tStrings): integer;
var
  itemText: string;
  itemTextWidth: integer;

  i: integer;
begin
  result:= 0;
  itemText:= '';
  for i:= 0 to aStrings.count - 1 do begin
    itemText:= aStrings[i];
    itemTextWidth:= aCanvas.textWidth(itemText);

    if (itemTextWidth > result) then begin
      result:= aCanvas.textWidth(itemText);
    end;
  end;
end;

class function cComponentUtils.getWidthForString(aFont: tFont; aString: string): integer;
var
  bitmap: tBitmap; //use for allow canvas drawing
begin
  bitmap:= tBitmap.create;
  try
    bitmap.canvas.font.assign(aFont);

    result:= bitmap.canvas.textWidth(aString);
  finally
    freeAndNil(bitmap);
  end;
end;

class procedure cComponentUtils.copyCanvasFields(aSource, aDestination: tCanvas);
begin
  aDestination.brush.assign(aSource.brush);
  aDestination.copyMode:= aSource.copyMode;
  aDestination.font.assign(aSource.font);
  aDestination.pen.assign(aSource.pen);
end;

class function cComponentUtils.getControlByName(aControl: tWinControl; aName: string): tControl;
  var
    i: integer;
begin
  result:= nil;

  for i := 0 to aControl.controlCount - 1 do begin
    result:= aControl.controls[i];

    if (result.name = aName) then begin
      break;
    end;
  end;
end;


end.
