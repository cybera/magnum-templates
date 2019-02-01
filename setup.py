#!/usr/bin/env python

import setuptools

setuptools.setup(
    name="rac_magnum",
    version="1.0",
    packages=['rac_magnum'],
    package_data={
        'rac_magnum': [
            'templates/*',
            'templates/swarm/*',
            'templates/swarm/fragments/*',
            'templates/fragments/*',
        ]
    },
    author="Cybera Rapid Access Cloud Admin",
    author_email="rac-admin@cybera.ca",
    description="Magnum templates for/from Cybera Rapid Access Cloud",
    license="Apache",
    keywords="magnum cybera rac",
    entry_points={
        'magnum.drivers': [
            'rac_swarm = rac_magnum.driver:RACAtomicSwarmDriver',
            'rac_k8s = rac_magnum.driver:RACAtomicK8sDriver',
            'rac_swarm_ubuntu = rac_magnum.driver:RACUbuntuSwarmDriver',
            'rac_k8s_ubuntu = rac_magnum.driver:RACUbuntuK8sDriver',
        ]
    }
)
