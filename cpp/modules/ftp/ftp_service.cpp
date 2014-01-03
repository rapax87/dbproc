#include "platform/modules/ftp/ftp_service.hpp"
#include "ftp_trace.hpp"
#include "ftp_client.hpp"
#include <iostream>
using namespace ubp::platform::ftp;
using namespace std;

std::string fileNameW(const std::string& filepath)
{
    std::string filename = "";
    if (filepath == "")
        return filename;

    basic_string<char>::size_type indexCh = 0;

    indexCh = filepath.rfind("\\");
    if ( indexCh != string::npos)
    {
        if (filepath.size() - (indexCh + 1) > 0)
        {
            filename = filepath.substr(indexCh+1, filepath.size() - (indexCh + 1));
        }
    }
    else
    {
        filename = filepath;
    }
    return filename;
}

std::string dirNameW(const std::string& filepath)
{
    std::string dir = "";
    if (filepath == "")
        return dir;

    basic_string<char>::size_type indexCh = 0;

    indexCh = filepath.rfind("\\");
    if ( indexCh != string::npos)
    {
        if (indexCh > 0)
        {
            dir = filepath.substr( 0, indexCh );
        }
    }
    else
    {
        dir = ".";
    }
    return dir;
}

FTPService::FTPService(const std::string &remote_ip,
                       const std::string &user_name, const std::string &pass_word,
                       const u_short remote_port, int os_type)
{
    this->user_name_ = user_name;
    this->pass_word_ = pass_word;
    this->remote_ip_ = remote_ip;
    this->remote_port_ = remote_port;
    //this->remote_addr_.set((u_short)remote_port, remote_ip.c_str());

    this->os_type_ = os_type;
}

FTPService::~FTPService()
{
    /*
    peer_.close_writer();
    	peer_.close_reader();
    	peer_.close();  */

}

bool FTPService::uploadFile(const std::string& ldir, const std::string& lfilename,
                            const std::string& sdir, const std::string& sfilename)
{
    FTP_TRACE_INFO("FTPService::uploadFile");
    char currentDir[512];
    ACE_OS::getcwd(currentDir, 512);
    string cdir(currentDir);
    FTP_TRACE_DEBUG("Current dir is "<<cdir);

    try
    {
        FTPClient ftp_client(remote_ip_, remote_port_, user_name_, pass_word_);

        bool ret = ftp_client.LogoIn();
        FTP_TRACE_RETURN_ERRCODE_IF_FALSE(ret, false, "LogoIn failed:" +  user_name_);
        ret = ftp_client.ChangeLocalDir(ldir);
        FTP_TRACE_RETURN_ERRCODE_IF_FALSE(ret, false, "ChangeLocalDir failed:" +  ldir);
        ret = ftp_client.ChangeRemoteDir(sdir);
        FTP_TRACE_RETURN_ERRCODE_IF_FALSE(ret, false, "ChangeRemoteDir failed:" +  sdir);
        ret = ftp_client.PutFile(lfilename);
        FTP_TRACE_RETURN_ERRCODE_IF_FALSE(ret, false, "PutFile failed:" +  lfilename);
        if (sfilename != "" && sfilename != lfilename)
        {
            ret = ftp_client.ReName(lfilename, sfilename);
            FTP_TRACE_RETURN_ERRCODE_IF_FALSE(ret, false, "ReName failed:" +  sfilename);
        }

        //back to original dir
        ret = ftp_client.ChangeLocalDir(currentDir);
        FTP_TRACE_RETURN_ERRCODE_IF_FALSE(ret, false, "Back to original dir  failed"<<cdir);

        ftp_client.LogoOut();
        FTP_TRACE_RETURN_ERRCODE_IF_FALSE(ret, false, "LogoOut failed:" +  user_name_);
    }
    catch (std::exception& exc)
    {
        //printf("[%d:%s]:%s/n", __LINE__, __FILE__, exc.what());
        FTP_TRACE_ERROR("FTP Error ["<<__LINE__<<":"<<__FILE__<<"]:"<<exc.what());
        return 0;
    }
    return true;
}



