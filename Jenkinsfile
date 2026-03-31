pipeline {
    agent any
    tools {
        jdk 'jdk-17'
    }
    environment {
        DOCKER_REPO_NAME = 'alikakavand/demo-app'
    }
    stages {
        stage('increment version') {
            steps {
                script {
                    echo 'incrementing app version...'
                    def buildGradle = readFile('build.gradle')
                    def currentVersion = (buildGradle =~ /version '(.+)'/)[0][1]
                    def (major, minor, patch) = currentVersion.tokenize('.').collect { it as int }
                    def newVersion = "${major}.${minor}.${patch + 1}"
                    buildGradle = buildGradle.replaceFirst("version '${currentVersion}'", "version '${newVersion}'")
                    writeFile file: 'build.gradle', text: buildGradle
                    env.IMAGE_VERSION = "${newVersion}-${BUILD_NUMBER}"
                }
            }
        }
        stage('build app') {
            steps {
                script {
                    echo 'building the application...'
                    sh 'chmod +x gradlew'
                    sh './gradlew clean build'
                }
            }
        }
        stage('build image') {
            steps {
                script {
                    echo 'building the docker image...'
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-repo', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                        sh "docker build -t ${DOCKER_REPO_NAME}:${IMAGE_VERSION} ."
                        sh 'echo $PASS | docker login -u $USER --password-stdin'
                        sh "docker push ${DOCKER_REPO_NAME}:${IMAGE_VERSION}"
                    }
                }
            }
        }
        stage('deploy') {
            environment {
                AWS_ACCESS_KEY_ID = credentials('jenkins_aws_access_key_id')
                AWS_SECRET_ACCESS_KEY = credentials('jenkins_aws_secret_access_key')
                APP_NAME = 'my-java-app'
            }
            steps {
                script {
                    echo 'deploying docker image...'
                    sh 'aws eks update-kubeconfig --name demo-cluster --region eu-central-1'
                    sh "helm upgrade --install ${APP_NAME} ./helm/my-java-app -f helm/eks-values.yaml --set image.tag=${IMAGE_VERSION}"
                }
            }
        }
        stage('commit version update') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'github-pat', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                        sh 'git config --global user.email "jenkins@example.com"'
                        sh 'git config --global user.name "Jenkins"'
                        sh 'git remote set-url origin https://$USER:$PASS@github.com/Alee7hub/gradle-app-exec11.git'
                        sh 'git add build.gradle'
                        sh 'git commit -m "ci: version bump"'
                        sh 'git push origin HEAD:main'
                    }
                }
            }
        }
    }
}
