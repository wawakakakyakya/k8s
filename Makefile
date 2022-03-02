# all: all-test export-all-coverage

ns := home-apps
com := apply

build_registry:
	kubectl ${com} -f registry/registry-service.yml
	kubectl ${com} -f registry/registry-deployment.yml

build_ns:
	kubectl ${com} -f namespace/namespace.yml

build: build_ns build_certs build_registry

build_certs:
	kubectl create configmap home-certs -n ${ns} \
	--from-file=certs/certs.d/fullchain.pem \
	--from-file=certs/certs.d/privatekey.pem \
	--dry-run -o yaml | tee certs/home-certs-configmap.yml
	kubectl ${com} -f certs/home-certs-configmap.yml

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
