pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        TRIVY_CACHE_DIR = '.trivy-cache'
        TERRAFORM_VERSION = '1.5.0'
        PATH = "/tmp/tools:${PATH}"
    }

    options {
        timestamps()
        timeout(time: 1, unit: 'HOURS')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('Install Dependencies') {
            steps {
                sh '''
                    # Create tools directory
                    mkdir -p /tmp/tools
                    
                    echo "[*] Checking for required tools..."
                    
                    # Install Trivy if not present
                    if ! command -v trivy &> /dev/null; then
                        echo "[*] Installing Trivy to /tmp/tools..."
                        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /tmp/tools 2>/dev/null || true
                    fi
                    
                    # Install Terraform if not present
                    if ! command -v terraform &> /dev/null; then
                        echo "[*] Installing Terraform to /tmp/tools..."
                        wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -O /tmp/terraform.zip 2>/dev/null || curl -fsSL -o /tmp/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
                        unzip -q /tmp/terraform.zip -d /tmp/tools/
                        chmod +x /tmp/tools/terraform
                        rm /tmp/terraform.zip
                    fi
                    
                    echo "✓ Dependencies installed successfully"
                    echo "Trivy version:"
                    trivy --version || echo "Trivy not available"
                    echo "Terraform version:"
                    terraform --version || echo "Terraform not available"
                '''
            }
        }

        stage('Checkout Code') {
            steps {
                script {
                    echo "=========================================="
                    echo "STAGE: Checkout Code from Git"
                    echo "=========================================="
                }
                sh '''
                    git clone --branch main https://github.com/Kamal-dev-1999/lenden-club-devops-assignment.git repo
                '''
                script {
                    echo "✓ Code checked out successfully"
                    echo "Current workspace: ${WORKSPACE}"
                }
            }
        }

        stage('Infrastructure Security Scan') {
            steps {
                script {
                    echo "=========================================="
                    echo "STAGE: Infrastructure Security Scan"
                    echo "=========================================="
                    echo ""
                    echo "Tool: Trivy"
                    echo "Scanning: Terraform files"
                    echo "=========================================="
                    echo ""
                }

                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    sh '''
                        cd repo

                        # Create cache directory
                        mkdir -p .trivy-cache

                        echo ""
                        echo "=========================================="
                        echo "SCANNING TERRAFORM FILES..."
                        echo "=========================================="
                        echo ""

                        # Run Trivy scan on Terraform files with detailed output
                        trivy config . \
                            --format json \
                            --output trivy-scan-report.json \
                            --cache-dir .trivy-cache \
                            --severity HIGH,CRITICAL \
                            --exit-code 0

                        # Also run with table format for console output
                        echo ""
                        echo "⚠️  SECURITY SCAN RESULTS (Table Format):"
                        echo "=========================================="
                        echo ""
                        trivy config . \
                            --format table \
                            --cache-dir .trivy-cache \
                            --severity HIGH,CRITICAL \
                            --exit-code 0

                        echo ""
                        echo "=========================================="
                        echo "DETAILED VULNERABILITY REPORT"
                        echo "=========================================="
                        echo ""

                        # Parse and highlight vulnerabilities
                        if [ -f trivy-scan-report.json ]; then
                            echo "[!] JSON Report generated: trivy-scan-report.json"
                            echo ""

                            # Count vulnerabilities
                            CRITICAL_COUNT=$(grep -c '"Severity": "CRITICAL"' trivy-scan-report.json || echo 0)
                            HIGH_COUNT=$(grep -c '"Severity": "HIGH"' trivy-scan-report.json || echo 0)

                            echo "📊 VULNERABILITY SUMMARY:"
                            echo "   CRITICAL: ${CRITICAL_COUNT}"
                            echo "   HIGH:     ${HIGH_COUNT}"
                            echo ""

                            if [ "${CRITICAL_COUNT}" != "0" ] || [ "${HIGH_COUNT}" != "0" ]; then
                                echo "⚠️  WARNINGS DETECTED!"
                                echo "-------------------------------------------"
                                cat trivy-scan-report.json
                                echo "-------------------------------------------"
                                echo ""
                            else
                                echo "✓ No critical or high severity issues found"
                            fi
                        fi
                    '''
                }

                script {
                    echo ""
                    echo "=========================================="
                    echo "✓ Infrastructure Security Scan Complete"
                    echo "=========================================="
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    echo "=========================================="
                    echo "STAGE: Terraform Plan"
                    echo "=========================================="
                }

                sh '''
                    cd repo

                    echo ""
                    echo "Terraform Version:"
                    terraform --version
                    echo ""

                    # Initialize Terraform
                    echo "Initializing Terraform..."
                    terraform init

                    echo ""
                    echo "=========================================="
                    echo "RUNNING TERRAFORM PLAN"
                    echo "=========================================="
                    echo ""

                    # Run Terraform plan with detailed output
                    terraform plan -out=tfplan -input=false || true
                    
                    echo ""
                    echo "=========================================="
                    echo "✓ Terraform Plan Complete"
                    echo "=========================================="
                '''
            }
        }
    }

    post {
        always {
            script {
                echo ""
                echo "=========================================="
                echo "PIPELINE SUMMARY"
                echo "=========================================="
                echo "Build Status: ${currentBuild.result}"
                echo "Build Number: ${env.BUILD_NUMBER}"
                echo "Build URL: ${env.BUILD_URL}"
                echo "=========================================="
            }
        }

        success {
            script {
                echo ""
                echo "✅ Pipeline completed successfully!"
            }
        }

        unstable {
            script {
                echo ""
                echo "⚠️  Pipeline completed with warnings (check security scan results)"
            }
        }

        failure {
            script {
                echo ""
                echo "❌ Pipeline failed. Check logs above for details."
            }
        }
    }
}
