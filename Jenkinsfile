pipeline {
    agent any

    parameters {
        booleanParam(name: 'FAULTY_RELEASE', defaultValue: false, description: 'Build a deliberately faulty image')
        booleanParam(name: 'DEPLOY', defaultValue: true, description: 'Deploy to Kubernetes')
    }

    environment {
        IMAGE = 'pratheebapari/smart-water'
        TAG = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Test') {
            parallel {
                stage('Dashboard Test') {
                    steps {
                        bat 'findstr /C:"Reservoir" index.html >nul && findstr /C:"Leakage" index.html >nul && findstr /C:"Zone Analytics" index.html >nul'
                    }
                }
                stage('Config Test') {
                    steps {
                        bat 'findstr /C:"FROM nginx" Dockerfile >nul && findstr /C:"kind: Deployment" deployment.yaml >nul'
                    }
                }
            }
        }

        stage('Build Image') {
            steps {
                bat "docker build --build-arg FAULTY=${params.FAULTY_RELEASE} -t %IMAGE%:%TAG% ."
            }
        }

        stage('Push Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
                    bat 'echo %DH_PASS%| docker login -u %DH_USER% --password-stdin'
                    bat 'docker push %IMAGE%:%TAG%'
                }
            }
        }

        stage('Deploy') {
            when {
                expression { params.DEPLOY }
            }
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    powershell '(Get-Content deployment.yaml) -replace "IMAGE_TAG", "$env:TAG" | Set-Content rendered.yaml'
                    bat 'kubectl apply -f rendered.yaml'
                    script {
                        def code = bat(returnStatus: true, script: 'kubectl rollout status deployment/smart-water --timeout=60s')
                        if (code != 0) {
                            bat 'kubectl rollout undo deployment/smart-water'
                            bat 'kubectl rollout status deployment/smart-water --timeout=90s'
                            error('Rollout failed. Rolled back to the previous stable release.')
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'index.html,Dockerfile,deployment.yaml,rendered.yaml', allowEmptyArchive: true
        }
    }
}