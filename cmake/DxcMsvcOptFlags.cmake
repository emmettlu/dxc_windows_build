# MSVC flags injected by dxc_windows_build CI.
# Applied after project(LLVM) so compiler ID is known, and before add_subdirectory
# targets are created (add_compile_options only affects later targets).
#
# Conflict notes (checked against DirectXShaderCompiler CMake):
# - /GR-   HARD CONFLICT: PredefinedParams sets LLVM_ENABLE_RTTI=ON and
#          LLVM_ENABLE_EH=ON; targets compile with RTTI + /EHsc. Global /GR-
#          causes D9025 and breaks dynamic_cast / COM / exception paths.
# - /MD /MDd  REDUNDANT: ChooseMSVCCRT / CMake defaults already set CRT.
# - /Zi + /DEBUG on Release: DXC HandleLLVMOptions forces them; CI patches that
#          block out, and this file scrubs leftovers + /DEBUG:NONE.
# - /GL + /LTCG  OVERLAP: LLVM_ENABLE_LTO path also adds these; safe to
#          enable here for size-focused Release without flipping that option.
# - /OPT:REF /OPT:ICF kept for size (no /DEBUG).
# - /guard:cf + /CETCOMPAT + /INCREMENTAL:NO stripped from root CMakeLists by CI.
# - /GS-   INTENTIONAL override of buffer security checks for size.
# - /Os vs /O2  CMake default Release is /O2; /Os may warn D9025 and win by order.
# - /arch:AVX2  no CMake conflict; binary requires AVX2 hosts.
# - /fp:fast    no CMake conflict; may change host FP semantics inside DXC.
# - /MANIFEST:NO enabled for smaller images.

if(NOT MSVC)
  return()
endif()

message(STATUS "dxc_windows_build: applying optimized MSVC compile/link flags (no PDB)")

# Scrub PDB/debug flags if already present (HandleLLVMOptions may run later;
# CI also patches that file; this is a belt-and-suspenders scrub for current vars).
macro(dxc_wb_scrub_debug_flags _var)
  if(DEFINED ${_var})
    string(REGEX REPLACE "(^| )[/-]Z[iI7]( |$)" " " ${_var} "${${_var}}")
    string(REGEX REPLACE "(^| )[/-]DEBUG(:[^ ]*)?( |$)" " " ${_var} "${${_var}}")
    string(REGEX REPLACE "  +" " " ${_var} "${${_var}}")
    string(STRIP "${${_var}}" ${_var})
  endif()
endmacro()

foreach(_f
    CMAKE_C_FLAGS_RELEASE CMAKE_CXX_FLAGS_RELEASE
    CMAKE_EXE_LINKER_FLAGS_RELEASE CMAKE_SHARED_LINKER_FLAGS_RELEASE
    CMAKE_MODULE_LINKER_FLAGS_RELEASE
    CMAKE_C_FLAGS_RELWITHDEBINFO CMAKE_CXX_FLAGS_RELWITHDEBINFO
    CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO
    CMAKE_MODULE_LINKER_FLAGS_RELWITHDEBINFO)
  dxc_wb_scrub_debug_flags(${_f})
endforeach()

add_compile_options(
  $<$<CONFIG:Debug>:/arch:AVX2>
  $<$<CONFIG:Debug>:/MP>

  $<$<CONFIG:Release>:/arch:AVX2>
  $<$<CONFIG:Release>:/fp:fast>
  $<$<CONFIG:Release>:/Gy>
  $<$<CONFIG:Release>:/GL>
  $<$<CONFIG:Release>:/Gw>
  $<$<CONFIG:Release>:/MP>
  $<$<CONFIG:Release>:/Oi>
  $<$<CONFIG:Release>:/Os>
  $<$<CONFIG:Release>:/GS->
)

add_compile_options(
  $<$<CONFIG:RelWithDebInfo>:/arch:AVX2>
  $<$<CONFIG:RelWithDebInfo>:/fp:fast>
  $<$<CONFIG:RelWithDebInfo>:/Gy>
  $<$<CONFIG:RelWithDebInfo>:/Gw>
  $<$<CONFIG:RelWithDebInfo>:/MP>
  $<$<CONFIG:RelWithDebInfo>:/Oi>
  $<$<CONFIG:RelWithDebInfo>:/GS->
)

add_link_options(
  $<$<CONFIG:Release>:/LTCG>
  $<$<CONFIG:Release>:/MANIFEST:NO>
  $<$<CONFIG:Release>:/MERGE:_RDATA=.rdata>
  $<$<CONFIG:Release>:/OPT:REF>
  $<$<CONFIG:Release>:/OPT:ICF>
  $<$<CONFIG:Release>:/DEBUG:NONE>

  $<$<CONFIG:RelWithDebInfo>:/MANIFEST:NO>
  $<$<CONFIG:RelWithDebInfo>:/OPT:REF>
  $<$<CONFIG:RelWithDebInfo>:/OPT:ICF>
  $<$<CONFIG:RelWithDebInfo>:/DEBUG:NONE>
)
