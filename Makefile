export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export AWS_DEFAULT_REGION="us-east-1"

.PHONY: all up down apply deploy-localstack providers version show output clean

apply: up localstack
	terraform apply -lock=false -var-file fixtures.tfvars -auto-approve -compact-warnings

up:
	docker-compose up -d # --pull always -d
	docker inspect localstack/localstack | jq '.[0].Architecture'

deploy-localstack:
	terraform fmt
	terraform init -backend=false -upgrade -lock=false
	terraform validate
	terraform plan -lock=false -input=false -var-file fixtures.tfvars
	terraform apply -input=true -auto-approve
	terraform state list
	aws --endpoint-url=http://localhost:4566 s3 ls
	aws --endpoint-url=http://localhost:4566 lambda list-functions

providers version show output:
	terraform $@

clean:
	rm -rf .terraform
	rm -rf terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl
	docker-compose down -v
