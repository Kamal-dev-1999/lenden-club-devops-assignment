pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        // Link the Jenkins Credential IDs to Environment Variables
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        TRIVY_CACHE_DIR = '.trivy-cache'
        TERRAFORM_VERSION = '1.0'
    }

    options {
        timestamps()
        timeout(time: 1, unit: 'HOURS')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('Checkout Code') {
            steps {
                script {
                    echo "=========================================="
                    echo "STAGE: Checkout Code from Git"
                    echo "=========================================="
                }
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[url: 'https://github.com/Kamal-dev-1999/lenden-club-devops-assignment']]
                ])
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
                        # Install Trivy if not present
                        if ! command -v trivy &> /dev/null; then
                            echo "[*] Installing Trivy..."
                            curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
                        fi

                        # Create cache directory
                        mkdir -p ${TRIVY_CACHE_DIR}

                        echo ""
                        echo "=========================================="
                        echo "SCANNING TERRAFORM FILES..."
                        echo "=========================================="
                        echo ""

                        # Run Trivy scan on Terraform files with detailed output
                        trivy config . \
                            --format json \
                            --output trivy-scan-report.json \
                            --cache-dir ${TRIVY_CACHE_DIR} \
                            --severity HIGH,CRITICAL \
                            --exit-code 0

                        # Also run with table format for console output
                        echo ""
                        echo "⚠️  SECURITY SCAN RESULTS (Table Format):"
                        echo "=========================================="
                        echo ""
                        trivy config . \
                            --format table \
                            --cache-dir ${TRIVY_CACHE_DIR} \
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

                            if [ ${CRITICAL_COUNT} -gt 0 ] || [ ${HIGH_COUNT} -gt 0 ]; then
                                echo "⚠️  WARNINGS DETECTED!"
                                echo "-------------------------------------------"
                                cat trivy-scan-report.json | jq '.Results[] | select(.Misconfigurations != null) | .Misconfigurations[] | select(.Severity == "CRITICAL" or .Severity == "HIGH")' 2>/dev/null || echo "See trivy-scan-report.json for details"
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
                    # Check if Terraform is installed
                    if ! command -v terraform &> /dev/null; then
                        echo "[!] Terraform not found. Please install Terraform."
                        exit 1
                    fi

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
                    terraform plan \
                        -out=tfplan \
                        -detailed-exitcode \
                        -input=false || EXIT_CODE=$?

                    if [ $EXIT_CODE -eq 0 ]; then
                        echo ""
                        echo "✓ No changes required"
                    elif [ $EXIT_CODE -eq 2 ]; then
                        echo ""
                        echo "⚠️  Changes detected in infrastructure"
                    else
                        echo ""
                        echo "✗ Plan failed with exit code: $EXIT_CODE"
                        exit 1
                    fi

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

            // Archive reports
            archiveArtifacts artifacts: '**/trivy-scan-report.json', allowEmptyArchive: true
            archiveArtifacts artifacts: '**/tfplan', allowEmptyArchive: true
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

        cleanup {
            cleanWs()
        }
    }
}
