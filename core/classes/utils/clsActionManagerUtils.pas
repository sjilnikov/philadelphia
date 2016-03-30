unit clsActionManagerUtils;

interface
uses
  sysUtils,
  actnMan;

type
  cActionManagerUtils = class
  private
    const

    SHORTCUT_CAPTION_FORMAT = '%s (%s)';
  private
    class procedure iterateClientProc(aClient: tActionClient);
  public
    class procedure addShortcutTextToCaption(aActionManager: tActionManager; aItemCaption: string);
    class procedure addShortcutTextToAllCaption(aActionManager: tActionManager);
  end;

implementation

{ cActionManagerUtils }

class procedure cActionManagerUtils.addShortcutTextToAllCaption(aActionManager: tActionManager);
begin
  aActionManager.actionBars.iterateClients(aActionManager.actionBars, iterateClientProc);
end;

class procedure cActionManagerUtils.addShortcutTextToCaption(aActionManager: tActionManager; aItemCaption: string);
var
  i: integer;
  item: tActionClientItem;
  curItem: tActionClientItem;
begin
  item:= aActionManager.findItemByCaption(aItemCaption);

  if not assigned(item) then exit;

  for i:= 0 to item.items.count - 1 do begin
    curItem:= item.items[i];

    if (not curItem.showShortCut) then continue;

    curItem.caption:= format(SHORTCUT_CAPTION_FORMAT, [curItem.caption, curItem.shortCutText]);
  end;

end;

class procedure cActionManagerUtils.iterateClientProc(aClient: tActionClient);
var
  curItem: tActionClientItem;
begin
  if not (aClient is tActionClientItem) then exit;

  curItem:= tActionClientItem(aClient);

  if (curItem.shortCutText = '') then exit;;
  if (not curItem.showShortCut) then exit;

  curItem.caption:= format(SHORTCUT_CAPTION_FORMAT, [curItem.caption, curItem.shortCutText]);
end;

end.
