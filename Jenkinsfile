pipeline {
    agent any
    environment {            PATH = "C:\\Program Files\\Git\\usr\\bin;C:\\Program Files\\Git\\bin;${env.PATH}"         } 
    stages {
        stage('Build') {
            steps {
                bat 'sh  ./test.sh root med123'
                bat 'docker exec -i some-mysql mysql -uroot -pmed123  -Bse "drop database if exists test;show databases;create database test;show databases;"'
                
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
