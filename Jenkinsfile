pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    triggers {
        cron('H 2 * * 1-5')
    }

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'qa', 'prod'], description: 'Target environment')
        choice(name: 'DEPLOY_STRATEGY', choices: ['rolling', 'blue-green', 'canary'], description: 'Deployment style')
        booleanParam(name: 'DEPLOY', defaultValue: false, description: 'Deploy after build')
        booleanParam(name: 'RUN_SONAR', defaultValue: false, description: 'Run SonarQube scan')
        booleanParam(name: 'RUN_SECURITY_SCANS', defaultValue: false, description: 'Run Gitleaks, pip-audit, and Trivy')
        booleanParam(name: 'RUN_DAST', defaultValue: false, description: 'Run OWASP ZAP baseline scan after deployment')
        booleanParam(name: 'RUN_TERRAFORM_PLAN', defaultValue: false, description: 'Run a Terraform plan')
        booleanParam(name: 'PUSH_IMAGE', defaultValue: false, description: 'Push Docker image to registry')
        booleanParam(name: 'AUTO_INSTALL_TOOLS', defaultValue: true, description: 'Install missing required tools on Ubuntu/Debian agents')
        string(name: 'DOCKER_IMAGE', defaultValue: 'yourdockerhub/churn-app', description: 'Docker image repository')
        string(name: 'SONAR_PROJECT_KEY', defaultValue: 'churn-app', description: 'SonarQube project key')
    }

    environment {
        APP_NAME = 'churn-app'
        PYTHONUNBUFFERED = '1'
        PIP_CACHE_DIR = '.pip-cache'
    }

    stages {
        stage('Build Metadata') {
            steps {
                script {
                    env.SHORT_SHA = env.GIT_COMMIT ? env.GIT_COMMIT.take(8) : sh(script: 'git rev-parse --short=8 HEAD', returnStdout: true).trim()
                    env.IMAGE_NAME = "${params.DOCKER_IMAGE}:${env.BUILD_NUMBER}-${env.SHORT_SHA}"
                }
            }
        }

        stage('Agent Tool Check') {
            steps {
                sh 'sh scripts/ci/check-agent-tools.sh ${AUTO_INSTALL_TOOLS}'
            }
        }

        stage('Branch Policy') {
            steps {
                sh 'sh scripts/ci/check-branch.sh'
            }
        }

        stage('Show Environment Config') {
            steps {
                sh 'cat ci/environments/${ENVIRONMENT}.env'
            }
        }

        stage('Resolve Python') {
            steps {
                script {
                    def systemPython = sh(
                        script: 'command -v python3 || command -v python || true',
                        returnStdout: true
                    ).trim()

                    if (!systemPython) {
                        error 'Python was not found. Install python3 and python3-pip on the Jenkins agent.'
                    }

                    sh """
                        "${systemPython}" -m venv .venv || {
                            echo "Could not create Python virtual environment."
                            echo "Install python3-venv and python3-pip on the Jenkins agent."
                            exit 1
                        }
                    """

                    env.PYTHON_BIN = '.venv/bin/python'
                    sh '"${PYTHON_BIN}" -m pip --version'
                    echo "Using Python: ${env.PYTHON_BIN}"
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'mkdir -p reports/junit'
                sh '"${PYTHON_BIN}" -m pip install --upgrade pip'
                sh '"${PYTHON_BIN}" -m pip install -r requirements-ci.txt'
            }
        }

        stage('Parallel Validation') {
            parallel {
                stage('Unit and Regression Tests') {
                    steps {
                        sh '"${PYTHON_BIN}" -m pytest tests --junitxml=reports/junit/pytest.xml --cov=app --cov=model --cov-report=xml:reports/coverage.xml --cov-report=term-missing --cov-fail-under=60'
                    }
                    post {
                        always {
                            junit allowEmptyResults: true, testResults: 'reports/junit/*.xml'
                        }
                    }
                }

                stage('Lint') {
                    steps {
                        sh '"${PYTHON_BIN}" -m flake8 app model tests --output-file=reports/flake8.txt --tee'
                    }
                }

                stage('Dependency Audit') {
                    when {
                        expression { params.RUN_SECURITY_SCANS }
                    }
                    steps {
                        sh '"${PYTHON_BIN}" -m pip_audit -r requirements.txt -f json -o reports/pip-audit.json'
                    }
                }

                stage('Secret Scan') {
                    when {
                        expression { params.RUN_SECURITY_SCANS }
                    }
                    steps {
                        sh 'gitleaks detect --source . --redact --report-format json --report-path reports/gitleaks.json'
                    }
                }
            }
        }

        stage('Train ML Model') {
            steps {
                sh '"${PYTHON_BIN}" model/train.py'
            }
        }

        stage('Evaluate Model') {
            steps {
                sh '"${PYTHON_BIN}" model/evaluate.py | tee reports/model-evaluation.txt'
            }
        }

        stage('Code Quality') {
            when {
                expression { params.RUN_SONAR }
            }
            steps {
                sh 'sonar-scanner -Dsonar.projectKey=${SONAR_PROJECT_KEY}'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build --label app=${APP_NAME} --label commit=${SHORT_SHA} --label build=${BUILD_NUMBER} -t ${IMAGE_NAME} .'
            }
        }

        stage('Container Image Scan') {
            when {
                expression { params.RUN_SECURITY_SCANS }
            }
            steps {
                sh 'trivy image --format table --output reports/trivy-image.txt ${IMAGE_NAME}'
            }
        }

        stage('Publish Docker Image') {
            when {
                expression { params.PUSH_IMAGE }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-token', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'
                    sh 'docker push ${IMAGE_NAME}'
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression { params.RUN_TERRAFORM_PLAN }
            }
            steps {
                sh 'terraform -chdir=infra/terraform init -input=false'
                sh 'terraform -chdir=infra/terraform plan -input=false -var-file=env/${ENVIRONMENT}.tfvars -out=../../reports/tfplan-${ENVIRONMENT}.out'
            }
        }

        stage('Approval') {
            when {
                expression { params.DEPLOY && params.ENVIRONMENT != 'dev' }
            }
            steps {
                input message: "Approve ${params.DEPLOY_STRATEGY} deployment to ${params.ENVIRONMENT}?"
            }
        }

        stage('Deploy') {
            when {
                expression { params.DEPLOY }
            }
            steps {
                sh 'sh scripts/ci/deploy.sh ${ENVIRONMENT} ${DEPLOY_STRATEGY} ${IMAGE_NAME}'
            }
        }

        stage('DAST') {
            when {
                expression { params.DEPLOY && params.RUN_DAST }
            }
            steps {
                sh 'zap-baseline.py -t http://churn-app-${ENVIRONMENT}.example.com -r reports/zap-baseline.html'
            }
        }

        stage('Release Metadata') {
            steps {
                sh 'sh scripts/ci/write-build-metadata.sh ${ENVIRONMENT} ${DEPLOY_STRATEGY} ${IMAGE_NAME}'
            }
        }
    }

    post {
        always {
            archiveArtifacts allowEmptyArchive: true, artifacts: 'reports/**/*,model/*.pkl,model/columns.pkl'
        }
        failure {
            script {
                if (params.DEPLOY) {
                    sh 'kubectl -n churn-${ENVIRONMENT} rollout undo deployment/churn-app || true'
                }
            }
        }
    }
}
