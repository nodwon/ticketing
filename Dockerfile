FROM mcr.microsoft.com/openjdk/jdk:21-ubuntu
VOLUME /tmp
ARG JAVA_OPTS
ENV JAVA_OPTS=$JAVA_OPTS
COPY target/stu-1.0.0-BUILD-SNAPSHOT.jar code.jar
EXPOSE 3000
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar code.jar"]
# For Spring-Boot project, use the entrypoint below to reduce Tomcat startup time.
#ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar code.jar"]
