FROM centos
ENV APP_FILE target/projsvc-0.0.1-SNAPSHOT.jar
ENV APP_HOME /usr/app
COPY . $APP_HOME/
WORKDIR $APP_HOME
RUN yum install maven -y
RUN mvn clean install
CMD java -javaagent:/usr/app/jmx_prometheus_javaagent-0.11.0.jar=8088:/usr/app/sample_config.yml -jar $APP_FILE
