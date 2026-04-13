pipeline {
    agent any
    
    environment {
        // This grabs the DockerHub username/password we saved in Jenkins
        DOCKER_CREDS = credentials('docker-creds')
        
        // This automatically securely passes your AWS keys to Terraform
        AWS_ACCESS_KEY_ID = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
        AWS_DEFAULT_REGION = "eu-north-1" 
        
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
                echo "Using Terraform to create the target server..."
                dir('terraform') {
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                }
            }
        }
    }
}