"""
Copy this to ~/.ansible/plugins/inventory/
"""

# Copyright (c) 2018 Ansible Project
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import (absolute_import, division, print_function)


__metaclass__ = type

DOCUMENTATION = '''
    name: aws_tfstate
    plugin_type: inventory
    author:
      - Eric Ihli
    short_description: Inventory source for terraformed digital ocean resources
    description:
        - Get inventory hosts from tfstate
'''

EXAMPLES = '''
# Example command line: ansible-inventory --list -i terraform.tfstate
'''

import json
from sys import version as python_version

from ansible.errors import AnsibleError
from ansible.module_utils.urls import open_url
from ansible.plugins.inventory import BaseInventoryPlugin
from ansible.module_utils._text import to_native, to_text
from ansible.module_utils.ansible_release import __version__ as ansible_version
from ansible.module_utils.six.moves.urllib.parse import urljoin

class InventoryModule(BaseInventoryPlugin):
    NAME = "aws_tfstate"

    def verify_file(self, path):
        if not path.endswith("tfstate"):
            return False
        with open(path) as f:
            return r"provider[\"registry.terraform.io/hashicorp/aws\"]" in f.read()

    def parse(self, inventory, loader, path, cache=True):
        super(InventoryModule, self).parse(inventory, loader, path)

        data = self.loader.load_from_file(path)
        resources = [
            resource
            for resource in data['resources']
            if resource['type'] == 'aws_instance'
        ]
        for resource in resources:
            self.inventory.add_group(
                resource["name"]
            )
            for instance in resource["instances"]:
                self.inventory.add_host(
                    instance['attributes']['public_ip'],
                    group=resource["name"]
                )
