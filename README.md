# dcape-app-nextcloud

[![GitHub Release][1]][2] [![GitHub code size in bytes][3]]() [![GitHub license][4]][5]

[1]: https://img.shields.io/github/release/dopos/dcape-app-nextcloud.svg
[2]: https://github.com/dopos/dcape-app-nextcloud/releases
[3]: https://img.shields.io/github/languages/code-size/dopos/dcape-app-nextcloud.svg
[4]: https://img.shields.io/github/license/dopos/dcape-app-nextcloud.svg
[5]: LICENSE

[nextcloud](https://www.nextcloud.com/) application package for [dcape](https://github.com/dopos/dcape) v2.

## Docker image used

* [nextcloud](https://hub.docker.com/_/nextcloud)
* [redis](https://hub.docker.com/_/redis)
* [nginx](https://hub.docker.com/_/nginx)

## Requirements

* linux 64bit (git, make, wget, gawk, openssl)
* [docker](http://docker.io)
* [dcape](https://github.com/dopos/dcape)
* Git service ([github](https://github.com), [gitea](https://gitea.io) or [gogs](https://gogs.io))

## Install

### By mouse (deploy with drone)

* Gitea: Fork or mirror this repo in your Git service
* Drone: Activate repo
* Gitea: Run "Test delivery", config sample will be saved to enfist
* Enfist: Edit config and remove .sample from name
* Run "Test delivery" again (app will be installed and started on webhook host)

### By hands

```bash
git clone -b v2 --single-branch --depth 1 https://github.com/dopos/dcape-app-nextcloud.git
cd dcape-app-nextcloud
make config
... <edit .env.sample>
mv .env.sample .env
make up
```

### Redis
```
sysctl vm.overcommit_memory=1
```

### __Host cookie:

config/config.php:
```
'overwriteprotocol' => 'https',
```

## Upgrade dcape app

```bash
git pull
make config
... <check .env.sample>
mv .env.sample .env
make up
```

## Upgrade nextcloud

#### v17 -> v18

* IMAGE_VER=18.0.11-apache
* В каталоге data развернуть из старой версии config,data
* поднять БД из дампа
* chown -R 32:101 data
* `make up` - остальное в data появится
* `make dc CMD="run --rm -u www-data cloud-app php occ upgrade"`
* Ошибка "Column name "oc_flow_operations"."entity" is NotNull, but has empty string or null as default.".
 Решение: `ALTER TABLE oc_flow_operations ADD COLUMN entity VARCHAR NOT NULL;` и повторить обновление

#### v18 -> v19

* IMAGE_VER=19.0.5-fpm-alpine
* chown -R 82:101 data
* `make up`

#### v19 -> v20

* IMAGE_VER=20.0.3-fpm-alpine
* `make up`
* chown -R 82:101 data
* `make dc CMD="run --rm -u www-data cloud-app php occ maintenance:mode --off"`
* открываем /settings/admin/overview - там напишут, какие команды еще запустить
* в одном месте все может отвалиться из-за подтверждения. Решение: `make dc CMD="run --rm  -u www-data cloud-app php occ db:convert-filecache-bigint --no-interaction"`

## License

The MIT License (MIT), see [LICENSE](LICENSE).

Copyright (c) 2019-2020 Aleksei Kovrizhkin <lekovr+dopos@gmail.com>
