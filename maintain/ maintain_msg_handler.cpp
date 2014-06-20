锘?********************************************************************
Copyright 2012,TD-Tech. Co., Ltd.
Filename:      maintain_msg_handler.hpp
Author:        XiaoLongguang
Created:       2012/01/23 11:15
Description:
*********************************************************************/
#include "maintain_msg_handler.hpp"

#include <google/protobuf/descriptor.h>
#include "ace/Date_Time.h"

#include "ubp_globe.hpp"
#include "platform/modules/sca/ubp_svc_env.hpp"
#include "platform/modules/mq/mq_context_itf.hpp"
#include "platform/modules/mq/message_factory.hpp"
#include "platform/modules/query/mq_query.hpp"
#include "platform/modules/util/locale_service.hpp"
#include "platform/modules/util/utils.hpp"
#include "platform/modules/ftp/ftp_service.hpp"
#include "platform/modules/svcmgr/ubp_svc_mgr.hpp"

#include "maintain/maintain_msg.pb.h"
#include "maintain/maintain_def.hpp"
#include "maintain/maintain_error.hpp"
#include "maintain_trace.hpp"


using namespace ubp::maintain;
using namespace ubp::platform::sca;
using namespace ubp::platform::mq;
using namespace ubp::platform::dao;
using namespace ubp::platform::query;
using namespace ubp::platform::util;
using namespace ubp::platform::ftp;
using namespace ubp::platform::svcmgr;

MaintainMsgDealerHandler::MaintainMsgDealerHandler()
{

}

MaintainMsgDealerHandler::~MaintainMsgDealerHandler()
{

}

//////////////////////////////////////////////////////////////////////////
//implemention of MaintainSubHandler
//////////////////////////////////////////////////////////////////////////
ACE_INT32 MaintainSubHandler::OnMessage(IMessageHeader *header, IMessage *msgbody)
{
    // send msg to scc main thread
    UBP_MAINTAIN_INFO(gettext("MaintainSubHandler::OnMessage"));

    return UBP_SUCCESS;
}

ACE_INT32 MaintainMsgDealerHandler::OnDealMessage(IMessageHeader *header, IMessage *msgbody)
{
    UBP_MAINTAIN_FUNC_TRACE("MaintainMsgDealerHandler::OnDealMessage");
    ACE_INT32 op_code = -1;
    std::string msgType = "";

    if(header->has_operator_code())
    {
        op_code = header->operator_code();
    }

    std::string msgId = header->msg_id();
    UBP_MAINTAIN_DEBUG("MaintainMsgDealerHandler::OnDealMessage receive message, msg_id=" << msgId
                       << ", operator_code=" << op_code);

    //SetMsgTypeByMsgId(msgId, msgType);

    if(NULL == msgbody)
    {
        UBP_MAINTAIN_ERROR("MaintainMsgDealerHandler::OnDealMessage message body is NULL, msg_id="
                           << msgId << ", operator_code=" << op_code);
        return ERR_UBP_MAINTAIN_BODY_NULL;
    }

    //IMessage *clonedMsg=IMessageFactory::CloneMessage(*msgbody);
    //std::auto_ptr<IMessage> apClnMsg(clonedMsg);

    if(msgId == LOGCOLLECT_MSG_ID)
    {
        UBP_MAINTAIN_INFO(gettext("Process log collect command:")<<LOGCOLLECT_MSG_ID);
        logcollect *pCmd = dynamic_cast<logcollect *>(msgbody);
        //std::auto_ptr<actcfgfile> msgPtr(pmsg);
        if(NULL == pCmd)
        {
            UBP_MAINTAIN_ERROR(gettext("Wrong message type, not logcollect "));
            return UBP_FAIL;
        }

//if master host
        int num;
std::vector<ServiceInfo> svc_array;
        if (ServiceEnv_T::instance()->GetModule<ServiceMgr>()->MasterIP() == "" )
        {
            UBP_MAINTAIN_INFO("master ip is "<<ServiceEnv_T::instance()->GetModule<ServiceMgr>()->MasterIP());
            num = ServiceEnv_T::instance()->GetModule<ServiceMgr>()->GetServicesByType(svc_array,"maintain_agent");
            if (num < 1)
            {
                UBP_MAINTAIN_ERROR("InitCmContext,can't find cm service info");
                return ERR_UBP_MAINTAIN_INIT;
            }

            MaintainSubHandler *matintainSubHandler = new MaintainSubHandler;
            for(std::vector<ServiceInfo>::iterator it(svc_array.begin());
                it != svc_array.end(); ++it)
            {
                if(!Utils::IsLocalIP(it->host_ip_))
                {
                    //cmKey_ = it->GetServiceKey();
                    UBP_MAINTAIN_INFO("maintain key is: "<<it->GetServiceKey());
                    ServiceEnv_T::instance()->GetModule<IMessageContext>()->SendMessage(it->GetServiceKey(), *pCmd);
                    //pContext_->SendMessage(it->GetServiceKey(), *pmsg);
                    //pMQCntx->RegMsgConsumer(it->GetServiceKey(), TOPIC_MAINTAIN_LOGCOLLECT, matintainSubHandler);//topic message in cm package
                    //break;
                }
            }

            //pMQCntx->RegMsgConsumer(cmKey_, TOPIC_MAINTAIN_LOGCOLLECT, matintainSubHandler);//topic message in cm package
        }

        std::string savepath = "/var/tmp/tracecollection";

        char cmd[512];
        ACE_OS::memset(cmd, 0, 512);
        char *tempstr = ACE_OS::getenv("EASY_INSTALL");
        ACE_OS::snprintf(cmd, sizeof(cmd),
                         "%s/bin/collection/ubp_collect.sh all %s%s %s %s %s>/dev/null",
                         tempstr, tempstr, savepath.c_str(), pCmd->starttime().c_str(),
                         pCmd->endtime().c_str(), pCmd->filename().c_str());
        //"%s/bin/collection/ubp_collect.sh all %s >/dev/null 2>&1 &", tempstr, savepath.c_str());
        UBP_MAINTAIN_DEBUG(gettext("command=") << cmd);
        ACE_OS::system(cmd);

        std::string ldir = tempstr;
        ldir = ldir + savepath;
        UBP_MAINTAIN_DEBUG(gettext("ldir=")<<ldir);
        bool result = false;
        try
        {
            FTPService ftp_service(pCmd->ftpserverip(), pCmd->ftpusr(), pCmd->ftppwd());
            result = ftp_service.uploadFile(ldir, pCmd->filename(),  pCmd->dirname(), pCmd->filename());
        }
        catch (std::exception& exc)
        {
            printf("[%d:%s]:%s/n", __LINE__, __FILE__, exc.what());
            UBP_MAINTAIN_ERROR(gettext("Upload file failed.")<<exc.what());
            return 0;
        }
        if (!result)
        {
            UBP_MAINTAIN_ERROR(gettext("Upload file failed."));
            return UBP_FAIL;
        }
        else
        {
            UBP_MAINTAIN_INFO(gettext("Upload file successfully."));
            return UBP_SUCCESS;
        }

    }



    return UBP_SUCCESS;
}



