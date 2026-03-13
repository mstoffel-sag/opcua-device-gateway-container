#!/bin/sh
set -e

# Try loading any values, which aren't already set
if [ "$GATEWAY_THINEDGE_ENABLED" = true ]; then
    echo "ThinEdge mode enabled"

    if [ "$GATEWAY_THINEDGE_USEHTTPPROXY" = true ]; then
        # Proxy mode: C8Y_BASEURL must be set via env var, fetch device ID via curl
        echo "HTTP Proxy mode enabled"
        
        if [ -z "$C8Y_BASEURL" ]; then
            echo "ERROR: No C8Y_BASEURL set. In proxy mode, please define it as an environment variable (e.g., C8Y_BASEURL=http://tedge-container:8001/c8y)"
            exit 1
        fi

        if [ -z "$GATEWAY_THINEDGE_DEVICEID" ]; then
            echo "Fetching GATEWAY_THINEDGE_DEVICEID from $C8Y_BASEURL/user/currentUser" 
            GATEWAY_THINEDGE_DEVICEID="$(curl -sS $C8Y_BASEURL/user/currentUser | jq -r '.id' | cut -d'_' -f2)"
            
            if [ -z "$GATEWAY_THINEDGE_DEVICEID" ]; then
                echo "ERROR: Failed to fetch GATEWAY_THINEDGE_DEVICEID from $C8Y_BASEURL/user/currentUser"
                exit 1
            fi
            
            echo "Got GATEWAY_THINEDGE_DEVICEID=$GATEWAY_THINEDGE_DEVICEID" 
            export GATEWAY_THINEDGE_DEVICEID
        fi
    else
        # Non-proxy mode: fetch both C8Y_BASEURL and device ID from tedge commands
        echo "Direct mode (no HTTP proxy), fetching values from tedge config"
        
        if [ -z "$GATEWAY_THINEDGE_DEVICEID" ]; then
            echo "Fetching GATEWAY_THINEDGE_DEVICEID using: tedge config get device.id"
            GATEWAY_THINEDGE_DEVICEID="$(tedge config get device.id 2>/dev/null ||:)"
            
            if [ -z "$GATEWAY_THINEDGE_DEVICEID" ]; then
                echo "ERROR: Failed to fetch device.id from tedge config"
                exit 1
            fi
            
            echo "Got GATEWAY_THINEDGE_DEVICEID=$GATEWAY_THINEDGE_DEVICEID"
            export GATEWAY_THINEDGE_DEVICEID
        fi

        if [ -z "$C8Y_BASEURL" ] || [ "$C8Y_BASEURL" = "https://" ] || [ "$C8Y_BASEURL" = "http://" ]; then
            echo "Fetching C8Y_BASEURL using: tedge config get c8y.url"
            C8Y_URL="$(tedge config get c8y.url 2>&1 ||:)"
            
            # Check if the command returned an error message or empty value
            if [ -z "$C8Y_URL" ] || echo "$C8Y_URL" | grep -q "not set"; then
                echo "ERROR: c8y.url is not configured in tedge config"
                exit 1
            fi
            
            C8Y_BASEURL="https://${C8Y_URL}"
            
            echo "Got C8Y_BASEURL=$C8Y_BASEURL"
            export C8Y_BASEURL
        fi
    fi

    # Add a prefix to the OPCUA identifier to ensure its external identity is unique
    # to allow deploying multiple versions in the fleet without having to define unique names all the time
    case "$GATEWAY_IDENTIFIER" in
        *"$GATEWAY_THINEDGE_DEVICEID"*)
            echo "Gateway identifier already includes the device_id"
            ;;
        *)
            echo "Prefixing GATEWAY_IDENTIFIER with the GATEWAY_THINEDGE_DEVICEID to avoid identity clashes"
            export GATEWAY_IDENTIFIER="${GATEWAY_THINEDGE_DEVICEID}:${GATEWAY_IDENTIFIER}"
            ;;
    esac
fi

cd /app
echo "Settings:"
echo "GATEWAY_IDENTIFIER: $GATEWAY_IDENTIFIER"
echo "GATEWAY_NAME: $GATEWAY_NAME"
echo "C8Y_BASEURL: $C8Y_BASEURL"
echo "Starting the opcua-device-gateway..."
# shellcheck disable=SC2086
exec /usr/bin/java $JAVA_OPTS -Dlogging.config=file:./logging.xml -Dspring.profiles.active=default -jar opcua-device-gateway.jar "$@"
