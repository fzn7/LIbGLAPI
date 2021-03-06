FLASCC:=X
FLEX:=X
AS3COMPILER:=asc2.jar

$?UNAME=$(shell uname -s)
ifneq (,$(findstring CYGWIN,$(UNAME)))
	$?nativepath=$(shell cygpath -at mixed $(1))
	$?unixpath=$(shell cygpath -at unix $(1))
else
	$?nativepath=$(abspath $(1))
	$?unixpath=$(abspath $(1))
endif

ifneq (,$(findstring "asc2.jar","$(AS3COMPILER)"))
	$?AS3COMPILERARGS=java $(JVMARGS) -jar $(call nativepath,$(FLASCC)/usr/lib/$(AS3COMPILER)) -merge -md 
else
	echo "ASC is no longer supported" ; exit 1 ;
endif

all: check compile

check:
	@if [ -d $(FLASCC)/usr/bin ] ; then true ; \
	else echo "Couldn't locate FLASCC sdk directory, please invoke make with \"make FLASCC=/path/to/FLASCC/sdk ...\"" ; exit 1 ; \
	fi

	@if [ -d "$(FLEX)/bin" ] ; then true ; \
	else echo "Couldn't locate Flex sdk directory, please invoke make with \"make FLEX=/path/to/flex  ...\"" ; exit 1 ; \
	fi
	
compile:
	@mkdir -p install/usr/lib
	@mkdir -p install/usr/include
	
	@echo "Compiling libGL.as"
	$(AS3COMPILERARGS) -md -strict -optimize -abcfuture -AS3 \
	-import $(call nativepath,$(FLASCC)/usr/lib/builtin.abc) \
	-import $(call nativepath,$(FLASCC)/usr/lib/playerglobal.abc) \
	-import $(call nativepath,$(FLASCC)/usr/lib/BinaryData.abc) \
	-import $(call nativepath,$(FLASCC)/usr/lib/C_Run.abc) \
	-import $(call nativepath,$(FLASCC)/usr/lib/CModule.abc) \
	-in src/com/adobe/utils_gls3d/AGALMiniAssembler.as \
	-in src/com/adobe/utils_gls3d/AGALMacroAssembler.as \
	-in src/com/adobe/utils_gls3d/FractalGeometryGenerator.as \
	-in src/com/adobe/utils_gls3d/PerspectiveMatrix3D.as \
	-in src/com/adobe/utils_gls3d/macro/AGALPreAssembler.as \
	-in src/com/adobe/utils_gls3d/macro/AGALVar.as \
	-in src/com/adobe/utils_gls3d/macro/Expression.as \
	-in src/com/adobe/utils_gls3d/macro/BinaryExpression.as \
	-in src/com/adobe/utils_gls3d/macro/ExpressionParser.as \
	-in src/com/adobe/utils_gls3d/macro/NumberExpression.as \
	-in src/com/adobe/utils_gls3d/macro/UnaryExpression.as \
	-in src/com/adobe/utils_gls3d/macro/VariableExpression.as \
	-in src/com/adobe/utils_gls3d/macro/VM.as \
	libGL.as
	@mv libGL.abc install/usr/lib/
	
	@echo "-> Generate SWIG wrappers around the functions in the library"
	"$(FLASCC)/usr/bin/swig" -as3 -module LibGLAPI -outdir . -includeall -ignoremissing -o LibGL_wrapper.c LibGLAPI.i
	
	@echo "-> Compile the SWIG wrapper to ABC"
	$(AS3COMPILERARGS) -import $(call nativepath,$(FLASCC)/usr/lib/builtin.abc) -import $(call nativepath,$(FLASCC)/usr/lib/playerglobal.abc) libGLAPI.as
	# rename the output so the compiler doesn't accidentally use both this .as file along with the .abc file we just produced
	@mv libGLAPI.as libGLAPI.as3

	@$(FLASCC)/usr/bin/g++ -fno-exceptions -O4 -c -Iinstall/usr/include/ libGL.cpp
	@$(FLASCC)/usr/bin/ar crus libGL.a install/usr/lib/libGL.abc libGL.o
	
	@$(FLASCC)/usr/bin/gcc -fno-exceptions -O4 -c LibGL_wrapper.c

	@echo "-> Compile the library into a SWC"
	@$(FLASCC)/usr/bin/g++ -Werror -Wno-write-strings -Wno-trigraphs libGLAPI.abc -lGL -lglut LibGL_wrapper.o libGL.a libGLmain.c -emit-swc=com.adumentum -o LibGLAPI.swc
	
	@rm -f libGL.o

install: check
	@cp -r install/usr/include/ $(FLASCC)/usr/include
	@cp -r install/usr/lib/ $(FLASCC)/usr/lib
	@cp $(FLASCC)/usr/SDL_opengl.h $(FLASCC)/usr/include/SDL/
