# This Dockerfile contains multiple targets.
# Use 'docker build --target=<name> .' to build one.
#
# Every target has a BIN_NAME argument that must be provided via --build-arg=BIN_NAME=<name>
# when building.


# ===================================
# 
#   Non-release images.
#
# ===================================


# devbuild compiles the binary
# -----------------------------------
FROM golang:latest AS devbuild
ARG BIN_NAME
# Escape the GOPATH
WORKDIR /build
COPY . ./
RUN go build -o $BIN_NAME


# dev runs the binary from devbuild
# -----------------------------------
FROM alpine:latest AS dev
ARG BIN_NAME
# Export BIN_NAME for the CMD below, it can't see ARGs directly.
ENV BIN_NAME=$BIN_NAME
RUN apk add --no-cache \
        git \
        libc6-compat 
COPY --from=devbuild /build/nomad-pack /bin/
ENTRYPOINT ["/bin/nomad-pack"] CMD ["help"]


# ===================================
# 
#   Release images.
#
# ===================================


# default release image
# -----------------------------------
FROM alpine:latest AS release-default
RUN apk add --no-cache \
        git \
        libc6-compat 
ARG BIN_NAME
# Export BIN_NAME for the CMD below, it can't see ARGs directly.
ENV BIN_NAME=$BIN_NAME
ARG PRODUCT_VERSION
ARG PRODUCT_REVISION
ARG PRODUCT_NAME=$BIN_NAME
# TARGETARCH and TARGETOS are set automatically when --platform is provided.
ARG TARGETOS TARGETARCH

LABEL maintainer="Nomad Ecosystem Team <nomad-eco@hashicorp.com>"
LABEL version=$PRODUCT_VERSION
LABEL revision=$PRODUCT_REVISION

# Create a non-root user to run the software.
RUN addgroup $PRODUCT_NAME && \
    adduser -S -G $PRODUCT_NAME 100

COPY dist/$TARGETOS/$TARGETARCH/nomad-pack /bin/

USER 100
ENTRYPOINT ["/bin/nomad-pack"] CMD ["help"]


# ===================================
# 
#   Set default target to 'dev'.
#
# ===================================
FROM dev
