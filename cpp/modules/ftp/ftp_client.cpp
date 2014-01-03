
/********************************************************************
  Filename:    ftp_client.cpp
  Author:      
  Created:     
  Description:

*********************************************************************/
#include "ftp_client.hpp"  
//#include "platform/modules/ftp/ftp_client.hpp"  
#include <stdio.h>  
#include <stdlib.h>  
//#include <ace/OS.h>  
#include <ace/OS_main.h>  
#include <ace/FILE_Addr.h>  
#include <ace/FILE_Connector.h>  
#include <ace/FILE_IO.h>  
#include <ace/OS_NS_string.h>  
#include <ace/OS_NS_stdio.h>  
#include "ftp_trace.hpp"  

using namespace ubp::platform::ftp;
  
FTPClient::FTPClient(const std::string &remote_ip, const u_short remote_port,  
                     const std::string &user_name, const std::string &pass_word,  
                     int os_type)  
{  
    this->user_name_ = user_name;  
    this->pass_word_ = pass_word;  
    this->remote_addr_.set((u_short)remote_port, remote_ip.c_str());  
  
    this->os_type_ = os_type;  
}  
  
FTPClient::~FTPClient()  
{  
    peer_.close_writer();  
    peer_.close_reader();  
    peer_.close();  
}  
  
/*接收FTP应答*/  
bool FTPClient::Recv(std::string &response)  
{  
    std::string     line;  
    ACE_Time_Value  tv(MAX_RECV_TIMEOUT_SECOND, MAX_RECV_TIMEOUT_MILLISECOND);  
  
    response.clear();  
  
    while (true)  
    {  
        char c;  
        switch (this->peer_.recv_n(&c, 1, &tv))  
        {  
        case   0:  
        case  -1:  
            return false;  
        default:  
            line.append(1, c);  
            break;  
        }  
  
        //if ('\n' == c)  
		if ('\n' == c)  
        {  
            response = line;  
            break;  
        }  
    }  
    std::cout << response << std::endl;  
    return true;  
}  
  
/*发送FTP命令*/  
bool FTPClient::Send(const std::string &command)  
{  
    std::cout << command;  
    if (static_cast<ssize_t>(command.length()) == this->peer_.send_n(command.c_str(), command.length()))  
    {  
        return true;  
    }  
    else  
    {  
        return false;  
    }  
}  
  
/*登录*/  
bool FTPClient::LogoIn()  
{  
    ACE_Time_Value  tv(MAX_CONN_TIMEOUT_SECOND, MAX_CONN_TIMEOUT_MILLISECOND);  
    std::stringstream USER, PASS, SYST;  
    std::string  ftp_resp;  
  
    if (this->connector_.connect(this->peer_, this->remote_addr_, &tv) == -1)  
    {  
        ACE_ERROR_RETURN((LM_ERROR, ACE_TEXT("(%P|%t) %p\n"), ACE_TEXT("connection failed")), false);  
    }  
  
    ACE_DEBUG((LM_DEBUG, ACE_TEXT("(%P|%t) connected to (%s:%d)\n\n"), this->remote_addr_.get_host_addr(), this->remote_addr_.get_port_number()));  
  
    if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "220")  
    {  
        return false;  
    }  
  
    USER << "USER " << this->user_name_ << "\r\n";  
    if (this->Send(USER.str()))  
    {  
        if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "331")  
        {  
            return false;  
        }  
    }  
  
    PASS << "PASS " << this->pass_word_ << "\r\n";  
    if (this->Send(PASS.str()))  
    {  
        if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "230")  
        {  
            return false;  
        }  
  
        /*AIX返回的Login指令有3个*/  
        if (this->os_type_ == OS_AIX)  
        {  
            if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "230")  
            {  
                return false;  
            }  
            if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "230")  
            {  
                return false;  
            }  
        }  
    }  
  
    return true;  
}  
  
/*退出*/  
bool FTPClient::LogoOut()  
{  
    std::stringstream QUIT;  
    std::string  ftp_resp;  
  
    QUIT << "QUIT" << "\r\n";  
    if (this->Send(QUIT.str()))  
    {  
        if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "221")  
        {  
            return false;  
        }  
    }  
  
    return true;  
}  
  
/*获得远程系统信息*/  
bool FTPClient::GetSysInfo()  
{  
    std::stringstream SYST;  
    std::string  ftp_resp;  
  
    SYST << "SYST" << "\r\n";  
    if (this->Send(SYST.str()))  
    {  
        if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "215")  
        {  
            return false;  
        }  
    }  
  
    return true;  
}  
  
/*防空闲*/  
bool FTPClient::Noop()  
{  
    std::stringstream NOOP;  
    std::string  ftp_resp;  
  
    NOOP << "NOOP" << "\r\n";  
    if (this->Send(NOOP.str()))  
    {  
        if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "200")  
        {  
            return false;  
        }  
    }  
  
    return true;  
}  
  
