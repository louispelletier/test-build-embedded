#------------------------
# Basic Makefile Template
#
# Use this file as a starting point for your build. It encapsulates much of the work
# We have done in this course.
# Search for "TODO" in the file below to set up the Makefile for your project.
#------------------------

# By default, recipe steps will be quieted.
# But a user can supply VERBOSE=1 as an environment variable or command line argument
# to re-enable build output.
VERBOSE ?= 0
ifeq ($(VERBOSE),1)
Q :=
export VERBOSE = 1
else
Q := @
export VERBOSE = 0
endif

# This function is used to check that a file fits within the allocated size
# Inputs:
#    $1: binary
#    $2: size limit
#  If max size is non-zero, use the specified size as a limit
ENFORCESIZE = @(FILESIZE=`stat -f '%z' $1` ; \
	if [ $2 -gt 0 ]; then \
		if [ $$FILESIZE -gt $2 ] ; then \
			echo "ERROR: File $1 exceeds size limit ($$FILESIZE > $2)" ; \
			exit 1 ; \
		fi ; \
	fi )
#
# The following options can be controlled on the command line
# by supplying a defintion, e.g.: make BUILDRESULTS=output/ DEBUG=1
#
BUILDRESULTS ?= buildresults
DEBUG ?= 1

# This variable can be set to select a different toolchain
TOOLCHAIN ?= native
# Default to the standard objcopy program
OBJCOPY := objcopy
# TODO: Set the max size for you build, if desired
MAX_SIZE:= 131702

ifeq ($(TOOLCHAIN),gcc-arm)
CC := arm-none-eabi-gcc
AR := arm-none-eabi-ar
OBJCOPY := arm-none-eabi-objcopy
CFLAGS += --specs=nosys.specs
# An example using LDFLAGS, if you were specifying a linker script.
#LDFLAGS += -Tstm32l4r5.ld -Llinker
endif

# Default C compilation flags. We use += to allow the user to specify others on the command line
CFLAGS += -Wall -Wextra -std=c11
# Default C linker flags. We use += to allow the user to specify others on the command line
LDFLAGS += -Wl,-Map,$@.map
STATIC_LIB_FLAGS := rcs
DEPFLAGS = -MT $@ -MMD -MP -MF $*.d

# By default, this Makefile produces release builds
ifeq ($(DEBUG),1)
CFLAGS += -Og -g3
else
CFLAGS += -O2
endif

.PHONY: all
# TODO: replace with your default targets
	# For example, you may want to list these:
	# $(BUILDRESULTS)/your_program.hex $(BUILDRESULTS)/your_program.bin
all: $(BUILDRESULTS)/your_program

# The list of source files needed for an executable target
# TODO: replace with YOUR files
APP_SOURCES := src/a_file.c
# The list of source files needed for a library target
# TODO: replace with YOUR files
LIB_SOURCES := src/lib/a_file.c

# The output location where libraries should be placed
# TODO: Adjust to be correct for your project
LIBDIR:=$(BUILDRESULTS)/lib

# Translate the library sources into object file namesthat can be used as prerequisites
LIB_OBJECTS := $(LIB_SOURCES:%.c=$(BUILDRESULTS)/%.o)
# Translate the application sources into object file names that can be used as prerequisites
APP_OBJECTS := $(APP_SOURCES:%.c=$(BUILDRESULTS)/%.o)
# Translate the object files into dependency files
# TODO: Adjust variables to add/remove additional lists of sources
DEPFILES := $(LIB_SOURCES:%.c=$(BUILDRESULTS)/%.d) $(APP_SOURCES:%.c=$(BUILDRESULTS)/%.d)

# This function can be used to work back from an object file to
# the appropriate .c file in the source tree
sourcefile = $(patsubst $(BUILDRESULTS)/%.o,%.c,$(1))

# Rule to turn source files into object files
# We use the sourcefile function to convert the object ot the appropriate source
%.o: %.c
.SECONDEXPANSION:
%.o: $$(call sourcefile,$$@) %.d | $$(@D)
	$(Q)$(CC) $(CFLAGS) $(DEPFLAGS) -c $< -o $@

# Rule to build the library and place it in the proper output folder,
# creating that folder if it doesn't exist.
# TODO: Replace with the appropriate library name
$(LIBDIR)/libyour_lib.a: $(LIB_OBJECTS) | $(LIBDIR)
	$(Q)$(AR) $(STATIC_LIB_FLAGS) $@ $^

# Assemble the application out of object files and libraries
# This target is now purely a link step. Split into multiple lines due to length
# TODO: Replace with the appropriate program name and library name, add additional libraries
$(BUILDRESULTS)/your_program:| $(BUILDRESULTS)
$(BUILDRESULTS)/your_program: $(LIBDIR)/libyour_lib.a $(APP_OBJECTS)
$(BUILDRESULTS)/your_program:
	$(Q)$(CC) $(CFLAGS) $(LDFLAGS) $(APP_OBJECTS) -L$(LIBDIR) -lyour_lib -o $@

# Generates a .hex file from the application using objcopy
# TODO: update for your  program name
$(BUILDRESULTS)/your_program.hex: $(BUILDRESULTS)/your_program
	$(Q)$(OBJCOPY) -O ihex $^ $@

# Generates a .bin file from the application using objcopy
# TODO: update for your program name
$(BUILDRESULTS)/your_program.bin: $(BUILDRESULTS)/your_program
	$(Q)$(OBJCOPY) -O binary $^ $@
	$(call ENFORCESIZE,$@,$(MAX_SIZE))

# Removes all generated build output
clean:
	$(Q)$(RM) -r $(BUILDRESULTS)

# Rule to create a mirror of the source tree in the build output folder,
# where object files for APP_SOURCES will be kept
# We sort to eliminate duplicates
# TODO: Update this to reference the appropriate variables
$(patsubst %/,%,$(addprefix $(BUILDRESULTS)/,$(sort $(dir $(APP_SOURCES) $(LIB_SOURCES))))):
	$(Q)mkdir -p $@

# Create the build output folder
$(BUILDRESULTS):
	$(Q)mkdir -p $@

# Create the library output folder
$(LIBDIR):
	$(Q)mkdir -p $@

$(DEPFILES):
include $(wildcard $(DEPFILES))

### Makefile help target, where you can add useful commands.
.PHONY: help
help:
	@echo "\nTo compile the software, run `make`"
	@echo "\nYou can cross-compile the software by setting the TOOLCHAIN variable."
	@echo "	e.g., `make TOOLCHAIN=arm-gcc`"
	@echo "\nSupported toolchains:"
	@echo "	- native (default): uses your system's default settings for"
	@echo "	  CC, AR, LD, etc."
	@echo "	- gcc-arm: compiles with --specs=nosys.specs and the "
	@echo "	  gnu-arm-none-eabi toolchain. You may need to supply additional arguments."
	@echo "Options:"
	@echo "	DEBUG=1 (default) generates a debug build, set to 0 to generate a release builds"
	@echo "Other targets:"
	@echo "	- clean: removes all generated build results"
