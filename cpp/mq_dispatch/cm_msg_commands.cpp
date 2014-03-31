
#include "cm_msg_commands.hpp"

#include "boost/tokenizer.hpp"
#include <google/protobuf/descriptor.h>

#include "ubp_globe.hpp"
#include "platform/modules/sca/ubp_svc_env.hpp"
#include "platform/modules/dao/dao_assistant.hpp"
#include "platform/modules/query/mq_query.hpp"
#include "platform/modules/mq/message_factory.hpp"
#include "platform/modules/error/ubp_error.hpp"
#include "platform/modules/util/locale_service.hpp"
#include "platform/modules/util/utils.hpp"
#include "platform/modules/ftp/ftp_service.hpp"

#include "cm/cm_msg.pb.h"
#include "globe/eapp_udc.pb.h"
#include "cm/cm_error.hpp"
#include "cm/cm_const.hpp"
#include "cm_const_def.hpp"
#include "cm_utility.h"
#include "cm_trace.hpp"
//#include "cm_moc_meta.h"
#include "cm/cm_mocoperator.h"
#include "cm_import_data.hpp"
#include "cm_vpn_processor.hpp"
#include "cm_mocview_processor.hpp"

#include "boost/property_tree/ptree.hpp"
#include "boost/property_tree/ini_parser.hpp"

using namespace ubp::cm;
using namespace eapp::udc;
using namespace ubp::platform::sca;
using namespace ubp::platform::dao;
using namespace ubp::platform::query;
using namespace ubp::platform::util;
using namespace ubp::platform::ftp;
using namespace google::protobuf;

