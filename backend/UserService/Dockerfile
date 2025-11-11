# Sử dụng OpenJDK 21
FROM openjdk:21-jdk-slim AS build
WORKDIR /app

# Copy file pom và cài dependency
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy mã nguồn và build jar
COPY src ./src
RUN mvn clean package -DskipTests

# Giai đoạn chạy
FROM openjdk:21-jdk-slim
WORKDIR /app
COPY --from=build /app/target/UserService-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8082
ENTRYPOINT ["java", "-jar", "app.jar"]
