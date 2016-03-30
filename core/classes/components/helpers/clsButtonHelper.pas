unit clsButtonHelper;

interface
uses
  classes,
  sysUtils,
  menus,
  stdCtrls,
  windows,

  clsMemory;

type
  tButtonDropDownDirection = (ddUp, ddDown);

  cButtonEditHelper = class helper for tButton
  public
    procedure dropDown(aPopupMenu: tPopupMenu; aDirection: tButtonDropDownDirection = ddDown);
  end;


implementation

{ cButtonEditHelper }

procedure cButtonEditHelper.dropDown(aPopupMenu: tPopupMenu; aDirection: tButtonDropDownDirection);
const
  trackType : array[tButtonDropDownDirection] of integer = (TPM_BOTTOMALIGN, TPM_TOPALIGN);

var
  popupPoint: tPoint;
  flags: integer;
begin
  popupPoint:= clientToScreen(point(0,0));


  flags :=
            TPM_LEFTALIGN or trackType[aDirection]
            //in this case to the left and up
            //, TPM_LEFTALIGN   or TPM_TOPALIGN
            //, TPM_LEFTALIGN   or TPM_VCENTERALIGN
            //, TPM_RIGHTALIGN  or TPM_BOTTOMALIGN
            //, TPM_RIGHTALIGN  or TPM_TOPALIGN
            //, TPM_RIGHTALIGN  or TPM_VCENTERALIGN
            //, TPM_CENTERALIGN or TPM_BOTTOMALIGN
            //, TPM_CENTERALIGN or TPM_TOPALIGN
            //, TPM_CENTERALIGN or TPM_VCENTERALIGN
            //or TPM_VERTICAL or TPM_HORIZONTAL
            //you could specify a region the PopUpMenu should'nt overlap
            //but you have to specify a TPMPARAMS(~TRect) structure (last Param)
            //                    or TPM_RETURNCMD  //Return the Identifier of the Item clicked
            //or TPM_NONOTIFY //no Message send back
            or TPM_LEFTBUTTON //the Left Button selects
            //or TPM_RIGHTBUTTON //the Right Button selects
            //or TPM_LEFTBUTTON or TPM_RIGHTBUTTON// or both
            or TPM_HORPOSANIMATION or TPM_VERNEGANIMATION;
            //^these Settings look best with TPM_LEFTALIGN and TPM_BOTTOMALIGN
            //could also be:
            //TPM_NOANIMATION
            //or TPM_HORNEGANIMATION or TPM_VERPOSANIMATION ;

  if aDirection = ddDown then inc(popupPoint.y, height);

  if assigned(aPopupMenu.onPopup) then aPopupMenu.onPopup(aPopupMenu);

  trackPopupMenu(aPopupMenu.items.handle, flags, popupPoint.x, popupPoint.y, 0 { reserved }, popupList.window, nil);
end;


end.
