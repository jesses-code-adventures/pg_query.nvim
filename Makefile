.PHONY: pre-reqs init

BINARIES_DIR:="$$HOME/.local/bin"
TEST_DIR := tests
LUAJIT := luajit -O -joff

test:
	@set -e; \
	for file in $(TEST_DIR)/*.lua; do \
		echo "Running $$file..."; \
		$(LUAJIT) $$file || exit 1; \
	done

pre-reqs:
	@if ! command -v pg_query_prepare >/dev/null 2>&1; then \
		echo "pg_query_prepare not found. Cloning and building pg_query_utils..."; \
		rm -rf pg_query_utils && \
		git clone --recurse-submodules --depth 1 https://github.com/timwmillard/pg_query_utils.git && \
		cd pg_query_utils && \
		sed -i '' '/^all:/s/pg_describe_query.*//;' Makefile && \
		make && \
		mkdir -p "$$HOME/.local/bin" && \
		cp pg_query_prepare "$$HOME/.local/bin" && \
		cp pg_query_json "$$HOME/.local/bin" && \
		cp pg_query_fingerprint "$$HOME/.local/bin" && \
		cd .. && \
		rm -rf pg_query_utils; \
	else \
		echo "pg_query_prepare already installed."; \
	fi

check-bins: # List installed binaries
	@find $(BINARIES_DIR) -type f -name "*pg_query*" -exec realpath {} \;

clean: ## Remove pg query binaries
	@$(MAKE) check-bins | xargs rm

build-image: ## build the project in a docker image, with luajit and make.
	docker build -t luajit-make .

run-pg-query-prepare: ## Run scripts/testing.sql through pg_query_prepare --details
	@cat scripts/testing.sql | pg_query_prepare -d

init: pre-reqs ## build and install pg_query_utils and its dependencies, to $(BINARIES_DIR)

reinstall-reqs: clean pre-reqs ## Delete and reinstall the pg_query binaries, using the latest version from github

# HELP - will output the help for each task in the Makefile
# In sorted order.
# The width of the first column can be determined by the `width` value passed to awk
#
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html for the initial version.
#
help: ## This help.
	@grep -E -h "^[a-zA-Z_-]+:.*?## " $(MAKEFILE_LIST) \
	  | sort \
	  | awk -v width=36 'BEGIN {FS = ":.*?## "} {printf "\033[36m%-*s\033[0m %s\n", width, $$1, $$2}'
