program Sample;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Horse,
  Horse.OpenTelemetry;

begin
  // Registra o middleware do OpenTelemetry
  THorse.Use(THorseOpenTelemetry.Middleware());

  THorse.Get('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse)
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
    end);

  Writeln('Servidor de teste rodando em http://localhost:9000/ping');
  THorse.Listen(9000);
end.
