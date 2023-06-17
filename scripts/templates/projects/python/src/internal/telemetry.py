import os
import logging

from opentelemetry import trace, metrics
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter

from opentelemetry import metrics
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.exporter.otlp.proto.http.metric_exporter import OTLPMetricExporter

from opentelemetry.sdk.resources import (
    SERVICE_NAME,
    SERVICE_NAMESPACE,
    SERVICE_VERSION,
    Resource,
)


# Setup logger
logger = logging.getLogger("telemetry")

# Read environment variables
APP_NAME = os.getenv("APP_NAME", "DEFAULT_APP")
PROJECT_NAME = os.getenv("PROJECT_NAME", "DEFAULT_PROJECT")
APP_VERSION = os.getenv("APP_VERSION", "DEFAULT_VERSION")
TRACES_ENDPOINT = os.getenv("OTEL_EXPORTER_OTLP_TRACES_ENDPOINT")
METRICS_ENDPOINT = os.getenv("OTEL_EXPORTER_OTLP_METRICS_ENDPOINT")


def init_resource():
    return Resource(
        attributes={
            SERVICE_NAME: "{0}:{1}:{2}".format(APP_NAME, PROJECT_NAME, APP_VERSION),
            SERVICE_NAMESPACE: PROJECT_NAME,
            SERVICE_VERSION: APP_VERSION,
        }
    )


def init_tracer():
    if not TRACES_ENDPOINT:
        logging.warn("Failed to start Tracer: invalid endpoint")
        return
    trace_exporter = OTLPSpanExporter(
        endpoint="http://{0}/v1/traces".format(TRACES_ENDPOINT)
    )
    tracer_provider = TracerProvider(resource=init_resource())
    processor = BatchSpanProcessor(trace_exporter)
    tracer_provider.add_span_processor(processor)
    trace.set_tracer_provider(tracer_provider)


def get_tracer_provider():
    return trace.get_tracer_provider()


def shutdown_tracer():
    trace.get_tracer_provider().shutdown()


def init_meter():
    if not METRICS_ENDPOINT:
        logging.warn("Failed to start Metrics: invalid endpoint")
        return
    metrics_exporter = PeriodicExportingMetricReader(
        OTLPMetricExporter(endpoint="http://{0}/v1/metrics".format(METRICS_ENDPOINT))
    )
    meter_provider = MeterProvider(
        resource=init_resource(), metric_readers=[metrics_exporter]
    )
    metrics.set_meter_provider(meter_provider)


def get_meter_provider():
    return metrics.get_meter_provider()


def shutdown_meter():
    metrics.get_meter_provider().shutdown()
