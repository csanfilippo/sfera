SWIFT_VERSION := 6.4.0
# The Wasm SDK must match the toolchain exactly: update the checksum with the version (swift.org/install).
WASM_SDK := swift-$(SWIFT_VERSION)-RELEASE_wasm
WASM_SDK_URL := https://download.swift.org/swift-$(SWIFT_VERSION)-release/wasm-sdk/swift-$(SWIFT_VERSION)-RELEASE/$(WASM_SDK).artifactbundle.tar.gz
WASM_SDK_CHECKSUM := f07b7be3c586d92d7a07051fc6d303b87ebea67eadc40640ba59d5a8b79aa86d

# The sources are mounted read-only and built outside them, so container builds never touch the local .build.
DOCKER_RUN := docker run --rm \
	--volume "$(CURDIR)":/src:ro \
	--volume sfera-swiftpm:/root/.swiftpm \
	--workdir /src \
	swift:$(SWIFT_VERSION)
SCRATCH := --scratch-path /tmp/build

.PHONY: test-linux test-wasm

test-linux:
	$(DOCKER_RUN) swift test $(SCRATCH)

# XCTest is disabled because its runner traps in Foundation's Bundle.main on WASI (6.4.0 SDK); the suite is Swift Testing only.
test-wasm:
	$(DOCKER_RUN) bash -c '\
		swift sdk list | grep -qx $(WASM_SDK) || swift sdk install $(WASM_SDK_URL) --checksum $(WASM_SDK_CHECKSUM) && \
		swift test --swift-sdk $(WASM_SDK) --disable-xctest $(SCRATCH)'
