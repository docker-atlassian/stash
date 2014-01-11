#!/bin/bash
# Copyright 2014, Tom Eklöf, Mogul AB
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


# Install Atlassian Stash
## Install Java
# Add Oracle Java PPA
apt-get -y update
apt-get -y install python-software-properties
add-apt-repository -y ppa:webupd8team/java
apt-get -y update
# Auto-accept the Oracle License
echo "debconf shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections
echo "debconf shared/accepted-oracle-license-v1-1 seen true" | debconf-set-selections
apt-get -y install libpq-dev oracle-java7-installer

# Work around the omnibus pg gem issue as suggested by Joshua Timberman in COOK-1406
apt-get install -y build-essential
apt-get build-dep -y postgresql
cd /opt/chef/embedded/
#curl -o postgresql-9.2.1.tar.gz http://ftp.postgresql.org/pub/source/v9.2.1/postgresql-9.2.1.tar.gz
tar xzf /opt/chef/embedded/postgresql-9.2.1.tar.gz -C /opt/chef/embedded/
cd postgresql-9.2.1
export MAJOR_VER=9.2
./configure --prefix=/opt/chef/embedded --mandir=/opt/chef/embedded/share/postgresql/${MAJOR_VER}/man --docdir=/opt/chef/embedded/share/doc/postgresql-doc-${MAJOR_VER} --sysconfdir=/etc/postgresql-common --datarootdir=/opt/chef/embedded/share/ --datadir=/opt/chef/embedded/share/postgresql/${MAJOR_VER} --bindir=/opt/chef/embedded/lib/postgresql/${MAJOR_VER}/bin --libdir=/opt/chef/embedded/lib/ --libexecdir=/opt/chef/embedded/lib/postgresql/ --includedir=/opt/chef/embedded/include/postgresql/ --enable-integer-datetimes --enable-thread-safety --enable-debug --with-gnu-ld --with-pgport=5432 --with-openssl --with-libedit-preferred --with-includes=/opt/chef/embedded/include --with-libs=/opt/chef/embedded/lib
make
make install
/opt/chef/embedded/bin/gem install pg -- --with-pg-config=/opt/chef/embedded/lib/postgresql/9.2/bin/pg_config

# Here we change dp password for postgresql to dbpassword and create the database. See cookbook documentation for examples.
sed -i "s%md5sumhash%$(echo -n 'dbpassword' | openssl md5 | sed -e 's/.* /md5/')%g" /etc/chef/node.json
sysctl -w kernel.shmmax=714219520 ; /etc/init.d/postgresql start ; chef-solo ; /etc/init.d/postgresql stop	# Chef-solo makes all the changes

set -x

#egrep -i '(debian|ubuntu)' /etc/lsb-release > /dev/null && useradd --system --home $STASH_HOME --user-group $STASHUSR   # Debian way
#if [ -f /etc/redhat-release ]
#then
#	# Do RHEL stuff
#	adduser -d $STASH_HOME -g $STASHUSR -r $STASHUSR			# RHEL way
#fi
useradd --system --home $STASH_HOME --user-group $STASHUSR   # Debian way

## Now Install Atlassian Stash
mkdir -p /opt/atlassian/
tar xzf /opt/atlassian/atlassian-$AppName-$AppVer.tar.gz -C /opt/atlassian/ --owner=$STASHUSR
mkdir -p $STASH_HOME
chown -R $STASHUSR /opt/atlassian/atlassian-$AppName-$AppVer
chown -R $STASHUSR $STASH_HOME
mkdir -p /data/var/lib/

# I don't put this in the block above because it's a behaviour that might change with cookbook updates
# Move data so we can expose it to the host with the VOLUME Dockerfile instruction
# RHEL way
#if [ -d /var/lib/postgresql ]; then
#	mv /var/lib/postgresql /data/var/lib/
#	ln -s /data/var/lib/postgresql /var/lib/postgresql
#fi
# Debian way
if [ -d /var/lib/pgsql ]; then
	mv /var/lib/pgsql /data/var/lib/
	ln -s /data/var/lib/pgsql /var/lib/pgsql
fi

# Clean up
rm -f /opt/atlassian/atlassian-$AppName-$AppVer.tar.gz
rm -f /var/cache/oracle-jdk7-installer/jdk-7u45-linux-x64.tar.gz
rm -f /opt/chef/embedded/postgresql-9.2.1.tar.gz