/*修改本地路径，影响下载的文件所保存的路径 或者 上传的本地文件所在路径*/  
bool FTPClient::ChangeLocalDir(const std::string &dirname)  
{  
    return ACE_OS::chdir(dirname.c_str()) < 0 ? false : true;  
}  
  
/*修改远程路径，影响下载的远程文件所在路径 或者 上传的文件所保存的路径*/  
bool FTPClient::ChangeRemoteDir(const std::string &dirname)  
{  
    std::stringstream CWD, PWD;  
    std::string  ftp_resp;  
  
    CWD << "CWD " << dirname << "\r\n";  
    if (this->Send(CWD.str()))  
    {  
        if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "250")  
        {  
            return false;  
        }  
    }  
  
    PWD << "PWD" << "\r\n";  
    if (this->Send(PWD.str()))  
    {  
        if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "257")  
        {  
            return false;  
        }  
    }  
  
    return true;  
}  
  
/*上传文件*/  
bool FTPClient::PutFile(const std::string &filename)  
{  
    std::stringstream TYPE, PASV, STOR;  
    std::string  ftp_resp;  
  
    ACE_Time_Value  tv(MAX_CONN_TIMEOUT_SECOND, MAX_CONN_TIMEOUT_MILLISECOND);  
  
    int d0, d1, d2, d3, p0, p1;  
    std::stringstream ip;  
    ACE_INET_Addr ftp_data_addr;  
  
    ACE_SOCK_Stream     stream;  
    ACE_SOCK_Connector  connector;  
  
    ACE_FILE_Info file_info;  
    ACE_FILE_IO file_put;  
    ACE_FILE_Connector file_con;  
    char file_cache[MAX_BUFSIZE];  
    int file_size, all_size;  
  
    if (ACE_OS::access(filename.c_str(), F_OK) < 0) return false; /*文件不存在*/  
  
    /*修改类型*/  
    TYPE << "TYPE I" << "\r\n";  
    if (this->Send(TYPE.str()))  
    {  
        if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "200")  
        {  
            return false;  
        }  
    }  
  
    PASV << "PASV" << "\r\n";  
    if (this->Send(PASV.str()))  
    {  
        if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "227")  
        {  
            return false;  
        }  
    }  
  
    ftp_resp = ftp_resp.substr(ftp_resp.find_last_of('(')+1, (ftp_resp.find_last_of(')')-ftp_resp.find_last_of('(')-1));  
  
    if (sscanf(ftp_resp.c_str(), "%d,%d,%d,%d,%d,%d", &d0, &d1, &d2, &d3, &p0, &p1) == -1) return false;  
    ip << d0 << "." << d1 << "." << d2 << "." << d3;  
    ftp_data_addr.set((p0 << 8) + p1, ip.str().c_str());  
  
    if (connector.connect(stream, ftp_data_addr, &tv) == -1)  
    {  
        ACE_ERROR_RETURN((LM_ERROR, ACE_TEXT("(%P|%t) %p\n"), ACE_TEXT("connection failed")), false);  
    }  
  
    ACE_DEBUG((LM_DEBUG, ACE_TEXT("(%P|%t) connected to (%s:%d)\n\n"), this->remote_addr_.get_host_addr(), this->remote_addr_.get_port_number()));  
  
    STOR << "STOR " << filename << "\r\n";  
    if (this->Send(STOR.str()))  
    {  
        if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "150")  
        {  
            return false;  
        }  
    }  
  
    if (file_con.connect(file_put, ACE_FILE_Addr(filename.c_str()), &tv, ACE_Addr::sap_any, 0, O_RDONLY, ACE_DEFAULT_FILE_PERMS) == -1)  
        ACE_ERROR_RETURN((LM_ERROR, ACE_TEXT("%p\n to %s"), ACE_TEXT("open"), filename.c_str()), false);  
		//ACE_ERROR_RETURN((LM_ERROR, ACE_TEXT("%p\n to %s"), ACE_TEXT("open"), filename), false);  
  
    if (file_put.get_info (&file_info) == -1)  
        ACE_ERROR_RETURN ((LM_ERROR, ACE_TEXT("%p\n"), ACE_TEXT("get_info")), false);  
  
    all_size = 0;  
    while ((all_size < file_info.size_) && ((file_size=file_put.recv(file_cache, sizeof(file_cache))) > 0))  
    {  
        all_size += stream.send_n(file_cache, file_size);  
    }  
    file_put.close();  
  
    stream.close_writer();  
    stream.close_reader();  
    stream.close();  
  
    if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "226")  
    {  
        return false;  
    }  
  
    if (all_size != file_info.size_)  
    {  
        std::cout << "Send " << filename << "(" << file_info.size_ << ") fail! Only sent (" << all_size <<")" << std::endl;  
        return false;  
    }  
  
    std::cout << "Send " << filename << "(" << all_size << ") OK!" << std::endl << std::endl;  
    return true;  
}  
  
