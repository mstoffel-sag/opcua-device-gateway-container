#!/bin/sh
set -e

# Try loading any values, which aren't already set, using tedge cli
if [ "$GATEWAY_THINEDGE_ENABLED" = true ]; then
    echo "ThinEdge mode enabled, trying to load values from tedge..." >&2
    if command -V tedge >/dev/null 2>&1; then
        if [ -z "$GATEWAY_THINEDGE_DEVICEID" ]; then
            echo "Fetching GATEWAY_THINEDGE_DEVICEID using tedge command tedge config get device.id" >&2
            GATEWAY_THINEDGE_DEVICEID="$(tedge config get device.id 2>/dev/null ||:)"
            echo "Using value from tedge: GATEWAY_THINEDGE_DEVICEID=$GATEWAY_THINEDGE_DEVICEID" >&2
            export GATEWAY_THINEDGE_DEVICEID
        fi

        if [ -z "$C8Y_BASEURL" ] || [ "$C8Y_BASEURL" = "https://" ] || [ "$C8Y_BASEURL" = "http://" ]; then
            echo "Fetching C8Y_BASEURL using tedge command tedge config get c8y.url" >&2
            C8Y_BASEURL="https://$(tedge config get c8y.url 2>/dev/null ||:)"
            echo "Using value from tedge: C8Y_BASEURL=$C8Y_BASEURL" >&2
            export C8Y_BASEURL
        fi

        # Add a prefix to the OPCUA identifier to ensure its external identity is unique
        # to allow deploying multiple versions in the fleet without having to define unique names all the time
        case "$GATEWAY_IDENTIFIER" in
            *"$GATEWAY_THINEDGE_DEVICEID"*)
                echo "Gateway identifier already includes the device_id" >&2
                ;;
            *)
                echo "Prefixing GATEWAY_IDENTIFIER with the GATEWAY_THINEDGE_DEVICEID to avoid identity clashes" >&2
                export GATEWAY_IDENTIFIER="${GATEWAY_THINEDGE_DEVICEID}:${GATEWAY_IDENTIFIER}"
                ;;
        esac
    fi
fi

cd /app
echo "Settings"
echo "GATEWAY_IDENTIFIER: $GATEWAY_IDENTIFIER" >&2
echo "GATEWAY_NAME: $GATEWAY_NAME" >&2
echo "C8Y_BASEURL: $C8Y_BASEURL" >&2
echo "Starting the opcua-device-gateway..." >&2
# shellcheck disable=SC2086
exec /usr/bin/java $JAVA_OPTS -Dlogging.config=file:./logging.xml -Dspring.profiles.active=default -jar opcua-device-gateway.jar "$@"