bool FTPService::uploadFile(std::vector<std::string>& filenames, const std::string& sdir, const std::string& ldir)
{
    FTP_TRACE_INFO("FTPService::uploadFiles");
    char currentDir[512];
    ACE_OS::getcwd(currentDir, 512);
    string cdir(currentDir);
    FTP_TRACE_DEBUG("Current dir is "<<cdir);

    try
    {
        FTPClient ftp_client(remote_ip_, remote_port_, user_name_, pass_word_);

        bool ret = ftp_client.LogoIn();
        FTP_TRACE_RETURN_ERRCODE_IF_FALSE(ret, false, "LogoIn failed:" +  user_name_);
        ret = ftp_client.ChangeLocalDir(ldir);
        FTP_TRACE_RETURN_ERRCODE_IF_FALSE(ret, false, "ChangeLocalDir failed:" +  ldir);
        ret = ftp_client.ChangeRemoteDir(sdir);
        FTP_TRACE_RETURN_ERRCODE_IF_FALSE(ret, false, "ChangeRemoteDir failed:" +  sdir);

        for (vector<string>::iterator iter = filenames.begin();
                iter != filenames.end(); ++iter)
        {
            ret = ftp_client.PutFile(*iter);
            FTP_TRACE_RETURN_ERRCODE_IF_FALSE(ret, false, "PutFile failed:" +  sdir);
        }

        //ftp_client.ReName(ftp_local_file_tmp, ftp_local_file);

        //back to original dir
        ret = ftp_client.ChangeLocalDir(currentDir);
        FTP_TRACE_RETURN_ERRCODE_IF_FALSE(ret, false, "Back to original dir  failed"<<cdir);

        ftp_client.LogoOut();
        FTP_TRACE_RETURN_ERRCODE_IF_FALSE(ret, false, "LogoOut failed:" +  user_name_);
    }
    catch (std::exception& exc)
    {
        //printf("[%d:%s]:%s/n", __LINE__, __FILE__, exc.what());
        FTP_TRACE_ERROR("FTP Error ["<<__LINE__<<":"<<__FILE__<<"]:"<<exc.what());
        return 0;
    }
    return true;
}
bool FTPService::downloadFile(const std::string& sdir, const std::string& sfilename, const std::string& ldir)
{
    FTP_TRACE_INFO("FTPService::downloadFile");
    char currentDir[512];
    ACE_OS::getcwd(currentDir, 512);
    string cdir(currentDir);
    FTP_TRACE_DEBUG("Current dir is "<<cdir);
    try
    {
        FTPClient ftp_client(remote_ip_, remote_port_, user_name_, pass_word_);

        bool ret = ftp_client.LogoIn();
        FTP_TRACE_RETURN_ERRCODE_IF_FALSE(ret, false, "LogoIn failed:" +  user_name_);
        ret = ftp_client.ChangeLocalDir(ldir);
        FTP_TRACE_RETURN_ERRCODE_IF_FALSE(ret, false, "ChangeLocalDir failed:" +  ldir);
        ret = ftp_client.ChangeRemoteDir(sdir);
        FTP_TRACE_RETURN_ERRCODE_IF_FALSE(ret, false, "ChangeRemoteDir failed:" +  sdir);
        ret = ftp_client.GetFile(sfilename);
        FTP_TRACE_RETURN_ERRCODE_IF_FALSE(ret, false, "GetFile failed:" +  sfilename);
        //ftp_client.ReName(ftp_local_file_tmp, ftp_local_file);

        //back to original dir
        ret = ftp_client.ChangeLocalDir(currentDir);
        FTP_TRACE_RETURN_ERRCODE_IF_FALSE(ret, false, "Back to original dir  failed"<<cdir);

        ftp_client.LogoOut();
        FTP_TRACE_RETURN_ERRCODE_IF_FALSE(ret, false, "LogoOut failed:" +  user_name_);
    }
    catch (std::exception& exc)
    {
        //printf("[%d:%s]:%s/n", __LINE__, __FILE__, exc.what());
        FTP_TRACE_ERROR("FTP Error ["<<__LINE__<<":"<<__FILE__<<"]:"<<exc.what());
        return 0;
    }
    return true;
}


bool FTPService::downloadFile(std::vector<std::string>& filenames, const std::string& sdir, const std::string& ldir)

{
    FTP_TRACE_INFO("FTPService::downloadFiles");
    char currentDir[512];
    ACE_OS::getcwd(currentDir, 512);
    string cdir(currentDir);
    FTP_TRACE_DEBUG("Current dir is "<<cdir);
    try
    {
        FTPClient ftp_client(remote_ip_, remote_port_, user_name_, pass_word_);

        bool ret = ftp_client.LogoIn();
        FTP_TRACE_RETURN_ERRCODE_IF_FALSE(ret, false, "LogoIn failed:" +  user_name_);
        ret = ftp_client.ChangeLocalDir(ldir);
        FTP_TRACE_RETURN_ERRCODE_IF_FALSE(ret, false, "ChangeLocalDir failed:" +  ldir);
        ret = ftp_client.ChangeRemoteDir(sdir);
        FTP_TRACE_RETURN_ERRCODE_IF_FALSE(ret, false, "ChangeRemoteDir failed:" +  sdir);

        for (vector<string>::iterator iter = filenames.begin();
                iter != filenames.end(); ++iter)
        {
            ret = ftp_client.GetFile(*iter);
            FTP_TRACE_RETURN_ERRCODE_IF_FALSE(ret, false, "GetFile failed:" +  sdir);
        }


        //ftp_client.ReName(ftp_local_file_tmp, ftp_local_file);

        //back to original dir
        ret = ftp_client.ChangeLocalDir(currentDir);
        FTP_TRACE_RETURN_ERRCODE_IF_FALSE(ret, false, "Back to original dir  failed"<<cdir);

        ftp_client.LogoOut();
        FTP_TRACE_RETURN_ERRCODE_IF_FALSE(ret, false, "LogoOut failed:" +  user_name_);
    }
    catch (std::exception& exc)
    {
        //printf("[%d:%s]:%s/n", __LINE__, __FILE__, exc.what());
        FTP_TRACE_ERROR("FTP Error ["<<__LINE__<<":"<<__FILE__<<"]:"<<exc.what());
        return 0;
    }
    return true;
}
