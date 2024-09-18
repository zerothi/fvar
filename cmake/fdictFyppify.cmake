# Preprocesses a list of files with given preprocessor and preprocessor options
#
# Args:
#     preproc [in]: Preprocessor program
#     preprocopts [in]: Preprocessor options
#     srcext [in]: File extension of the source files
#     trgext [in]: File extension of the target files
#     srcfiles [in]: List of the source files
#     trgfiles [out]: Contains the list of the preprocessed files on exit
#
function(fdict_preprocess preproc preprocopts srcext trgext srcfiles trgfiles)

  set(_trgfiles)
  foreach(srcfile IN LISTS srcfiles)
    string(REGEX REPLACE "\\.${srcext}$" ".${trgext}" trgfile ${srcfile})
    add_custom_command(
      OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${trgfile}"
      COMMAND ${preproc} ${preprocopts} "${CMAKE_CURRENT_SOURCE_DIR}/${srcfile}" "${CMAKE_CURRENT_BINARY_DIR}/${trgfile}"
      MAIN_DEPENDENCY "${CMAKE_CURRENT_SOURCE_DIR}/${srcfile}")
    list(APPEND _trgfiles "${CMAKE_CURRENT_BINARY_DIR}/${trgfile}")
  endforeach()
  set(${trgfiles} ${_trgfiles} PARENT_SCOPE)

endfunction()

# Define a function for fyppifying sources
function(fdict_fyppify)
 # Parse arguments
 set(options "")
 set(oneValueArgs FYPP EXTIN EXTOUT COMMENT OUTPUT)
 set(multiValueArgs FLAGS FILES)
 cmake_parse_arguments(
   _fyppify "${options}" "${oneValueArgs}" "${multiValueArgs}"
   ${ARGN}
   )

 # Now handle arguments
 #[==[
 message(INFO "Before parsing inputs:
 comment=${_fyppify_COMMENT}
 fypp=${_fyppify_FYPP}
 EXTIN=${_fyppify_EXTIN}
 EXTOUT=${_fyppify_EXTOUT}
 FLAGS=${_fyppify_FLAGS}
 FILES=${_fyppify_FILES}
 ")
 ]==]

 if(NOT DEFINED _fyppify_FYPP)
   set(_fyppify_FYPP "${FDICT_FYPP}")
 endif()
 if(NOT DEFINED _fyppify_EXTIN)
   set(_fyppify_EXTIN "fypp")
 endif()
 if(NOT DEFINED _fyppify_EXTOUT)
   set(_fyppify_EXTOUT "f90")
 endif()
 if(DEFINED _fyppify_COMMENT)
   message(VERBOSE "-- Setting up fyppify: ${_fyppify_COMMENT}")
 endif()
 if(NOT DEFINED _fyppify_FLAGS)
   set(_fyppify_FLAGS "")
 endif()
 if(NOT DEFINED _fyppify_FILES)
   message(FATAL_ERROR "fyppify requires FILES arguments to determine which files to preprocess")
 endif()

 #[==[
 message(INFO "After parsing inputs:
 comment=${_fyppify_COMMENT}
 fypp=${_fyppify_FYPP}
 EXTIN=${_fyppify_EXTIN}
 EXTOUT=${_fyppify_EXTOUT}
 FLAGS=${_fyppify_FLAGS}
 FILES=${_fyppify_FILES}
 ")
 ]==]

 # Lets do the preprocessing
 fdict_preprocess("${_fyppify_FYPP}" "${_fyppify_FLAGS}"
   "${_fyppify_EXTIN}" "${_fyppify_EXTOUT}"
   "${_fyppify_FILES}" _outfiles)
 if(DEFINED _fyppify_OUTPUT)
   set(${_fyppify_OUTPUT} ${_outfiles} PARENT_SCOPE)
 endif()

endfunction()
