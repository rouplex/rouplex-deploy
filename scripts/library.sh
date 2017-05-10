# SYNOPSIS
#  install_jdk8
install_jdk8() {
    local jdk8Name="jdk1.8.0_121.x86_64"
    local jdk8Rpm="jdk-8u121-linux-x64.rpm"

    if yum list installed $jdk8Name > /dev/null 2>&1; then
        echo "=========== Rouplex ============= Skipping install of $jdk8Name (already installed)"
    else
        echo "=========== Rouplex ============= Downloading java rpm $jdk8Rpm"
        wget --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u121-b13/e9e7ea248e2c4826b92b3f075a80e441/$jdk8Rpm -O $jdk8Rpm  > /dev/null 2>&1

        echo "=========== Rouplex ============= Installing java rpm $jdk8Name from $jdk8Rpm"
        sudo yum -y localinstall $jdk8Rpm > /dev/null 2>&1

        if ! yum list installed $jdk8Name > /dev/null 2>&1; then
            echo "=========== Rouplex ============= Exiting. Error installing rpm $jdk8Name"
            exit 1
        fi

        rm -rf $jdk8Rpm
        echo "=========== Rouplex ============= Installed $jdk8Name"
    fi
}

# SYNOPSIS
#  install_tomcat <tomcat_version> <extras>
# Takes in the tomcat version (ex: 8.5.12) and a list of extras and populates TOMCAT_FOLDER (under current folder)
# and TOMCAT_PATH upon success.
# Example: install_tomcat 8.5.12 "catalina-jmx-remote.jar another-extra.jar"
install_tomcat() {
    if [ -z $1 ]; then
        echo "=========== Rouplex ============= Exiting. Missing <tomcat_version> in install_tomcat()"
        exit 1
    fi

    local tomcatVersion=$1
    TOMCAT_FOLDER="apache-tomcat-"${tomcatVersion}
    TOMCAT_PATH=`pwd`/${TOMCAT_FOLDER}
    local tomcatGz=${TOMCAT_FOLDER}.tar.gz

    echo "=========== Rouplex ============= Downloading tomcat $tomcatGz"
    wget http://archive.apache.org/dist/tomcat/tomcat-${tomcatVersion:0:1}/v${tomcatVersion}/bin/${tomcatGz} -O $tomcatGz > /dev/null 2>&1

    if [ $? -eq 0 ]; then
    echo "=========== Rouplex ============= Downloaded tomcat $tomcatGz"
    else
        echo "=========== Rouplex ============= Exiting. Error downloading $tomcatGz"
        exit 1
    fi

    echo "=========== Rouplex ============= Untaring tomcat $tomcatGz"
    tar -xvf $tomcatGz > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "=========== Rouplex ============= Installed tomcat $tomcatVersion at $TOMCAT_PATH"
    else
        echo "=========== Rouplex ============= Exiting. Error installing tomcat $tomcatVersion"
        exit 1
    fi

    for extra in $2; do
        echo "=========== Rouplex ============= Downloading tomcat extra $extra"
        wget http://archive.apache.org/dist/tomcat/tomcat-${tomcatVersion:0:1}/v${tomcatVersion}/bin/extras/$extra -O $TOMCAT_FOLDER/lib/$extra > /dev/null 2>&1

        if [ $? -eq 0 ]; then
            echo "=========== Rouplex ============= Downloaded tomcat extra $extra"
        else
            echo "=========== Rouplex ============= Exiting. Error downloading tomcat extra $extra"
            exit 1
        fi
    done

    rm $tomcatGz
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

    # echo "=========== Rouplex ============= Replacing $2 occurrences with $3 in $1"

    local searchEscaped=$(sed 's/[^^]/[&]/g; s/\^/\\^/g' <<<"$2")
    local replaceEscaped=$(sed 's/[&/\]/\\&/g' <<<"$3")

    sed -i -e "s/$searchEscaped/$replaceEscaped/g" $1
}
