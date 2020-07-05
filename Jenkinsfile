pipeline {
    agent any
    environment {            PATH = "C:\\Program Files\\Git\\usr\\bin;C:\\Program Files\\Git\\bin;${env.PATH}"         } 
    stages {
        stage('Build') {
            steps {
                bat 'sh  ./test.sh root med123'
                bat 'docker exec -i some-mysql mysql -uroot -pmed123  -Bse "drop database if exists test;create database test;"'
                bat 'docker exec -i some-mysql mysql -uroot -pmed123  test < "C:\\Program Files (x86)\\Jenkins\\workspace\\DB_Continuous_Delivery\\output.sql"'
                bat 'docker exec -i some-mysql mysql -uroot -pmed123  test < ".\\temp_sql_scripts\\test1.sql"'
                
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
