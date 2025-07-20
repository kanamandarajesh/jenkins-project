pipeline {
    agent any

    environment {
        DOCKER_IMAGE_NAME = 'dockerspacex/calculator-app'
        DOCKER_IMAGE_TAG = 'latest'
        REMOTE_USER = 'root'  // Replace with your remote SSH username
        REMOTE_HOST = '192.168.199.129'  // Replace with your Kubernetes machine IP
        SSH_KEY_ID = 'my-ssh-key'  // The ID of the SSH key stored in Jenkins Credentials
    }

    tools {
        jdk 'Java 17'
        maven 'Maven 3.6.3'
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/kanamandarajesh/jenkins-project.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh '''
                    docker build -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} .
                    '''
                }
            }
        }

        stage('Login to Docker Registry') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: '3a2a5540-c9f8-46cf-af31-b69252f84a65', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                        sh '''
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        '''
                    }
                }
            }
        }

        stage('Push Image to Docker Hub') {
            steps {
                script {
                    sh '''
                    docker push ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
                    '''
                    echo "Image pushed to Docker Hub"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sshagent(credentials: [SSH_KEY_ID]) {
                        sh '''
                        ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "kubectl apply -f /root/Kubernetes/deployment.yml"
                        '''
                    }
                }
            }
        }

        stage('Apply Kubernetes Service') {
            steps {
                script {
                    sshagent(credentials: [SSH_KEY_ID]) {
                        sh '''
                        ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "kubectl apply -f /root/Kubernetes/service.yml"
                        '''
                    }
                }
            }
        }
    }
}
