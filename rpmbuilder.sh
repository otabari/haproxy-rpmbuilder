#!/bin/sh
haproxyver=$1
haproxyrel=$2
rpmrel="1"

RED='\033[0;31m'
DEFCOLOR='\033[0m'
GREEN='\e[0;32m'

packages="gcc wget pcre pcre-devel socat openssl-devel openssl rpm-build"
missing_pkgs=""

display_usage() { 
	    echo -e "\nThis script builds an RPM package for HAproxy"
	    echo -e "This script takes two arguments"
    	echo -e "Usage:\n$0 <HAproxy Version> <HAproxy Release> \n"

	} 

if [  $# -le 1 ] 
	then 
		display_usage
		exit 1
fi 

echo "checking for dependencies:"

# populating text file with installed packages to check against
rm -rf /tmp/all-packages.txt
rpm -qa > /tmp/all-packages.txt

# check logic for needed packages
for pkg in $packages
	do
		if grep -q $pkg /tmp/all-packages.txt 
			then echo -e "package $pkg is installed.... ${GREEN} OK ${DEFCOLOR} "
			sleep 0.5
		else
			echo -e "package $pkg is ${RED}NOT${DEFCOLOR} installed.... ${RED} FAIL ${DEFCOLOR}"
			missing_pkgs="$missing_pkgs $pkg"
			sleep 0.5
		fi
	done

is_missing=`echo $missing_pkgs | wc -w`

if [ $is_missing -gt 0 ]
    then echo "missing packages found, script aborting" && exit 1
fi

rm -rf ~/rpmbuild/{BUILD,BUILDROOT,SRPMS}/haproxy* || true
mkdir -p ~/rpmbuild/{BUILD,BUILDROOT,SOURCES,RPMS,SRPMS}

echo "Downloading sources..."
if [ ! -f ~/rpmbuild/SOURCES/haproxy-$haproxyver.$haproxyrel.tar.gz ];
then
    wget "http://www.haproxy.org/download/$haproxyver/src/haproxy-$haproxyver.$haproxyrel.tar.gz" -O ~/rpmbuild/SOURCES/haproxy-$haproxyver.$haproxyrel.tar.gz
fi

cd ~/rpmbuild/SOURCES/
tar zxf ~/rpmbuild/SOURCES/haproxy-$haproxyver.$haproxyrel.tar.gz
cd ~

cp ~/rpmbuild/SOURCES/haproxy-$haproxyver.$haproxyrel/examples/haproxy.spec ~/haproxy.spec

sed -i 's/Release: .*/Release:  1/' ~/haproxy.spec
sed -i '/Requires/{s/.*/&\nRequires: socat/;:a;n;ba}' ~/haproxy.spec
sed -i 's/pcre-devel/pcre-devel make gcc openssl-devel/' ~/haproxy.spec
sed -i 's/USE_PCRE=1/USE_PCRE=1 USE_OPENSSL=1 USE_ZLIB=1/' ~/haproxy.spec
sed -i 's/TARGET=linux26/TARGET=linux2628/' ~/haproxy.spec

echo "Building initial source rpm..."
sleep 1
rpmbuild -bs ~/haproxy.spec

echo "Using mock to build rpm..."
sleep 1
mock -r epel-6-x86_64 --resultdir=`pwd`/rpmbuild/RPMS/centos6/ ~/rpmbuild/SRPMS/haproxy-$haproxyver.$haproxyrel-$rpmrel.src.rpm
mock -r epel-7-x86_64 --resultdir=`pwd`/rpmbuild/RPMS/centos7/ ~/rpmbuild/SRPMS/haproxy-$haproxyver.$haproxyrel-$rpmrel.src.rpm
#mock  --resultdir=`pwd`/rpmbuild/RPMS/ ~/rpmbuild/SRPMS/haproxy-$haproxyver.$haproxyrel-$rpmrel.src.rpm

# create and update the repo with created files
# createrepo /var/www/html/ib-repo/6/
# createrepo /var/www/html/ib-repo/7/
## move packages to respected folders
## update the repos
# createrepo --update -v /var/www/html/ib-repo/6/
# createrepo --update -v /var/www/html/ib-repo/7/

echo "Cleaning up..."
rm -rf ~/haproxy.spec
rm -rf /tmp/all-packages.txt
