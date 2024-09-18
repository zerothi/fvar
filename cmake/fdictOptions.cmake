# Here we define all options that are related to fdict

# --- compiler feature checks
include(CheckFortranSourceCompiles)
include(CheckFortranSourceRuns)


function(fortran_conv_type type result)
  if("${type}" STREQUAL "INT")
    set(${result} "integer" PARENT_SCOPE)
  elseif("${type}" STREQUAL "REAL")
    set(${result} "real" PARENT_SCOPE)
  elseif("${type}" STREQUAL "CMPLX")
    set(${result} "complex" PARENT_SCOPE)
  elseif("${type}" STREQUAL "LOG")
    set(${result} "logical" PARENT_SCOPE)
  elseif("${type}" STREQUAL "ISO_C")
    set(${result} "type(c_ptr)" PARENT_SCOPE)
  else()
    set(${result} "${type}" PARENT_SCOPE)
    message(VERBOSE "Expecting type to be explicit: ${type}")
  endif()
endfunction()

function(fortran_test_type type result)
  # type = INT,real,REAL for data-type checking
  # define the source code that should be compiled

  # Create unique test-name
  string(REGEX REPLACE "[\\(\\)]" "_" testname "f90_type_${type}")

  # get the data type
  fortran_conv_type(${type} actual_type)
  if("${type}" STREQUAL "ISO_C")
    set(source "
    use, intrinsic :: iso_c_binding
    ${actual_type} :: p
    real :: a
    p = c_loc(a)
    end")
  else()
    set(source "
    ${actual_type} :: a
    print *, a
    end")
  endif()
  check_fortran_source_runs("${source}" "${testname}" SRC_EXT f90)

  # pass result to outside
  set(${result} "${${testname}}" PARENT_SCOPE)
endfunction()

function(fortran_test_rank_size type rank result)
  string(REGEX REPLACE "[\\(\\)]" "_" testname "f90_rank_${type}_${rank}")

  set(_dims "")
  if(${rank} GREATER 0)
    set(_dims ":")
    foreach(IR RANGE 2 ${rank})
      list(APPEND _dims ":")
    endforeach()
    list(JOIN _dims "," _dims)
    set(_dims "(${_dims})")
  endif()

  # get data-type
  fortran_conv_type(${type} actual_type)

  if("${type}" STREQUAL "ISO_C")
    set(source "
    use, intrinsic :: iso_c_binding
    ${actual_type}, allocatable :: p${_dims}
    end")
  else()
    set(source "
    ${actual_type}, allocatable :: a${_dims}
    end")
  endif()

  # Create unique test-name
  check_fortran_source_compiles("${source}" "${testname}" SRC_EXT f90)

  set(${result} "${${testname}}" PARENT_SCOPE)
endfunction()



# Ensure we have the program fypp installed
find_program(FDICT_FYPP fypp
  HINTS "${PROJECT_SOURCE_DIR}/utils"
  )
if(NOT FDICT_FYPP)
  message(FATAL_ERROR "Could not find executable fypp -- it is required for the pre-processing step")
endif()


# Figure out if the compiler supports pure interfaces
set(source "
print *, pure_func()
contains
pure function pure_func() result(out)
character(len=4) :: out
out = 'TRUE'
end function
end")
message(CHECK_START "Use PURE interfaces")
list(APPEND CMAKE_MESSAGE_INDENT "  ")
check_fortran_source_compiles("${source}" f90_pure_interface SRC_EXT f90)
list(POP_BACK CMAKE_MESSAGE_INDENT)

option(FDICT_WITH_PURE_INTERFACE "Use PURE interfaces where possible" "${f90_pure_interface}")
if(${WITH_PURE_INTERFACE})
  message(CHECK_PASS "using")
else()
  message(CHECK_FAIL "not using")
  list(APPEND FDICT_FYPPFLAGS "-DFDICT_WITH_PURE_INTERFACE=$<BOOL:FALSE>")
endif()



# Whether we should use the iso_fortran_env for data-types
message(CHECK_START "Use intrinsic fortran module (iso_fortran_env) for data-types")
list(APPEND CMAKE_MESSAGE_INDENT "  ")

# Check that it iso_fortran_env works
set(source "
use, intrinsic :: iso_fortran_env, only : real64
real(real64) :: x
x = x+1._real64
end")
check_fortran_source_compiles("${source}" f90_fortran_env SRC_EXT f90)
list(POP_BACK CMAKE_MESSAGE_INDENT "  ")

option(FDICT_WITH_ISO_ENV "Use intrinsic fortran module iso_fortran_env" ${f90_fortran_env})
if(${FDICT_WITH_ISO_ENV})

  if(NOT "${f90_fortran_env}")
    message(CHECK_FAIL "could not compile source: ${source}")
    message(FATAL_ERROR "Requested use of iso_fortran_env, but the compiler does not support it! Remove WITH_ISO_ENV=true from command line or change compiler!")
  else()
    message(CHECK_PASS "used")
    list(APPEND FDICT_FYPPFLAGS "-DFDICT_WITH_ISO_ENV=$<BOOL:${FDICT_WITH_ISO_ENV}>")
  endif()

else()
  message(CHECK_FAIL "not used")

endif()


# Parse data-type options
message(CHECK_START "Checking for data-type interfaces")
list(APPEND CMAKE_MESSAGE_INDENT "  ")
foreach(var INT8 INT16 REAL80 REAL128 LOG8 LOG16 LOG64 ISO_C)
  message(CHECK_START "data-type ${var} (WITH_${var})")
  option(FDICT_WITH_${var} "Enable data-type ${var}?" OFF)
  if(${FDICT_WITH_${var}})
    message(CHECK_PASS "added")
    list(APPEND FDICT_FYPPFLAGS "-DFDICT_WITH_${var}=$<BOOL:${FDICT_WITH_${var}}>")
  else()
    message(CHECK_FAIL "not added")
  endif()
endforeach()
list(POP_BACK CMAKE_MESSAGE_INDENT)
message(CHECK_PASS "done")



# Global maxrank
message(CHECK_START "Checking for data-type rank size interfaces")
list(APPEND CMAKE_MESSAGE_INDENT "  ")
set(FDICT_MAXRANK 5 CACHE STRING "Maximum default rank size")
message(STATUS "using default rank size FDICT_MAXRANK = ${FDICT_MAXRANK}")

# Parse rank sizes
foreach(var INT REAL CMPLX LOG)
  message(CHECK_START "rank size of ${var} (FDICT_MAXRANK_${var})")
  set(FDICT_MAXRANK_${var} ${FDICT_MAXRANK} CACHE STRING "Maximum rank for data types ${var}")

  # Test the compilation of the datatype
  list(APPEND CMAKE_MESSAGE_INDENT "  ")
  fortran_test_rank_size(${var} ${FDICT_MAXRANK_${var}} result)
  list(POP_BACK CMAKE_MESSAGE_INDENT)

  if(NOT "${result}")
    message(CHECK_FAIL "could not compile type ${var} in rank ${FDICT_MAXRANK_${var}}")
    message(FATAL_ERROR "Requested ${FDICT_MAXRANK_${var}} dimensions for data-type ${var}; the compiler does not support it! Reduce rank size or change compiler options to enable this!")
  else()
    message(CHECK_PASS "got size = ${FDICT_MAXRANK_${var}}")
    list(APPEND FDICT_FYPPFLAGS "-DFDICT_MAXRANK_${var}=${FDICT_MAXRANK_${var}}")
  endif()
endforeach()

# Now for the 1-default dimensions
set(var "ISO_C")
message(CHECK_START "rank size of ${var} (FDICT_MAXRANK_${var})")
set(FDICT_MAXRANK_${var} "1" CACHE STRING "Maximum rank for data types ${var}")

# Test the compilation of the datatype
list(APPEND CMAKE_MESSAGE_INDENT "  ")
fortran_test_rank_size(${var} ${FDICT_MAXRANK_${var}} result)
list(POP_BACK CMAKE_MESSAGE_INDENT)

if(NOT "${result}")
  message(CHECK_FAIL "could not compile type ${var} in rank ${FDICT_MAXRANK_${var}}")
  message(FATAL_ERROR "Requested ${FDICT_MAXRANK_${var}} dimensions for data-type ${var}; the compiler does not support it! Reduce rank size or change compiler options to enable this!")
else()
  message(CHECK_PASS "got size = ${FDICT_MAXRANK_${var}}")
  list(APPEND FDICT_FYPPFLAGS "-DFDICT_MAXRANK_${var}=${FDICT_MAXRANK_${var}}")
endif()
unset(var)

list(POP_BACK CMAKE_MESSAGE_INDENT)
message(CHECK_PASS "done")
