# horse-opentelemetry

OpenTelemetry middleware for **Horse**.

Provides context propagation and W3C Trace Context validation for Delphi APIs.

## ⚙️ Installation

Use the [Boss](https://github.com/HashLoad/boss) package manager:

```sh
boss install horse-opentelemetry
```

## ⚡️ Quick Start

```delphi
uses
  Horse,
  Horse.OpenTelemetry;

begin
  // Register the OpenTelemetry middleware
  THorse.Use(THorseOpenTelemetry.Middleware);

  THorse.Get('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      LOtelCtx: THorseOpenTelemetryContext;
    begin
      // Retrieve the current context from the Request.State
      LOtelCtx := THorseOpenTelemetryContext(Req.State.Items['otel.context']);
      
      // Access TraceID and SpanID in logs or outbound HTTP calls
      Writeln('Current TraceID: ', LOtelCtx.TraceId);
      Writeln('Current SpanID: ', LOtelCtx.SpanId);

      Res.Send('pong');
    end);

  THorse.Listen(9000);
end.
```

## 🔗 Distributed Tracing

This middleware automatically:
1. Validates the incoming W3C `traceparent` header (format `00-traceid-spanid-traceflags`).
2. Propagates the existing `TraceID` if present, or generates a new one.
3. Automatically injects the `traceparent` header into the HTTP response.
4. Cleans up the context object at the end of the request lifecycle automatically (preventing memory leaks).
