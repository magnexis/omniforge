program worker;

{$mode objfpc}

uses
  SysUtils;

function ExtractValue(const Source, Marker: string): string;
var
  StartPos, ValuePos, EndPos: Integer;
begin
  StartPos := Pos(Marker, Source);
  if StartPos = 0 then
    Exit('');
  ValuePos := StartPos + Length(Marker);
  EndPos := ValuePos;
  while (EndPos <= Length(Source)) and (Source[EndPos] <> '"') do
    Inc(EndPos);
  Result := Copy(Source, ValuePos, EndPos - ValuePos);
end;

procedure SendMessage(const MessageText: string);
begin
  WriteLn(MessageText);
  Flush(Output);
end;

var
  LineText, JobId, Body, Piece: string;
  StartPos, EndPos, CommaPos, Count: Integer;
  ProductValue: Int64;
begin
  while not EOF(Input) do
  begin
    ReadLn(LineText);
    if Pos('"type":"HELLO"', LineText) > 0 then
    begin
      SendMessage('{"type":"WELCOME","protocol":"ofp/1","workerId":"pascal-product-01","language":"pascal","runtimeVersion":"3.2.2","workerVersion":"0.1.0","status":"ready"}');
      SendMessage('{"type":"REGISTER","protocol":"ofp/1","workerId":"pascal-product-01","language":"pascal","runtimeVersion":"3.2.2","workerVersion":"0.1.0","capabilities":[{"name":"math.product"}]}');
    end
    else if Pos('"type":"REGISTER_ACK"', LineText) > 0 then
      Continue
    else if Pos('"type":"JOB_START"', LineText) > 0 then
    begin
      if Pos('"capability":"math.product"', LineText) = 0 then
        SendMessage('{"type":"JOB_ERROR","jobId":"unknown","error":"unsupported capability"}')
      else
      begin
        JobId := ExtractValue(LineText, '"jobId":"');
        if JobId = '' then
          JobId := 'job-unknown';
        SendMessage('{"type":"JOB_ACCEPTED","jobId":"' + JobId + '","status":"running"}');
        SendMessage('{"type":"JOB_LOG","jobId":"' + JobId + '","severity":"info","message":"starting math.product"}');
        StartPos := Pos('"numbers":[', LineText);
        ProductValue := 1;
        Count := 0;
        if StartPos > 0 then
        begin
          StartPos := StartPos + Length('"numbers":[');
          EndPos := StartPos;
          while (EndPos <= Length(LineText)) and (LineText[EndPos] <> ']') do
            Inc(EndPos);
          Body := Copy(LineText, StartPos, EndPos - StartPos);
          while Body <> '' do
          begin
            CommaPos := Pos(',', Body);
            if CommaPos > 0 then
            begin
              Piece := Trim(Copy(Body, 1, CommaPos - 1));
              Delete(Body, 1, CommaPos);
            end
            else
            begin
              Piece := Trim(Body);
              Body := '';
            end;
            if Piece <> '' then
            begin
              ProductValue := ProductValue * StrToInt(Piece);
              Inc(Count);
            end;
          end;
        end;
        if Count = 0 then
          ProductValue := 0;
        SendMessage('{"type":"JOB_RESULT","jobId":"' + JobId + '","output":{"count":' + IntToStr(Count) + ',"product":' + IntToStr(ProductValue) + '}}');
      end;
    end
    else if Pos('"type":"JOB_CANCEL"', LineText) > 0 then
    begin
      JobId := ExtractValue(LineText, '"jobId":"');
      if JobId = '' then
        JobId := 'job-unknown';
      SendMessage('{"type":"JOB_CANCELLED","jobId":"' + JobId + '","status":"cancelled"}');
    end
    else if Pos('"type":"SHUTDOWN"', LineText) > 0 then
    begin
      SendMessage('{"type":"SHUTDOWN_ACK","workerId":"pascal-product-01","status":"stopped"}');
      Halt(0);
    end;
  end;
end.
