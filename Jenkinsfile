pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        TRIVY_CACHE_DIR = '.trivy-cache'
        TERRAFORM_VERSION = '1.5.0'
        // This ensures the pipeline looks in your custom folder for the tools
        PATH = "/tmp/tools:${PATH}"
    }

    options {
        timestamps()
        timeout(time: 1, unit: 'HOURS')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('Install Tools') {
            steps {
                sh '''
                    mkdir -p /tmp/tools
                    
                    # Install Trivy to /tmp/tools if not present
                    if ! command -v trivy &> /dev/null; then
                        echo "[*] Installing Trivy..."
                        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /tmp/tools
                    fi
                    
                    # Install Terraform to /tmp/tools if not present
                    if ! command -v terraform &> /dev/null; then
                        echo "[*] Installing Terraform..."
                        curl -fsSL -o /tmp/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
                        unzip -o /tmp/terraform.zip -d /tmp/tools/
                        chmod +x /tmp/tools/terraform
                        rm /tmp/terraform.zip
                    fi
                '''
            }
        }

        stage('Infrastructure Security Scan') {
            steps {
                script {
                    echo "STAGE: Infrastructure Security Scan (Trivy)" [cite: 34, 35]
                }
                // Fail on failure but clearly show security warnings as required [cite: 39]
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    sh '''
                        trivy config . \
                            --format table \
                            --severity HIGH,CRITICAL \
                            --exit-code 0
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    echo "STAGE: Terraform Plan" [cite: 45]
                }
                sh '''
                    terraform init
                    terraform plan -var="key_pair_name=devsecops-dev-key" -input=false
                '''
            }
        }
    }

    post {
        always {
            script {
                echo "Build Status: ${currentBuild.result}"
            }
        }
    }
}
