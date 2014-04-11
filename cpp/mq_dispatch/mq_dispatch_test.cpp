#include <string>
#include <iostream>
#include <memory>
#include "ace/ACE.h"
#include "ace/Reactor.h"

#include "ubp_globe.hpp"
#include "platform/modules/sca/ubp_svc_env_impl.hpp"
#include "platform/modules/mq/mq_context_itf.hpp"
#include "platform/modules/mq/mq_dispatch.hpp"
#include "platform/modules/mq/mq_trace.hpp"
#include "platform/modules/thread/ubp_threadpool.hpp"
#include "platform/modules/svcmgr/ubp_svc_mgr.hpp"
#include "platform/modules/trace/ubp_trace.hpp"
#include "platform/modules/util/utils.hpp"
#include "platform/modules/query/mq_query.hpp"

#include "platform/platform_msg.pb.h"
#include "cm/cm_msg.pb.h"

using namespace ubp::platform::mq;
using namespace ubp::platform::frame;
using namespace ubp::platform::sca;
using namespace ubp::platform::svcmgr;
using namespace ubp::platform::trace;
using namespace ubp::platform::thread;
using namespace ubp::platform::util;
using namespace ubp::platform;
using namespace ubp::cm;
using namespace ubp::platform::query;


const static char *SVC_NAME = "ubp_testmq";
const static char *AGENT_TYPE = "testmq_type";

static const char *TEST_MQ_ENDPOINT = "inproc://test.message_producer_";

//////////////////////////////////////////////////////////////////////////
class TestMsg
{
  public:
    std::string msg;
    int count;
    char buf[64];
  public:
    void Print()
    {
      std::cout << "Msg count :" << count << ",msg : " << msg << std::endl;
    }
};

//////////////////////////////////////////////////////////////////////////

class TestDispathRecvTask : public WorkerRequest
{
  public:
    TestDispathRecvTask(MsgDispatcher *pDispatch)
      : pDispatch_(pDispatch)
    {
    }

    virtual ~TestDispathRecvTask(void)
    {
    }

    virtual int call(void)
    {
      while(true)
      {
        void *pMsg = pDispatch_->OnMessage();                                               
        if(NULL != pMsg)
        {
          TestMsg *pTestMsg = (TestMsg *)pMsg;
          std::cout << "TestDispathRecvTask recv : " << pTestMsg->count << std::endl;
          delete pTestMsg;
        }
        ACE_OS::sleep(ACE_Time_Value(0,1));
      }
      return UBP_SUCCESS;
    }

  private:
    MsgDispatcher *pDispatch_;
};


//////////////////////////////////////////////////////////////////////////

class MyWorkerTask : public MsgDealWorker
{
  public:
    MyWorkerTask()
    {
    }

    ~MyWorkerTask()
    {

    }

    virtual ACE_INT32 OnMessage(void *pMsg)
    {
      UBP_MQ_INFO("MsgDealWorker : " << this->GetWorkerID());
      TestMsg *msgPtr = (TestMsg *)pMsg;
      std::cout << "MyWorkerTask "<< this->GetWorkerID()<< " recv : " << 
          msgPtr->count << std::endl;
      //std::auto_ptr<TestMsg> msgPtr((TestMsg*)pMsg);
      //msgPtr->Print();    

      TestMsg *msgSend = new TestMsg;
      msgSend->count = msgPtr->count;
      this->SendMsg2Dispatcher(msgSend);

      delete msgPtr;
      return UBP_SUCCESS;
    }

};

//////////////////////////////////////////////////////////////////////////

int main(int argc, char *argv[])
{
  MQ_FUN_INFO("!!! Test mq queue !!!");

  bool runloop = false;
  ACE_INT32 ret;
  if(argc == 1)
  {
    runloop = false;
  }
  else
  {
    runloop = true;
  }

  UBPTrace_T::instance()->Init("mq_queue_test");
  UBP_MQ_INFO("local agent name:" << SVC_NAME);
  ServiceEnvImpl_T::instance()->Init(SVC_NAME, AGENT_TYPE);

  IMessageContext *mqContext = ServiceEnvImpl_T::instance()->GetModule<IMessageContext>();
  ServiceMgr *svc_mgr = ServiceEnvImpl_T::instance()->GetModule<ServiceMgr>();

  MsgDispatcher dispatcher(mqContext, TEST_MQ_ENDPOINT);
  ret = dispatcher.Init();
  MQ_CHECK_VAL_RETURN_FAIL(ret, "Init MsgDispatcher error!");

  TestDispathRecvTask *pDispatchRecvTask = new TestDispathRecvTask(&dispatcher);
  ServiceEnvImpl_T::instance()->GetModule<ThreadPool>()->
  PostRequest(pDispatchRecvTask);

  dispatcher.AddWorker("Work_1", new MyWorkerTask());
  dispatcher.AddWorker("Work_2", new MyWorkerTask());

  for(int i = 0; i < 100; i++)
  {
    TestMsg *pMsg = new TestMsg;
    pMsg->msg = "Test";
    pMsg->count = i;
    ACE_OS::memset(pMsg->buf, 0x0, sizeof(pMsg->buf));
    if(i % 2 == 0)
    {
      dispatcher.PushMsg("Work_1", pMsg);
    }
    else
    {
      dispatcher.PushMsg("Work_2", pMsg);
    }

  }

  ACE_OS::sleep(10);

  ret = dispatcher.Fini();
  MQ_CHECK_VAL_RETURN_FAIL(ret, "Fini MsgQueue error!");

  if(runloop)
  {
    ACE_Reactor::instance()->run_reactor_event_loop();
  }
  else
  {
    ACE_OS::sleep(15 * 1);
  }

  ServiceEnvImpl_T::instance()->Fini();


  return 0;
}

