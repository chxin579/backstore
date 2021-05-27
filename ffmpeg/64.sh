
#!/bin/sh
echo "ffmpeg4.2.3-x64 start install 开始安装"
wget -N --no-check-certificate "https://raw.githubusercontent.com/chxin579/backstore/master/ffmpeg/x64/ffmpeg.tar.gz"
wget -N --no-check-certificate "https://raw.githubusercontent.com/chxin579/backstore/master/ffmpeg/x64/ffprobe.tar.gz"
tar -xzvf ffmpeg.tar.gz
tar -xzvf ffprobe.tar.gz
mv ffmpeg /usr/bin/ffmpeg
mv ffprobe /usr/bin/ffprobe
rm -rf ffmpeg.tar.gz
rm -rf ffprobe.tar.gz
resultb=$(ffmpeg -version | grep "ffmpeg version" )
if [ "$resultb" != ""  ] ; then
  echo "安装成功 install success!"
else
  echo "安装失败 install fail"
fi
