# 1️⃣ Sử dụng image Maven + JDK 21 để build
FROM maven:3.9.3-eclipse-temurin-21 AS build

# Set working directory
WORKDIR /app

# Copy pom.xml và download dependencies (caching layer)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy toàn bộ source code
COPY src ./src

# Build project
RUN mvn clean package -DskipTests

# 2️⃣ Sử dụng image JDK 21 để chạy JAR
FROM eclipse-temurin:21-jre

# Set working directory
WORKDIR /app

# Copy JAR từ stage build
COPY --from=build /app/target/PostService-0.0.1-SNAPSHOT.jar app.jar

# Expose port Spring Boot
EXPOSE 8081

# Command to run the app
ENTRYPOINT ["java", "-jar", "app.jar"]
