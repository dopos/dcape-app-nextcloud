# dcape-app-nextcloud Makefile
SHELL               = /bin/sh
CFG                ?= .env
CFG_BAK            ?= $(CFG).bak

#- App name
APP_NAME           ?= service-nextcloud

# Redefine dcape params without config duplicate
USE_DB             ?= yes
ADD_USER           ?= yes
USE_TLS            = yes
USER_NAME          ?= nc
USER_PASS          ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c8; echo)
USER_EMAIL         ?= ${USER_NAME}@${DCAPE_DOMAIN}

#- Docker image name
IMAGE              ?= nextcloud

#- docker image version from dcape
IMAGE_VER          ?= 30-fpm-alpine

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
OO_IMAGE_VER       ?= 8.2

#- OnlyOffice database
OO_PGDATABASE      ?= onlyoffice

#- OnlyOffice database user
OO_PGUSER          ?= onlyoffice

#- OnlyOffice database password
OO_PGPASSWORD      ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c18; echo)

#- OnlyOffice web endpoint
OO_APP_SITE        ?= oo-$(APP_SITE)

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
## Prepare before 'make up'
setup:
	@mkdir -p ${APP_ROOT}/html ${APP_ROOT}/config ${APP_ROOT}/data ; \
	chown -R 82:82 ${APP_ROOT}/html ${APP_ROOT}/config ${APP_ROOT}/data ; \
	$(MAKE) -s db-create db-create-oo

## Execute OCC command inside nextcloud container (php occ $OCC_CMD)
exec-occ:
	$(MAKE) -s dc CMD='exec -ti -u www-data nextcloud php /var/www/html/occ ${OCC_CMD}'

## Execute cron command inside nextcloud container (php cron.php)
exec-cron:
	$(MAKE) -s dc CMD='exec -ti -u www-data anextcloudpp php cron.php'

## Create OnlyOffice database
db-create-oo: 
	@$(MAKE) -s db-create PGUSER='${OO_PGUSER}' PGDATABASE='${OO_PGDATABASE}' PGPASSWORD='${OO_PGPASSWORD}'

## Drop OnlyOffice database
db-drop-oo:
	@$(MAKE) -s db-drop PGUSER='${OO_PGUSER}' PGDATABASE='${OO_PGDATABASE}'
