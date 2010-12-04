# The script is taken from http://code.google.com/p/nvidia-texture-tools/

#
# Try to find OpenEXR's libraries, and include path.
# Once done this will define:
#
# OPENEXR_FOUND = OpenEXR found. 
# OPENEXR_INCLUDE_PATHS = OpenEXR include directories.
# OPENEXR_LIBRARIES = libraries that are needed to use OpenEXR.
# 

SET(OPENEXR_LIBRARIES)

SET(LIBRARY_PATHS 
    /usr/lib
    /usr/local/lib
    /sw/lib
    /opt/local/lib
    $ENV{PROGRAM_FILES}/OpenEXR/lib/static)

FIND_PATH(OPENEXR_INCLUDE_PATH ImfRgbaFile.h
    PATH_SUFFIXES OpenEXR
    /usr/include
    /usr/local/include
    /sw/include
    /opt/local/include)

FIND_LIBRARY(OPENEXR_HALF_LIBRARY 
    NAMES Half
    PATHS ${LIBRARY_PATHS})

FIND_LIBRARY(OPENEXR_IEX_LIBRARY 
    NAMES Iex
    PATHS ${LIBRARY_PATHS})

FIND_LIBRARY(OPENEXR_IMATH_LIBRARY
    NAMES Imath
    PATHS ${LIBRARY_PATHS})

FIND_LIBRARY(OPENEXR_ILMIMF_LIBRARY
    NAMES IlmImf
    PATHS ${LIBRARY_PATHS})

IF (OPENEXR_INCLUDE_PATH AND OPENEXR_IMATH_LIBRARY AND OPENEXR_ILMIMF_LIBRARY AND OPENEXR_IEX_LIBRARY AND OPENEXR_HALF_LIBRARY)
    SET(OPENEXR_FOUND TRUE)
    SET(OPENEXR_INCLUDE_PATHS ${OPENEXR_INCLUDE_PATH} CACHE STRING "The include paths needed to use OpenEXR")
    SET(OPENEXR_LIBRARIES ${OPENEXR_IMATH_LIBRARY} ${OPENEXR_ILMIMF_LIBRARY} ${OPENEXR_IEX_LIBRARY} ${OPENEXR_HALF_LIBRARY} opencv_zlib CACHE STRING "The libraries needed to use OpenEXR")
ENDIF ()

IF(OPENEXR_FOUND)
    IF(NOT OPENEXR_FIND_QUIETLY)
        MESSAGE(STATUS "Found OpenEXR: ${OPENEXR_ILMIMF_LIBRARY}")
    ENDIF()
ELSE()
    IF(OPENEXR_FIND_REQUIRED)
        MESSAGE(FATAL_ERROR "Could not find OpenEXR library")
    ENDIF()
ENDIF()

MARK_AS_ADVANCED(
    OPENEXR_INCLUDE_PATHS
    OPENEXR_ILMIMF_LIBRARY
    OPENEXR_IMATH_LIBRARY
    OPENEXR_IEX_LIBRARY
    OPENEXR_HALF_LIBRARY)
