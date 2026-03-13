#!/bin/sh
set -e

# Try loading any values, which aren't already set
if [ "$GATEWAY_THINEDGE_ENABLED" = true ]; then
    echo "ThinEdge mode enabled, trying to get device_id from c8y over proxy..."

        if [ -z "$C8Y_BASEURL" ]; then
            echo "ERROR: No C8Y_BASEURL set, please define it as an environment variable like export C8Y_BASEURL=http://tedge-container:8001/c8y"
            exit 1
        fi

        if [ -z "$GATEWAY_THINEDGE_DEVICEID" ]; then
            echo "Fetching GATEWAY_THINEDGE_DEVICEID using device user for cumulocity to get device.id $C8Y_BASEURL/user/currentUser" 
            GATEWAY_THINEDGE_DEVICEID="$(curl -sS $C8Y_BASEURL/user/currentUser | jq -r '.id' | cut -d'_' -f2)"
            
            if [ -z "$GATEWAY_THINEDGE_DEVICEID" ]; then
                echo "ERROR: Failed to fetch GATEWAY_THINEDGE_DEVICEID from $C8Y_BASEURL/user/currentUser"
                exit 1
            fi
            
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
echo "Settings:"
echo "GATEWAY_IDENTIFIER: $GATEWAY_IDENTIFIER"
echo "GATEWAY_NAME: $GATEWAY_NAME"
echo "C8Y_BASEURL: $C8Y_BASEURL"
echo "Starting the opcua-device-gateway..."
# shellcheck disable=SC2086
exec /usr/bin/java $JAVA_OPTS -Dlogging.config=file:./logging.xml -Dspring.profiles.active=default -jar opcua-device-gateway.jar "$@"
