###########################################################################
## Makefile generated for component 'discretize_error_dynamics_FOH_kepler_fixedtf'. 
## 
## Makefile     : discretize_error_dynamics_FOH_kepler_fixedtf_rtw.mk
## Generated on : Sun Sep 07 00:23:54 2025
## Final product: ./discretize_error_dynamics_FOH_kepler_fixedtf.lib
## Product type : static-library
## 
###########################################################################

###########################################################################
## MACROS
###########################################################################

# Macro Descriptions:
# PRODUCT_NAME            Name of the system to build
# MAKEFILE                Name of this makefile
# COMPILER_COMMAND_FILE   Compiler command listing model reference header paths
# CMD_FILE                Command file
# MODELLIB                Static library target

PRODUCT_NAME              = discretize_error_dynamics_FOH_kepler_fixedtf
MAKEFILE                  = discretize_error_dynamics_FOH_kepler_fixedtf_rtw.mk
MATLAB_ROOT               = C:/PROGRA~1/MATLAB/R2025a
MATLAB_BIN                = C:/PROGRA~1/MATLAB/R2025a/bin
MATLAB_ARCH_BIN           = $(MATLAB_BIN)/win64
START_DIR                 = C:/Users/thatf/OneDrive/DOCUME~1/ASA/PSP-AS~3/3DORBI~1
TGT_FCN_LIB               = ISO_C
SOLVER_OBJ                = 
CLASSIC_INTERFACE         = 0
MODEL_HAS_DYNAMICALLY_LOADED_SFCNS = 
RELATIVE_PATH_TO_ANCHOR   = ../../..
COMPILER_COMMAND_FILE     = discretize_error_dynamics_FOH_kepler_fixedtf_rtw_comp.rsp
CMD_FILE                  = discretize_error_dynamics_FOH_kepler_fixedtf_rtw.rsp
C_STANDARD_OPTS           = -fwrapv
CPP_STANDARD_OPTS         = -fwrapv
MODELLIB                  = discretize_error_dynamics_FOH_kepler_fixedtf.lib

###########################################################################
## TOOLCHAIN SPECIFICATIONS
###########################################################################

# Toolchain Name:          MinGW64 | gmake (64-bit Windows)
# Supported Version(s):    8.x
# ToolchainInfo Version:   2025a
# Specification Revision:  1.0
# 
#-------------------------------------------
# Macros assumed to be defined elsewhere
#-------------------------------------------

# C_STANDARD_OPTS
# CPP_STANDARD_OPTS
# MINGW_ROOT
# MINGW_C_STANDARD_OPTS

#-----------
# MACROS
#-----------

WARN_FLAGS            = -Wall -W -Wwrite-strings -Winline -Wstrict-prototypes -Wnested-externs -Wpointer-arith -Wcast-align -Wno-stringop-overflow
WARN_FLAGS_MAX        = $(WARN_FLAGS) -Wcast-qual -Wshadow
CPP_WARN_FLAGS        = -Wall -W -Wwrite-strings -Winline -Wpointer-arith -Wcast-align -Wno-stringop-overflow
CPP_WARN_FLAGS_MAX    = $(CPP_WARN_FLAGS) -Wcast-qual -Wshadow
MW_EXTERNLIB_DIR      = $(MATLAB_ROOT)/extern/lib/win64/mingw64
SHELL                 = %SystemRoot%/system32/cmd.exe

TOOLCHAIN_SRCS = 
TOOLCHAIN_INCS = 
TOOLCHAIN_LIBS = -lws2_32

#------------------------
# BUILD TOOL COMMANDS
#------------------------

# C Compiler: GNU C Compiler
CC_PATH = $(MINGW_ROOT)
CC = "$(CC_PATH)/gcc"

# Linker: GNU Linker
LD_PATH = $(MINGW_ROOT)
LD = "$(LD_PATH)/g++"

# C++ Compiler: GNU C++ Compiler
CPP_PATH = $(MINGW_ROOT)
CPP = "$(CPP_PATH)/g++"

# C++ Linker: GNU C++ Linker
CPP_LD_PATH = $(MINGW_ROOT)
CPP_LD = "$(CPP_LD_PATH)/g++"

# Archiver: GNU Archiver
AR_PATH = $(MINGW_ROOT)
AR = "$(AR_PATH)/ar"

# MEX Tool: MEX Tool
MEX_PATH = $(MATLAB_ARCH_BIN)
MEX = "$(MEX_PATH)/mex"

# Download: Download
DOWNLOAD =

# Execute: Execute
EXECUTE = $(PRODUCT)

# Builder: GMAKE Utility
MAKE_PATH = $(MINGW_ROOT)
MAKE = "$(MAKE_PATH)/mingw32-make.exe"


