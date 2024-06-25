FROM debian:11-slim

ARG BUILDTIME
ARG REVISION
ARG VERSION=1018.0.308

LABEL org.opencontainers.image.title="thin-edge.io"
LABEL org.opencontainers.image.created=$BUILDTIME
LABEL org.opencontainers.image.version=$VERSION
LABEL org.opencontainers.image.revision=$REVISION
LABEL org.opencontainers.image.description="OPCUA Device Gateway to support connecting thin-edge.io to OPCUA Servers"
LABEL org.opencontainers.image.source="https://github.com/thin-edge/opcua-device-gateway-container"
LABEL org.opencontainers.image.authors="thin-edge.io"
LABEL org.opencontainers.image.vendor="thin-edge.io"
LABEL org.opencontainers.image.licenses="Apache 2.0"
LABEL org.opencontainers.image.url="https://thin-edge.io"
LABEL org.opencontainers.image.documentation="https://thin-edge.github.io/thin-edge.io/"
LABEL org.opencontainers.image.base.name="debian:11-slim"
LABEL com.cumulocity.image.opcua.version="$VERSION"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        openjdk-11-jre \
        wget \
        bash \
        unzip \
        curl

# Only install thin-edge.io to read the tedge config properties (see the entrypoint.sh)
# TODO: In the future this coupling may be removed
RUN wget -O - thin-edge.io/install.sh | sh -s

WORKDIR /app

# Download gateway from https://resources.cumulocity.com/examples/opc-ua/
# From opcua version 1020.x.y, the download link changed, so handle both new and old download urls
RUN case "${VERSION}" in \
        10[0-1][0-9]*)  DOWNLOAD_URL="https://resources.cumulocity.com/examples/opc-ua/opcua-device-gateway-${VERSION}.jar"  ;; \
        *)  DOWNLOAD_URL="https://resources.cumulocity.com/examples/opc-ua/${VERSION}/opcua-device-gateway.jar"  ;; \
    esac \
    && wget -O opcua-device-gateway.jar "$DOWNLOAD_URL"

COPY application-tenant.yaml .
COPY logging.xml .
COPY entrypoint.sh .

# Default settings
ENV OPCUA_GATEWAY_IDENTIFIER=OPCUAGateway
ENV OPCUA_GATEWAY_NAME=OPCUAGateway
ENV MQTT_BROKER=mqtt-broker:1883

CMD ["/app/entrypoint.sh"]
