# Copyright (c) 2019, UK HealthCare (https://ukhealthcare.uky.edu) All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


##########################

echo "ensure the correct environment is selected..."
KUBECONTEXT=$(kubectl config view -o template --template='{{ index . "current-context" }}')
if [ "$KUBECONTEXT" != "docker-desktop" ]; then
	echo "ERROR: Script is running in the wrong Kubernetes Environment: $KUBECONTEXT"
	exit 1
else
	echo "Verified Kubernetes context: $KUBECONTEXT"
fi

##########################

echo "setup the persistent volume for mariadb...."
mkdir -p /Users/Shared/Kubernetes/persistent-volumes/default/mariadb
kubectl apply -f https://raw.githubusercontent.com/ukhc/mariadb-docker/master/kubernetes/mariadb-single-local-pv.yaml

##########################

echo "deploy mariadb...."
kubectl apply -f https://raw.githubusercontent.com/ukhc/mariadb-docker/master/kubernetes/mariadb-single.yaml

echo "wait for mariadb..."
sleep 2
isPodReady=""
isPodReadyCount=0
until [ "$isPodReady" == "true" ]
do
	isPodReady=$(kubectl get pod -l app=mariadb -o jsonpath="{.items[0].status.containerStatuses[*].ready}")
	if [ "$isPodReady" != "true" ]; then
		((isPodReadyCount++))
		if [ "$isPodReadyCount" -gt "100" ]; then
			echo "ERROR: timeout waiting for mariadb pod. Exit script!"
			exit 1
		else
			echo "waiting...mariadb pod is not ready...($isPodReadyCount/100)"
			sleep 2
		fi
	fi
done

##########################

echo "setup the persistent volume for mediawiki...."
mkdir -p /Users/Shared/Kubernetes/persistent-volumes/default/mediawiki
kubectl apply -f ./kubernetes/mediawiki-local-pv.yaml

##########################

echo "deploy php config configmap..."
kubectl apply -f ./kubernetes/mediawiki-php-config.yaml

##########################

echo "deploy mediawiki..."
rm -f yaml.tmp
cp ./kubernetes/mediawiki.yaml yaml.tmp

#### Use the '--with-volumes' parameter to turn on the volume mounts ####
if [ "$1" == "--with-volumes" ]
then
    echo "--with-volumes parameter was used, turning on the persistent volumes..."
	sed -i '' 's/#persistent-storage#//' yaml.tmp
else
    echo "--with-volumes parameter was not used, persistent volumes are off..."
fi

kubectl apply -f yaml.tmp
rm -f yaml.tmp

echo "wait for mediawiki..."
sleep 2
isPodReady=""
isPodReadyCount=0
until [ "$isPodReady" == "true" ]
do
	isPodReady=$(kubectl get pod -l app=mediawiki -o jsonpath="{.items[0].status.containerStatuses[*].ready}")
	if [ "$isPodReady" != "true" ]; then
		((isPodReadyCount++))
		if [ "$isPodReadyCount" -gt "100" ]; then
			echo "ERROR: timeout waiting for mediawiki pod. Exit script!"
			exit 1
		else
			echo "waiting...mediawiki pod is not ready...($isPodReadyCount/100)"
			sleep 2
		fi
	fi
done

##########################

echo "opening the browser..."
open http://127.0.0.1

##########################

echo "...done"