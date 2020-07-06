pipeline {
    agent any
    environment {            PATH = "C:\\Program Files\\Git\\usr\\bin;C:\\Program Files\\Git\\bin;${env.PATH}"         } 
    stages {
        stage('Clone N Test') {
            steps {
                bat 'sh  ./test.sh root med123'
                bat 'docker exec -i some-mysql mysql -uroot -pmed123  -Bse "drop database if exists test;create database test;"'
                bat 'docker exec -i some-mysql mysql -uroot -pmed123   < "C:\\Program Files (x86)\\Jenkins\\workspace\\DB_Continuous_Delivery\\output.sql"'
                bat 'docker exec -i some-mysql mysql -uroot -pmed123   < ".\\temp_sql_scripts\\test_1.sql"'
                
            }
        }
        stage('Apply in Prod') {
            steps {
                bat 'mysql -uroot -pmed123   < ".\\temp_sql_scripts\\test_1.sql"'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying....'
            }
        }
    }
    post { 
        always { 
            emailext body: 'A Test EMail', recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']], subject: 'Test'
        }
    }
}
