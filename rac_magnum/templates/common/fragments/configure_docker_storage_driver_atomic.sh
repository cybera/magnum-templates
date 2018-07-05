# This file contains docker storage drivers configuration for fedora
# atomic hosts, as supported by Magnum.

# * Remove any existing docker-storage configuration. In case of an
#   existing configuration, docker-storage-setup will fail.
# * Remove docker storage graph
clear_docker_storage () {
    # stop docker
    systemctl stop docker
    systemctl disable docker-storage-setup
    # clear storage graph
    rm -rf /var/lib/docker/*

    if [ -f /etc/sysconfig/docker-storage ]; then
        sed -i "/^DOCKER_STORAGE_OPTIONS=/ s/=.*/=/" /etc/sysconfig/docker-storage
    fi
}

# Configure generic docker storage driver.
configure_storage_driver_generic() {
    clear_docker_storage

    if [ -n "$DOCKER_VOLUME_SIZE" ] && [ "$DOCKER_VOLUME_SIZE" -gt 0 ]; then
        mkfs.xfs -f ${device_path}
        echo "${device_path} /var/lib/docker xfs defaults 0 0" >> /etc/fstab
        mount -a
    fi

    echo "DOCKER_STORAGE_OPTIONS=\"--storage-driver $1\"" > /etc/sysconfig/docker-storage
}

# Configure docker storage with devicemapper using direct LVM
configure_devicemapper () {
    clear_docker_storage

    echo "GROWROOT=True" > /etc/sysconfig/docker-storage-setup
    echo "STORAGE_DRIVER=devicemapper" >> /etc/sysconfig/docker-storage-setup

    if [ -n "$DOCKER_VOLUME_SIZE" ] && [ "$DOCKER_VOLUME_SIZE" -gt 0 ]; then

        pvcreate -f ${device_path}
        vgcreate docker ${device_path}

        echo "VG=docker" >> /etc/sysconfig/docker-storage-setup
    else
        echo "ROOT_SIZE=5GB" >> /etc/sysconfig/docker-storage-setup
        echo "DATA_SIZE=95%FREE" >> /etc/sysconfig/docker-storage-setup
    fi

    docker-storage-setup
}
