# === Giai đoạn build ===
FROM eclipse-temurin:21-jdk AS build
WORKDIR /app

# Copy file pom.xml và tải dependencies
COPY pom.xml .
RUN apt-get update && apt-get install -y maven && mvn dependency:go-offline -B

# Copy mã nguồn và build jar
COPY src ./src
RUN mvn clean package -DskipTests

# === Giai đoạn chạy ===
FROM eclipse-temurin:21-jdk
WORKDIR /app
COPY --from=build /app/target/PostService-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8082
ENTRYPOINT ["java", "-jar", "app.jar"]
