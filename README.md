opennebula-nfdhcpd
==================

Overview
--------

opennebula-nfdhcpd is a fork of 
[snf-nfdhcpd](https://github.com/grnet/snf-nfdhcpd) that enable the integration
of nfdhcpd for [OpenNebula](https://github.com/grnet/snf-nfdhcpd).

This is opennebula-nfdhpcd, a userspace server written in python and based on
[NFQUEUE](https://www.wzdftpd.net/redmine/projects/nfqueue-bindings/wiki/). The
administrator can enable processing of DHCP requests on individual TAP 
interfaces by injecting opennebula-nfdhcpd in the processing pipeline for IP 
packets dynamically (by mangling the corresponding packet types and redirect them to the
appropriate nfqueue).

The daemon runs on the host and is controlled by manipulating files
under its state directory. Creation of a new file under this directory
("binding file") instructs the daemon to reply on the requests arriving
on the specified TAP interface.

openenbula-nfdhpcd is meant to work with [OpenNebula](http://opennebula.org).
Instances will obtain their network configuration dynamically in a completely transparent 
way without being aware of opennebula-nfdhpcd's existence.

Building
--------

1. Clone the repository :

`git clone https://github.com/unistra/opennebula-nfdhcpd`

2. Create the source package :

`dpkg-source -b opennebula-nfdhcpd`

3. Create the pbuilder environement :

`pbuilder --create --distribution xenial`

4. Build the package :

`pbuilder --build --distribution xenial opennebula-nfdhcpd_x.x.x.dsc`

5. Results are in `/var/cache/pbuilder/result/`

Installation
------------

1. Add in /etc/one/oned.conf :

```
INHERIT_VNET_ATTR       = "NFDHCPD"
INHERIT_VNET_ATTR       = "NETWORK_ADDRESS"
INHERIT_VNET_ATTR       = "NETWORK_MASK"
INHERIT_VNET_ATTR       = "GATEWAY"
INHERIT_VNET_ATTR       = "DNS"
```

2. Update VXLAN and 802.1Q scripts :
  * In post action : 
  ```
  nfdhcpd_driver = VNMMAD::NFDHCPDDriver.new(template64, xpath_filter, deploy_id)
  nfdhcpd_driver.activate
  ```

  * In clean action :
  ```
  nfdhcpd_driver = VNMMAD::NFDHCPDDriver.new(template64, xpath_filter, deploy_id)
  nfdhcpd_driver.deactivate
  ```

3. Copy the nfdhdcpd driver in the remotes scripts directory :

`cp remotes/vnm/nfdhcpd.rb /var/lib/one/remotes/vnm/nfdhcpd.rb`

4. Add `require 'nfdhcpd'` in /var/lib/one/remotes/vnm/vnmmad.rb 

5. Install opennebula-nfdhcpd package on your hypervisors

Copyright and license
=====================

Copyright (c) 2010, 2011, 2012, 2013, 2014 GRNET SA

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along
   with this program; if not, write to the Free Software Foundation, Inc.,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
