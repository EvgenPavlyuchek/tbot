def available_os
def available_arch
def f_ChoiceOs(command, os, arch) {
    available_os = ['linux', 'darwin', 'windows']
    if (os == 'all') {
        for (int i = 0; i < available_os.size(); i++) {
            f_ChoiceArch(command, available_os[i], arch)
        }
    } else {
        f_ChoiceArch(command, os, arch)
    }
}
def f_ChoiceArch(command, os, arch) {
    available_arch = ['amd64', 'arm64', 'arm','386']
    if (arch == 'all') {
        for (int i = 0; i < available_arch.size(); i++) {
            f_Check(command, os, available_arch[i])
        }
    } else {
        f_Check(command, os, arch)
    }
}
def f_Check(command, os, arch) {
    if ((os == "darwin" && arch == "arm") || (os == "darwin" && arch == "386")){echo "Invalid combination of OS and architecture: ${os} - ${arch}";return }
    echo "make ${command} for ${os} - ${arch}"
    sh "make ${command} TARGETOS=${os} TARGETARCH=${arch}"
}

pipeline {
    agent any
    parameters {
        choice(name: 'OS', choices: ['linux', 'darwin', 'windows', 'all'], description: 'Pick OS')
        choice(name: 'ARCH', choices: ['amd64', 'arm64', 'arm', '386', 'all'], description: 'Pick ARCH')
    }
    // agent {
    //     label 'local'
    // }
    environment {
        REPO = 'https://github.com/EvgenPavlyuchek/tbot'
        BRANCH = 'main'
        GITHUB_TOKEN=credentials('ghcr')
    }
    stages {
        
        stage("clone") {
            steps {
                echo 'CLONE  REPOSITORY'
                git branch: "${BRANCH}", url: "${REPO}"
            }
        }

        stage("test") {
            steps {
                echo 'TEST EXECUTION STARTED'
                script {
                    f_ChoiceOs('test', params.OS, params.ARCH)
                    // sh 'make test TARGETOS=' + params.OS + ' TARGETARCH=' + params.ARCH
                }               
            }
        }

        stage("build") {
            steps {
                echo 'BUILD EXECUTION STARTED'
                script {
                    f_ChoiceOs('build', params.OS, params.ARCH)
                    // sh 'make build TARGETOS=' + params.OS + ' TARGETARCH=' + params.ARCH
                }
            }
        }

        stage('image') {
            steps {
                echo 'BUILD EXECUTION STARTED'
                script {
                    f_ChoiceOs('image', params.OS, params.ARCH)
                    // sh 'make image TARGETOS=' + params.OS + ' TARGETARCH=' + params.ARCH
                }    
            }
        }  

        stage('push') {
            steps {
                echo "PUSH IMAGE"
                script {
                    sh 'echo $GITHUB_TOKEN_PSW | docker login ghcr.io -u $GITHUB_TOKEN_USR --password-stdin'
                    f_ChoiceOs('push', params.OS, params.ARCH)
                    // sh 'make push TARGETOS=' + params.OS + ' TARGETARCH=' + params.ARCH
                }    
            }
        }
    }
}