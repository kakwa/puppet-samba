pipeline {
  agent none
  stages {
    stage('Compile') {
      steps {
        parallel(
          "CentOS 7": {
            node(label: 'root_centos-7') {
              sh 'git config --global user.email "jenkins@kakwa.fr";env | sort'
              sh 'git config --global user.name "jenkins@kakwa.fr"'
              git(url: 'https://github.com/kakwa/puppet-samba', poll: true, changelog: true, branch: "${env.BRANCH_NAME}")
              sh 'git clean -fdx'
              sh './tests/tests.sh -C'
            }
            
            
          },
          "Debian 8": {
            node(label: 'root_debian-8') {
              sh 'git config --global user.email "jenkins@kakwa.fr"'
              sh 'git config --global user.name "jenkins@kakwa.fr"'
              git(url: 'https://github.com/kakwa/puppet-samba', poll: true, changelog: true, branch: "${env.BRANCH_NAME}")
              sh 'git clean -fdx'
              sh './tests/tests.sh -CD'
            }
            
            
          }
        )
      }
    }
  }
}
