KTF_ROOT := $(abspath $(CURDIR))
export KTF_ROOT

CONFIG := $(KTF_ROOT)/.config
include $(CONFIG)

THIRD_PARTY := third-party
PATCH := patch
TOOLS_DIR := tools

ifeq ($(OS),Windows_NT)
SYSTEM := WIN
else
UNAME := $(shell uname -s)

ifeq ($(UNAME),Linux)
SYSTEM := LINUX
endif

ifeq ($(UNAME),Darwin)
SYSTEM := MACOS
endif
endif

PFMLIB_ARCHIVE :=
PFMLIB_LINKER_FLAGS :=
PFMLIB_INCLUDE :=
PFMLIB_NAME := libpfm
PFMLIB_VER := 4.13.0
PFMLIB_DIR := $(KTF_ROOT)/$(THIRD_PARTY)/$(PFMLIB_NAME)
PFMLIB_TARBALL := $(PFMLIB_DIR)/$(PFMLIB_NAME)-$(PFMLIB_VER).tar.gz
ifeq ($(CONFIG_LIBPFM),y)
KTF_PFMLIB_COMPILE := 1
export KTF_PFMLIB_COMPILE
TAR_CMD_PFMLIB := tar --exclude=.git --exclude=.gitignore --strip-components=1 -xf
PFMLIB_TOOLS_DIR := $(KTF_ROOT)/$(TOOLS_DIR)/$(PFMLIB_NAME)
PFMLIB_ARCHIVE := $(PFMLIB_DIR)/$(PFMLIB_NAME).a
PFMLIB_UNTAR_FILES := $(PFMLIB_NAME)-$(PFMLIB_VER)/lib
PFMLIB_UNTAR_FILES += $(PFMLIB_NAME)-$(PFMLIB_VER)/include
PFMLIB_UNTAR_FILES += $(PFMLIB_NAME)-$(PFMLIB_VER)/rules.mk
PFMLIB_UNTAR_FILES += $(PFMLIB_NAME)-$(PFMLIB_VER)/config.mk
PFMLIB_UNTAR_FILES += $(PFMLIB_NAME)-$(PFMLIB_VER)/Makefile
PFMLIB_UNTAR_FILES += $(PFMLIB_NAME)-$(PFMLIB_VER)/README
PFMLIB_UNTAR_FILES += $(PFMLIB_NAME)-$(PFMLIB_VER)/COPYING
PFMLIB_PATCH_FILE := $(PFMLIB_TOOLS_DIR)/libpfm_diff.patch
PFMLIB_LINKER_FLAGS += -L$(PFMLIB_DIR) -lpfm
PFMLIB_INCLUDE += $(PFMLIB_DIR)/include
endif

ACPICA_DEST_DIR := $(KTF_ROOT)/drivers/acpi/acpica
ifeq ($(CONFIG_ACPICA),y)
TAR_CMD_ACPICA := tar --exclude=.git --exclude=.gitignore --strip-components=1 -C $(ACPICA_DEST_DIR) -xf
ACPICA_VER := unix-20230628
ACPICA_NAME := acpica
ACPICA_DIR := $(KTF_ROOT)/$(THIRD_PARTY)/$(ACPICA_NAME)
ACPICA_TARBALL := $(ACPICA_DIR)/$(ACPICA_NAME)-$(ACPICA_VER).tar.gz
ACPICA_PATCH := $(ACPICA_DIR)/acpica_ktf.patch
ACPICA_UNTAR_DIRS := $(ACPICA_NAME)-$(ACPICA_VER)/source/components/dispatcher
ACPICA_UNTAR_DIRS += $(ACPICA_NAME)-$(ACPICA_VER)/source/components/events
ACPICA_UNTAR_DIRS += $(ACPICA_NAME)-$(ACPICA_VER)/source/components/executer
ACPICA_UNTAR_DIRS += $(ACPICA_NAME)-$(ACPICA_VER)/source/components/hardware
ACPICA_UNTAR_DIRS += $(ACPICA_NAME)-$(ACPICA_VER)/source/components/namespace
ACPICA_UNTAR_DIRS += $(ACPICA_NAME)-$(ACPICA_VER)/source/components/parser
ACPICA_UNTAR_DIRS += $(ACPICA_NAME)-$(ACPICA_VER)/source/components/tables
ACPICA_UNTAR_DIRS += $(ACPICA_NAME)-$(ACPICA_VER)/source/components/utilities
ACPICA_UNTAR_DIRS += $(ACPICA_NAME)-$(ACPICA_VER)/source/include
ACPICA_INCLUDE := $(ACPICA_DEST_DIR)/source/include
endif

