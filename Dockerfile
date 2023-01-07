FROM maven:3-eclipse-temurin-17-alpine AS deps

WORKDIR /app
COPY pom.xml /app

RUN mvn go-offline:resolve-dependencies

FROM maven:3-eclipse-temurin-17-alpine AS build

WORKDIR /app
COPY --from=deps /root/.m2/repository /root/.m2/repository
COPY . /app

RUN mvn package -DskipTests -o

FROM maven:3-eclipse-temurin-17-alpine AS dev

WORKDIR /app
COPY --from=deps /root/.m2/repository /root/.m2/repository
COPY ./docker-entrypoint.sh /docker-entrypoint.sh

RUN apk add inotify-tools
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

FROM eclipse-temurin:17.0.5_8-jdk-alpine AS release

LABEL maintainer="kishieel"
WORKDIR /app

COPY --from=build /app/target/app.jar /app/app.jar

RUN addgroup --system app && adduser -S -s /bin/false -G app app
RUN chown -R app:app /app

USER app
CMD ["java", "-jar", "app.jar"]
