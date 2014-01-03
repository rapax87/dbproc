锘?********************************************************************
  Filename:   ftp_trace.hpp
  Author:     
  Created:    
  Description:

*********************************************************************/

#ifndef UBP_PLATFORM_MOUDLES_FTP_TRACE_HPP_
#define UBP_PLATFORM_MOUDLES_FTP_TRACE_HPP_

#include "platform/modules/trace/ubp_trace.hpp"
#include "platform/modules/error/ubp_error.hpp"

#define FTP_TRACE_DEBUG(LOG) UBP_LOGGER_DEBUG("PLATFORM.FTP", LOG)
#define FTP_TRACE_INFO(LOG) UBP_LOGGER_INFO("PLATFORM.FTP", LOG)
#define FTP_TRACE_WARN(LOG)  UBP_LOGGER_WARN("PLATFORM.FTP", LOG)
#define FTP_TRACE_ERROR(LOG)  UBP_LOGGER_ERROR("PLATFORM.FTP", LOG)
#define FTP_TRACE_FATAL(LOG)  UBP_LOGGER_FATAL("PLATFORM.FTP", LOG)

#define FTP_TRACE_RETURN_ERRCODE_IF_FALSE(CHECK_VAL,RTN_ERRCODE,ERROR_DETAIL) \
	do { if( true != CHECK_VAL) { \
	FTP_TRACE_ERROR("Return code:"<< RTN_ERRCODE<< ","<<ERROR_DETAIL); \
	return RTN_ERRCODE; }  \
	} while (0)
	
#define FTP_TRACE_RETURN_ERRCODE_IF_ERROR(CHECK_VAL,RTN_ERRCODE,ERROR_DETAIL) \
	do { if( UBP_SUCCESS != CHECK_VAL) { \
	FTP_TRACE_ERROR("Error code:"<< RTN_ERRCODE<< ","<<ERROR_DETAIL); \
	return RTN_ERRCODE; }  \
	} while (0)

#define FTP_TRACE_RETURN_NULL_IF_ERROR(CHECK_VAL,RTN_ERRCODE,ERROR_DETAIL) \
	do { if( UBP_SUCCESS != CHECK_VAL) { \
	FTP_TRACE_ERROR("Error code:"<< RTN_ERRCODE<< ","<<ERROR_DETAIL); \
	return NULL; }  \
	} while (0)

#define FTP_TRACE_RETURN_ERRCODE_IF_NULLPOINTER(POINTER,RTN_ERRCODE,ERROR_DETAIL) \
    do { if(NULL==POINTER) { \
    FTP_TRACE_ERROR("Error code:"<< RTN_ERRCODE<< ","<<ERROR_DETAIL); \
    return RTN_ERRCODE; }  \
    } while (0)

#define FTP_TRACE_RETURN_NULL_IF_NULLPOINTER(POINTER,RTN_ERRCODE,ERROR_DETAIL) \
	do { if(NULL==POINTER) { \
	FTP_TRACE_ERROR("Error code:"<< RTN_ERRCODE<< ","<<ERROR_DETAIL); \
	return NULL; }  \
	} while (0)

#endif //UBP_PLATFORM_MOUDLES_FTP_TRACE_HPP_

