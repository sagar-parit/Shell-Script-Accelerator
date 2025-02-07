#!/bin/bash

install_java() {
    sudo dnf install -y java-17-openjdk
    sudo ln -sf /usr/lib/jvm/java-17-openjdk/bin/java /usr/bin/java
}

install_python() {
    sudo dnf install -y python3
    sudo ln -sf /usr/bin/python3 /usr/bin/python
}

install_terraform() {
    wget https://releases.hashicorp.com/terraform/1.5.6/terraform_1.5.6_linux_amd64.zip -P /opt
    sudo unzip -o /opt/terraform_1.5.6_linux_amd64.zip -d /opt
    sudo ln -sf /opt/terraform /usr/bin/terraform
}

install_ansible() {
    sudo dnf install -y epel-release 
    sudo dnf install -y ansible
    sudo ln -sf /usr/bin/ansible /usr/bin/ansible
}

install_groovy() {
    wget https://groovy.jfrog.io/ui/native/dist-release-local/groovy-zips/apache-groovy-sdk-4.0.25.zip -P /opt
    sudo unzip -o /opt/apache-groovy-sdk-4.0.25.zip -d /opt
    sudo ln -sf /opt/apache-groovy-sdk-4.0.25/bin/groovy /usr/bin/groovy
}

install_docker() {
    sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $(whoami)
}

install_jenkins() {
    sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    sudo yum install -y jenkins
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
    echo "Jenkins installation complete and service started."
}

get_admin_password() {
    ADMIN_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
}

install_jenkins_plugins() {
    JENKINS_URL="http://localhost:8080"
    PLUGIN_LIST="git,workflow-aggregator,pipeline-stage-view,terraform,ansible,groovy,java,docker"
    sleep 30
    
    for plugin in $(echo $PLUGIN_LIST | tr "," "\n")
    do
        echo "Installing plugin: $plugin"
        response=$(curl -s -u admin:$ADMIN_PASSWORD -X POST -d "plugin=$plugin" "$JENKINS_URL/pluginManager/installNecessaryPlugins")
        if echo "$response" | grep -q "plugin installed"; then
            echo "Plugin $plugin installed successfully."
        else
            echo "Failed to install plugin: $plugin"
        fi
    done
}