IMessage *CmReponseHander::OnReponseMessage(IMessageHeader *header,
    IMessage *msgbody)
{
  CM_TRACE_DEBUG(gettext("CmReponseHander::OnReponseMessage"));
  int result = CM_SUCCESS;
  int mo_op = -1;
  IMessage *pQueryRsp = NULL;

  if(header->has_operator_code())
  {
    mo_op = header->operator_code();
  }

  std::string msgId = header->msg_id();
  std::string src_svc_id = header->src_svc_id();
  CM_TRACE_INFO(gettext("Receive message, src_svc_id=") << src_svc_id << ", msg_id=" << msgId << ", operator_code=" << mo_op);

  IMessage *pReq = msgbody;

  if(NULL == pReq)
  {
    CM_TRACE_ERROR(gettext("Message body is NULL, msg_id=") << msgId << ", operator_code=" << mo_op);
    //return NULL;
    return GetCMRspByResult(ERR_UBP_CM_BODYNULL);
  }
  if(mo_op == OP_BATCH_IMPORT)
  {
    CM_TRACE_INFO(gettext("CM is importing xml...  "));
    CMSimpleCommand *pCmd = dynamic_cast<CMSimpleCommand *>(msgbody);
    if(NULL == pCmd)
    {
      CM_TRACE_ERROR(gettext("Wrong message type, not CMSimpleCommand "));
      //return NULL;
      return GetCMRspByResult(ERR_UBP_CM_BODYTYPE);
    }
    std::string filepath = "";
    if(pCmd->has_filepath())
    {
      filepath = pCmd->filepath();
    }

    CM_TRACE_INFO(gettext("XML filepath=") << filepath);
    //import ugc config from xml file
    ugc_import_manager ugc(filepath);
    result = ugc.ugc_import_data();
    if(result == CM_ERROR)
    {
      return GetCMRspByResult(ERR_UBP_CM_IMPORTXML);
    }
    else
    {
      return GetCMRspByResult(result);
    }
  }
  else if(mo_op == OP_BATCH_IMPORT_XML)
  {
    CM_TRACE_INFO(gettext("CM is importing xml...  "));
    CMSimpleCommand *pCmd = dynamic_cast<CMSimpleCommand *>(msgbody);
    if(NULL == pCmd)
    {
      CM_TRACE_ERROR(gettext("Wrong message type, not CMSimpleCommand "));
      //return NULL;
      return GetCMRspByResult(UBP_FAIL);
    }
    std::string filepath = "";
    if(pCmd->has_filepath())
    {
      filepath = pCmd->filepath();
    }
    else
    {
        CM_TRACE_ERROR("File path not set when import XML.");
	 return GetCMRspByResult(UBP_FAIL	);
    }
    if (filepath == "")
    {
        CM_TRACE_ERROR("File path not set when import XML.");
	 return GetCMRspByResult(UBP_FAIL);
    }

    CM_TRACE_INFO(gettext("XML filepath=") << filepath);

    char importxml_bin[1024] = {0};
    ACE_OS::memset(importxml_bin, 0, 1024);
    char *tempstr = ACE_OS::getenv("EASY_INSTALL");
    if (NULL==tempstr)
    {
        CM_TRACE_ERROR("env {EASY_INSTALL} is not set. Use local path.");
        return GetCMRspByResult(UBP_FAIL);//add error msg later
        //tempstr = ".";
    }
    else
    {
        //CM_TRACE_INFO(gettext("use env {EASY_INSTALL} path."));
        ACE_OS::snprintf(importxml_bin, sizeof(importxml_bin),
                         "%s/bin/dbproc/ubp_importdb.sh", tempstr);
    }

    string importxml_bin_file(importxml_bin);
    CM_TRACE_DEBUG(gettext("Import XML BIN file is:")<<importxml_bin_file);
    string cmdline = importxml_bin_file + " " + filepath + " del";
    int status = system(cmdline.c_str());
    if (status != UBP_SUCCESS)
    {
        return GetCMRspByResult(UBP_FAIL);
    }
    return GetCMRspByResult(UBP_SUCCESS);
    
  }
  else if(mo_op == OP_QUERY_SYNC_INFO)
  {
    CM_TRACE_INFO(gettext("Query sync info...  "));
    CMSimpleCommand *pCmd = dynamic_cast<CMSimpleCommand *>(msgbody);
    if(NULL == pCmd)
    {
      CM_TRACE_ERROR(gettext("Wrong message type, not CMSimpleCommand "));
      //return NULL;
      return GetCMRspByResult(UBP_FAIL);
    }

    

    char inifile[1024] = {0};
    ACE_OS::memset(inifile, 0, 1024);
    char *tempstr = ACE_OS::getenv("EASY_INSTALL");
    if (NULL==tempstr)
    {
        CM_TRACE_ERROR("env {EASY_INSTALL} is not set. Use local path.");
        return GetCMRspByResult(UBP_FAIL);//add error msg later
        //tempstr = ".";
    }
    else
    {
        //CM_TRACE_INFO(gettext("use env {EASY_INSTALL} path."));
        ACE_OS::snprintf(inifile, sizeof(inifile),
                         "%s/res/sync/ubp_sync.ini", tempstr);
    }

    string inifilepath(inifile);
    CM_TRACE_DEBUG(gettext("Read ini file:")<<inifilepath);
    boost::property_tree::ptree pt;
    try
    {
    boost::property_tree::ini_parser::read_ini(inifilepath, pt);
    }
    catch(...)
    {
      CM_TRACE_ERROR("Read ini file error.");
      return GetCMRspByResult(UBP_FAIL);
    }
    string log = pt.get<std::string>("SYNCHRONID") + "," + pt.get<std::string>("LASTUPDATE");
    return GetCMRspByResult(UBP_SUCCESS, log);
    
  }
  else if(mo_op == OP_BATCH_IMPORT_CSV)
  {
    CM_TRACE_INFO(gettext("CM is importing csv...  "));
    CMSimpleCommand *pCmd = dynamic_cast<CMSimpleCommand *>(msgbody);
    if(NULL == pCmd)
    {
      CM_TRACE_ERROR(gettext("Wrong message type, not CMSimpleCommand "));
      //return NULL;
      return GetCMRspByResult(ERR_UBP_CM_BODYTYPE);
    }
    std::string filepath = "";
    if(pCmd->has_filepath())
    {
      filepath = pCmd->filepath();
    }

    if(filepath == "")
    {
      //return GetCMRspByResult(CM_ERROR);
      return GetCMRspByResult(ERR_UBP_CM_IMPORTCSV);
    }
    else
    {
      CM_TRACE_INFO(gettext("CSV filepath=") << filepath);
      //import ugc config from xml file
      ugc_import_manager ugc(filepath);
      result = ugc.import_csv_data();
      if(result == CM_ERROR)
      {
        return GetCMRspByResult(ERR_UBP_CM_IMPORTCSV);
      }
      else
      {
        return GetCMRspByResult(result);
      }
    }
  }
  else if(mo_op == OP_COLLECT_TRACE)
  {
    CM_TRACE_INFO(gettext("CM is collecting trace...  "));
    CMSimpleCommand *pCmd = dynamic_cast<CMSimpleCommand *>(msgbody);
    if(NULL == pCmd)
    {
      CM_TRACE_ERROR(gettext("Wrong message type, not CMSimpleCommand "));
      //return NULL;
      return GetCMRspByResult(ERR_UBP_CM_BODYTYPE);
    }

    std::string savepath = "";
    if(pCmd->has_filepath())
    {
      savepath = pCmd->filepath();
      //ACE_OS::system(cmd.c_str());
    }

    char cmd[512];
    ACE_OS::memset(cmd, 0, 512);
    char *tempstr = ACE_OS::getenv("EASY_INSTALL");
    ACE_OS::snprintf(cmd, sizeof(cmd),
                     "%s/bin/collection/ubp_collect.sh all %s >/dev/null 2>&1 &", tempstr, savepath.c_str());
    CM_TRACE_DEBUG(gettext("command=") << cmd);
    ACE_OS::system(cmd);

    return GetCMRspByResult(CM_SUCCESS);
  }
  else if(msgId == SYNC_MSG_ID)
  {
  	CM_TRACE_INFO(gettext("Query sync info...  "));
    syncinfo *pCmd = dynamic_cast<syncinfo *>(msgbody);
    if(NULL == pCmd)
    {
      CM_TRACE_ERROR(gettext("Wrong message type, not syncinfo "));
      //return NULL;
      return GetCMRspByResult(UBP_FAIL);
    }

    

    char inifile[1024] = {0};
    ACE_OS::memset(inifile, 0, 1024);
    char *tempstr = ACE_OS::getenv("EASY_INSTALL");
    if (NULL==tempstr)
    {
        CM_TRACE_ERROR("env {EASY_INSTALL} is not set. Use local path.");
        return GetCMRspByResult(UBP_FAIL);//add error msg later
        //tempstr = ".";
    }
    else
    {
        //CM_TRACE_INFO(gettext("use env {EASY_INSTALL} path."));
        ACE_OS::snprintf(inifile, sizeof(inifile),
                         "%s/res/sync/ubp_sync.ini", tempstr);
    }

    string inifilepath(inifile);
    CM_TRACE_DEBUG(gettext("Read ini file:")<<inifilepath);
    boost::property_tree::ptree pt;
    string syncno; 
    string latestupdate;
    string esn;
    try
    {
    boost::property_tree::ini_parser::read_ini(inifilepath, pt);
    syncno = pt.get<std::string>("SYNCHRONID"); 
    latestupdate = pt.get<std::string>("LASTUPDATE");
    esn = pt.get<std::string>("ESN");
    }
    catch(...)
    {
      CM_TRACE_ERROR("Read ini file error:"<<inifilepath);
      string failcause= "Read ini file error:" + inifilepath;
      return GetSyncRspByResult(UBP_FAIL, failcause);
    }
    
    return GetSyncRspByResult(UBP_SUCCESS, "", syncno, latestupdate, esn);
  }
  else if(msgId == DLDCFG_MSG_ID)
  {
  	CM_TRACE_INFO(gettext("Process download command:")<<DLDCFG_MSG_ID);
    dldcfgfile *pCmd = dynamic_cast<dldcfgfile *>(msgbody);
    if(NULL == pCmd)
    {
      CM_TRACE_ERROR(gettext("Wrong message type, not dldcfgfile "));
      //return NULL;
      return GetUDCRspByResult(UBP_FAIL, "Wrong message type, not dldcfgfile ");
    }

    char xmlfiledir[1024] = {0};
    ACE_OS::memset(xmlfiledir, 0, 1024);
    char *tempstr = ACE_OS::getenv("EASY_INSTALL");
    if (NULL==tempstr)
    {
        CM_TRACE_ERROR("env {EASY_INSTALL} is not set. Use local path.");
        return GetCMRspByResult(UBP_FAIL);//add error msg later
        //tempstr = ".";
    }
    else
    {
        ACE_OS::snprintf(xmlfiledir, sizeof(xmlfiledir),
                         "%s/ftp/cm", tempstr);
    }

    string xmlfilepath(xmlfiledir);

    FTPService ftp_service(pCmd->ftpip(), pCmd->ftpusrname(), pCmd->ftppassword());
    bool result = ftp_service.downloadFile(pCmd->cfgfiledir(), pCmd->cfgfile(),  xmlfilepath);
    if (!result)
    {
    	return GetUDCRspByResult(UBP_FAIL, "Download file failed.");
    }
    else
    {
    	return GetUDCRspByResult(UBP_SUCCESS);
    }

  }
  else if(msgId == ACTCFG_MSG_ID)
  {
  	CM_TRACE_INFO(gettext("Process activate command:")<<ACTCFG_MSG_ID);
    actcfgfile *pCmd = dynamic_cast<actcfgfile *>(msgbody);
    if(NULL == pCmd)
    {
      CM_TRACE_ERROR(gettext("Wrong message type, not actcfgfile "));
      //return NULL;
      return GetUDCRspByResult(UBP_FAIL, "Wrong message type, not dldcfgfile ");
    }

     if ( pCmd->cfgfiledir() == "")
    {
        CM_TRACE_ERROR("File path not set when import XML.");
	 return GetUDCRspByResult(UBP_FAIL, "File path not set when import XML.");
    }

    CM_TRACE_INFO(gettext("XML filepath=") << pCmd->cfgfiledir());

    char importxml_bin[1024] = {0};
    char restartubp_bin[1024] = {0};
    char xmlfiledir[1024] = {0};
    ACE_OS::memset(importxml_bin, 0, 1024);
    ACE_OS::memset(restartubp_bin, 0, 1024);
    ACE_OS::memset(xmlfiledir, 0, 1024);
    char *tempstr = ACE_OS::getenv("EASY_INSTALL");
    if (NULL==tempstr)
    {
        CM_TRACE_ERROR("env {EASY_INSTALL} is not set. Use local path.");
        return GetCMRspByResult(UBP_FAIL);//add error msg later
        //tempstr = ".";
    }
    else
    {
        //CM_TRACE_INFO(gettext("use env {EASY_INSTALL} path."));
        ACE_OS::snprintf(importxml_bin, sizeof(importxml_bin),
                         "%s/bin/dbproc/ubp_importdb.sh", tempstr);
        ACE_OS::snprintf(restartubp_bin, sizeof(restartubp_bin),
                         "%s/bin/restartubp.sh", tempstr);
        ACE_OS::snprintf(xmlfiledir, sizeof(xmlfiledir),
                         "%s/ftp/cm", tempstr);
    }

    string importxml_bin_file(importxml_bin);
    string xmlfilepath(xmlfiledir);
    xmlfilepath = xmlfilepath + "/" + pCmd->cfgfiledir();
    CM_TRACE_INFO(gettext("Import XML BIN file is:")<<importxml_bin_file);
    string cmdline = importxml_bin_file + " " + xmlfilepath + " del";
    int status = system(cmdline.c_str());
    if (status != UBP_SUCCESS)
    {
        return GetUDCRspByResult(UBP_FAIL, "Activiate file failed");
    }
/*
    CM_TRACE_INFO(gettext("Restart UBP..."));
    string restartubp_bin_file(restartubp_bin);
    string cmdline_restartupb = restartubp_bin_file;
    status = system(cmdline_restartupb.c_str());
*/    
    
    return GetUDCRspByResult(UBP_SUCCESS);

  }
  //else if(mo_op != OP_QUERY)
  else if(mo_op == OP_ADD || mo_op == OP_MODIFY || mo_op == OP_DELETE 
  || mo_op == OP_BATCH_ADD || mo_op == OP_BATCH_MODIFY || mo_op == OP_BATCH_DELETE)
  {
    CM_TRACE_INFO(gettext("CM is updating moc data ...  "));
    //璁剧疆msgType, 渚嬪锛歅TTUser
    msgType_ = getMsgTypeByMsgId(header->msg_id());
    std::map<std::string, MocMeta>::iterator it_val = val_map_.find(msgType_);
    if(it_val == val_map_.end())
    {
      //return GetCMRspByResult(CM_ERROR);
      CM_TRACE_ERROR(gettext("Message type not found, msgType=") << msgType_);
      //return NULL;
      return GetCMRspByResult(ERR_UBP_CM_MOCTYPE);
    }
    std::map<std::string, vector<MocOperator *> >::iterator it_opt = opt_map_.find(msgId);
    if(it_opt == opt_map_.end())
    {
      if(mo_op == OP_ADD || mo_op == OP_MODIFY || mo_op == OP_DELETE)
      {
        it_opt = opt_map_.find(DEFAULT_MSGID);
        if(it_opt == opt_map_.end())
        {
          CM_TRACE_ERROR(gettext("Operation type not found, mgsid=") << msgId << ", OperateType=" << mo_op);
          //return NULL;
          return GetCMRspByResult(ERR_UBP_CM_OPTYPE);
        }
      }
      else if(mo_op == OP_BATCH_ADD || mo_op == OP_BATCH_MODIFY || mo_op == OP_BATCH_DELETE)
      {
        it_opt = opt_map_.find(DEFAULT_LIST_MSGID);
        if(it_opt == opt_map_.end())
        {
          CM_TRACE_ERROR(gettext("Operation type not found, mgsid=") << msgId << ", OperateType=" << mo_op);
          //return NULL;
          return GetCMRspByResult(ERR_UBP_CM_OPTYPE);
        }
      }

      else
      {
        CM_TRACE_ERROR(gettext("Operation type not found, mgsid=") << msgId << ", OperateType=" << mo_op);
        //return NULL;
        return GetCMRspByResult(ERR_UBP_CM_OPTYPE);
      }
    }

    for(vector<MocOperator *>::iterator iter = it_opt->second.begin();
        iter != it_opt->second.end(); ++iter)
    {
      result = (*iter)->OperateMoc(header, msgbody, &(it_val->second));
      if(result != UBP_SUCCESS)
      {
        break;
      }
    }
    if(result == UBP_FAIL)
    {
      return GetCMRspByResult(ERR_UBP_CM_MOCMODIFY);
    }
    else
    {
      return GetCMRspByResult(result);
    }
    //return GetCMRspByResult(result);
  }
  else if(msgId == MQ_QUERY_MSG_ID)
  {
    //TODO::be removed
    CM_TRACE_ERROR(gettext(">>>>>>>>>>Query from MQQuery interface<<<<<<"));
    //閰嶇疆椤规煡璇㈡搷浣?
    ubp::platform::MqQueryMsg *pQueryMsg =
      dynamic_cast<ubp::platform::MqQueryMsg *>(pReq);
    if(NULL == pQueryMsg)
    {
      CM_TRACE_ERROR(gettext("Get MqQueryMsg error!"));
      return NULL;
    }

    QueryRequest queryReq(pQueryMsg->mocname(),
                          "ubp.cm." + pQueryMsg->mocname() + "List",
                          pQueryMsg->condition(),
                          pQueryMsg->checkpoint(), pQueryMsg->limit());

    MqQuery query;
    result = query.QueryMO(&queryReq, &pQueryRsp);
    if(result != UBP_SUCCESS)
    {
      //return GetQueryRspByResult(CM_ERROR);
      return NULL;
    }
    return pQueryRsp;
  }
  else if(msgId == "ubp.cm.CMQuery")   //TODO:鍏煎鐜版湁浠ｇ爜鏆傛椂淇濈暀锛屽悗闈㈠垹闄?
  {
    //閰嶇疆椤规煡璇㈡搷浣?
    ubp::cm::CMQuery *pQueryMsg =
      dynamic_cast<ubp::cm::CMQuery *>(pReq);
    if(NULL == pQueryMsg)
    {
      CM_TRACE_ERROR(gettext("Get MqQueryMsg error!"));
      return NULL;
    }

    std::string queryCond = pQueryMsg->condition();
	
    if(pQueryMsg->mocname().find("View_") == 0)
	{
		CM_TRACE_DEBUG("Query view:"<<pQueryMsg->mocname());
		std::auto_ptr<MocViewProcessor> apMocViewProcessor(new MocViewProcessor(val_map_,opt_map_));
		IMessage *queryMsg =apMocViewProcessor->QueryViewData(pQueryMsg, queryCond);
		return queryMsg;
	}


    ACE_INT32 vpnid = pQueryMsg->vpnid();

    //鏌ヨ鏃惰缃簡vpn, 鍒欓渶鎷艰鏌ヨ鏉′欢
    if(-1 != vpnid)
    {
      std::string mocname =pQueryMsg->mocname();
	  std::string isdn =pQueryMsg->isdn();

	  std::auto_ptr<VpnProcessor> apVpnProcessor(new VpnProcessor(val_map()));
	  if(mocname == MOCNAME_VPNRANGEQUERY)
	  {
	  	CM_TRACE_INFO("Query ISDNs by vpn.");
		return apVpnProcessor->BuildVpnRangeList(isdn, vpnid);
	  }
	  
      std::string isdn_cond("");
      bool buildRet = apVpnProcessor->BuildVpnFilterCondition(mocname, isdn, vpnid, isdn_cond);
      if(!buildRet)
      {
        CM_TRACE_ERROR("build isdn condition error!");
        return GetCMRspByResult(CM_SUCCESS);
      }

      if(!isdn_cond.empty())
      {
        if(!queryCond.empty())
        {
          queryCond = isdn_cond + " AND " + queryCond;
        }
        else
        {
          queryCond = isdn_cond;
        }
      }
    }
    CM_TRACE_DEBUG("queryCond is " << queryCond);

    QueryRequest queryReq(pQueryMsg->mocname(),  //MOC鍚嶇О锛屼笉鏄痜ullname
                          "ubp.cm." + pQueryMsg->mocname() + "List", //鍖呭悕+MOC鍚?List
                          //pQueryMsg->condition(),
                          queryCond,
                          pQueryMsg->checkpoint(), pQueryMsg->limit());
    CM_TRACE_DEBUG("mocname=" << pQueryMsg->mocname()
                   << ", condition=" << pQueryMsg->condition()
                   << ", checkpoint=" << pQueryMsg->checkpoint()
                   << ", limit=" << pQueryMsg->limit());
    MqQuery query;
    result = query.QueryMO(&queryReq, &pQueryRsp);
    if(result != UBP_SUCCESS)
    {
      CM_TRACE_ERROR("query error");
      //return GetQueryRspByResult(CM_ERROR);
      return NULL;
    }

    return pQueryRsp;
  }
  else if(mo_op== OP_VIEW_UPDATE)
  {
  	CM_TRACE_DEBUG("Update View");
	std::auto_ptr<MocViewProcessor> apMocViewProcessor(new MocViewProcessor(val_map_, opt_map_));
	apMocViewProcessor->UpdateViewData(header,msgbody);
	return GetCMRspByResult(0);
  }
  else
  {
    //return GetQueryRspByResult(CM_ERROR);
    return NULL;
  }

}
void CmReponseHander::clearOptList()
{
    for(std::map<std::string, vector<MocOperator*> >::iterator iter=opt_map_.begin();iter!=opt_map_.end();++iter)
    {
        vector<MocOperator*> vec = iter->second;
		for (vector<MocOperator*>::iterator iter2 = vec.begin();iter2!=vec.end();++iter2)
		{
            if (*iter2 != NULL)
            {
                delete *iter2;
                *iter2 = NULL;
            }
		}
		vec.clear();
    }
	opt_map_.clear();
}
int CmReponseHander::RegOperator(std::string msgid, vector<MocOperator *> &opt_vec)
//int CmReponseHander::RegOperator(std::string msgid, int opType, vector<MocOperator*>& opt_vec)
{

  //stringstream ss_opType;
  //ss_opType<<opType;
  //string linktype = msgid + ss_opType.str();
  opt_map_.insert(std::pair<std::string, vector<MocOperator *> >(msgid, opt_vec));
  //opt_map_.insert(std::pair<std::string, vector<MocOperator*> >(linktype, opt_vec));

  return CM_SUCCESS;
}

