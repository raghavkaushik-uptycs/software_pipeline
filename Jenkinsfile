import groovy.json.JsonSlurper;
import java.text.SimpleDateFormat
pipeline {
    // worker label to use
    agent {label "Ubuntu20"}
    // parameters to be used in this pipeline
    parameters {
        choice(name: 'UPTYCS_CI_HOSTNAME', choices: ['regscan.uptycs.dev',  'quality2.uptycs.io', 'autokube.uptycs.net', 'vulnerability.uptycs.net', 'k8sdev.uptycs.net', 'cqtesting3.uptycs.net', 'demo.uptycs.io','kubernetes.uptycs.net' ], description: 'Name of the stack')
        string(name: 'FATAL_CVSS_SCORE', defaultValue: '8', description: 'Fail the build based on FATAL CVSS SCORE')
        string(name: 'UPTYCS_CI_SECRET', defaultValue: 'xxxx', description: 'Stack secret')
        string(name: 'API_KEY', defaultValue: 'xxxx', description: 'Stack api key')
        string(name: 'API_SECRET', defaultValue: 'xxxx', description: 'Stack api secret')
        string(name: 'IMG_NAME', defaultValue: 'software_pipeline_demo', description: 'Image_name')
        string(name: 'ID', defaultValue: '871a76dd-2bae-49e5-8d75-d14a73ce2a31', description: 'Stack customer-id')
        string(name: 'UPTYCS_CI_IMAGE', defaultValue: 'uptycs/uptycs-ci:latest', description: 'The uptycs-ci image to use when executing a scan')
 }

    stages {


    stage('Building the image and scan') {
        steps {
            script {

                // build the docker image
		        sh "docker build --tag '${params.IMG_NAME}:${BUILD_ID}' . "

                // run the scanner with  the secrets from jenkins secret store
                withCredentials([
					string(credentialsId: 'GITHUB_TOKEN', variable: 'GITHUB_TOKEN'),
                    string(credentialsId: 'JENKINS_TOKEN', variable: 'JENKINS_TOKEN')
                 ]) {
                // uptycs scanner and its parameters

		        sh (script: "set > uptycs-env.txt")
		        sh (script: "cat uptycs-env.txt")
                def scannerImage = 'uptycs/uptycs-ci:latest'
                def scannerImageOpts = [
                  '--rm', '--privileged', '--pid host', '--net host', '--restart no',
                  "--env RUN_DISPLAY_URL=${RUN_DISPLAY_URL}",
                  '--volume /var/run/docker.sock:/var/run/docker.sock:ro',
                  '--env JOB_NAME="${JOB_NAME}"',
                  '--env-file uptycs-env.txt',
                  '--volume \$(pwd):/opt/uptycs/cloud',
                ].join(' ')
                // scanner options
                def scanArgs = [
                    "scan",
                    "--image-id '${params.IMG_NAME}:${BUILD_ID}'",
                    "--api-key '${params.API_KEY}'",
                    "--api-secret '${params.API_SECRET}'",
                    "--uptycs-secret '${params.UPTYCS_CI_SECRET}'",
                    "--config-file uptycs-ci-config.yml",
                    "--output-name 'ciscan'",
                    "--ci-runner-type jenkins",
                    "--uptycs-hostname '${params.UPTYCS_CI_HOSTNAME}'",
                    "--customer-id '${params.ID}'",
                    "--github-checks",
                    "--jenkins-checks",
                    '--jenkins-token ${JENKINS_TOKEN}',
                    "--fatal-cvss-score ${params.FATAL_CVSS_SCORE}",
                    '--approved-email-domain uptycs.com',
                    '--github-token ${GITHUB_TOKEN}'
                ].join(' ')

                // run the scanner with docker run command
               sh (script: "docker run ${scannerImageOpts} ${params.UPTYCS_CI_IMAGE} ${scanArgs}")



                 }
            }
        }
    }
    }

    post ('Docker push to jfrog'){
    always {
            script {
                withCredentials([
                    string(credentialsId: 'JFROG_QA_USERNAME', variable: 'JFROG_USERNAME'),
                    string(credentialsId: 'JFROG_QA_PWD', variable: 'JFROG_PASSWORD')
                 ]) {
                sh "docker login --username ${JFROG_USERNAME} --password ${JFROG_PASSWORD} uptycsk8s-docker-local.jfrog.io"
                sh "docker tag '${params.IMG_NAME}:${BUILD_ID}' uptycsk8s-docker-local.jfrog.io/jfrog-test/${params.IMG_NAME}:${BUILD_ID}"
                sh "docker push uptycsk8s-docker-local.jfrog.io/jfrog-test/${params.IMG_NAME}:${BUILD_ID}"
                sh "docker system prune -f -a"
                }
            }
        }
     }

}