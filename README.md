# nfrastack/container-bulwark

## About

This repository will build a container for [Bulwark Webmail](https://bulwarkmail.org), a JMAP webmail client

* `full` - Node.js server with admin dashboard and settings sync
* `lite` - Static client served by nginx on `80`
* `relay` - Push relay (FCM / Web Push / UnifiedPush)

## Maintainer

- [Nfrastack](https://www.nfrastack.com)

## Table of Contents

- [About](#about)
- [Maintainer](#maintainer)
- [Table of Contents](#table-of-contents)
- [Installation](#installation)
  - [Prebuilt Images](#prebuilt-images)
  - [Quick Start](#quick-start)
  - [Persistent Storage](#persistent-storage)
- [Environment Variables](#environment-variables)
  - [Base Images used](#base-images-used)
  - [Core Configuration](#core-configuration)
  - [Bulwark Full Mode Options](#bulwark-full-mode-options)
  - [Bulwark Lite Mode Options](#bulwark-lite-mode-options)
  - [Relay Options](#relay-options)
- [Users and Groups](#users-and-groups)
  - [Networking](#networking)
- [Maintenance](#maintenance)
  - [Shell Access](#shell-access)
- [Support & Maintenance](#support--maintenance)
- [References](#references)
- [License](#license)

## Installation

### Prebuilt Images

Feature limited builds of the image are available on the [Github Container Registry](https://github.com/nfrastack/container-bulwark/pkgs/container/container-bulwark) and [Docker Hub](https://hub.docker.com/r/nfrastack/bulwark).

To get access to the image use your container orchestrator to pull from the following locations:

```
ghcr.io/nfrastack/container-bulwark:(image_tag)
docker.io/nfrastack/bulwark:(image_tag)
```

Image tag syntax is:

`<image>:<optional tag>-<optional_distribution>_<optional_distribution_variant>`

Example:

`ghcr.io/nfrastack/container-bulwark:latest` or

`ghcr.io/nfrastack/container-bulwark:1.12.0`

* `latest` will be the most recent commit
* An optional `tag` may exist that matches the [CHANGELOG](CHANGELOG.md) - These are the safest
* If it is built for multiple distributions there may exist a value of `alpine` or `debian`
* If there are multiple distribution variations it may include a version - see the registry for availability

Have a look at the container registries and see what tags are available.

#### Multi-Architecture Support

Images are built for `amd64` by default, with optional support for `arm64` and other architectures.

### Quick Start

* The quickest way to get started is using [docker-compose](https://docs.docker.com/compose/). See the examples folder for a working [compose.yml](examples/compose.yml) that can be modified for your use.
* Map [persistent storage](#persistent-storage) for access to configuration and data files for backup.
* Set various [environment variables](#environment-variables) to understand the capabilities of this image.
* Depending on your MODE Set `JMAP_SERVER_URL` to your mail server. On first launch in `full` mode complete the setup wizard in app.

### Persistent Storage

The following directories are used for configuration and can be mapped for persistent storage.

| Directory             | Description                    |
| --------------------- | ------------------------------ |
| `/config`             | Admin config, plugins, themes) |
| `/data/settings`      | Encrypted user settings        |
| `/data/admin-state`   | Admin runtime state            |
| `/data/telemetry`     | Telemetry state                |
| `/data/version-check` | Update check state             |
| `/data/relay`         | Relay state, FCM key           |
| `/logs`               | Logfiles                       |

>> `Lite` `MODE` needs no `/data` volumes. Config is generated from env on first start. Mount your own file at `/config/config.json` to have it linked automatically.

## Environment Variables

### Base Images used

This image relies on a customized base image in order to work.
Be sure to view the following repositories to understand all the customizable options:

| Image                                                   | Description           |
| ------------------------------------------------------- | --------------------- |
| [OS Base](https://github.com/nfrastack/container-base/) | Base Image            |
| [Nginx](https://github.com/nfrastack/container-nginx/)  | Web Server Base Image |

Below is the complete list of available options that can be used to customize your installation.

### Core Configuration

| Parameter      | Description                                                                                        | Default  |
| -------------- | -------------------------------------------------------------------------------------------------- | -------- |
| `SETUP_TYPE`   | Lite `config.json` handling. `AUTO` generates, `MANUAL` leaves it                                  | `AUTO`   |
| `BULWARK_MODE` | Runtime mode  `full` `lite` `relay`  comma separated                                               | `full`   |
| `ENABLE_NGINX` | Serve through nginx in front  of `full` server                                                     | `FALSE`  |
| `LOG_TYPE`     | Log output type for both services. Override per service with `BULWARK_LOG_TYPE` / `RELAY_LOG_TYPE` | `FILE`   |
| `LOG_PATH`     | Log directory for both services. Override per service with `BULWARK_LOG_PATH` / `RELAY_LOG_PATH`   | `/logs/` |

### Bulwark Full Mode Options

Passed through to the Bulwark Node.js server. See the [environment reference](https://bulwarkmail.org/docs/getting-started/configuration/environment-reference) for the full list.

| Parameter                    | Description                                                                       | Default                |
| ---------------------------- | --------------------------------------------------------------------------------- | ---------------------- |
| `BULWARK_USER`               | User the `full` server runs as                                                    | `bulwark`              |
| `BULWARK_GROUP`              | Group the `full` server runs as                                                   | `bulwark`              |
| `BULWARK_LISTEN_PORT`        | Port the `full` server listens on                                                 | `3000`                 |
| `BULWARK_CONFIG_PATH`        | Admin config directory                                                            | `/config/`             |
| `BULWARK_SETTINGS_PATH`      | Encrypted user settings directory                                                 | `/data/settings/`      |
| `BULWARK_ADMIN_STATE_PATH`   | Admin runtime state directory                                                     | `/data/admin-state/`   |
| `BULWARK_TELEMETRY_PATH`     | Telemetry state directory                                                         | `/data/telemetry/`     |
| `BULWARK_VERSION_CHECK_PATH` | Update check state directory                                                      | `/data/version-check/` |
| `BULWARK_LOG_PATH`           | Bulwark log directory                                                             | `/logs/bulwark/`       |
| `BULWARK_LOG_FILE`           | Bulwark log file name                                                             | `bulwark.log`          |
| `LOG_LEVEL`                  | Server log level. `error` `warn` `info` `debug`                                   | `info`                 |
| `LOG_FORMAT`                 | Log format. `text` or `json`                                                      |                        |
| `JMAP_SERVER_URL`            | URL of the JMAP mail server. Example: `https://mail.example.com`                  |                        |
| `APP_NAME`                   | App name shown in the UI                                                          |                        |
| `APP_SHORT_NAME`             | App short name for the PWA manifest                                               |                        |
| `APP_DESCRIPTION`            | App description for the PWA manifest                                              |                        |
| `SESSION_SECRET`             | Secret for Remember me and settings sync. Generate with `openssl rand -base64 32` |                        |
| `SETTINGS_SYNC_ENABLED`      | Sync user settings across devices. Requires `SESSION_SECRET`                      |                        |
| `ADMIN_PASS`                 | Bootstrap password for the admin dashboard.                                       |                        |
| `ALLOW_CUSTOM_JMAP_ENDPOINT` | Show a JMAP server field on the login page                                        |                        |
| `BULWARK_TELEMETRY`          | Vendor telemetry. `on` opts in, `off` disables.                                   | `off`                  |
| `BULWARK_UPDATE_CHECK`       | Set `off` to disable release update checks                                        |                        |
| `LOGIN_COMPANY_NAME`         | Company name shown on login                                                       |                        |
| `LOGIN_SHOW_VERSION`         | Show version on login                                                             |                        |
| `TRUSTED_PROXY_DEPTH`        | `X-Forwarded-For` hops to trust behind proxies                                    |                        |
| `OAUTH_ENABLED`              | Enable OAuth / OIDC login                                                         |                        |
| `OAUTH_CLIENT_ID`            | OAuth client ID                                                                   |                        |
| `OAUTH_CLIENT_SECRET`        | OAuth client secret                                                               |                        |
| `OAUTH_ISSUER_URL`           | OAuth issuer URL                                                                  |                        |

### Bulwark Lite Mode Options

Used when `SETUP_TYPE=AUTO` to generate `config.json`. Drop your own file at `/config/config.json` to override.

| Parameter                       | Description                            | Default           |
| ------------------------------- | -------------------------------------- | ----------------- |
| `BULWARK_JMAP_SERVER_URL`       | URL of the JMAP mail server            |                   |
| `BULWARK_APP_NAME`              | App name shown in the UI               | `Bulwark Webmail` |
| `BULWARK_ALLOW_CUSTOM_ENDPOINT` | Show a server field on login           | `true`            |
| `BULWARK_REMEMBER_ME`           | Show remember me option                | `true`            |
| `BULWARK_DEMO_MODE`             | Serve fixture data with no mail server | `false`           |
| `BULWARK_LOGIN_SHOW_TOTP`       | Show the 2FA code toggle               | `true`            |
| `BULWARK_LOGIN_SHOW_VERSION`    | Show the version on the login page     | `true`            |

### Relay Options

| Parameter                  | Description                                                                 | Default        |
| -------------------------- | --------------------------------------------------------------------------- | -------------- |
| `RELAY_USER`               | User the push relay runs as                                                 | `relay`        |
| `RELAY_GROUP`              | Group the push relay runs as                                                | `relay`        |
| `RELAY_LISTEN_PORT`        | Port the push relay listens on                                              | `3003`         |
| `RELAY_LISTEN_IP`          | Address the push relay binds to                                             | `0.0.0.0`      |
| `RELAY_LOG_PATH`           | Relay log directory                                                         | `/logs/relay/` |
| `RELAY_LOG_FILE`           | Relay log file name                                                         | `relay.log`    |
| `PUSH_DATA_PATH`           | Relay state directory                                                       | `/data/relay`  |
| `VAPID_PUBLIC_KEY`         | Web Push VAPID public key. Generate with `npx web-push generate-vapid-keys` |                |
| `VAPID_PRIVATE_KEY`        | Web Push VAPID private key                                                  |                |
| `VAPID_SUBJECT`            | Contact for push services (`mailto:` or `https:`)                           |                |
| `FCM_SERVICE_ACCOUNT_JSON` | Firebase service account JSON, inline or path                               |                |

Point webmail at the relay from the admin dashboard relay list, or with the `NEXT_PUBLIC_PUSH_RELAY_URL` build arg. Web Push needs `VAPID_*`.

## Users and Groups

| Type  | Name      | ID   |
| ----- | --------- | ---- |
| User  | `bulwark` | 2525 |
| Group | `bulwark` | 2525 |
| User  | `relay`   | 2526 |
| Group | `relay`   | 2526 |

### Networking

| Port   | Protocol | Description                                              |
| ------ | -------- | -------------------------------------------------------- |
| `3000` | tcp      | Bulwark server (full mode)                               |
| `80`   | tcp      | Nginx (lite mode, or full mode with `ENABLE_NGINX=TRUE`) |
| `3003` | tcp      | Push relay

* * *

## Maintenance

### Shell Access

For debugging and maintenance, `bash` and `sh` are available in the container.

## Support & Maintenance

- For community help, tips, and community discussions, visit the [Discussions board](/discussions).
- For personalized support or a support agreement, see [Nfrastack Support](https://nfrastack.com/).
- To report bugs, submit a [Bug Report](issues/new). Usage questions will be closed as not-a-bug.
- Feature requests are welcome, but not guaranteed. For prioritized development, consider a support agreement.
- Updates are best-effort, with priority given to active production use and support agreements.

## References

- [Bulwark Webmail](https://bulwarkmail.org)
- [Bulwark Documentation](https://bulwarkmail.org/docs)
- [bulwarkmail/webmail](https://github.com/bulwarkmail/webmail)
- [bulwarkmail/relay](https://github.com/bulwarkmail/relay)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. The Bulwark Webmail application built by this image is licensed [AGPL-3.0-only](https://github.com/bulwarkmail/webmail/blob/main/LICENSE).
