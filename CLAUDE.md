# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A devcontainer-based development environment for [ONNXRuntime](https://github.com/microsoft/onnxruntime). The `onnxruntime` submodule is built from source via its own `build.py` script, and a small C++ sample (`onnxruntime/samples/cxx/main.cc`) is compiled against the resulting library to validate the build.

## Build commands

Each backend has three make targets: `<type>.build`, `<type>.run`, `<type>.bench`.

```sh
make cpu.build       # build onnxruntime + sample (CPU only)
make cpu.run         # run sample binary
make cpu.bench       # time the sample binary

make cuda.build      # build with CUDA EP
make tensorrt.build  # build with TensorRT EP (requires TensorRT libs)
make coreml.build    # build with CoreML EP (macOS only)
make coreml.run

make cpu             # shorthand for cpu.build + cpu.run
make cuda            # shorthand for cuda.build
make coreml          # shorthand for coreml.build + coreml.run

make cpu.clean       # remove build artifacts for a backend
make clean           # clean all backends
```

Build outputs land in `onnxruntime/build.<type>/<OS>/` and the sample binary in `onnxruntime/samples/cxx/build.<type>/`.

## Architecture

### Make targets and build flow

`%.build` does two things in sequence:
1. Runs `onnxruntime/tools/ci_build/build.py` to configure and build the ORT library.
2. Runs cmake to configure and build the C++ sample against the freshly built library.

`%.run` and `%.bench` are pure execution targets with no build dependencies — they just invoke the already-built sample binary. Both are declared `.PHONY`.

`ARGS.tensorrt` extends `ARGS.cuda` (CUDA EP is required as fallback for ops TensorRT doesn't cover).

`FETCHCONTENT_BASE_DIR` is redirected to `.deps/` at repo root so CMake dependency downloads are shared across build types and can be cached independently of compiled objects.

### CI caching strategy

Three independent caches per OS:
- `.ccache/` — keyed on `<os>-<build_type>-<submodule SHA>` — compiled object cache
- `.deps/` — keyed on `<os>-<submodule SHA>` (shared across build types) — FetchContent source downloads
- `.cache/` — keyed on `<os>-hash(Makefile)` — model files for bench

### CI container strategy (Linux only)

The `.github/workflows/actions/devcontainer` composite action:
1. Builds the devcontainer image using `@devcontainers/cli`.
2. Pulls/pushes the image to `ghcr.io/<repo>/devcontainer-<arch>` keyed by branch name to warm the layer cache across runs.
3. Outputs an `exec` variable (`devcontainer exec --workspace-folder .`) that prefixes every subsequent `make` invocation so commands run inside the container.

macOS jobs run natively — no devcontainer, `EXEC` is empty.

### Devcontainer image

`.devcontainer/Dockerfile` is a plain Ubuntu image that installs:
- Build tools: `cmake`, `ninja-build`, `clang`, `ccache`
- CUDA: `cuda-toolkit-12-9`, `libcudnn9-dev-cuda-12`
- TensorRT: `libnvinfer-dev`, `libnvinfer-plugin-dev`, `libnvonnxparsers-dev`
- Runtime extras: `ccache`, `libcurl4-openssl-dev`, `libssl-dev` (via devcontainer feature)

The NVIDIA apt repo is configured at image build time via `cuda-keyring`.