#-------------------------
# Directives/Utilities
#-------------------------

CDEBUG              = -g
C_OUTPUT_FLAG       = -o
LDDEBUG             = -g
OUTPUT_FLAG         = -o
CPPDEBUG            = -g
CPP_OUTPUT_FLAG     = -o
CPPLDDEBUG          = -g
OUTPUT_FLAG         = -o
ARDEBUG             =
STATICLIB_OUTPUT_FLAG =
MEX_DEBUG           = -g
RM                  = @del
ECHO                = @echo
MV                  = @move
RUN                 =

#--------------------------------------
# "Faster Runs" Build Configuration
#--------------------------------------

ARFLAGS              = ruvs
CFLAGS               = -c $(MINGW_C_STANDARD_OPTS) -m64 \
                       -O3
CPPFLAGS             = -c $(CPP_STANDARD_OPTS) -m64 \
                       -O3
CPP_LDFLAGS          =  -static -m64
CPP_SHAREDLIB_LDFLAGS  = -shared -Wl,--no-undefined \
                         -Wl,--out-implib,$(basename $(PRODUCT)).lib
DOWNLOAD_FLAGS       =
EXECUTE_FLAGS        =
LDFLAGS              =  -static -m64
MEX_CPPFLAGS         =
MEX_CPPLDFLAGS       =
MEX_CFLAGS           =
MEX_LDFLAGS          =
MAKE_FLAGS           = -j $(MAX_MAKE_JOBS) -l $(MAX_MAKE_LOAD_AVG) -Oline -f $(MAKEFILE)
SHAREDLIB_LDFLAGS    = -shared -Wl,--no-undefined \
                       -Wl,--out-implib,$(basename $(PRODUCT)).lib



###########################################################################
## OUTPUT INFO
###########################################################################

PRODUCT = ./discretize_error_dynamics_FOH_kepler_fixedtf.lib
PRODUCT_TYPE = "static-library"
BUILD_TYPE = "Static Library"

###########################################################################
## INCLUDE PATHS
###########################################################################

INCLUDES_BUILDINFO = 

INCLUDES = $(INCLUDES_BUILDINFO)

###########################################################################
## DEFINES
###########################################################################

DEFINES_ = -D__USE_MINGW_ANSI_STDIO=1
DEFINES_CUSTOM = 
DEFINES_STANDARD = -DMODEL=discretize_error_dynamics_FOH_kepler_fixedtf

DEFINES = $(DEFINES_) $(DEFINES_CUSTOM) $(DEFINES_STANDARD)

###########################################################################
## SOURCE FILES
###########################################################################

SRCS = $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/discretize_error_dynamics_FOH_kepler_fixedtf_data.c $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/rt_nonfinite.c $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/rtGetNaN.c $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/rtGetInf.c $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/discretize_error_dynamics_FOH_kepler_fixedtf_initialize.c $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/discretize_error_dynamics_FOH_kepler_fixedtf_terminate.c $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/discretize_error_dynamics_FOH_kepler_fixedtf.c $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/linspace.c $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/A_kepler_fixedtf.c $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/discretize_error_dynamics_FOH_kepler_fixedtf_emxutil.c $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/discretize_error_dynamics_FOH_kepler_fixedtf_emxAPI.c $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/discretize_error_dynamics_FOH_kepler_fixedtf_rtwutil.c

ALL_SRCS = $(SRCS)

###########################################################################
## OBJECTS
###########################################################################

OBJS = discretize_error_dynamics_FOH_kepler_fixedtf_data.obj rt_nonfinite.obj rtGetNaN.obj rtGetInf.obj discretize_error_dynamics_FOH_kepler_fixedtf_initialize.obj discretize_error_dynamics_FOH_kepler_fixedtf_terminate.obj discretize_error_dynamics_FOH_kepler_fixedtf.obj linspace.obj A_kepler_fixedtf.obj discretize_error_dynamics_FOH_kepler_fixedtf_emxutil.obj discretize_error_dynamics_FOH_kepler_fixedtf_emxAPI.obj discretize_error_dynamics_FOH_kepler_fixedtf_rtwutil.obj

ALL_OBJS = $(OBJS)

###########################################################################
## PREBUILT OBJECT FILES
###########################################################################

PREBUILT_OBJS = 

###########################################################################
## LIBRARIES
###########################################################################

LIBS = 

###########################################################################
## SYSTEM LIBRARIES
###########################################################################

SYSTEM_LIBS = 

###########################################################################
## ADDITIONAL TOOLCHAIN FLAGS
###########################################################################

#---------------
# C Compiler
#---------------

