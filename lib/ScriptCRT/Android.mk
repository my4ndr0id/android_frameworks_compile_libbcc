#
# Copyright (C) 2011 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := libclcore.bc
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := SHARED_LIBRARIES

LOCAL_SRC_FILES := \
    rs_cl.c \
    rs_core.c


include $(BUILD_SYSTEM)/base_rules.mk

clcore_CLANG := $(HOST_OUT_EXECUTABLES)/clang$(HOST_EXECUTABLE_SUFFIX)
clcore_LLVM_LINK := $(HOST_OUT_EXECUTABLES)/llvm-link$(HOST_EXECUTABLE_SUFFIX)

clcore_bc_files := $(patsubst %.c,%.bc, \
    $(addprefix $(intermediates)/, $(LOCAL_SRC_FILES)))

ifeq ($(BOARD_USE_QCOM_LLVM_CLANG_RS),true)
QCOM_FLAGS := -DQCOM_LLVM
clcore_cpp_bc_files = $(addprefix $(intermediates)/, neonRuntimeMath.bc)
endif

CLANG_PATH ?= external/clang
$(clcore_cpp_bc_files) $(clcore_bc_files): PRIVATE_INCLUDES := \
    frameworks/base/libs/rs/scriptc \
    $(CLANG_PATH)/lib/Headers

ifeq ($(BOARD_USE_QCOM_LLVM_CLANG_RS),true)
$(clcore_cpp_bc_files) : PRIVATE_INCLUDES += $(LOCAL_PATH)
$(intermediates)/neonRuntimeMath.bc: $(LOCAL_PATH)/neonRuntimeMath.cpp $(clcore_CLANG)
	mkdir -p $(dir $@)
	$(hide) $(clcore_CLANG) $(addprefix -I, $(PRIVATE_INCLUDES)) $(QCOM_FLAGS) -MD -xc++ -c -O3 -fno-builtin -emit-llvm -ccc-host-triple armv7-none-linux-gnueabi $< -o $@
endif

$(clcore_bc_files): $(intermediates)/%.bc: $(LOCAL_PATH)/%.c  $(clcore_CLANG)
	@mkdir -p $(dir $@)
	$(hide) $(clcore_CLANG) $(addprefix -I, $(PRIVATE_INCLUDES)) $(QCOM_FLAGS) -MD -std=c99 -c -O3 -fno-builtin -emit-llvm -ccc-host-triple armv7-none-linux-gnueabi $< -o $@

-include $(clcore_bc_files:%.bc=%.d)

$(LOCAL_BUILT_MODULE): PRIVATE_BC_FILES := $(clcore_bc_files) $(clcore_cpp_bc_files)
$(LOCAL_BUILT_MODULE) : $(clcore_bc_files) $(clcore_cpp_bc_files) $(clcore_LLVM_LINK)
	@mkdir -p $(dir $@)
	$(hide) $(clcore_LLVM_LINK) $(PRIVATE_BC_FILES) -o $@
