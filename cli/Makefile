BINARY_NAME=kapctl

build:
	GOARCH=amd64 GOOS=linux go build -o ${BINARY_NAME} main.go

run:
	./${BINARY_NAME} create project --project-name test --project-description desc

clean:
	go clean
	rm ${BINARY_NAME}