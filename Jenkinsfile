pipeline {
    agent any
    environment {            PATH = "C:\\Program Files\\Git\\usr\\bin;C:\\Program Files\\Git\\bin;${env.PATH}"         } 
    stages {
        stage('Clone DB') {
            steps {
                bat 'sh  ./test.sh root med123'
             }
        }
        stage('Import DB + Script') {
            steps {
                bat 'docker exec -i some-mysql mysql -uroot -pmed123   < "C:\\Program Files (x86)\\Jenkins\\workspace\\DB_Continuous_Delivery\\output.sql"'
                bat 'docker exec -i some-mysql mysql -uroot -pmed123   < ".\\temp_sql_scripts\\test_1.sql"'
            }
        }
        stage('Apply in Prod') {
            steps {
                bat 'mysql -uroot -pmed123   < ".\\temp_sql_scripts\\test_1.sql"'
            }
        }
        
    }
}
