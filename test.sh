#!/bin/bash

kubectl apply -f docker-registry-secrets.yaml --dry-run

cd app
kubectl apply -f autoscaler.yaml -f secrets.yaml -f volume.yaml --dry-run

cd ..
cd laravel-echo-server
kubectl apply -f config.yaml -f service.yaml -f ingress.yaml --dry-run

cd ..
cd mongodb
kubectl apply -f secrets.yaml -f service.yaml -f volume.yaml --dry-run

cd ..
cd nginx
kubectl apply -f config.yaml -f service.yaml -f ingress.yaml --dry-run

cd ..
cd redis
kubectl apply -f config.yaml -f service.yaml -f volume.yaml --dry-run

cd ..
kubectl apply -f app/deployment.yaml -f laravel-echo-server/deployment.yaml \
              -f listener/deployment.yaml -f mongodb/deployment.yaml -f redis/deployment.yaml \
              -f horizon/deployment.yaml --dry-run

kubectl apply -f app/cronjob.yaml --dry-run