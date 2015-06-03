haproxy-rpmbuilde

This script will download the HAproxy version you request from the HAproxy web site and will compile and build an RPM for you.
This script uses mock to build a CentOS 6 and a Centos 7 RPM for HAproxy. The host OS can be either CentOS 6 or 7.

To build for different CentOS releases this script uses "mock" that pulls the needed depends for each release and builds under chroot.

Usage:
./haproxy-rpmbuild <version> <release>
example:
./haproxy-rpmbuilder 1.5 12

Run this script as an unprivileged user since "mock" will not run as root.

created RPMS can be moved to local yum repo for deployment
sample yum repo file:

[local-repo]
baseurl=http://<IP ADDRESS>/$releasever/
enabled=0

