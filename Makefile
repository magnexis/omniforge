PYTHON ?= python
CLI = $(PYTHON) apps/cli/omniforge.py

.PHONY: workers capabilities languages detect pipeline demo verify

workers:
	$(CLI) workers list

capabilities:
	$(CLI) capabilities list

languages:
	$(CLI) languages list

detect:
	$(CLI) toolchains detect

pipeline:
	$(CLI) pipeline run pipelines/data-intelligence.yaml --input examples/data/customers.csv

demo:
	$(CLI) run text.replace-cmake --language cmake --input .cache/job-cmake.json
	$(CLI) run text.search-findstr --language findstr --input .cache/job-findstr.json
	$(CLI) run text.length --language batch --input .cache/job-batch.json

verify:
	$(PYTHON) -m unittest tests/test_omniforge.py

docker-config:
	docker compose config

docker-functional-shell:
	docker compose --profile functional run --rm omniforge-functional bash

docker-functional-smoke:
	docker compose --profile functional run --rm omniforge-functional bash containers/smoke-functional.sh

docker-full-shell:
	docker compose --profile full run --rm omniforge-full bash