/*下载文件*/  
bool FTPClient::GetFile(const std::string &filename)  
{  
    std::stringstream PASV, RETR;  
    std::string  ftp_resp;  
	std::stringstream TYPE;
  
    ACE_Time_Value  tv(MAX_CONN_TIMEOUT_SECOND, MAX_CONN_TIMEOUT_MILLISECOND);  
  
    int d0, d1, d2, d3, p0, p1;  
    std::stringstream ip;  
    ACE_INET_Addr ftp_data_addr;  
  
    ACE_SOCK_Stream     stream;  
    ACE_SOCK_Connector  connector;  
  
    ACE_FILE_IO file_put;  
    ACE_FILE_Connector file_con;  
    char file_cache[MAX_BUFSIZE];  
    int file_size, all_size;  

    /*修改类型*/  
    TYPE << "TYPE I" << "\r\n";  
    if (this->Send(TYPE.str()))  
    {  
        if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "200")  
        {  
            return false;  
        }  
    } 
    PASV << "PASV" << "\r\n";  
    if (this->Send(PASV.str()))  
    {  
        if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "227")  
        {  
            return false;  
        }  
    }  
  
    ftp_resp = ftp_resp.substr(ftp_resp.find_last_of('(')+1, (ftp_resp.find_last_of(')')-ftp_resp.find_last_of('(')-1));  
  
    if (sscanf(ftp_resp.c_str(), "%d,%d,%d,%d,%d,%d", &d0, &d1, &d2, &d3, &p0, &p1) == -1) return false;  
    ip << d0 << "." << d1 << "." << d2 << "." << d3;  
    ftp_data_addr.set((p0 << 8) + p1, ip.str().c_str());  
  
    if (connector.connect(stream, ftp_data_addr, &tv) == -1)  
    {  
        ACE_ERROR_RETURN((LM_ERROR, ACE_TEXT("(%P|%t) %p\n"), ACE_TEXT("connection failed")), false);  
    }  
  
    ACE_DEBUG((LM_DEBUG, ACE_TEXT("(%P|%t) connected to (%s:%d)\n\n"), this->remote_addr_.get_host_addr(), this->remote_addr_.get_port_number()));  
  
    RETR << "RETR " << filename << "\r\n";  
    if (this->Send(RETR.str()))  
    {  
        if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "150")  
        {  
            return false;  
        }  
    }  
  
    if (file_con.connect(file_put, ACE_FILE_Addr(filename.c_str()), &tv, ACE_Addr::sap_any, 0, O_RDWR|O_CREAT, ACE_DEFAULT_FILE_PERMS) == -1)  
        ACE_ERROR_RETURN((LM_ERROR, ACE_TEXT("%p\n to %s"), ACE_TEXT("open"), filename.c_str()), false);  
		//ACE_ERROR_RETURN((LM_ERROR, ACE_TEXT("%p\n to %s"), ACE_TEXT("open"), filename), false);  
  
    all_size = 0;  
    while ((file_size = stream.recv(file_cache, sizeof(file_cache))) > 0)  
    {  
        all_size += file_put.send_n(file_cache, file_size);  
    }  
    file_put.close();  
  
    stream.close_writer();  
    stream.close_reader();  
    stream.close();  
  
    if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "226")  
    {  
        return false;  
    }  
  
    std::cout << "Recv " << filename << "(" << all_size << ") OK!" << std::endl << std::endl;  
    return true;  
}  
  
