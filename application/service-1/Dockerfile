FROM golang:1.19.4 AS builder

RUN mkdir /go/app
WORKDIR /go/app
COPY go.mod ./
COPY main.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -o app 


#FROM alpine:3.17.0

#COPY --from=builder /go/app/app /app
#EXPOSE 8090
#CMD ["/app"]
