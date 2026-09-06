FROM eclipse-temurin:17-jdk-ubi9-minimal

WORKDIR /opt/app

RUN microdnf install -y shadow-utils && \
    useradd --system --create-home --uid 10001 appuser && \
    microdnf clean all

COPY --chown=appuser:appuser \
    build/libs/bootcamp-java-mysql-project-1.0-SNAPSHOT.jar \
    /opt/app/app.jar

EXPOSE 8080 8081

USER appuser

ENTRYPOINT ["java", "-jar", "/opt/app/app.jar"]