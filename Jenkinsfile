pipeline {
    // install golang 1.14 on Jenkins node
    agent { node { label 'uptycs' } } 
    tools {
        go 'go1.20'
    }
    environment {
        GO114MODULE = 'on'
        CGO_ENABLED = 0 
        GOPATH = "${JENKINS_HOME}/jobs/${JOB_NAME}/builds/${BUILD_ID}"
    }
    parameters {
        string(name: "CI_IMAGE_TAG", defaultValue: "latest", trim: true, description: "Uptycs CI Image tag")
        string(name: "STACK_NAME", defaultValue: "alphacentauri", trim: true, description: "Stack name")
    }
    stages {
        stage("build") {
            steps {
                echo 'BUILD image STARTED'
                sh 'docker build --tag software_pipeline:${BUILD_ID} . '
            
                script {
		    sh (script: "set > uptycs-env.txt")
                    def stack = "$params.STACK_NAME"
                    withCredentials([
                            string(credentialsId: stack + '_UPTYCS_CI_SECRET', variable: 'UPTYCS_CI_SECRET'),
                            string(credentialsId: stack + '_UPTYCS_API_KEY', variable: 'UPTYCS_API_KEY'),
                            string(credentialsId: stack + '_UPTYCS_API_SECRET', variable: 'UPTYCS_API_SECRET'),
                            string(credentialsId: 'GITHUB_TOKEN', variable: 'GITHUB_TOKEN'),
                            string(credentialsId: 'JENKINS_TOKEN', variable: 'JENKINS_TOKEN'),

                        ]) {
                        // uptycs scanner and its parameters
                        def scannerImage = "267292272963.dkr.ecr.us-east-1.amazonaws.com/uptycs/uptycs-ci:$params.CI_IMAGE_TAG"  
                        def scannerImageOpts = [
                        '--rm', '--restart no',
                        "--network host",
			            '--env-file uptycs-env.txt',
                        "--env RUN_DISPLAY_URL=${RUN_DISPLAY_URL}",
                        '--volume /var/run/docker.sock:/var/run/docker.sock:rw',
                        '--volume ${WORKSPACE}:/opt/uptycs/cloud',
                        '--env JOB_NAME="${JOB_NAME}"'
                        ].join(' ')
                        // scanner options 
                        def scanArgs = [
                            "scan",
			                '--github-checks',
                            '--jenkins-checks',
			                '--fatal-cvss-score 11',	
			                '--jenkins-url http://10.249.0.232:8080',
                            '--jenkins-token ${JENKINS_TOKEN}',
                            "--image-id 'software_pipeline:${BUILD_ID}'",
                            //"--insecure",
                            '--ci-runner-type jenkins',
                            '--api-key ${UPTYCS_API_KEY}',
                            '--api-secret ${UPTYCS_API_SECRET}',
                            '--github-token ${GITHUB_TOKEN}',
                            '--uptycs-secret ${UPTYCS_CI_SECRET}',
                            '--approved-email-domain uptycs.com',
                            "--config-file=uptycs/${params.STACK_NAME}.yml",
                            '--audit=true',
                        ].join(' ')
			                docker.withRegistry('https://267292272963.dkr.ecr.us-east-1.amazonaws.com', 'ecr:us-east-1:uptycs-shared-jenkins') {
                        	sh (script: "docker run ${scannerImageOpts} ${scannerImage} ${scanArgs}")
			}
                    } // withCredentials
                } // script
            } //steps
        } //stage

        
        stage('Docker push to jfrog') {
                steps {
                    script {
                        withCredentials([usernamePassword(credentialsId: 'JFROG_CRED_FOR_ALPHA_CENT', usernameVariable: 'JFROG_USERNAME', passwordVariable: 'JFROG_PASSWORD')]) {
                            sh "docker login --username ${JFROG_USERNAME} --password ${JFROG_PASSWORD} uptycsk8s-docker-local.jfrog.io"
                            sh "docker tag software_pipeline:${BUILD_ID} uptycsk8s-docker-local.jfrog.io/jfrog-test/software_pipeline:${BUILD_ID}"
                            sh "docker push uptycsk8s-docker-local.jfrog.io/jfrog-test/software_pipeline:${BUILD_ID}"

                            sh "docker tag apiserver-demo:${BUILD_ID} uptycsk8s-docker-local.jfrog.io/jfrog-test/apiserver-demo:${BUILD_ID}"
                            sh "docker push uptycsk8s-docker-local.jfrog.io/jfrog-test/apiserver-demo:${BUILD_ID}"

                            } //withCredentials
                        } //script
                } // steps
            } //stage
        
        stage('sign') {
            steps {
                script{
                    sh 'curl -O -L https://github.com/sigstore/cosign/releases/latest/download/cosign_2.2.4_amd64.deb'
                    sh 'sudo dpkg -i cosign_2.2.4_amd64.deb'
                    withCredentials([
                        usernamePassword(credentialsId: 'JFROG_CRED_FOR_ALPHA_CENT', usernameVariable: 'JFROG_USERNAME', passwordVariable: 'JFROG_PASSWORD'),
                        file(credentialsId: 'COSIGN_KEY', variable: 'COSIGN_KEY'),
                    ]) {
                        sh "docker login --username ${JFROG_USERNAME} --password ${JFROG_PASSWORD} uptycsk8s-docker-local.jfrog.io"
                        sh "docker tag software_pipeline:${BUILD_ID} uptycsk8s-docker-local.jfrog.io/jfrog-test/software_pipeline:${BUILD_ID}"
                        sh 'COSIGN_PASSWORD="" cosign sign --key ${COSIGN_KEY} -y uptycsk8s-docker-local.jfrog.io/jfrog-test/software_pipeline:${BUILD_ID}'

                        sh "docker tag apiserver-demo:${BUILD_ID} uptycsk8s-docker-local.jfrog.io/jfrog-test/apiserver-demo:${BUILD_ID}"
                        sh 'COSIGN_PASSWORD="" cosign sign --key ${COSIGN_KEY} -y uptycsk8s-docker-local.jfrog.io/jfrog-test/apiserver-demo:${BUILD_ID}'
                    }
                    }
                }
            }
            
        } //stages
    } // pipeline
