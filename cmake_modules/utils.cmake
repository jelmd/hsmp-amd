################################################################################
##
## The University of Illinois/NCSA
## Open Source License (NCSA)
##
## Copyright (c) 2020-2023, Advanced Micro Devices, Inc. All rights reserved.
##
## Portions Copyright (c) 2025 Jens Elkner, OvGU Magdeburg.
################################################################################

## Parses the VERSION_STRING variable and places
## the first, second and third number values in
## the major, minor and patch variables.
function( parse_version VERSION_STRING )

    string ( FIND ${VERSION_STRING} "-" STRING_INDEX )

    if ( ${STRING_INDEX} GREATER -1 )
        math ( EXPR STRING_INDEX "${STRING_INDEX} + 1" )
        string ( SUBSTRING ${VERSION_STRING} ${STRING_INDEX} -1 VERSION_BUILD )
    endif ()

    string ( REGEX MATCHALL "[0123456789]+" VERSIONS ${VERSION_STRING} )
    list ( LENGTH VERSIONS VERSION_COUNT )

    if ( ${VERSION_COUNT} GREATER 0)
        list ( GET VERSIONS 0 MAJOR )
    else()
		set ( MAJOR "0" )
    endif ()

    if ( ${VERSION_COUNT} GREATER 1 )
        list ( GET VERSIONS 1 MINOR )
    else()
		set ( MINOR "0" )
    endif ()

    if ( ${VERSION_COUNT} GREATER 2 )
        list ( GET VERSIONS 2 PATCH )
    else()
		set ( PATCH "0" )
    endif ()

	set ( VERSION_MAJOR ${MAJOR} PARENT_SCOPE )
	set ( VERSION_MINOR ${MINOR} PARENT_SCOPE )
	set ( VERSION_PATCH ${PATCH} PARENT_SCOPE )
	set ( VERSION_STRING "${MAJOR}.${MINOR}.${PATCH}" PARENT_SCOPE )
	set ( VERSION_BUILD "${VERSION_BUILD}" PARENT_SCOPE )
endfunction ()

function (getCommitHash)
	if (NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.commit")
		execute_process (COMMAND git rev-parse --short HEAD
			WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
			OUTPUT_VARIABLE GIT_HASH
			OUTPUT_STRIP_TRAILING_WHITESPACE
			RESULT_VARIABLE RESULT )
	else()
		execute_process(COMMAND cat .commit
			WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
			OUTPUT_VARIABLE GIT_HASH
			OUTPUT_STRIP_TRAILING_WHITESPACE
			RESULT_VARIABLE RESULT )
	endif()
	if (NOT DEFINED GIT_HASH)
		set(GIT_HASH "unknown")
	endif()
	set( COMMIT_HASH "${GIT_HASH}" PARENT_SCOPE)
endfunction()

## Gets the current version of the repository
## using versioning tags and git describe.
## Passes back a packaging version string
## and a library version string.
## Vendors may use PKG_VERSION_SN to add another digit to the version string.
function(get_version_from_tag DEFAULT_VERSION_STRING VERSION_PREFIX)
	if (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.version")
		execute_process (COMMAND cat .version
			WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
			OUTPUT_VARIABLE GIT_TAG_STRING
			OUTPUT_STRIP_TRAILING_WHITESPACE
			RESULT_VARIABLE RESULT )
	endif()
	getCommitHash()
	if ("${COMMIT_HASH}" STREQUAL "unknown")
		if (DEFINED VERSION_BUILD)
			set(COMMIT_HASH "${VERSION_BUILD}")
		endif()
	endif()
	if (NOT DEFINED GIT_TAG_STRING)
		set(GIT_TAG_STRING "${VERSION_PREFIX}-${DEFAULT_VERSION_STRING}-${COMMIT_HASH}")
	endif()
	message("Using version: ${GIT_TAG_STRING}")
	parse_version ( ${GIT_TAG_STRING} )
	if (DEFINED PKG_VERSION_SN)
		set(VERSION_STRING "${VERSION_STRING}.${PKG_VERSION_SN}" PARENT_SCOPE)
	else()
		set(VERSION_STRING "${VERSION_STRING}" PARENT_SCOPE )
	endif()
	set( VERSION_MAJOR  "${VERSION_MAJOR}" PARENT_SCOPE )
	set( VERSION_MINOR  "${VERSION_MINOR}" PARENT_SCOPE )
	set( VERSION_PATCH  "${VERSION_PATCH}" PARENT_SCOPE )
	set( COMMIT_HASH "${COMMIT_HASH}" PARENT_SCOPE)
endfunction()

function(get_package_version_number DEFAULT_VERSION_STRING VERSION_PREFIX)
    get_version_from_tag(${DEFAULT_VERSION_STRING} ${VERSION_PREFIX})

    set(VERSION_ID  "${COMMIT_HASH}" PARENT_SCOPE )
	set(VERSION_STR "${VERSION_STRING}" PARENT_SCOPE)
	set(PKG_VERSION_STR "${VERSION_STRING}" PARENT_SCOPE)
    set(VERSION_STRING "${VERSION_STRING}" PARENT_SCOPE)
    set(VERSION_MAJOR  "${VERSION_MAJOR}" PARENT_SCOPE)
    set(VERSION_MINOR  "${VERSION_MINOR}" PARENT_SCOPE)
    set(VERSION_PATCH  "${VERSION_PATCH}" PARENT_SCOPE)
endfunction()
