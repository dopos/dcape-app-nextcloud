## dcape-app-nextcloud Makefile
## This file extends Makefile.app from dcape
#:

SHELL            = /bin/bash
CFG             ?= .env
CFG_BAK         ?= $(CFG).bak

#- Docker repo & image name without version
IMAGE           ?= nginx
#- docker image version from dcape
IMAGE_VER       ?= 1.19.4-alpine

# ------------------------------------------------------------------------------
# app custom config

# Owerwrite for setup
APP_SITE        ?= host.dev.test

#- Nextcloud image
CLOUD_IMAGE     ?= nextcloud

#- Nextcloud image version
CLOUD_IMAGE_VER ?= 27.1.4-fpm-alpine

#- Redis image
REDIS_IMAGE     ?= redis

#- Redis image version
REDIS_IMAGE_VER ?= 7.2.3

#- Redis password
REDIS_PASS      ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c8; echo)

#- app root
APP_ROOT        ?= $(PWD)

PERSIST_FILES    = nginx.conf

USE_DB           = yes
ADD_USER         = yes
USE_TLS          = true

# ------------------------------------------------------------------------------

# if exists - load old values
-include $(CFG_BAK)
export

-include $(CFG)
export

# ------------------------------------------------------------------------------
# Find and include DCAPE_ROOT/Makefile
DCAPE_COMPOSE   ?= dcape-compose
DCAPE_ROOT      ?= $(shell docker inspect -f "{{.Config.Labels.dcape_root}}" $(DCAPE_COMPOSE))

ifeq ($(shell test -e $(DCAPE_ROOT)/Makefile.app && echo -n yes),yes)
  include $(DCAPE_ROOT)/Makefile.app
else
  include /opt/dcape/Makefile.app
endif

CLOUD_CONTAINER ?= dcape-app-nextcloud-cloud-1

occ-idx:
	docker exec -u 82 $(CLOUD_CONTAINER) ./occ db:add-missing-indices

occ-upgrade:
	docker exec -u 82 $(CLOUD_CONTAINER) ./occ upgrade
