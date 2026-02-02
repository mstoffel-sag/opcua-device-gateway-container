FROM debian:12-slim

ARG BUILDTIME
ARG REVISION
ARG VERSION=1023.1.0

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
LABEL org.opencontainers.image.base.name="debian:12-slim"
LABEL com.cumulocity.image.opcua.version="$VERSION"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gpg \
        ca-certificates \
        openjdk-17-jre \
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
RUN DOWNLOAD_URL="https://resources.cumulocity.com/examples/opc-ua/${VERSION}/opcua-device-gateway.jar" \
    && wget -O opcua-device-gateway.jar "$DOWNLOAD_URL"

COPY logging.xml .
COPY entrypoint.sh .

# Default settings
ENV OPCUA_GATEWAY_IDENTIFIER=OPCUAGateway
ENV OPCUA_GATEWAY_NAME=OPCUAGateway
ENV JAVA_OPTS=

# check compatibility of the jar with the installed java version
# If the jar is not compatible then java will return quickly with an exit code of 1
# otherwise if everything is ok, the timeout will kill the app, and it exits with exit code 124
RUN sh -c 'timeout 4 java -jar opcua-device-gateway.jar; [ $? = 124 ]'

CMD ["/app/entrypoint.sh"]
