# Devcontainer for ONNXRuntime

[![ONNXRuntime devcontainer](https://github.com/TheCBaH/devcontainer.onnxruntime/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/TheCBaH/devcontainer.onnxruntime/actions/workflows/build.yml)

Devcontainer to create [ONNXRuntime](https://github.com/microsoft/onnxruntime) development environment.

## Get started
* [![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=1222124733)
* run
  * `make cpu` build and run ONNXRuntime on CPU
  * `make cuda` build and run ONNXRuntime on NVIDIA GPU
  * `make coreml` build and run ONNXRuntime on Apple CoreML

## Build targets

Each backend (`cpu`, `cuda`, `tensorrt`, `coreml`) supports the following targets:

| Target | Description |
|---|---|
| `<type>.ort` | Build ORT core library (no test binaries) |
| `<type>.tests` | Build ORT test binaries (requires prior `<type>.ort`) |
| `<type>.test` | Run ORT test suite (requires prior `<type>.tests`) |
| `<type>.sample` | Build the C++ sample against the ORT library |
| `<type>.run` | Run the C++ sample |
| `<type>.bench` | Time the C++ sample |
| `<type>.build` | Shorthand: `<type>.ort` + `<type>.sample` |
| `<type>.clean` | Remove all build artifacts for that backend |
| `clean` | Clean all backends |
