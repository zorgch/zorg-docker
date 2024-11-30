zorg on Docker
===

> *Portable, Server independent, Docker-based code to get the zorg Websites and Services up, running, and hosted.*

---

**Table of Contents**
<!-- TOC maker: https://github.com/derlin/bitdowntoc -->

[🔖 Pre-requisites](#-pre-requisites)
- [git installation](#git-installation)
- [Docker installation](#docker-installation)
- [📂 Folder structure setup](#-folder-structure-setup)

[🏁 Getting started](#-getting-started)
- [Initial setup (one time only)](#initial-setup-one-time-only)
- [⏩ Update the local cloned `zorg-docker` git repository](#-update-the-local-cloned-zorg-docker-git-repository)

[👨‍💻 Docker services](#-docker-services)
- [Manage general services](#manage-general-services)
    - [Single «KeePass SFTP» service](#run-the-keepass-sftp-service-separately)
    - [Single «Quake 3 Arena Server»](#run-the-quake-3-arena-server-separately)
    - [Single «phpDocumentor» service](#run-the-phpdocumentor-service-separately)
- [🩺 Resource usage & services health](#docker-resource-usage---services-health)


[👨‍🏫 Explanations](#-explanations)
- [🧪 Debugging Docker Services](#-debugging-docker-services)
- [🏷️ Docker services -> profiles mapping](#-docker-services---profiles-mapping)
- [📄 The `/zorg-docker/resources`-directory & files](#-the-zorg-dockerresources-directory--files)

<br>

---

<br>

## 🔖 Pre-requisites
### git installation
Install **git** [for your OS](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git).

<br>

### Docker installation
Following the [official installation instructions](https://docs.docker.com/engine/install/) for **Docker**.

> [!TIP]
> On Ubuntu it's advised *against installing via snap*, as this may cause compatibility issues!

<br>

### 📂 Folder structure setup
Creat the a folder structure on your host machine that reflects the following:

> [!IMPORTANT]
> This is just a proposal, folder structures & names can be different!

```
└── www               <-- (Your project root directory)
    │
    ├── zorg-docker/       <-- Pulled Git repository (repo)
    │
    ├── .env               <-- Copy & adjust ".env.example" from repo
    ├── docker-compose.yml <-- Symbolic-linked ./zorg-docker/docker-compose.yml
    │
    ├── apache/
    │   ├── zorg.conf      <-- Copy & adjust "website/apache/example.conf" from repo
    │   ├── cronjobs/
    │   │   └── cronjobs.crontab   <-- Copy & adjust "website/php/example.crontab" from repo
    │   ├── modsec/
    │   │   └── WAF-REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf   <-- (Optional)
    │   │   └── WAF-RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf   <-- (Optional)
    │   └── sendmail/
    │       └── msmtprc    <-- Copy & adjust "website/sendmail/example-msmtprc" from repo
    │
    ├── code-docu/
    │   └── phpdoc.xml     <-- (Optional)
    │
    ├── website/           <-- zorg Website configs & data
    │   ├── .env           <-- .env file for Website
    │   └── data/          <-- Website /data/ folder & files
    │       ├── files/         (user generated content for zorg website)
    │       ├── gallery/
    │       ├── tauschboerse/
    │       └── ...
    │
    ├── irc/
    │   ├── anope-configs/    <-- Copy & adjust "irc/anope-example-sensitive-includes" from repo
    │   │   ├── sensitive-channels.conf
    │   │   ├── sensitive-mail.conf
    │   │   ├── sensitive-networkinfo.conf
    │   │   ├── sensitive-nicknames.conf
    │   │   ├── sensitive-operators.conf
    │   │   ├── sensitive-serverinfo.conf
    │   │   ├── sensitive-uplink.conf
    │   │   └── services.motd
    │   └── ircd-configs/     <-- Copy & adjust "irc/unrealircd-example-sensitive-includes" from repo
    │       ├── ircd.motd
    │       ├── sensitive-admin.conf
    │       ├── sensitive-history.conf
    │       ├── sensitive-me.conf
    │       ├── sensitive-network.conf
    │       ├── sensitive-operators.conf
    │       ├── sensitive-server.conf
    │       └── sensitive-servicelink.conf
    │
    ├── keepass/
    │   └── vault.kdbx     <-- Put kdbx file here. Reference in .env
    │
    ├── logs/              <-- Reference in .env - Sub-directories are created automatically
    │
    └── quake3-baseq3/
        ├── autoexec.cfg    <-- Copy & adjust "quake3/example-autoexec.cfg" from repo
        ├── pak0.pk3        <-- Should be sufficient
        └── pak1-8.pk3      <-- Provide only if "Client/Server Mismatch" occurs
```

<br><br>

## 🏁 Getting started
In general make sure to work from the project root directory:

`cd /srv/<my-website>/<host>`

<br>

### Initial setup (one time only)
#### Git clone the `zorg-docker` repository

```bash
git clone -b <branch-name> --depth 1 https://github.com/zorgch/zorg-docker.git ./zorg-docker
```

> [!INFO]
> See below section for how to UPDATE the cloned git repository to get its latest changes.

##### Copy the example `.env`-file

```bash
cp ./zorg-docker/.env.example ./zorg-docker/.env
```

> [!IMPORTANT]
> Using your text editor of choice, adjust the `.env`-file to the setup of your host machine.

##### Create a symbolic link to `docker-compose.yml`

```bash
ln -s ./zorg-docker/docker-compose.yml ./docker-compose.yml
```

#### Validate the Docker services configurations

```bash
docker compose build
```

<br>

#### 🔐 TLS/SSL: generate self-signed certificates
Some services require self-signed certificates, this does not interfere with (also) using Let's Encrypt certificates!

Add these first using the `sslcerts` service:

```bash
docker compose --profile setup up
```

<br>

#### 📧 Mailserver (SMTP) configuration

> [!INFO]
> This requires the mailserver service to be running!

##### Add postfix accounts & email forwarding

> [!NOTE]
> This is required when emails to a local user (alias) should be forwarded to an external email address corresponding to that alias.

```
docker exec -ti PROJECTNAME-mailserver setup email add postmaster@DOMAINNAME <NEW_PASSWORD>
docker exec -ti PROJECTNAME-mailserver setup alias add <EMAILADDRESS> <RECIPIENT>
```

##### General mailserver setup help

The docker-mailserver setup is required for various configurations, including for example [DKIM](https://docker-mailserver.github.io/docker-mailserver/v11.0/config/best-practices/dkim/).

```
docker exec -ti PROJECTNAME-mailserver setup
docker exec -ti PROJECTNAME-mailserver setup config dkim help
```

<br>

#### 👨‍💻 Working locally (development)? Add `hosts`!

On production a proper setup with pointing DNS for the root domain to the server's IP-address, this should not be necessary. But **locally** with a dummy domain, the domain & hostnames must be added to the `/etc/hosts`-file:

<details>
<summary>Example `hosts`-entries</summary>

(adjust as per your `.env` settings)

```bash
127.0.0.1	zdocker.dev
127.0.0.1	status.zdocker.dev
127.0.0.1	www.zdocker.dev
127.0.0.1	db.zdocker.dev
127.0.0.1	ftp.zdocker.dev
127.0.0.1	irc.zdocker.dev
127.0.0.1	pw.zdocker.dev
127.0.0.1	smtp.zdocker.dev
127.0.0.1	quake.zdocker.dev
```
</details>

<br>

### ⏩ Update the local cloned `zorg-docker` git repository
cd into the directory containing the locally cloned git files, and run a git pull:

```bash
cd /srv/<my-website>/<host>/zorg-docker
git pull --depth 1 --rebase
```


<br><br>

## 👨‍💻 Docker services
### Manage general services

**PRODUCTION mode** – run in "detached mode" (background), *without* interative logging to the shell by adding the `-d` flag.

<details open>
<summary>Start/stop all services <sup>*</sup></summary>

```bash
docker compose --profile all up -d
```

* Applicable services: `dashboard`, `reverseproxy`, `waf`, `website`, `db`, `postfix-smtp`, `irc`, `irc-quizbot`, `stockticker`
</details>

<details>
<summary>Example: only the Webserver services</summary>

```bash
docker compose --profile webserver up -d
```
* Applicable services: `dashboard`, `reverseproxy`, `waf`, `website`, `db`, `postfix-smtp`
</details>

<details>
<summary>Example 2: only the IRC services</summary>

```bash
docker compose --profile irc up -d
```
* Applicable services: `dashboard`, `irc`, `irc-quizbot`
</details>

<br>

#### Run the KeePass SFTP-service (separately)
<sup>*</sup> As provisioning a KeePass KDBX via SFTP is not required for the general website hosting, the SFTP service (`keepass`) is separated from the overall services.

```bash
docker compose --profile sftp up -d
```

<br>

#### Run the Quake 3 Arena Server (separately)
<sup>*</sup> Due to a potential high load on the server, the «Quake 3 Arena» Server (`quake3`) is separated from the general services.

```bash
docker compose --profile quake up -d
```

<br>

#### Run the phpDocumentor service (separately)
<sup>*</sup> As the code generation is only run occassionally, the phpDoc service (`phpdoc`) is separated from the general services.

```bash
docker compose --profile docu up
```

<br>

## 🩺 Docker resource usage & services health

### Quick resource analysis using the CLI

This is particularly helpful to fine-tune the CPU & memory limits for the Docker services, which can be adjusted in the `.env`-file.

```bash
docker stats
```

<details>
<summary>Example docker status output</summary>

```bash
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

NAME                   CPU %     MEM USAGE / LIMIT     MEM %
zorg-reverseproxy      0.00%     69.01MiB / 1GiB       6.74%
zorg-waf               0.03%     70.19MiB / 1GiB       6.85%
zorg-mariadb           0.01%     133.8MiB / 4GiB       3.27%
zorg-website           0.01%     8.855MiB / 4GiB       0.22%
zorg-dashboard         0.00%     27.06MiB / 1GiB       2.64%
zorg-mailserver        0.11%     39.41MiB / 256MiB    15.39%
```
</details>


### The Docker Status-Dashboard

The full-fledged Docker Management Dashboard (Portainer) can be accessed at:

* `https://dockerstatus.DOMAINNAME`<br><sub>*Host can be adjusted in the `.env`*</sub>


<br><br>

## 👨‍🏫 Explanations
### 🧪 Debugging Docker Services
For **DEBUGGING mode** – with an *interactive log output* to the active shell - omit the `-d` flag when starting services:

`docker compose --file ./website/docker-compose.yml up` <-- no `-d` flag

<br>

### 🏷️ Docker services -> profiles mapping
The `docker-compose.yml` file uses Docker Service-profiles to group services into logical groups.

* This allows to only start / stop a certain group of services at once.
* Yet individual docker services can still be targeted individually by referencing their service name.

Some single services have their own profile, in order to prevent them from starting/stopping when using `docker compose` without any `--profile`.

> [!NOTE]
> Multiple profiles can be combined: `docker compose --profile website --profile irc up`

| Profile        | Applicablae Docker Services   | Example Usage                      |
| -------------- | ----------------------------- | ---------------------------------- |
| `all`          | All general services          | `--profile all`                    |
| `setup`        | `sslcerts` `postfix-smtp`    | `--profile setup`                  |
| `status`       | `dashboard` `reverseproxy`    | `--profile status`                 |
| `webserver`    | `dashboard` `reverseproxy` `waf` `website` `db` `postfix-smtp` | `--profile webserver` |
| `mailserver`   | `dashboard` `reverseproxy` `postfix-smtp` | `--profile mailserver`             |
| `irc`          | `dashboard` `irc` `irc-quizbot`           | `--profile irc`                    |
| `sftp`         | `dashboard` `keepass`                     | `--profile sftp`                   |
| `quake`        | `dashboard` `quake3`                      | `--profile quake`                  |
| `docu`         | `phpdoc`                      | `--profile docu`                   |
| Single service | e.g. `stockticker`            | `docker compose up -d stockticker` |

<br>

### 📄 The `/zorg-docker/resources`-directory & files
Contains site specific resources that are actively mapped from the Host to some of the Docker Services. But it also contains some *example* files that can be used to configure the services.

<details>
<summary>Examples of example files</summary>

* `irc/anope-example-*` & `irc/unrealircd-example-*` --> MUST be adapted
* `website/apache/example.conf` --> use as `000-default.conf`
* `website/php/example.crontab` --> use as `crontab`
* `website/sendmail/example-msmtprc` --> use as `msmtprc`
* `quake3/example-autoexec.cfg` --> use as `autoexec.cfg`
</details>

<br>

### 🔁 `logrotate` must be done on the Host
The Docker services are just writing logs to the mapped `/logs`-directory, but `logrotate` must be configured on the Host machine.

<br><br>

---

<br>

## ⚖️ License

> Copyright (C) 2024  zorg Verein <https://github.com/zorgch>
>
>   This program is free software: you can redistribute it and/or modify
> it under the terms of the GNU General Public License as published by
> the Free Software Foundation, either version 3 of the License, or
> (at your option) any later version.
>
>   This program is distributed in the hope that it will be useful,
> but WITHOUT ANY WARRANTY; without even the implied warranty of
> MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
> GNU General Public License for more details.
>
>   You should have received a copy of the GNU General Public License
> along with this program. If not, see <https://www.gnu.org/licenses/>.
>
>   This program comes with ABSOLUTELY NO WARRANTY; for details read the README.
> This is free software, and you are welcome to redistribute it
> under certain conditions; see the LICENSE.

<br><br>

---
# [DEPRECATED] zorg on Docker v1

> [!CAUTION]
> You can ignore this section, as it's overhauled (see above).

## Docker configs
Edit the file: `.env.docker`

#### Setup on macOS
(The following steps are copied from [this online documentation](https://reece.tech/posts/osx-docker-performance/))
* **Recommendation**: use [OrbStack](https://orbstack.dev/) instead of Docker Desktop for Mac!

## Build the Docker container & start the services
Start container with all services.

* in "detached mode" - without interative log in the Shell

```
cd /path/to/zorg-code/
docker compose --project-directory ./ --file ./Docker/docker-compose.yml --env-file ./Docker/.env.docker up -d
```

* or with an interactive log in the Shell

```
cd /path/to/zorg-code/
docker compose --project-directory ./ --file ./Docker/docker-compose.yml --env-file ./Docker/.env.docker up
```

## Usage
---
### Service configurations
#### MySQL connection config
The MySQL database host name is `zorg-db` and needs be added to the PHP environment config file `/www/.env`.

#### sendmail SMTP config
Edit the msmtprc config file in the `./Docker/sendmail/` directory and replace the following placeholders with real values:
* SMTP_HOST => mail.mymailserver.com
* SMTP_EMAIL => myemail@mymailserver.com
* SMTP_PASSWORD => password for your SMTP_EMAIL account

Further details on the sendmail / msmtprc integration can be found here: [Send email on testing docker container with php and sendmail](https://stackoverflow.com/a/63977888/5750030)

### Show the website
[http://localhost/](http://localhost/)

…or with a hosts entry pointing to `127.0.0.1` and SSL: [https://zorg.local/](https://zorg.local/)

### Use PHPMyAdmin to manage the database
[http://localhost:8080/](http://localhost:8080/)

…or with a hosts entry pointing to `127.0.0.1`: [http://zorg.local:8080/](http://zorg.local:8080/)

* **Server**: use the Docker's `zorg-db`-service hostname or IP-address
* **Username**: use the defined `MYSQL_USER`-environment value
* **Password**: use the defined `MYSQL_PASSWORD`-environment value

#### Using a pre-existing local database
The best way is to import an SQL-dump using the phpmysql Docker service at [http://localhost:8080/](http://localhost:8080/).

Alternatively the path to a local database folder can be provided by overriding the ENV var `MYSQL_LOCAL_DATABASE_PATH`:
```
MYSQL_LOCAL_DATABASE_PATH=/path/to/my/mysql57 docker compose --project-directory ./ --file ./Docker/docker-compose.yml --env-file ./Docker/.env.docker up -d
```

#### Fix possible "Tablespace missing"-errors
To fix the MySQL-Error 1812 `Tablespace is missing for table zooomclan . <table-name>` try the following command per affected `<table-name>`:

```ALTER TABLE zooomclan.<table-name> IMPORT TABLESPACE```


## Docker services inspection
Find IP of a container service (can also be seen in the network details)

`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' SERVICENAME`

Inspect all running Docker services

`docker ps`

Inspect all container service details

`docker container inspect SERVICENAME`

Inspect a container's network details

`docker network inspect CONTAINER_NETWORKNAME`

Execute a shell command on a container service

`docker exec -it SERVICENAME ls -la`

* Example: show apache2's `000-default.conf` file:

`docker exec -it zorg-web cat /etc/apache2/sites-available/000-default.conf`

Enter into interactive shell mode for a container service

`docker exec -it SERVICENAME sh`

List all Environment Variables for a container service

`docker exec SERVICENAME env`

### docker-sync inspection
!! Refresh docker-sync after updating the `docker-compose.yml`-file

`docker-sync clean`

Inspect running docker-sync services:

`docker volume ls | grep -sync`

### sendmail Logfile
Inspect the logfile for sendmail / msmtprc:

`docker exec -it zorg-web cat /var/log/sendmail.log`
