FROM postgres:16-bullseye

ARG ROOT_PASSWORD="changeme"
ARG APP_PASSWORD="changeme"
ARG APP_UID=1000
ARG SSHD_PORT=22
ARG HTTPDX_PORT=80

USER root

ADD bin/ /bin/

WORKDIR /

RUN set -eux; \
    mkdir -p /data/etc; \
    mv /root /data/root; \
    ln -s /data/root /root; \
    mkdir /data/etc/httpdx; \
    httpdx create-config -server-addr $HTTPDX_PORT -out "/data/etc/httpdx/httpdx.yml"; \
    apt update; \
    apt install -y curl \
        supervisor \
        procps \
        passwd \
        openssh-server \
        vim \
        nano \
        tmux \
        tree \
        unzip \
        htop \
        cron; \
    rm -rf /var/lib/apt/lists/*; \
    mv /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-postgresql-entrypoint.sh; \
    if [ ! -e /root/.ssh ]; then \
        set -eux; \
        mkdir -p /root/.ssh; \
        chmod 700 /root/.ssh; \
        ssh-keygen -q -t rsa -f /root/.ssh/id_rsa -N '' -C 'keypair generated during docker build'; \
        cat /root/.ssh/id_rsa.pub > /root/.ssh/authorized_keys; \
        chmod 600 /root/.ssh/authorized_keys; \
    fi; \
    mkdir -p /var/run/sshd; \
    chmod 700 /var/run/sshd; \
    echo "root:$ROOT_PASSWORD" | chpasswd; \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config; \
    echo "Port ${SSHD_PORT}" >> /etc/ssh/sshd_config; \
    adduser --uid $APP_UID --home /data/app app; \
    echo "app:$APP_PASSWORD" | chpasswd; \
    if [ ! -e ~app/.ssh ]; then \
        su - app -c 'set -eux; mkdir .ssh; chmod 700 .ssh; ssh-keygen -q -t rsa -N "" -f .ssh/id_rsa'; \
    fi; \
    mkdir /var/log/sshd; \
    mkdir /var/log/ssh;


RUN set -eux; \
    mkdir -p /data/etc/supervisor; \
    mv /etc/supervisor/conf.d /data/etc/supervisor/conf.d; \
    ln -s /data/etc/supervisor/conf.d /etc/supervisor/conf.d; \
    mkdir -p /data/var/lib/postgresql; \
    ln -s /data/var/lib/postgresql/data /var/lib/postgresql/data; \
    mv /usr/bin/passwd /usr/bin/__passwd.original; \
    mv /bin/__passwd /usr/bin/passwd; \
    mv /usr/sbin/chpasswd /usr/sbin/__chpasswd.original; \
    mv /bin/__chpasswd /usr/sbin/chpasswd; \
    mv /etc/shadow /data/etc/shadow; \
    ln -s /data/etc/shadow /etc/shadow;

ADD supervisor-services/ /data/etc/supervisor/conf.d/
ADD entrypoint.sh /usr/local/bin/docker-minimal-server-entrypoint.sh
ADD data /data

VOLUME /data

EXPOSE $SSHD_PORT
EXPOSE $HTTPDX_PORT

ENV PATH="/data/bin:${PATH}"

ENTRYPOINT ["docker-minimal-server-entrypoint.sh"]