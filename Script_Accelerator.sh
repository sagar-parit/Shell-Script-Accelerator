#!/bin/bash

install_java() {
    sudo dnf install -y java-17-openjdk
    sudo ln -sf /usr/lib/jvm/java-17-openjdk-17.0.14.0.7-2.el9.x86_64/bin/java /usr/bin/java
    java -version
}

install_python() {
    sudo dnf install -y python3 python3-pip
    sudo ln -sf /usr/bin/python3 /usr/bin/python
}

install_terraform() {
    wget https://releases.hashicorp.com/terraform/1.5.6/terraform_1.5.6_linux_amd64.zip -P /opt
    sudo unzip -o /opt/terraform_1.5.6_linux_amd64.zip -d /usr/local/bin
    sudo ln -sf /usr/local/bin/terraform /usr/bin/terraform
}

install_ansible() {
    sudo dnf install -y python3 python3-pip
    sudo pip3 install ansible
    sudo ln -sf /usr/local/bin/ansible /usr/bin/ansible
}

install_groovy() {
    wget https://groovy.jfrog.io/artifactory/dist-release-local/groovy-zips/apache-groovy-sdk-4.0.25.zip -P /opt
    sudo unzip -o /opt/apache-groovy-sdk-4.0.25.zip -d /opt
    sudo ln -sf /opt/apache-groovy-sdk-4.0.25/bin/groovy /usr/bin/groovy
}

install_docker() {
    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $(whoami)
}

install_jenkins() {
    sudo curl -o /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    sudo dnf install -y jenkins
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
}

get_admin_password() {
    echo "Waiting for Jenkins to initialize..."
    while [ ! -f /var/lib/jenkins/secrets/initialAdminPassword ]; do
        sleep 10
    done
    ADMIN_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
    echo "Jenkins Admin Password: $ADMIN_PASSWORD"
}

install_jenkins_plugins() {
    JENKINS_URL="http://localhost:8080"
    ADMIN_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
    CRUMB=$(curl -s -u "admin:$ADMIN_PASSWORD" "$JENKINS_URL/crumbIssuer/api/json" | jq -r .crumb)

    for plugin in git workflow-aggregator pipeline-stage-view terraform ansible groovy java docker; do
        echo "Installing plugin: $plugin"
        curl -s -u "admin:$ADMIN_PASSWORD" -X POST "$JENKINS_URL/pluginManager/installNecessaryPlugins" \
            -H "Jenkins-Crumb:$CRUMB" --data-urlencode "plugin.$plugin.default"
    done
}

install_java
install_python
install_terraform
install_ansible
install_groovy
install_docker
install_jenkins
get_admin_password
install_jenkins_plugins