CFLAGS_OPTS = -fopenmp
CFLAGS_TFL = -msse2 -fno-predictive-commoning
CFLAGS_BASIC = $(DEFINES) $(INCLUDES) @$(COMPILER_COMMAND_FILE)

CFLAGS += $(CFLAGS_OPTS) $(CFLAGS_TFL) $(CFLAGS_BASIC)

#-----------------
# C++ Compiler
#-----------------

CPPFLAGS_OPTS = -fopenmp
CPPFLAGS_TFL = -msse2 -fno-predictive-commoning
CPPFLAGS_BASIC = $(DEFINES) $(INCLUDES) @$(COMPILER_COMMAND_FILE)

CPPFLAGS += $(CPPFLAGS_OPTS) $(CPPFLAGS_TFL) $(CPPFLAGS_BASIC)

#---------------
# C++ Linker
#---------------

CPP_LDFLAGS_ = -fopenmp

CPP_LDFLAGS += $(CPP_LDFLAGS_)

#------------------------------
# C++ Shared Library Linker
#------------------------------

CPP_SHAREDLIB_LDFLAGS_ = -fopenmp

CPP_SHAREDLIB_LDFLAGS += $(CPP_SHAREDLIB_LDFLAGS_)

#-----------
# Linker
#-----------

LDFLAGS_ = -fopenmp

LDFLAGS += $(LDFLAGS_)

#---------------------
# MEX C++ Compiler
#---------------------

MEX_CPP_Compiler_BASIC =  @$(COMPILER_COMMAND_FILE)

MEX_CPPFLAGS += $(MEX_CPP_Compiler_BASIC)

#-----------------
# MEX Compiler
#-----------------

MEX_Compiler_BASIC =  @$(COMPILER_COMMAND_FILE)

MEX_CFLAGS += $(MEX_Compiler_BASIC)

#--------------------------
# Shared Library Linker
#--------------------------

SHAREDLIB_LDFLAGS_ = -fopenmp

SHAREDLIB_LDFLAGS += $(SHAREDLIB_LDFLAGS_)

###########################################################################
## INLINED COMMANDS
###########################################################################


MINGW_C_STANDARD_OPTS = $(C_STANDARD_OPTS)


###########################################################################
## PHONY TARGETS
###########################################################################

.PHONY : all build clean info prebuild download execute


all : build
	@echo "### Successfully generated all binary outputs."


build : prebuild $(PRODUCT)


prebuild : 


download : $(PRODUCT)


execute : download


###########################################################################
## FINAL TARGET
###########################################################################

#---------------------------------
# Create a static library         
#---------------------------------

$(PRODUCT) : $(OBJS) $(PREBUILT_OBJS)
	@echo "### Creating static library "$(PRODUCT)" ..."
	$(AR) $(ARFLAGS)  $(PRODUCT) @$(CMD_FILE)
	@echo "### Created: $(PRODUCT)"


###########################################################################
## INTERMEDIATE TARGETS
###########################################################################

#---------------------
# SOURCE-TO-OBJECT
#---------------------

%.obj : %.c
	$(CC) $(CFLAGS) -o "$@" "$<"


%.obj : %.cpp
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : %.cc
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : %.cp
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : %.cxx
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : %.CPP
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : %.c++
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : %.C
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : $(RELATIVE_PATH_TO_ANCHOR)/%.c
	$(CC) $(CFLAGS) -o "$@" "$<"


%.obj : $(RELATIVE_PATH_TO_ANCHOR)/%.cpp
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : $(RELATIVE_PATH_TO_ANCHOR)/%.cc
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : $(RELATIVE_PATH_TO_ANCHOR)/%.cp
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : $(RELATIVE_PATH_TO_ANCHOR)/%.cxx
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : $(RELATIVE_PATH_TO_ANCHOR)/%.CPP
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : $(RELATIVE_PATH_TO_ANCHOR)/%.c++
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : $(RELATIVE_PATH_TO_ANCHOR)/%.C
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/%.c
	$(CC) $(CFLAGS) -o "$@" "$<"


%.obj : $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/%.cpp
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/%.cc
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/%.cp
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/%.cxx
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/%.CPP
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/%.c++
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/%.C
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : $(START_DIR)/%.c
	$(CC) $(CFLAGS) -o "$@" "$<"


%.obj : $(START_DIR)/%.cpp
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : $(START_DIR)/%.cc
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : $(START_DIR)/%.cp
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : $(START_DIR)/%.cxx
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : $(START_DIR)/%.CPP
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : $(START_DIR)/%.c++
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.obj : $(START_DIR)/%.C
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


discretize_error_dynamics_FOH_kepler_fixedtf_data.obj : $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/discretize_error_dynamics_FOH_kepler_fixedtf_data.c
	$(CC) $(CFLAGS) -o "$@" "$<"


