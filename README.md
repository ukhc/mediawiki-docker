# MediaWiki for Docker

## Reference
- https://hub.docker.com/_/mediawiki
- https://github.com/wikimedia/mediawiki-containers/blob/master/mediawiki-dev.yaml
- https://github.com/bitnami/charts/blob/master/upstreamed/mediawiki/templates/deployment.yaml

## Build the image
~~~
VERSION=$(cat version)
docker build -t 127.0.0.1:30500/internal/mediawiki:$VERSION . --no-cache
~~~

## Docker deployment to the local workstation

~~~
# start the container
VERSION=$(cat version)
docker run --name mediawiki -p 8080:80 -d 127.0.0.1:30500/internal/mediawiki:$VERSION

# see the status
docker container ls

# open the url
open http://127.0.0.1:8080

# destroy the container
docker container stop mediawiki
docker container rm mediawiki
~~~

## Create a deployable configuration

1. Comment out the volumeMounts and volumes in the mediawiki.yaml file
1. Deploy MediaWiki with a MariaDB
1. Run through the install wizard
1. When you are complete, save the LocalSettings.php file
1. Save the /var/www/html folder from your pod
~~~
POD=$(kubectl get pod -l app=mediawiki -o jsonpath="{.items[0].metadata.name}")
mkdir -p mediawiki-html/html
kubectl cp $POD:/var/www/html mediawiki-html/html
~~~
1. Copy the LocalSettings.php file into the ./html folder on your drive
1. Maybe tar the folder `tar czf mediawiki-html.tar.gz mediawiki-html`
1. Export the database
~~~
POD=$(kubectl get pod -l app=mediawiki -o jsonpath="{.items[0].metadata.name}")
kubectl exec -it $POD -- /usr/bin/mysqldump -u root -padmin mediawiki > mediawiki-dump.sql
~~~
1. Destroy your environment
1. Uncomment the volumeMounts and volumes in the mediawiki.yaml file
1. Deploy MariaDB
1. Restore the mediawiki database
1. Deploy MediaWiki
1. Restore the html folder (untar if needed `tar xvzf mediawiki-html.tar.gz`)
~~~
POD=$(kubectl get pod -l app=mediawiki -o jsonpath="{.items[0].metadata.name}")
kubectl cp mediawiki-html/html $POD:/var/www
~~~


## Kubernetes deployment to the local workstation (macOS only)

## Prep your local workstation (macOS only)
1. Clone this repo and work in it's root directory
1. Install Docker Desktop for Mac (https://www.docker.com/products/docker-desktop)
1. In Docker Desktop > Preferences > Kubernetes, check 'Enable Kubernetes'
1. Click on the Docker item in the Menu Bar. Mouse to the 'Kubernetes' menu item and ensure that 'docker-for-desktop' is selected.


## Deploy
Before you deploy, you will need a running instance of MariaDB in Kubernetes: https://github.com/ukhc/mariadb-docker


Deploy (run these commands from the root folder of this repo)
~~~
./local-apply.sh
~~~

Note: The default admin password is admin

Delete
~~~
./local-delete.sh
~~~