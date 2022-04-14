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
COPY --from=devbuild /build/$BIN_NAME /bin/
CMD /bin/$BIN_NAME


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

LABEL maintainer="Team RelEng <team-rel-eng@hashicorp.com>"
LABEL version=$PRODUCT_VERSION
LABEL revision=$PRODUCT_REVISION

# Create a non-root user to run the software.
RUN addgroup $PRODUCT_NAME && \
    adduser -S -G $PRODUCT_NAME 100

COPY dist/$TARGETOS/$TARGETARCH/$BIN_NAME /bin/

USER 100
CMD /bin/$BIN_NAME


# alternate release image, just for the sake of example. In this case we're using
# debian as the base image just to make the image different from the default alpine one.
#
# The use cases for alternate images are things like defining an additional UBI compatible
# image, or an image with a different function than the main image, e.g. Waypoint's ODR images.
# -----------------------------------
FROM debian:latest AS release-alternate

ARG BIN_NAME
# Export BIN_NAME for the CMD below, it can't see ARGs directly.
ENV BIN_NAME=$BIN_NAME
ARG PRODUCT_VERSION
ARG PRODUCT_REVISION
ARG PRODUCT_NAME=$BIN_NAME
# TARGETARCH and TARGETOS are set automatically when --platform is provided.
ARG TARGETOS TARGETARCH

LABEL maintainer="Team RelEng <team-rel-eng@hashicorp.com>"
LABEL version=$PRODUCT_VERSION
LABEL revision=$PRODUCT_REVISION

# Create a non-root user to run the software.
RUN addgroup $PRODUCT_NAME && \
    adduser --system --uid 101 --group $PRODUCT_NAME

COPY dist/$TARGETOS/$TARGETARCH/$BIN_NAME /bin/

USER 101
CMD /bin/$BIN_NAME


# ===================================
# 
#   Set default target to 'dev'.
#
# ===================================
FROM dev
