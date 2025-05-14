#/bin/bash

if [ $# -eq 0 ]; then
        echo "Erreur : Vous devez spécifier une version pour l'image Docker."
        echo "Usage: $0 <version>"
        exit 1
fi

docker stop portainer_agent
docker rm portainer_agent
docker pull portainer/agent:$1
docker run -d -p 9001:9001 --name portainer_agent --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes portainer/agent:$1
