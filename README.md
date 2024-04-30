# minimal web server

Is a Minimal Web Server.

## Specs

- Debian Bullseye, inherited from [PostgreSQL 16](https://hub.docker.com/layers/library/postgres/16-bullseye);
- Linux users: this server haves two users: `root` and `app`. 
  For change passwords, use `passwd`
- [HTTPDx](https://github.com/moisespsena-go/httpdx) as HTTP server. See `/data/etc/httpdx/httpdx.conf` configuration file;
- [PostgreSQL 16](https://hub.docker.com/layers/library/postgres/16-bullseye) as database server. It's disabled by default.

  See to [Postgres Docker HUB Page](https://hub.docker.com/_/postgres) for expanded details.  

  For enable it, run: 
  ```bash
  cd /data/etc/supervisor/conf.d
  mv postgresql.conf.disabled postgresql.conf
  supervisorctl update # if container is running
  ```
  
- CRON. It's disabled by default.

  For enable it, run:
  ```bash
  cd /data/etc/supervisor/conf.d
  mv cron.conf.disabled cron.conf
  supervisorctl update # if container is running
  ```
  
- Open SSH Server (sshd). It's disabled by default.

  For enable it, run:
  ```bash
  cd /data/etc/supervisor/conf.d
  mv sshd.conf.disabled sshd.conf
  supervisorctl update # if container is running
  ```
  
  For access SSH server proxified by HTTP websockets, see to HTTPDx
  config in section `server/tcp_sockets`.

  Server config example (`/data/etc/httpdx/httpdx.conf`):
  ```yaml
  server:
    # ...
    tcp_sockets:
      # ...
      routes:
        ssh:
          addr: localhost:22
        # ...
  ```
  
  Client config example `client.yml` (in the client machine):
  ```yaml
  client:
    # ...
    routes:
      - name: ssh
        local_addr: :25000
  ```
  
  To connect, in client machine, runs `httpdx -config client.yml client`, in another
  terminal session, runs `ssh -p 25000 root@127.0.0.1`.

## Volumes
  - PGDATA: `/var/lib/postgresql/data`
  - DATA: `/data`
    - If $PGDATA is default value, it's stored into `/data/var/lib/postgresql/data`.
    - The `~root` dir is stored into `/data/root` (haves symbolic link from `/root` to `/data/root`)
    - The `~app` dir is stored into `/data/app`

## Image building

Build Arguments:
- ROOT_PASSWORD="changeme"
- APP_PASSWORD="changeme"
- APP_UID=1000
- SSHD_PORT=22
- HTTPDX_PORT=80

Example:
```bash
docker build \
  --build-arg HTTPDX_PORT=8080 \
  --build-arg APP_PASSWORD=123 \
  --tag my-minimal-server:latest .
```

## Enviroment variables

See to [Postgres Docker HUB Page](https://hub.docker.com/_/postgres) for PostgreSQL
variables.

- ROOT_PASSWORD: if set, replaces `root` user password.
- APP_PASSWORD: if set, replaces `app` user password.

## Add custom application

- To add custom application server, when logged as `app` user, puts contents into `~app/`.
- If haves a services, puts your supervisor configuration into 
`/data/etc/supervisor/config.d` and runs `supervisorctl update`.
- If haves HTTP server, add proxy config in `/data/etc/httpdx/httpdx.yml`.

## Scripts

- `/data/main.sh`: is default command runed by ENTRYPOINT. Edit it to set custom command.
- `/data/setup.sh`: this command was called by ENTRYPOINT if `/data/.initialized` does not exists.
  It's a tool to configure your container on first execution or post image updated or same 
  runs container after deleted `/data/.initialized`. 