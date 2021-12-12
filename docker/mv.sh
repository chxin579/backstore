#! /bin/bash
#! move file tools v2
function read_dir(){
IFS_BACKUP=$IFS
IFS=$(echo -en "\n\b")
for file in `ls $1` #注意此处这是两个反引号，表示运行系统命令
do
 if [ $1 == "/down/up"x ] #注意此处之间一定要加上空格，否则会报错
 then
 read_dir $1"/"$file
 elif [ -d $1"/"$file ] 
 then
 echo ""
 else
 
 size=$(wc -c $1"/"$file | awk '{print $1}')
  if [[ $size -gt 314572800 ]]
  then 
  echo $file #在此处处理文件即可
  mv $1"/"$file /down/up
  #mv $1"/"$file /down/up/$file
  fi
 fi
done
echo "finish moved"
IFS=$IFS_BACKUP
} 
#读取第一个参数
read_dir '/down'