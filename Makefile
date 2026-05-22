CLUSTER ?= skillpulse-dev
NAMESPACE ?= skillpulse
AWS_REGION ?= ap-south-1
ACCOUNT_ID ?= 486036174293

BACKEND_IMAGE ?= $(ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/skillpulse-backend:latest
FRONTEND_IMAGE ?= $(ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/skillpulse-frontend:latest

.PHONY: build push apply status logs restart destroy

build:
	docker build -t $(BACKEND_IMAGE) ./backend
	docker build -t $(FRONTEND_IMAGE) ./frontend

push:
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
	docker push $(BACKEND_IMAGE)
	docker push $(FRONTEND_IMAGE)

apply:
	kubectl apply -f k8s/core/
	kubectl apply -f k8s/mysql/
	kubectl apply -f k8s/skillpulse/

status:
	kubectl get pods -n $(NAMESPACE)
	kubectl get svc -n $(NAMESPACE)

logs:
	kubectl logs -n $(NAMESPACE) -l app=backend --tail=50
	kubectl logs -n $(NAMESPACE) -l app=frontend --tail=50
	kubectl logs -n $(NAMESPACE) mysql-0 --tail=50

restart:
	kubectl rollout restart deployment/backend -n $(NAMESPACE)
	kubectl rollout restart deployment/frontend -n $(NAMESPACE)

destroy:
	cd terraform/environments/dev && terraform destroy --auto-approve
