if(CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
  # GNU compiler gfortran
  set(
    CMAKE_Fortran_FLAGS_INIT
    "-fimplicit-none"
  )
  set(
    CMAKE_Fortran_FLAGS_RELEASE_INIT
    "-O3"
    "-ftree-vectorize"
    "-fprefetch-loop-arrays"
  )
  set(
    CMAKE_Fortran_FLAGS_DEBUG_INIT
    "-Wall"
    "-Wextra"
    "-Wimplicit-procedure"
  )
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "^Intel")
  # Intel compiler ifort
  set(
    CMAKE_Fortran_FLAGS_INIT
  )
  set(
    CMAKE_Fortran_FLAGS_RELEASE_INIT
    "-O2"
  )
  set(
    CMAKE_Fortran_FLAGS_DEBUG_INIT
    "-warn declarations,general,usage,interfaces,unused"
  )
else()
  # unknown compiler (possibly)
  set(
    CMAKE_Fortran_FLAGS_INIT
  )
  set(
    CMAKE_Fortran_FLAGS_RELEASE_INIT
  )
  set(
    CMAKE_Fortran_FLAGS_DEBUG_INIT
  )
endif()
list(JOIN CMAKE_Fortran_FLAGS_INIT " " CMAKE_Fortran_FLAGS_INIT)
list(JOIN CMAKE_Fortran_FLAGS_RELEASE_INIT " " CMAKE_Fortran_FLAGS_RELEASE_INIT)
list(JOIN CMAKE_Fortran_FLAGS_DEBUG_INIT " " CMAKE_Fortran_FLAGS_DEBUG_INIT)
