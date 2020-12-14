# dcape-app-nextcloud Makefile
SHELL               = /bin/sh
CFG                ?= .env
# docker image version from dcape
IMAGE_VER          ?= 20.0.3-apache
REDIS_IMAGE_VER    ?= 6.0.9-alpine
NGINX_IMAGE_VER    ?= 1.19.4-alpine
# Config vars are described below in section `define CONFIG_...`
APP_SITE           ?= cloud.dev.lan
USE_TLS            ?= false
USER_NAME          ?= nc
USER_PASS          ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c8; echo)
PGDATABASE         ?= nextcloud
PGUSER             ?= $(PGDATABASE)
PGPASSWORD         ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo)
PG_DUMP_SOURCE     ?=
IMAGE              ?= nextcloud
REDIS_IMAGE        ?= redis
NGINX_IMAGE        ?= nginx
PROJECT_NAME       ?= $(shell basename $$PWD)
DCAPE_TAG          ?= dcape
DCAPE_NET          ?= $(DCAPE_TAG)
PG_CONTAINER       ?= $(DCAPE_TAG)_db_1
APP_ROOT           ?= $(PWD)
DC_VER             ?= latest

define CONFIG_DEF
# ------------------------------------------------------------------------------
# Nextcloud: general config

# Site host
APP_SITE=$(APP_SITE)

# Use TLS (true|false)
USE_TLS=$(USE_TLS)

# Admin user name
USER_NAME=$(USER_NAME)
# Admin user password
USER_PASS=$(USER_PASS)

# ------------------------------------------------------------------------------
# Nextcloud: internal config

# Host dir for app data
APP_ROOT=$(APP_ROOT)

# Database name
PGDATABASE=$(PGDATABASE)
# Database user name
PGUSER=$(PGUSER)
# Database user password
PGPASSWORD=$(PGPASSWORD)
# Database dump for import on create
PG_DUMP_SOURCE=$(PG_DUMP_SOURCE)

# Docker details

# Used by docker-compose
# Docker-compose project name (container name prefix)
PROJECT_NAME=$(PROJECT_NAME)

# dcape container name prefix
DCAPE_TAG=$(DCAPE_TAG)

# dcape network attach to
DCAPE_NET=$(DCAPE_NET)

# dcape postgresql container name
PG_CONTAINER=$(PG_CONTAINER)

# Nextcloud image name
IMAGE=$(IMAGE)
# Redis image name
REDIS_IMAGE=$(REDIS_IMAGE)
# Nginx image name
NGINX_IMAGE=$(NGINX_IMAGE)

# Nextcloud image tag
IMAGE_VER=$(IMAGE_VER)
# Redis image tag
REDIS_IMAGE_VER=$(REDIS_IMAGE_VER)
# Nginx image tag
NGINX_IMAGE_VER=$(NGINX_IMAGE_VER)

endef
export CONFIG_DEF

-include $(CFG)
export

-include $(CFG).bak
export

.PHONY: all $(CFG) start start-hook stop update up reup down docker-wait db-create db-drop psql dc help

all: help

# ------------------------------------------------------------------------------
# webhook commands

start: db-create up

start-hook: db-create reup

stop: down

update: reup

# ------------------------------------------------------------------------------
# docker commands

## старт контейнеров
up:
up: CMD=up -d
up: dc

## рестарт контейнеров
reup:
reup: CMD=up --force-recreate -d
reup: dc

## остановка и удаление всех контейнеров
down:
down: CMD=rm -f -s
down: dc


# Wait for postgresql container start
docker-wait:
	@echo -n "Checking PG is ready..."
	@until [ `docker inspect -f "{{.State.Health.Status}}" $$PG_CONTAINER` = "healthy" ] ; do sleep 1 ; echo -n "." ; done
	@echo "Ok"

# ------------------------------------------------------------------------------
# DB operations

# Database import script
# DCAPE_DB_DUMP_DEST must be set in pg container

define IMPORT_SCRIPT
[ "$$DCAPE_DB_DUMP_DEST" ] || { echo "DCAPE_DB_DUMP_DEST not set. Exiting" ; exit 1 ; } ; \
DB_NAME="$$1" ; DB_USER="$$2" ; DB_PASS="$$3" ; DB_SOURCE="$$4" ; \
dbsrc=$$DCAPE_DB_DUMP_DEST/$$DB_SOURCE.tgz ; \
if [ -f $$dbsrc ] ; then \
  echo "Dump file $$dbsrc found, restoring database..." ; \
  zcat $$dbsrc | PGPASSWORD=$$DB_PASS pg_restore -h localhost -U $$DB_USER -O -Ft -d $$DB_NAME || exit 1 ; \
else \
  echo "Dump file $$dbsrc not found" ; \
  exit 2 ; \
fi
endef
export IMPORT_SCRIPT

# create user, db and load sql
db-create: docker-wait
	@echo "*** $@ ***" ; \
	sql="CREATE USER \"$$PGUSER\" WITH PASSWORD '$$PGPASSWORD'" ; \
	docker exec -i $$PG_CONTAINER psql -U postgres -c "$$sql" 2>&1 > .psql.log | grep -v "already exists" > /dev/null || true ; \
	cat .psql.log ; \
	docker exec -i $$PG_CONTAINER psql -U postgres -c "CREATE DATABASE \"$$PGDATABASE\" OWNER \"$$PGUSER\";" 2>&1 > .psql.log | grep  "already exists" > /dev/null || db_exists=1 ; \
	cat .psql.log ; rm .psql.log ; \
	if [ "$$db_exists" = "1" ] ; then \
	  echo "*** db data load" ; \
	  if [ "$$PG_DUMP_SOURCE" ] ; then \
	    echo "$$IMPORT_SCRIPT" | docker exec -i $$PG_CONTAINER bash -s - $$PGDATABASE $$PGUSER $$PGPASSWORD $$PG_DUMP_SOURCE \
	    && docker exec -i $$PG_CONTAINER psql -U postgres -c "COMMENT ON DATABASE \"$$PGDATABASE\" IS 'SOURCE $$PG_DUMP_SOURCE';" \
	    || true ; \
	  fi \
	fi

## drop database and user
db-drop: docker-wait
	@echo "*** $@ ***"
	@docker exec -it $$PG_CONTAINER psql -U postgres -c "DROP DATABASE \"$$PGDATABASE\";" || true
	@docker exec -it $$PG_CONTAINER psql -U postgres -c "DROP USER \"$$PGUSER\";" || true

psql: docker-wait
	@docker exec -it $$PG_CONTAINER psql -U $$PGUSER $$PGDATABASE

# ------------------------------------------------------------------------------

# $$PWD используется для того, чтобы текущий каталог был доступен в контейнере по тому же пути
# и относительные тома новых контейнеров могли его использовать
## run docker-compose
dc: docker-compose.yml
	@docker run --rm  \
	  -v /var/run/docker.sock:/var/run/docker.sock \
	  -v $$PWD:$$PWD \
	  -w $$PWD \
	  docker/compose:$(DC_VER) \
	  -p $$PROJECT_NAME \
	  $(CMD)

# ------------------------------------------------------------------------------

$(CFG).sample:
	@echo "$$CONFIG_DEF" > $@

config: $(CFG).sample
# ------------------------------------------------------------------------------

## List Makefile targets
help:
	@grep -A 1 "^##" Makefile | less

##
## Press 'q' for exit
##