IMessage *CmReponseHander::GetUDCRspByResult(int result, std::string failcause)
{
  CM_TRACE_DEBUG(gettext("Handle message return. result=") << result);
  UDCRsp *pRsp = dynamic_cast<UDCRsp *>
                (IMessageFactory::CreateMessage("eapp.udc.UDCRsp"));
  pRsp->set_result(result);
  pRsp->set_failcause(failcause);
  return pRsp;
}

IMessage *CmReponseHander::GetSyncRspByResult(int result, std::string failcause, std::string syncno, std::string latestupdate, std::string esn)
{
  CM_TRACE_DEBUG(gettext("Handle message return. result=") << result);
  SyncRsp *pRsp = dynamic_cast<SyncRsp *>
                (IMessageFactory::CreateMessage("eapp.udc.SyncRsp"));
  pRsp->set_result(result);
  pRsp->set_failcause(failcause);
  pRsp->set_syncno(atoi(syncno.c_str()));
  pRsp->set_latestupdatetime(latestupdate);
  pRsp->set_esn(atoi(esn.c_str()));
  return pRsp;
}

IMessage *CmReponseHander::GetCMRspByResult(int result, std::string log)
{
  CM_TRACE_DEBUG(gettext("Handle message return. result=") << result);
  CMRsp *pRsp = dynamic_cast<CMRsp *>
                (IMessageFactory::CreateMessage("ubp.cm.CMRsp"));
  pRsp->set_result(result);
  pRsp->set_log(log);
  return pRsp;
}

