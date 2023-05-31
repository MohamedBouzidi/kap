FROM golang:1.19.4 AS builder

RUN mkdir /go/app
WORKDIR /go/app
COPY go.mod ./
COPY go.sum ./
COPY main.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -o app
RUN useradd --no-create-home --shell /sbin/nologin --user-group --uid 10001 appuser


FROM scratch

COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group
COPY --from=builder /go/app/app /app
USER appuser:appuser
EXPOSE 8090
CMD ["/app"]
