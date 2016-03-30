unit clsRangeSlider;

interface
uses
  sysUtils,
  messages,
  windows,
  classes,
  controls,
  extCtrls,
  graphics;

type
  eRangeSlider = class(exception);
  tRangeSlider = class;

  tRangeSliderPositionChangeEvent = procedure(aSender: tObject; aValue : integer) of object;
  tRangeSliderGetRullerLengthEvent = procedure( aSender: tObject; var aValue : integer) of object;

  sRangeSelectPointsArray = record
    origin : tPoint;
    points : array of tPoint;
  end;

  tRangeSliderOrientation = ( rsHorizontal, rsVertical);
  tRangeSliderTickStyle   = ( rsBottomRight, rsTopLeft);
  tRangeSliderThumbStyle  = ( rsStandard, rsTriangle, rsCorner, rsArrow);
  tRangeSliderMoveSliders = ( rsMinSlider, rsMaxSlider, rsBothSliders);

  // Thumbnail bitmap for slider
  cRangeSliderThumbBitmap = class( tBitMap)
  private
    fSlider         : tRangeSlider;
    fOrigin         : tPoint;
    fBkg            : tBitMap;
    fBkgRect        : tRect;
    fInitialDrawing : boolean;
  protected
    property    slider : tRangeSlider read fSlider write fSlider;
  public
    constructor create; override;
    destructor  destroy; override;
    property    origin : tPoint read fOrigin write fOrigin;
    { When true Draw saves initial background and then resets InitialDrawing}
    property    initialDrawing : boolean write fInitialDrawing;
    { draws bitmap on Canvas at Value position
      relative to Ruller's middle line using Origin}
    procedure   draw( aCanvas : tCanvas; aValue : integer; aOrientation : tRangeSliderOrientation);
    function    myPoint( X, Y : integer) : boolean;
    end;

  tRangeSlider = class( tCustomControl)
  private
    fMaxPosition: integer;
    fMinPosition: integer;
    fMax: integer;
    fMin: integer;
    fDrawStep: integer;
    fOrientation: tRangeSliderOrientation;
    fTickStyle: tRangeSliderTickStyle;
    fThumbStyle: tRangeSliderThumbStyle;
    fThumbColor: tColor;

    fOnMinChange: tRangeSliderPositionChangeEvent;
    fOnMaxPosChange: tRangeSliderPositionChangeEvent;
    fOnMaxChange: tRangeSliderPositionChangeEvent;
    fOnMinPosChange: tRangeSliderPositionChangeEvent;
    fOnChange: tNotifyEvent;
    fRullerWidth: integer;
    fOnGetRullerLength: tRangeSliderGetRullerLengthEvent;
    fOnBeforeChange: TNotifyEvent;

    procedure CMEnter(var Message: TCMGotFocus); message CM_ENTER;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;

    procedure setMaxPosition(const aValue: integer);
    procedure setMinPosition(const aValue: integer);
    procedure setMax(const aValue: integer);
    procedure setMin(const aValue: integer);
    procedure setOrientation(const aValue: tRangeSliderOrientation);
    procedure setTickStyle(const aValue: tRangeSliderTickStyle);
    procedure setDrawStep(const aValue: integer);
    procedure setThumbStyle(const aValue: tRangeSliderThumbStyle);
    procedure setRullerWidth(const aValue: integer);
    procedure setOnGetRullerLength(const aValue: tRangeSliderGetRullerLengthEvent);
    procedure setOnBeforeChange(const aValue: TNotifyEvent);
    procedure setThumbColor(const Value: tColor);
  protected
    fDragging: boolean;
    fDragOffset : integer;
    fDragThumb : cRangeSliderThumbBitmap;
    fOldMinPos, fOldMaxPos : integer;
    fGenerateChangeEvent : boolean;
    fScaleFactor : integer;
    fMinThumb, fMaxThumb : cRangeSliderThumbBitmap;
    fThumbPoints : sRangeSelectPointsArray;
    fRullerRect : TRect;
    fPixelsPerStep : double; // pixels per one unit
    fRullerLength : integer; // ruller length

    { preparing Thumbnail Points}
    procedure makePointsArray( aStyle : tRangeSliderThumbStyle);
    function makeThumbPoints( aPA : sRangeSelectPointsArray;
                              aFlip : boolean;
                              aScale : integer;
                              aRotateClockSteps : integer
                              ) : sRangeSelectPointsArray;
    function getThumbDimensions( aPA : sRangeSelectPointsArray) : tPoint;
    procedure createThumbBmp( aBmp : cRangeSliderThumbBitmap; aPA : sRangeSelectPointsArray);

    procedure checkPositionValues;
    procedure moveSlider( aSlider : tRangeSliderMoveSliders; aValue : integer);

    procedure createThumbnails; // Create thumbnail Bitmaps
    procedure calcRullerDimensions;
    procedure drawRuller( aCanvas : TCanvas);
    procedure drawMinThumb( aCanvas : TCanvas);
    procedure drawMaxThumb( aCanvas : TCanvas);

    procedure paint; override;
    procedure keyDown(var Key: Word; Shift: TShiftState); override;
    procedure mouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure mouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure mouseMove(Shift: TShiftState; X, Y: Integer); override;

    property  rullerWidth : integer read fRullerWidth write setRullerWidth;
  public
    constructor create(aOwner: tComponent); override;
    destructor destroy; override;
    property rullerRect : tRect read fRullerRect;
    property rullerLength : integer read fRullerLength;
    function valueToPix( aValue : integer) : integer;
    function aPixToValue( aPix : integer) : integer;
    { Duplicates KeyDown for}
    procedure doKeyDown( var Key: Word; Shift: TShiftState);
  published
    property min : integer read fMin write setMin;
    property max : integer read fMax write setMax;
    property minPosition : integer read fMinPosition write setMinPosition;
    property maxPosition : integer read fMaxPosition write setMaxPosition;
    { If Frequecy = 0 the ticks are autocalculated}
    property drawStep : integer read fDrawStep write setDrawStep default 0;
    property orientation : tRangeSliderOrientation read fOrientation write setOrientation default rsHorizontal;
    property tickStyle : tRangeSliderTickStyle read fTickStyle write setTickStyle default rsBottomRight;
    property thumbStyle : tRangeSliderThumbStyle read fThumbStyle write setThumbStyle default rsStandard;
    property thumbColor: tColor read fThumbColor write setThumbColor default clBtnFace;

    property onMinChange : tRangeSliderPositionChangeEvent read fOnMinChange write fOnMinChange;
    property onMaxChange : tRangeSliderPositionChangeEvent read fOnMaxChange write fOnMaxChange;
    property onMaxPosChange : tRangeSliderPositionChangeEvent read fOnMaxPosChange write fOnMaxPosChange;
    property onMinPosChange : tRangeSliderPositionChangeEvent read fOnMinPosChange write fOnMinPosChange;
    property onChange : tNotifyEvent read fOnChange write fOnChange;
    { If assigned then calculate ruller length and return in Value
      If Value = 0 then autoLength}
    property onGetRullerLength : tRangeSliderGetRullerLengthEvent read fOnGetRullerLength write setOnGetRullerLength;

    { Useful to store values before they changed}
    property onBeforeChange : tNotifyEvent read fOnBeforeChange write setOnBeforeChange;

    {}
    property Align;
    property Anchors;
    property Constraints;
    property Enabled;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
  end;


implementation

const
  { First point (0-index) of this array is Origin}
  mktpStandardPoints : array[0..4] of TPoint = (
    ( X:3; Y:3), ( X:0; Y:0), ( X:3; Y:0), ( X:3; Y:7), ( X:0; Y:4));
  mktpTrianglePoints : array[0..3] of TPoint = (
    ( X:3; Y:3), ( X:3; Y:0), ( X:3; Y:6), ( X:0; Y:3));
  mktpCornerPoints : array[0..3] of TPoint = (
    ( X:6; Y:3), ( X:0; Y:0), ( X:6; Y:0), ( X:6; Y:6));
  mktpArrowPoints : array[0..7] of TPoint = (
    ( X:7; Y:4), ( X:0; Y:3), ( X:3; Y:3), ( X:3; Y:0), ( X:7; Y:4), ( X:3; Y:8), ( X:3; Y:5), ( X:0; Y:5));

const
  transparentColor = clRed;
  minRullerLength = 30;

{ cRangeSlider }

constructor tRangeSlider.create(aOwner: TComponent);
  function createThumbImages : cRangeSliderThumbBitmap;
  begin
    result := cRangeSliderThumbBitmap.create;
    result.slider := Self;
  end;
begin
  inherited;
  doubleBuffered := true;
//  ControlStyle := ControlStyle + [csReplicatable];
  tabStop := true;
  width := 200;
  height := 32;
  fRullerWidth := 11;
  fThumbColor:= clBtnFace;

  fThumbPoints.origin := point( 0, 0);
  fThumbPoints.points := NIL;

  fThumbStyle := rsStandard;
  fOrientation := rsHorizontal;
  fTickStyle := rsBottomRight;
  fMin := 0;
  fMax := 10;
  fMinPosition := fMin;
  fMaxPosition := fMax;
  fGenerateChangeEvent := true;

  fScaleFactor := 3;

  fMinThumb := CreateThumbImages;
  fMaxThumb := CreateThumbImages;

  createThumbnails;
  calcRullerDimensions;
end;

procedure tRangeSlider.createThumbBmp(aBmp: cRangeSliderThumbBitmap; aPA: sRangeSelectPointsArray);
var
  Dimension : TPoint;
  TmpBmp : TBitMap;

  { Works perfect when line degrees are 0, 45, 90, 135, 180 ... }
  procedure MakeEdges( Bmp : TBitMap;
                       PA : sRangeSelectPointsArray;
                       OffsetX, OffsetY : integer;
                       AColor : TColor);
  var Cou : integer; TmpPA : sRangeSelectPointsArray;
  begin
    Bmp.Transparent := true;
    Bmp.TransparentColor := transparentColor;
    SetLength( TmpPA.points, High( PA.points) + 1);
    TmpPA.points := Copy( PA.points, 0, High( PA.points) + 1);
    with Bmp.Canvas do begin
      Brush.Color := Bmp.TransparentColor;
      FillRect( ClipRect);

      Pen.Color := AColor;
      Brush.Color := AColor;
      Polygon( TmpPA.points);

      Pen.Color := {clBlack;} Bmp.TransparentColor;
      Brush.Color := Bmp.TransparentColor;

      for Cou := 0 to High(TmpPA.points) do begin
        TmpPA.points[Cou].X := TmpPA.points[Cou].X + OffsetX;
        TmpPA.points[Cou].Y := TmpPA.points[Cou].Y + OffsetY;
        end;
      Polygon( TmpPA.points);
      end;
  end;

  procedure OverlayBmp( BaseBmp, OverBmp : TBitMap);
  begin BaseBmp.Canvas.Draw( 0, 0, OverBmp); end;

begin
  Dimension := getThumbDimensions( aPA);
  aBmp.Width := Dimension.X;
  aBmp.Height := Dimension.Y;
  aBmp.TransparentColor := transparentColor;
  aBmp.TransparentMode := tmFixed;

  { Draw main polygon}
  with aBmp.Canvas do begin
    Brush.Color := transparentColor;
    Pen.Color := clBtnFace;
    FillRect( ClipRect);
    Brush.Color := fThumbColor;
    Polygon( aPA.points);
    end;

  { Shadows BitMap}
  TmpBmp := TBitMap.Create;
  try
    TmpBmp.Width := Dimension.X;
    TmpBmp.Height := Dimension.Y;

    MakeEdges( TmpBmp, aPA, 0, 1, clBtnHighlight);
    OverlayBmp( aBmp, TmpBmp);
    MakeEdges( TmpBmp, aPA, 1, 0, clBtnHighlight);
    OverlayBmp( aBmp, TmpBmp);
    MakeEdges( TmpBmp, aPA, 0, -1, clBtnShadow);
    OverlayBmp( aBmp, TmpBmp);
    MakeEdges( TmpBmp, aPA, -1, 0, clBtnShadow);
    OverlayBmp( aBmp, TmpBmp);

  finally TmpBmp.Free; end;

  aBmp.origin := aPA.origin;
end;

procedure tRangeSlider.createThumbnails;

  procedure MakeThumbsSou( Rotate : integer; Flip : boolean);
  var TP : sRangeSelectPointsArray;
  begin
    TP := makeThumbPoints( fThumbPoints, Flip, fScaleFactor, Rotate);
    createThumbBmp( fMinThumb, TP);

    TP := makeThumbPoints( fThumbPoints, NOT Flip, fScaleFactor, Rotate);
    createThumbBmp( fMaxThumb, TP);
  end;

begin
  makePointsArray( fThumbStyle);
  if orientation = rsHorizontal then begin
    if tickStyle = rsBottomRight then MakeThumbsSou( 0, false) else
    if tickStyle = rsTopLeft then MakeThumbsSou( 2, true);
    Constraints.MinWidth := 50;
    Constraints.MinHeight := 10;
    end {rsHorizontal} else
  if orientation = rsVertical then begin
    if tickStyle = rsBottomRight then MakeThumbsSou( 3, true) else
    if tickStyle = rsTopLeft then MakeThumbsSou( 1, false);
    Constraints.MinWidth := 10;
    Constraints.MinHeight := 50;
    end; {rsVertical}
end;

destructor tRangeSlider.Destroy;
begin
  fThumbPoints.points := NIL;
  fMinThumb.Free;
  fMaxThumb.Free;
  inherited;
end;

procedure tRangeSlider.drawRuller( aCanvas : TCanvas);
var
  Bmp : TBitMap;
  R : TRect;

  procedure SouDrawRuller;
  begin
    with Bmp.Canvas do begin
      Brush.Color := cl3DLight;
      FillRect( ClipRect);
      Pen.Color := clBtnShadow;
//      Rectangle( ClipRect);
      R := ClipRect;
      Frame3D( Bmp.Canvas, R, clBtnShadow, clBtnHighLight, 1);
      end;
  end;

  procedure SouDrawTicks;
  const
    MinPixPerTic = 5; // minimal distance between tick markers in pixels
  var
    Steps, CurrStep, BigStep : integer;


    function MinSteps : integer;
    const  TmkFact : array[0..2] of integer = (1, 2, 5);
    var
      Steps, SMult, PixPerStep, FInd: integer;

      function CurPixPerTic : integer;
      begin
        Result := ( fRullerLength * TmkFact[ FInd] * SMult) DIV ( max - min);
      end;

    begin
      FInd := low( TmkFact);
      SMult := 1;
      while CurPixPerTic < MinPixPerTic do begin
        if FInd = High( TmkFact) then begin
          FInd := low( TmkFact);
          SMult := SMult * 10;
          end
        else Inc( FInd);
        end;
      Result := TmkFact[ FInd] * SMult;
    end;

    procedure DrawSimpleTick;
    var R : TRect;
    begin
      R := Bounds( 0, 0, 2, 2);
      if orientation = rsHorizontal then begin
        OffsetRect( R, valueToPix( CurrStep) - R.Right DIV 2,
                       rullerWidth DIV 2 - R.Bottom DIV 2);
        end
      else begin
        OffsetRect( R, rullerWidth DIV 2 - R.Right DIV 2,
                       valueToPix( CurrStep) - R.Bottom DIV 2);
        end;
      Bmp.Canvas.Ellipse( R);
    end;

    procedure Draw10thTick;
    const RDist = 1;
    var R : TRect;
    begin
      if orientation = rsHorizontal then begin
        R := Bounds( 0, 2, 2, rullerWidth - 2 * RDist - 1);
        OffsetRect( R, valueToPix( CurrStep) - R.Right DIV 2,
                       rullerWidth DIV 2 - R.Bottom DIV 2);
        end
      else begin
        R := Bounds( 2, 0, rullerWidth - 2 * RDist - 1, 2);
        OffsetRect( R, rullerWidth DIV 2 - R.Right DIV 2,
                       valueToPix( CurrStep) - R.Bottom DIV 2);
        end;
      Bmp.Canvas.moveTo(R.Left, R.Top);
      Bmp.Canvas.LineTo(R.Left, R.Bottom);
    end;

  begin { SouDrawTicks}
    Bmp.Canvas.Brush.Color := clBlack;
    Bmp.Canvas.Pen.Color := clBtnShadow {clBlack};
    if fDrawStep <= 0 then Steps := MinSteps
    else                    Steps := fDrawStep;
    if Steps >= 100000 then BigStep := 1000000 else
    if Steps >= 10000 then BigStep := 100000 else
    if Steps >= 1000 then BigStep := 10000 else
    if Steps >= 100 then BigStep := 1000 else
    if Steps >= 10 then BigStep := 100 else
    if Steps >= 1 then BigStep := 10 else
                       BigStep := 1;
    CurrStep := min - ( min MOD Steps);
    while CurrStep < max do begin
      if CurrStep MOD BigStep = 0 then Draw10thTick
      else                             DrawSimpleTick;
      inc( CurrStep, Steps);
      end;
  end; { SouDrawTicks}

begin
  calcRullerDimensions;
  Bmp := TBitMap.Create;
  try
    if orientation = rsHorizontal then begin
      Bmp.Width := fRullerLength; Bmp.Height := rullerWidth;
      end { rsHorizontal}
    else begin
      Bmp.Height := fRullerLength; Bmp.Width := rullerWidth;
      end; { rsVertical}
    SouDrawRuller; // draw ruller on Bmp
    SouDrawTicks;  // draw ticks
    aCanvas.Draw( fRullerRect.Left, fRullerRect.Top, Bmp);
  finally
    Bmp.Free;
    end;
end;

function tRangeSlider.getThumbDimensions(aPA: sRangeSelectPointsArray): TPoint;
var Cou, MaxX, MaxY : integer;
begin
  Result.X := -MaxInt;
  Result.Y := -Maxint;
  for Cou := 0 to High( aPA.points) do begin
    if aPA.points[Cou].X >= Result.X then Result.X := aPA.points[Cou].X;
    if aPA.points[Cou].Y >= Result.Y then Result.Y := aPA.points[Cou].Y;
    end;
  inc( Result.X); inc( Result.Y);
end;

procedure tRangeSlider.KeyDown(var Key: Word; Shift: TShiftState);
var IncDir : integer;
begin
  inherited;
  fGenerateChangeEvent := true;
  if orientation = rsHorizontal then IncDir := 1 else IncDir := -1;
  case Key of
    VK_LEFT, VK_DOWN  : begin
      if ssShift IN Shift then moveSlider( rsBothSliders, -1*IncDir) else
      if ssCtrl  IN Shift then moveSlider( rsMaxSlider, -1*IncDir) else
      moveSlider( rsMinSlider, -1*IncDir);
      Key := VK_CLEAR;
      end;
    VK_RIGHT, VK_UP : begin
      if ssShift IN Shift then moveSlider( rsBothSliders, 1*IncDir) else
      if ssCtrl  IN Shift then moveSlider( rsMaxSlider, 1*IncDir) else
      moveSlider( rsMinSlider, 1*IncDir);
      Key := VK_CLEAR;
      end;
   end;
end;

procedure tRangeSlider.makePointsArray( aStyle: tRangeSliderThumbStyle);
var Cou : integer;
begin
  fThumbPoints.points := NIL;
  case aStyle of
    rsStandard : begin
      fThumbPoints.origin := mktpStandardPoints[0];
      SetLength( fThumbPoints.points, High( mktpStandardPoints) + 1 - 1{for Origin});
      for Cou := 1 to High( mktpStandardPoints) do fThumbPoints.points[Cou-1] := mktpStandardPoints[Cou];
      end;
    rsTriangle : begin
      fThumbPoints.origin := mktpTrianglePoints[0];
      SetLength( fThumbPoints.points, High( mktpTrianglePoints) + 1 - 1{for Origin});
      for Cou := 1 to High( mktpTrianglePoints) do fThumbPoints.points[Cou-1] := mktpTrianglePoints[Cou];
      end;
    rsCorner : begin
      fThumbPoints.origin := mktpCornerPoints[0];
      SetLength( fThumbPoints.points, High( mktpCornerPoints) + 1 - 1{for Origin});
      for Cou := 1 to High( mktpCornerPoints) do fThumbPoints.points[Cou-1] := mktpCornerPoints[Cou];
      end;
    rsArrow : begin
      fThumbPoints.origin := mktpArrowPoints[0];
      SetLength( fThumbPoints.points, High( mktpArrowPoints) + 1 - 1{for Origin});
      for Cou := 1 to High( mktpArrowPoints) do fThumbPoints.points[Cou-1] := mktpArrowPoints[Cou];
      end;
    else begin
      fThumbPoints.origin := mktpStandardPoints[0];
      SetLength( fThumbPoints.points, High( mktpStandardPoints) + 1 - 1{for Origin});
      for Cou := 1 to High( mktpStandardPoints) do fThumbPoints.points[Cou-1] := mktpStandardPoints[Cou];
      end;
    end;
end;

function tRangeSlider.makeThumbPoints(aPA: sRangeSelectPointsArray; aFlip: boolean;
  aScale, aRotateClockSteps: integer): sRangeSelectPointsArray;
var
  SouPA : sRangeSelectPointsArray;
  ALength : integer;

  procedure HorizontalFlip;
  var Cou : integer; TmpPA : sRangeSelectPointsArray;
  begin
    SetLength( TmpPA.points, High( SouPA.points) + 1);
    {flip origin}
    TmpPA.origin.X := - SouPA.origin.X;
    TmpPA.origin.Y :=   SouPA.origin.Y;
    {flip points}
    for Cou := 0 to High( SouPA.points) do begin
      TmpPA.points[ High( SouPA.points) - Cou].X := - SouPA.points[ Cou].X;
      TmpPA.points[ High( SouPA.points) - Cou].Y :=   SouPA.points[ Cou].Y;
      end;
    {copy to source}  
    SouPA.origin := TmpPA.origin;
    SouPA.points := Copy( TmpPA.points, 0, High( SouPA.points) + 1);
    TmpPA.points := NIL;
  end;

  procedure Rotate;
  var Cou, SinS, CosS, MinX, MinY : integer; TmpPA : sRangeSelectPointsArray;
  begin
    // duplicate Source
    SetLength( TmpPA.points, High( SouPA.points));
    TmpPA.points := Copy( SouPA.points, 0, High( SouPA.points) + 1);
    case aRotateClockSteps MOD 4 of
      0: begin SinS :=  0; CosS :=  1; end;
      1: begin SinS := -1; CosS :=  0; end;
      2: begin SinS :=  0; CosS := -1; end;
      3: begin SinS :=  1; CosS :=  0; end;
      end;
    MinX := Maxint; MinY := Maxint;
    // make transformation of Origin
    TmpPA.origin.X :=    SouPA.origin.X  * CosS + SouPA.origin.Y * SinS;
    TmpPA.origin.Y := -( SouPA.origin.X) * SinS + SouPA.origin.Y * CosS;
    // make transformation of Points
    for Cou := 0 to High( SouPA.points) do begin
      TmpPA.points[ Cou].X :=    SouPA.points[ Cou].X  * CosS + SouPA.points[ Cou].Y * SinS;
      TmpPA.points[ Cou].Y := -( SouPA.points[ Cou].X) * SinS + SouPA.points[ Cou].Y * CosS;
      if TmpPA.points[ Cou].X <= MinX then MinX := TmpPA.points[ Cou].X;
      if TmpPA.points[ Cou].Y <= MinY then MinY := TmpPA.points[ Cou].Y;
      end;
    if MinX >= 0 then MinX := 0;
    if MinY >= 0 then MinY := 0;
    // move to positive area
    TmpPA.origin.X := TmpPA.origin.X - MinX;
    TmpPA.origin.Y := TmpPA.origin.Y - MinY;
    for Cou := 0 to High( TmpPA.points) do begin
      TmpPA.points[ Cou].X := TmpPA.points[ Cou].X - MinX;
      TmpPA.points[ Cou].Y := TmpPA.points[ Cou].Y - MinY;
      end;
    // replace source with transformed array
    SouPA.origin := TmpPA.origin;
    SouPA.points := Copy( TmpPA.points, 0, High( TmpPA.points) + 1);
    TmpPA.points := NIL;
  end;

  procedure Zoom;
  var Cou : integer;
  begin
    SouPA.origin.X := SouPA.origin.X * aScale;
    SouPA.origin.Y := SouPA.origin.Y * aScale;
    for Cou := 0 to High( SouPA.points) do begin
      SouPA.points[ Cou].X := SouPA.points[ Cou].X * aScale;
      SouPA.points[ Cou].Y := SouPA.points[ Cou].Y * aScale;
      end;
  end;

begin
  // duplicate Source points
  SetLength( SouPA.points, High( aPA.points));
  SouPA.origin := aPA.origin;
  SouPA.points := Copy( aPA.points, 0, High( aPA.points) + 1);

  if aFlip then HorizontalFlip;
  Rotate;
  Zoom;
  { Copy to result}
  ALength := High( SouPA.points) + 1;
  SetLength( Result.points, ALength);
  Result.points := Copy( SouPA.points, 0, ALength);
  Result.origin := SouPA.origin;

  SouPA.points := NIL;
end;

procedure tRangeSlider.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if NOT Focused then begin SetFocus; {Refresh;} end;

  if Button <> mbLeft then exit;

  if fMinThumb.myPoint( X, Y) then begin
    fDragThumb := fMinThumb;
    fDragOffset := valueToPix( minPosition);
    end else
  if fMaxThumb.myPoint( X, Y) then begin
    fDragThumb := fMaxThumb;
    fDragOffset := valueToPix( maxPosition);
    end else
  fDragThumb := NIL;

  if fDragThumb = NIL then exit;  // mouse is not in thumbs

  if orientation = rsHorizontal then fDragOffset := fDragOffset - X
  else                               fDragOffset := fDragOffset - Y;
  fDragging := true;
  fGenerateChangeEvent := false;
  fOldMinPos := minPosition;
  fOldMaxPos := maxPosition;
end;

procedure tRangeSlider.MouseMove(Shift: TShiftState; X, Y: Integer);
var NewMaxP, NewMinP, FDragValue, OldMaxP, OldMinP : integer;

  function CheckValue( Value : integer) : boolean;
  begin
    Result := ( Value <= max) AND ( Value >= min);
  end;

begin
  inherited;

  if NOT fDragging then exit;
  OldMaxP := maxPosition;
  OldMinP := minPosition;
  if orientation = rsHorizontal then FDragValue := X
  else                               FDragValue := Y;
  if fDragThumb = fMinThumb then begin
    NewMinP := aPixToValue( FDragValue + fDragOffset);
    if ssShift IN Shift then begin
      NewMaxP := OldMaxP + ( NewMinP - OldMinP);
      if CheckValue( NewMinP) AND CheckValue( NewMaxP) then begin
        minPosition := NewMinP; maxPosition := NewMaxP; end;
      end
    else minPosition := NewMinP;
    end else
  if fDragThumb = fMaxThumb then begin
    NewMaxP := aPixToValue( FDragValue + fDragOffset);
    if ssShift IN Shift then begin
      NewMinP := OldMinP + ( NewMaxP - OldMaxP);
      if CheckValue( NewMinP) AND CheckValue( NewMaxP) then begin
        maxPosition := NewMaxP; minPosition := NewMinP; end;
      end
    else maxPosition := NewMaxP;
    end;
end;

procedure tRangeSlider.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited;
  fDragging := false;
  if { FGenerateChangeEvent} true AND
     (( fOldMinPos <> minPosition) OR ( fOldMaxPos <> maxPosition)) then begin
    fGenerateChangeEvent := true;
    if Assigned( onChange) then onChange( Self);
    end;
end;

procedure tRangeSlider.Paint;
var Bmp : TBitMap;

  procedure PaintFrame;
  var R : TRect;
  begin
    R := Bmp.Canvas.ClipRect;
    Frame3D( Bmp.Canvas, R, clBtnShadow, clBtnHighLight, 1);
  end;

begin
  Bmp := TBitMap.Create;
  try
    Bmp.Width := Width; Bmp.Height := Height;
//    Bmp.Transparent := true;
//    Bmp.TransparentColor := TransparentColor;
    with Bmp.Canvas do begin
      Brush.Color := {TransparentColor;} Self.Color;
      FillRect( ClipRect);
      end;

    drawRuller( Bmp.Canvas);

    fMinThumb.initialDrawing := true;
    drawMinThumb( Bmp.Canvas);

    fMaxThumb.initialDrawing := true;
    drawMaxThumb( Bmp.Canvas);

//    if Focused then Bmp.Canvas.DrawFocusRect( Bmp.Canvas.ClipRect);

//    PaintFrame;

    Self.Canvas.CopyRect( Self.Canvas.ClipRect, Bmp.Canvas, Self.Canvas.ClipRect);
//    Self.Canvas.Draw( 0, 0, Bmp);
  finally Bmp.Free; end;

{
  OutputDebugString( 'Painting');

  DrawRuller( Self.Canvas);

  MinThumb.InitialDrawing := true;
  DrawMinThumb( Self.Canvas); // redraw Min thumb

  MaxThumb.InitialDrawing := true;
  DrawMaxThumb( Self.Canvas); // redraw Max thumb
}
//  if Focused then Canvas.DrawFocusRect( Canvas.ClipRect);
end;

procedure tRangeSlider.setDrawStep(const aValue: integer);
begin
  fDrawStep := aValue;
  Refresh;
end;

procedure tRangeSlider.setMax(const aValue: integer);
begin
  if aValue <= min then raise eRangeSlider.Create('Max <= Min');
  fMax := aValue;
  if ( csReading IN ComponentState) OR
     ( csUpdating IN ComponentState) OR
     ( csLoading IN ComponentState) then exit;
  if Assigned( fOnBeforeChange) then fOnBeforeChange( Self);
  checkPositionValues;
  Refresh;
  if Assigned( fOnMaxChange) then fOnMaxChange( Self, fMax);
  if Assigned( onChange) AND fGenerateChangeEvent then onChange( Self);
end;

procedure tRangeSlider.drawMaxThumb( aCanvas : TCanvas);
begin
  fMaxThumb.draw( aCanvas, valueToPix( maxPosition), orientation);
end;

procedure tRangeSlider.setMaxPosition(const aValue: integer);
begin
  if fMaxPosition = aValue then exit;
  if ( csReading IN ComponentState) OR
     ( csUpdating IN ComponentState) OR
     ( csLoading IN ComponentState) then begin
    fMaxPosition := aValue;
    exit;
    end;
  if Assigned( fOnBeforeChange) then fOnBeforeChange( Self);
  if aValue < fMinPosition then fMaxPosition := fMinPosition else
  if aValue > max then fMaxPosition := max else
    fMaxPosition := aValue;
  drawMaxThumb( Self.Canvas);
//  Refresh;
  if Assigned( fOnMaxPosChange) then fOnMaxPosChange( Self, fMaxPosition);
  if Assigned( onChange) AND fGenerateChangeEvent then onChange( Self);
end;

procedure tRangeSlider.setMin(const aValue: integer);
begin
  if aValue >= max then raise eRangeSlider.Create('Min >= Max');
  fMin := aValue;
  if ( csReading IN ComponentState) OR
     ( csUpdating IN ComponentState) OR
     ( csLoading IN ComponentState) then exit;
  if Assigned( fOnBeforeChange) then fOnBeforeChange( Self);
  checkPositionValues;
  Refresh;
  if Assigned( fOnMinChange) then fOnMinChange( Self, fMin);
  if Assigned( onChange) AND fGenerateChangeEvent then onChange( Self);
end;

procedure tRangeSlider.drawMinThumb( aCanvas : TCanvas);
begin
  fMinThumb.draw( aCanvas, valueToPix( minPosition)-1, orientation)
end;

procedure tRangeSlider.setMinPosition(const aValue: integer);
begin
  if fMinPosition = aValue then exit;
  if ( csReading IN ComponentState) OR
     ( csUpdating IN ComponentState) OR
     ( csLoading IN ComponentState) then begin
    fMinPosition := aValue;
    exit;
    end;
  if Assigned( fOnBeforeChange) then fOnBeforeChange( Self);
  if aValue < min then fMinPosition := min else
  if aValue > fMaxPosition then fMinPosition := fMaxPosition else
    fMinPosition := aValue;
  drawMinThumb( Self.Canvas);
//  Refresh;
  if Assigned( fOnMinPosChange) then fOnMinPosChange( Self, fMinPosition);
  if Assigned( onChange) AND fGenerateChangeEvent then onChange( Self);
end;

procedure tRangeSlider.setOrientation(const aValue: tRangeSliderOrientation);
var TmpInt : integer;
begin
  if fOrientation = aValue then exit;
  if Assigned( fOnBeforeChange) then fOnBeforeChange( Self);
  fOrientation := aValue;

  if ComponentState * [csLoading, csUpdating] = [] then
    SetBounds(Left, Top, Height, Width);
(*
  if (csDesigning IN ComponentState) AND ( NOT (csLoading IN ComponentState)) then begin
    TmpInt := Width; Width := Height; Height := TmpInt; // swap Width and height
    end;
*)    
  createThumbnails;
  calcRullerDimensions;
  Refresh;
end;

procedure tRangeSlider.setThumbColor(const Value: tColor);
begin
  fThumbColor := Value;
  createThumbnails;
  repaint;
end;

procedure tRangeSlider.setThumbStyle(const aValue: tRangeSliderThumbStyle);
begin
  if fThumbStyle = aValue then exit;
  if Assigned( fOnBeforeChange) then fOnBeforeChange( Self);
  fThumbStyle := aValue;
  createThumbnails;
  calcRullerDimensions;
  Refresh;
end;

procedure tRangeSlider.setTickStyle(const aValue: tRangeSliderTickStyle);
begin
  if fTickStyle = aValue then exit;
  if Assigned( fOnBeforeChange) then fOnBeforeChange( Self);
  fTickStyle := aValue;
  createThumbnails;
  calcRullerDimensions;
  Refresh;
end;

function tRangeSlider.aPixToValue(aPix: integer): integer;
begin
  Result := round( aPix / fPixelsPerStep) + fMin;
end;

function tRangeSlider.valueToPix(aValue: integer): integer;
begin
  Result := round( (aValue - fMin) * fPixelsPerStep);
end;

procedure tRangeSlider.CMEnter(var Message: TCMGotFocus);
begin
  inherited;
//  Refresh;
end;

procedure tRangeSlider.CMExit(var Message: TCMExit);
begin
  inherited;
//  Refresh;
end;

procedure tRangeSlider.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  Message.Result := DLGC_WANTARROWS;
end;

procedure tRangeSlider.moveSlider(aSlider: tRangeSliderMoveSliders; aValue: integer);
begin
  case aSlider of
    rsMinSlider : minPosition := minPosition + aValue;
    rsMaxSlider : maxPosition := maxPosition + aValue;
    rsBothSliders : begin
      if ( minPosition + aValue >= min) AND ( minPosition + aValue <= max) AND
         ( maxPosition + aValue >= min) AND ( maxPosition + aValue <= max) then begin
        minPosition := minPosition + aValue;
        maxPosition := maxPosition + aValue;
        end;
      end;
    end;
end;

procedure tRangeSlider.setRullerWidth(const aValue: integer);
begin
  fRullerWidth := aValue;
end;

procedure tRangeSlider.setOnGetRullerLength(
  const aValue: tRangeSliderGetRullerLengthEvent);
begin
  fOnGetRullerLength := aValue;
end;

procedure tRangeSlider.calcRullerDimensions;
const
  RullerShrink = 6;
  RullerMinOffset = 2;
var ROfs : integer;
begin
  { Get Ruller length}
  if csDesigning IN ComponentState then fRullerLength := 0
  else begin
    if Assigned( fOnGetRullerLength) then begin
      fOnGetRullerLength( Self, fRullerLength);
      if fRullerLength < minRullerLength then fRullerLength := minRullerLength;
      end
    else fRullerLength := 0;
    end;
  { Calculate ruller dimensions}
  if orientation = rsHorizontal then begin
    if fRullerLength <= 0 then fRullerLength := Width - 2 * fMinThumb.Width - RullerShrink
    else Width := fRullerLength + 2 * fMinThumb.Width + RullerShrink;
    fRullerRect := Bounds( 0, 0, fRullerLength, rullerWidth);
    if fMinThumb.origin.Y <= rullerWidth DIV 2 then ROfs := RullerMinOffset
    else ROfs := fMinThumb.origin.Y - rullerWidth DIV 2 + RullerMinOffset;
    OffsetRect( fRullerRect, fMinThumb.Width + RullerShrink DIV 2, ROfs);
    end { rsHorizontal}
  else begin
    if fRullerLength <= 0 then fRullerLength := Height - 2 * fMinThumb.Height - RullerShrink
    else Height := fRullerLength + 2 * fMinThumb.Height + RullerShrink;
    fRullerRect := Bounds( 0, 0, rullerWidth, fRullerLength);
    if fMinThumb.origin.X <= rullerWidth DIV 2 then ROfs := RullerMinOffset
    else ROfs := fMinThumb.origin.X - rullerWidth DIV 2 + RullerMinOffset;
    OffsetRect( fRullerRect, ROfs, fMinThumb.Height + RullerShrink DIV 2);
    end; { rsVertical}
  fPixelsPerStep := fRullerLength / ( max - min);
end;

procedure tRangeSlider.checkPositionValues;
begin
  if fMinPosition < fMin then fMinPosition := fMin;
  if fMaxPosition < fMin then fMaxPosition := fMin;
  if fMinPosition > fMax then fMinPosition := fMax;
  if fMaxPosition > fMax then fMaxPosition := fMax;
end;

procedure tRangeSlider.setOnBeforeChange(const aValue: TNotifyEvent);
begin
  fOnBeforeChange := aValue;
end;

procedure tRangeSlider.doKeyDown(var Key: Word; Shift: TShiftState);
begin
  KeyDown( Key, Shift);
end;

{ TmkThumbBitmap }

constructor cRangeSliderThumbBitmap.Create;
begin
  inherited;
  Transparent := true;
  fSlider := NIL;
  fOrigin := Point( 0, 0);
  fBkg := TBitMap.Create;
  fInitialDrawing := false;
end;

destructor cRangeSliderThumbBitmap.Destroy;
begin
  fBkg.Free;
  inherited;
end;

procedure cRangeSliderThumbBitmap.draw( aCanvas : TCanvas; aValue : integer; aOrientation : tRangeSliderOrientation);
var TmpRect : TRect;

  function CalcThumbRect : TRect;
  var AbsPoint : TPoint;
  begin
    with Slider.rullerRect do begin
      if aOrientation = rsHorizontal then
        AbsPoint := Point( Left + aValue, Top + ((Bottom - Top) DIV 2))
      else
        AbsPoint := Point( Left + (( Right - Left) DIV 2), Top + aValue);
      end;
    Result := Bounds( AbsPoint.X - fOrigin.X, AbsPoint.Y - fOrigin.Y, Width, Height);
  end;

  procedure SaveCurrentBkg;
  begin
    fBkgRect := CalcThumbRect;
    fBkg.Canvas.CopyRect( fBkg.Canvas.ClipRect, aCanvas, fBkgRect);
  end;
begin
  if NOT Assigned( fSlider) then raise
    eRangeSlider.Create('Slider not assigned to bitmap');
  if fInitialDrawing then begin { save initial background}
    //OutputDebugString( 'FInitialDrawing');
    fBkg.Width := Width; fBkg.Height := Height;
    SaveCurrentBkg;
    fInitialDrawing := false;
    end
  else begin { restore old background}
    aCanvas.CopyRect( fBkgRect, fBkg.Canvas, fBkg.Canvas.ClipRect);
    SaveCurrentBkg;
    end;
  //OutputDebugString( 'Thumb Drawing');
  aCanvas.Draw( fBkgRect.Left, fBkgRect.Top, Self);
end;

function cRangeSliderThumbBitmap.myPoint(X, Y: integer): boolean;
begin
  Result :=
    PtInRect( fBkgRect, Point( X, Y));
end;

end.
