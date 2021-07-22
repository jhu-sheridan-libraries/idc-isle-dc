#!/bin/bash

#
# Shell functions and environment common to all tests go here
#

# The name of the currently running Drupal Docker container
DRUPAL_CONTAINER_NAME=$(docker ps | awk '{print $NF}'|grep drupal)

# The Docker registry used to obtain the migration assets image
assets_repo=${MIGRATION_ASSETS_REPO:-ghcr.io/jhu-sheridan-libraries/idc-isle-dc}
# The name of the Docker image for migration assets
assets_image=${MIGRATION_ASSETS_IMAGE:-migration-assets}
# The migration assets image tag
assets_image_tag=${MIGRATION_ASSETS_IMAGE_TAG}
# The *external* port the migration assets HTTP server listens on
ext_assets_port=${MIGRATION_ASSETS_PORT:-8081}
# The name used by the migration assets container
assets_container=${MIGRATION_ASSETS_CONTAINER:-migration-assets}

# Starts the assets container used for migrations
function startMigrationAssetsContainer {
  docker run --name ${assets_container} --network gateway --rm -d ${assets_repo}/${assets_image}:${assets_image_tag}
  trap "docker stop ${assets_container}" EXIT
}

# Re-starts the Docker environment with the given environment variables appended to the existing .env
# Argument is a string that will be concatenatd with the .env file (i.e. like "FOO=BAR").
function use_env {
	if [ -f "docker-compose.yml" ]; then cp docker-compose.yml .docker-compose.yml; fi
	echo -e "\nUsing additional environment variables and re-loading containers\n\n$1\n\n"
	ENV_FILE="/tmp/$(date +%s).env"
	cat .env > "${ENV_FILE}"
	echo "$1" >> "${ENV_FILE}"

	if [ "$TEST_ENVIRONMENT" == "static" ]; then
		echo "Using static environment"
		make -B static-docker-compose.yml env="${ENV_FILE}";
	else 
		make -B docker-compose.yml args="--env-file ${ENV_FILE}"
	fi
	make up
	mv .docker-compose.yml docker-compose.yml || make docker-compose.yml
}
