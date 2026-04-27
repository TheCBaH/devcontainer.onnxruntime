all: cpu

VARIANTS = cpu cuda tensorrt coreml

CPUS=$$(getconf _NPROCESSORS_ONLN)
OS=$(shell uname -s | sed 's/Darwin/MacOS/')

CUDA_HOME      ?= /usr/local/cuda
CUDNN_HOME     ?= /usr
TENSORRT_HOME  ?= /usr

BUILD_SCRIPT = cd onnxruntime && python3 tools/ci_build/build.py

DEPS_DIR = $(abspath .deps)
ARGS.base      = --config Release --build_shared_lib --parallel $(CPUS) \
  --cmake_extra_defines FETCHCONTENT_BASE_DIR=$(DEPS_DIR) \
  --cmake_extra_defines CMAKE_C_COMPILER_LAUNCHER=ccache \
  --cmake_extra_defines CMAKE_CXX_COMPILER_LAUNCHER=ccache
ARGS.cpu       = $(ARGS.base)
ARGS.cuda      = $(ARGS.base) --use_cuda --cuda_home $(CUDA_HOME) --cudnn_home $(CUDNN_HOME) \
  $(if ${CUDA_ARCHITECTURE}, --cmake_extra_defines CMAKE_CUDA_ARCHITECTURES=${CUDA_ARCHITECTURE}) \
  $(if ${NVCC_THREADS}, --nvcc_threads ${NVCC_THREADS})
ARGS.tensorrt  = $(ARGS.cuda) --use_tensorrt --tensorrt_home $(TENSORRT_HOME)
ARGS.coreml    = $(ARGS.base) --use_coreml

SAMPLE_SRC    = onnxruntime/samples/cxx
ORT_HEADER_DIR = $(abspath onnxruntime/include/onnxruntime/core/session)

%.ort: onnxruntime/CMakeLists.txt FORCE
	$(BUILD_SCRIPT) --build_dir build.$(basename $@)/$(OS) $(ARGS.$(basename $@)) --update --build --skip_tests

%.tests: FORCE
	$(BUILD_SCRIPT) --build_dir build.$(basename $@)/$(OS) $(ARGS.$(basename $@)) --update --build

%.test: FORCE
	$(BUILD_SCRIPT) --build_dir build.$(basename $@)/$(OS) $(ARGS.$(basename $@)) --test

%.sample: FORCE
	cmake -B $(SAMPLE_SRC)/build.$(basename $@) -G Ninja \
	  -DCMAKE_BUILD_TYPE=Release \
	  -DORT_LIBRARY_DIR=$(abspath onnxruntime/build.$(basename $@)/$(OS)/Release) \
	  -DORT_HEADER_DIR=$(ORT_HEADER_DIR) \
	  $(SAMPLE_SRC)
	cmake --build $(SAMPLE_SRC)/build.$(basename $@) -j $(CPUS)

%.build: onnxruntime/CMakeLists.txt
	$(MAKE) $*.ort
	$(MAKE) $*.sample

%.run: FORCE
	$(SAMPLE_SRC)/build.$(basename $@)/onnxruntime_sample_program \
	  $(SAMPLE_SRC)/add_model.onnx

%.bench: FORCE
	time $(SAMPLE_SRC)/build.$(basename $@)/onnxruntime_sample_program \
	  $(SAMPLE_SRC)/add_model.onnx

%.clean:
	rm -rf onnxruntime/build.$(basename $@)
	rm -rf $(SAMPLE_SRC)/build.$(basename $@)

cpu: cpu.build cpu.run

cuda: cuda.build

tensorrt: tensorrt.build

coreml: coreml.build coreml.run

onnxruntime/CMakeLists.txt: onnxruntime

onnxruntime:
	git submodule update --recursive --init --depth=1 $@

clean: $(VARIANTS:%=%.clean)

.PHONY: FORCE onnxruntime clean $(VARIANTS)
