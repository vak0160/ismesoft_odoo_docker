try:
    from odoo.addons.web.controllers.main import Database, DBNAME_PATTERN
except ImportError:
    Database = object
    DBNAME_PATTERN = '^[a-zA-Z0-9][a-zA-Z0-9_.-]+$'

import os
import sys

import jinja2
import odoo
from odoo.exceptions import AccessDenied

if hasattr(sys, 'frozen'):
    # When running on compiled windows binary, we don't have access to package loader.
    path = os.path.realpath(os.path.join(os.path.dirname(__file__), '..', 'view'))
    loader = jinja2.FileSystemLoader(path)
else:
    loader = jinja2.PackageLoader('odoo.addons.isme_db_debrand', "view")

env = jinja2.Environment(loader=loader, autoescape=True)


class DatabaseView(Database):
    """
    Override method ``_render_template``, supaya mengambil template dari sini
    """

    def _render_template(self, **d):
        """
        Mengganti Template
        """
        d.setdefault('manage', True)
        d['insecure'] = odoo.tools.config['admin_passwd'] == 'admin'
        d['list_db'] = odoo.tools.config['list_db']
        d['langs'] = odoo.service.db.exp_list_lang()
        d['countries'] = odoo.service.db.exp_list_countries()
        d['pattern'] = DBNAME_PATTERN
        # databases list
        d['databases'] = []
        try:
            d['databases'] = odoo.http.db_list()
        except AccessDenied:
            monodb = odoo.http.db_monodb()
            if monodb:
                d['databases'] = [monodb]
        return env.get_template("database_manager.html").render(d)
