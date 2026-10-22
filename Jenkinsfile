
pipeline {
    agent any

    environment {
        IMAGE_NAME = 'my_app-pipeline'
        CONTAINER_NAME = 'my_app_pipeline'
        TEST_CONTAINER = 'my_app_test'
        APP_PORT = '8014'
        TEST_PORT = '8015'

        AWS_HOST = 'ubuntu@16.4.72.200'
        AWS_KEY = '/var/lib/jenkins/.ssh/Deployment_server'
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

        stage('Deploy to AWS EC2') {
            steps {
                sh '''
                    set -eu

                    KEY="${AWS_KEY}"
                    HOST="${AWS_HOST}"
                    IMAGE_TAG="${IMAGE_NAME}:${BUILD_NUMBER}"
                    IMAGE_FILE="/tmp/${IMAGE_NAME}-${BUILD_NUMBER}.tar.gz"
                    REMOTE_IMAGE_FILE="/tmp/${IMAGE_NAME}-${BUILD_NUMBER}.tar.gz"

                    echo "Exporting Docker image..."

                    docker save "${IMAGE_TAG}" |
                        gzip > "${IMAGE_FILE}"

                    echo "Transferring image to AWS EC2..."

                    scp -i "${KEY}" \
                        -o StrictHostKeyChecking=yes \
                        "${IMAGE_FILE}" \
                        "${HOST}:${REMOTE_IMAGE_FILE}"

                    echo "Deploying container on EC2..."

                    ssh -i "${KEY}" \
                        -o StrictHostKeyChecking=yes \
                        "${HOST}" \
                        "IMAGE_NAME=${IMAGE_NAME} BUILD_NUMBER=${BUILD_NUMBER} REMOTE_IMAGE_FILE=${REMOTE_IMAGE_FILE} bash -s" <<'REMOTE_SCRIPT'
set -eu

CONTAINER="my_app_pipeline"
OLD_CONTAINER="my_app_pipeline_previous"
IMAGE="${IMAGE_NAME}:${BUILD_NUMBER}"
OLD_MOVED=0

rollback() {
    rc=$?

    if [ "$rc" -ne 0 ] && [ "$OLD_MOVED" -eq 1 ]; then
        echo "Deployment failed. Restoring previous container..."

        docker rm -f "$CONTAINER" 2>/dev/null || true
        docker rename "$OLD_CONTAINER" "$CONTAINER" || true
        docker start "$CONTAINER" || true
    fi
}

trap rollback EXIT

echo "Loading Docker image..."
docker load -i "$REMOTE_IMAGE_FILE"

# Remove a leftover backup from an earlier deployment.
docker rm -f "$OLD_CONTAINER" 2>/dev/null || true

# Preserve the current production container.
if docker inspect "$CONTAINER" >/dev/null 2>&1; then
    docker stop "$CONTAINER"
    docker rename "$CONTAINER" "$OLD_CONTAINER"
    OLD_MOVED=1
fi

# Start the new version on public HTTP port 80.
docker run -d \
    --name "$CONTAINER" \
    -p 80:80 \
    "$IMAGE"

sleep 3

# Verify that the website responds and serves the expected content.
curl -fsS http://localhost/ -o /tmp/aws-deployment-test.html

grep -q "The commands you keep forgetting" \
    /tmp/aws-deployment-test.html

echo "AWS deployment and HTTP content checks passed!"

# Disable rollback only after successful verification.
trap - EXIT

docker rm -f "$OLD_CONTAINER" 2>/dev/null || true
rm -f "$REMOTE_IMAGE_FILE" /tmp/aws-deployment-test.html

REMOTE_SCRIPT

                    rm -f "${IMAGE_FILE}"

                    echo "Deployment to AWS completed successfully!"
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
