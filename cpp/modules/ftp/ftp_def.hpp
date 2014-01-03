锘?********************************************************************
Filename:      ftp_def.hpp
Author:        
Created:       
Description:
*********************************************************************/

#ifndef PLATFORM_FTP_DEF_HPP_
#define PLATFORM_FTP_DEF_HPP_

#ifdef WIN32
#ifdef FTP_EXPORT
#define FTP_IMPORT_EXPORT __declspec(dllexport)
#else//NOT FTP__EXPORT
#define FTP_IMPORT_EXPORT __declspec(dllimport)
#endif//FTP_EXPORT
#else//NOT WIN32
#define FTP_IMPORT_EXPORT
#endif//WIN32

enum  
{  
	OS_DEFAULT = 0,  
	OS_LINUX   = 1,  
	OS_WIN32   = 2,  
	OS_AIX     = 3,  
	OS_HP_UNIX = 4,  
	OS_SUNOS   = 5  
};  

#endif  //PLATFORM_FTP_CLIENT_DEF_HPP_
