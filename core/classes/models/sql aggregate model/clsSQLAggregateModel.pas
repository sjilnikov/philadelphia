unit clsSQLAggregateModel;

interface
uses
  sysUtils,
  asyncCalls,

  uMetrics,

  clsMulticastEvents,
  clsTimer,
  clsStringUtils,
  clsSQLQueryFactory,
  clsAbstractSQLQuery,
  clsSQLTableModel,
  clsAbstractSQLConnection,
  clsSQLConnectionsFactory,
  clsAbstractAggregateModel;

type
  cSQLAggregateModel = class;

  cSQLAggregateModelGetAggregateConditionEvent = procedure(aSender: cSQLAggregateModel; var aCondition: string) of object;

  cSQLAggregateModel = class(cAbstractAggregateModel)
  private
    fParallelTask                   : iAsyncCall;
    fScheduleTimer                  : cTimer;
    fUpdateAggregateValuesScheduled : boolean;
    fOnGetAggregateCondition        : cSQLAggregateModelGetAggregateConditionEvent;

    procedure   scheduleUpdateAggregateValues(aValue: boolean);
    function    isUpdateAggregateValuesScheduled: boolean;

    procedure   setupEvents;
    procedure   disconnectEvents;

    function    getCastedModel: cSQLTableModel;
  protected
    procedure   updateAggregateValues; override;
  public
    constructor create;
    destructor  destroy; override;
  published
    //SLOTS
    procedure   scheduleTimerTick(aSender: cTimer);
  published
    //EVENTS
    property    onGetAggregateCondition: cSQLAggregateModelGetAggregateConditionEvent read fOnGetAggregateCondition write fOnGetAggregateCondition;
  end;

implementation

{ cSQLAggregateModel }

constructor cSQLAggregateModel.create;
begin
  inherited create;

  fUpdateAggregateValuesScheduled:= false;

  fScheduleTimer:= cTimer.create(SECOND);
  fScheduleTimer.start;

  setupEvents;
end;

destructor cSQLAggregateModel.destroy;
begin
  fParallelTask:= nil;

  disconnectEvents;

  if assigned(fScheduleTimer) then begin
    freeAndNil(fScheduleTimer);
  end;

  inherited;
end;

procedure cSQLAggregateModel.setupEvents;
begin
  connect(fScheduleTimer, 'onTick', self, 'scheduleTimerTick');
end;

procedure cSQLAggregateModel.disconnectEvents;
begin
  disconnect(fScheduleTimer, 'onTick', self, 'scheduleTimerTick');
end;

function cSQLAggregateModel.getCastedModel: cSQLTableModel;
begin
  result:= tableModel as cSQLTableModel;
end;

function cSQLAggregateModel.isUpdateAggregateValuesScheduled: boolean;
begin
  result:= fUpdateAggregateValuesScheduled;
end;

procedure cSQLAggregateModel.scheduleUpdateAggregateValues(aValue: boolean);
begin
  fUpdateAggregateValuesScheduled:= aValue;
end;

procedure cSQLAggregateModel.updateAggregateValues;
var
  aggregateCommand: string;
  userCondition: string;
begin
  if not isEnabled then exit;

  if (isBusy) then begin
    scheduleUpdateAggregateValues(true);

    exit;
  end;

  beginCalc;

  userCondition:= '';
  if assigned(onGetAggregateCondition) then begin
    onGetAggregateCondition(self, userCondition);
  end;

  aggregateCommand:= getCastedModel.getAggregateCommand(getAggregateFieldDelimitedNames, getAggregateFieldTypes, userCondition);

  fParallelTask:= tAsyncCalls.invoke(

    procedure
    var
      i: integer;
      newConnection: cAbstractSQLConnection;
      delimitedFields: string;

      query: cAbstractSQLQuery;
    begin

      try
        newConnection:= cSQLConnectionFactory.createNew(getCastedModel.getConnection.connectionInfo.driver, cStringUtils.getNewGUID);
        try

          try

            newConnection.assign(getCastedModel.getConnection);
            if not newConnection.open then begin
              exit;
            end;


            query:= cSQLQueryFactory.createNew(getCastedModel.getConnection.connectionInfo.driver);
            try
              query.setConnection(newConnection);
              query.setSQL(aggregateCommand);

              if (not query.open) then begin
                exit;
              end;

              for i:= 0 to query.fields.count - 1 do begin
                setFieldData(query.fields[i].displayName, getRowCount - 1, query.fields[i].asCurrency);
              end;

            finally
              freeAndNil(query);
            end;
          finally
            freeAndNil(newConnection);
          end;

        finally
          endCalc;
        end;


        //must invoke in main thread (e.g. for update views)
        enterMainThread;
        try
          dataFetched;
        finally
          leaveMainThread;
        end;
        //
      except
        endCalc;
      end;
    end

  );

end;

//SLOTS
procedure cSQLAggregateModel.scheduleTimerTick(aSender: cTimer);
begin
  if (isUpdateAggregateValuesScheduled) then begin
    scheduleUpdateAggregateValues(false);
    updateAggregateValues;
  end;
end;

end.
