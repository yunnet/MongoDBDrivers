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
unit JsonWriter;

interface

uses BSONTypes;

type
  TJsonWriter = class
  private
    function WriteInterface(const val: IUnknown): AnsiString;

    function BsonObjectToJson(const ABSON: IBSONObject): AnsiString;
    function BsonArrayToJson(const ABSONArray: IBSONArray): AnsiString;

    function ItemToJson(AItem: TBSONItem): AnsiString;
    function ItemValueToJson(AItem: TBSONItem): AnsiString;

    function Indent(level: Integer): AnsiString;
  public
    function ToJson(const ABSON: IBSONObject): AnsiString;
    function ToJsonReadable(const ABSON: IBSONObject): AnsiString;

    function Beautifier(JsonText: AnsiString): AnsiString;
  end;

implementation

uses SysUtils, StrUtils;

{ TJsonWriter }

function TJsonWriter.Beautifier(JsonText: AnsiString): AnsiString;
var
  i: Integer;
  currentChar: Char;
  inString: Boolean;
  newJson: AnsiString;
  indentLevel: Integer;
begin
  inString := False;
  indentLevel := 0;
  for i := 1 to Length(JsonText) do
  begin
    currentChar := JsonText[i];

    case currentChar of
      '{', '[':
        begin
          if not inString then
          begin
            newJson := newJson + currentChar + sLineBreak + Indent(indentLevel + 1);
            Inc(indentLevel);
          end
          else
            newJson := newJson + currentChar;
        end;
      '}', ']':
        begin
         if not inString then
         begin
           Dec(indentLevel);
           newJson := newJson + sLineBreak + Indent(indentLevel) + currentChar;
         end
         else
           newJson := newJson + currentChar;
        end;
      ',':
        begin
          if not inString then
          begin
            newJson := newJson + ',' + sLineBreak + Indent(indentLevel);
          end
          else
            newJson := newJson + currentChar;
        end;
      ':':
        begin
          if not inString then
            newJson := newJson + ': '
          else
            newJson := newJson + currentChar;
        end;
      ' ', #13, #10:
        begin
          if inString then
          begin
            newJson := newJson + currentChar;
          end;
        end;
      '"':
        begin
           if (i > 1) and (JsonText[i - 1] <> '\') then
           begin
             inString := not inString;
           end;

           newJson := newJson + currentChar;
        end;
    else
      newJson := newJson + currentChar;
    end;
  end;

  Result := newJson;
end;

function TJsonWriter.BsonArrayToJson(const ABSONArray: IBSONArray): AnsiString;
var
  i: Integer;
begin
  Result := '[';
  for i := 0 to ABSONArray.Count-1 do
  begin
    Result := Result + ItemValueToJson(ABSONArray[i]);

    if (i < ABSONArray.Count-1) then
    begin
      Result := Result + ',';
    end;
  end;
  Result := Result + ']';
end;

function TJsonWriter.BsonObjectToJson(const ABSON: IBSONObject): AnsiString;
var
  i: Integer;
  vItem: TBSONItem;
begin
  Result := '{';

  for i := 0 to ABSON.Count-1 do
  begin
    vItem := ABSON[i];

    Result := Result + ItemToJson(vItem);
  end;

  Result := Result + '}';
end;

function TJsonWriter.Indent(level: Integer): AnsiString;
begin
  Result := DupeString('    ', level);
end;

function TJsonWriter.ItemToJson(AItem: TBSONItem): AnsiString;
begin
  Result := Format('"%s" : %s', [AItem.Name, ItemValueToJson(AItem)]);
end;

function TJsonWriter.ItemValueToJson(AItem: TBSONItem): AnsiString;
begin
  Result := EmptyStr;
  case AItem.ValueType of
    bvtNull: Result := 'null';
    bvtBoolean: Result := LowerCase(BoolToStr(AItem.AsBoolean, True));
    bvtInteger,
    bvtInt64: Result := IntToStr(AItem.AsInt64);
    bvtDouble: Result := StringReplace(FormatFloat('0.00', AItem.AsFloat),',', '.', []);
    bvtDateTime: Result := DateToStr(AItem.AsDateTime);
    bvtString: Result := '"' + AItem.AsString + '"';
    bvtInterface: Result := WriteInterface(IUnknown(AItem.Value));
  end;
end;

function TJsonWriter.ToJson(const ABSON: IBSONObject): AnsiString;
begin
  Result := WriteInterface(ABSON);
end;

function TJsonWriter.ToJsonReadable(const ABSON: IBSONObject): AnsiString;
begin
  Result := Beautifier(ToJson(ABSON));
end;

function TJsonWriter.WriteInterface(const val: IUnknown): AnsiString;
var
  vBsonArray: IBSONArray;
  vBsonObject: IBSONObject;
begin
  if Supports(val, IBSONArray, vBsonArray) then
  begin
    Result := BsonArrayToJson(vBsonArray);
  end
  else if Supports(val, IBsonObject, vBsonObject) then
  begin
    Result := BsonObjectToJson(vBsonObject);
  end;
end;

end.