ifeq ($(CC),cc) # overwrite on default, otherwise use whatever is in the CC env variable
CC := gcc
endif
LD := ld

NM := nm
CTAGS := ctags
PYTHON := $(shell tools/ci/get-python.sh)
SHELL := bash
RM := rm
LN := ln
SYMLINK := $(LN) -s -f
HARDLINK := $(LN) -f
OBJCOPY := objcopy
STRIP := strip
ifeq ($(SYSTEM), MACOS)
STRIP_OPTS := -S
else
STRIP_OPTS := -s
endif

GRUB_DIR := grub/boot
GRUB_FILE := grub-file
GRUB_MKRESCUE := grub-mkrescue
GRUB_MODULES := multiboot2 iso9660 serial normal
ifneq ($(UNITTEST),)
GRUB_CONFIG := grub/grub-test.cfg
else
GRUB_CONFIG := grub/grub-prod.cfg
endif
XORRISO := xorriso
QEMU_BIN := qemu-system-x86_64
GDB := gdb
XZ := xz

COMMON_INCLUDES := -I$(KTF_ROOT)/include -I$(KTF_ROOT)/include/arch/x86
ifeq ($(CONFIG_LIBPFM),y)
COMMON_INCLUDES += -I$(PFMLIB_INCLUDE)
endif
ifeq ($(CONFIG_ACPICA),y)
COMMON_INCLUDES += -I$(ACPICA_INCLUDE)
endif

COMMON_FLAGS := $(COMMON_INCLUDES) -pipe -MP -MMD -m64 -D__x86_64__ -D__KTF__ -DEARLY_VIRT_MEM=$(CONFIG_EARLY_VIRT_MEM)

ifeq ($(CONFIG_DEBUG),y)
COMMON_FLAGS += -DKTF_DEBUG
endif

ifeq ($(CONFIG_LIBPFM),y)
COMMON_FLAGS += -DKTF_PMU
endif

ifeq ($(CONFIG_ACPICA),y)
COMMON_FLAGS += -DKTF_ACPICA
endif

ifneq ($(UNITTEST),)
COMMON_FLAGS += -DKTF_UNIT_TEST
endif

AFLAGS  := $(COMMON_FLAGS) -DASM_FILE -D__ASSEMBLY__ -nostdlib -nostdinc
CFLAGS  := $(COMMON_FLAGS) -std=gnu99 -O2 -g -Wall -Wextra -ffreestanding -nostdlib -nostdinc
CFLAGS  += -mno-red-zone -mno-mmx -mno-sse -mno-sse2
CFLAGS  += -fno-stack-protector -fno-exceptions -fno-builtin -fomit-frame-pointer -fcf-protection="none"
CFLAGS  += -mcmodel=kernel -fno-pic -fno-asynchronous-unwind-tables -fno-unwind-tables
CFLAGS  += -Wno-unused-parameter -Wno-address-of-packed-member
CFLAGS  += -Werror
# Newer versions of GCC warn about memory accesses at non-zero offsets from null pointers.
# As we use this intentionally at different places in our code, these warnings result in many false positives.
CFLAGS  += -Wno-array-bounds

ifneq ($(V), 1)
VERBOSE=@
endif

-include Makeconf.local

ifeq ($(CONFIG_ACPICA),y)
ACPICA_INSTALL := $(shell [ -d $(ACPICA_DEST_DIR)/source ] ||                         \
                          $(TAR_CMD_ACPICA) $(ACPICA_TARBALL) $(ACPICA_UNTAR_DIRS) && \
                          $(PATCH) -p0 < $(ACPICA_PATCH) &&                           \
                          $(HARDLINK) $(ACPICA_DEST_DIR)/acktf.h $(ACPICA_INCLUDE)/platform/acktf.h)
