unit Horse.OpenTelemetry;

{$IF DEFINED(FPC)}
  {$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  {$IF DEFINED(FPC)}
    SysUtils, Classes, Generics.Collections,
  {$ELSE}
    System.StringHelper, System.SysUtils, System.Classes, System.Generics.Collections,
  {$ENDIF}
  Horse;

type
  THorseOpenTelemetryContext = class
  private
    FTraceId: string;
    FSpanId: string;
    FParentSpanId: string;
  public
    constructor Create(const ATraceId, ASpanId, AParentSpanId: string);
    property TraceId: string read FTraceId;
    property SpanId: string read FSpanId;
    property ParentSpanId: string read FParentSpanId;
  end;

  THorseOpenTelemetry = class
  strict private
    class function GenerateRandomHex(const ALen: Integer): string;
    class procedure ParseTraceParent(const AHeader: string; out ATraceId, AParentSpanId: string);
  public
    class function Middleware: THorseCallback;
  end;

implementation

{ THorseOpenTelemetryContext }

constructor THorseOpenTelemetryContext.Create(const ATraceId, ASpanId, AParentSpanId: string);
begin
  inherited Create;
  FTraceId := ATraceId;
  FSpanId := ASpanId;
  FParentSpanId := AParentSpanId;
end;

{ THorseOpenTelemetry }

class function THorseOpenTelemetry.GenerateRandomHex(const ALen: Integer): string;
const
  CHexChars = '0123456789abcdef';
var
  I: Integer;
begin
  Result := '';
  for I := 1 to ALen do
    Result := Result + CHexChars[Random(16) + 1];
end;

class procedure THorseOpenTelemetry.ParseTraceParent(const AHeader: string; out ATraceId, AParentSpanId: string);
var
  LParts: TArray<string>;
begin
  ATraceId := '';
  AParentSpanId := '';

  if AHeader = '' then
    Exit;

  // Formato W3C: 00-traceid-parentid-traceflags
  LParts := AHeader.Split(['-']);
  if (Length(LParts) >= 3) and (LParts[0] = '00') then
  begin
    ATraceId := LParts[1];
    AParentSpanId := LParts[2];
  end;
end;

class function THorseOpenTelemetry.Middleware: THorseCallback;
begin
  Result :=
    procedure(Req: THorseRequest; Res: THorseResponse; Next: {$IF DEFINED(FPC)}TNextProc{$ELSE}TProc{$ENDIF})
    var
      LTraceParent: string;
      LTraceId: string;
      LSpanId: string;
      LParentSpanId: string;
      LOtelContext: THorseOpenTelemetryContext;
      LStartTime: Int64;
      LEndTime: Int64;
      LElapsedSeconds: Double;
    begin
      // 1. Tenta obter o TraceParent do header da requisição
      LTraceParent := Req.Headers.Dictionary.Items['traceparent'];

      // 2. Extrai ou gera os IDs
      ParseTraceParent(LTraceParent, LTraceId, LParentSpanId);

      if LTraceId = '' then
        LTraceId := GenerateRandomHex(32);

      LSpanId := GenerateRandomHex(16);

      // 3. Cria o contexto OTel e armazena em Req.State (destruído automaticamente ao fim do ciclo de vida)
      LOtelContext := THorseOpenTelemetryContext.Create(LTraceId, LSpanId, LParentSpanId);
      Req.State.Add('otel.context', LOtelContext);

      // 4. Injeta os headers de rastreamento na resposta para fins de correlação
      Res.AddHeader('traceparent', Format('00-%s-%s-01', [LTraceId, LSpanId]));

      LStartTime := TThread.GetTickCount64;
      try
        Next();
      finally
        LEndTime := TThread.GetTickCount64;
        LElapsedSeconds := (LEndTime - LStartTime) / 1000.0;

        // Aqui, futuramente, o middleware pode empacotar a Span em uma requisição OTLP
        // e enviá-la para o OpenTelemetry Collector em segundo plano.
        // O escopo do Core e os metadados (Req.MatchedRoute, Res.Status) estão totalmente acessíveis:
        //   TraceID: LOtelContext.TraceId
        //   SpanID: LOtelContext.SpanId
        //   MatchedRoute: Req.MatchedRoute
        //   Status: Res.Status
        //   Duration: LElapsedSeconds
      end;
    end;
end;

initialization
  Randomize;

end.
