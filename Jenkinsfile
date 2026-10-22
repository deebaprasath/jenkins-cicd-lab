
pipeline {
    agent any

    environment {
        IMAGE_NAME = 'my_app-pipeline'
        CONTAINER_NAME = 'my_app_pipeline'
        TEST_CONTAINER = 'my_app_test'
        APP_PORT = '8014'
        TEST_PORT = '8015'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo 'Source code checked out successfully'
            }
        }

        stage('Validate Source') {
            steps {
                sh '''
                    set -eu

                    test -f index.html
                    test -f Dockerfile
                    test -f test.sh

                    echo "Source files validated successfully"
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    set -eu

                    chmod +x test.sh
                    ./test.sh
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    set -eu

                    docker build \
                        -t ${IMAGE_NAME}:${BUILD_NUMBER} .

                    echo "Docker image built successfully"
                '''
            }
        }

        stage('Test New Container') {
            steps {
                sh '''
                    set -eu

                    docker rm -f ${TEST_CONTAINER} 2>/dev/null || true

                    docker run -d \
                        --name ${TEST_CONTAINER} \
                        -p ${TEST_PORT}:80 \
                        ${IMAGE_NAME}:${BUILD_NUMBER}

                    sleep 3

                    if ! curl -fsS \
                        http://localhost:${TEST_PORT}/ \
                        -o /tmp/jenkins-test.html; then
                        docker logs ${TEST_CONTAINER}
                        exit 1
                    fi

                    grep -q "The commands you keep forgetting" \
                        /tmp/jenkins-test.html

                    echo "Test container passed HTTP and content checks"
                '''
            }
        }

        stage('Deploy Production') {
            steps {
                sh '''
                    set -eu

                    OLD_CONTAINER="${CONTAINER_NAME}_previous"
                    OLD_MOVED=0

                    rollback() {
                        rc=$?

                        if [ "$rc" -ne 0 ] && [ "$OLD_MOVED" -eq 1 ]; then
                            echo "Deployment failed. Restoring previous container..."

                            docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

                            docker rename \
                                "${OLD_CONTAINER}" \
                                "${CONTAINER_NAME}" || true

                            docker start "${CONTAINER_NAME}" || true

                            sleep 2

                            curl -fsS \
                                "http://localhost:${APP_PORT}/" \
                                -o /dev/null \
                                || echo "WARNING: Check previous container health"
                        fi
                    }

                    trap rollback EXIT

                    # Remove a leftover backup from an earlier successful deployment.
                    docker rm -f "${OLD_CONTAINER}" 2>/dev/null || true

                    # Preserve the current production container.
                    if docker inspect "${CONTAINER_NAME}" >/dev/null 2>&1; then
                        docker stop "${CONTAINER_NAME}"
                        docker rename "${CONTAINER_NAME}" "${OLD_CONTAINER}"
                        OLD_MOVED=1
                    fi

                    # Start the new version.
                    docker run -d \
                        --name "${CONTAINER_NAME}" \
                        -p "${APP_PORT}:80" \
                        "${IMAGE_NAME}:${BUILD_NUMBER}"

                    sleep 3

                    # Verify the production website responds.
                    curl -fsS \
                        "http://localhost:${APP_PORT}/" \
                        -o /tmp/jenkins-production.html

                    # Verify the expected website content.
                    grep -q "The commands you keep forgetting" \
                        /tmp/jenkins-production.html

                    echo "Production deployment and content checks passed"

                    # Disable rollback after successful verification.
                    trap - EXIT

                    # Remove the previous container after success.
                    docker rm -f "${OLD_CONTAINER}" 2>/dev/null || true
                '''
            }
        }
    }

    post {
        always {
            sh '''
                docker rm -f ${TEST_CONTAINER} 2>/dev/null || true
            '''
        }

        success {
            echo 'CI/CD pipeline completed successfully!'
        }

        failure {
            echo 'CI/CD pipeline failed. Check the Console Output.'
        }
    }
}
