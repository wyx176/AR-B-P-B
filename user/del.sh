#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

#Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }

#Check OS
if [ -n "$(grep 'Aliyun Linux release' /etc/issue)" -o -e /etc/redhat-release ];then
OS=CentOS
[ -n "$(grep ' 7\.' /etc/redhat-release)" ] && CentOS_RHEL_version=7
[ -n "$(grep ' 6\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release6 15' /etc/issue)" ] && CentOS_RHEL_version=6
[ -n "$(grep ' 5\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release5' /etc/issue)" ] && CentOS_RHEL_version=5
elif [ -n "$(grep 'Amazon Linux AMI release' /etc/issue)" -o -e /etc/system-release ];then
OS=CentOS
CentOS_RHEL_version=6
elif [ -n "$(grep bian /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Debian' ];then
OS=Debian
[ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep Deepin /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Deepin' ];then
OS=Debian
[ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep Ubuntu /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Ubuntu' -o -n "$(grep 'Linux Mint' /etc/issue)" ];then
OS=Ubuntu
[ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
Ubuntu_version=$(lsb_release -sr | awk -F. '{print $1}')
[ -n "$(grep 'Linux Mint 18' /etc/issue)" ] && Ubuntu_version=16
elif [ ! -z "$(grep 'Arch Linux' /etc/issue)" ];then
    OS=Ubuntu
else
echo "${CFAILURE}Does not support this OS, Please contact the author! ${CEND}"
kill -9 $$
fi

echo "1.使用用户名"
echo "2.使用端口"
echo ""
while :; do echo
	read -p "请选择： " lsid
	if [[ ! $lsid =~ ^[1-2]$ ]]; then
		if [[ $lsid == "" ]]; then
			bash /usr/local/SSR-Bash-Python/user.sh || exit 0
		fi
		echo "输入错误! 请输入正确的数字!"
	else
		break	
	fi
done
if [[ $lsid == 1 ]];then
	read -p "输入用户名： " uid
	cd /usr/local/shadowsocksr
	python mujson_mgr.py -d -u $uid || echo "删除失败，用户名或端口号无效"
	echo "已成功删除用户名为 $uid 的用户流量"
        port=$(python mujson_mgr.py -l -u ${uid} | grep "port :" | awk -F" : " '{ print $2 }')
fi
if [[ $lsid == 2 ]];then
	read -p "输入端口号： " uid
	cd /usr/local/shadowsocksr
	python mujson_mgr.py -d -p $uid || echo "删除失败，用户名或端口号无效"
	echo "已成功删除端口号为 $uid 的用户流量"
        port=${uid}
fi
if [[ ${OS} =~ ^Ubuntu$|^Debian$ ]];then
	iptables-restore < /etc/iptables.up.rules
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport $port -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport $port -j ACCEPT
	iptables-save > /etc/iptables.up.rules
fi

if [[ ${OS} == CentOS ]];then
	if [[ $CentOS_RHEL_version == 7 ]];then
		iptables-restore < /etc/iptables.up.rules
    		iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport $port -j ACCEPT
		iptables -D INPUT -m state --state NEW -m udp -p udp --dport $port -j ACCEPT
		iptables-save > /etc/iptables.up.rules
	else
    		iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport $port -j ACCEPT
		iptables -D INPUT -m state --state NEW -m udp -p udp --dport $port -j ACCEPT
		/etc/init.d/iptables save
		/etc/init.d/iptables restart
	fi
fi
