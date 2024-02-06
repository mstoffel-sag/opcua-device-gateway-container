FROM alpine:3.18

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
LABEL org.opencontainers.image.base.name="alpine:3.18"

RUN apk update \
    && apk upgrade \
    && apk add --no-cache bash \
    && apk add --no-cache --virtual=build-dependencies unzip \
    && apk add --no-cache curl \
    && apk add --no-cache openjdk11

# Only install thin-edge.io to read the tedge config properties (see the entrypoint.sh)
# TODO: In the future this coupling may be removed
RUN wget -O - thin-edge.io/install.sh | sh -s

WORKDIR /app

# Download gateway from https://resources.cumulocity.com/examples/opc-ua/
RUN wget -O opcua-device-gateway.jar https://resources.cumulocity.com/examples/opc-ua/opcua-device-gateway-${VERSION}.jar

COPY application-tenant.yaml .
COPY logging.xml .
COPY entrypoint.sh .

# Default settings
ENV OPCUA_GATEWAY_IDENTIFIER=OPCUAGateway
ENV OPCUA_GATEWAY_NAME=OPCUAGateway
ENV MQTT_BROKER=mqtt-broker:1883

CMD ["/app/entrypoint.sh"]
