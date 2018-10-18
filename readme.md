[![Build Status](https://travis-ci.org/rennokki/lar8s.svg?branch=master)](https://travis-ci.org/rennokki/lar8s)

[![PayPal](https://img.shields.io/badge/PayPal-donate-blue.svg)](https://paypal.me/rennokki)

# Lar8s
Lar8s is your scaffolded Kubernetes configuration to deploy Laravel Echo Server with Echo Server and Horizon. The configuration comes with MongoDB, PostgreSQL and Redis to enjoy the Homestead-like environment in Kubernetes.

# Special thanks
It's good to mention [edbizarro's gitlab-ci-pipeline-php](https://github.com/edbizarro/gitlab-ci-pipeline-php) repo that contains Dockerfiles for PHP images. They're good for CI/CD or running Laravel apps with them. This project is based on those images.

# Project files
The project contains three main folders:
* `kubernetes/` - all the config files are here.
* `laravel/` - this is where the Laravel app is.
* `laravel-echo-server/` - this is where Laravel Echo Server sits.

Don't worry, your project structure will not be like this.

# Docker Registry
To be able to containerize your application, and deploy it, you should be using a Container Registry. There are a dozen of Container Registry services, such as Gitlab Container Registry, DockerHub or Google Container Registry. Feel free to choose any of them.

# Project structure
First of all, the `Dockerfile` inside `laravel/` should stay in the root of your Laravel application. It will copy all the files in the image. What you want to do here is to build the container **after** you have installed/updated all your dependencies (composer and/or npm). The dependencies will come along with your project file in the container and they'll be available when running in Kubernetes.

Also, you'll want to put everything in the `laravel-echo-server/` to a separate repository, including `Dockerfile`. That Dockerfile will build your Node environment so Laravel Echo Server will run inside it. It's straightforward and easy.

# Automating the updates
The config files of Kubernetes will also stay in a separate repository. It's the best to automate the process in a different repo. Think about your updates like `tag` commits, no longer `git push` to master.

When you detect tag creations, either it's your Laravel app repo or Laravel Echo Server repo, run the dependecy install process, build your image with the tag name as Docker image tag, push it to the registry and test your container. If everything passed, you should be triggering the next action: automating the Kubernetes config files edit.

In this CI/CD step, you'll want to pull the repository containing the Kubernetes configuration files with GIT, checkout to a new branch, edit them with `sed` command and then commit & push to the repository. Additionally, if your GIT provider is supporting Merge/Pull Requests creation, you should `curl` that endpoint with your secret token and create a Merge/Pull Request with those changes. Then you'll manually accepting them. It's easy, right? You'll know what version to put since you're in the same CI/CD process, you'll manually approve those changes in a separate branch on the Kubernetes' config repository.

What happens then, in the CI/CD of the Kubernetes' config repository is that after the MR/PR takes place, you want to connect to the cluster and apply the changes. Also, make sure your configuration files are good to go, either you're pushing to branch or after a MR/PR. You'll find a `deploy.sh` bash script that will run all your files in the correct order if you want to deploy your app to the cluster. To run tests, add `--dry-run` after each `kubectl apply` command. That'll test the config file and return non-zero exit code if the YAML is wrong.

# Building Laravel image
To create an image with your Laravel app, run this in the Laravel project root, with Dockerfile copied from `laravel/`. Make sure you have access to the registry you're pushing to.
```bash
$ docker build . -t yourname/laravel-app:1.0.0
```

And then push it to the registry:
```bash
$ docker push yourname/laravel-app:1.0.0
```

You'll find `<your_name>/<your_app_image>:<tag>` in:
* `app/deployment.yaml`
* `app/cronjob.yaml`
* `horizon/deployment.yaml`

Change them with your own image built before. That'd should be: `yourname/laravel-app:1.0.0`

# Building Laravel Echo image
Just the same, but go into the project containing the Dockerfile and `laravel-echo-server.json`:
```bash
$ docker build . -t yourname/laravel-echo-server:1.0.0
$ docker push yourname/laravel-echo-server:1.0.0
```

You'll find the image name in:
* `laravel-echo-server/deployment.yaml`

# Configuring Secrets
In each `secrets.yaml` files you'll find secrets. They're injected as environment variables. Note that your `.env` file just turned into an `app/secrets.yaml` file.

# Customizing Deployment
Each time a new tag appears, your images will have their tag changed and pushed to the repo. When updating, your containers will be destroyed one-by-one. The process is simple: a new container is created, an old container is destroyed. And so on. You'll end up with new containers in the end. You can change the number of containers to be created/destroyed on each run.

In each `deployment.yaml` file you'll find this kind of configuration, but only when `strategy` will contain `rollingUpdate`:
```yaml
...
spec:
  ...
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
    type: RollingUpdate
...
```

This means that when deploying the update, will kill one container after a new container (with the newer image) is running. We do not want downtime, so we want `0` containers to be unavailable in the process.

# Customizing resource consumptions
What happens if you run out of memory? What if your database just needs more because all of a sudden, your users are using your Laravel app more than you expected? This is where the resource limits and requests takes over. You can set an amount of resources needed in order to start the container, and also set the maximum allowed resources that a certain pod can consume while it's active.

For example, your MySQL container should run only if a minimum of 1 CPU and 1 GB of RAM is available. Then, it's able to consume up to 8 GB of RAM and 8 CPUs. The point is, that if you set upper limits, you spare your application's availability. In case you don't set limits to your MySQL, it can go how much the server permits. It will reach a point when the CPU and Memory will be at 100% and your whole app throttles just because you allowed the MySQL to consume without limit. So, be kind and set limits:

```yaml
imagePullPolicy: Always
  resources:
    limits:
      cpu: 100m
      memory: 256Mi
    requests:
      cpu: 100m
      memory: 256Mi
```

`100m` is equivalent of 1 CPU. Remember: `limits` keeps your pod from over-taking on resources (that's the maximum it can consume), while `requests` are the lower limits: it cannot start if, in this example, 0.1 CPUs and 256 MB of RAM are not available.