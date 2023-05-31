package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"sync"
	"time"

	"github.com/gin-gonic/gin"

	"go.opentelemetry.io/contrib/instrumentation/github.com/gin-gonic/gin/otelgin"
	"go.opentelemetry.io/contrib/instrumentation/runtime"
	"go.opentelemetry.io/contrib/instrumentation/host"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetrichttp"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/propagation"
	sdkmetric "go.opentelemetry.io/otel/sdk/metric"
	sdkresource "go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.20.0"
)

var (
	appName             string = "DEFAULT_APP"
	projectName         string = "DEFAULT_PROJECT"
	appVersion          string = "DEFAULT_VERSION"
	otelTracesEndpoint  string
	otelMetricsEndpoint string
	resource            *sdkresource.Resource
	initResourcesOnce   sync.Once
)

type album struct {
	ID     string  `json:"id"`
	Title  string  `json:"title"`
	Artist string  `json:"artist"`
	Price  float64 `json:"price"`
}

var albums = []album{
	{ID: "1", Title: "Blue Train", Artist: "John Coltrane", Price: 56.99},
	{ID: "2", Title: "Jeru", Artist: "Gerry Mulligan", Price: 17.99},
	{ID: "3", Title: "Sarah Vaughan and Clifford Brown", Artist: "Sarah Vaughan", Price: 39.99},
}

func getAlbums(c *gin.Context) {
	c.IndentedJSON(http.StatusOK, albums)
}

func postAlbums(c *gin.Context) {
	var newAlbum album

	if err := c.BindJSON(&newAlbum); err != nil {
		return
	}

	albums = append(albums, newAlbum)
	c.IndentedJSON(http.StatusCreated, newAlbum)
}

func getAlbumByID(c *gin.Context) {
	id := c.Param("id")

	for _, a := range albums {
		if a.ID == id {
			c.IndentedJSON(http.StatusOK, a)
			return
		}
	}
	c.IndentedJSON(http.StatusNotFound, gin.H{"message": "album not found"})
}

func main() {
	readConfigFromEnv()
	ctx := context.Background()
	tracerShutdown, err := initTracer(ctx)
	if err != nil {
		log.Printf("Failed to start Tracing.")
	} else {
		defer tracerShutdown()
	}
	meterShutdown, err := initMeter(ctx)
	if err != nil {
		log.Printf("Failed to start Metris.")
	} else {
		defer meterShutdown()
	}

	router := gin.New()
	router.Use(otelgin.Middleware(fmt.Sprintf("%s-server", appName)))

	router.GET("/albums", getAlbums)
	router.GET("/albums/:id", getAlbumByID)
	router.POST("/albums", postAlbums)

	router.Run(":8090")
}

func readConfigFromEnv() {
	if value, exists := os.LookupEnv("APP_NAME"); exists {
		appName = value
	}
	if value, exists := os.LookupEnv("PROJECT_NAME"); exists {
		projectName = value
	}
	if value, exists := os.LookupEnv("APP_VERSION"); exists {
		appVersion = value
	}
	if value, exists := os.LookupEnv("OTEL_EXPORTER_OTLP_TRACES_ENDPOINT"); exists {
		otelTracesEndpoint = value
	}
	if value, exists := os.LookupEnv("OTEL_EXPORTER_OTLP_METRICS_ENDPOINT"); exists {
		otelMetricsEndpoint = value
	}
}

func initResource(ctx context.Context) *sdkresource.Resource {
	initResourcesOnce.Do(func() {
		extraResources, err := sdkresource.New(
			ctx,
			sdkresource.WithAttributes(
				semconv.ServiceName(fmt.Sprintf("%s:%s:%s", appName, projectName, appVersion)),
				semconv.ServiceNamespace(projectName),
				semconv.ServiceVersion(appVersion),
			),
			sdkresource.WithOS(),
			sdkresource.WithProcess(),
			sdkresource.WithContainer(),
			sdkresource.WithHost(),
		)
		if err != nil {
			log.Printf("Failed to create OTEL resource")
		}
		resource, _ = sdkresource.Merge(
			sdkresource.Default(),
			extraResources,
		)
	})
	return resource
}

func initTracer(ctx context.Context) (func(), error) {
	traceExporter, err := otlptracehttp.New(
		ctx,
		otlptracehttp.WithEndpoint(otelTracesEndpoint),
		otlptracehttp.WithURLPath("/v1/traces"),
		otlptracehttp.WithInsecure(),
	)
	if err != nil {
		return nil, err
	}

	batchSpanProcessor := sdktrace.NewBatchSpanProcessor(traceExporter)
	tracerProvider := sdktrace.NewTracerProvider(
		sdktrace.WithSampler(sdktrace.AlwaysSample()),
		sdktrace.WithResource(initResource(ctx)),
		sdktrace.WithSpanProcessor(batchSpanProcessor),
	)
	otel.SetTracerProvider(tracerProvider)
	otel.SetTextMapPropagator(propagation.TraceContext{})

	return func() {
		if err := tracerProvider.Shutdown(ctx); err != nil {
			log.Printf("Error shutting down tracer provider: %v", err)
		}
	}, nil
}

func initMeter(ctx context.Context) (func(), error) {
	metricsExporter, err := otlpmetrichttp.New(
		ctx,
		otlpmetrichttp.WithEndpoint(otelMetricsEndpoint),
		otlpmetrichttp.WithURLPath("/v1/metrics"),
		otlpmetrichttp.WithInsecure(),
	)
	if err != nil {
		return nil, err
	}

	meterProvider := sdkmetric.NewMeterProvider(
		sdkmetric.WithReader(sdkmetric.NewPeriodicReader(metricsExporter)),
		sdkmetric.WithResource(initResource(ctx)),
	)
	otel.SetMeterProvider(meterProvider)

	return func() {
		if err := meterProvider.Shutdown(ctx); err != nil {
			log.Printf("Error shutting down metrics provider: %v", err)
		}
	}, nil
}

func startInstrumentation() {
	log.Print("Starting host instrumentation:")
	err := host.Start(host.WithMeterProvider(otel.GetMeterProvider()))
	if err != nil {
		log.Fatal(err)
	}

	log.Print("Starting runtime instrumentation:")
	err = runtime.Start(runtime.WithMinimumReadMemStatsInterval(time.Second))
	if err != nil {
		log.Fatal(err)
	}
}