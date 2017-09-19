FROM debian:jessie
MAINTAINER Andre Kurniawan <andre.kurniawan@sibasistem.co.id>

# All needed dependencies, pip included
RUN set -ex; \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        wget \
        ca-certificates \
        node-less \
        python-gevent \
        python-pip \
        python-renderpm \
        python-support \
        python-watchdog \
        python-dev \
        gcc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Update latest pip & install odoo deps using pip
RUN set -ex; \
    pip install --upgrade pip \
    && pip install cython --install-option="--no-cython-compile" \
    && pip install psycogreen==1.0 peewee xlrd xlsxwriter httpagentparser

# Gosu
ENV GOSU_VERSION=1.10
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

# wkhtmltopdf
ENV WKHTMLTOPDF_URL=http://nightly.odoo.com/extra/wkhtmltox-0.12.1.2_linux-jessie-amd64.deb
ENV WKHTMLTOPDF_HASH=40e8b906de658a2221b15e4e8cd82565a47d7ee8
RUN set -ex; \
    wget -O wkhtmltox.deb $WKHTMLTOPDF_URL \
    && echo $WKHTMLTOPDF_HASH wkhtmltox.deb | sha1sum -c - \
    && apt-get update \
    && dpkg --force-depends -i wkhtmltox.deb \
    && apt-get -y install -f --no-install-recommends \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# Postgres List & Odoo
ENV ODOO_RC=/etc/odoo/odoo.conf
ENV ODOO_VERSION=10.0
ENV ODOO_DATE=20170613
ENV ODOO_HASH=26201aaee763c0a24b431cc69f3d1602605e7a00
RUN set -ex; \
    echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' | tee /etc/apt/sources.list.d/postgresql.list \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && apt-get update \
    && wget -O odoo.deb http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_DATE}_all.deb \
    && echo $ODOO_HASH odoo.deb | sha1sum -c - \
    && dpkg --force-depends -i odoo.deb \
    && apt-get -y install -f --no-install-recommends \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* odoo.deb

# db list/manager debranding by ISMESoft
COPY ./isme_db_debrand /opt/odoo_addons/ismesoft/isme_db_debrand

# additional addons
RUN set -ex; \
    apt-get update \
    && apt-get -y --no-install-recommends install git \
    && mkdir -p /opt/odoo_addons/ \
    && cd /opt/odoo_addons/ \

    # Prepare OCA addons directory
    && mkdir OCA && cd OCA \

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

    # vertical-association from OCA
    && git clone https://github.com/OCA/vertical-association.git --depth=1 --branch=${ODOO_VERSION} \
    && rm -Rf vertical-association/.git* \

    # hr from OCA
    && git clone https://github.com/OCA/hr.git --depth=1 --branch=${ODOO_VERSION} \
    && rm -Rf hr/.git* \

    # reporting-engine from OCA
    && git clone https://github.com/OCA/reporting-engine.git --branch=${ODOO_VERSION} \
    && rm -Rf reporting-engine/.git* \
    # remove unported addons that causing problem
    && rm -Rf reporting-engine/report_xls reporting-engine/base_report_assembler \

    # operating-unit
    # && git clone https://github.com/OCA/operating-unit.git --branch=${ODOO_VERSION} \
    # && rm -Rf operating-unit/.git* \

    # Return to normal addons folder
    && cd /opt/odoo_addons/ \

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

    # HR Holidays Multi Levels Approval from baamtu
    && mkdir baamtu && cd baamtu \
    && git clone http://github.com/baamtu/hr_holidays_multi_levels_approval.git --depth=1 --branch=${ODOO_VERSION} \
    && rm -Rf hr_holidays_multi_levels_approval/.git* && cd /opt/odoo_addons/ \

    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false git \

    # extra addons slot
    && mkdir -p /mnt/extra-addons; mkdir -p /mnt/extra-addons2; mkdir -p /mnt/extra-addons3

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/

# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
VOLUME ["/var/lib/odoo"]

# Expose Odoo services
EXPOSE 8069 8072

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
