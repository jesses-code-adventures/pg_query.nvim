.PHONY: pre-reqs init

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


init: pre-reqs ## build and install pg_query_utils and its dependencies, to $$HOME/.local/bin
