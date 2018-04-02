pipeline {

  agent { label 'linux' }

  options {
    ansiColor('xterm')
  }

  stages {
    stage ('Build Dockerfile') {
      steps {
        sh 'docker build -t jenkins-plugins-build .'
      }
    }

    stage ('Run Mirror') {
      steps {
        sh './make.sh'
      }
    }
  }
}
