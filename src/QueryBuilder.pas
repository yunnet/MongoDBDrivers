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
unit QueryBuilder;

interface

uses
  BsonTypes, SysUtils;

type
  TQueryOperators = (qoGreaterThan,
                     qoGreaterThanEquals,
                     qoLessThan,
                     qoLessThanEquals,
                     qoNotEquals,
                     qoIn,
                     qoNotIn,
                     qoMod,
                     qoAll,
                     qoSize,
                     qoExists,
                     qoWhere,
                     qoNear);

  TBsonTypes = (btDouble,
                btString,
                btObject,
                btArray,
                btBinary,
                btObjectId,
                btBoolean,
                btDate,
                btNull,
                btRegularExpression,
                btJavaScriptCode,
                btSymbol,
                btJavaScriptCodeWithScope,
                btinteger,
                btTimestamp,
                btInt64,
                btMinKey,
                btMaxKey);

  TQueryBuilder = class
  private
    FQuery: IBSONObject;
    FCurrentKey: AnsiString;

    function putKey(key: AnsiString): TQueryBuilder;
  protected
    constructor Create;
  public
    class function empty(): TQueryBuilder;
    class function query(key: AnsiString): TQueryBuilder;

    function build: IBSONObject;
    function buildAndFree: IBSONObject;

    function equals(value: Variant): TQueryBuilder;
    function andField(key: AnsiString): TQueryBuilder;

    function greaterThan(value: Variant): TQueryBuilder;                        //����
    function greaterThanEquals(value: Variant): TQueryBuilder;                  //���ڻ����
    function lessThan(value: Variant): TQueryBuilder;                           //С��
    function lessThanEquals(value: Variant): TQueryBuilder;                     //С�ڻ����
    function exists(value: Variant): TQueryBuilder;                             //����

    (*
    see http://www.mongodb.org/display/DOCS/Advanced+Queries
    
    function all(): TQueryBuilder;                     //����
    function exists(): TQueryBuilder;                  //����
    function greaterThan(): TQueryBuilder;             //����
    function greaterThanEquals(): TQueryBuilder;       //���ڻ����
    function lessThan(): TQueryBuilder;                //С��
    function lessThanEquals(): TQueryBuilder;          //С�ڻ����
    function notEquals(): TQueryBuilder;               //������
    function notIn(): TQueryBuilder;
    function modOp(): TQueryBuilder;
    function orOp(): TQueryBuilder;
    function inOp(): TQueryBuilder;
    function isOp(): TQueryBuilder;
    function size(): TQueryBuilder;
    function typeOp(AType: TBsonTypes): TQueryBuilder;
    function regex(): TQueryBuilder;

    see http://www.mongodb.org/display/DOCS/Geospatial+Indexing

    function nearOp(x, y: Double): TQueryBuilder;overload;
    function nearOp(x, y, maxDistance: Double): TQueryBuilder;overload;
    function withinBox(x, y, x2, y2: Double): TQueryBuilder;
    function withinCenter(x, y, radius: Double): TQueryBuilder;
    function withinPolygon(APolygon: IBSONObject): TQueryBuilder;
    *)
  end;

implementation

uses
  Variants;

{ TQueryBuilder }
constructor TQueryBuilder.Create;
begin
  FQuery := TBSONObject.Create;
end;

{: ���洴��  ��}
class function TQueryBuilder.empty: TQueryBuilder;
begin
  Result := TQueryBuilder.Create;
end;

{: ���洴��  ��}
class function TQueryBuilder.query(key: AnsiString): TQueryBuilder;
begin
  Result := TQueryBuilder.Create;

  Result.putKey(key);
end;

function TQueryBuilder.build: IBSONObject;
begin
  Result := FQuery;
end;

function TQueryBuilder.buildAndFree: IBSONObject;
begin
  Result := build;
  Free;
end;  

function TQueryBuilder.putKey(key: AnsiString): TQueryBuilder;
begin
  FQuery.Put(key, Null);
  FCurrentKey := key;

  Result := Self;
end;

function TQueryBuilder.andField(key: AnsiString): TQueryBuilder;
begin
  Result := putKey(key);
end;

{: ����  ��}
function TQueryBuilder.equals(value: Variant): TQueryBuilder;
begin
  FQuery.Put(FCurrentKey, value);

  Result := Self;
end;

{: ���� >��}
function TQueryBuilder.greaterThan(value: Variant): TQueryBuilder;
var
  json: IBSONObject;
  tmp_str: AnsiString;
begin
  json := TBSONObject.Create;
  json.Put('$gt', value);

  FQuery.Put(FCurrentKey, json);
  tmp_str := FQuery.AsJson;

  Result := Self;
end;

{: ���ڻ���� >= ��}
function TQueryBuilder.greaterThanEquals(value: Variant): TQueryBuilder;
var
  json: IBSONObject;
begin
  json := TBSONObject.Create;
  json.Put('$gte', value);
  FQuery.Put(FCurrentKey, json);

  Result := Self;
end;

{: С�� < ��}
function TQueryBuilder.lessThan(value: Variant): TQueryBuilder;
var
  json: IBSONObject;
begin
  json := TBSONObject.Create;
  json.Put('$lt', value);
  FQuery.Put(FCurrentKey, json);

  Result := Self;
end;

{: С�ڻ���� <=  ��}
function TQueryBuilder.lessThanEquals(value: Variant): TQueryBuilder;
var
  json: IBSONObject;
begin
  json := TBSONObject.Create;
  json.Put('$lte', value);
  FQuery.Put(FCurrentKey, json);

  Result := Self;
end;

{: ����  ��}
function TQueryBuilder.exists(value: Variant): TQueryBuilder;
var
  json: IBSONObject;
begin
  json := TBSONObject.Create;
  json.Put('$in', value);
  FQuery.Put(FCurrentKey, json);

  Result := Self;
end;

end.
