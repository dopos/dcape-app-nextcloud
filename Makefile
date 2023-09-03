# dcape-app-nextcloud Makefile
SHELL               = /bin/sh
CFG                ?= .env
CFG_BAK            ?= $(CFG).bak

#- App name
APP_NAME           ?= service-nextcloud

# Redefine dcape params without config duplicate
USE_DB              ?= yes
ADD_USER            ?= yes
USE_TLS             = yes
USER_NAME          ?= nc
USER_PASS          ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c8; echo)

#- Docker image name
IMAGE              ?= nextcloud

#- Docker image tag
IMAGE_VER          ?= 27-fpm-alpine

#- docker image version from dcape
IMAGE_VER          ?= 27-fpm-alpine

#- Redis container image version
REDIS_IMAGE_VER    ?= 7.2-alpine

#- Nginx container image version
NGINX_IMAGE_VER    ?= 1.25.2-alpine

#APP_SITE           ?= cloud.dev.lan
USE_TLS            ?= false

#- Redis container image
REDIS_IMAGE        ?= redis

#- Nginx container image
NGINX_IMAGE        ?= nginx

#- Project name for DC
PROJECT_NAME       ?= $(shell basename $$PWD)

#- Application root dir (only for local deploy)
APP_ROOT           ?= $(PWD)

#- Redis SU password
REDIS_PASS         ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c8; echo)

#- OnlyOffice image
OO_IMAGE           ?= onlyoffice/documentserver

#- OnlyOffice image version
OO_IMAGE_VER       ?= 7.3

#- OnlyOffice database
OO_PGDATABASE      ?= onlyoffice

#- OnlyOffice database user
OO_PGUSER          ?= onlyoffice

#- OnlyOffice database password
OO_PGPASSWORD      ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c18; echo)

#- OnlyOffice web endpoint
OO_APP_SITE        ?= oo.$(APP_SITE)

#- OnlyOffice JWT secret
OO_JWT_SECRET      ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c18; echo)
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

# ------------------------------------------------------------------------------

## Set Nextcloud config params template.
set-nextcloud: CMD=exec -ti -u www-data app ./occ config:system:set default_phone_region --value=\"RU\"
set-nextcloud: dc
