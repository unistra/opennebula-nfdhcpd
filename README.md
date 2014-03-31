nfdhcpd
=======

Overview
--------

This is nfdhpcd, a userspace server written in python and based on
[NFQUEUE](https://www.wzdftpd.net/redmine/projects/nfqueue-bindings/wiki/). The
administrator can enable processing of DHCP, NS, RS, DHCPv6 requests on
individual TAP interfaces by injecting nfdhcpd in the processing pipeline for
IP packets dynamically (by mangling the corresponding packet types and redirect
them to the appropriate nfqueue).

The daemon runs on the host and is controlled by manipulating files
under its state directory. Creation of a new file under this directory
("binding file") instructs the daemon to reply on the requests arriving
on the specified TAP interface.

nfdhpcd is meant to work with [Ganeti](http://code.google.com/p/ganeti) and
[snf-network](https://github.com/grnet/snf-network). Instances inside the
cluster will obtain their configuration dynamically in a completely transparent
way without being aware of nfdhpcd's existence.


Project Page
------------

Please see the [official Synnefo site](http://www.synnefo.org) and the
[latest snf-network docs](http://www.synnefo.org/docs/nfdhcpd/latest/index.html)
for more information.


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
