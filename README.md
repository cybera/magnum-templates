# Cybera templates for OpenStack Magnum

This repository contains OpenStack Magnum templates used in our Rapid Access Cloud.

## Templates

### Docker Swarm

This template has been modified from the standard Docker Swarm template to do the following:

1. Not require floating IPs (https://review.openstack.org/#/c/571200)
3. When configured to use floating IPs, only the master will be assigned an IP.
2. IPv6 support

## Installation

Something like:

```shell
$ cd /usr/share
$ git clone https://github.com/cybera/magnum-templates
$ cd magnum-templates
$ python setup.py develop
```

Then edit `/etc/magnum/magnum.conf` and set:

```
[bay]
enabled_definitions = rac_swarm_standard
```
