# syntax=docker/dockerfile:1.8

FROM --platform=$BUILDPLATFORM golang:1.26.5-alpine AS builder

ARG TARGETOS
ARG TARGETARCH
ARG GOOSE_BUILD_TAGS=""
ARG GOOSE_VERSION=""

ENV CGO_ENABLED=0 \
    GOOSE_BUILD_TAGS=${GOOSE_BUILD_TAGS}

WORKDIR /src

RUN apk add --no-cache git

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN GOOS=$TARGETOS GOARCH=$TARGETARCH /bin/sh -c '\
    set -e; \
    ldflags="-s -w"; \
    if [ -n "$GOOSE_VERSION" ]; then \
      ldflags="$ldflags -X main.version=$GOOSE_VERSION"; \
    fi; \
    if [ -n "$GOOSE_BUILD_TAGS" ]; then \
      go build -trimpath -tags "$GOOSE_BUILD_TAGS" -ldflags "$ldflags" -o /out/goose ./cmd/goose; \
    else \
      go build -trimpath -ldflags "$ldflags" -o /out/goose ./cmd/goose; \
    fi'

FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=builder /out/goose /usr/local/bin/goose

WORKDIR /migrations

ENTRYPOINT ["goose"]
CMD ["--help"]
