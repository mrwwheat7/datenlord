#! /bin/sh

set -o errexit
set -o nounset
set -o xtrace

if [ "$1" == "helm" ]
then
    kubectl create namespace datenlord-monitoring 
    helm repo add stable https://charts.helm.sh/stable
    helm install prometheus stable/prometheus-operator --namespace datenlord-monitoring 
    helm repo add elastic https://helm.elastic.co
    helm install filebeat elastic/filebeat
    helm install kibana elastic/kibana
    helm install elasticsearch elastic/elasticsearch -f values.yaml
    kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=grafana -n datenlord-monitoring --timeout=60s
    kubectl wait --for=condition=Ready pod -l app=elasticsearch-master --timeout=120s
    kubectl wait --for=condition=Ready pod -l app=kibana --timeout=120s
    POD_NAME=`kubectl get pods -l app.kubernetes.io/name=grafana | grep grafana | awk '{print $1}'`
    kubectl port-forward $POD_NAME 3000 -n datenlord-monitoring
else
    kubectl apply -f datenlord-logging.yaml
    kubectl apply -f datenlord-monitor.yaml
    kubectl wait --for=condition=Ready pod -l app=prometheus-server -n datenlord-monitoring --timeout=60s
    kubectl wait --for=condition=Ready pod -l app=grafana -n datenlord-monitoring --timeout=60s
    kubectl wait --for=condition=Ready pod -l app=kibana -n datenlord-logging --timeout=120s
    kubectl wait --for=condition=Ready pod -l app=elasticsearch -n datenlord-logging --timeout=120s
    POD_NAME=`kubectl get pods -l app=grafana -n datenlord-monitoring | grep grafana | awk '{print $1}'`
    kubectl port-forward $POD_NAME 3000 -n datenlord-monitoring
fi