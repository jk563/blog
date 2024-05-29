static_files := "frontend/public"
domain := "jamiekelly.com"
bucket_suffix := domain + "-assets"

default:
  just --list

preview: (local-deploy "preview" "blog.preview")

production: (local-deploy "production" "blog")

local-deploy ENVIRONMENT SUBDOMAIN: (apply-infra ENVIRONMENT) (generate-frontend ENVIRONMENT) && (deploy SUBDOMAIN)

deploy SUBDOMAIN:
  #!/usr/bin/env sh
  BUCKET=$(aws s3api list-buckets --query 'Buckets[?starts_with(Name, `{{ SUBDOMAIN}}.{{ bucket_suffix }}`)].Name' --output text)
  DISTRIBUTION=$(aws cloudfront list-distributions --query 'DistributionList.Items[?Aliases.Items[0]==`{{ SUBDOMAIN }}.{{ domain }}`].Id' --output text)
  echo s3://${BUCKET}
  aws s3 sync --delete --exclude "*.swp" {{ static_files }} s3://${BUCKET} && aws cloudfront create-invalidation --distribution-id ${DISTRIBUTION} --paths "/*" | jq '.Invalidation.Id' --raw-output | xargs -I {} aws cloudfront wait invalidation-completed --distribution-id ${DISTRIBUTION} --id {}

lighthouse SUBDOMAIN:
	find {{ static_files }} -name '*.html' \
		| cut -d '/' -f 3- \
		| xargs -n 1 -I {} lighthouse https://{{ SUBDOMAIN }}.{{ domain }}/{} --chrome-flags='--headless' --quiet --output json \
		| jq '{ "page": .requestedUrl, "scores": .categories | map(select(.id != "pwa") | {(.id) : .score}) | add }' \
		| jq --slurp ' map(select(.scores | any(.!=1)))'

apply-infra ENVIRONMENT: 
  cd infrastructure && just workspace {{ ENVIRONMENT }}
  cd infrastructure && just apply

generate-frontend ENVIRONMENT: 
  cd frontend && just build {{ ENVIRONMENT }}
