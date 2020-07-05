pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                bat 'groovy --version'
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
