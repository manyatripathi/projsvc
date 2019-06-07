FROM jamesdbloom/docker-java8-maven as BUILD
COPY . /usr/src/app/
RUN mvn -f /usr/src/app/pom.xml clean package
FROM openjdk:8-jre-alpine
COPY --from=build /usr/src/app/jmx_prometheus_javaagent-0.11.0.jar /usr/app/jmx_prometheus_javaagent-0.11.0.jar
COPY --from=build /usr/src/app/target/projsvc-0.0.1-SNAPSHOT.jar /usr/app/projsvc-0.0.1-SNAPSHOT.jar
ENV APP_FILE projsvc-0.0.1-SNAPSHOT.jar
ENV APP_HOME /usr/app
EXPOSE 8080
COPY target/$APP_FILE $APP_HOME/
#COPY jmx_prometheus_javaagent-0.11.0.jar $APP_HOME/
COPY sample_config.yml $APP_HOME/
WORKDIR $APP_HOME
CMD java -javaagent:/usr/app/jmx_prometheus_javaagent-0.11.0.jar=8088:/usr/app/sample_config.yml -jar $APP_FILE
