program Horse.OpenTelemetry.Tests;

{$IFNDEF FPC}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
  {$IFDEF FPC}
  SysUtils,
  {$ELSE}
  System.SysUtils,
  {$ENDIF}
  Horse.OpenTelemetry.Tests.Cases in 'Horse.OpenTelemetry.Tests.Cases.pas';

begin
  try
    RunAllTests;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
