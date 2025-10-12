# Variables for protobuf compilation
PROTOC ?= protoc
PROTOC_GEN_DART ?= $(shell which protoc-gen-dart 2>/dev/null || find ~/.pub-cache/bin -name "protoc-gen-dart" 2>/dev/null | head -1 || echo "")
PROTO_INCLUDE ?= $(shell $(PROTOC) --print_include_path 2>/dev/null || find /opt/homebrew/Cellar/protobuf -name "include" -type d 2>/dev/null | head -1 || echo "")

proto:
	@PROTO_FILES="$$(find ../proto/models ../proto/api -name '*.proto' 2>/dev/null)"; \
	if [ -z "$(PROTOC_GEN_DART)" ]; then \
		echo "Error: protoc-gen-dart not found. Please install it or set PROTOC_GEN_DART environment variable."; \
		exit 1; \
	fi; \
	if [ -z "$(PROTO_INCLUDE)" ]; then \
		echo "Error: Could not determine protobuf include path. Please set PROTO_INCLUDE environment variable."; \
		exit 1; \
	fi; \
	if [ -n "$$PROTO_FILES" ]; then \
		echo "Generating Dart code from proto files: $$PROTO_FILES"; \
	    $(PROTOC) --plugin=protoc-gen-dart="$(PROTOC_GEN_DART)" \
			--dart_out=lib/generated \
			--proto_path=../proto \
			--proto_path="$(PROTO_INCLUDE)" \
			$$PROTO_FILES; \
		echo "Generating Google protobuf standard types..."; \
		$(PROTOC) --plugin=protoc-gen-dart="$(PROTOC_GEN_DART)" \
			--dart_out=lib/generated \
			--proto_path="$(PROTO_INCLUDE)" \
			google/protobuf/duration.proto google/protobuf/timestamp.proto; \
	else \
		echo "No proto files found in ../proto/models/ or ../proto/api/"; \
	fi

generate:
	@echo "Running Dart build runner build..."; \
	dart run build_runner build -d

.PHONY: proto generate
