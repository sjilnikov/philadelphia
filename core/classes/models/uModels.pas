unit uModels;

interface

const
  NO_CONSIDER_LIMIT   = -1;
  NO_CONSIDER_OFFSET  = -1;
  NOT_VALID_KEY_ID    = 0;
  NEW_KEY_ID          = -1;
  USE_RECORD_ID       = -1;

type
  tAggregateFieldType = (aftCount, aftSum, aftAverage, aftFormula);
  cAggregateFieldTypes = array of tAggregateFieldType;

  tExitState = (esNormal, esAddNext);

  tEditMode = (emUpdate, emInsert);

  tModelSearchDirection = (sdForward, sdBackward);
  tModelSearchPosition = (spFirst, spCurrent, spNextFromCurrent, spPrevFromCurrent, spLast);

implementation

end.
