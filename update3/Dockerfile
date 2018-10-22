FROM ismesoft/odoo:10.2
LABEL maintainer Andre Kurniawan <andre.kurniawan@sibasistem.co.id>

# Update pip & Add pandas
RUN set -ex; \
    pip install --upgrade pip wheel setuptools \
    && pip install --upgrade pandas matplotlib scikit-learn==0.20.0
