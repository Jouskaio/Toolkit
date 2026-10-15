# Cheatsheet Docker - Basic commands

## Containers

| Topic     | Command | Command details                         | Description                                                    |
|-----------|---------|-----------------------------------------|----------------------------------------------------------------|
| list      | ps      | `docker ps`                             | Running containers                                             |
| list      | ps      | `docker ps -a`                          | All containers, stopped ones too                               |
| run       | run     | `docker run -d --name web -p 8080:80 nginx` | Start a container in the background, port 8080 -> 80       |
| run       | run     | `docker run --rm -it alpine sh`         | Throw-away interactive shell, deleted on exit                  |
| run       | run     | `docker run -v $(pwd):/data alpine ls /data` | Mount the current folder in the container                 |
| lifecycle | stop    | `docker stop web` / `docker start web`  | Stop or start a container                                      |
| lifecycle | restart | `docker restart web`                    | Restart a container                                            |
| lifecycle | rm      | `docker rm -f web`                      | Delete a container, even a running one                         |
| inspect   | logs    | `docker logs -f --tail 100 web`         | Follow the last 100 lines of the logs                          |
| inspect   | exec    | `docker exec -it web sh`                | Open a shell in a running container                            |
| inspect   | stats   | `docker stats`                          | CPU and memory of the running containers                       |
| inspect   | inspect | `docker inspect web`                    | Full configuration of a container as JSON                      |

## Images

| Topic | Command | Command details                  | Description                                  |
|-------|---------|----------------------------------|----------------------------------------------|
| list  | images  | `docker images`                  | Images on this machine                       |
| build | build   | `docker build -t myapp:1.0 .`    | Build an image from the Dockerfile here      |
| pull  | pull    | `docker pull nginx:alpine`       | Download an image                            |
| push  | push    | `docker push ghcr.io/me/app:1.0` | Send an image to a registry                  |
| clean | rmi     | `docker rmi myapp:1.0`           | Delete an image                              |

## Compose

| Topic   | Command | Command details                     | Description                                          |
|---------|---------|-------------------------------------|------------------------------------------------------|
| up      | compose | `docker compose up -d`              | Create and start the services in the background      |
| up      | compose | `docker compose up -d --build`      | Rebuild the images first                             |
| down    | compose | `docker compose down`               | Stop and delete the services (volumes are kept)      |
| inspect | compose | `docker compose logs -f web`        | Follow the logs of the service `web`                 |
| inspect | compose | `docker compose ps`                 | State of the services                                |
| update  | compose | `docker compose pull && docker compose up -d` | Fetch newer images and restart what changed |

## Clean up

| Topic  | Command | Command details               | Description                                                              |
|--------|---------|-------------------------------|--------------------------------------------------------------------------|
| space  | system  | `docker system df`            | Disk used by images, containers and volumes                              |
| clean  | prune   | `docker system prune`         | Delete stopped containers, unused networks and dangling images           |
| clean  | prune   | `docker image prune -a`       | Also delete every image that no container uses                           |
| clean  | prune   | `docker volume prune`         | Delete the volumes no container uses (**data is lost**: check first)     |