/*名字列表*/  
bool FTPClient::NList(std::string &pathlist, const std::string &pathname)  
{  
    std::stringstream PASV, NLST;  
    std::string  ftp_resp;  
  
    ACE_Time_Value  tv(MAX_CONN_TIMEOUT_SECOND, MAX_CONN_TIMEOUT_MILLISECOND);  
  
    int d0, d1, d2, d3, p0, p1;  
    std::stringstream ip;  
    ACE_INET_Addr ftp_data_addr;  
  
    ACE_SOCK_Stream     stream;  
    ACE_SOCK_Connector  connector;  
  
    char file_cache[MAX_BUFSIZE] = {0};  
    int file_size;  
  
    PASV << "PASV" << "\r\n";  
    if (this->Send(PASV.str()))  
    {  
        if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "227")  
        {  
            return false;  
        }  
    }  
  
    ftp_resp = ftp_resp.substr(ftp_resp.find_last_of('(')+1, (ftp_resp.find_last_of(')')-ftp_resp.find_last_of('(')-1));  
  
    if (sscanf(ftp_resp.c_str(), "%d,%d,%d,%d,%d,%d", &d0, &d1, &d2, &d3, &p0, &p1) == -1) return false;  
    ip << d0 << "." << d1 << "." << d2 << "." << d3;  
    ftp_data_addr.set((p0 << 8) + p1, ip.str().c_str());  
  
    if (connector.connect(stream, ftp_data_addr, &tv) == -1)  
    {  
        ACE_ERROR_RETURN((LM_ERROR, ACE_TEXT("(%P|%t) %p\n"), ACE_TEXT("connection failed")), false);  
    }  
  
    ACE_DEBUG((LM_DEBUG, ACE_TEXT("(%P|%t) connected to (%s:%d)\n\n"), this->remote_addr_.get_host_addr(), this->remote_addr_.get_port_number()));  
  
    if (pathname.empty())  
    {  
        NLST << "NLST" << "\r\n";  
    }  
    else  
    {  
        NLST << "NLST " << pathname << "\r\n";  
    }  
    if (this->Send(NLST.str()))  
    {  
        if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "150")  
        {  
            return false;  
        }  
    }  
  
    pathlist.clear();  
    while ((file_size = stream.recv(file_cache, sizeof(file_cache)-1)) > 0)  
    {  
        pathlist.append(file_cache);  
  
        ACE_OS::memset(file_cache, 0x00, sizeof(file_cache));  
    }  
  
    stream.close_writer();  
    stream.close_reader();  
    stream.close();  
  
    if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "226")  
    {  
        return false;  
    }  
  
    return true;  
}  
  
/*列表*/  
bool FTPClient::List(std::string &pathlist, const std::string &pathname)  
{  
    std::stringstream PASV, LIST;  
    std::string  ftp_resp;  
  
    ACE_Time_Value  tv(MAX_CONN_TIMEOUT_SECOND, MAX_CONN_TIMEOUT_MILLISECOND);  
  
    int d0, d1, d2, d3, p0, p1;  
    std::stringstream ip;  
    ACE_INET_Addr ftp_data_addr;  
  
    ACE_SOCK_Stream     stream;  
    ACE_SOCK_Connector  connector;  
  
    char file_cache[MAX_BUFSIZE] = {0};  
    int file_size;  
  
    PASV << "PASV" << "\r\n";  
    if (this->Send(PASV.str()))  
    {  
        if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "227")  
        {  
            return false;  
        }  
    }  
  
    ftp_resp = ftp_resp.substr(ftp_resp.find_last_of('(')+1, (ftp_resp.find_last_of(')')-ftp_resp.find_last_of('(')-1));  
  
    if (sscanf(ftp_resp.c_str(), "%d,%d,%d,%d,%d,%d", &d0, &d1, &d2, &d3, &p0, &p1) == -1) return false;  
    ip << d0 << "." << d1 << "." << d2 << "." << d3;  
    ftp_data_addr.set((p0 << 8) + p1, ip.str().c_str());  
  
    if (connector.connect(stream, ftp_data_addr, &tv) == -1)  
    {  
        ACE_ERROR_RETURN((LM_ERROR, ACE_TEXT("(%P|%t) %p\n"), ACE_TEXT("connection failed")), false);  
    }  
  
    ACE_DEBUG((LM_DEBUG, ACE_TEXT("(%P|%t) connected to (%s:%d)\n\n"), this->remote_addr_.get_host_addr(), this->remote_addr_.get_port_number()));  
  
    LIST << "LIST " << pathname << "\r\n";  
    if (this->Send(LIST.str()))  
    {  
        if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "150")  
        {  
            return false;  
        }  
    }  
  
    pathlist.clear();  
    while ((file_size = stream.recv(file_cache, sizeof(file_cache))) > 0)  
    {  
        pathlist.append(file_cache);  
  
        ACE_OS::memset(file_cache, 0x00, sizeof(file_cache));  
    }  
  
    stream.close_writer();  
    stream.close_reader();  
    stream.close();  
  
    if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "226")  
    {  
        return false;  
    }  
  
    return true;  
}  
  
/*更名*/  
bool FTPClient::ReName(const std::string &srcname, const std::string &dstname)  
{  
    std::stringstream RNFR, RNTO;  
    std::string  ftp_resp;  
  
    RNFR << "RNFR " << srcname << "\r\n";  
    if (this->Send(RNFR.str()))  
    {  
        if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "350")  
        {  
            return false;  
        }  
    }  
  
    RNTO << "RNTO " << dstname << "\r\n";  
    if (this->Send(RNTO.str()))  
    {  
        if (!this->Recv(ftp_resp) || ftp_resp.substr(0, 3) != "250")  
        {  
            return false;  
        }  
    }  
  
    return true;  
} 
