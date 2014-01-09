#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
 
static int getResultFromSystemCall(const char* pCmd, char* pResult, int size)
{
   int fd[2];
   if(pipe(fd))   {
      printf("pipe error!\n");
      return -1;
   }
 
   //prevent content in stdout affect result
   fflush(stdout);
 
   //hide stdout
   int bak_fd = dup(STDOUT_FILENO);
   int new_fd = dup2(fd[1], STDOUT_FILENO);
 
   //the output of `pCmd` is write into fd[1]
   system(pCmd);
   read(fd[0], pResult, size-1);
   pResult[strlen(pResult)-1] = 0;
 
   //resume stdout
   dup2(bak_fd, new_fd);
 
   return 0;
}
 
 
 
int main(void)
{
   char* filePath = "./test.conf";
   char* key = "aaa";
   char res[100] = {0};
 
   char cmd[100] = {0};
   sprintf(cmd, "cat %s | grep -m 1 -E \"^%s\" | cut -d= -f2 | sed 's/[[:space:]]*//g'", filePath, key);
   getResultFromSystemCall(cmd, res, sizeof(res)/sizeof(res[0]));
   //getResultFromSystemCall("export aaa=1234 && echo ${aaa#=}", res, sizeof(res)/sizeof(res[0]));
 
   printf("result is [%s]\n", res);
 
   return 0;
}
