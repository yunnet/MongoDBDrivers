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

    function greaterThan(value: Variant): TQueryBuilder;                        //大于
    function greaterThanEquals(value: Variant): TQueryBuilder;                  //大于或等于
    function lessThan(value: Variant): TQueryBuilder;                           //小于
    function lessThanEquals(value: Variant): TQueryBuilder;                     //小于或等于
    function exists(value: Variant): TQueryBuilder;                             //包含

    (*
    see http://www.mongodb.org/display/DOCS/Advanced+Queries
    
    function all(): TQueryBuilder;                     //所有
    function exists(): TQueryBuilder;                  //包含
    function greaterThan(): TQueryBuilder;             //大于
    function greaterThanEquals(): TQueryBuilder;       //大于或等于
    function lessThan(): TQueryBuilder;                //小于
    function lessThanEquals(): TQueryBuilder;          //小于或等于
    function notEquals(): TQueryBuilder;               //不等于
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

{: 外面创建  。}
class function TQueryBuilder.empty: TQueryBuilder;
begin
  Result := TQueryBuilder.Create;
end;

{: 外面创建  。}
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

{: 等于  。}
function TQueryBuilder.equals(value: Variant): TQueryBuilder;
begin
  FQuery.Put(FCurrentKey, value);

  Result := Self;
end;

{: 大于 >。}
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

{: 大于或等于 >= 。}
function TQueryBuilder.greaterThanEquals(value: Variant): TQueryBuilder;
var
  json: IBSONObject;
begin
  json := TBSONObject.Create;
  json.Put('$gte', value);
  FQuery.Put(FCurrentKey, json);

  Result := Self;
end;

{: 小于 < 。}
function TQueryBuilder.lessThan(value: Variant): TQueryBuilder;
var
  json: IBSONObject;
begin
  json := TBSONObject.Create;
  json.Put('$lt', value);
  FQuery.Put(FCurrentKey, json);

  Result := Self;
end;

{: 小于或等于 <=  。}
function TQueryBuilder.lessThanEquals(value: Variant): TQueryBuilder;
var
  json: IBSONObject;
begin
  json := TBSONObject.Create;
  json.Put('$lte', value);
  FQuery.Put(FCurrentKey, json);

  Result := Self;
end;

{: 包含  。}
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
