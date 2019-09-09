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

echo "stop the mediawiki deployment..."
kubectl scale --replicas=0 deployment mediawiki

echo "stop the mariadb deployment..."
kubectl scale --replicas=0 deployment mariadb

echo "wait a moment..."
sleep 5

##########################

echo "start the mariadb deployment..."
kubectl scale --replicas=1 deployment mariadb

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

echo "start the mediawiki deployment..."
kubectl scale --replicas=1 deployment mediawiki

##########################

# wait for mediawiki
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

echo
echo "...done"