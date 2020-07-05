pipeline {
    agent any
    environment {            PATH = "C:\\Program Files\\Git\\usr\\bin;C:\\Program Files\\Git\\bin;${env.PATH}"         } 
    stages {
        stage('Build') {
            steps {
                bat 'sh  ./test.sh root med123'
                
            }
        }
        stage('Test') {
            steps {
                echo 'Testing..'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying....'
            }
        }
    }
}
