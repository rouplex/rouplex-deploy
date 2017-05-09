# SYNOPSIS
#  install_jdk8
install_jdk8() {
    local JDK8_NAME="jdk1.8.0_121.x86_64"
    local JDK8_RPM="jdk-8u121-linux-x64.rpm"

    if yum list installed $JDK8_NAME > /dev/null 2>&1; then
        echo "=========== Rouplex ============= Skipping install of $JDK8_NAME (already installed)"
    else
        echo "=========== Rouplex ============= Downloading java rpm $JDK8_RPM"
        wget --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u121-b13/e9e7ea248e2c4826b92b3f075a80e441/$JDK8_RPM -O $JDK8_RPM

        echo "=========== Rouplex ============= Installing java rpm $JDK8_NAME from $JDK8_RPM"
        sudo yum -y localinstall $JDK8_RPM > /dev/null 2>&1

        if ! yum list installed $JDK8_NAME > /dev/null 2>&1; then
            echo "=========== Rouplex ============= Exiting. Error installing rpm $JDK8_NAME"
            exit 1
        fi

        echo "=========== Rouplex ============= Installed $JDK8_NAME"
    fi
}

# SYNOPSIS
#  install_tomcat <tomcat_version>
#  Takes in the tomcat version (ex: 8.5.12) and populates TOMCAT_FOLDER off current folder upon success
install_tomcat() {
    if [ -z $1 ]; then
        echo "=========== Rouplex ============= Exiting. Missing <tomcat_version> in install_tomcat()"
        exit 1
    fi

    local TOMCAT_VERSION=$1
    TOMCAT_FOLDER="apache-tomcat-"${TOMCAT_VERSION}
    local TOMCAT_GZ=${TOMCAT_FOLDER}.tar.gz

    echo "=========== Rouplex ============= Downloading tomcat $TOMCAT_VERSION"
    wget http://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_VERSION:0:1}/v${TOMCAT_VERSION}/bin/${TOMCAT_GZ} -O $TOMCAT_GZ > /dev/null 2>&1
    wget http://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_VERSION:0:1}/v${TOMCAT_VERSION}/bin/extras/catalina-jmx-remote.jar -O $TOMCAT_FOLDER/lib/catalina-jmx-remote.jar > /dev/null 2>&1

    echo "=========== Rouplex ============= Untaring tomcat $TOMCAT_GZ"
    tar -xvf $TOMCAT_GZ > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "=========== Rouplex ============= Installed tomcat $TOMCAT_GZ at $TOMCAT_FOLDER"
    else
        echo "=========== Rouplex ============= Exiting. Error installing rpm $TOMCAT_GZ"
        exit 1
    fi
}

# SYNOPSIS
#  clone_rouplex_private_repo <bitbucket repo> <branch>
# Clones a rouplex bitbucket repo starting at current folder
clone_rouplex_private_repo() {
    if [ "$#" -lt 1 ]; then
        echo "=========== Rouplex ============= Exiting. Missing <bitbucket repo> param in clone_rouplex_private_repo()"
        exit 1
    fi

    if [ "$#" -lt 2 ]; then
        echo "=========== Rouplex ============= Exiting. Missing <branch> param in clone_rouplex_private_repo()"
        exit 1
    fi

    local ROUPLEX_REPO=$1
    local BRANCH=$2
    mkdir .ssh

    # Name of key is the same as the repo for simplicity
    aws s3 cp s3://rouplex/deploys/access-keys/${ROUPLEX_REPO} .ssh > /dev/null 2>&1
    aws s3 cp s3://rouplex/deploys/access-keys/known_hosts .ssh > /dev/null 2>&1

    chmod 400 .ssh/${ROUPLEX_REPO}
    chown -R ec2-user:ec2-user .ssh

    yum install -y git
    rm -rf ${ROUPLEX_REPO}
    sudo -H -u ec2-user bash -c "ssh-agent bash -c 'ssh-add .ssh/${ROUPLEX_REPO}; git clone ssh://bitbucket.org/rouplex/${ROUPLEX_REPO}.git --branch ${BRANCH} --single-branch'"

    if [ -d ${ROUPLEX_REPO} ]; then
        echo "=========== Rouplex ============= Cloned ${ROUPLEX_REPO}"
    else
        echo "=========== Rouplex ============= Exiting. Failed cloning ${ROUPLEX_REPO}"
    fi
}

# SYNOPSIS
#  replace <filename> <search> <replace>
# https://stackoverflow.com/questions/29613304
search_and_replace() {
    if [ "$#" -lt 1 ]; then
        echo "=========== Rouplex ============= Exiting. Missing <filename> param in replace()"
        exit 1
    fi

    if [ "$#" -lt 2 ]; then
        echo "=========== Rouplex ============= Exiting. Missing <search> param in replace()"
        exit 1
    fi

    if [ "$#" -lt 3 ]; then
        echo "=========== Rouplex ============= Exiting. Missing <replace> param in replace()"
        exit 1
    fi

    local searchEscaped=$(sed 's/[^^]/[&]/g; s/\^/\\^/g' <<<"$2")
    local replaceEscaped=$(sed 's/[&/\]/\\&/g' <<<"$3")

    sed -i "" -e "s/$searchEscaped/$replaceEscaped/g" $1
}

#replace "server.xml" "#keystoreFile#" "/home/ec2-user/apache-tomcat-8.5.12/conf/server_key.p12"
#replace "server.xml" "#keystorePass#" "kotplot123"
#
