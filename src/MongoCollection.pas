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
unit MongoCollection;

interface

uses
  MongoDBCursorIntf
  , BSONTypes
  , WriteResult
  , CommandResult
  ;

type
  TMongoCollection = class
  private

  protected
    function GetCollectionName: AnsiString; virtual; abstract;
    function GetFullName: AnsiString; virtual; abstract;
    function GetDBName: AnsiString; virtual; abstract;
  public
    function Find: IMongoDBCursor; overload; virtual; abstract;
    function Find(Query: IBSONObject): IMongoDBCursor; overload; virtual; abstract;
    function Find(Query, Fields: IBSONObject): IMongoDBCursor; overload; virtual; abstract;

    function Count(Limit: Integer = 0): Integer; overload; virtual; abstract;
    function Count(Query: IBSONObject; Limit: Integer = 0): Integer; overload; virtual; abstract;

    function CreateIndex(KeyFields: IBSONObject; AIndexName: AnsiString = ''): IWriteResult; virtual; abstract;

    procedure DropIndex(AIndexName: AnsiString); virtual; abstract;
    procedure DropIndexes; virtual; abstract;
    procedure Drop(); virtual; abstract;

    function Insert(const BSONObject: IBSONObject): IWriteResult; overload; virtual; abstract;
    function Insert(const BSONObjects: array of IBSONObject): IWriteResult; overload; virtual; abstract;

    function Update(Query, BSONObject: IBSONObject): IWriteResult; overload; virtual; abstract;
    function Update(Query, BSONObject: IBSONObject; Upsert, Multi: Boolean): IWriteResult; overload; virtual; abstract;
    function UpdateMulti(Query, BSONObject: IBSONObject): IWriteResult; virtual; abstract;

    function Remove(AObject: IBSONObject): IWriteResult; virtual; abstract;

    function FindOne(): IBSONObject; overload; virtual; abstract;
    function FindOne(Query: IBSONObject): IBSONObject; overload; virtual; abstract;
    function FindOne(Query, Fields: IBSONObject): IBSONObject; overload; virtual; abstract;
    
    function GetIndexInfo: IBSONArray; virtual; abstract;
    
    property DBName: AnsiString read GetDBName;
    property CollectionName: AnsiString read GetCollectionName;
    property FullName: AnsiString read GetFullName;
  end;
  
implementation


end.

