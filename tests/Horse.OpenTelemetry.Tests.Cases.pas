unit Horse.OpenTelemetry.Tests.Cases;

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

procedure RunAllTests;

implementation

uses
  {$IFDEF FPC}
    SysUtils, Classes,
  {$ELSE}
    System.SysUtils, System.Classes,
  {$ENDIF}
  Horse.OpenTelemetry;

var
  GTestsFailed: Integer = 0;
  GTestsPassed: Integer = 0;

procedure AssertEqual(const AExpected, AActual: string; const AMessage: string);
begin
  if AExpected <> AActual then
  begin
    Writeln('[FAIL] ', AMessage, ' - Expected: "', AExpected, '", Actual: "', AActual, '"');
    Inc(GTestsFailed);
  end
  else
  begin
    Writeln('[PASS] ', AMessage);
    Inc(GTestsPassed);
  end;
end;

procedure AssertTrue(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
  begin
    Writeln('[FAIL] ', AMessage, ' - Expected: True, Actual: False');
    Inc(GTestsFailed);
  end
  else
  begin
    Writeln('[PASS] ', AMessage);
    Inc(GTestsPassed);
  end;
end;

type
  THorseOpenTelemetryExposed = class(THorseOpenTelemetry)
  public
    class function GenerateRandomHex(const ALen: Integer): string;
    class procedure ParseTraceParent(const AHeader: string; out ATraceId, AParentSpanId: string);
  end;

class function THorseOpenTelemetryExposed.GenerateRandomHex(const ALen: Integer): string;
begin
  Result := inherited GenerateRandomHex(ALen);
end;

class procedure THorseOpenTelemetryExposed.ParseTraceParent(const AHeader: string; out ATraceId, AParentSpanId: string);
begin
  inherited ParseTraceParent(AHeader, ATraceId, AParentSpanId);
end;

procedure TestContextCreation;
var
  LContext: THorseOpenTelemetryContext;
begin
  Writeln('--- TestContextCreation ---');
  LContext := THorseOpenTelemetryContext.Create('trace123', 'span123', 'parent123');
  try
    AssertEqual('trace123', LContext.TraceId, 'Context TraceId');
    AssertEqual('span123', LContext.SpanId, 'Context SpanId');
    AssertEqual('parent123', LContext.ParentSpanId, 'Context ParentSpanId');
  finally
    LContext.Free;
  end;
end;

procedure TestParseTraceParent;
var
  LTraceId, LParentSpanId: string;
begin
  Writeln('--- TestParseTraceParent ---');
  
  // Caso 1: Válido
  THorseOpenTelemetryExposed.ParseTraceParent('00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01', LTraceId, LParentSpanId);
  AssertEqual('4bf92f3577b34da6a3ce929d0e0e4736', LTraceId, 'Parse TraceParent Válido (TraceId)');
  AssertEqual('00f067aa0ba902b7', LParentSpanId, 'Parse TraceParent Válido (ParentSpanId)');

  // Caso 2: Inválido
  THorseOpenTelemetryExposed.ParseTraceParent('invalid-format', LTraceId, LParentSpanId);
  AssertEqual('', LTraceId, 'Parse TraceParent Inválido (TraceId)');
  AssertEqual('', LParentSpanId, 'Parse TraceParent Inválido (ParentSpanId)');

  // Caso 3: Vazio
  THorseOpenTelemetryExposed.ParseTraceParent('', LTraceId, LParentSpanId);
  AssertEqual('', LTraceId, 'Parse TraceParent Vazio (TraceId)');
  AssertEqual('', LParentSpanId, 'Parse TraceParent Vazio (ParentSpanId)');
end;

procedure TestGenerateRandomHex;
var
  LHex16, LHex32: string;
  I: Integer;
begin
  Writeln('--- TestGenerateRandomHex ---');
  LHex16 := THorseOpenTelemetryExposed.GenerateRandomHex(16);
  LHex32 := THorseOpenTelemetryExposed.GenerateRandomHex(32);

  AssertEqual('16', IntToStr(Length(LHex16)), 'Comprimento hexadecimal de 16 caracteres');
  AssertEqual('32', IntToStr(Length(LHex32)), 'Comprimento hexadecimal de 32 caracteres');

  // Verificar se são caracteres válidos em hexadecimal [0-9a-f]
  for I := 1 to Length(LHex16) do
    AssertTrue(LHex16[I] in ['0'..'9', 'a'..'f'], 'Caractere hexadecimal válido em LHex16[' + IntToStr(I) + ']');

  for I := 1 to Length(LHex32) do
    AssertTrue(LHex32[I] in ['0'..'9', 'a'..'f'], 'Caractere hexadecimal válido em LHex32[' + IntToStr(I) + ']');
end;

procedure RunAllTests;
begin
  GTestsFailed := 0;
  GTestsPassed := 0;

  try
    TestContextCreation;
    TestParseTraceParent;
    TestGenerateRandomHex;
  except
    on E: Exception do
    begin
      Writeln('[CRITICAL ERROR] ', E.ClassName, ': ', E.Message);
      Inc(GTestsFailed);
    end;
  end;

  Writeln('======================================');
  Writeln('Test Results:');
  Writeln('  Passed: ', GTestsPassed);
  Writeln('  Failed: ', GTestsFailed);
  Writeln('======================================');

  if GTestsFailed > 0 then
    ExitCode := 1
  else
    ExitCode := 0;
end;

end.
