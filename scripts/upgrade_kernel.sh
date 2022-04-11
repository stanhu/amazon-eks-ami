#!/usr/bin/env bash

set -o pipefail
set -o nounset
set -o errexit

if [[ -z "$KERNEL_VERSION" ]]; then
    # Save for resetting
    OLDIFS=$IFS
    # Makes 5.4 kernel the default on 1.19 and higher
    IFS='.'
    # Convert kubernetes version in an array to compare versions
    read -ra ADDR <<< "$KUBERNETES_VERSION"
    # Reset
    IFS=$OLDIFS

    if (( ADDR[0] == 1 && ADDR[1] < 19 )); then
        KERNEL_VERSION=4.14
    else
        KERNEL_VERSION=5.4
    fi

    echo "kernel_version is unset. Setting to $KERNEL_VERSION based on kubernetes_version $KUBERNETES_VERSION"
fi

if [[ $KERNEL_VERSION == "4.14" ]]; then
    sudo yum update -y kernel
elif [[ $KERNEL_VERSION == "5.4" ]]; then
    sudo amazon-linux-extras install -y kernel-5.4
elif [[ $KERNEL_VERSION == "5.10" ]]; then
    sudo amazon-linux-extras install -y kernel-5.10
else
    echo "$KERNEL_VERSION is not a valid kernel version"
    exit 1
fi

if [[ "$ENABLE_FIPS_MODE" == "true" ]]; then
    # install and enable fips modules
    sudo yum install -y dracut-fips openssl
    sudo dracut -f

    # enable fips in the boot command
    sudo sed -i 's/^\(GRUB_CMDLINE_LINUX_DEFAULT=.*\)"$/\1 fips=1"/' /etc/default/grub

    # rebuild grub
    sudo grub2-mkconfig -o /etc/grub2.cfg
fi

sudo reboot
