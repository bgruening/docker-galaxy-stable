KOMPOSE_VERSION := $(shell kompose version 2>/dev/null)
MINIKUBE_VERSION := $(shell minikube version 2>/dev/null)

.cmd-kompose:
ifdef KOMPOSE_VERSION
	@echo "Using kompose version $(KOMPOSE_VERSION)"
else
	$(error "Executable kompose not found - please install")
endif

.cmd-minikube:
ifdef MINIKUBE_VERSION
	@echo "Using $(MINIKUBE_VERSION)"
else
	$(error "Executable minikube not found - please install")
endif

minikube-start: .cmd-minikube
	minikube start

minikube-build: .cmd-minikube
	minikube status
	eval \$(minikube docker-env) && cd .. && ./buildlocal.sh

convert: .cmd-kompose
	python convert.py

down: .cmd-kompose
	kompose -f docker-compose-for-kompose.yml down

up: .cmd-kompose
	#kompose -f docker-compose-for-kompose.yml up
	bash up_manual.sh

up_wo_pv:
	kompose -f docker-compose-for-kompose.yml up --emptyvols
