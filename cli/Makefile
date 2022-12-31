BINARY_NAME=kapctl

build:
	GOARCH=amd64 GOOS=linux go build -o ${BINARY_NAME} main.go

create:
	./${BINARY_NAME} create project --project-name test --project-description desc --project-user test-dev --project-user-email "test-dev@test.dev" --project-user-initial-password "testtest"

delete:
	./${BINARY_NAME} delete project --project-name test

clean:
	go clean
	rm ${BINARY_NAME}

.PHONY: build create delete clean