endif

ASM_OFFSETS_C := asm-offsets.c
ASM_OFFSETS_SH := $(KTF_ROOT)/tools/asm-offsets/asm-offsets.sh

SOURCES     := $(shell find . -name \*.c -and -not -name $(ASM_OFFSETS_C))
HEADERS     := $(shell find . -name \*.h)
ASM_SOURCES := $(shell find . -name \*.S)
ASM_OFFSETS := $(shell find . -name $(ASM_OFFSETS_C))
LINK_SCRIPT := $(shell find . -name \*.ld)

ASM_OFFSETS_S := $(ASM_OFFSETS:.c=.s)
ASM_OFFSETS_H := $(addprefix include/,$(ASM_OFFSETS:.c=.h))

SYMBOLS_NAME := symbols
SYMBOLS_TOOL := symbols.py
SYMBOLS_DIR  := tools/symbols

PREP_LINK_SCRIPT := $(LINK_SCRIPT:%.ld=%.lds)

OBJS := $(SOURCES:%.c=%.o)
OBJS += $(ASM_SOURCES:%.S=%.o)

TARGET := kernel64.bin
TARGET_DEBUG := $(TARGET).debug

# On Linux systems, we build directly. On non-Linux, we rely on the 'docker%'
# rule below to create an Ubuntu container and perform the Linux-specific build
# steps therein.
ifeq ($(SYSTEM), LINUX)
all: $(TARGET)
else
all: docker$(TARGET)
endif

$(PREP_LINK_SCRIPT) : $(LINK_SCRIPT)
	$(VERBOSE) $(CC) $(AFLAGS) -E -P -C -x c $< -o $@

$(TARGET_DEBUG): $(OBJS) $(PREP_LINK_SCRIPT)
	@echo "LD " $@
	$(VERBOSE) $(LD) -T $(PREP_LINK_SCRIPT) -o $@ $(OBJS) $(PFMLIB_LINKER_FLAGS)
	@echo "GEN " $(SYMBOLS_NAME).S
	$(VERBOSE) $(NM) -p --format=posix $@ | $(PYTHON) $(SYMBOLS_DIR)/$(SYMBOLS_TOOL)
	@echo "CC " $(SYMBOLS_NAME).S
	$(VERBOSE) $(CC) -c -o $(SYMBOLS_NAME).o $(AFLAGS) $(SYMBOLS_NAME).S
	$(VERBOSE) rm -rf $(SYMBOLS_NAME).S
	@echo "LD " $@ $(SYMBOLS_NAME).o
	$(VERBOSE) $(LD) -T $(PREP_LINK_SCRIPT) -o $@ $(OBJS) $(PFMLIB_LINKER_FLAGS) $(SYMBOLS_NAME).o

$(TARGET): $(TARGET_DEBUG)
	@echo "STRIP"
	$(VERBOSE) $(STRIP) $(STRIP_OPTS) -o $@ $<

$(PFMLIB_ARCHIVE): $(PFMLIB_TARBALL)
	@echo "UNTAR libpfm"
	$(VERBOSE) cd $(PFMLIB_DIR) &&\
	$(TAR_CMD_PFMLIB) $(PFMLIB_TARBALL) $(PFMLIB_UNTAR_FILES) -C ./ &&\
	$(PATCH) -s -p1 < $(PFMLIB_PATCH_FILE) &&\
	cd -
	@echo "BUILD libpfm"
	$(VERBOSE) $(MAKE) -C $(PFMLIB_DIR) lib
	$(VERBOSE) cp $(PFMLIB_DIR)/lib/$(PFMLIB_NAME).a $(PFMLIB_DIR)/
	$(VERBOSE) find $(PFMLIB_DIR) -name \*.c -delete

