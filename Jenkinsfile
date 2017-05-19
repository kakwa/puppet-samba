pipeline {
  agent none
  stages {
    stage('Compile') {
      steps {
        parallel(
          "CentOS 7": {
            node(label: 'root_centos-7') {
              sh 'git config --global user.email "jenkins@kakwa.fr"'
              sh 'git config --global user.name "jenkins@kakwa.fr"'
              git(url: 'https://github.com/kakwa/puppet-samba', poll: true, changelog: true)
              sh 'git clean -fdx'
              sh 'export OS=centos-7; /bin/true'
            }
          },
          "Debian 8": {
            node(label: 'debian-8') {
              sh 'git config --global user.email "jenkins@kakwa.fr"'
              sh 'git config --global user.name "jenkins@kakwa.fr"'
              git(url: 'https://github.com/kakwa/puppet-samba', poll: true, changelog: true)
              sh 'git clean -fdx'
              sh 'export OS=debian-8; /bin/true'
            }
          }
        )
      }
    }
  }
}
