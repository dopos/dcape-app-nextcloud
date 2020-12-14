# dcape-app-nextcloud
nextcloud.com application package for dcape

# dcape-app-nextcloud

[![GitHub Release][1]][2] [![GitHub code size in bytes][3]]() [![GitHub license][4]][5]

[1]: https://img.shields.io/github/release/dopos/dcape-app-nextcloud.svg
[2]: https://github.com/dopos/dcape-app-nextcloud/releases
[3]: https://img.shields.io/github/languages/code-size/dopos/dcape-app-nextcloud.svg
[4]: https://img.shields.io/github/license/dopos/dcape-app-nextcloud.svg
[5]: LICENSE

[nextcloud](https://www.nextcloud.com/) application package for [dcape](https://github.com/dopos/dcape).

## Docker image used

* [nextcloud](https://hub.docker.com/_/nextcloud)
* [redis](https://hub.docker.com/_/redis)

## Requirements

* linux 64bit (git, make, wget, gawk, openssl)
* [docker](http://docker.io)
* [dcape](https://github.com/dopos/dcape)
* Git service ([github](https://github.com), [gitea](https://gitea.io) or [gogs](https://gogs.io))

## Usage

### Redis
```
sysctl vm.overcommit_memory=1
```

### __Host cookie:

config/config.php:
```
'overwriteprotocol' => 'https',
```

* Fork this repo in your Git service
* Setup deploy hook
* Run "Test delivery" (config sample will be created in dcape)
* Edit and save config (enable deploy etc)
* Run "Test delivery" again (app will be installed and started on webhook host)
* Fork [dopos/dcape-dns-config](https://github/com/dopos/dcape-dns-config) and cook your zones

See also: [Deploy setup](https://github.com/dopos/dcape/blob/master/DEPLOY.md) (in Russian)

## License

The MIT License (MIT), see [LICENSE](LICENSE).

Copyright (c) 2019 Aleksei Kovrizhkin <lekovr+dopos@gmail.com>
