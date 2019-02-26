# Copyright 2016 Rackspace Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

from magnum.drivers.swarm_fedora_atomic_v2 import driver as swarm_driver
from magnum.drivers.k8s_fedora_atomic_v1 import driver as k8s_driver
from magnum.drivers.swarm_fedora_atomic_v2 import monitor
from template_def import RACAtomicSwarmTemplateDefinition, RACAtomicK8sTemplateDefinition, RACUbuntuSwarmTemplateDefinition, RACUbuntuK8sTemplateDefinition


class RACAtomicSwarmDriver(swarm_driver.Driver):

    @property
    def provides(self):
        return [
            {'server_type': 'vm',
             'os': 'rac-fedora-atomic',
             'coe': 'swarm'},
        ]

    def get_template_definition(self):
        return RACAtomicSwarmTemplateDefinition()

    def get_monitor(self, context, cluster):
        return monitor.SwarmMonitor(context, cluster)

class RACUbuntuSwarmDriver(swarm_driver.Driver):

    @property
    def provides(self):
        return [
            {'server_type': 'vm',
             'os': 'ubuntu-1804',
             'coe': 'swarm'},
        ]

    def get_template_definition(self):
        return RACUbuntuSwarmTemplateDefinition()

    def get_monitor(self, context, cluster):
        return monitor.SwarmMonitor(context, cluster)

class RACAtomicK8sDriver(k8s_driver.Driver):

    @property
    def provides(self):
        return [
            {'server_type': 'vm',
             'os': 'rac-fedora-atomic',
             'coe': 'kubernetes'},
        ]

    def get_template_definition(self):
        return RACAtomicK8sTemplateDefinition()

    def get_monitor(self, context, cluster):
        return k8s_monitor.K8sMonitor(context, cluster)

    def get_scale_manager(self, context, osclient, cluster):
        # FIXME: Until the kubernetes client is fixed, remove
        # the scale_manager.
        # https://bugs.launchpad.net/magnum/+bug/1746510
        return None

class RACUbuntuK8sDriver(k8s_driver.Driver):

    @property
    def provides(self):
        return [
            {'server_type': 'vm',
             'os': 'ubuntu-1804',
             'coe': 'kubernetes'},
        ]

    def get_template_definition(self):
        return RACUbuntuK8sTemplateDefinition()

    def get_monitor(self, context, cluster):
        return k8s_monitor.K8sMonitor(context, cluster)

    def get_scale_manager(self, context, osclient, cluster):
        # FIXME: Until the kubernetes client is fixed, remove
        # the scale_manager.
        # https://bugs.launchpad.net/magnum/+bug/1746510
        return None
