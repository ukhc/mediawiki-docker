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

## Kubernetes deployment to the local workstation (macOS only)

## Prep your local workstation (macOS only)
1. Clone this repo and work in it's root directory
1. Install Docker Desktop for Mac (https://www.docker.com/products/docker-desktop)
1. In Docker Desktop > Preferences > Kubernetes, check 'Enable Kubernetes'
1. Click on the Docker item in the Menu Bar. Mouse to the 'Kubernetes' menu item and ensure that 'docker-for-desktop' is selected.


## Deploy and development workflow
The basic workflow is... 
1. Deploy MediaWiki without a persistent volume so you can create a basic configuration
1. Create a backup of that basic configuration
1. Re-deploy WordPress with a persistent volume and restore from the backup
1. Congratulations, you now have a working MediaWiki environment with a persistent volume

From here you can make whatever changes you like to MediaWiki.  You can access the persistent volume on your local drive `/Users/Shared/Kubernetes/persistent-volumes/default/mediawiki`.  You can create more backups for point in time restores.  There's even a script that makes it easy to restart the MediaWiki deployment.  When you're all done, there is a delete script that will remove the deployment and the persistent volume but don't worry... as long as you have a backup, you can re-deploy and restore to the state where you left off.


NOTE: Run the following commands from the root folder of this repo.

### Deploy a new MediaWiki without persistent volumes along with a new MariaDB
~~~
./local-apply.sh
~~~

Use this to do the initial installation and configuration for MediaWiki.  Once you are satisfied with the setup, you can back it up.


Use these MariaDB values:
- hostname: mariadb
- user: root
- password: admin
- database name: mediawiki


Note: When you have completed the install, you will be given a file called `LocalSettings.php`.  Save this file for an upcoming step.


### Create a backup of the persistent volume and database
~~~
./local-backup.sh
~~~

This backs up the html folder as well as the database. The backup will be created in the 'backup' folder in this repo. You can take multiple backups.


Note: You can now copy the `LocalSettings.php` file into the `./backup/YOURBACKUPFOLDER/html` folder.


### Delete the deployment
~~~
./local-delete.sh
~~~

Once you have a backup that you are happy with, delete the deployment so you can deploy MediaWiki again but this time with persistent volumes.


### Deploy MediaWiki with persistent volumes along with a new MariaDB
~~~
./local-apply.sh --with-volumes
~~~

When the persistent volume is mounted, it will be empty.  The new MariaDB will also have no data.  Once this deployment is complete, restore from one of your backup folders to populate the persistent volume as well as the database.


Persistent data is stored here: `/Users/Shared/Kubernetes/persistent-volumes/default/mediawiki`


### Restore from backup (pass it the backup folder name and the restore mode --restore-all, --restore-database, or --restore-files)
~~~
./local-restore.sh 2019-10-31_20-05-55 --restore-all
~~~

Restore from one of your backup folders to populate the html folder as well as the database.  The backups are stored in the 'backup' folder in this repo.


### Restart the deployment
~~~
./local-restart.sh
~~~

Some changes may require a restart of the containers.  This script will do that for you.


### Scale the deployment
~~~
kubectl scale --replicas=4 deployment/mediawiki
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