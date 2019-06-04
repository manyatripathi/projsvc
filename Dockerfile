FROM openjdk:8-jre-alpine
ENV APP_FILE projsvc-0.0.1-SNAPSHOT.jar
ENV APP_HOME /usr/app
EXPOSE 8080
COPY target/$APP_FILE $APP_HOME/
COPY jmx_prometheus_javaagent-0.11.0.jar $APP_HOME/
COPY sample_config.yml $APP_HOME/
RUN chmod -R 0777 $APP_HOME/
RUN ls -la /usr/app
WORKDIR $APP_HOME
CMD java -javaagent:/usr/app/jmx_prometheus_javaagent-0.11.0.jar=8088:/usr/app/sample_config.yml -jar $APP_FILE
