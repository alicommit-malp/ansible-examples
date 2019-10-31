#!/bin/sh 


install_vagrant() {
    echo "Installing Vagrant on localhost ..."
    ansible localhost -b -m apt -a "name=vagrant state=present"
    echo "Installing Vagrant on localhost ... done"
}

echo "Provisioning ..."
    install_vagrant
    vagrant up --provision
echo "Provisioning ... done"