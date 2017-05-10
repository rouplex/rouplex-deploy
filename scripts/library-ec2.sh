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

    local rouplexRepo=$1
    local branch=$2
    mkdir .ssh

    # Name of key is the same as the repo for simplicity
    aws s3 cp s3://rouplex/deploys/access-keys/${rouplexRepo} .ssh > /dev/null 2>&1
    aws s3 cp s3://rouplex/deploys/access-keys/known_hosts .ssh > /dev/null 2>&1

    chmod 400 .ssh/${rouplexRepo}
    chown -R ec2-user:ec2-user .ssh

    yum install -y git
    rm -rf ${rouplexRepo}
    sudo -H -u ec2-user bash -c "ssh-agent bash -c 'ssh-add .ssh/${rouplexRepo}; git clone ssh://bitbucket.org/rouplex/${rouplexRepo}.git --branch ${branch} --single-branch'"

    if [ -d ${rouplexRepo} ]; then
        echo "=========== Rouplex ============= Cloned ${rouplexRepo}"
    else
        echo "=========== Rouplex ============= Exiting. Failed cloning ${rouplexRepo}"
    fi
}
