
init:
	terraform init -reconfigure

plan:
	terraform plan -var-file=shared_vars.tfvars

apply:
	terraform apply -var-file=shared_vars.tfvars -auto-approve 

destroy:
	terraform destroy -var-file=shared_vars.tfvars -auto-approve 

fmt:
	terraform fmt 

validate:
	terraform validate




docker-init:
	docker run -ti --rm --name terra -v ${PWD}:/root hernanku/devops-cli terraform init -reconfigure

docker-plan:
	docker run -ti --rm --name terra -v ${PWD}:/root -v ~/.aws:/root/.aws hernanku/devops-cli terraform plan -var-file=shared_vars.tfvars

docker-apply:
	docker run -ti --rm --name terra -v ${PWD}:/root -v ~/.aws:/root/.aws hernanku/devops-cli terraform apply -var-file=shared_vars.tfvars -auto-approve 

docker-destroy:
	docker run -ti --rm --name terra -v ${PWD}:/root -v ~/.aws:/root/.aws hernanku/devops-cli terraform destroy -var-file=shared_vars.tfvars -auto-approve 

docker-fmt:
	docker run -ti --rm --name terra -v ${PWD}:/root hernanku/devops-cli terraform fmt 

docker-validate:
	docker run -ti --rm --name terra -v ${PWD}:/root -v ~/.aws:/root/.aws hernanku/devops-cli terraform validate


