# Start from golang v1.8 base image
FROM golang:1.8 as builder

WORKDIR /go/src/github.com/ONSdigital/eq-questionnaire-launcher

COPY . .

# Download dependencies
RUN go get -u github.com/golang/dep/cmd/dep
RUN $GOPATH/bin/dep ensure

# Build the Go app
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /go/bin/eq-questionnaire-launcher .

######## Start a new stage from scratch #######
FROM alpine:latest  

RUN apk --no-cache update && \
    apk --no-cache add python py-pip py-setuptools ca-certificates && \
    pip --no-cache-dir install awscli && \
    rm -rf /var/cache/apk/*

# Copy the Pre-built binary file and entry point from the previous stage
COPY --from=builder /go/bin/eq-questionnaire-launcher .
COPY docker-entrypoint.sh .
COPY static/ /static/
COPY templates/ /templates/
COPY jwt-test-keys /jwt-test-keys/

EXPOSE 8000

ENTRYPOINT ["sh", "/docker-entrypoint.sh"]
