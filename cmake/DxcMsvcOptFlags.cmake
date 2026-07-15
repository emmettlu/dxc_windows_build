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
