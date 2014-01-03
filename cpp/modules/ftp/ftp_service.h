/********************************************************************
  Filename:    ftp_service.h
  Author:      
  Created:     
  Description:

*********************************************************************/
#ifndef    PLATFORM_FTP_SERVICE_HPP_
#define    PLATFORM_FTP_SERVICE_HPP_

#include <stdio.h>

#include <string>
#include <sstream>
#include <iostream>
#include <vector>

//#include <ace/OS.h>
#include <ace/OS_main.h>
#include <ace/Reactor.h>
#include <ace/SOCK_Acceptor.h>
#include <ace/SOCK_Connector.h>
#include <ace/SOCK_Stream.h>
#include <ace/Acceptor.h>
#include <ace/Connector.h>
#include "platform/modules/ftp/ftp_def.hpp"


#define FTP_PORT 21

/************************************************************************/
/* ACE库实现FTP功能，支持发送和接受文件                                 */
/************************************************************************/
namespace ubp
{
namespace platform
{
namespace ftp
{

class FTP_IMPORT_EXPORT FTPService
{
public:
    FTPService(const std::string &remote_ip,
               const std::string &user_name, const std::string &pass_word,
               const u_short remote_port=FTP_PORT, int os_type = OS_DEFAULT);

    virtual ~FTPService();

    bool uploadFile(const std::string& ldir, const std::string& lfilename,
                    const std::string& sdir, const std::string& sfilename="");
    bool uploadFile(std::vector<std::string>& filenames,
                    const std::string& sdir, const std::string& ldir);

    bool downloadFile(const std::string& sdir,
                      const std::string& sfilename, const std::string& ldir);
    bool downloadFile(std::vector<std::string>& filenames,
                      const std::string& sdir, const std::string& ldir);


private:


    std::string user_name_, pass_word_;
    std::string remote_ip_;
    u_short remote_port_;


    int os_type_;


};

}//namespace ftp
}//namespace platform
}//namespace ubp

#endif // PLATFORM_FTP_SERVICE_HPP_
