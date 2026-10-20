
pipeline {
    agent any

    environment {
        IMAGE_NAME = 'my_app-pipeline'
        CONTAINER_NAME = 'my_app_pipeline'
        APP_PORT = '8014'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo 'Source code checked out'
            }
        }

        stage('Validate Source') {
            steps {
                sh '''
                    set -eu
                    test -f index.html
                    test -f Dockerfile
                    test -f test.sh
                    echo "Source files validated"
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    chmod +x test.sh
                    ./test.sh
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build \
                      -t ${IMAGE_NAME}:${BUILD_NUMBER} .
                '''
            }
        }

        stage('Deploy Container') {
            steps {
                sh '''
                    docker rm -f ${CONTAINER_NAME} 2>/dev/null || true

                    docker run -d \
                      --name ${CONTAINER_NAME} \
                      -p ${APP_PORT}:80 \
                      ${IMAGE_NAME}:${BUILD_NUMBER}
                '''
            }
        }

        stage('Verify Website') {
            steps {
                sh '''
                    set -eu
                    sleep 2
                    curl -fsS -o /dev/null \
                      http://localhost:${APP_PORT}/
                    echo "Website verification successful"
                '''
            }
        }
    }
}
