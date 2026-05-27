# ============================================================
# Project   : 티켓팅 보안관제
# Image     : ticketing-app
# Base      : Tomcat 9 (Servlet 4.0, JDK 11)
# Purpose   : DMZ Zone Docker Host VM에서 실행
# Build     : docker build -t ticketing-app:1.0 .
# Run       : docker run -d -p 8080:8080 \
#                        -v ticketing-logs:/var/log/ticketing/security \
#                        --name ticketing ticketing-app:1.0
# ============================================================

# Multi-stage build: Maven으로 WAR 빌드 후 Tomcat에 배포
# Stage 1: Build
FROM maven:3.8.6-eclipse-temurin-11 AS builder

WORKDIR /build
COPY pom.xml .
# 의존성만 먼저 다운로드 (캐싱 활용)
RUN mvn dependency:go-offline -B

COPY src ./src
RUN mvn clean package -DskipTests -B

# Stage 2: Runtime
FROM tomcat:9.0-jdk11-temurin

# 한글 / UTF-8 처리
ENV LANG=ko_KR.UTF-8 \
    LC_ALL=ko_KR.UTF-8 \
    JAVA_OPTS="-Dfile.encoding=UTF-8 -Dconsole.encoding=UTF-8 -DLOG_HOME=/var/log/ticketing/security"

# Tomcat 기본 webapps 제거 (보안)
RUN rm -rf /usr/local/tomcat/webapps/*

# 로그 디렉토리 생성 (Splunk Forwarder 가 마운트할 경로)
RUN mkdir -p /var/log/ticketing/security && \
    chmod 755 /var/log/ticketing/security

# WAR 배포 - ROOT.war 로 배치하면 컨텍스트 경로 없이 / 로 접근 가능
COPY --from=builder /build/target/stu.war /usr/local/tomcat/webapps/ROOT.war

# Tomcat server.xml 의 Connector URIEncoding 을 UTF-8 로
RUN sed -i 's|<Connector port="8080"|<Connector port="8080" URIEncoding="UTF-8"|' \
    /usr/local/tomcat/conf/server.xml

EXPOSE 8080

# 로그 디렉토리를 외부 볼륨으로 (Splunk Forwarder 가 접근)
VOLUME ["/var/log/ticketing/security"]

# 헬스체크 - 보안 관제에서 컨테이너 상태 모니터링
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/main.do || exit 1

CMD ["catalina.sh", "run"]
