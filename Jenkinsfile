pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                bat 'sh test.sh'
                
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
