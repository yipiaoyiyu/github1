#脚本功能：1判断进程clconfd是否存在，不存在先启动；2存在再判断内存占用率，剩余内存小于10M的时候，重启进程
#!/usr/bin/ksh
logfile=/tmp/`hostname`_clconfd.log
clconfd_status=`lssrc -s clconfd|grep "clconfd" |awk '{print $NF}'`
echo "Now clconfd status is:${clconfd_status}!!!"|tee -a ${logfile}
while true
do 
    if [  "${clconfd_status}" != "active" ];then
	   sleep 3   ##循环5s检查clconfd进程是否启动成功
       echo "`date +"%Y%m%d-%H:%M:%S"`:clconfd is down,please start process..."|tee -a ${logfile}
	   startsrc -s clconfd
    else
       echo "`date +"%Y%m%d-%H:%M:%S"`:clconfd is normal!" |tee -a ${logfile}
       break;  ###如果进程启动正常了就跳出整个循环。
    fi
echo "###############################################################" |tee -a ${logfile}
done

##第二段判断剩余内存是否小于10M，是的话则重启clconfd 
##65536个page * 4k pagesize= 256M
##预留10M重启：10M/4k=2560个pages
PID_clconfd=`ps -ef|grep "/usr/sbin/clconfd"|grep -v grep|awk '{print $2}'`
primate_mem=`svmon -P $PID_clconfd -r  -m|awk '{a[NR]=$0;if(a[NR-1]~/work process private/) {print a[NR]}}'|awk '{sub("^ *","");sub(" *$",""); print}'` 
heap=`svmon -P $PID_clconfd -r  -m|awk '{a[NR]=$0;if(a[NR-1]~/work process private/) {print a[NR]}}' |cut -d ':' -f2 |awk -F '.' '{print $3}'|awk '{sub("^ *","");sub(" *$",""); print}' `
stack=`svmon -P $PID_clconfd -r  -m|awk '{a[NR]=$0;if(a[NR-1]~/work process private/) {print a[NR]}}' |cut -d ':' -f3 |awk -F '.' '{print $1}'|awk '{sub("^ *","");sub(" *$",""); print}' `
minus=`expr ${stack} - ${heap}`

##打印的是过滤行的下一行行号 svmon -P 27131944 -r  -m|awk '/work process private/{a=NR-1;print a}'  
##去掉字符串开头和结尾的空格 awk '{sub("^ *","");sub(" *$",""); print}'  1.list

echo "Current PID is : ${PID_clconfd}"|tee -a ${logfile}
echo "current memory usage is :$primate_mem"|tee -a ${logfile}
echo "current free memory is :expr ${stack} - ${heap} = ${minus}"|tee -a ${logfile}
if [[ ${minus} -le 2560 ]]
then
   echo "The free memeory is less than 10M,you should restart clconfd!!!" |tee -a ${logfile}
   stopsrc -s clconfd
   sleep 3
   startsrc -s clconfd
   echo "after restart,the new status is:`lssrc -s clconfd|grep "clconfd" |awk '{print $NF}'`" 
   NEW_PID_clconfd=`ps -ef|grep "/usr/sbin/clconfd"|grep -v grep|awk '{print $2}'`
   svmon -P $NEW_PID_clconfd -r  -m|tee -a ${logfile}   
else
   echo "The free memory of clconfd is enough!!!"|tee -a ${logfile}
fi
echo "*************************************************************************************************************************************"|tee -a ${logfile}
