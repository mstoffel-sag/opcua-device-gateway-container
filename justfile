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