%.o: %.S $(ASM_OFFSETS_H)
	@echo "AS " $@
	$(VERBOSE) $(CC) -c -o $@ $(AFLAGS) $<

%.o: %.c $(PFMLIB_ARCHIVE)
	@echo "CC " $@
	$(VERBOSE) $(CC) -c -o $@ $(CFLAGS) $<

$(ASM_OFFSETS_S): $(ASM_OFFSETS)
	$(VERBOSE) $(CC) $(CFLAGS) -S -g0 -o $@ $<

$(ASM_OFFSETS_H): $(ASM_OFFSETS_S)
	@echo "GEN" $@
	$(VERBOSE) $(ASM_OFFSETS_SH) $< $@

DEPFILES := $(OBJS:.o=.d)
-include $(wildcard $(DEPFILES))

clean:
	@echo "CLEAN"
	$(VERBOSE) find $(KTF_ROOT) -name \*.d -delete
	$(VERBOSE) find $(KTF_ROOT) -name \*.o -delete
	$(VERBOSE) find $(KTF_ROOT) -name \*.lds -delete
	$(VERBOSE) find $(KTF_ROOT) -name \*.bin -delete
	$(VERBOSE) find $(KTF_ROOT) -name \*.iso -delete
	$(VERBOSE) find $(KTF_ROOT) -name \*.img -delete
	$(VERBOSE) find $(KTF_ROOT) -name \*.xz -delete
	$(VERBOSE) find $(KTF_ROOT) -name cscope.\* -delete
	$(VERBOSE) find $(KTF_ROOT) -maxdepth 1 \( -name tags -or -name TAGS \) -delete
	$(VERBOSE) find $(PFMLIB_DIR) -mindepth 1 ! -name $(PFMLIB_NAME)-$(PFMLIB_VER).tar.gz -delete
	$(VERBOSE) $(RM) -f $(ASM_OFFSETS_H) $(ASM_OFFSETS_S)
	$(VERBOSE) $(RM) -rf $(ACPICA_DEST_DIR)/source
	$(VERBOSE) $(RM) -f $(TARGET_DEBUG) $(TARGET)
	$(VERBOSE) $(RM) -rf $(GRUB_DIR)

# Check whether we can use kvm for qemu
ifeq ($(SYSTEM),LINUX)
ifneq ($(USE_KVM), false) # you can hard-disable KVM use with the USE_KVM environment variable
HAVE_KVM=$(shell test -w /dev/kvm && echo kvm)
endif # USE_KVM
endif # SYSTEM == LINUX

# Set qemu parameters
QEMU_CONFIG := $(KTF_ROOT)/.qemu_config
include $(QEMU_CONFIG)

ifeq ($(SYSTEM)$(HAVE_KVM),LINUXkvm)
QEMU_PARAMS := -cpu host -enable-kvm
else
QEMU_PARAMS := -cpu max
endif
QEMU_PARAMS += -m $(QEMU_RAM)
QEMU_PARAMS += -serial stdio
QEMU_PARAMS += -smp cpus=$(QEMU_CPUS)
QEMU_PARAMS_NOGFX := -display none -vga none -vnc none
QEMU_PARAMS_GFX := $(QEMU_PARAMS)
QEMU_PARAMS += $(QEMU_PARAMS_NOGFX)

QEMU_PARAMS_DEBUG := -s -S &

ISO_FILE := ktf.iso

ifneq ($(SYSTEM), LINUX)
$(ISO_FILE): docker${ISO_FILE}
else
$(ISO_FILE): $(TARGET)
	@echo "GEN ISO" $(ISO_FILE)
	$(VERBOSE) $(GRUB_FILE) --is-x86-multiboot2 $< || { echo "Multiboot not supported"; exit 1; }
	$(VERBOSE) $(RM) -rf $(GRUB_DIR) && mkdir -p $(GRUB_DIR)/grub
	$(VERBOSE) cp $< $(GRUB_DIR)/
	$(VERBOSE) cp $(GRUB_CONFIG) $(GRUB_DIR)/grub/grub.cfg
	$(VERBOSE) $(XZ) -q -f $(GRUB_DIR)/$<
	$(VERBOSE) $(GRUB_MKRESCUE) --install-modules="$(GRUB_MODULES)" --fonts=no --compress=xz -o $(ISO_FILE) grub &> /dev/null
