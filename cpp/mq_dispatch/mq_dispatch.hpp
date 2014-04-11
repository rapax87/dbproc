#ifndef UBP_PLATFORM_MOUDLES_MQ_DISPATCH_HPP_
#define UBP_PLATFORM_MOUDLES_MQ_DISPATCH_HPP_

#include "ace/Basic_Types.h"
#include "boost/shared_ptr.hpp"
#include <memory>
#include <list>
#include <string>

#include "platform/modules/thread/ubp_threadpool.hpp"
#include "mq_context_itf.hpp"

namespace ubp
{
namespace platform
{
namespace mq
{
class IMessageSocket;
class MsgDealWorker;

typedef MsgDealWorker* WorkerPtr;
typedef std::map<std::string, WorkerPtr>  WorkerMap;
typedef std::map<std::string, WorkerPtr>::iterator WorkerIter;
typedef std::map<std::string, WorkerPtr>::const_iterator WorkerConstIter;
typedef std::pair<std::string, WorkerPtr> WorkerMapPair;
typedef std::pair<WorkerMap::const_iterator, bool> WorkerMapPairRet;
typedef WorkerMap::value_type WorkerValueType;

class MQ_IMPORT_EXPORT MsgDispatcher
{
  public:
    MsgDispatcher(IMessageContext *pContext, const std::string &endpoint);
    virtual ~MsgDispatcher();

    ACE_INT32 Init();

    ACE_INT32 Fini();

    ACE_INT32 AddWorker(const std::string &workerId, MsgDealWorker *pWorker);

    ACE_INT32 PushMsg(const std::string &workerId, void *pMsg);

    void *OnMessage();

  private:
    IMessageSocket *pPushSocket_;
    WorkerMap taskMap_;
    IMessageContext *pMqContext_;
    std::string endpoint_;
    ACE_Recursive_Thread_Mutex rwPushSocketMutex_;  //rwPushSocketMutex_璇诲啓閿?
    ACE_Recursive_Thread_Mutex rwTaskMapMutex_;  //rwPushSocketMutex_璇诲啓閿?
};

//////////////////////////////////////////////////////////////////////////
class MQ_IMPORT_EXPORT MsgDealWorker: private ubp::platform::thread::WorkerRequest
{
    friend MsgDispatcher;
  public:
    MsgDealWorker();
    virtual ~MsgDealWorker();

    /********************************************************************
     Method:      OnMessage
     FullName:    MsgDealWorker::OnMessage
     Access:      public
     Returns:     void
     Description: 鎺ユ敹MsgDispatcher娲惧彂鐨勬秷鎭?
     Parameter:   void *pMsg 浣跨敤鍚庨渶瑕乺elease
    ********************************************************************/
    virtual ACE_INT32 OnMessage(void *pMsg) = 0;

    /********************************************************************
     Method:      SendMsg2Dispatcher
     FullName:    MsgDealWorker::SendMsg2Dispatcher
     Access:      public
     Returns:     ACE_INT32锛氬彂閫佹秷鎭殑闀垮害锛屽鏋滆繑鍥濽BP_FAIL鍙戦€佸け璐?
     Description: 鍚慚sgDispatcher鍙戦€佹秷鎭?
     Parameter:   void *pMsg锛歁sgDispatcher鎺ユ敹鍒伴渶瑕乺elease
    ********************************************************************/
    ACE_INT32 SendMsg2Dispatcher(void *pMsg);

    virtual ACE_INT32 call(void);
    bool IsRun() const;
    void SetRun(bool val);
    std::string GetWorkerID() const;
  protected:
    ACE_INT32 Init(IMessageContext *pContext,const std::string& endpoint,
        const std::string& workerId);
    ACE_INT32 Fini();
    IMessageSocket* GetSocket() const;
  private:
    IMessageSocket *pDealSocket_;
    bool run_;
    std::string workerId_;
    ACE_Recursive_Thread_Mutex rwSendSocketMutex_;  //rwSendSocketMutex_璇诲啓閿?
};

}//mq
}//platform
}//ubp
#endif //UBP_PLATFORM_MOUDLES_MQ_DISPATCH_HPP_
