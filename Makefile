# BuildKit is a next generation container image builder. You can enable it using
# an environment variable or using the Engine config, see:
# https://docs.docker.com/develop/develop-images/build_enhancements/#to-enable-buildkit-builds
export DOCKER_BUILDKIT=1

GIT_TAG ?= $(shell git rev-parse --short HEAD)
ifeq ($(GIT_TAG),)
	GIT_TAG=latest
endif

FRONTEND_IMG = metcalfc/timestamper:${GIT_TAG}
REGISTRY_ID ?= 175142243308
DOCKER_PUSH_REPOSITORY=dkr.ecr.us-west-2.amazonaws.com

# Local development happens here!
# This starts your application and bind mounts the source into the container so
# that changes are reflected in real time.
# Once you see the message "Running on http://0.0.0.0:5000/", open a Web browser at
# http://localhost:5000
.PHONY: dev
all: dev
dev: secret.txt
	@COMPOSE_DOCKER_CLI_BUILD=1 docker-compose -f docker-compose.yml up --build

create-ecr:
	aws ecr create-repository --repository-name ${FRONTEND_IMG}

build-image:
	docker --context default build -t $(REGISTRY_ID).$(DOCKER_PUSH_REPOSITORY)/$(FRONTEND_IMG) ./app
	docker --context default build -t $(FRONTEND_IMG) ./app

push-image-ecr:
	aws ecr get-login-password --region us-west-2 | docker login -u AWS --password-stdin $(REGISTRY_ID).$(DOCKER_PUSH_REPOSITORY)
	docker --context default push $(REGISTRY_ID).$(DOCKER_PUSH_REPOSITORY)/$(FRONTEND_IMG)

push-image-hub:
	docker --context default push $(FRONTEND_IMG)

deploy: secret.txt push-image-hub
	docker --context ecs compose up

convert:
	docker --context ecs compose convert

clean:
	@docker-compose rm -f || true
	@docker rmi ${FRONTEND_IMG}
