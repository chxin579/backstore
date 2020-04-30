
#!/bin/sh
echo "开始安装"
wget https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz
xz -d ffmpeg-release-amd64-static.tar.xz
tar xvf ffmpeg-release-amd64-static.tar
Folder_A="/root"
for file_a in ${Folder_A}/*
do
    result=$(echo "$file_a" | grep "ffmpeg" )
    if [ "$result" != ""  ] ; then
    resulta=$(echo "$file_a" | grep "tar" )
      if [ "$resulta" == ""  ] ; then
        mv $file_a/ffmpeg /usr/bin/ffmpeg
        mv $file_a/ffprobe /usr/bin/ffprobe
      fi
    fi
done
resultb=$(ffmpeg -version | grep "ffmpeg version" )
if [ "$resultb" != ""  ] ; then
  echo "安装成功"
else
  echo "安装失败"
fi
