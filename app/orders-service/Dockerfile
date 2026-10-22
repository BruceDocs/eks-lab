FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /src
COPY pom.xml .
RUN mvn -q -B dependency:go-offline
COPY src ./src
RUN mvn -q -B package -DskipTests

FROM eclipse-temurin:17-jre
ARG JMX_VER=1.0.1
# JMX Exporter java agent -> :9404/metrics
ADD --chmod=644 https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${JMX_VER}/jmx_prometheus_javaagent-${JMX_VER}.jar /opt/jmx_prometheus_javaagent.jar
COPY jmx-config.yaml /opt/jmx-config.yaml
COPY --from=build /src/target/orders-service.jar /app/app.jar
ENV JAVA_TOOL_OPTIONS="-javaagent:/opt/jmx_prometheus_javaagent.jar=9404:/opt/jmx-config.yaml -XX:MaxRAMPercentage=70"
EXPOSE 8080 9404
USER 1000
ENTRYPOINT ["java","-jar","/app/app.jar"]