rt_nonfinite.obj : $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/rt_nonfinite.c
	$(CC) $(CFLAGS) -o "$@" "$<"


rtGetNaN.obj : $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/rtGetNaN.c
	$(CC) $(CFLAGS) -o "$@" "$<"


rtGetInf.obj : $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/rtGetInf.c
	$(CC) $(CFLAGS) -o "$@" "$<"


discretize_error_dynamics_FOH_kepler_fixedtf_initialize.obj : $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/discretize_error_dynamics_FOH_kepler_fixedtf_initialize.c
	$(CC) $(CFLAGS) -o "$@" "$<"


discretize_error_dynamics_FOH_kepler_fixedtf_terminate.obj : $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/discretize_error_dynamics_FOH_kepler_fixedtf_terminate.c
	$(CC) $(CFLAGS) -o "$@" "$<"


discretize_error_dynamics_FOH_kepler_fixedtf.obj : $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/discretize_error_dynamics_FOH_kepler_fixedtf.c
	$(CC) $(CFLAGS) -o "$@" "$<"


linspace.obj : $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/linspace.c
	$(CC) $(CFLAGS) -o "$@" "$<"


A_kepler_fixedtf.obj : $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/A_kepler_fixedtf.c
	$(CC) $(CFLAGS) -o "$@" "$<"


discretize_error_dynamics_FOH_kepler_fixedtf_emxutil.obj : $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/discretize_error_dynamics_FOH_kepler_fixedtf_emxutil.c
	$(CC) $(CFLAGS) -o "$@" "$<"


discretize_error_dynamics_FOH_kepler_fixedtf_emxAPI.obj : $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/discretize_error_dynamics_FOH_kepler_fixedtf_emxAPI.c
	$(CC) $(CFLAGS) -o "$@" "$<"


discretize_error_dynamics_FOH_kepler_fixedtf_rtwutil.obj : $(START_DIR)/codegen/lib/discretize_error_dynamics_FOH_kepler_fixedtf/discretize_error_dynamics_FOH_kepler_fixedtf_rtwutil.c
	$(CC) $(CFLAGS) -o "$@" "$<"


###########################################################################
## DEPENDENCIES
###########################################################################

$(ALL_OBJS) : rtw_proj.tmw $(COMPILER_COMMAND_FILE) $(MAKEFILE)


###########################################################################
## MISCELLANEOUS TARGETS
###########################################################################

info : 
	@echo "### PRODUCT = $(PRODUCT)"
	@echo "### PRODUCT_TYPE = $(PRODUCT_TYPE)"
	@echo "### BUILD_TYPE = $(BUILD_TYPE)"
	@echo "### INCLUDES = $(INCLUDES)"
	@echo "### DEFINES = $(DEFINES)"
	@echo "### ALL_SRCS = $(ALL_SRCS)"
	@echo "### ALL_OBJS = $(ALL_OBJS)"
	@echo "### LIBS = $(LIBS)"
	@echo "### MODELREF_LIBS = $(MODELREF_LIBS)"
	@echo "### SYSTEM_LIBS = $(SYSTEM_LIBS)"
	@echo "### TOOLCHAIN_LIBS = $(TOOLCHAIN_LIBS)"
	@echo "### CFLAGS = $(CFLAGS)"
	@echo "### LDFLAGS = $(LDFLAGS)"
	@echo "### SHAREDLIB_LDFLAGS = $(SHAREDLIB_LDFLAGS)"
	@echo "### CPPFLAGS = $(CPPFLAGS)"
	@echo "### CPP_LDFLAGS = $(CPP_LDFLAGS)"
	@echo "### CPP_SHAREDLIB_LDFLAGS = $(CPP_SHAREDLIB_LDFLAGS)"
	@echo "### ARFLAGS = $(ARFLAGS)"
	@echo "### MEX_CFLAGS = $(MEX_CFLAGS)"
	@echo "### MEX_CPPFLAGS = $(MEX_CPPFLAGS)"
	@echo "### MEX_LDFLAGS = $(MEX_LDFLAGS)"
	@echo "### MEX_CPPLDFLAGS = $(MEX_CPPLDFLAGS)"
	@echo "### DOWNLOAD_FLAGS = $(DOWNLOAD_FLAGS)"
	@echo "### EXECUTE_FLAGS = $(EXECUTE_FLAGS)"
	@echo "### MAKE_FLAGS = $(MAKE_FLAGS)"


clean : 
	$(ECHO) "### Deleting all derived files ..."
	$(RM) $(subst /,\,$(PRODUCT))
	$(RM) $(subst /,\,$(ALL_OBJS))
	$(ECHO) "### Deleted all derived files."


