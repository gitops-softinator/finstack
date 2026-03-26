const { NodeSDK } = require("@opentelemetry/sdk-node");
const { getNodeAutoInstrumentations } = require("@opentelemetry/auto-instrumentations-node");
const { OTLPTraceExporter } = require("@opentelemetry/exporter-trace-otlp-http");
const { resourceFromAttributes } = require("@opentelemetry/resources");
const { SemanticResourceAttributes } = require("@opentelemetry/semantic-conventions");

const traceExporter = new OTLPTraceExporter({
  url: "http://tempo:4318/v1/traces"
});

const sdk = new NodeSDK({
  traceExporter,
  instrumentations: [getNodeAutoInstrumentations()],
  resource: resourceFromAttributes({
    [SemanticResourceAttributes.SERVICE_NAME]: "notification-service"
  })
});

sdk.start();
