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
        booleanParam(name: 'RUN_SECURITY_SCANS', defaultValue: false, description: 'Run pip-audit, Docker-based Gitleaks, and Docker-based Trivy')
        booleanParam(name: 'RUN_DAST', defaultValue: false, description: 'Run Docker-based OWASP ZAP baseline scan after deployment')
        booleanParam(name: 'RUN_TERRAFORM_PLAN', defaultValue: false, description: 'Run a Terraform plan')
        booleanParam(name: 'PUSH_IMAGE', defaultValue: false, description: 'Push Docker image to registry')
        string(name: 'DOCKER_IMAGE', defaultValue: 'shivam1999/churn-app', description: 'Docker image repository')
        string(name: 'AWS_REGION', defaultValue: 'ap-south-1', description: 'AWS region for the EKS cluster')
        string(name: 'EKS_CLUSTER_NAME', defaultValue: 'advance-assignment-eks', description: 'Existing AWS EKS cluster name')
        string(name: 'AWS_CREDENTIAL_ID', defaultValue: 'aws-jenkins-credentials', description: 'Jenkins username/password credential for AWS access key and secret')
        string(name: 'NEXUS_REPO_URL', defaultValue: 'http://65.1.87.174:8081/repository/churn-app/', description: 'Optional Nexus upload URL')
        string(name: 'NEXUS_CREDENTIAL_ID', defaultValue: 'nexus-credentials', description: 'Optional Nexus username/password credential ID')
        string(name: 'SONAR_PROJECT_KEY', defaultValue: 'ShivendraSingh01_advance-assignment', description: 'SonarQube project key')
        string(name: 'SONAR_ORGANIZATION', defaultValue: 'shivendrasingh01', description: 'SonarCloud organization key')
        string(name: 'SONAR_TOKEN_CREDENTIAL_ID', defaultValue: 'sonarcloud-token', description: 'Jenkins Secret text credential ID for SonarCloud')
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
                sh 'sh scripts/ci/check-agent-tools.sh ${RUN_SECURITY_SCANS} ${RUN_SONAR} ${RUN_DAST} ${RUN_TERRAFORM_PLAN} ${DEPLOY}'
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
                sh '"${PYTHON_BIN}" -m pip install -r requirements.txt'
            }
        }

        stage('Parallel Validation') {
            parallel {
                stage('Unit and Regression Tests') {
                    steps {
                        sh '"${PYTHON_BIN}" -m pytest tests --junitxml=reports/junit/pytest.xml --cov=app --cov=model --cov-report=xml:reports/coverage.xml --cov-report=term-missing --cov-fail-under=35'
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
                        sh '''
                            docker run --rm \
                                -v "$PWD:/repo" \
                                zricethezav/gitleaks:latest \
                                detect --source /repo --config /repo/.gitleaks.toml --redact --report-format json --report-path /repo/reports/gitleaks.json
                        '''
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

        stage('Package Artifact') {
            steps {
                sh 'sh scripts/ci/write-feedback-summary.sh'
                sh 'sh scripts/ci/package-artifact.sh ${IMAGE_NAME}'
            }
        }

        stage('Code Quality') {
            when {
                expression { params.RUN_SONAR }
            }
            steps {
                withCredentials([string(credentialsId: params.SONAR_TOKEN_CREDENTIAL_ID, variable: 'SONAR_TOKEN')]) {
                    sh '''
                        sonar-scanner \
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                            -Dsonar.organization=${SONAR_ORGANIZATION} \
                            -Dsonar.token=${SONAR_TOKEN}
                    '''
                }
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
                sh '''
                    docker run --rm \
                        -v /var/run/docker.sock:/var/run/docker.sock \
                        -v "$PWD/reports:/reports" \
                        aquasec/trivy:latest \
                        image --format table --output /reports/trivy-image.txt ${IMAGE_NAME}
                '''
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

        stage('Publish Build Artifact') {
            when {
                expression { params.NEXUS_REPO_URL?.trim() }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: params.NEXUS_CREDENTIAL_ID, usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    sh '''
                        curl -f -u "$NEXUS_USER:$NEXUS_PASS" \
                            -T "reports/${APP_NAME}-${BUILD_NUMBER}-${SHORT_SHA}.tar.gz" \
                            "${NEXUS_REPO_URL}/${APP_NAME}/${BUILD_NUMBER}/${APP_NAME}-${BUILD_NUMBER}-${SHORT_SHA}.tar.gz"
                    '''
                }
            }
        }

        stage('Promote Artifact Metadata') {
            steps {
                sh 'sh scripts/ci/promote-artifact.sh ${ENVIRONMENT} ${IMAGE_NAME}'
            }
        }

        stage('Terraform Plan') {
            when {
                expression { params.RUN_TERRAFORM_PLAN || params.DEPLOY }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: params.AWS_CREDENTIAL_ID, usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        terraform -chdir=infra/terraform init -input=false
                        terraform -chdir=infra/terraform validate
                        terraform -chdir=infra/terraform plan -input=false \
                            -var-file=env/${ENVIRONMENT}.tfvars \
                            -var="aws_region=${AWS_REGION}" \
                            -var="eks_cluster_name=${EKS_CLUSTER_NAME}" \
                            -var="app_name=${APP_NAME}" \
                            -var="image=${IMAGE_NAME}" \
                            -var="deployment_strategy=${DEPLOY_STRATEGY}" \
                            -out=../../reports/tfplan-${ENVIRONMENT}.out
                    '''
                }
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

        stage('Terraform Apply') {
            when {
                expression { params.DEPLOY }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: params.AWS_CREDENTIAL_ID, usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        terraform -chdir=infra/terraform plan -input=false \
                            -var-file=env/${ENVIRONMENT}.tfvars \
                            -var="aws_region=${AWS_REGION}" \
                            -var="eks_cluster_name=${EKS_CLUSTER_NAME}" \
                            -var="app_name=${APP_NAME}" \
                            -var="image=${IMAGE_NAME}" \
                            -var="deployment_strategy=${DEPLOY_STRATEGY}" \
                            -out=../../reports/tfplan-${ENVIRONMENT}.out

                        terraform -chdir=infra/terraform apply -input=false -auto-approve ../../reports/tfplan-${ENVIRONMENT}.out
                    '''
                }
            }
        }

        stage('DAST') {
            when {
                expression { params.DEPLOY && params.RUN_DAST }
            }
            steps {
                sh '''
                    docker run --rm \
                        -v "$PWD/reports:/zap/wrk/:rw" \
                        ghcr.io/zaproxy/zaproxy:stable \
                        zap-baseline.py -t http://churn-app-${ENVIRONMENT}.example.com -r zap-baseline.html
                '''
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
    }
}
