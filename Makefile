# all: all-test export-all-coverage

ns := home-apps
com := apply
network := 10.0.0.0/24

setup:
	$(MAKE) init
	$(MAKE) flannel
	$(MAKE) pod_on_master

init:
	kubeadm init
	# kubeadm init --pod-network-cidr=${network}
	mkdir -p ${HOME}/.kube
	sudo cp -i /etc/kubernetes/admin.conf ${HOME}/.kube/config
	sudo chown $(id -u):$(id -g) ${HOME}/.kube/config

flannel:
	curl -L https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml -o /etc/kubernetes/manifests/flannel.yml
	kubectl apply -f /etc/kubernetes/manifests/flannel.yml

pod_on_master:
	kubectl taint nodes ${HOSTNAME} node-role.kubernetes.io/master:NoSchedule-

reset:
	kubeadm reset

build_ns:
	kubectl ${com} -f namespace/namespace.yml

build: build_ns build_certs build_registry

build_certs:
	kubectl create configmap home-certs -n ${ns} \
	--from-file=certs/certs.d/fullchain.pem \
	--from-file=certs/certs.d/privatekey.pem \
	--dry-run -o yaml | tee certs/home-certs-configmap.yml
	kubectl ${com} -f certs/home-certs-configmap.yml

build_registry: build_ns build_certs
	kubectl ${com} -f registry/registry-service.yml
	kubectl ${com} -f registry/registry-deployment.yml

build_secret:
	kubectl create secret generic dotenv --from-env-file=.env --dry-run=client -o yaml | tee secrets/dotenv-secret.yml
	kubectl apply -f secrets/dotenv-secret.yml

build_ntp:
	kubectl create configmap ntp-conf -n ${ns} \
	--from-file=ntp/chrony.conf \
	--dry-run -o yaml | tee ntp/ntp-conf-configmap.yml
	kubectl ${com} -f ntp/ntp-conf-configmap.yml
	kubectl ${com} -f ntp/ntp-service.yml
	kubectl ${com} -f ntp/ntp-deployment.yml

build_dns:
	kubectl create configmap dns-conf -n ${ns} \
	--from-file=dns/conf.d/Corefile \
	--from-file=dns/conf.d/hosts \
	--dry-run -o yaml | tee dns/dns-conf-configmap.yml
	kubectl ${com} -f dns/dns-conf-configmap.yml
	kubectl ${com} -f dns/dns-service.yml
	kubectl ${com} -f dns/dns-deployment.yml

build_mysql: build_secret
	kubectl create configmap mysql-conf -n ${ns} \
	--from-file=mysql/my.cnf \
	--dry-run -o yaml | tee mysql/mysql-conf-configmap.yml
	kubectl create secret generic initdb-d --from-file=mysql/initdb.d/initdb.sql \
	--dry-run=client -o yaml | tee mysql/initdb-secret.yml
	kubectl ${com} -f mysql/initdb-secret.yml
	kubectl ${com} -f mysql/mysql-conf-configmap.yml
	kubectl ${com} -f mysql/mysql-service.yml
	kubectl ${com} -f mysql/mysql-deployment.yml

build_dhcp:
	kubectl create configmap dhcp-conf -n ${ns} \
	--from-file=dhcp/dhcpd.conf \
	--dry-run -o yaml | tee dhcp/dhcp-conf-configmap.yml
	kubectl ${com} -f dhcp/dhcp-conf-configmap.yml
	kubectl ${com} -f dhcp/dhcp-service.yml
	kubectl ${com} -f dhcp/dhcp-deployment.yml
