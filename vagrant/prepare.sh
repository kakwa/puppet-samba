#!/bin/sh
#
# Preparations required prior to "puppet apply".

usage() {
    echo
    echo "Usage: prepare.sh -n module_name -f osfamily -o os"
    echo
    echo "Options:"
    echo " -n   Name of the module that includes this script. Used to copy"
    echo "      the module code to the modulepath."
    echo " -f   Operating system family for this Vagrant VM. Valid values are"
    echo "      redhat and debian. This determines the logic to use when"
    echo "      installing Puppet on the nodes."
    echo " -o   Operating system version. For Debian derivatives use the"
    echo "      codename (e.g. stretch or xenial). For RedHat derivatives"
    echo "      use the osname-osversion scheme (e.g. el-7). For details"
    echo "      see Puppet yum/apt repository documentation"
    echo " -b   Base directory for dependency Puppet modules installed by"
    echo "      librarian-puppet."
    exit 1
}


# Parse the options

# We are run without parameters -> usage
if [ "$1" == "" ]; then
        usage
fi

while getopts "n:f:o:b:h" options; do
  case $options in
        n ) THIS_MODULE=$OPTARG;;
        f ) OSFAMILY=$OPTARG;;
        o ) OS=$OPTARG;;
        b ) BASEDIR=$OPTARG;;
        h ) usage;;
        \? ) usage;;
        * ) usage;;
  esac
done

CWD=`pwd`

install_puppet() {
    if [ $OSFAMILY = 'redhat' ]; then
        rpm -ivh https://yum.puppetlabs.com/puppet5/puppet5-release-$OS.noarch.rpm
        yum install -y puppet-agent yum-utils git
        yum-config-manager --save --setopt=puppetlabs-pc1.skip_if_unavailable=true
    elif [ $OSFAMILY = 'debian' ]; then
        wget https://apt.puppetlabs.com/puppet5-release-$OS.deb -O puppet5-release-$OS.deb
        dpkg -i puppet5-release-$OS.deb
        apt-get update
        apt-get -y install puppet-agent git
    else
        echo "ERROR: unsupported value ${OSFAMILY} for option -f!"
        usage
    fi
}

install_puppet

export PATH=$PATH:/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin

# Install librarian-puppet with Puppetlabs' gem and not a system gem
/opt/puppetlabs/puppet/bin/gem install librarian-puppet

# Install dependency modules with librarian-puppet
cd $BASEDIR
mkdir -p modules
rm -f $BASEDIR/metadata.json
ln -s /vagrant/metadata.json
librarian-puppet install

# Copy over this in-development module to modules
# directory
rm -f modules/${THIS_MODULE}
ln -s /vagrant modules/${THIS_MODULE}

cd $CWD
