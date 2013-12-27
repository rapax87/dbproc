##############################################################################
#Copyright 2012,TD-Tech. Co., Ltd.
#Filename: CMakeList.txt for install collect
#Author:   XuBingbing
#Created:  2013/08/27 10:56
#Description: 
##############################################################################


##############################################################################
#                                    INSTALL                                 #
##############################################################################
INSTALL(PROGRAMS installsfha.sh DESTINATION bin/veritas)
INSTALL(PROGRAMS configVcsEnv.sh DESTINATION bin/veritas)
INSTALL(PROGRAMS config_appdir.sh DESTINATION bin/veritas)
INSTALL(PROGRAMS create_maincf.sh DESTINATION bin/veritas)
INSTALL(PROGRAMS changeip.sh DESTINATION bin/veritas)
INSTALL(PROGRAMS config_vvr.sh DESTINATION bin/veritas)
INSTALL(PROGRAMS startsfha.sh DESTINATION bin/veritas)
INSTALL(PROGRAMS clean.sh DESTINATION bin/veritas)
INSTALL(PROGRAMS config_vxvm.sh DESTINATION bin/veritas)
INSTALL(PROGRAMS setDiskId.sh DESTINATION bin/veritas)
INSTALL(PROGRAMS stopha.sh DESTINATION bin/veritas)
INSTALL(PROGRAMS copy_agent.sh DESTINATION bin/veritas)
INSTALL(PROGRAMS hacommon.sh DESTINATION bin/veritas)
INSTALL(PROGRAMS startha.sh DESTINATION bin/veritas)
INSTALL(PROGRAMS recover.sh DESTINATION bin/veritas)
INSTALL(PROGRAMS reinstallUBP_ch.sh DESTINATION bin/veritas)
INSTALL(PROGRAMS reinstallUBP_en.sh DESTINATION bin/veritas)
INSTALL(DIRECTORY eAPPApplication DESTINATION bin/veritas/ PATTERN ".svn" EXCLUDE)
INSTALL(DIRECTORY conf DESTINATION bin/veritas/ PATTERN ".svn" EXCLUDE)
