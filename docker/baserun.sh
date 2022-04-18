#!/usr/bin/env bash

echo "更新Update OneShareUpload"
wget -q http://file.thiinkget.eu.org/uploads/LinuxX64/OneShareUpload -O /usr/local/bin/OneShareUpload && chmod +x /usr/local/bin/OneShareUpload

cd /root
OneShareUpload -n

echo "更新Update mv.sh"
wget -q https://raw.githubusercontent.com/chxin579/backstore/master/docker/mv.sh -O /root/mv.sh && chmod +x /root/mv.sh

echo "更新完毕Update Finish"
