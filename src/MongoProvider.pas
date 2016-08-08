{***************************************************************************}
{                                                                           }
{                    Mongo Delphi Driver                                    }
{                                                                           }
{           Copyright (c) 2012 Fabricio Colombo                             }
{                                                                           }
{  Licensed under the Apache License, Version 2.0 (the "License");          }
{  you may not use this file except in compliance with the License.         }
{  You may obtain a copy of the License at                                  }
{                                                                           }
{      http://www.apache.org/licenses/LICENSE-2.0                           }
{                                                                           }
{  Unless required by applicable law or agreed to in writing, software      }
{  distributed under the License is distributed on an "AS IS" BASIS,        }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{  See the License for the specific language governing permissions and      }
{  limitations under the License.                                           }
{                                                                           }
{***************************************************************************}
unit MongoProvider;

{$IFDEF FPC}
  {$MODE Delphi}
  {$DEFINE SYNAPSE}
{$ENDIF}

interface

uses
  Classes, SysUtils
  , MongoEncoder
  , MongoDecoder
  , BSONTypes
  , BSONStream
  {$IFDEF SYNAPSE}
  , blcksock
  {$ENDIF}
  , Sockets
  , CommandResult
  , WriteResult
  ;

const
  DEFAULT_HOST = 'localhost';
  DEFAULT_PORT = 27017;

  (* Mongo Collections *)
  COMMAND_COLLECTION = '$cmd';
  SYSTEM_INDEXES_COLLECTION = 'system.indexes';
  SYSTEM_NAMESPACES_COLLECTION = 'system.namespaces';

type
  IMongoProvider = interface;

  TCommandResult = class(TBSONObject, ICommandResult)
  public
    function HasError: Boolean;
    function Ok: Boolean;
    function GetCode: Integer;
    function GetErrorMessage: AnsiString;
    function GetException: Exception;
    procedure RaiseOnError;
  end;

  TWriteResult = class(TInterfacedObject, IWriteResult)
  private
    FProvider: IMongoProvider;
    FRequestId: Integer;
    FDB: AnsiString;
    FLastErrorResult: ICommandResult;
  public
    function getCachedLastError: ICommandResult;
    function getLastError: ICommandResult;

    constructor Create(const AProvider: IMongoProvider;
                       const ADB: AnsiString;
                       const ARequestId: Integer
                       );
  end;

  IMongoProvider = interface
    ['{DBF272FB-59BE-4CA6-B38B-2B1E5879EC34}']
    
    procedure SetEncoder(const AEncoder: IMongoEncoder);
    procedure SetDecoder(const ADecoder: IMongoDecoder);

    procedure Close;

    function GetLastError(DB: AnsiString; RequestId: Integer=0): ICommandResult;
    function RunCommand(DB: AnsiString; Command: IBSONObject): ICommandResult;

    function Insert(DB, Collection: AnsiString; BSONObject: IBSONObject): IWriteResult;overload;
    function Insert(DB, Collection: AnsiString; BSONObjects: Array of IBSONObject): IWriteResult;overload;

    function Update(DB, Collection: AnsiString; Query, BSONObject: IBSONObject): IWriteResult;overload;
    function Update(DB: AnsiString; Collection: AnsiString; Query, BSONObject: IBSONObject; Upsert, Multi: Boolean): IWriteResult;overload;
    function UpdateMulti(DB, Collection: AnsiString; Query, BSONObject: IBSONObject): IWriteResult;

    function Remove(DB, Collection: AnsiString; AObject: IBSONObject): IWriteResult;

    function FindOne(DB, Collection: AnsiString): IBSONObject;overload;
    function FindOne(DB, Collection: AnsiString; Query: IBSONObject): IBSONObject;overload;
    function FindOne(DB, Collection: AnsiString; Query, Fields: IBSONObject): IBSONObject;overload;

    function OpenQuery(AStream: TBSONStream; DB: AnsiString; Collection: AnsiString; Query, Fields: IBSONObject; ASkip, ABatchSize: Integer): IBSONObject;
    function HasNext(AStream: TBSONStream; DB: AnsiString; Collection: AnsiString; ACursorId: Int64; ABatchSize: Integer): IBSONObject;

    procedure KillCursor(ACursorId: Int64);
    procedure KillCursors(ACursorId: Array of Int64);

    function Authenticate(const DB, AUserName, APassword: AnsiString): Boolean;
    procedure Logout(const DB: AnsiString);

    function CreateIndex(DB, Collection: AnsiString; KeyFields: IBSONObject; AIndexName: AnsiString = ''): IWriteResult;

    procedure SetConnected(const Value: Boolean);
    function GetConnected: Boolean;

    procedure SetActive(const Value: Boolean);
    function GetActive: Boolean;

    procedure SetServerAddr(const Value: AnsiString);
    function GetServerAddr: AnsiString;

    procedure SetServerPort(const Value: Word);
    function GetServerPort: Word;

    property Connected: Boolean read GetConnected write SetConnected;
    property Active: Boolean read GetActive write SetActive;
    property ServerAddr: AnsiString read GetServerAddr write SetServerAddr;
    property ServerPort: Word read GetServerPort write SetServerPort;
  end;

  TResponse = class
  private
    FCursorId: Int64;
    FRequestID: Integer;
    FStartingFrom: Integer;
    FFlags: Integer;
    FOpCode: Integer;
    FLength: Integer;
    FNumberReturned: Integer;
    FResponseTo: Integer;
  public
    property Length: Integer read FLength write FLength;
    property RequestID: Integer read FRequestID write FRequestID;
    property ResponseTo: Integer read FResponseTo write FResponseTo;
    property OpCode: Integer read FOpCode write FOpCode;
    property Flags: Integer read FFlags write FFlags;
    property CursorId: Int64 read FCursorId write FCursorId;
    property StartingFrom: Integer read FStartingFrom write FStartingFrom;
    property NumberReturned: Integer read FNumberReturned write FNumberReturned;
  end;

  TDefaultMongoProvider = class(TInterfacedObject, IMongoProvider)
  private
    FConnected: Boolean;
    FActive: Boolean;
    FServerAddr: AnsiString;
    FServerPort: Word;

    FRequestId: Integer;
    FEncoder: IMongoEncoder;
    FDecoder: IMongoDecoder;
    FQueueRequests: TStringList;
    {$IFDEF SYNAPSE}
    FSocket: TTCPBlockSocket;
    {$ELSE}
    FSocket: TTcpClient;
    {$ENDIF}

    procedure ReadResponse(AStream: TBSONStream; ARequestId: Integer; var AFlags, ANumberReturned: Integer); overload;
    procedure ReadResponse(AStream: TBSONStream; ARequestId: Integer; var AFlags, ANumberReturned: Integer; var ACursorId: Int64); overload;
    function ReadResponse(AStream: TBSONStream; ARequestId: Integer): TResponse; overload;

    function SendBuf(Buffer: Pointer; Length: Integer): Integer;
    function ReceiveBuf(var Buffer; Length: Integer): Integer;

    procedure BeginMsg(AStream: TBSONStream; OperationCode: Integer);overload;
    procedure BeginMsg(AStream: TBSONStream; DB, Collection: AnsiString; OperationCode: Integer);overload;
    procedure SendMsg(AStream: TBSONStream);

    function MakeHash(const AUserName, APassword: AnsiString): AnsiString;

    procedure SetServerAddr(const Value: AnsiString);
    function GetServerAddr: AnsiString; 
    procedure SetServerPort(const Value: Word);
    function GetServerPort: Word;
    
    procedure TryConnect;
  protected
    procedure SetConnected(const Value: Boolean);
    function GetConnected: Boolean;

    procedure SetActive(const _active: Boolean);
    function GetActive: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    procedure SetEncoder(const AEncoder: IMongoEncoder);
    procedure SetDecoder(const ADecoder: IMongoDecoder);

    procedure Close;

    function GetLastError(DB: AnsiString; RequestId: Integer=0): ICommandResult;
    function RunCommand(DB: AnsiString; Command: IBSONObject): ICommandResult;

    function Insert(DB, Collection: AnsiString; BSONObject: IBSONObject): IWriteResult; overload;
    function Insert(DB, Collection: AnsiString; BSONObjects: Array of IBSONObject): IWriteResult; overload;

    function Update(DB: AnsiString; Collection: AnsiString; Query, BSONObject: IBSONObject): IWriteResult;overload;
    function Update(DB: AnsiString; Collection: AnsiString; Query, BSONObject: IBSONObject; Upsert, Multi: Boolean): IWriteResult;overload;
    function UpdateMulti(DB: AnsiString; Collection: AnsiString; Query: IBSONObject; BSONObject: IBSONObject): IWriteResult;

    function Remove(DB, Collection: AnsiString; AObject: IBSONObject): IWriteResult;

    function FindOne(DB, Collection: AnsiString): IBSONObject; overload;
    function FindOne(DB, Collection: AnsiString; Query: IBSONObject): IBSONObject; overload;
    function FindOne(DB, Collection: AnsiString; Query, Fields: IBSONObject): IBSONObject; overload;

    function OpenQuery(AStream: TBSONStream; DB, Collection: AnsiString; Query, Fields: IBSONObject; ASkip, ABatchSize: Integer): IBSONObject;
    function HasNext(AStream: TBSONStream; DB: AnsiString; Collection: AnsiString;  ACursorId: Int64; ABatchSize: Integer): IBSONObject;

    procedure KillCursor(ACursorId: Int64);
    procedure KillCursors(ACursorId: Array of Int64);

    function Authenticate(const DB, AUserName, APassword: AnsiString): Boolean;
    procedure Logout(const DB: AnsiString);

    function CreateIndex(DB: AnsiString; Collection: AnsiString; KeyFields: IBSONObject; AIndexName: AnsiString): IWriteResult;

    property Connected: Boolean read GetConnected write SetConnected;
    property Active: Boolean read GetActive write SetActive;
    property ServerAddr: AnsiString read GetServerAddr write SetServerAddr;
    property ServerPort: Word read GetServerPort write SetServerPort;
   //TODO - Assert socket is Connected
  end;

implementation

uses
  MongoException, Windows, BSON, Variants, Math
  , unitMd5 
;

{ TDefaultMongoProvider }
constructor TDefaultMongoProvider.Create;
begin
  inherited;
  FConnected := False; 

  {$IFDEF SYNAPSE}
  FSocket := TTCPBlockSocket.Create;
  {$ELSE}
  FSocket := TTcpClient.Create(nil);
  {$ENDIF}     

  FQueueRequests := TStringList.Create;
end;

destructor TDefaultMongoProvider.Destroy;
begin
  FQueueRequests.Free;
  Close;
  FSocket.Free;
  inherited;
end;

function TDefaultMongoProvider.FindOne(DB, Collection: AnsiString; Query: IBSONObject): IBSONObject;
begin
  Result := FindOne(DB, Collection, Query, TBSONObject.Empty);
end;

function TDefaultMongoProvider.GetLastError(DB: AnsiString; RequestId: Integer): ICommandResult;
begin
  if (RequestId > 0) and (RequestId <> FRequestId) then
  begin
    Result := nil;
    Exit;
  end;
  Result := RunCommand(DB, TBSONObject.NewFrom('getlasterror', 1));
end;

function TDefaultMongoProvider.Insert(DB, Collection: AnsiString; BSONObject: IBSONObject): IWriteResult;
begin
  Result := Insert(DB, Collection, [BSONObject]);
end;

function TDefaultMongoProvider.GetActive: Boolean;
begin
  Result := FActive;
end;

procedure TDefaultMongoProvider.SetActive(const _active: Boolean);
begin
  if FActive = _active then
    Exit;
  FActive := _active;

  if FActive then
    TryConnect        //FReactor.PostUserSignal(Self, C_SIGNAL_CONN, nil)
  else
  begin
    Close;
  end;
end;

function TDefaultMongoProvider.GetConnected: Boolean;
begin
  Result := FConnected;
end;

procedure TDefaultMongoProvider.SetConnected(const Value: Boolean);
begin
  FConnected := Value;
end;

procedure TDefaultMongoProvider.TryConnect;
begin
  if not FActive then
    Exit;

  if 0 = FServerPort then
    Exit;

  Close;

  {$IFDEF SYNAPSE}
  FSocket.Connect(AHost, IntToStr(APort));

  if (FSocket.LastError <> 0) then
  begin
    raise EMongoConnectionFailureException.CreateResFmt(@sMongoConnectionFailureException, [AHost, APort]);
  end
  else
    SetConnected(True);
  {$ELSE}
  FSocket.RemoteHost := FServerAddr;
  FSocket.RemotePort := TSocketPort(IntToStr(FServerPort));
  FSocket.Open;

  if not FSocket.Connected then
    raise EMongoConnectionFailureException.CreateResFmt(@sMongoConnectionFailureException, [FServerAddr, FServerPort])
  else
    SetConnected(FSocket.Connected);
  {$ENDIF}   
end;

procedure TDefaultMongoProvider.Close;
begin
  {$IFDEF SYNAPSE}
  FSocket.CloseSocket;
  {$ELSE}
  FSocket.Close;
  {$ENDIF}
end;

procedure TDefaultMongoProvider.ReadResponse(AStream: TBSONStream;
                                             ARequestId: Integer;
                                             var AFlags, ANumberReturned: Integer;
                                             var ACursorId: Int64
                                             );
var
  vResponse: TResponse;
begin
  vResponse := ReadResponse(AStream, ARequestId);
  try
    AFlags := vResponse.Flags;
    ANumberReturned := vResponse.NumberReturned;
    ACursorId := vResponse.CursorId;
  finally
    vResponse.Free;
  end;
end;

function TDefaultMongoProvider.RunCommand(DB: AnsiString; Command: IBSONObject): ICommandResult;
var
  vBSON: IBSONObject;
begin
  vBSON := FindOne(DB, COMMAND_COLLECTION, Command);

  Result := TCommandResult.Create;
  Result.PutAll(vBSON);
end;

procedure TDefaultMongoProvider.SetDecoder(const ADecoder: IMongoDecoder);
begin
  FDecoder := ADecoder;
end;

procedure TDefaultMongoProvider.SetEncoder(const AEncoder: IMongoEncoder);
begin
  FEncoder := AEncoder;
end;

function TDefaultMongoProvider.ReceiveBuf(var Buffer; Length: Integer): Integer;
begin
  {$IFDEF SYNAPSE}
  Result := FSocket.RecvBuffer(@Buffer, Length);
  {$ELSE}
  Result := FSocket.ReceiveBuf(Buffer, Length);
  {$ENDIF}
end;

function TDefaultMongoProvider.SendBuf(Buffer: Pointer; Length: Integer): Integer;
begin
  {$IFDEF SYNAPSE}
  Result := FSocket.SendBuffer(Buffer, Length);
  {$ELSE}
  Result := FSocket.SendBuf(Buffer^, Length);
  {$ENDIF}
end;

function TDefaultMongoProvider.OpenQuery(AStream: TBSONStream;
                                         DB, Collection: AnsiString;
                                         Query, Fields: IBSONObject;
                                         ASkip, ABatchSize: Integer
                                         ): IBSONObject;
var
  vNumberReturned: Integer;
  vFlags:integer;
  vCursorId: Int64;
begin
  Result := TBSONObject.NewFrom('requestId', FRequestId);

  BeginMsg(AStream, DB, Collection, OP_QUERY);

  AStream.WriteInt(ASkip);
  AStream.WriteInt(ABatchSize);

  FEncoder.SetBuffer(AStream);
  FEncoder.Encode(Query);

  if (Fields <> nil) and (Fields.Count > 0) then
  begin
     FEncoder.Encode(Fields);
  end;

  SendMsg(AStream);

  ReadResponse(AStream, FRequestId, vFlags, vNumberReturned, vCursorId);

  Result.Put('numberReturned', vNumberReturned);
  Result.Put('cursorId', vCursorId);
end;

function TDefaultMongoProvider.HasNext(AStream: TBSONStream;
                                       DB, Collection: AnsiString;
                                       ACursorId: Int64;
                                       ABatchSize: Integer
                                       ): IBSONObject;
var
  vFlags, vNumberReturned: Integer;
  vCursorId: Int64;
  vHasNext: Boolean;
begin
  vHasNext := False;
  vFlags := 0;
  vNumberReturned := 0;
  vCursorId := 0;

  if ACursorId > 0 then
  begin
    BeginMsg(AStream, DB, Collection, OP_GET_MORE);

    AStream.WriteInt(ABatchSize);
    AStream.WriteInt64(ACursorId);

    SendMsg(AStream);

    ReadResponse(AStream, FRequestId, vFlags, vNumberReturned, vCursorId);

    vHasNext := vNumberReturned <> 0;

    if (vFlags and $0001)<>0 then raise
      Exception.Create('Query: cursor not found');
  end;

  Result := TBSONObject.NewFrom('requestId', FRequestId)
                           .Put('hasNext', vHasNext)
                           .Put('numberReturned', vNumberReturned)
                           .Put('cursorId', vCursorId);
end;

procedure TDefaultMongoProvider.BeginMsg(AStream: TBSONStream; OperationCode: Integer);
begin
  InterlockedIncrement(FRequestId);

  AStream.Clear;
  AStream.WriteInt(0); //length
  AStream.WriteInt(FRequestId);
  AStream.WriteInt(0);//ResponseTo
  AStream.WriteInt(OperationCode);
  AStream.WriteInt(0);//Flags
end;

procedure TDefaultMongoProvider.BeginMsg(AStream: TBSONStream; DB, Collection: AnsiString; OperationCode: Integer);
begin
  BeginMsg(AStream, OperationCode);
  
  AStream.WriteUTF8String(Format('%s.%s', [DB, Collection]));
end;

procedure TDefaultMongoProvider.ReadResponse(AStream: TBSONStream;ARequestId: Integer; var AFlags, ANumberReturned: Integer);
var
  vCursorId: Int64;
begin
  ReadResponse(AStream, ARequestId, AFlags, ANumberReturned, vCursorId);
end;

function TDefaultMongoProvider.FindOne(DB, Collection: AnsiString): IBSONObject;
begin
  Result := FindOne(DB, Collection, TBSONObject.Empty);
end;

function TDefaultMongoProvider.FindOne(DB, Collection: AnsiString; Query, Fields: IBSONObject): IBSONObject;
var
  vStream: TBSONStream;
  vResponse: TResponse;
begin
  vStream := TBSONStream.Create;
  try
    BeginMsg(vStream, DB, Collection, OP_QUERY);
    vStream.WriteInt(0); //NumberToSkip
    vStream.WriteInt(1); //NumberToReturn

    if (Query = nil) then
    begin
      Query := TBSONObject.Create;
    end;

    FEncoder.SetBuffer(vStream);
    FEncoder.Encode(Query);

    if (Fields <> nil) and (Fields.Count > 0) then
    begin
      FEncoder.Encode(Fields);
    end;

    SendMsg(vStream);

    vResponse := ReadResponse(vStream, FRequestId);
    try
     //To capture a response
      vStream.Position := 0;
//      vStream.SaveToFile('XXX.stream');
      vStream.Position := 36;

      if vResponse.NumberReturned = 0 then
        Result := nil
      else
        Result := FDecoder.Decode(vStream);
    finally
      vResponse.Free;
    end;
  finally
    vStream.Free;
  end;
end;

function TDefaultMongoProvider.Remove(DB, Collection: AnsiString; AObject: IBSONObject): IWriteResult;
var
  vStream: TBSONStream;
begin
  vStream := TBSONStream.Create;
  try
    BeginMsg(vStream, DB, Collection, OP_DELETE);

    if AObject.HasOid then
    begin
      vStream.WriteInt(1); //Single Remove

      //Optimization to use only _id 
      AObject := TBSONObjectQueryHelper.NewFilterOid(AObject);
    end
    else
      vStream.WriteInt(0);

    FEncoder.SetBuffer(vStream);
    FEncoder.Encode(AObject);

    SendMsg(vStream);

    Result := TWriteResult.Create(Self, DB, FRequestId);
  finally
    vStream.Free;
  end;
end;

procedure TDefaultMongoProvider.KillCursor(ACursorId: Int64);
begin
  KillCursors([ACursorId]);
end;

procedure TDefaultMongoProvider.KillCursors(ACursorId: array of Int64);
const
  MAX_CURSORS_PER_BATCH = 2;
var
  vStream: TBSONStream;
  vTotalCursors: Integer;
  i, soFar, totalSoFar: Integer;
begin
  vStream := TBSONStream.Create;
  try
    vTotalCursors := Length(ACursorId);
    soFar := 0;
    totalSoFar := 0;

    BeginMsg(vStream, OP_KILL_CURSORS);
    vStream.WriteInt(Min(MAX_CURSORS_PER_BATCH, vTotalCursors));

    for i := Low(ACursorId) to High(ACursorId) do
    begin
      vStream.WriteInt64(ACursorId[i]);

      Inc(soFar);
      Inc(totalSoFar);

      if (soFar = MAX_CURSORS_PER_BATCH) then
      begin
        SendMsg(vStream);

        BeginMsg(vStream, OP_KILL_CURSORS);
        vStream.WriteInt(Min(MAX_CURSORS_PER_BATCH, vTotalCursors - totalSoFar));
        soFar := 0;
      end;
    end;

    SendMsg(vStream);
  finally
    vStream.Free;
  end;
end;

procedure TDefaultMongoProvider.SendMsg(AStream: TBSONStream);
var
  vLength: Integer;
begin
  vLength := AStream.Size;

  AStream.WriteInt(0, vLength);

  SendBuf(AStream.Memory, vLength);
end;

function TDefaultMongoProvider.Insert(DB, Collection: AnsiString; BSONObjects: array of IBSONObject): IWriteResult;
var
  vStream: TBSONStream;
  i: Integer;
begin
  vStream := TBSONStream.Create;
  try
    BeginMsg(vStream, DB, Collection, OP_INSERT);

    FEncoder.SetBuffer(vStream);

    for i := Low(BSONObjects) to High(BSONObjects) do
    begin
      FEncoder.Encode(BSONObjects[i]);
    end;

    SendMsg(vStream);

    Result := TWriteResult.Create(Self, DB, FRequestId);
  finally
    vStream.Free;
  end;
end;

function TDefaultMongoProvider.Update(DB, Collection: AnsiString;
                                      Query, BSONObject: IBSONObject
                                      ): IWriteResult;
begin
  Update(DB, Collection, Query, BSONObject, False, False);
end;

function TDefaultMongoProvider.Update(DB, Collection: AnsiString;
                                      Query,BSONObject: IBSONObject;
                                      Upsert, Multi: Boolean
                                      ): IWriteResult;
var
  vStream: TBSONStream;
  vUpsertOp: Integer;
begin
  vStream := TBSONStream.Create;
  try
    BeginMsg(vStream, DB, Collection, OP_UPDATE);

    vUpsertOp := 0;
    if Upsert then
      Inc(vUpsertOp, 1);

    if Multi then
      Inc(vUpsertOp, 2);

    vStream.WriteInt(vUpsertOp);

    FEncoder.SetBuffer(vStream);

    if Query.HasOid then
    begin
      Query := TBSONObjectQueryHelper.NewFilterOid(Query);
    end;

    FEncoder.Encode(Query);
    FEncoder.Encode(BSONObject);

    SendMsg(vStream);

    Result := TWriteResult.Create(Self, DB, FRequestId);
  finally
    vStream.Free;
  end;
end;

function TDefaultMongoProvider.UpdateMulti(DB, Collection: AnsiString;
                                           Query,BSONObject: IBSONObject
                                           ): IWriteResult;
begin
  Result := Update(DB, Collection, Query, BSONObject, False, True);
end;

function TDefaultMongoProvider.Authenticate(const DB, AUserName, APassword: AnsiString): Boolean;
var
  vHash, vKey: AnsiString;
  vCommandResult: ICommandResult;
  vNonce: TBSONItem;
  vAuthCommand: IBSONObject;
begin
  vCommandResult := RunCommand(DB, TBSONObject.NewFrom('getnonce', 1));

  vCommandResult.RaiseOnError;

  vNonce := vCommandResult.Items['nonce'];

  vHash := MakeHash(AUserName, APassword);

  vKey := MD5EncryptString(vNonce.AsString + AUserName + vHash);

  vAuthCommand := TBSONObject.Create;
  vAuthCommand.put('authenticate', 1);
  vAuthCommand.put('user', AUserName);
  vAuthCommand.put('nonce', vNonce.AsString);
  vAuthCommand.put('key', vKey);

  vCommandResult := RunCommand(DB, vAuthCommand);

  Result := vCommandResult.Ok;

  vCommandResult.RaiseOnError;
end;

function TDefaultMongoProvider.MakeHash(const AUserName, APassword: AnsiString): AnsiString;
begin
  Result := MD5EncryptString(AUserName + ':mongo:' + APassword);
end;

procedure TDefaultMongoProvider.Logout(const DB: AnsiString);
begin
  RunCommand(DB, TBSONObject.NewFrom('logout', 1));
end;

function TDefaultMongoProvider.ReadResponse(AStream: TBSONStream; ARequestId: Integer): TResponse;
const
  dSize = $10000;
var
  i,l: integer;
  buf: array[0..2] of integer;
  d: array[0..dSize-1] of byte;
begin
  repeat
    //MsgLength,RequestID,ResponseTo
    i := ReceiveBuf(buf[0],12);
    if i <> 12 then
      raise EMongoInvalidResponse.CreateResFmt(@sMongoInvalidResponse, [ARequestId]);

    if buf[2] = ARequestId then
    begin
      //forward start of header
      AStream.Position := 0;
      AStream.Write(buf[0], 12);

      l := buf[0]-12;
      while l > 0 do
      begin
        if l < dSize then
          i := l
        else
          i := dSize;

        i:= ReceiveBuf(d[0],i);

        if i=0 then
          raise EMongoReponseAborted.CreateResFmt(@sMongoReponseAborted, [ARequestId]);

        AStream.Write(d[0],i);
        dec(l,i);
      end;

      //set position after message header
      if buf[0] < 36 then
        AStream.Position := buf[0]
      else
        AStream.Position := 36;
    end;
  until buf[2]= ARequestID;

  AStream.Position := 0;


  Result := TResponse.Create;    
  with Result do
  begin
    Length := AStream.ReadInt;
    RequestID := AStream.ReadInt;
    ResponseTo := AStream.ReadInt;
    OpCode := AStream.ReadInt;
    Flags := AStream.ReadInt;
    CursorId := AStream.ReadInt64;
    StartingFrom := AStream.ReadInt;
    NumberReturned := AStream.ReadInt;
  end;
end;

function TDefaultMongoProvider.CreateIndex(DB, Collection: AnsiString;
                                           KeyFields: IBSONObject;
                                           AIndexName: AnsiString
                                           ): IWriteResult;
var
  vIndexOptions: IBSONObject;
begin
  vIndexOptions := TBSONObject.NewFrom('name', AIndexName).Put('ns', Format('%s.%s', [DB, Collection])).Put('key', KeyFields);

  Result := Insert(DB, SYSTEM_INDEXES_COLLECTION, vIndexOptions);
end;

function TDefaultMongoProvider.GetServerAddr: AnsiString;
begin
  Result := FServerAddr;
end;

function TDefaultMongoProvider.GetServerPort: Word;
begin
  Result := FServerPort;
end;

procedure TDefaultMongoProvider.SetServerAddr(const Value: AnsiString);
begin
  FServerAddr := Value;
end;

procedure TDefaultMongoProvider.SetServerPort(const Value: Word);
begin
  FServerPort := Value;
end;

{ TWriteResult }
constructor TWriteResult.Create(const AProvider: IMongoProvider;
                                const ADB: AnsiString;
                                const ARequestId: Integer
                                );
begin
  FProvider := AProvider;
  FDB := ADB;
  FRequestId := ARequestId;
end;

function TWriteResult.getCachedLastError: ICommandResult;
begin
  Result := ICommandResult(FLastErrorResult);
end;

function TWriteResult.getLastError: ICommandResult;
begin
  if Assigned(FLastErrorResult) then
  begin
    Result := FLastErrorResult
  end
  else
  begin
    Result := FProvider.GetLastError(FDB, FRequestId);

    FLastErrorResult := Result;
  end;
end;

{ TCommandResult }

function TCommandResult.GetCode: Integer;
var
  vCode: TBSONItem;
begin
  Result := -1;

  vCode := Find('code');

  if (vCode <> nil) then
  begin
    Result := vCode.Value;
  end;
end;

function TCommandResult.GetErrorMessage: AnsiString;
var
  vErrorMsg: TBSONItem;
begin
  vErrorMsg := Find('err');
  if (vErrorMsg = nil) then
  begin
    vErrorMsg := Find('errmsg');
  end;

  Result := EmptyStr;
  if Assigned(vErrorMsg) then
  begin
    Result := vErrorMsg.AsString;
  end;
end;

function TCommandResult.GetException: Exception;
var
  cmdName, vMessage: AnsiString;
  vError: TBSONItem;
  vCode: Integer;
begin
  Result := nil;
  
  if not Ok then
  begin
    cmdName := Item[0].AsString;

    vMessage := Format('command failed [%s]' + sLineBreak{  + Self.ToString}, [cmdName]);

    Result := ECommandFailure.Create(vMessage);
  end
  else
  begin
    // GLE check
    if HasError then
    begin
      vError := Items['err'];

      vCode := getCode();

      if (vCode = 11000) or (vCode = 11001) or (Pos('E11000', vError.AsString) = 1) or (Pos('E11001', vError.AsString) = 1) then
        Result := EMongoDuplicateKey.Create(vCode, vError.AsString)
      else
        Result := EMongoException.Create(vCode, vError.AsString);
    end;
  end;
end;

function TCommandResult.HasError: Boolean;
var
  vOK: TBSONItem;
begin
  vOK := Items['err'];

  Result := Length(vOK.AsString) > 1;
end;

function TCommandResult.Ok: Boolean;
var
  vOK: TBSONItem;
begin
  vOK := Items['ok'];

  Result := (vOK.Value = True) or (vOK.Value = Ord(True));
end;

procedure TCommandResult.RaiseOnError;
var
  vException: Exception;
begin
  if (not Ok) or HasError then
  begin
    vException := GetException;

    if (vException <> nil) then
    begin
      raise vException;
    end;
  end;
end;

end.
