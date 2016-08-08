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
unit Mongo;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils, StrUtils, Math, Contnrs, Classes
  , Sockets
  , MongoEncoder
  , MongoDecoder
  , BSONStream
  , BSONTypes
  , MongoProvider
  , MongoDB
  , MongoConnector
  , WriteResult
  , CommandResult
  , MongoDBCursor
  , MongoCollection
  ;

type
  TMongo = class
  private  
    FConnected: Boolean;
    FActive: Boolean;

    FProvider: IMongoProvider;
    FEncoder: IMongoEncoder;
    FDecoder: IMongoDecoder;
    FDBList: TObjectList;
    FConnector: IMongoConnector;
    
    procedure SetEncoder(const Value: IMongoEncoder);
    procedure SetDecoder(const Value: IMongoDecoder);
    procedure SetActive(const Value: Boolean);
    procedure doActive(const Value: Boolean);
    function GetServerAddr: AnsiString;
    function GetServerPort: Word;
    procedure SetServerAddr(const Value: AnsiString);
    procedure SetServerPort(const Value: Word);
  public
    constructor Create;
    destructor Destroy; override;  

    function GetDB(const ADBname: AnsiString): TMongoDB;
    procedure GetDatabaseNames(AList: TStrings);
    procedure DropDatabase(const DBName: AnsiString);

    property Encoder: IMongoEncoder read FEncoder write SetEncoder;
    property Decoder: IMongoDecoder read FDecoder write SetDecoder;

    property Provider: IMongoProvider read FProvider;
    property Connected: Boolean read FConnected;
    property Active: Boolean read FActive write SetActive;
    property ServerAddr: AnsiString read GetServerAddr write SetServerAddr;
    property ServerPort: Word read GetServerPort write SetServerPort;
  end; 

implementation

uses
   MongoException
  , BSON
  , MongoDBApiLayer
  ;


{ TMongo } 
constructor TMongo.Create;
begin
  FProvider := TDefaultMongoProvider.Create;
  FDBList := TObjectList.Create;   

  SetEncoder(TMongoEncoderFactory.DefaultEncoder);
  SetDecoder(TMongoDecoderFactory.DefaultDecoder);
end;

destructor TMongo.Destroy;
begin
  FDBList.Free;
  inherited;
end;

procedure TMongo.GetDatabaseNames(AList: TStrings);
var
  vResult: ICommandResult;
  vDatabases: IBSONArray;
  i: Integer;
begin
  AList.Clear;

  vResult := FProvider.RunCommand('admin', TBSONObject.NewFrom('listDatabases', 1));

  vResult.RaiseOnError;

  vDatabases := vResult.Items['databases'].AsBSONArray;

  for i := 0 to vDatabases.Count - 1 do
  begin
    AList.Add(vDatabases[i].AsBSONObject.Items['name'].AsString);
  end;
end;

function TMongo.GetDB(const ADBname: AnsiString): TMongoDB;
begin
  Result := TMongoDBApiLayer.Create(Self, ADBname, FConnector, FProvider);

  FDBList.Add(Result);
end;

procedure TMongo.SetDecoder(const Value: IMongoDecoder);
begin
  FDecoder := Value;
  FProvider.SetDecoder(FDecoder);
end;

procedure TMongo.SetEncoder(const Value: IMongoEncoder);
begin
  FEncoder := Value;
  FProvider.SetEncoder(FEncoder);
end;

procedure TMongo.dropDatabase(const DBName: AnsiString);
begin
  FProvider.RunCommand(DBName, TBSONObject.NewFrom('dropDatabase', 1));
end;

procedure TMongo.SetActive(const Value: Boolean);
begin
  if FActive = Value then
    Exit;
  FActive := Value;

  doActive(Value);
end;

procedure TMongo.doActive(const Value: Boolean);
begin
  FProvider.Active := Value;
  FConnected := FProvider.Connected;
end;

function TMongo.GetServerAddr: AnsiString;
begin
  Result := FProvider.ServerAddr;
end;

function TMongo.GetServerPort: Word;
begin
  Result := FProvider.ServerPort;
end;

procedure TMongo.SetServerAddr(const Value: AnsiString);
begin
  FProvider.ServerAddr := Value;
end;

procedure TMongo.SetServerPort(const Value: Word);
begin
  FProvider.ServerPort := Value;
end;

end.
