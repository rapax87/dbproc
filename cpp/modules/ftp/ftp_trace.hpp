/********************************************************************
  Filename:   ftp_trace.hpp
  Author:     
  Created:    
  Description:

*********************************************************************/

#ifndef PLATFORM_MOUDLES_FTP_TRACE_HPP_
#define PLATFORM_MOUDLES_FTP_TRACE_HPP_

#include "platform/modules/trace/trace.hpp"
#include "platform/modules/error/error.hpp"

#define FTP_TRACE_DEBUG(LOG) LOGGER_DEBUG("PLATFORM.FTP", LOG)
#define FTP_TRACE_INFO(LOG) LOGGER_INFO("PLATFORM.FTP", LOG)
#define FTP_TRACE_WARN(LOG)  LOGGER_WARN("PLATFORM.FTP", LOG)
#define FTP_TRACE_ERROR(LOG)  LOGGER_ERROR("PLATFORM.FTP", LOG)
#define FTP_TRACE_FATAL(LOG)  LOGGER_FATAL("PLATFORM.FTP", LOG)

//检查值是否合法，如果有错则打印错误并返回错误码
#define FTP_TRACE_RETURN_ERRCODE_IF_FALSE(CHECK_VAL,RTN_ERRCODE,ERROR_DETAIL) \
	do { if( true != CHECK_VAL) { \
	FTP_TRACE_ERROR("Return code:"<< RTN_ERRCODE<< ","<<ERROR_DETAIL); \
	return RTN_ERRCODE; }  \
	} while (0)
	
#define FTP_TRACE_RETURN_ERRCODE_IF_ERROR(CHECK_VAL,RTN_ERRCODE,ERROR_DETAIL) \
	do { if( SUCCESS != CHECK_VAL) { \
	FTP_TRACE_ERROR("Error code:"<< RTN_ERRCODE<< ","<<ERROR_DETAIL); \
	return RTN_ERRCODE; }  \
	} while (0)

#define FTP_TRACE_RETURN_NULL_IF_ERROR(CHECK_VAL,RTN_ERRCODE,ERROR_DETAIL) \
	do { if( SUCCESS != CHECK_VAL) { \
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

#endif //PLATFORM_MOUDLES_FTP_TRACE_HPP_

