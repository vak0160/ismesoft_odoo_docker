FROM ismesoft/odoo:10
LABEL maintainer Andre Kurniawan <andre.kurniawan@sibasistem.co.id>

# Update addons
ENV ADDONS_VERSION=10.0
RUN set -ex; \
    apt-get update \
    && apt-get -y --no-install-recommends install git \
    && cd /opt/odoo_addons/ \
    # update CybroAddons from CybroOdoo
    && rm -R CybroOdoo \
    && mkdir CybroOdoo && cd CybroOdoo \
    && git clone https://github.com/CybroOdoo/CybroAddons.git --depth=1 --branch=$ADDONS_VERSION \
    && rm -Rf CybroAddons/.git* && cd /opt/odoo_addons/ \
    # add deltatech from dhongu
    && mkdir dhongu && cd dhongu \
    && git clone https://github.com/dhongu/deltatech.git --depth=1 --branch=$ADDONS_VERSION \
    && rm -Rf deltatech/.git* && cd /opt/odoo_addons/ \
    # add multi company from OCA
    && cd OCA \
    && git clone https://github.com/OCA/multi-company.git --depth=1 --branch=${ODOO_VERSION} \
    && rm -Rf multi-company/.git* \
    # cleanup git
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false git

# Update latest PIP & add more dependencies
RUN set -ex; \
    pip install --upgrade pip \
    && pip install --upgrade validate_email pytemperature python-stdnum googletrans html2text

# Copy latest conf
COPY ./odoo.conf /etc/odoo/
