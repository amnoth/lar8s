#!/bin/bash

kubectl apply -f docker-registry-secrets.yaml

cd app
kubectl apply -f autoscaler.yaml -f secrets.yaml -f volume.yaml

cd ..
cd laravel-echo-server
kubectl apply -f config.yaml -f service.yaml -f ingress.yaml

cd ..
cd mongodb
kubectl apply -f secrets.yaml -f service.yaml -f volume.yaml

cd ..
cd nginx
kubectl apply -f config.yaml -f service.yaml -f ingress.yaml

cd ..
cd redis
kubectl apply -f config.yaml -f service.yaml -f volume.yaml

cd ..
kubectl apply -f app/deployment.yaml -f laravel-echo-server/deployment.yaml \
              -f listener/deployment.yaml -f mongodb/deployment.yaml -f redis/deployment.yaml \
              -f horizon/deployment.yaml

kubectl apply -f app/cronjob.yaml