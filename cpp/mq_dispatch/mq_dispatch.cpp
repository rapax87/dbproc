#include "platform/modules/mq/mq_dispatch.hpp"
#include "platform/modules/util/utils.hpp"
#include "message_socket.hpp"

using namespace ubp::platform::mq;

//////////////////////////////////////////////////////////////////////////
//implemention of MsgDispatcher
//////////////////////////////////////////////////////////////////////////
MsgDispatcher::MsgDispatcher(IMessageContext *pContext, const std::string &endpoint):
  pMqContext_(pContext), endpoint_(endpoint)
{
}

MsgDispatcher::~MsgDispatcher()
{
  if(NULL != pPushSocket_)
  {
    delete pPushSocket_;
  }
}

ACE_INT32 MsgDispatcher::Init()
{
  pPushSocket_ = new IMessageSocket(pMqContext_, MODE_ROUTER, EndPoint(endpoint_));
  ACE_INT32 rc = pPushSocket_->Bind();
  MQ_CHECK_VAL_RETURN_FAIL(rc, "MsgDispatcher bind socket error");
  UBP_MQ_INFO("MsgDispatcher socket binding success : " << endpoint_);

  return UBP_SUCCESS;
}

ACE_INT32 MsgDispatcher::Fini()
{
  pPushSocket_->Close();
  for(WorkerIter it = taskMap_.begin(); it != taskMap_.end(); ++it)
  {
    it->second->Fini();
  }

  taskMap_.clear();

  return UBP_SUCCESS;
}

ACE_INT32 MsgDispatcher::AddWorker(const std::string &workerId, MsgDealWorker *pWorker)
{
  ACE_INT32 rc = UBP_FAIL;
  MsgDealWorker *pTask = dynamic_cast<MsgDealWorker *>(pWorker);
  MQ_CHECK_NULL_RETURN_FAIL(pTask, "MsgDispatcher get NULL pWorker error");

  rc = pTask->Init(pMqContext_, endpoint_, workerId);
  MQ_CHECK_VAL_RETURN_FAIL(rc, "MsgDispatcher init MsgDealWorker error");

  ACE_WRITE_GUARD_RETURN(ACE_Recursive_Thread_Mutex, mon, rwTaskMapMutex_, UBP_FAIL);
  taskMap_.insert(WorkerMapPair(workerId, WorkerPtr(pTask)));

  pMqContext_->Context()->ModuleRef<ubp::platform::thread::ThreadPool>()->
  PostRequest(pTask);
  return UBP_SUCCESS;
}

ACE_INT32 MsgDispatcher::PushMsg(const std::string &workerId, void *pMsg)
{
  WorkerIter iter;
  {
    ACE_READ_GUARD_RETURN(ACE_Recursive_Thread_Mutex, mon, rwTaskMapMutex_, UBP_FAIL);
    iter = taskMap_.find(workerId);
    if(iter == taskMap_.end())
    {
      UBP_MQ_ERROR("MsgDispatcher can't find WorkerID : " << workerId);
      return UBP_FAIL;
    }
  }

  ACE_WRITE_GUARD_RETURN(ACE_Recursive_Thread_Mutex, mon, rwPushSocketMutex_, UBP_FAIL);
  pPushSocket_->Send(workerId, MORE_NOWAIT);
  pPushSocket_->SendPtr(pMsg);
  return UBP_SUCCESS;
}

void *MsgDispatcher::OnMessage()
{
  zmq_pollitem_t items [] =
  {
    { pPushSocket_->GetMQSocket(), 0, ZMQ_POLLIN, 0 },
  };

  ACE_INT32 ret = zmq_poll(items, 1, 0);
  MQ_CHECK_CONDITION_RETURN_NULL(ret < 0, "IMessageQueue::OnMessage zmq_poll error");
  ACE_UINT32 currentFrameNum = 0;
  zmq_msg_t zmq_msg;
  void *pMsg = NULL;

  if(items[0].revents & ZMQ_POLLIN)
  {
    while(currentFrameNum < 2)
    {
      if(currentFrameNum == 0) //dealer socket带的标识，不需要处理
      {
        zmq_msg_init(&zmq_msg);
        ACE_INT32 size = zmq_recvmsg(pPushSocket_->GetMQSocket(), &zmq_msg, 0);
        if(size <= 0)
        {
          zmq_msg_close(&zmq_msg);
          break;
        }
        currentFrameNum++;
        zmq_msg_close(&zmq_msg);
      }
      else if(currentFrameNum == 1) //first frame:header
      {
        pMsg = pPushSocket_->RecvPtr<void>();
        break;
      }
    }
  }
  return pMsg;
}

//////////////////////////////////////////////////////////////////////////
//implemention of MsgDealWorker
//////////////////////////////////////////////////////////////////////////
MsgDealWorker::MsgDealWorker()
{

}
MsgDealWorker::~MsgDealWorker()
{
  UBP_RELEASE_PTR(pDealSocket_);
}

ACE_INT32 MsgDealWorker::Init(IMessageContext *pContext, const std::string &endpoint,
                              const std::string &workerId)
{
  workerId_ = workerId;
  pDealSocket_ = new IMessageSocket(pContext, MODE_DEALER, EndPoint(endpoint));
  pDealSocket_->SetIndentity(workerId);
  pDealSocket_->Connect();
  SetRun(true);
  return UBP_SUCCESS;
}

ACE_INT32 MsgDealWorker::Fini()
{
  SetRun(false);
  pDealSocket_->Close();
  return UBP_SUCCESS;
}

IMessageSocket *MsgDealWorker::GetSocket() const
{
  return pDealSocket_;
}

ACE_INT32 MsgDealWorker::call()
{
  zmq_pollitem_t items [] =
  {
    { pDealSocket_->GetMQSocket(), 0, ZMQ_POLLIN, 0 },
  };

  while(IsRun())
  {
    ACE_INT32 ret = zmq_poll(items, 1, -1);
    if(ret < 0)
    {
      if(!IsRun())
      {
        UBP_MQ_ERROR("MsgWorkerTask::RecvMsg zmq_poll error,break thread!");
        break;
      }
    }

    if(items [0].revents & ZMQ_POLLIN)
    {
      do
      {
        void *pMsg = pDealSocket_->RecvPtr<void>();
        if(NULL == pMsg)
        {
          UBP_MQ_DEBUG("MsgDealWorker::RecvPtr msg is NULL,break thread!");
          break;
        }
        OnMessage(pMsg);
      }
      while(true);
    }
  }

  return UBP_SUCCESS;
}

bool MsgDealWorker::IsRun() const
{
  return run_;
}

void MsgDealWorker::SetRun(bool val)
{
  run_ = val;
}

std::string MsgDealWorker::GetWorkerID() const
{
  return workerId_;
}

ACE_INT32 MsgDealWorker::SendMsg2Dispatcher(void *pMsg)
{
  ACE_INT32 ret = UBP_FAIL;
  ACE_WRITE_GUARD_RETURN(ACE_Recursive_Thread_Mutex, mon, rwSendSocketMutex_, UBP_FAIL);
  ret = pDealSocket_->SendPtr<void>(pMsg);
  return ret;
}

