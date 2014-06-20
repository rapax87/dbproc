锘?********************************************************************
Copyright 2012,TD-Tech. Co., Ltd.
Filename:      maintain_agent.cpp
Author:        XiaoLongguang
Created:       2012/01/23 11:08
Description:
*********************************************************************/
#include <iomanip>
#include <ace/OS_NS_time.h>
#include <boost/format.hpp>
#include "ubp_globe.hpp"
#include "platform/modules/sca/ubp_svc_env.hpp"
#include "platform/modules/util/locale_service.hpp"

#include "platform/modules/svcmgr/ubp_svc_mgr.hpp"
#include "platform/modules/util/utils.hpp"

#include "lm/lm_proxy.hpp"
#include "maintain_agent.hpp"
#include "maintain_trace.hpp"
#include "maintain/maintain_def.hpp"
#include "maintain/maintain_error.hpp"
#include "ace/Reactor.h"



using namespace ubp::lm;
using namespace ubp::maintain;
using namespace ubp::platform::sca;
using namespace ubp::platform::util;
using namespace ubp::platform::trace;

using namespace ubp::platform::svcmgr;

//////////////////////////////////////////////////////////////////////////
//implemention of MaintainAgentImpl
//////////////////////////////////////////////////////////////////////////
MaintainAgentImpl::MaintainAgentImpl(void)
{
}

MaintainAgentImpl::~MaintainAgentImpl(void)
{
}

int MaintainAgentImpl::Init()
{
    UBP_MAINTAIN_DEBUG("MaintainAgentImpl::Init");

    LocaleService::Init(LOCALE_UBP);

    SysLogMsg sys_msg;
    time_t curTime = ACE_OS::time(0);
    struct tm date_time;
    ACE_OS::localtime_r(&curTime, &date_time);
    std::stringstream ss;
    ss << (date_time.tm_year+1900) <<"/"
       << std::setfill('0') <<std::setw(2) << (date_time.tm_mon +1) <<"/"
       << std::setfill('0') <<std::setw(2) << date_time.tm_mday
       << " "
       << std::setfill('0') <<std::setw(2) << date_time.tm_hour <<":"
       << std::setfill('0') <<std::setw(2) << date_time.tm_min  <<":"
       << std::setfill('0') <<std::setw(2) << date_time.tm_sec;
    sys_msg.op_time=ss.str();

    sys_msg.op_level = 1;
    sys_msg.op_src = "ubp_maintain";
    try
    {
        sys_msg.op_base = boost::str(boost::format("1022#"));
    }
    catch(std::exception &e)
    {
        UBP_MAINTAIN_ERROR("boost format error:"<<e.what());
    }
    sys_msg.op_result = 0;
    sys_msg.op_desc = "";
    LmProxy* lmProxy = ServiceEnv_T::instance()->GetModule<LmProxy>();
    if (lmProxy==NULL)
    {
        //UBP_LIC_MAN_ERROR("get lmProxy error...");
    }
    else
    {
        ACE_INT32 result=lmProxy->LogAdd(sys_msg);
        //UBP_LIC_MAN_DEBUG("Add log to lm...done");
        if (result!=0)
        {
            //UBP_LIC_MAN_ERROR("error add log...");
        }
    }

    IMessageContext *pMQCntx=ServiceEnv_T::instance()->GetModule<IMessageContext>();
    if (NULL == pMQCntx)
    {
        UBP_MAINTAIN_ERROR("MaintainAgentImpl::Init pMQCntx is NULL.");
        return ERR_UBP_MAINTAIN_INIT;
    }

    //娉ㄥ唽寮傛
    //maintain_handler_.reset(new MaintainMsgDealerHandler());
    MaintainMsgDealerHandler *dealer_handler = new MaintainMsgDealerHandler();
    pMQCntx->RegMsgDealer(dealer_handler, MSG_PACKAGE_MAINTAIN);

    //娉ㄥ唽鍚屾
    MaintainResponseHandler *response_handler = new MaintainResponseHandler();
    pMQCntx->RegMsgReponser(response_handler, MSG_PACKAGE_MAINTAIN);

    //Register topic TOPIC_CM_CHANGE
    std::vector<ServiceInfo> svc_array;
    int num;
    string cmKey_;

    //if master host
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
                pMQCntx->RegMsgConsumer(it->GetServiceKey(), TOPIC_MAINTAIN_LOGCOLLECT, matintainSubHandler);//topic message in cm package
                //break;
            }
        }

        //pMQCntx->RegMsgConsumer(cmKey_, TOPIC_MAINTAIN_LOGCOLLECT, matintainSubHandler);//topic message in cm package
    }
    return UBP_SUCCESS;
}

int MaintainAgentImpl::Fini()
{
    SysLogMsg sys_msg;
    time_t curTime = ACE_OS::time(0);
    struct tm date_time;
    ACE_OS::localtime_r(&curTime, &date_time);
    std::stringstream ss;
    ss << (date_time.tm_year+1900) <<"/"
       << std::setfill('0') <<std::setw(2) << (date_time.tm_mon +1) <<"/"
       << std::setfill('0') <<std::setw(2) << date_time.tm_mday
       << " "
       << std::setfill('0') <<std::setw(2) << date_time.tm_hour <<":"
       << std::setfill('0') <<std::setw(2) << date_time.tm_min  <<":"
       << std::setfill('0') <<std::setw(2) << date_time.tm_sec;
    sys_msg.op_time=ss.str();

    sys_msg.op_level = 1;
    sys_msg.op_src = "ubp_maintain";
    try
    {
        sys_msg.op_base = boost::str(boost::format("1023#"));
    }
    catch(std::exception &e)
    {
        UBP_MAINTAIN_ERROR("boost format error:"<<e.what());
    }
    sys_msg.op_result = 0;
    sys_msg.op_desc = "";
    LmProxy* lmProxy = ServiceEnv_T::instance()->GetModule<LmProxy>();
    if (lmProxy==NULL)
    {
        //UBP_LIC_MAN_ERROR("get lmProxy error...");
    }
    else
    {
        ACE_INT32 result=lmProxy->LogAdd(sys_msg);
        //UBP_LIC_MAN_DEBUG("Add log to lm...done");
        if (result!=0)
        {
            //UBP_LIC_MAN_ERROR("error add log...");
        }
    }

    return 0;
}

extern "C" SERVICE_EXPORT
ServiceBaseItf *CreateUBPService(void)
{
    return new MaintainAgentImpl();
}

int ACE_TMAIN(int argc, ACE_TCHAR *argv[])
{
    string trace_service_name = "ubp_maintain_service";
    string service_name = "ubp_maintain";
    string service_type = "maintain_agent";

    //LocaleService ls;
    LocaleService::Init(LOCALE_UBP);


    UBPTrace_T::instance()->Init(trace_service_name.c_str());

    ServiceEnv_T::instance()->Init(service_name, service_type);

    MaintainAgentImpl agent;
    int result = agent.Init();
    if (UBP_SUCCESS == result)
    {
        UBP_MAINTAIN_DEBUG("maintain info start");
        result =  ACE_Reactor::instance()->run_reactor_event_loop();
    }

    return result;

}
