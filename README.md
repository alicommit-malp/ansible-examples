# DevOps, Vagrant with Ansible 

Do you want to automate the setting up of your production/test servers? so keep reading.

All resources are in Github at [alicommit-malp/ansible-examples](https://github.com/alicommit-malp/ansible-examples)

## Usage 
you need to install Vagrant ver >= 1.7.0 on your system from [here](https://www.vagrantup.com/downloads.html) 
```
git clone https://github.com/alicommit-malp/ansible-examples
cd ansible-examples/vm-docker-mariadb
sudo vagrant up --provision

//test your connection to the mariaDb from localhost
telnet 192.168.3.141 33306
```

## Use case 

- creating a virtual machine, any distribution or version
  -  in our case CentOs7
- installing the docker daemon and docker client 
- running your desire docker image as a container
  - in our case MariaDb version 10.2.14
  
we will use [Vagrant](https://www.vagrantup.com) to create our virtual machine , you can install it from [here](https://www.vagrantup.com/downloads.html) for your desired operation system.


then we will ask the Vagrant to make a VM for us using the centOs7 image and  map the localhost port 33306 to the VM's port of 3306, futhermore to assign 192.168.3.141 as the ip address of the VM 

```
config.vm.box = "generic/centos7"
config.vm.network :private_network, ip: "192.168.3.141"
config.vm.network "forwarded_port", guest: 3306, host: 33306
```

Vagrant has a smooth integration with [Ansible](https://www.ansible.com), therefore we can directly use Ansible to provision the freshly created CentOs7 VM as we demand, by passing the name of the playbook file path to it.

```
ansible.playbook = "mariaDb-docker-playbook.yml"
```

therefore we will end up with a Vagrantfile like this 
```
Vagrant.require_version ">= 1.7.0"

Vagrant.configure(2) do |config|

  config.vm.hostname = "maria_host"
  config.vm.box = "generic/centos7"

  config.vm.network :private_network, ip: "192.168.3.141"
  config.vm.network "forwarded_port", guest: 3306, host: 33306

  config.ssh.insert_key = false

  config.vm.provision "ansible" do |ansible|
    ansible.verbose = "v"
    ansible.raw_arguments  = "--ask-vault-pass"
    ansible.playbook = "mariaDb-docker-playbook.yml"
  end
end

```
and we will run it like this 

```
sudo vagrant up --provision
```
be aware that the --provision parameter will apply any changes to the VM if there is therefore after one time running the mentioned command it will create the VM and provision it with Ansible playbook and if you make changes afterwards to the playbook file and run the same command Vagrant will apply the changes.

for the sake of our example we are using a playbook file like this 

```yml
---
- name: provision_mariadb_on_docker_in_vm
  hosts: all
  vars_files:
    - vars.yml
  become: true

  tasks:

    - name: Installing docker related dependencies
      yum:   
        name: "{{ item }}"
        state: latest
      loop:
        - yum-utils
        - device-mapper-persistent-data
        - lvm2
        - python-pip

    - name: Configuring docker-ce repo
      get_url:
        url: https://download.docker.com/linux/centos/docker-ce.repo
        dest: /etc/yum.repos.d/docker-ce.repo
        mode: 0644

    - name: Installing docker
      yum:   
        name: "{{ item }}"
        state: latest
      loop:
        - docker-ce
        - docker-ce-cli 
        - containerd.io
        
    - name: Starting and Enabling Docker service
      service:
        name: docker
        state: started
        enabled: yes
    
    - name: Install docker python package 
      pip:
        name: docker 

    - name: Setting up the mariaDB container 
      docker_container:
        image: mariadb:10.2.14
        name: mariadb
        state: started
        restart: yes
        ports:
        - "33306:3306"
        env:
          MYSQL_ROOT_PASSWORD: "{{mariadb_root_password}}"
          MYSQL_PASSWORD: "{{mariadb_password}}"
          MYSQL_USER: "{{mariadb_username}}"

```

as it can be seen above, the Ansible file is very straight forward, the only point which i need to make here is to explain a bit about the vars.yml file because if you look inside of it you will see something like this

```
$ANSIBLE_VAULT;1.1;AES256
34383662366637303734663432376630306439343838313564313431343035323862633166363366
3336313535633434326439323966613562313536316138350a316638653233383862383235323965
61666434323332613461656365313331383638666365323731363564646336303464653465636437
3232323365356238640a626464326238643466613366393462346137336365633266343033306139
31373639386636643536646634333939303164313931366365376539643836366631303134303266
64306464616466373863376130646135346332303665653730346231663661363136306134376230
30613166646639303739653838393264656161313235396263613962323535343733356363666165
63666337653161323861356536623461666239336634346338363433646237306535383762346261
39613231646538613666613231333563633638643661643438633234666633326533

```

yes you have guessed correctly, it has been encrypted, and this is another fantastic feature of the Ansible, despite of the fact that I have shared the repository with you but still you can not figure out what is the value of the MYSQL_PASSWORD for instance 

```
MYSQL_ROOT_PASSWORD: "{{mariadb_root_password}}"
MYSQL_PASSWORD: "{{mariadb_password}}"
MYSQL_USER: "{{mariadb_username}}"
```

but the ansible can figure the values out in runtime.

## Ansible Vault
with [ansible valut](https://docs.ansible.com/ansible/latest/user_guide/vault.html) you can encrypt the variable files with password so when you are provisioning the server you need to provide that password or you can use a password file if you wish to automate this part as well.

you can test the connection to the MariaDb living inside the container which is living inside the VM like this

```
❯ telnet 192.168.3.141 33306
Trying 192.168.3.141...
Connected to 192.168.3.141.
Escape character is '^]'.
n
5.5.5-10.2.14-MariaDB-10.2.14+maria~jessi
```

All resources are in Github at [alicommit-malp/ansible-examples](https://github.com/alicommit-malp/ansible-examples)

Happy coding :)