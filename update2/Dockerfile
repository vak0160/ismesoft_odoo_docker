FROM ismesoft/odoo:10.1
LABEL maintainer Andre Kurniawan <andre.kurniawan@sibasistem.co.id>

# patch Cybroaddons' print spamming
RUN set -ex; \
    sed -i 's/print "hello"//g'  /opt/odoo_addons/CybroOdoo/CybroAddons/sale_discount_total/models/sale.py \
    && sed -i 's/print "total_excluded:",total_excluded//g' /opt/odoo_addons/CybroOdoo/CybroAddons/sale_discount_total/models/sale.py \
    && sed -i 's/print "total_included:",total_included//g' /opt/odoo_addons/CybroOdoo/CybroAddons/sale_discount_total/models/sale.py \
    # remove bad addons from dhongu/deltatech
    && rm -R /opt/odoo_addons/dhongu/deltatech/website_report \
    # install git
    && apt-get update \
    && apt-get -y --no-install-recommends install git \
    # add addons from https://github.com/OCA/account-payment.git
    && cd /opt/odoo_addons/OCA/ \
    && git clone https://github.com/OCA/account-payment.git --depth=1 --branch=10.0 \
    && rm -R account-payment/.git* \
    # add addons from https://github.com/akhdaniel/published_addons
    && cd /opt/odoo_addons/ \
    && mkdir akhdaniel && cd akhdaniel \
    && git clone https://github.com/akhdaniel/published_addons.git --depth=1 --branch=10.0 \
    && rm -R published_addons/.git* \
    # remove bad modules that using deprecated simplejson package
    && rm -R published_addons/vit_dummy_fingerprint published_addons/vit_sms_mysmsmasking published_addons/vit_sms_nusasms published_addons/vit_website_sale_selectize \
    # clean git
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false git

# copy updated odoo.conf
COPY ./odoo.conf /etc/odoo/
