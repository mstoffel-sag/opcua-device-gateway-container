set dotenv-load

export VERSION := env_var_or_default("VERSION", `date +'%Y%m%d.%H%M'`)

# Generate a version name (that can be used in follow up commands)
generate_version:
    @echo "{{VERSION}}"

# Trigger a release (by creating a tag)
release:
    git tag -a "{{VERSION}}" -m "{{VERSION}}"
    git push origin "{{VERSION}}"
    @echo
    @echo "Created release (tag): {{VERSION}}"
    @echo

# Build the docker image
build opcua_version *args:
    docker build -t opcua-device-gateway-image:{{VERSION}} --build-arg VERSION={{opcua_version}} -f containers/opcua-device-gateway/Dockerfile containers/opcua-device-gateway {{args}}
