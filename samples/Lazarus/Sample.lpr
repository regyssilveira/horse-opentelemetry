program Sample;

{$MODE DELPHI}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  Horse,
  Horse.OpenTelemetry;

procedure GetPing(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  LOtelCtx: THorseOpenTelemetryContext;
begin
  // Recupera o contexto do OpenTelemetry de Req.State
  LOtelCtx := THorseOpenTelemetryContext(Req.State.Items['otel.context']);

  Writeln('--------------------------------------------------');
  Writeln('TraceID de entrada / gerado: ', LOtelCtx.TraceId);
  Writeln('SpanID gerado para esta request: ', LOtelCtx.SpanId);
  if LOtelCtx.ParentSpanId <> '' then
    Writeln('Parent SpanID recebido: ', LOtelCtx.ParentSpanId)
  else
    Writeln('Nenhum Parent SpanID recebido (Nova raiz de rastreamento)');
  Writeln('--------------------------------------------------');

  Res.Send('pong');
end;

begin
  // Registra o middleware do OpenTelemetry
  THorse.Use(THorseOpenTelemetry.Middleware);

  THorse.Get('/ping', GetPing);

  Writeln('Servidor de teste rodando em http://localhost:9000/ping');
  THorse.Listen(9000);
end.
