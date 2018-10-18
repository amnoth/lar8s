FROM node:10.11.0-alpine

COPY . /app
RUN chmod -R 777 /app

WORKDIR /app
ENTRYPOINT ["laravel-echo-server", "start"]
