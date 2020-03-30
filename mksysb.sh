##/usr/bin/perl /openimis/SysChk/bin/UdpJobsts.pl AIX_os_backup 开始 month $0 $$ 
#$0: 脚本本身文件名称     $$: 脚本运行时的PID
#注意.pl文件名，有的分区可能为UdpJobsts.pl 
HST=`hostname`
nfs_server="192.168.37.87" 
nfs_dir="/soft"
mount_dir="/nim_mksysb" 
LOG="${mount_dir}/mksysb_${HST}.log" 
Tmp_log="/tmp/tmplogfile" 
flag=1 

mount  ${nfs_server}:${nfs_dir}  ${mount_dir}|tee -a  ${LOG}
#重复挂nfs不会报错

returnnum=`df -g |grep -w  ${mount_dir}|wc -l`
if [[ ${returnnum} -eq 1 ]] 
then 
    echo "************************${HST}*********************" |tee -a ${LOG} 
    echo "进程$$ 提示 mount成功 "
    echo "进程$$ 提示 开始备份 `date \"+%Y%m%d %H:%M:%S\"` "|tee -a ${LOG} 
    mksysb -ieXp $mount_dir/`hostname`_mksysb_`date "+%Y%m%d_%H%M%S"`  >$Tmp_log 
    cat $Tmp_log |tee -a ${LOG}  
    msg=`cat $Tmp_log|tr -d "/n"|tr -d "/r"|tr -d "\n"|tr -s " " "_"` 
    ##tr -d删除掉资质文件中的‘\r’ (回车)  \n换行  下划线  空格，相当于把日志几行的内容拼接成一行展示
    b=`grep "Backup Completed Successfully" $Tmp_log` 
    if [ -n "$b" ] 
    then 
        echo" `date \"+%Y%m%d %H:%M:%S\"`:  进程$$ 提示 mksysb完成 !!"
    else 
        echo" `date \"+%Y%m%d %H:%M:%S\"`:  进程$$ 报警 mksysb失败!!!" 
        flag=0 
    fi 
    sleep 3 
    umount -f $mount_dir 
    sleep 3 
        dirnum=`df -g |grep ${nfs_server}:${nfs_dir} |grep -w  ${mount_dir} |wc -l`
    if [[ ${dirnum} -eq 0 ]]
    then 
       echo "进程$$ 提示 umount成功" 
    else 
       echo "进程$$ 报警 umount失败 "
    fi 
elif [[ ${returnnum} -eq 0 ]] 
then 
     echo "进程$$ 报警 mount失败" 
     flag=0 
else 
    echo "进程$$ 报警 mount异常"
    flag=0 
fi 

if [ $flag -eq 1 ] 
then 
    echo " 进程$$ 结束 AIX_os_backup作业结束状态码$a$c$msg "
else 
    echo " 进程$$ 异常 AIX_os_backup作业结束状态码$a$c$msg "
fi 

echo "exit code: $a$c$flag" |tee -a $Tmp_log 
echo "exit code: $a$c$flag*******exit time: `date \"+%Y%m%d %H:%M:%S\"`" |tee -a ${LOG}
