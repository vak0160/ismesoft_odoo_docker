FROM ismesoft/odoo:10.1
LABEL maintainer Andre Kurniawan <andre.kurniawan@sibasistem.co.id>

# patch Cybroaddons' print spamming
RUN sed -i 's/print "hello"//g'  /opt/odoo_addons/CybroOdoo/CybroAddons/sale_discount_total/models/sale.py \
    && sed -i 's/print "total_excluded:",total_excluded//g'  /opt/odoo_addons/CybroOdoo/CybroAddons/sale_discount_total/models/sale.py \
    && sed -i 's/print "total_included:",total_included//g'  /opt/odoo_addons/CybroOdoo/CybroAddons/sale_discount_total/models/sale.py \
    # remove bad addons from dhongu/deltatech
    rm -R /opt/odoo_addons/dhongu/deltatech/website_report
