PROJECT   := tinjis
SHA       := $$(git log -1 --pretty=%h)
BRANCH    := $$(git branch | grep \* | cut -d " " -f2)
DATETIME  := $(shell date -u +"%Y%m%d.%H%M%S")
NAME_PREFIX := tinjis-

ifeq ($(ENV), staging)
	DEPLOYMENT_TARGET    := staging
	DOCKER_IMAGE_PREFIX  := registry.pleo.io:5000/tinjis/
	DOCKER_REGISTRY_HOST := registry.pleo.io:5000
	NAME_SUFFIX          := -stg
	TAG                  := ${BRANCH}.${DATETIME}.${SHA}
else ifeq ($(ENV), production)
	DEPLOYMENT_TARGET    := production
	DOCKER_IMAGE_PREFIX  := registry.pleo.io/tinjis/
	DOCKER_REGISTRY_HOST := registry.pleo.io
	NAME_SUFFIX          := -prod
	TAG                  := ${BRANCH}.${DATETIME}.${SHA}
else
	DEPLOYMENT_TARGET    := development
	DOCKER_IMAGE_PREFIX  := rickbgs
	DOCKER_REGISTRY_HOST :=
	ENV                  := development
	NAME_SUFFIX          := -dev
	TAG                  := $(shell date -u +"%Y%m%d")
endif

PUSH_APPLICATIONS   = push-antaeus push-payments
DEPLOY_APPLICATIONS = deploy-antaeus deploy-payments

.PHONY: install-requirements-mac install-requirements-minikube remove-requirements-mac remove-requirements-minikube
.PHONY: build login test
.PHONY: setup update cleanup
.PHONY: $(PUSH_APPLICATIONS) push
.PHONY: $(DEPLOY_APPLICATIONS) deploy



# TODO: Currently it only covers Docker for Mac.
# Installs NGINX Ingress Controller.
install-requirements-mac:
	@echo "\033[0;34mInstalling Ingress NGINX...\033[0m"
	@kubectl config use-context docker-desktop
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.29.0/deploy/static/mandatory.yaml
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.29.0/deploy/static/provider/cloud-generic.yaml

# install-requirements-minikube:
# 	@echo "\033[0;34mInstalling Ingress NGINX...\033[0m"
# 	@minikube addons enable ingress

# Uninstall NGINX Ingress Controller.
# Should be used only if NGINX Ingress Controller was installed via `make install-requirements-mac`.
remove-requirements-mac:
	@echo "\033[0;34mUninstalling Ingress NGINX...\033[0m"
	@kubectl config use-context docker-desktop
	@kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.29.0/deploy/static/provider/cloud-generic.yaml 2>/dev/null || true
	@kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.29.0/deploy/static/mandatory.yaml 2>/dev/null || true

# remove-requirements-minikube:
# 	@echo "\033[0;34mUninstalling Ingress NGINX...\033[0m"
# 	@minikube addons disable ingress







# Build all images used by tinjis.
build:
	@echo "\033[0;34mBuilding images...\033[0m"
	@docker-compose build --force-rm --no-cache --no-rm --parallel --pull

# Log in to Docker registry so images can be pushed to it.
login:
	@echo "\033[0;34mLogging on the Docker Registry...\033[0m"
	@docker login ${DOCKER_REGISTRY_HOST}

# Run tests to ensure it's safe to push images.
test:
	@echo "\033[0;34mRunning tests...\033[0m"
	@docker-compose -f docker-compose.yml run --rm -e RAILS_ENV=test payments rspec

# Push specific image to Docker registry. The image will be prefixed with tinjis-.
$(PUSH_APPLICATIONS): build test
	@echo "\033[0;34mPushing $(subst push-,,$@)...\033[0m"
	@docker tag $(subst push-,,$@) \
				${DOCKER_IMAGE_PREFIX}/tinjis-$(subst push-,,$@):${TAG}
	@docker push ${DOCKER_IMAGE_PREFIX}/tinjis-$(subst push-,,$@):${TAG}

	@echo "\033[0;34mUpdating Kustomize...\033[0m"
	@cd kubernetes/overlays/${DEPLOYMENT_TARGET} \
			&& kustomize edit set image $(subst push-,,$@)=${DOCKER_IMAGE_PREFIX}/tinjis-$(subst push-,,$@):${TAG}

push: $(PUSH_APPLICATIONS)



# Creates all resources specific to this project.
# Ideal with new clusters or after a cleanup.
# FIXME: push has been commented out so people without access to the rickbgs/* repositories can run `make setup`.
setup: # push
	@echo "\033[0;34mCreating Kubernetes resources...\033[0m"
	@kubectl create namespace antaeus
	@kubectl create namespace payments
	@kustomize build ./kubernetes/overlays/${DEPLOYMENT_TARGET} | kubectl create --save-config -f -

# Updates all resources specific to this project.
# Ideal when changes other than image tags are made.
update:
	@echo "\033[0;34mUpdating Kubernetes resources...\033[0m"
	@kustomize build ./kubernetes/overlays/${DEPLOYMENT_TARGET} | kubectl apply -f -

# Removes all resources specific to this project.
# Ideal when changes other than image tags are made.
cleanup:
	@echo "\033[0;34mDestroying Kubernetes resources...\033[0m"
	@kustomize build ./kubernetes/overlays/${DEPLOYMENT_TARGET} | kubectl delete -f -
	@kubectl delete namespace payments
	@kubectl delete namespace antaeus



# (Pushes and) Deploy the image for Antaeus service.
# It also update the deployment files to keep track of changes.
deploy-antaeus: push-antaeus
	@echo "\033[0;34mDeploying Antaeus...\033[0m"
	@kubectl -n antaeus set image deployment.apps/${NAME_PREFIX}antaeus-api${NAME_SUFFIX} --record \
			api=${DOCKER_IMAGE_PREFIX}/tinjis-antaeus:${TAG}
	@kubectl -n antaeus rollout status deployment.apps/${NAME_PREFIX}antaeus-api${NAME_SUFFIX}

# (Pushes and) Deploy the image for Antaeus service.
# It also update the deployment files to keep track of changes.
deploy-payments: push-payments
	@echo "\033[0;34mDeploying Payments...\033[0m"
	@kubectl -n payments set image deployment.apps/${NAME_PREFIX}payments-api${NAME_SUFFIX} --record \
			api=${DOCKER_IMAGE_PREFIX}/tinjis-payments:${TAG}
	@kubectl -n payments rollout status deployment.apps/${NAME_PREFIX}payments-api${NAME_SUFFIX}

deploy: $(DEPLOY_APPLICATIONS)
	@sleep 5
