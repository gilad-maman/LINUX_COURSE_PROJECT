FROM openjdk:11

RUN apt-get update && apt-get install -y imagemagick

WORKDIR /app

COPY WatermarkAdder.java /app/

RUN javac WatermarkAdder.java

ENTRYPOINT ["java", "WatermarkAdder"]

CMD ["/app/images"]
