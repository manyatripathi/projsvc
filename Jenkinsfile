def readProperties(){
	def properties_file_path = "${workspace}" + "@script/properties.yml"
	def property = readYaml file: properties_file_path

    env.APP_NAME = property.APP_NAME
    env.MS_NAME = property.MS_NAME
    env.BRANCH = property.BRANCH
    env.GIT_SOURCE_URL = property.GIT_SOURCE_URL
    env.SONAR_HOST_URL = property.SONAR_HOST_URL
    
}

def firstTimeDevDeployment(projectName,msName){
    openshift.withCluster() {
        openshift.withProject(projectName) {
             
            openshift.startBuild("https://github.com/Vageesha17/projsvc","--strategy=docker")
          /*  def bcSelector = openshift.selector( "bc", msName)
            def bcExists = bcSelector.exists()
            if (!bcExists) {
                openshift.newApp("redhat-openjdk18-openshift:1.1~${GIT_SOURCE_URL}","--strategy=dockerfile")
                sh 'sleep 400'
                openshiftTag(namespace: projectName, srcStream: msName, srcTag: 'latest', destStream: msName, destTag: 'test-apps')
                openshiftTag(namespace: projectName, srcStream: msName, srcTag: 'latest', destStream: msName, destTag: 'prod-apps')
            } else {
                sh 'echo build config already exists in development environment'  
            } */
        }
    }
}

def firstTimeTestDeployment(sourceProjectName,destinationProjectName,msName){
    openshift.withCluster() {
        openshift.withProject(destinationProjectName){
	    def dcSelector = openshift.selector( "dc", msName)
            def dcExists = dcSelector.exists()
	    if(!dcExists){
	    	openshift.newApp(sourceProjectName+"/"+msName+":"+"test-apps")   
	    }
            else {
                sh 'echo deployment config already exists in testing environment'  
            } 
        }
    }
}

def firstTimeProdDeployment(sourceProjectName,destinationProjectName,msName){
    openshift.withCluster() {
        openshift.withProject(destinationProjectName){
	    def dcSelector = openshift.selector( "dc", msName)
            def dcExists = dcSelector.exists()
	    if(!dcExists){
	    	openshift.newApp(sourceProjectName+"/"+msName+":"+"prod-apps")   
	    }
            else {
                sh 'echo deployment config already exists in production environment'  
            } 
        }
    }
}

def buildApp(projectName,msName){
    openshift.withCluster() {
        openshift.withProject(projectName){
            openshift.startBuild(msName,"--wait")   
        }
    }
}

def deployApp(projectName,msName){
    openshift.withCluster() {
        openshift.withProject(projectName){
            openshiftDeploy(namespace: projectName,deploymentConfig: msName)
             
        }
    }
}

podTemplate(cloud:'openshift',label: 'selenium', 
  containers: [
    containerTemplate(
      name: 'jnlp',
      image: 'cloudbees/jnlp-slave-with-java-build-tools',
      alwaysPullImage: true,
      args: '${computer.jnlpmac} ${computer.name}'
    )])
{
node 
{
   def MAVEN_HOME = tool "Maven_HOME"
   def JAVA_HOME = tool "JAVA_HOME"
   env.PATH="${env.PATH}:${MAVEN_HOME}/bin:${JAVA_HOME}/bin"
   
   stage('First Time Deployment'){
       
        readProperties()
       
       firstTimeDevDeployment("${APP_NAME}-dev-apps", "${MS_NAME}")
       /*  firstTimeTestDeployment("${APP_NAME}-dev-apps", "${APP_NAME}-test-apps", "${MS_NAME}")
        firstTimeProdDeployment("${APP_NAME}-dev-apps", "${APP_NAME}-prod-apps", "${MS_NAME}")*/
   }
   stage('Tagging Image for Testing'){
        openshiftTag(namespace: '$APP_NAME-dev-apps', srcStream: '$MS_NAME', srcTag: 'latest', destStream: '$MS_NAME', destTag: 'test')
   }
   stage('Checkout')
   {
       checkout([$class: 'GitSCM', branches: [[name: "*/${BRANCH}"]], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: '', url: "${GIT_SOURCE_URL}"]]])
   }

   stage('Initial Setup')
   {
       sh 'mvn clean compile'
   }

   stage('Code Quality Analysis')
   {
       sh 'mvn sonar:sonar -Dsonar.host.url="${SONAR_HOST_URL}"'
   }

   stage('Unit Testing')
   {
   
        sh 'chmod 777 ./mvnw'
        sh './mvnw test'
   }

   stage('Code Coverage')
   {
	sh 'mvn package'
jacoco(deltaBranchCoverage: '10', deltaClassCoverage: '10', deltaComplexityCoverage: '10', deltaInstructionCoverage: '10', deltaLineCoverage: '10', deltaMethodCoverage: '20')
   }

   stage('Security Scanning')
    {
        sh 'mvn findbugs:findbugs'
    }


  /* stage('Dev - Build Application')
   {
       buildApp("${APP_NAME}-dev-apps", "${MS_NAME}")
   }*/

   stage('Dev - Deploy Application')
   {
       deployApp("${APP_NAME}-dev-apps", "${MS_NAME}")
      sh script: $/
          oc patch deploymentconfig ${MS_NAME} -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject": "true"}}}}}' -n=${APP_NAME}-dev-apps
       /$
       
   }
		

   stage('Tagging Image for Testing')
   {
       openshiftTag(namespace: '$APP_NAME-dev-apps', srcStream: '$MS_NAME', srcTag: 'latest', destStream: '$MS_NAME', destTag: 'test-apps')
   }

   stage('Test - Deploy Application')
   {
       deployApp("${APP_NAME}-test-apps", "${MS_NAME}")
         sh script: $/
          oc patch deploymentconfig ${MS_NAME} -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject": "true"}}}}}' -n=${APP_NAME}-test-apps
       /$
   }
	
   node('selenium')
   {
	stage('Integration Testing')
	{
	    container('jnlp')
	    {
	         checkout([$class: 'GitSCM', branches: [[name: "*/${BRANCH}"]], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: '', url: "${GIT_SOURCE_URL}"]]])
		 sh 'mvn integration-test'
	    }
	 }
    }
	
    stage('Tagging Image for Testing')
    {
        openshiftTag(namespace: '$APP_NAME-dev-apps', srcStream: '$MS_NAME', srcTag: 'latest', destStream: '$MS_NAME', destTag: 'prod-apps')
    }	
    
    stage('Deploy to Production approval')
    {
       input "Deploy to Production Environment?"
    }
	
    stage('Prod - Deploy Application')
    {
       deployApp("${APP_NAME}-prod-apps", "${MS_NAME}")
          sh script: $/
          oc patch deploymentconfig ${MS_NAME} -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject": "true"}}}}}' -n=${APP_NAME}-prod-apps
         /$
    }	
 
}
}
