#!/bin/bash


check_os() {
    OS_ID=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')

    if [[ "$OS_ID" == "centos" || "$OS_ID" == "rhel" || "$OS_ID" == "rocky" ]]; then
        echo "[INFO] Supported RHEL-based OS detected ($OS_ID)"
    elif [[ "$OS_ID" == "ubuntu" ]]; then
        echo "[INFO] Supported Ubuntu OS detected ($OS_ID)"
    else
        echo "[ERROR] Unsupported OS detected ($OS_ID). Exiting..."
        exit 1
    fi
}

install_java() {
    sudo dnf install -y java-17-openjdk
    sudo ln -sf /usr/lib/jvm/java-17-openjdk-*/bin/java /usr/bin/java
}

install_terraform() {
    sudo dnf install -y wget unzip
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
    echo "[INFO] Installing Jenkins..."
    sudo curl -o /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    sudo dnf install -y jenkins
    sudo systemctl enable jenkins
    sudo systemctl start jenkins
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

cookie_jar="$(mktemp)"
full_crumb=$(curl -u "administrator:JenkinsAdmin007$"  --cookie-jar "$cookie_jar" http://localhost:8080/crumbIssuer/api/xml?xpath=concat\(//crumbRequestField,%22:%22,//crumb\))
arr_crumb=(${full_crumb//:/ })
only_crumb=$(echo ${arr_crumb[1]})

# MAKE THE REQUEST TO DOWNLOAD AND INSTALL REQUIRED MODULES
curl -X POST -u "administrator:JenkinsAdmin007$" http://localhost:8080/pluginManager/installPlugins \
  -H 'Connection: keep-alive' \
  -H 'Accept: application/json, text/javascript, */*; q=0.01' \
  -H 'X-Requested-With: XMLHttpRequest' \
  -H "$full_crumb" \
  -H 'Content-Type: application/json' \
  -H 'Accept-Language: en,en-US;q=0.9,it;q=0.8' \
  --cookie $cookie_jar \
  --data-raw "{'dynamicLoad':true,'plugins':['cloudbees-folder','antisamy-markup-formatter','build-timeout','credentials-binding','timestamper','ws-cleanup','pipeline-stage-view','gradle','workflow-aggregator','github-branch-source','pipeline-github-lib','pipeline-stage-view','git','ssh-slaves','matrix-auth','pam-auth','ldap','email-ext','mailer', ],'Jenkins-Crumb':'$only_crumb'}"

check_os
install_java
install_python
install_terraform
install_ansible
install_groovy
install_docker
install_jenkins
get_admin_password
install_jenkins_plugins

