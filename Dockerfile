FROM debian:jessie
MAINTAINER Andre Kurniawan <andre.kurniawan@sibasistem.co.id>

# Setup ENVs
ENV GOSU_VERSION=1.10 ODOO_RC=/etc/odoo/odoo.conf ODOO_VERSION=10.0

# update latest debian & install wget + certs
RUN set -ex; \
    apt-get update \
    && apt-get upgrade --with-new-pkgs -y \
    && apt-get install -y --no-install-recommends wget ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false

# Gosu & certs
RUN set -ex; \
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

# Wkhtmltopdf
RUN set -ex; \
    apt-get update \
    && wget -O wkhtmltox.deb http://nightly.odoo.com/extra/wkhtmltox-0.12.1.2_linux-jessie-amd64.deb \
    && echo '40e8b906de658a2221b15e4e8cd82565a47d7ee8 wkhtmltox.deb' | sha1sum -c - \
    && dpkg --force-depends -i wkhtmltox.deb \
    && apt-get -y install -f --no-install-recommends \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# latest postgresql client
RUN set -ex; \
    apt-get update \
    && echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' | tee /etc/apt/sources.list.d/postgresql.list \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && apt-get update \
    && apt-get install -y postgresql-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ODOO dependencies
RUN set -ex; \
    apt-get update \
    && apt-get install -y --no-install-recommends python-pip node-less \
        git python-dev build-essential \
    && pip install cython --install-option="--no-cython-compile" \
    && pip install psycogreen==1.0 peewee xlrd xlsxwriter \
    && pip uninstall -y cython \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false \
        git python-dev build-essential

# Odoo & another dependecies
RUN set -ex; \
    apt-get update \
    && apt-get install -y --no-install-recommends git \
        libpq-dev libxml2-dev libxslt1-dev libfreetype6-dev libjpeg62-turbo-dev libsasl2-dev libldap2-dev libssl-dev \
    && pip install cython --install-option="--no-cython-compile" \
    && cd /opt/ \
    && git clone --depth=1 --branch=10.0 https://github.com/OCA/OCB.git \
    && pip install -r OCB/requirements.txt \
    && pip uninstall -y cython \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false \
        git libpq-dev libxml2-dev libxslt1-dev libfreetype6-dev libjpeg62-turbo-dev libsasl2-dev libldap2-dev libssl-dev

# additional addons
RUN set -ex; \
    apt-get update \
    && apt-get -y --no-install-recommends install git \
    && mkdir -p /opt/odoo_addons/ \
    && cd /opt/odoo_addons/ \

    # server tools from OCA
    && git clone https://github.com/OCA/server-tools.git --depth=1 --branch=${ODOO_VERSION} \
    && rm -Rf server-tools/.git* \

    # web from OCA
    && git clone https://github.com/OCA/web.git --depth=1 --branch=${ODOO_VERSION} \
    && rm -Rf web/.git* \

    # product-attribute from OCA
    && git clone https://github.com/OCA/product-attribute.git --branch=${ODOO_VERSION} \
    && rm -Rf product-attribute/.git* \

    # purchase-workflow from OCA
    && git clone https://github.com/OCA/purchase-workflow.git --depth=1 --branch=${ODOO_VERSION} \
    && rm -Rf purchase-workflow/.git* \

    # reporting-engine from OCA
    && git clone https://github.com/OCA/reporting-engine.git --branch=${ODOO_VERSION} \
    && rm -Rf reporting-engine/.git* \
    # remove unported addons that causing problem
    && rm -Rf reporting-engine/report_xls reporting-engine/base_report_assembler \

    # operating-unit
    # && git clone https://github.com/OCA/operating-unit.git --branch=${ODOO_VERSION} \
    # && rm -Rf operating-unit/.git* \

    # POS Addons from it-projects-llc
    && mkdir it-projects-llc && cd it-projects-llc \
    && git clone https://github.com/it-projects-llc/pos-addons.git --depth=1 --branch=10.0 \
    # remove product_brand module, overlap with OCA's product-attribute
    && rm -Rf pos-addons/.git* && rm -Rf pos-addons/product_brand/ && cd /opt/odoo_addons/ \

    # CybroAddons from CybroOdoo / Cybrosys Techno Solutions
    && mkdir CybroOdoo && cd CybroOdoo \
    && git clone https://github.com/CybroOdoo/CybroAddons.git --depth=1 --branch=10.0 \
    && rm -Rf CybroAddons/.git* && cd /opt/odoo_addons/ \

    # l10n-indonesia from OCA & raditv
    && mkdir raditv && cd raditv \
    && git clone https://github.com/raditv/l10n-indonesia.git --depth=1 --branch=10.0 \
    && rm -Rf raditv/.git* && cd /opt/odoo_addons/ \

    # Account Parent from steigendit
    && mkdir steigendit && cd steigendit \
    && git clone https://github.com/steigendit/addons-steigend.git --depth=1 --branch=10.0 \
    && rm -Rf steigendit/.git* && cd /opt/odoo_addons/ \

    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false git \

    # extra addons slot
    && mkdir -p /mnt/extra-addons; mkdir -p /mnt/extra-addons2; mkdir -p /mnt/extra-addons3

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/

# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
VOLUME ["/var/lib/odoo", "/mnt/extra-addons", "/mnt/extra-addons2", "/mnt/extra-addons3"]

# Expose Odoo services
EXPOSE 8069 8072

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
