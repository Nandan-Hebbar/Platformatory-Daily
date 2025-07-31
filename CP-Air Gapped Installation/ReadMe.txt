/home/nandan/air-gapped-installation/CP-Air Gapped Installation/ReadMe.txt
-- This explains the simulation of air gapped installation of the Confluent Platform with CP ansible on your local machine using the multipass VM


    Create 2 VMs 
    
    1. ControlNode
    multipass launch --name ControlNode --cpus 4 --mem 4G --disk 25G 20.04
    
    2. HostNode
    multipass launch --name HostNode --cpus 4 --mem 8G --disk 75G 20.04

    3. On HostNode disableinternet connectivity by
    sudo ip route del default
    sudo sed -i '/^nameserver/d' /etc/resolv.conf
    
    4. check python version on both nodes (refer the CP documentation for the versioning)
    python3 --version 
    
    Upgrade the python version to 3.12

        sudo apt update
        sudo apt install python3.12
        python3 --version
    
    5. Install ansible on ControlNode
        pip install ansible==9.4.0
    
    
    6. download CP package from ansible galaxy using on the ControlNode
    
        pip install --upgrade packaging
        python3 -m pip show packaging
        ansible-galaxy collection install confluent.platform

    
    
    7. download the cryptographic package from the ControlNode and move it to the CP-Host VM
        pip download cryptography
    
        It will download 3 files, now move it to the CP-Host using the below command 
        multipass transfer /home/nandan/air-gapped-installation/cryptography-44.0.2-cp37-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl CP-Host:/home/ubuntu/


 
    8. Install them on the 
        
        sudo apt update
        sudo apt install python3.12-venv
        python3 -m venv ~/venv-crypto
        source ~/venv-crypto/bin/activate
        pip install /home/ubuntu/cryptography-44.0.2-cp37-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl
        pip freeze | grep "cryptography"


OR

        pip install /home/ubuntu/cryptography-44.0.2-*.whl


    9. Create ssh keys on your localhost
        ssh-keygen -t rsa -b 4096
        
        --Move ssh keys 
        --Move the private key to the ControlNode
            multipass transfer ~/cp-ssh ControlNode:/home/ubuntu/.ssh

        --Move the public key to the HostNode
            multipass transfer ~/cp-ssh.pub HostNode:/home/ubuntu/.ssh
        
        --On host run
            cat ~/.ssh/cp-ssh.pub >> ~/.ssh/authorized_keys
        
            chmod 600 ~/.ssh/authorized_keys
        
            chmod 700 ~/.ssh
        
            chown ubuntu:ubuntu ~/.ssh ~/.ssh/authorized_keys



    10. From ControlNode check the ssh connectivity
        
            ssh -i ~/.ssh/cp-ssh ubuntu@<Host-IP>
        
            ssh ubuntu@<Host-IP>


    11. On the distributed node download the CP installation package
        
            curl -O http://packages.confluent.io/archive/7.9/confluent-7.9.0.tar.gz

    12. On the control node, extract the contents of the Confluent Platform archive:
        
            tar xzf confluent-7.9.0.tar.gz


    13. Run readlink -f $(which java) to see the java path and version


    14. On the HostNode 
        sudo mkdir -p /opt/confluent
        sudo chown ubuntu:ubuntu /opt/confluent
        sudo chmod -R 755 /opt/confluent
  
  
  
    15. Validate hosts before installing Confluent Platform:

        check run the playbook
            export ANSIBLE_HASH_BEHAVIOUR=merge
            ansible-playbook -i host.yaml confluent.platform.all.yml --check -vvv



Ansible Playbook:

all:
  vars:
    installation_method: archive
    confluent_archive_file_source: /home/ubuntu/cp-packages/confluent-7.9.0.tar.gz
    confluent_archive_file_remote: false
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ~/.ssh/cp-ssh
    ansible_become: true
    ansible_become_method: sudo
    package_installed_dependencies: true  
    jolokia_enabled: false
    jmxexporter_enabled: false
    install_java: false
    custom_java_path: /usr/lib/jvm/java-17-openjdk-amd64
    confluent_server_enabled: true

kafka_controller:
  hosts:
    HostNode:
kafka_broker:
  hosts:
    HostNode:
schema_registry:
  hosts:
    HostNode:
kafka_rest:
  hosts:
    HostNode:
ksql:
  hosts:
    HostNode:
kafka_connect:
  hosts:
    HostNode:
control_center:
  hosts:
    HostNode:


--Post Installation checks

See the installed services installed 
    cd /etc/systemd/system/


Path of Bin directory to run the commands from
    /opt/confluent/confluent-7.9.0/bin





-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

To install CP with internet


Follow same steps as above (Dont download the tar file, running the ansible playbook itself will do it directl from the internet as it will have internet connectivity)


sudo apt install python3-cryptography

all:
  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ~/.ssh/ansible1
    ansible_become: true
    ansible_become_method: sudo
    package_installed_dependencies: true  
    jolokia_enabled: false
    jmxexporter_enabled: false
    install_java: false
    custom_java_path: /usr/lib/jvm/java-11-openjdk-amd64
    confluent_server_enabled: true

kafka_controller:
  hosts:
    HostNode:
kafka_broker:
  hosts:
    HostNode:
schema_registry:
  hosts:
    HostNode:
kafka_rest:
  hosts:
    HostNode:
ksql:
  hosts:
    HostNode:
kafka_connect:
  hosts:
    HostNode:
control_center:
  hosts:
    HostNode:



-------------------------------------------------------------------------------------------------------------------------------------------------
-- Multipass commands

-- Launch a new VM
multipass launch --name VMname

--To get into the shell of a VM
multipass shell VMname

--To get info about the VM
multipass info VMname


--To list all the VMs
multipass list

