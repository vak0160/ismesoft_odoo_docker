from urllib import urlopen
from time import sleep

vers = ("10.0", "9.0", "8.0")


print "{} | {:^8} | {:^40} | {:^30} | {}".format(
    "Version", "Release", "Hash", "Filename", "Size"
)
for version in vers:
    sleep(0.1)
    root = "https://nightly.odoo.com/{ver}/nightly/deb".format(ver=version)
    url = "{root}/odoo_{ver}.latest_amd64.changes".format(root=root, ver=version)
    response = urlopen(url)
    data = response.read()
    hash_str, size, filename = data.split("\n")[22].strip().split()
    release = filename.split("_")[1].rsplit(".", 1)[1]

    print "{:>7} | {} | {} | {:<30} | {}".format(
        version, release, hash_str, filename, size
    )
