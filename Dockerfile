# Build stage
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:17-jre
WORKDIR /app

# Upgrade OpenSSL to fix CVE-2026-14456 (requires 3.5.8+)
RUN apt-get update && \
    apt-get install -y --only-upgrade openssl libssl3 adduser && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/*.jar app.jar
EXPOSE 8080

# Create non-root user
# Créer un utilisateur non-root
RUN groupadd -r appgroup && useradd -r -g appgroup -s /sbin/nologin -d /nonexistent appuser
RUN chown -R appuser:appgroup /app
USER appuser

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
