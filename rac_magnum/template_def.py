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
import os

import magnum.conf
from rac_magnum.drivers.heat import k8s_mode_template_def as kftd
from rac_magnum.drivers.heat import swarm_mode_template_def as sftd


class RACAtomicSwarmTemplateDefinition(sftd.SwarmModeTemplateDefinition):
    """Docker swarm template for a Fedora Atomic VM on RAC."""

    @property
    def driver_module_path(self):
        return __name__[:__name__.rindex('.')]

    @property
    def template_path(self):
        return os.path.join(os.path.dirname(os.path.realpath(__file__)),
                            'templates/swarm/swarmcluster.yaml')

    def get_params(self, context, cluster_template, cluster, **kwargs):
        ep = kwargs.pop('extra_params', {})

        ep['number_of_secondary_masters'] = cluster.master_count - 1

        return super(RACAtomicSwarmTemplateDefinition,
                     self).get_params(context, cluster_template, cluster,
                                      extra_params=ep,
                                      **kwargs)


class RACUbuntuSwarmTemplateDefinition(sftd.SwarmModeTemplateDefinition):
    """Docker swarm template for Ubuntu on RAC."""

    @property
    def driver_module_path(self):
        return __name__[:__name__.rindex('.')]

    @property
    def template_path(self):
        return os.path.join(os.path.dirname(os.path.realpath(__file__)),
                            'templates/swarm-ubuntu/swarmcluster.yaml')

    def get_params(self, context, cluster_template, cluster, **kwargs):
        ep = kwargs.pop('extra_params', {})

        ep['number_of_secondary_masters'] = cluster.master_count - 1

        return super(RACUbuntuSwarmTemplateDefinition,
                     self).get_params(context, cluster_template, cluster,
                                      extra_params=ep,
                                      **kwargs)



CONF = magnum.conf.CONF

class RACAtomicK8sTemplateDefinition(kftd.K8sModeTemplateDefinition):
    """Kubernetes template for a Fedora Atomic VM on RAC."""

    @property
    def driver_module_path(self):
        return __name__[:__name__.rindex('.')]

    @property
    def template_path(self):
        return os.path.join(os.path.dirname(os.path.realpath(__file__)),
                            'templates/k8s/kubecluster.yaml')

class RACUbuntuK8sTemplateDefinition(kftd.K8sModeTemplateDefinition):
    """Kubernetes template for Ubuntu VM on RAC."""

    @property
    def driver_module_path(self):
        return __name__[:__name__.rindex('.')]

    @property
    def template_path(self):
        return os.path.join(os.path.dirname(os.path.realpath(__file__)),
                            'templates/k8s-ubuntu/kubecluster.yaml')
