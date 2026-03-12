#!/bin/sh
set -e

# Try loading any values, which aren't already set
if [ "$GATEWAY_THINEDGE_ENABLED" = true ]; then
    echo "ThinEdge mode enabled, trying to get device_id from c8y over proxy..."

        if [ -z "$C8Y_BASEURL" ]; then
            echo "No C8Y_BASEURL set, setting to localhost thinEdge Proxy only on native"
            export C8Y_BASEURL=http://127.0.0.1:8001/c8y
        fi

        if [ -z "$GATEWAY_THINEDGE_DEVICEID" ]; then
            echo "Fetching GATEWAY_THINEDGE_DEVICEID using device user for cumulocity to get device.id http://127.0.0.1:8001/c8y/user/currentUser" 
            GATEWAY_THINEDGE_DEVICEID="$(curl $C8Y_BASEURL/user/currentUser | jq -r '.id' | cut -d'_' -f2)"
            echo "Got GATEWAY_THINEDGE_DEVICEID=$GATEWAY_THINEDGE_DEVICEID" 
            export GATEWAY_THINEDGE_DEVICEID
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
echo "Settings"
echo "GATEWAY_IDENTIFIER: $GATEWAY_IDENTIFIER"
echo "GATEWAY_NAME: $GATEWAY_NAME"
echo "C8Y_BASEURL: $C8Y_BASEURL"
echo "Starting the opcua-device-gateway..."
# shellcheck disable=SC2086
exec /usr/bin/java $JAVA_OPTS -Dlogging.config=file:./logging.xml -Dspring.profiles.active=default -jar opcua-device-gateway.jar "$@"
