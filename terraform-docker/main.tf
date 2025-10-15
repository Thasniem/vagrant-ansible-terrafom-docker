terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# ---------------- Quiz App ----------------
resource "docker_image" "quiz_app" {
  name = "quiz-app:latest"

  build {
    context    = "${path.module}/terraform-deployment"
    dockerfile = "Dockerfile"
  }

  triggers = {
    app_code = filesha256("/home/vagrant/terraform-docker/terraform-deployment/app.py")
  }

  keep_locally = false
}

resource "docker_container" "quiz_app" {
  name   = "quiz_app"
  image  = docker_image.quiz_app.image_id
  must_run = true
  restart  = "always"

  ports {
    internal = 8080
    external = 8080
  }

  networks_advanced {
    name = docker_network.app_network.name
  }

  lifecycle {
    replace_triggered_by  = [docker_image.quiz_app]
    create_before_destroy = false
  }
}

# ---------------- Nginx ----------------
resource "docker_image" "nginx_image" {
  name = "nginx:latest"
}

resource "docker_container" "nginx_container" {
  name   = "nginx_server"
  image  = docker_image.nginx_image.image_id
  must_run = true
  restart  = "always"

  ports {
    internal = 80
    external = 8081
  }

  networks_advanced {
    name = docker_network.app_network.name
  }
}

# ---------------- Redis ----------------
resource "docker_image" "redis_image" {
  name = "redis:latest"
}

resource "docker_container" "redis_container" {
  name   = "redis_server"
  image  = docker_image.redis_image.image_id
  must_run = true
  restart  = "always"

  ports {
    internal = 6379
    external = 6379
  }

  networks_advanced {
    name = docker_network.app_network.name
  }
}

# ---------------- Network ----------------
resource "docker_network" "app_network" {
  name = "app_network"
}
