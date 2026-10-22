
stage('Deploy to AWS EC2') {
    steps {
        sh '''
            set -eu

            KEY="/var/lib/jenkins/.ssh/Deployment_server"
            HOST="ubuntu@16.4.72.200"
            IMAGE_FILE="/tmp/${IMAGE_NAME}-${BUILD_NUMBER}.tar.gz"
            REMOTE_IMAGE_FILE="/tmp/${IMAGE_NAME}-${BUILD_NUMBER}.tar.gz"

            echo "Exporting Docker image..."
            docker save "${IMAGE_NAME}:${BUILD_NUMBER}" |
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

            docker load -i "$REMOTE_IMAGE_FILE"

            docker rm -f "$OLD_CONTAINER" 2>/dev/null || true

            if docker inspect "$CONTAINER" >/dev/null 2>&1; then
                docker stop "$CONTAINER"
                docker rename "$CONTAINER" "$OLD_CONTAINER"
                OLD_MOVED=1
            fi

            docker run -d \
                --name "$CONTAINER" \
                -p 80:80 \
                "$IMAGE"

            sleep 3

            curl -fsS http://localhost/ -o /tmp/aws-deployment-test.html

            grep -q "The commands you keep forgetting" \
                /tmp/aws-deployment-test.html

            echo "AWS deployment and HTTP content checks passed!"

            trap - EXIT
            docker rm -f "$OLD_CONTAINER" 2>/dev/null || true
            rm -f "$REMOTE_IMAGE_FILE"
            REMOTE_SCRIPT

            rm -f "${IMAGE_FILE}"

            echo "Deployment to AWS completed successfully!"
        '''
    }
}

