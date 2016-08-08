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
unit BSONDBRef;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses BsonTypes, MongoDB;

type
  TBSONDBRef = class(TBSONObject, IBSONDBRef)
  private
    FObjectId: IBSONObjectId;
    FDB: AnsiString;
    FCollection: AnsiString;
    FRefDoc: IBSONObject;
    function GetCollection: AnsiString;
    function GetDB: AnsiString;
    function GetObjectId: IBSONObjectId;
  public
    property DB: AnsiString read GetDB;
    property Collection: AnsiString read GetCollection;
    property ObjectId: IBSONObjectId read GetObjectId;

    constructor Create(const ADB, ACollection: AnsiString; const AObjectId: IBSONObjectId);

    class function NewFrom(const ADB, ACollection: AnsiString; const AObjectId: IBSONObjectId): IBSONDBRef;

    class function Fetch(ADB: TMongoDB; ARef: IBSONDBRef): IBSONObject;overload;
    class function Fetch(ADB: TMongoDB; AQuery: IBSONObject): IBSONObject;overload;

    function GetInstance: TObject;
  end;

implementation

uses SysUtils;

{ TBSONDBRef }

constructor TBSONDBRef.Create(const ADB, ACollection: AnsiString; const AObjectId: IBSONObjectId);
begin
  inherited Create;
  FDB := ADB;
  FCollection := ACollection;
  FObjectId := AObjectId;
end;

class function TBSONDBRef.Fetch(ADB: TMongoDB; ARef: IBSONDBRef): IBSONObject;
begin
  with TBSONDBRef(ARef.GetInstance) do
  begin
    if (FRefDoc = nil) then
    begin
      if (ADB.DBName <> ARef.DB) then
        raise Exception.CreateFmt('Must use same db.', []);

      FRefDoc := ADB.GetCollection(ARef.Collection).FindOne(TBSONObject.NewFrom('_id', ARef.ObjectId));
    end;

    Result := FRefDoc;
  end;
end;

class function TBSONDBRef.Fetch(ADB: TMongoDB;AQuery: IBSONObject): IBSONObject;
var
  vIndexRef, vIndexId: Integer;
begin
  Result := nil;

  if AQuery.Find('$ref', vIndexRef) and AQuery.Find('$id', vIndexId) then
  begin
    Result := ADB.GetCollection(AQuery.Item[vIndexRef].AsString).FindOne(TBSONObject.NewFrom('_id', AQuery.Item[vIndexId].AsString));
  end;
end;

function TBSONDBRef.GetCollection: AnsiString;
begin
  Result := FCollection;
end;

function TBSONDBRef.GetDB: AnsiString;
begin
  Result := FDB;
end;

function TBSONDBRef.GetInstance: TObject;
begin
  Result := Self; 
end;

function TBSONDBRef.GetObjectId: IBSONObjectId;
begin
  Result := FObjectId;
end;

class function TBSONDBRef.NewFrom(const ADB, ACollection: AnsiString; const AObjectId: IBSONObjectId): IBSONDBRef;
begin
  Result := TBSONDBRef.Create(ADB, ACollection, AObjectId);
end;


end.
