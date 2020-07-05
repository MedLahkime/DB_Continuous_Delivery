pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                bat 'groovy test.gvy'
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
