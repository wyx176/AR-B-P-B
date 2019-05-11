#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

#Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }

install_overture(){
	port=$(netstat -nltpu | grep ':53')
	if [[ ! -z ${port} ]]; then
		echo "53端口已经被使用，请先禁用该端口所占用的服务："
		echo "${port}"
		exit 1
	fi
	echo "开始安装！这通常不需要很久"
    ARCH=$(uname -m)
    NEW_VER=$(curl -s https://api.github.com/repos/shawn1m/overture/releases/latest | grep 'tag_name' | cut -d\" -f4)
    if [[ "$ARCH" == "i686" ]] || [[ "$ARCH" == "i386" ]]; then
        VDIS="386"
    elif [[ "$ARCH" == "x86_64" ]]; then
        VDIS="amd64"
    elif [[ "$ARCH" == *"armv7"* ]] || [[ "$ARCH" == "armv6l" ]]; then
        VDIS="arm"
    elif [[ "$ARCH" == *"armv8"* ]] || [[ "$ARCH" == "aarch64" ]]; then
        VDIS="arm64"
    elif [[ "$ARCH" == *"mips64le"* ]]; then
        VDIS="mips64le"
    elif [[ "$ARCH" == *"mips64"* ]]; then
        VDIS="mips64"
    elif [[ "$ARCH" == *"mipsle"* ]]; then
        VDIS="mipsle"
    elif [[ "$ARCH" == *"mips"* ]]; then
        VDIS="mips-hardfloat"
    fi
	mkdir -p /tmp/overture
	mkdir -p /etc/overture
	cd /tmp/overture
	wget -q  https://github.com/shawn1m/overture/releases/download/${NEW_VER}/overture-linux-${VDIS}.zip
	unzip -q ./overture-linux-${VDIS}.zip
	rm ./*zip
	mv ./overture-linux-${VDIS} /usr/bin/overture
	mv ./* /etc/overture
	cd ~
	rm -rf /tmp/overture
	cat >>/usr/local/shadowsocksr/logrun.sh <<EOF
eval $(ps -ef | grep "overture" | awk '{print "kill "$2}')
cd /etc/overture; nohup overture -c ./config.json >> ./dns.log 2>&1 &
EOF
	echo "安装完成！"

	firsttime=1
}
check_over(){
	if [[ ! -e /usr/bin/overture ]]; then
		echo "本功能依赖于部分软件包，这些软件包未在脚本安装时提供"
		echo "按回车键继续安装，Ctrl+C退出安装！"
		read -s
		install_overture
	fi
}
start_ss(){
	bash /usr/local/shadowsocksr/stop.sh
	killall overture
	bash /usr/local/shadowsocksr/logrun.sh 2>/dev/null
	sleep 1s
	PID=$(ps -aux | grep 'overture' | grep -v grep | awk '{print $2}')
	if [[ -z ${PID} ]]; then
		echo "启动失败！"
		tail -n 8 /etc/overture/dns.log
	else
		if [[ ${firsttime} == "1" ]]; then
			sed -i "s/^nameserver.*/nameserver 127.0.0.1/" /etc/resolv.conf
		fi
		echo "启动成功！（此处可能会导致系统卡死，稍等即可）"
	fi
}
update_hosts(){
	echo "请选择过滤等级："
	echo "1.True Lite Blocking(50K+ Domains)"
	echo "2.Energized GO Edition(120K+ Domains)"
	echo "3.Finest Midrange Protection(180K+ Domains)"
	echo "4.Energized Basic Protection(450K+ Domains)"
	echo "5.Energized Porn Blocking(530K+ Domains)"
	echo "6.Energized Flagship Annoyances Protection(700K+ Domains)"
	echo "7.Energized Flagship Annoyances & Porn Protection(1200K+ Domains)"
	echo "8.Nano(off)"
	while :; do echo
	read -p "请选择： " choice
	if [[ ! $choice =~ ^[1-8]$ ]]; then
                if [[ -z ${choice} ]]; then
                        main
                        break
                fi
		echo "输入错误! 请输入正确的数字!"
	else
		echo
		echo
		break
	fi
	done
	if [[ ${choice} == 1 ]]; then
		url="https://raw.githubusercontent.com/EnergizedProtection/block/master/spark/formats/hosts"
	elif [[ ${choice} == 2 ]]; then
		url="https://raw.githubusercontent.com/EnergizedProtection/block/master/bluGo/formats/hosts"
	elif [[ ${choice} == 3 ]]; then
		url="https://raw.githubusercontent.com/EnergizedProtection/block/master/blu/formats/hosts"
	elif [[ ${choice} == 4 ]]; then
		url="https://raw.githubusercontent.com/EnergizedProtection/block/master/basic/formats/hosts"
	elif [[ ${choice} == 5 ]]; then
		url="https://raw.githubusercontent.com/EnergizedProtection/block/master/porn/formats/hosts"
	elif [[ ${choice} == 6 ]]; then
		url="https://raw.githubusercontent.com/EnergizedProtection/block/master/ultimate/formats/hosts"
	elif [[ ${choice} == 7 ]]; then
		url="https://raw.githubusercontent.com/EnergizedProtection/block/master/unified/formats/hosts"
	fi
	if [[ ${choice} == 8 ]]; then
		cat /etc/hosts > /etc/overture/hosts_sample
	else
		echo "开始下载黑名单列表！"
		curl -s -L -o /etc/overture/hosts_sample ${url}
		echo "下载成功！"
	fi
	echo "若要应用该文件，将会重启SSR服务，这将会导致已连接的用户掉线."
	echo "输入回车键继续，其它内容将会退出，您可以等合适的时间自行重启服务！"
	read -n 1 yn
	if [[ -z ${yn} ]]; then
		start_ss
	else 
		main
	fi
}
main(){
	check_over
	if [[ ${firsttime} == 1 ]]; then
		update_hosts
	fi
	PID=$(ps -aux | grep 'overture' | grep -v grep | awk '{print $2}')
	if [[ -z ${PID} ]]; then
		status="(服务未启动)"
	fi
	echo "1.启动服务${status}"
	echo "2.停止服务"
	echo "3.更新访问黑名单列表"
	while :; do echo
	read -p "请选择： " choice
	if [[ ! $choice =~ ^[1-3]$ ]]; then
                if [[ -z ${choice} ]]; then
                        bash /usr/local/SSR-Bash-Python/dev.sh
                        break
                fi
		echo "输入错误! 请输入正确的数字!"
	else
		echo 
		break	
	fi
	done
	if [[ ${choice} == 1 ]]; then
		start_ss
		bash /usr/local/SSR-Bash-Python/dev.sh
	elif [[ ${choice} == 2 ]]; then
		kill -9 ${PID}
		echo "已停止"
	elif [[ ${choice} == 3 ]]; then
		update_hosts
		bash /usr/local/SSR-Bash-Python/dev.sh
	fi
}
main
exit 0