IMessage *CmReponseHander::GetQueryRspByResult(int result)
{
  CM_TRACE_DEBUG(gettext("Handle message return. result=") << result);
  IMessage *pRsp = IMessageFactory::CreateMessage("ubp.cm." + msgType_ + "List");
  const Descriptor *descriptor = pRsp->GetDescriptor();
  const Reflection *reflection = pRsp->GetReflection();
  const FieldDescriptor *field = descriptor->FindFieldByName("result");
  reflection->SetInt32(pRsp, field, result);
  return pRsp;
}

std::map<std::string, MocMeta> &CmReponseHander::val_map()
{
  return val_map_;
}

void CmReponseHander::set_val_map(std::map<std::string, MocMeta> &value)
{
  val_map_ = value;
}

ACE_INT32 CmMsgDealerHandler::OnDealMessage(IMessageHeader *header, IMessage *msgbody)
{
  CM_TRACE_DEBUG("CmMsgDealerHandler::OnDealMessage");
  ACE_INT32 result = CM_SUCCESS;
  ACE_INT32 op_code = -1;

  if(header->has_operator_code())
  {
    op_code = header->operator_code();
  }

  //msgid鏍囪瘑鏄敤鎴锋棩蹇楄繕鏄郴缁熸棩蹇?
  std::string msgId = header->msg_id();
  CM_TRACE_INFO("CmMsgDealerHandler::OnDealMessage Receive message, msg_id=" << msgId
               << ", operator_code=" << op_code);

  IMessage *pReq = msgbody;

  if(NULL == pReq)
  {
    CM_TRACE_ERROR("CmMsgDealerHandler::OnDealMessage Message body is NULL, msg_id="
                 << msgId << ", operator_code=" << op_code);
    return CM_ERROR;
  }

  if(msgId == ACTCFG_MSG_ID)
  {
	CM_TRACE_INFO(gettext("Process activate command:")<<ACTCFG_MSG_ID);
	actcfgfile *pCmd = dynamic_cast<actcfgfile *>(msgbody);
	if(NULL == pCmd)
	{
		CM_TRACE_ERROR(gettext("Wrong message type, not actcfgfile "));
		return CM_ERROR;
	}

	if ( pCmd->cfgfiledir() == "")
	{
		CM_TRACE_ERROR("File path not set when import XML.");
		return CM_ERROR;
	}

	CM_TRACE_INFO(gettext("XML filepath=") << pCmd->cfgfiledir());

	char importxml_bin[1024] = {0};
	char restartubp_bin[1024] = {0};
	char xmlfiledir[1024] = {0};
	ACE_OS::memset(importxml_bin, 0, 1024);
	ACE_OS::memset(restartubp_bin, 0, 1024);
	ACE_OS::memset(xmlfiledir, 0, 1024);
	char *tempstr = ACE_OS::getenv("EASY_INSTALL");
	if (NULL==tempstr)
	{
		CM_TRACE_ERROR("env {EASY_INSTALL} is not set. Use local path.");
		return CM_ERROR;//add error msg later
	}
	else
	{
		ACE_OS::snprintf(importxml_bin, sizeof(importxml_bin),
                         "%s/bin/dbproc/ubp_importdb.sh", tempstr);
		ACE_OS::snprintf(restartubp_bin, sizeof(restartubp_bin),
                         "%s/bin/restartubp.sh", tempstr);
		ACE_OS::snprintf(xmlfiledir, sizeof(xmlfiledir),
                         "%s/ftp/cm", tempstr);
	}

	string importxml_bin_file(importxml_bin);
	string xmlfilepath(xmlfiledir);
	xmlfilepath = xmlfilepath + "/" + pCmd->cfgfiledir();
	CM_TRACE_INFO(gettext("Import XML BIN file is:")<<importxml_bin_file);
	string cmdline = importxml_bin_file + " " + xmlfilepath + " del";
	int status = system(cmdline.c_str());
	if (status != UBP_SUCCESS)
	{
		return CM_ERROR;
	}
    
	return CM_SUCCESS;
  }
  else
  {
  	CM_TRACE_ERROR("CmMsgDealerHandler::OnDealMessage ERROR! Unknow msgid, \
                      msgId=" << msgId);
      result = CM_ERROR;
  }
  /*
  switch(op_code)
  {
    case ACTCFG_MSG_ID:
      result = query.AddMO(pReq);
      break;
    default:
      CM_TRACE_ERROR("CmMsgDealerHandler::OnDealMessage ERROR! Unknow op code, \
                      operator_code=" << op_code);
      result = CM_ERROR;
      break;
  };
 */
  return result;
}