void MaintainMsgDealerHandler::SetMsgTypeByMsgId(const std::string &msgId,
        std::string &aMsgType)
{
    UBP_MAINTAIN_FUNC_TRACE("MaintainMsgDealerHandler::SetMsgTypeByMsgId");
    ACE_UINT32 found = msgId.rfind(".");
    if(found == std::string::npos)
    {
        aMsgType = msgId;
    }
    else
    {
        aMsgType = msgId.substr(found + 1, msgId.size() - found);
    }
}

//////////////////////////////////////////////////////////////////////////////////////////
////// 鍚屾娑堟伅澶勭悊
//////////////////////////////////////////////////////////////////////////////////////////

IMessage *MaintainResponseHandler::OnReponseMessage(IMessageHeader *header, IMessage *msgbody)
{
    UBP_MAINTAIN_FUNC_TRACE("MaintainResponseHandler::OnReponseMessage");
    ACE_INT32 result = UBP_SUCCESS;
    ACE_INT32 op_code = -1;
    //IMessage *pQueryRsp = NULL;
    std::string msgType = "";

    if(header->has_operator_code())
    {
        op_code = header->operator_code();
    }

    std::string msgId = header->msg_id();
    UBP_MAINTAIN_DEBUG("MaintainResponseHandler::OnReponseMessage receive message, msg_id=" << msgId
                       << ", operator_code=" << op_code);

    //if(op_code != OP_QUERY)
    //{
    //  UBP_MAINTAIN_ERROR("MaintainResponseHandler::OnReponseMessage operator code is not QUERY, code="
    //               << op_code);
    //  return NULL;
    //}

    IMessage *pReq = msgbody;

    if(NULL == pReq)
    {
        UBP_MAINTAIN_ERROR("MaintainResponseHandler::OnReponseMessage message body is NULL, msg_id="
                           << msgId << ", operator_code=" << op_code);
        return GetMAINTAINRspByResult(UBP_MAINTAIN_FAIL);
    }

    SetMsgTypeByMsgId(msgId, msgType);


    return GetMAINTAINRspByResult(result);
    //return pQueryRsp;
}


void MaintainResponseHandler::SetMsgTypeByMsgId(const std::string &msgId, std::string &aMsgType)
{
    UBP_MAINTAIN_FUNC_TRACE("MaintainResponseHandler::SetMsgTypeByMsgId");
    ACE_UINT32 found = msgId.rfind(".");
    if(found == std::string::npos)
    {
        aMsgType = msgId;
    }
    else
    {
        aMsgType = msgId.substr(found + 1, msgId.size() - found);
    }
}

IMessage *MaintainResponseHandler::GetMAINTAINRspByResult(ACE_INT32 result)
{
    UBP_MAINTAIN_FUNC_TRACE("MaintainResponseHandler::GetMAINTAINRspByResult");
    UBP_MAINTAIN_DEBUG("MaintainResponseHandler::GetMAINTAINRspByResult handle message return. result="
                       << result);
    LogCollectRsp *pRsp = dynamic_cast<LogCollectRsp *>
                          (IMessageFactory::CreateMessage("ubp.maintain.LogCollectRsp"));
    pRsp->set_result(result);
    return pRsp;
}


