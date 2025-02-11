#!/bin/bash

# Function to check if the OS supports dnf
check_os() {
    if grep -qi 'ID=' /etc/os-release | grep -Eq 'fedora|centos|rhel|rocky|almalinux'; then
        echo "✅ Supported OS detected. Proceeding with installation..."
    else
        echo "❌ Unsupported OS. This script only works on RHEL-based systems with dnf."
        exit 1
    fi
}

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
    sudo unzip -o /opt/terraform_1.5.6_linux_amd64.zip -d /opt/terraform_1.5.6
    sudo ln -sf /opt/terraform_1.5.6/terraform /usr/bin/terraform
}

install_ansible() {
    sudo dnf install -y epel-release
    sudo dnf install -y ansible
}

install_groovy() {
    wget https://groovy.jfrog.io/ui/native/dist-release-local/groovy-zips/apache-groovy-sdk-4.0.25.zip -P /opt
    sudo unzip -o /opt/apache-groovy-sdk-4.0.25.zip -d /opt/groovy
    sudo ln -sf /opt/groovy/apache-groovy-sdk-4.0.25/bin/groovy /usr/bin/groovy
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
    if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
        ADMIN_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
        echo "Jenkins Admin Password: $ADMIN_PASSWORD"
    else
        echo "Jenkins Admin Password file not found."
    fi
}

install_jenkins_plugins() {
    JENKINS_URL="http://localhost:8080"
    PLUGIN_LIST="git workflow-aggregator pipeline-stage-view terraform ansible groovy java docker"
    
    sleep 30  # Allow Jenkins time to start

    for plugin in $PLUGIN_LIST; do
        echo "Installing plugin: $plugin"
        curl -s -u "admin:$ADMIN_PASSWORD" -X POST "$JENKINS_URL/pluginManager/installNecessaryPlugins" --data "<jenkins><install plugin=\"$plugin@latest\"/></jenkins>"
    done

    echo "Jenkins plugin installation process completed."
}

main() {
    check_os  # Ensure OS compatibility before proceeding
    install_java
    install_python
    install_terraform
    install_ansible
    install_groovy
    install_docker
    install_jenkins
    get_admin_password
    install_jenkins_plugins
}

main
