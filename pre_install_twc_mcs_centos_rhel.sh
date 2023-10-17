#!/bin/bash
NM_VERSION='2022x Refresh 2'

if [ "$EUID" -ne 0 ];then
	echo
	echo "Please run as root or sudo."
	exit 1
fi
## Obtain OS information using either lsb_release or /etc/os-release
if ( type lsb_release &> /dev/null ); then
	OS=$(lsb_release -is)
	if [[ $OS =~ "RedHat" ]]; then OS="rhel"; fi
	if [[ $OS =~ "CentOS" ]]; then OS="centos"; fi
	OS_V=$(lsb_release -rs | cut -f1 -d.)
elif [ -f /etc/os-release ]; then
	source /etc/os-release
	OS=$ID
	OS_V=$(echo $VERSION_ID | cut -f1 -d.)
else
	echo "Installation Exited: Unable to obtain OS information."
	exit 1
fi
## Check for compatibility
unset PKG_EXE
if [[ $OS  =~ "rhel" ]] || [[ $OS  =~ "centos" ]]; then
	if [[ $OS_V  == "7" ]]; then
		PKG_EXE=yum
	elif [[ $OS_V  == "8" ]]; then
		PKG_EXE=dnf
	fi
fi
if [[ -z "${PKG_EXE}" ]]; then
	echo "Installation Exited: $OS $OS_V is not supported."
	exit 1
fi

## Determine OS and set install command for EPEL package
if rpm -q epel-release > /dev/null; then
	EPEL_RELEASE=$(rpm -q epel-release)
	INSTALL_CMDS="echo Package $EPEL_RELEASE already installed, skipping."
else
	if [[ $OS  =~ "rhel" ]]; then
		echo "Installing epel-release for RHEL"
		INSTALL_CMDS="rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-$OS_V.noarch.rpm"
	elif [[ $OS  =~ "centos" ]]; then
		echo "Installing epel-release for CentOS 7"
		INSTALL_CMDS="yum -y -q install epel-release"
	fi
fi
## Install EPEL Package
eval $INSTALL_CMDS
/usr/bin/crb
$PKG_EXE -y update

echo "======================================================"
echo "Installing $PRODUCT Dependencies"
echo "======================================================"
echo "Installing unzip"
$PKG_EXE install -y unzip
echo "Installing fonts"
$PKG_EXE install -y dejavu-serif-fonts
echo "Installing Tomcat Native Libraries"
$PKG_EXE install -y tomcat-native
echo "Installing git"
$PKG_EXE install -y git
if [[ "$PKG_EXE" == "dnf" ]]; then
  echo "Installing az cli"
  rpm --import https://packages.microsoft.com/keys/microsoft.asc
  $PKG_EXE install -y https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm
  $PKG_EXE install -y azure-cli
fi
