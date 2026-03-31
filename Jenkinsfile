pipeline {
    agent any
    tools {
        maven 'maven-3.9'
    }
    environment {
        DOCKER_REPO_SERVER = '320806842529.dkr.ecr.eu-central-1.amazonaws.com'
        DOCKER_REPO_NAME = "${DOCKER_REPO_SERVER}/java-maven-app"
    }
    stages {
        stage('increment version') {
            steps {
                script {
                    echo 'incrementing app version...'
                    sh 'mvn build-helper:parse-version versions:set \
                        -DnewVersion=\\\${parsedVersion.majorVersion}.\\\${parsedVersion.minorVersion}.\\\${parsedVersion.nextIncrementalVersion} \
                        versions:commit'
                    def matcher = readFile('pom.xml') =~ '<version>(.+)</version>'
                    def version = matcher[0][1]
                    env.IMAGE_VERSION = "$version-$BUILD_NUMBER"
                }
            }
        }
         stage('build app') {
            steps {
                script {
                    echo 'building the application...'
                    sh 'mvn clean package'
                }
            }
        }
        stage('build image') {
            steps {
                script {
                    echo "building the docker image..."
                    withCredentials([usernamePassword(credentialsId: 'ecr-credentials', passwordVariable: 'PASS', usernameVariable: 'USER')]){
                        sh "docker build -t ${DOCKER_REPO_NAME}:${IMAGE_VERSION} ."
                        sh 'echo $PASS | docker login -u $USER --password-stdin ${DOCKER_REPO_SERVER}'
                        sh "docker push ${DOCKER_REPO_NAME}:${IMAGE_VERSION}"
                    }
                }
            }
        } 
        stage('deploy') {
            environment {
                AWS_ACCESS_KEY_ID = credentials('jenkins_aws_access_key_id')
                AWS_SECRET_ACCESS_KEY = credentials('jenkins_aws_secret_access_key')
                APP_NAME = 'java-maven-app'
            }
            steps {
                script {
                   echo 'deploying docker image...'
                   sh 'aws eks update-kubeconfig --name demo-cluster --region eu-central-1'
                   sh 'envsubst < kubernetes/deployment.yaml | kubectl apply -f -'
                   sh 'envsubst < kubernetes/service.yaml | kubectl apply -f -'
                }
            }
        }
        stage('commit version update'){
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'github-pat', passwordVariable: 'PASS', usernameVariable: 'USER')]){
                        sh 'git config --global user.email "jenkins@example.com"'
                        sh 'git config --global user.name "Jenkins"'
                        sh 'git remote set-url origin https://$USER:$PASS@github.com/Alee7hub/jm-deploy-to-eks-jenkins.git'
                        sh 'git add .'
                        sh 'git commit -m "ci: version bump"'
                        sh 'git push origin HEAD:jenkins-jobs'
                    }
                }
            }
        }
    }
}
