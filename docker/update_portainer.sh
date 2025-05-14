#/bin/bash

if [ $# -eq 0 ]; then
        echo "Erreur : Vous devez spécifier une version pour l'image Docker."
        echo "Usage: $0 <version>"
        exit 1
fi

docker stop portainer
docker rm portainer
docker pull portainer/portainer-ce:$1
docker run -d -p 9443:9443 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:$1
