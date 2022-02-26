# all: all-test export-all-coverage

ns := home-apps

build_registry:
	kubectl apply -f registry/registry-certs-configmap.yml
	kubectl apply -f registry/registry-service.yml
	kubectl apply -f registry/registry-deployment.yml

build_ns:
	kubectl apply -f namespace/namespace.yml

build: build_ns build_certs build_registry

build_certs:
	kubectl create configmap home-certs -n ${ns} \
	--from-file=certs/certs.d/fullchain.pem \
	--from-file=certs/certs.d/privatekey.pem \
	--dry-run -o yaml | tee certs/home-certs-configmap.yml
