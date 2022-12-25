FROM golang:1.19.4

RUN mkdir /go/app
WORKDIR /go/app
COPY go.mod ./
COPY main.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -o app 
EXPOSE 8090
CMD ["/go/app/app"]
