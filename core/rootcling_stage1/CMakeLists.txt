############################################################################
# CMakeLists.txt file for building ROOT core/rootcling_stage1 package
############################################################################

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../dictgen/res)

if(WIN32)
  set_source_files_properties(src/rootcling_stage1.cxx PROPERTIES COMPILE_FLAGS "-D_WIN32 -DNOMINMAX")
else()
  if(CXX_HAS_fno_rtti)
    set_source_files_properties(src/rootcling_stage1.cxx PROPERTIES COMPILE_FLAGS "-fno-rtti")
  endif()
endif()

ROOT_EXECUTABLE(rootcling_stage1 src/rootcling_stage1.cxx
                              $<TARGET_OBJECTS:Clib>
                              $<TARGET_OBJECTS:ClingUtils>
                              $<TARGET_OBJECTS:Dictgen>
                              $<TARGET_OBJECTS:Foundation_Stage1>
                              LIBRARIES ${CLING_LIBRARIES}  ${CMAKE_DL_LIBS} ${CMAKE_THREAD_LIBS_INIT}
                              NOINSTALL)
set_target_properties(rootcling_stage1 PROPERTIES RUNTIME_OUTPUT_DIRECTORY src)
add_dependencies(rootcling_stage1 CLING LLVMRES)
