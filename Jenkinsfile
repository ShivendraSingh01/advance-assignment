pipeline {
    agent any

    parameters {
        choice(name: 'ENV', choices: ['dev', 'qa', 'prod'], description: 'Deploy Environment')
        booleanParam(name: 'DEPLOY', defaultValue: true, description: 'Deploy after build')
    }

    environment {
        IMAGE = "yourdockerhub/churn-app:${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/yourrepo/churn-mlops-project.git'
            }
        }

        stage('Parallel Validation') {
            parallel {

                stage('Unit Tests') {
                    steps {
                        sh 'pytest tests/'
                    }
                }

                stage('Lint') {
                    steps {
                        sh 'flake8 .'
                    }
                }

                stage('Secret Scan') {
                    steps {
                        sh 'gitleaks detect .'
                    }
                }
            }
        }

        stage('Train ML Model') {
            steps {
                sh 'python model/train.py'
            }
        }

        stage('Evaluate Model') {
            steps {
                sh 'python model/evaluate.py'
            }
        }

        stage('Code Quality') {
            steps {
                sh 'sonar-scanner'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $IMAGE .'
            }
        }

        stage('Image Security Scan') {
            steps {
                sh 'trivy image $IMAGE'
            }
        }

        stage('Push Image') {
            steps {
                sh 'docker push $IMAGE'
            }
        }

        stage('Deploy Dev') {
            when {
                expression { params.ENV == 'dev' && params.DEPLOY }
            }
            steps {
                sh 'kubectl apply -f k8s/dev/'
            }
        }

        stage('Approval for QA/Prod') {
            when {
                expression { params.ENV != 'dev' }
            }
            steps {
                input message: 'Approve deployment?'
            }
        }

        stage('Deploy QA/Prod') {
            when {
                expression { params.DEPLOY }
            }
            steps {
                sh "kubectl apply -f k8s/${params.ENV}/"
            }
        }

        stage('Smoke Test') {
            steps {
                sh 'curl -f http://service/health'
            }
        }

        stage('Rollback') {
            when {
                expression { currentBuild.result == 'FAILURE' }
            }
            steps {
                sh 'kubectl rollout undo deployment/churn-app'
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'model/*.pkl', fingerprint: true
        }
    }
}