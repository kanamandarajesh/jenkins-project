Jenkinsfile is solid — it builds a Docker image, pushes it to Docker Hub, and deploys to a Kubernetes cluster via SSH.

Now, let’s **enhance it for multi-environment support** (Dev and Prod) with:

* Parameterized `ENVIRONMENT` choice
* Separate image tags for Dev (`dev`) and Prod (`latest` or versioned)
* Separate Kubernetes manifests (optional)
* **Manual approval for Prod**

---

## ✅ Updated Multi-Environment Jenkinsfile

```groovy
pipeline {
    agent any

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'prod'], description: 'Select deployment environment')
    }

    environment {
        DOCKER_IMAGE_NAME = 'dockerspacex/calculator-app'
        REMOTE_USER = 'root'
        REMOTE_HOST = '192.168.199.129'
        SSH_KEY_PATH = '/var/jenkins_home/.ssh/my-ssh-key'
    }

    tools {
        jdk 'Java 17'
        maven 'Maven 3.6.3'
    }

    stages {
        stage('Set Environment') {
            steps {
                script {
                    if (params.ENVIRONMENT == 'dev') {
                        env.DOCKER_IMAGE_TAG = 'dev'
                        env.KUBE_DEPLOY_FILE = '/root/Kubernetes/deployment-dev.yml'
                        env.KUBE_SERVICE_FILE = '/root/Kubernetes/service-dev.yml'
                    } else if (params.ENVIRONMENT == 'prod') {
                        env.DOCKER_IMAGE_TAG = 'latest'
                        env.KUBE_DEPLOY_FILE = '/root/Kubernetes/deployment-prod.yml'
                        env.KUBE_SERVICE_FILE = '/root/Kubernetes/service-prod.yml'
                    }
                }

                echo "Deploying to ${params.ENVIRONMENT} environment"
                echo "Image Tag: ${env.DOCKER_IMAGE_TAG}"
                echo "Kube Deployment File: ${env.KUBE_DEPLOY_FILE}"
            }
        }

        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/kanamandarajesh/jenkins-project.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                docker build -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} .
                '''
            }
        }

        stage('Login to Docker Registry') {
            steps {
                withCredentials([usernamePassword(credentialsId: '3a2a5540-c9f8-46cf-af31-b69252f84a65', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                    sh '''
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    '''
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                sh '''
                docker push ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
                '''
            }
        }

        stage('Approval for Prod') {
            when {
                expression { params.ENVIRONMENT == 'prod' }
            }
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    input message: "Approve deployment to PRODUCTION?"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "kubectl apply -f ${KUBE_DEPLOY_FILE}"
                '''
            }
        }

        stage('Apply Kubernetes Service') {
            steps {
                sh '''
                ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "kubectl apply -f ${KUBE_SERVICE_FILE}"
                '''
            }
        }
    }

    post {
        success {
            echo "Deployment to ${params.ENVIRONMENT} was successful"
        }
        failure {
            echo "Deployment to ${params.ENVIRONMENT} failed"
        }
    }
}
```

---

### 🧱 Directory Structure Recommendation (Kubernetes Files)

On the Kubernetes server (remote machine):

```
/root/Kubernetes/
├── deployment-dev.yml
├── service-dev.yml
├── deployment-prod.yml
├── service-prod.yml
```

---

### 🧪 How to Use

1. In Jenkins, click **“Build with Parameters”**
2. Select either `dev` or `prod`
3. For `prod`, it will pause and wait for manual approval
4. Then builds image, pushes it, and deploys to Kubernetes using the right files

---
