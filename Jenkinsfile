pipeline {
    agent any
    
    environment {
        // Credentials
        DOCKER_CREDS = credentials('docker-creds')
        AWS_ACCESS_KEY_ID = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
        AWS_DEFAULT_REGION = "eu-north-1" 
        
        // Variables
        IMAGE_NAME = "sehaj07/cicd-miniproject:latest" 
    }

    stages {
        stage('Build Docker Image') {
            steps {
                echo "Building the Docker Image..."
                sh 'docker build -t $IMAGE_NAME .'
            }
        }
        
        stage('Push to DockerHub') {
            steps {
                echo "Logging into DockerHub and Pushing Image..."
                sh 'echo $DOCKER_CREDS_PSW | docker login -u $DOCKER_CREDS_USR --password-stdin'
                sh 'docker push $IMAGE_NAME'
            }
        }
        
        stage('Provision Target Server (Terraform)') {
            steps {
                echo "Verifying infrastructure with Terraform..."
                dir('terraform') {
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                }
            }
        }
        
        stage('Deploy via SSH') {
            steps {
                echo "Deploying updated container to the Target Node..."
                
                // 1. Grab the dynamic IP address from Terraform
                script {
                    env.TARGET_IP = sh(script: "cd terraform && terraform output -raw target_public_ip", returnStdout: true).trim()
                }
                
                // 2. Securely use the SSH key to log in and update the app
                withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY')]) {
                    sh """
                    ssh -o StrictHostKeyChecking=no -i \$SSH_KEY ubuntu@\${TARGET_IP} '
                        sudo docker pull ${IMAGE_NAME} &&
                        sudo docker rm -f cicd-app || true &&
                        sudo docker run -d -p 80:80 --name cicd-app --restart always ${IMAGE_NAME}
                    '
                    """
                }
            }
        }
    }
}