endif

.PHONY: boot
boot: $(ISO_FILE)
	@echo "QEMU START"
	$(VERBOSE) $(QEMU_BIN) -cdrom $(ISO_FILE) $(QEMU_PARAMS)

.PHONY: boot_gfx
boot_gfx: $(ISO_FILE)
	@echo "QEMU START"
	$(VERBOSE) $(QEMU_BIN) -cdrom $(ISO_FILE) $(QEMU_PARAMS_GFX)

.PHONY: boot_debug
boot_debug: $(ISO_FILE)
	$(QEMU_BIN) -cdrom $(ISO_FILE) $(QEMU_PARAMS) $(QEMU_PARAMS_DEBUG)

.PHONY: gdb
gdb: boot_debug
	$(GDB) $(TARGET_DEBUG) -ex 'target remote :1234' -ex 'hb _start' -ex c
	killall -9 $(QEMU_BIN)

define all_sources
	find $(KTF_ROOT) -name "*.[hcsS]"
endef

.PHONY: cscope
cscope:
	@echo "CSCOPE"
	$(VERBOSE) $(all_sources) > cscope.files
	$(VERBOSE) cscope -b -q -k

tags TAGS: $(SOURCES) $(HEADERS) $(ASM_SOURCES)
	@echo "TAGS ($@)"
	$(VERBOSE) $(CTAGS) -o $@ $+

.PHONY: style
style:
	@echo "STYLE"
	$(VERBOSE) docker run --rm --workdir /src -v $(PWD):/src$(DOCKER_MOUNT_OPTS) clang-format-lint --clang-format-executable /clang-format/clang-format10 \
          -r $(SOURCES) $(HEADERS) | grep -v -E '^Processing [0-9]* files:' | patch -s -p1 ||:

.PHONY: commit_style
commit_style:
	@echo "COMMIT_STYLE"
	$(VERBOSE) git clang-format HEAD^1 > /dev/null

DOCKERFILE  := $(shell find $(KTF_ROOT) -type f -name Dockerfile)
DOCKERIMAGE := "ktf:build"
DOCKERUSERFLAGS := --user $(shell id -u):$(shell id -g) $(shell printf -- "--group-add=%q " $(shell id -G))

ifeq ($(SYSTEM), LINUX)
	DOCKER_BUILD_ARGS=--network=host
endif

.PHONY: dockerimage
dockerimage:
	@echo "Creating docker image"
	$(VERBOSE) docker build -t $(DOCKERIMAGE) -f $(DOCKERFILE) \
		$(DOCKER_BUILD_ARGS) .

.PHONY: docker%
docker%: dockerimage
	@echo "running target '$(strip $(subst :,, $*))' in docker"
	$(VERBOSE) docker run -t $(DOCKERUSERFLAGS) -e UNITTEST=$(UNITTEST) -e CONFIG_LIBPFM=$(CONFIG_LIBPFM) -e CONFIG_ACPICA=$(CONFIG_ACPICA) -v $(PWD):$(PWD)$(DOCKER_MOUNT_OPTS) -w $(PWD) $(DOCKERIMAGE) bash -c "make -j $(strip $(subst :,, $*))"

.PHONY: onelinescan
onelinescan:
	@echo "scanning current working directory with one-line-scan"
	$(VERBOSE) docker run -t -e BASE_COMMIT=origin/mainline \
		-e REPORT_NEW_ONLY=true -e OVERRIDE_ANALYSIS_ERROR=true \
		-e INFER_ANALYSIS_EXTRA_ARGS="--bufferoverrun" \
		-e CPPCHECK_EXTRA_ARG=" --enable=style --enable=performance --enable=information --enable=portability" \
		-e VERBOSE=0 -e BUILD_COMMAND="make -B all" \
		-v $(PWD):$(PWD)$(DOCKER_MOUNT_OPTS) -w $(PWD) ktf-one-line-scan
