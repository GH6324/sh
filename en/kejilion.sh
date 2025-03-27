#!/bin/bash
sh_v="3.8.6"


gl_hui='\e[37m'
gl_hong='\033[31m'
gl_lv='\033[32m'
gl_huang='\033[33m'
gl_lan='\033[34m'
gl_bai='\033[0m'
gl_zi='\033[35m'
gl_kjlan='\033[96m'


canshu="default"
permission_granted="false"
ENABLE_STATS="true"


quanju_canshu() {
if [ "$canshu" = "CN" ]; then
	zhushi=0
	gh_proxy="https://gh.kejilion.pro/"
elif [ "$canshu" = "V6" ]; then
	zhushi=1
	gh_proxy="https://gh.kejilion.pro/"
else
	zhushi=1  # 0 表示执行，1 表示不执行
	gh_proxy="https://"
fi

}
quanju_canshu



# 定义一个函数来执行命令
run_command() {
	if [ "$zhushi" -eq 0 ]; then
		"$@"
	fi
}


canshu_v6() {
	if grep -q '^canshu="V6"' /usr/local/bin/k > /dev/null 2>&1; then
		sed -i 's/^canshu="default"/canshu="V6"/' ~/kejilion.sh
	fi
}


CheckFirstRun_true() {
	if grep -q '^permission_granted="true"' /usr/local/bin/k > /dev/null 2>&1; then
		sed -i 's/^permission_granted="false"/permission_granted="true"/' ~/kejilion.sh
	fi
}



# 收集功能埋点信息的函数，记录当前脚本版本号，使用时间，系统版本，CPU架构，机器所在国家和用户使用的功能名称，绝对不涉及任何敏感信息，请放心！请相信我！
# 为什么要设计这个功能，目的更好的了解用户喜欢使用的功能，进一步优化功能推出更多符合用户需求的功能。
# 全文可搜搜 send_stats 函数调用位置，透明开源，如有顾虑可拒绝使用。



send_stats() {

	if [ "$ENABLE_STATS" == "false" ]; then
		return
	fi

	local country=$(curl -s ipinfo.io/country)
	local os_info=$(grep PRETTY_NAME /etc/os-release | cut -d '=' -f2 | tr -d '"')
	local cpu_arch=$(uname -m)
	curl -s -X POST "https://api.kejilion.pro/api/log" \
		 -H "Content-Type: application/json" \
		 -d "{\"action\":\"$1\",\"timestamp\":\"$(date -u '+%Y-%m-%d %H:%M:%S')\",\"country\":\"$country\",\"os_info\":\"$os_info\",\"cpu_arch\":\"$cpu_arch\",\"version\":\"$sh_v\"}" &>/dev/null &
}


yinsiyuanquan2() {

if grep -q '^ENABLE_STATS="false"' /usr/local/bin/k > /dev/null 2>&1; then
	sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' ~/kejilion.sh
fi

}



canshu_v6
CheckFirstRun_true
yinsiyuanquan2


sed -i '/^alias k=/d' ~/.bashrc > /dev/null 2>&1
sed -i '/^alias k=/d' ~/.profile > /dev/null 2>&1
sed -i '/^alias k=/d' ~/.bash_profile > /dev/null 2>&1
cp -f ./kejilion.sh ~/kejilion.sh > /dev/null 2>&1
cp -f ~/kejilion.sh /usr/local/bin/k > /dev/null 2>&1



CheckFirstRun_false() {
	if grep -q '^permission_granted="false"' /usr/local/bin/k > /dev/null 2>&1; then
		UserLicenseAgreement
	fi
}

# 提示用户同意条款
UserLicenseAgreement() {
	clear
echo -e "${gl_kjlan}Welcome to use the tech lion script toolbox${gl_bai}"
echo "For the first time using the script, please read and agree to the user license agreement."
echo "User License Agreement: https://blog.kejilion.pro/user-license-agreement/"
	echo -e "----------------------"
	read -r -p "是否同意以上条款？(y/n): " user_input


	if [ "$user_input" = "y" ] || [ "$user_input" = "Y" ]; then
		send_stats "许可同意"
		sed -i 's/^permission_granted="false"/permission_granted="true"/' ~/kejilion.sh
		sed -i 's/^permission_granted="false"/permission_granted="true"/' /usr/local/bin/k
	else
		send_stats "许可拒绝"
		clear
		exit
	fi
}

CheckFirstRun_false





ip_address() {

ipv4_address=$(curl -s https://ipinfo.io/ip && echo)
ipv6_address=$(curl -s --max-time 1 https://v6.ipinfo.io/ip && echo)

}



install() {
	if [ $# -eq 0 ]; then
echo "No package parameters provided!"
		return 1
	fi

	for package in "$@"; do
		if ! command -v "$package" &>/dev/null; then
echo -e "${gl_huang} is installing $package...${gl_bai}"
			if command -v dnf &>/dev/null; then
				dnf -y update
				dnf install -y epel-release
				dnf install -y "$package"
			elif command -v yum &>/dev/null; then
				yum -y update
				yum install -y epel-release
				yum install -y "$package"
			elif command -v apt &>/dev/null; then
				apt update -y
				apt install -y "$package"
			elif command -v apk &>/dev/null; then
				apk update
				apk add "$package"
			elif command -v pacman &>/dev/null; then
				pacman -Syu --noconfirm
				pacman -S --noconfirm "$package"
			elif command -v zypper &>/dev/null; then
				zypper refresh
				zypper install -y "$package"
			elif command -v opkg &>/dev/null; then
				opkg update
				opkg install "$package"
			elif command -v pkg &>/dev/null; then
				pkg update
				pkg install -y "$package"
			else
echo "Unknown package manager!"
				return 1
			fi
		fi
	done
}


check_disk_space() {

	required_gb=$1
	required_space_mb=$((required_gb * 1024))
	available_space_mb=$(df -m / | awk 'NR==2 {print $4}')

	if [ $available_space_mb -lt $required_space_mb ]; then
echo -e "${gl_huang} Tip: ${gl_bai} disk space is insufficient!"
echo "Currently available space: $((available_space_mb/1024))G"
echo "Minimum demand space: ${required_gb}G"
echo "The installation cannot be continued. Please clean the disk space and try again."
		send_stats "磁盘空间不足"
		break_end
		kejilion
	fi
}


install_dependency() {
	install wget unzip tar jq
}

remove() {
	if [ $# -eq 0 ]; then
echo "No package parameters provided!"
		return 1
	fi

	for package in "$@"; do
echo -e "${gl_huang} is uninstalling $package...${gl_bai}"
		if command -v dnf &>/dev/null; then
			dnf remove -y "$package"
		elif command -v yum &>/dev/null; then
			yum remove -y "$package"
		elif command -v apt &>/dev/null; then
			apt purge -y "$package"
		elif command -v apk &>/dev/null; then
			apk del "$package"
		elif command -v pacman &>/dev/null; then
			pacman -Rns --noconfirm "$package"
		elif command -v zypper &>/dev/null; then
			zypper remove -y "$package"
		elif command -v opkg &>/dev/null; then
			opkg remove "$package"
		elif command -v pkg &>/dev/null; then
			pkg delete -y "$package"
		else
echo "Unknown package manager!"
			return 1
		fi
	done
}


# 通用 systemctl 函数，适用于各种发行版
systemctl() {
	local COMMAND="$1"
	local SERVICE_NAME="$2"

	if command -v apk &>/dev/null; then
		service "$SERVICE_NAME" "$COMMAND"
	else
		/bin/systemctl "$COMMAND" "$SERVICE_NAME"
	fi
}


# 重启服务
restart() {
	systemctl restart "$1"
	if [ $? -eq 0 ]; then
echo "$1 service has been restarted."
	else
echo "Error: Restarting $1 service failed."
	fi
}

# 启动服务
start() {
	systemctl start "$1"
	if [ $? -eq 0 ]; then
echo "$1 service started."
	else
echo "Error: Starting $1 service failed."
	fi
}

# 停止服务
stop() {
	systemctl stop "$1"
	if [ $? -eq 0 ]; then
echo "$1 service has been stopped."
	else
echo "Error: Stop $1 service failed."
	fi
}

# 查看服务状态
status() {
	systemctl status "$1"
	if [ $? -eq 0 ]; then
echo "$1 Service status is displayed."
	else
echo "Error: The $1 service status cannot be displayed."
	fi
}


enable() {
	local SERVICE_NAME="$1"
	if command -v apk &>/dev/null; then
		rc-update add "$SERVICE_NAME" default
	else
	   /bin/systemctl enable "$SERVICE_NAME"
	fi

echo "$SERVICE_NAME has been set to power on."
}



break_end() {
echo -e "${gl_lv} operation completed ${gl_bai}"
echo "Press any key to continue..."
	  read -n 1 -s -r -p ""
	  echo ""
	  clear
}

kejilion() {
			cd ~
			kejilion_sh
}




check_port() {
	install lsof

	stop_containers_or_kill_process() {
		local port=$1
		local containers=$(docker ps --filter "publish=$port" --format "{{.ID}}" 2>/dev/null)

		if [ -n "$containers" ]; then
			docker stop $containers
		else
			for pid in $(lsof -t -i:$port); do
				kill -9 $pid
			done
		fi
	}

	stop_containers_or_kill_process 80
	stop_containers_or_kill_process 443
}


install_add_docker_cn() {

local country=$(curl -s ipinfo.io/country)
if [ "$country" = "CN" ]; then
	cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": [
	"https://docker-0.unsee.tech",
	"https://docker.1panel.live",
	"https://registry.dockermirror.com",
	"https://docker.imgdb.de",
	"https://docker.m.daocloud.io",
	"https://hub.firefly.store",
	"https://hub.littlediary.cn",
	"https://hub.rat.dev",
	"https://dhub.kubesre.xyz",
	"https://cjie.eu.org",
	"https://docker.1panelproxy.com",
	"https://docker.hlmirror.com",
	"https://hub.fast360.xyz",
	"https://dockerpull.cn",
	"https://cr.laoyou.ip-ddns.com",
	"https://docker.melikeme.cn",
	"https://docker.kejilion.pro"
  ]
}
EOF
fi


enable docker
start docker
restart docker

}


install_add_docker_guanfang() {
local country=$(curl -s ipinfo.io/country)
if [ "$country" = "CN" ]; then
	cd ~
	curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/install && chmod +x install
	sh install --mirror Aliyun
	rm -f install
else
	curl -fsSL https://get.docker.com | sh
fi
install_add_docker_cn


}



install_add_docker() {
echo -e "${gl_huang} is installing docker environment...${gl_bai}"
	if  [ -f /etc/os-release ] && grep -q "Fedora" /etc/os-release; then
		install_add_docker_guanfang
	elif command -v dnf &>/dev/null; then
		dnf update -y
		dnf install -y yum-utils device-mapper-persistent-data lvm2
		rm -f /etc/yum.repos.d/docker*.repo > /dev/null
		country=$(curl -s ipinfo.io/country)
		arch=$(uname -m)
		if [ "$country" = "CN" ]; then
			curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo | tee /etc/yum.repos.d/docker-ce.repo > /dev/null
		else
			yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo > /dev/null
		fi
		dnf install -y docker-ce docker-ce-cli containerd.io
		install_add_docker_cn

	elif [ -f /etc/os-release ] && grep -q "Kali" /etc/os-release; then
		apt update
		apt upgrade -y
		apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
		rm -f /usr/share/keyrings/docker-archive-keyring.gpg
		local country=$(curl -s ipinfo.io/country)
		local arch=$(uname -m)
		if [ "$country" = "CN" ]; then
			if [ "$arch" = "x86_64" ]; then
				sed -i '/^deb \[arch=amd64 signed-by=\/etc\/apt\/keyrings\/docker-archive-keyring.gpg\] https:\/\/mirrors.aliyun.com\/docker-ce\/linux\/debian bullseye stable/d' /etc/apt/sources.list.d/docker.list > /dev/null
				mkdir -p /etc/apt/keyrings
				curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg > /dev/null
				echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://mirrors.aliyun.com/docker-ce/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
			elif [ "$arch" = "aarch64" ]; then
				sed -i '/^deb \[arch=arm64 signed-by=\/etc\/apt\/keyrings\/docker-archive-keyring.gpg\] https:\/\/mirrors.aliyun.com\/docker-ce\/linux\/debian bullseye stable/d' /etc/apt/sources.list.d/docker.list > /dev/null
				mkdir -p /etc/apt/keyrings
				curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg > /dev/null
				echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://mirrors.aliyun.com/docker-ce/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
			fi
		else
			if [ "$arch" = "x86_64" ]; then
				sed -i '/^deb \[arch=amd64 signed-by=\/usr\/share\/keyrings\/docker-archive-keyring.gpg\] https:\/\/download.docker.com\/linux\/debian bullseye stable/d' /etc/apt/sources.list.d/docker.list > /dev/null
				mkdir -p /etc/apt/keyrings
				curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg > /dev/null
				echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
			elif [ "$arch" = "aarch64" ]; then
				sed -i '/^deb \[arch=arm64 signed-by=\/usr\/share\/keyrings\/docker-archive-keyring.gpg\] https:\/\/download.docker.com\/linux\/debian bullseye stable/d' /etc/apt/sources.list.d/docker.list > /dev/null
				mkdir -p /etc/apt/keyrings
				curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg > /dev/null
				echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
			fi
		fi
		apt update
		apt install -y docker-ce docker-ce-cli containerd.io
		install_add_docker_cn


	elif command -v apt &>/dev/null || command -v yum &>/dev/null; then
		install_add_docker_guanfang
	else
		install docker docker-compose
		install_add_docker_cn

	fi
	sleep 2
}


install_docker() {
	if ! command -v docker &>/dev/null; then
		install_add_docker
	fi
}


docker_ps() {
while true; do
	clear
	send_stats "Docker容器管理"
echo "Docker container list"
	docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
	echo ""
echo "Container Operation"
	echo "------------------------"
echo "1. Create a new container"
	echo "------------------------"
echo "2. Start the specified container 6. Start all containers"
echo "3. Stop the specified container 7. Stop all containers"
echo "4. Delete the specified container 8. Delete all containers"
echo "5. Restart the specified container 9. Restart all containers"
	echo "------------------------"
echo "11. Enter the specified container 12. View the container log"
echo "13. View container network 14. View container occupancy"
	echo "------------------------"
echo "0. Return to previous menu"
	echo "------------------------"
	read -e -p "请输入你的选择: " sub_choice
	case $sub_choice in
		1)
			send_stats "新建容器"
			read -e -p "请输入创建命令: " dockername
			$dockername
			;;
		2)
			send_stats "启动指定容器"
			read -e -p "请输入容器名（多个容器名请用空格分隔）: " dockername
			docker start $dockername
			;;
		3)
			send_stats "停止指定容器"
			read -e -p "请输入容器名（多个容器名请用空格分隔）: " dockername
			docker stop $dockername
			;;
		4)
			send_stats "删除指定容器"
			read -e -p "请输入容器名（多个容器名请用空格分隔）: " dockername
			docker rm -f $dockername
			;;
		5)
			send_stats "重启指定容器"
			read -e -p "请输入容器名（多个容器名请用空格分隔）: " dockername
			docker restart $dockername
			;;
		6)
			send_stats "启动所有容器"
			docker start $(docker ps -a -q)
			;;
		7)
			send_stats "停止所有容器"
			docker stop $(docker ps -q)
			;;
		8)
			send_stats "删除所有容器"
			read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有容器吗？(Y/N): ")" choice
			case "$choice" in
			  [Yy])
				docker rm -f $(docker ps -a -q)
				;;
			  [Nn])
				;;
			  *)
echo "Invalid selection, please enter Y or N."
				;;
			esac
			;;
		9)
			send_stats "重启所有容器"
			docker restart $(docker ps -q)
			;;
		11)
			send_stats "进入容器"
			read -e -p "请输入容器名: " dockername
			docker exec -it $dockername /bin/sh
			break_end
			;;
		12)
			send_stats "查看容器日志"
			read -e -p "请输入容器名: " dockername
			docker logs $dockername
			break_end
			;;
		13)
			send_stats "查看容器网络"
			echo ""
			container_ids=$(docker ps -q)
			echo "------------------------------------------------------------"
			printf "%-25s %-25s %-25s\n" "容器名称" "网络名称" "IP地址"
			for container_id in $container_ids; do
				local container_info=$(docker inspect --format '{{ .Name }}{{ range $network, $config := .NetworkSettings.Networks }} {{ $network }} {{ $config.IPAddress }}{{ end }}' "$container_id")
				local container_name=$(echo "$container_info" | awk '{print $1}')
				local network_info=$(echo "$container_info" | cut -d' ' -f2-)
				while IFS= read -r line; do
					local network_name=$(echo "$line" | awk '{print $1}')
					local ip_address=$(echo "$line" | awk '{print $2}')
					printf "%-20s %-20s %-15s\n" "$container_name" "$network_name" "$ip_address"
				done <<< "$network_info"
			done
			break_end
			;;
		14)
			send_stats "查看容器占用"
			docker stats --no-stream
			break_end
			;;
		*)
			break  # 跳出循环，退出菜单
			;;
	esac
done
}


docker_image() {
while true; do
	clear
	send_stats "Docker镜像管理"
echo "Docker image list"
	docker image ls
	echo ""
echo "Mirror Operation"
	echo "------------------------"
echo "1. Get the specified image 3. Delete the specified image"
echo "2. Update the specified image 4. Delete all images"
	echo "------------------------"
echo "0. Return to previous menu"
	echo "------------------------"
	read -e -p "请输入你的选择: " sub_choice
	case $sub_choice in
		1)
			send_stats "拉取镜像"
			read -e -p "请输入镜像名（多个镜像名请用空格分隔）: " imagenames
			for name in $imagenames; do
echo -e "${gl_huang} getting mirror: $name${gl_bai}"
				docker pull $name
			done
			;;
		2)
			send_stats "更新镜像"
			read -e -p "请输入镜像名（多个镜像名请用空格分隔）: " imagenames
			for name in $imagenames; do
echo -e "${gl_huang} is updating the image: $name${gl_bai}"
				docker pull $name
			done
			;;
		3)
			send_stats "删除镜像"
			read -e -p "请输入镜像名（多个镜像名请用空格分隔）: " imagenames
			for name in $imagenames; do
				docker rmi -f $name
			done
			;;
		4)
			send_stats "删除所有镜像"
			read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有镜像吗？(Y/N): ")" choice
			case "$choice" in
			  [Yy])
				docker rmi -f $(docker images -q)
				;;
			  [Nn])
				;;
			  *)
echo "Invalid selection, please enter Y or N."
				;;
			esac
			;;
		*)
			break  # 跳出循环，退出菜单
			;;
	esac
done


}





check_crontab_installed() {
	if ! command -v crontab >/dev/null 2>&1; then
		install_crontab
	fi
}



install_crontab() {

	if [ -f /etc/os-release ]; then
		. /etc/os-release
		case "$ID" in
			ubuntu|debian|kali)
				apt update
				apt install -y cron
				systemctl enable cron
				systemctl start cron
				;;
			centos|rhel|almalinux|rocky|fedora)
				yum install -y cronie
				systemctl enable crond
				systemctl start crond
				;;
			alpine)
				apk add --no-cache cronie
				rc-update add crond
				rc-service crond start
				;;
			arch|manjaro)
				pacman -S --noconfirm cronie
				systemctl enable cronie
				systemctl start cronie
				;;
			opensuse|suse|opensuse-tumbleweed)
				zypper install -y cron
				systemctl enable cron
				systemctl start cron
				;;
			iStoreOS|openwrt|ImmortalWrt|lede)
				opkg update
				opkg install cron
				/etc/init.d/cron enable
				/etc/init.d/cron start
				;;
			FreeBSD)
				pkg install -y cronie
				sysrc cron_enable="YES"
				service cron start
				;;
			*)
echo "Unsupported Distribution: $ID"
				return
				;;
		esac
	else
echo "The operating system cannot be determined."
		return
	fi

echo -e "${gl_lv}crontab is installed and the cron service is running.${gl_bai}"
}



docker_ipv6_on() {
	root_use
	install jq

	local CONFIG_FILE="/etc/docker/daemon.json"
	local REQUIRED_IPV6_CONFIG='{"ipv6": true, "fixed-cidr-v6": "2001:db8:1::/64"}'

	# 检查配置文件是否存在，如果不存在则创建文件并写入默认设置
	if [ ! -f "$CONFIG_FILE" ]; then
		echo "$REQUIRED_IPV6_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
	else
		# 使用jq处理配置文件的更新
		local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

		# 检查当前配置是否已经有 ipv6 设置
		local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq '.ipv6 // false')

		# 更新配置，开启 IPv6
		if [[ "$CURRENT_IPV6" == "false" ]]; then
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {ipv6: true, "fixed-cidr-v6": "2001:db8:1::/64"}')
		else
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {"fixed-cidr-v6": "2001:db8:1::/64"}')
		fi

		# 对比原始配置与新配置
		if [[ "$ORIGINAL_CONFIG" == "$UPDATED_CONFIG" ]]; then
echo -e "${gl_huang} Currently ipv6 access ${gl_bai}"
		else
			echo "$UPDATED_CONFIG" | jq . > "$CONFIG_FILE"
			restart docker
		fi
	fi
}


docker_ipv6_off() {
	root_use
	install jq

	local CONFIG_FILE="/etc/docker/daemon.json"

	# 检查配置文件是否存在
	if [ ! -f "$CONFIG_FILE" ]; then
echo -e "${gl_hong} configuration file does not exist ${gl_bai}"
		return
	fi

	# 读取当前配置
	local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

	# 使用jq处理配置文件的更新
	local UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq 'del(.["fixed-cidr-v6"]) | .ipv6 = false')

	# 检查当前的 ipv6 状态
	local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq -r '.ipv6 // false')

	# 对比原始配置与新配置
	if [[ "$CURRENT_IPV6" == "false" ]]; then
echo -e "${gl_huang} Currently closed ipv6 access ${gl_bai}"
	else
		echo "$UPDATED_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
echo -e "${gl_huang} has successfully closed ipv6 access ${gl_bai}"
	fi
}



save_iptables_rules() {
	mkdir -p /etc/iptables
	touch /etc/iptables/rules.v4
	iptables-save > /etc/iptables/rules.v4
	check_crontab_installed
	crontab -l | grep -v 'iptables-restore' | crontab - > /dev/null 2>&1
	(crontab -l ; echo '@reboot iptables-restore < /etc/iptables/rules.v4') | crontab - > /dev/null 2>&1

}




iptables_open() {
	install iptables
	save_iptables_rules
	iptables -P INPUT ACCEPT
	iptables -P FORWARD ACCEPT
	iptables -P OUTPUT ACCEPT
	iptables -F

	ip6tables -P INPUT ACCEPT
	ip6tables -P FORWARD ACCEPT
	ip6tables -P OUTPUT ACCEPT
	ip6tables -F

}



open_port() {
	local ports=($@)  # 将传入的参数转换为数组
	if [ ${#ports[@]} -eq 0 ]; then
echo "Please provide at least one port number"
		return 1
	fi

	install iptables

	for port in "${ports[@]}"; do
		# 删除已存在的关闭规则
		iptables -D INPUT -p tcp --dport $port -j DROP 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j DROP 2>/dev/null

		# 添加打开规则
		if ! iptables -C INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j ACCEPT
		fi

		if ! iptables -C INPUT -p udp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j ACCEPT
echo "Port $port opened"
		fi
	done

	save_iptables_rules
	send_stats "已打开端口"
}


close_port() {
	local ports=($@)  # 将传入的参数转换为数组
	if [ ${#ports[@]} -eq 0 ]; then
echo "Please provide at least one port number"
		return 1
	fi

	install iptables

	for port in "${ports[@]}"; do
		# 删除已存在的打开规则
		iptables -D INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j ACCEPT 2>/dev/null

		# 添加关闭规则
		if ! iptables -C INPUT -p tcp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j DROP
		fi

		if ! iptables -C INPUT -p udp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j DROP
echo "Port $port closed"
		fi
	done

	save_iptables_rules
	send_stats "已关闭端口"
}


allow_ip() {
	local ips=($@)  # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
echo "Please provide at least one IP address or IP segment"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 删除已存在的阻止规则
		iptables -D INPUT -s $ip -j DROP 2>/dev/null

		# 添加允许规则
		if ! iptables -C INPUT -s $ip -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j ACCEPT
echo "Released IP $ip"
		fi
	done

	save_iptables_rules
	send_stats "已放行IP"
}

block_ip() {
	local ips=($@)  # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
echo "Please provide at least one IP address or IP segment"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 删除已存在的允许规则
		iptables -D INPUT -s $ip -j ACCEPT 2>/dev/null

		# 添加阻止规则
		if ! iptables -C INPUT -s $ip -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j DROP
echo "IP $ip blocked"
		fi
	done

	save_iptables_rules
	send_stats "已阻止IP"
}







enable_ddos_defense() {
	# 开启防御 DDoS
	iptables -A DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A DOCKER-USER -p tcp --syn -j DROP
	iptables -A DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A DOCKER-USER -p udp -j DROP
	iptables -A INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A INPUT -p tcp --syn -j DROP
	iptables -A INPUT -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A INPUT -p udp -j DROP

	send_stats "开启DDoS防御"
}

# 关闭DDoS防御
disable_ddos_defense() {
	# 关闭防御 DDoS
	iptables -D DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p tcp --syn -j DROP 2>/dev/null
	iptables -D DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p udp -j DROP 2>/dev/null
	iptables -D INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D INPUT -p tcp --syn -j DROP 2>/dev/null
	iptables -D INPUT -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D INPUT -p udp -j DROP 2>/dev/null

	send_stats "关闭DDoS防御"
}





# 管理国家IP规则的函数
manage_country_rules() {
	local action="$1"
	local country_code="$2"
	local ipset_name="${country_code,,}_block"
	local download_url="http://www.ipdeny.com/ipblocks/data/countries/${country_code,,}.zone"

	install ipset

	case "$action" in
		block)
			# 如果 ipset 不存在则创建
			if ! ipset list "$ipset_name" &> /dev/null; then
				ipset create "$ipset_name" hash:net
			fi

			# 下载 IP 区域文件
			if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
echo "Error: Failed to download the IP zone file of $country_code"
				exit 1
			fi

			# 将 IP 添加到 ipset
			while IFS= read -r ip; do
				ipset add "$ipset_name" "$ip"
			done < "${country_code,,}.zone"

			# 使用 iptables 阻止 IP
			iptables -I INPUT -m set --match-set "$ipset_name" src -j DROP
			iptables -I OUTPUT -m set --match-set "$ipset_name" dst -j DROP

echo "The IP address of $country_code has been blocked successfully"
			rm "${country_code,,}.zone"
			;;

		allow)
			# 为允许的国家创建 ipset（如果不存在）
			if ! ipset list "$ipset_name" &> /dev/null; then
				ipset create "$ipset_name" hash:net
			fi

			# 下载 IP 区域文件
			if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
echo "Error: Failed to download the IP zone file of $country_code"
				exit 1
			fi

			# 删除现有的国家规则
			iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null
			iptables -D OUTPUT -m set --match-set "$ipset_name" dst -j DROP 2>/dev/null
			ipset flush "$ipset_name"

			# 将 IP 添加到 ipset
			while IFS= read -r ip; do
				ipset add "$ipset_name" "$ip"
			done < "${country_code,,}.zone"

			# 仅允许指定国家的 IP
			iptables -P INPUT DROP
			iptables -P OUTPUT DROP
			iptables -A INPUT -m set --match-set "$ipset_name" src -j ACCEPT
			iptables -A OUTPUT -m set --match-set "$ipset_name" dst -j ACCEPT

echo "Only the IP address of $country_code has been allowed successfully"
			rm "${country_code,,}.zone"
			;;

		unblock)
			# 删除国家的 iptables 规则
			iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null
			iptables -D OUTPUT -m set --match-set "$ipset_name" dst -j DROP 2>/dev/null

			# 销毁 ipset
			if ipset list "$ipset_name" &> /dev/null; then
				ipset destroy "$ipset_name"
			fi

echo "The IP address restriction of $country_code has been successfully lifted"
			;;

		*)
			;;
	esac
}




iptables_panel() {
  root_use
  install iptables
  save_iptables_rules
  while true; do
		  clear
echo "Advanced Firewall Management"
		  send_stats "高级防火墙管理"
		  echo "------------------------"
		  iptables -L INPUT
		  echo ""
echo "Firewall Management"
		  echo "------------------------"
echo "1. Open the specified port 2. Close the specified port"
echo "3. Open all ports 4. Close all ports"
		  echo "------------------------"
echo "5. IP whitelist 6. IP blacklist"
echo "7. Clear the specified IP"
		  echo "------------------------"
echo "11. Allow PING 12. Disable PING"
		  echo "------------------------"
echo "13. Start DDOS Defense 14. Turn off DDOS Defense"
		  echo "------------------------"
echo "15. Block specified country IP 16. Only specified country IPs are allowed"
echo "17. Release the IP restrictions of designated countries"
		  echo "------------------------"
echo "0. Return to previous menu"
		  echo "------------------------"
		  read -e -p "请输入你的选择: " sub_choice
		  case $sub_choice in
			  1)
				  read -e -p "请输入开放的端口号: " o_port
				  open_port $o_port
				  send_stats "开放指定端口"
				  ;;
			  2)
				  read -e -p "请输入关闭的端口号: " c_port
				  close_port $c_port
				  send_stats "关闭指定端口"
				  ;;
			  3)
				  # 开放所有端口
				  current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')
				  iptables -F
				  iptables -X
				  iptables -P INPUT ACCEPT
				  iptables -P FORWARD ACCEPT
				  iptables -P OUTPUT ACCEPT
				  iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
				  iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
				  iptables -A INPUT -i lo -j ACCEPT
				  iptables -A FORWARD -i lo -j ACCEPT
				  iptables -A INPUT -p tcp --dport $current_port -j ACCEPT
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "开放所有端口"
				  ;;
			  4)
				  # 关闭所有端口
				  current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')
				  iptables -F
				  iptables -X
				  iptables -P INPUT DROP
				  iptables -P FORWARD DROP
				  iptables -P OUTPUT ACCEPT
				  iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
				  iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
				  iptables -A INPUT -i lo -j ACCEPT
				  iptables -A FORWARD -i lo -j ACCEPT
				  iptables -A INPUT -p tcp --dport $current_port -j ACCEPT
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "关闭所有端口"
				  ;;

			  5)
				  # IP 白名单
				  read -e -p "请输入放行的IP或IP段: " o_ip
				  allow_ip $o_ip
				  ;;
			  6)
				  # IP 黑名单
				  read -e -p "请输入封锁的IP或IP段: " c_ip
				  block_ip $c_ip
				  ;;
			  7)
				  # 清除指定 IP
				  read -e -p "请输入清除的IP: " d_ip
				  iptables -D INPUT -s $d_ip -j ACCEPT 2>/dev/null
				  iptables -D INPUT -s $d_ip -j DROP 2>/dev/null
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "清除指定IP"
				  ;;
			  11)
				  # 允许 PING
				  iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
				  iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "允许PING"
				  ;;
			  12)
				  # 禁用 PING
				  iptables -D INPUT -p icmp --icmp-type echo-request -j ACCEPT 2>/dev/null
				  iptables -D OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT 2>/dev/null
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "禁用PING"
				  ;;
			  13)
				  enable_ddos_defense
				  ;;
			  14)
				  disable_ddos_defense
				  ;;

			  15)
				  read -e -p "请输入阻止的国家代码（如 CN, US, JP）: " country_code
				  manage_country_rules block $country_code
				  send_stats "允许国家 $country_code 的IP"
				  ;;
			  16)
				  read -e -p "请输入允许的国家代码（如 CN, US, JP）: " country_code
				  manage_country_rules allow $country_code
				  send_stats "阻止国家 $country_code 的IP"
				  ;;

			  17)
				  read -e -p "请输入清除的国家代码（如 CN, US, JP）: " country_code
				  manage_country_rules unblock $country_code
				  send_stats "清除国家 $country_code 的IP"
				  ;;

			  *)
				  break  # 跳出循环，退出菜单
				  ;;
		  esac
  done

}








add_swap() {
	local new_swap=$1  # 获取传入的参数

	# 获取当前系统中所有的 swap 分区
	local swap_partitions=$(grep -E '^/dev/' /proc/swaps | awk '{print $1}')

	# 遍历并删除所有的 swap 分区
	for partition in $swap_partitions; do
		swapoff "$partition"
		wipefs -a "$partition"
		mkswap -f "$partition"
	done

	# 确保 /swapfile 不再被使用
	swapoff /swapfile

	# 删除旧的 /swapfile
	rm -f /swapfile

	# 创建新的 swap 分区
	fallocate -l ${new_swap}M /swapfile
	chmod 600 /swapfile
	mkswap /swapfile
	swapon /swapfile

	sed -i '/\/swapfile/d' /etc/fstab
	echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

	if [ -f /etc/alpine-release ]; then
		echo "nohup swapon /swapfile" > /etc/local.d/swap.start
		chmod +x /etc/local.d/swap.start
		rc-update add local
	fi

echo -e "The virtual memory size has been resized to ${gl_huang}${new_swap}${gl_bai}M"
}




check_swap() {

local swap_total=$(free -m | awk 'NR==3{print $2}')

# 判断是否需要创建虚拟内存
[ "$swap_total" -gt 0 ] || add_swap 1024


}









ldnmp_v() {

	  # 获取nginx版本
	  local nginx_version=$(docker exec nginx nginx -v 2>&1)
	  local nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
	  echo -n -e "nginx : ${gl_huang}v$nginx_version${gl_bai}"

	  # 获取mysql版本
	  local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	  local mysql_version=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SELECT VERSION();" 2>/dev/null | tail -n 1)
	  echo -n -e "            mysql : ${gl_huang}v$mysql_version${gl_bai}"

	  # 获取php版本
	  local php_version=$(docker exec php php -v 2>/dev/null | grep -oP "PHP \K[0-9]+\.[0-9]+\.[0-9]+")
	  echo -n -e "            php : ${gl_huang}v$php_version${gl_bai}"

	  # 获取redis版本
	  local redis_version=$(docker exec redis redis-server -v 2>&1 | grep -oP "v=+\K[0-9]+\.[0-9]+")
	  echo -e "            redis : ${gl_huang}v$redis_version${gl_bai}"

	  echo "------------------------"
	  echo ""

}



install_ldnmp_conf() {

  # 创建必要的目录和文件
  cd /home && mkdir -p web/html web/mysql web/certs web/conf.d web/redis web/log/nginx && touch web/docker-compose.yml
  wget -O /home/web/nginx.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf
  wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default10.conf

  default_server_ssl

  # 下载 docker-compose.yml 文件并进行替换
  wget -O /home/web/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/LNMP-docker-compose-10.yml
  dbrootpasswd=$(openssl rand -base64 16) ; dbuse=$(openssl rand -hex 4) ; dbusepasswd=$(openssl rand -base64 8)

  # 在 docker-compose.yml 文件中进行替换
  sed -i "s#webroot#$dbrootpasswd#g" /home/web/docker-compose.yml
  sed -i "s#kejilionYYDS#$dbusepasswd#g" /home/web/docker-compose.yml
  sed -i "s#kejilion#$dbuse#g" /home/web/docker-compose.yml

}





install_ldnmp() {

	  check_swap

	  cp /home/web/docker-compose.yml /home/web/docker-compose1.yml

	  if ! grep -q "healthcheck" /home/web/docker-compose.yml; then
		wget -O /home/web/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/LNMP-docker-compose-10.yml
	  	dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose1.yml | tr -d '[:space:]')
	  	dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose1.yml | tr -d '[:space:]')
	  	dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose1.yml | tr -d '[:space:]')

  		sed -i "s#webroot#$dbrootpasswd#g" /home/web/docker-compose.yml
  		sed -i "s#kejilionYYDS#$dbusepasswd#g" /home/web/docker-compose.yml
  		sed -i "s#kejilion#$dbuse#g" /home/web/docker-compose.yml
	  fi

	  if grep -q "kjlion/nginx:alpine" /home/web/docker-compose1.yml; then
	  	sed -i 's|kjlion/nginx:alpine|nginx:alpine|g' /home/web/docker-compose.yml  > /dev/null 2>&1
		sed -i 's|nginx:alpine|kjlion/nginx:alpine|g' /home/web/docker-compose.yml  > /dev/null 2>&1
	  fi

	  cd /home/web && docker compose up -d
	  sleep 1
  	  crontab -l 2>/dev/null | grep -v 'logrotate' | crontab -
  	  (crontab -l 2>/dev/null; echo '0 2 * * * docker exec nginx apk add logrotate && docker exec nginx logrotate -f /etc/logrotate.conf') | crontab -
	  restart_ldnmp

	  clear
echo "LDNMP environment installation is completed"
	  echo "------------------------"
	  ldnmp_v

}


install_certbot() {

	cd ~
	curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/auto_cert_renewal.sh
	chmod +x auto_cert_renewal.sh

	check_crontab_installed
	local cron_job="0 0 * * * ~/auto_cert_renewal.sh"
	crontab -l 2>/dev/null | grep -vF "$cron_job" | crontab -
	(crontab -l 2>/dev/null; echo "$cron_job") | crontab -
echo "Renewal Task Updated"
}


install_ssltls() {
	  docker stop nginx > /dev/null 2>&1
	  check_port > /dev/null 2>&1
	  cd ~

	  local file_path="/etc/letsencrypt/live/$yuming/fullchain.pem"
	  if [ ! -f "$file_path" ]; then
		 	local ipv4_pattern='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
	  		local ipv6_pattern='^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))))$'
			if [[ ($yuming =~ $ipv4_pattern || $yuming =~ $ipv6_pattern) ]]; then
				mkdir -p /etc/letsencrypt/live/$yuming/
				if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
					openssl req -x509 -nodes -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -keyout /etc/letsencrypt/live/$yuming/privkey.pem -out /etc/letsencrypt/live/$yuming/fullchain.pem -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
				else
					openssl genpkey -algorithm Ed25519 -out /etc/letsencrypt/live/$yuming/privkey.pem
					openssl req -x509 -key /etc/letsencrypt/live/$yuming/privkey.pem -out /etc/letsencrypt/live/$yuming/fullchain.pem -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
				fi
			else
				docker run -it --rm -p 80:80 -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot certonly --standalone -d "$yuming" --email your@email.com --agree-tos --no-eff-email --force-renewal --key-type ecdsa
			fi
	  fi

	  cp /etc/letsencrypt/live/$yuming/fullchain.pem /home/web/certs/${yuming}_cert.pem > /dev/null 2>&1
	  cp /etc/letsencrypt/live/$yuming/privkey.pem /home/web/certs/${yuming}_key.pem > /dev/null 2>&1

	  docker start nginx > /dev/null 2>&1
}



install_ssltls_text() {
echo -e "${gl_huang}$yuming Public key information${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/fullchain.pem
	echo ""
echo -e "${gl_huang}$yuming Private key information${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/privkey.pem
	echo ""
echo -e "${gl_huang} certificate storage path ${gl_bai}"
echo "Public key: /etc/letsencrypt/live/$yuming/fullchain.pem"
echo "Private Key: /etc/letsencrypt/live/$yuming/privkey.pem"
	echo ""
}





add_ssl() {

yuming="${1:-}"
if [ -z "$yuming" ]; then
	add_yuming
fi
install_docker
install_certbot
docker run -it --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
install_ssltls
certs_status
install_ssltls_text
ssl_ps
}


ssl_ps() {
echo -e "${gl_huang}Applied certificate expiration ${gl_bai}"
echo "Site Information Certificate Expiration Time"
	echo "------------------------"
	for cert_dir in /etc/letsencrypt/live/*; do
	  local cert_file="$cert_dir/fullchain.pem"
	  if [ -f "$cert_file" ]; then
		local domain=$(basename "$cert_dir")
		local expire_date=$(openssl x509 -noout -enddate -in "$cert_file" | awk -F'=' '{print $2}')
		local formatted_date=$(date -d "$expire_date" '+%Y-%m-%d')
		printf "%-30s%s\n" "$domain" "$formatted_date"
	  fi
	done
	echo ""
}




default_server_ssl() {
install openssl

if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
	openssl req -x509 -nodes -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -keyout /home/web/certs/default_server.key -out /home/web/certs/default_server.crt -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
else
	openssl genpkey -algorithm Ed25519 -out /home/web/certs/default_server.key
	openssl req -x509 -key /home/web/certs/default_server.key -out /home/web/certs/default_server.crt -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
fi

openssl rand -out /home/web/certs/ticket12.key 48
openssl rand -out /home/web/certs/ticket13.key 80

}


certs_status() {

	sleep 1

	local file_path="/etc/letsencrypt/live/$yuming/fullchain.pem"
	if [ -f "$file_path" ]; then
		send_stats "域名证书申请成功"
	else
		send_stats "域名证书申请失败"
echo -e "${gl_hong}Note: The application for ${gl_bai} certificate failed. Please check the following possible reasons and try again:"
echo -e "1. Domain name spelling error ➠ Please check whether the domain name is entered correctly"
echo -e "2. DNS resolution problem ➠ Confirm that the domain name has been correctly resolved to this server IP"
echo -e "3. Network configuration issues ➠ If you use Cloudflare Warp and other virtual networks, please temporarily shut down"
echo -e "4. Firewall Limitations ➠ Check whether port 80/443 is open to ensure verification is accessible"
echo -e "5. The number of applications exceeds the limit ➠ Let's Encrypt has a weekly limit (5 times/domain/week)"
		break_end
		clear
echo "Please try deploying $webname again"
		add_yuming
		install_ssltls
		certs_status
	fi

}


repeat_add_yuming() {
if [ -e /home/web/conf.d/$yuming.conf ]; then
  send_stats "域名重复使用"
  web_del "${yuming}" > /dev/null 2>&1
fi

}


add_yuming() {
	  ip_address
echo -e "First resolve the domain name to the native IP: ${gl_huang}$ipv4_address $ipv6_address${gl_bai}"
	  read -e -p "请输入你的IP或者解析过的域名: " yuming
}


add_db() {
	  dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
	  dbname="${dbname}"

	  dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	  dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	  dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	  docker exec mysql mysql -u root -p"$dbrootpasswd" -e "CREATE DATABASE $dbname; GRANT ALL PRIVILEGES ON $dbname.* TO \"$dbuse\"@\"%\";"
}

reverse_proxy() {
	  ip_address
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  sed -i "s/0.0.0.0/$ipv4_address/g" /home/web/conf.d/$yuming.conf
	  sed -i "s|0000|$duankou|g" /home/web/conf.d/$yuming.conf
	  nginx_http_on
	  docker exec nginx nginx -s reload
}


restart_redis() {
  docker exec redis redis-cli FLUSHALL > /dev/null 2>&1
  docker exec -it redis redis-cli CONFIG SET maxmemory 512mb > /dev/null 2>&1
  docker exec -it redis redis-cli CONFIG SET maxmemory-policy allkeys-lru > /dev/null 2>&1
  docker exec -it redis redis-cli CONFIG SET save "" > /dev/null 2>&1
  docker exec -it redis redis-cli CONFIG SET appendonly no > /dev/null 2>&1
}



restart_ldnmp() {
	  restart_redis
	  docker exec nginx chown -R nginx:nginx /var/www/html > /dev/null 2>&1
	  docker exec nginx mkdir -p /var/cache/nginx/proxy > /dev/null 2>&1
	  docker exec nginx mkdir -p /var/cache/nginx/fastcgi > /dev/null 2>&1
	  docker exec nginx chown -R nginx:nginx /var/cache/nginx/proxy > /dev/null 2>&1
	  docker exec nginx chown -R nginx:nginx /var/cache/nginx/fastcgi > /dev/null 2>&1
	  docker exec php chown -R www-data:www-data /var/www/html > /dev/null 2>&1
	  docker exec php74 chown -R www-data:www-data /var/www/html > /dev/null 2>&1
	  cd /home/web && docker compose restart nginx php php74

}

nginx_upgrade() {

  local ldnmp_pods="nginx"
  cd /home/web/
  docker rm -f $ldnmp_pods > /dev/null 2>&1
  docker images --filter=reference="kjlion/${ldnmp_pods}*" -q | xargs docker rmi > /dev/null 2>&1
  docker images --filter=reference="${ldnmp_pods}*" -q | xargs docker rmi > /dev/null 2>&1
  docker compose up -d --force-recreate $ldnmp_pods
  crontab -l 2>/dev/null | grep -v 'logrotate' | crontab -
  (crontab -l 2>/dev/null; echo '0 2 * * * docker exec nginx apk add logrotate && docker exec nginx logrotate -f /etc/logrotate.conf') | crontab -
  docker exec nginx chown -R nginx:nginx /var/www/html
  docker exec nginx mkdir -p /var/cache/nginx/proxy
  docker exec nginx mkdir -p /var/cache/nginx/fastcgi
  docker exec nginx chown -R nginx:nginx /var/cache/nginx/proxy
  docker exec nginx chown -R nginx:nginx /var/cache/nginx/fastcgi
  docker restart $ldnmp_pods > /dev/null 2>&1

  send_stats "更新$ldnmp_pods"
echo "Update ${ldnmp_pods} completed"

}

phpmyadmin_upgrade() {
  local ldnmp_pods="phpmyadmin"
  local local docker_port=8877
  local dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
  local dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

  cd /home/web/
  docker rm -f $ldnmp_pods > /dev/null 2>&1
  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
  curl -sS -O https://raw.githubusercontent.com/kejilion/docker/refs/heads/main/docker-compose.phpmyadmin.yml
  docker compose -f docker-compose.phpmyadmin.yml up -d
  clear
  ip_address

  check_docker_app_ip
echo "Login information: "
echo "Username: $dbuse"
echo "Password: $dbusepasswd"
  echo
  send_stats "启动$ldnmp_pods"
}


cf_purge_cache() {
  local CONFIG_FILE="/home/web/config/cf-purge-cache.txt"
  local API_TOKEN
  local EMAIL
  local ZONE_IDS

  # 检查配置文件是否存在
  if [ -f "$CONFIG_FILE" ]; then
	# 从配置文件读取 API_TOKEN 和 zone_id
	read API_TOKEN EMAIL ZONE_IDS < "$CONFIG_FILE"
	# 将 ZONE_IDS 转换为数组
	ZONE_IDS=($ZONE_IDS)
  else
	# 提示用户是否清理缓存
	read -e -p "需要清理 Cloudflare 的缓存吗？（y/n）: " answer
	if [[ "$answer" == "y" ]]; then
echo "CF information is saved in $CONFIG_FILE, and the CF information can be modified later"
	  read -e -p "请输入你的 API_TOKEN: " API_TOKEN
	  read -e -p "请输入你的CF用户名: " EMAIL
	  read -e -p "请输入 zone_id（多个用空格分隔）: " -a ZONE_IDS

	  mkdir -p /home/web/config/
	  echo "$API_TOKEN $EMAIL ${ZONE_IDS[*]}" > "$CONFIG_FILE"
	fi
  fi

  # 循环遍历每个 zone_id 并执行清除缓存命令
  for ZONE_ID in "${ZONE_IDS[@]}"; do
echo "Clearing cache for zone_id: $ZONE_ID"
	curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
	-H "X-Auth-Email: $EMAIL" \
	-H "X-Auth-Key: $API_TOKEN" \
	-H "Content-Type: application/json" \
	--data '{"purge_everything":true}'
  done

echo "The cache clear request has been sent."
}



web_cache() {
  send_stats "清理站点缓存"
  # docker exec -it nginx rm -rf /var/cache/nginx
  cf_purge_cache
  docker exec php php -r 'opcache_reset();'
  docker exec php74 php -r 'opcache_reset();'
  docker exec nginx nginx -s stop
  docker exec nginx rm -rf /var/cache/nginx/*
  docker exec nginx nginx
  docker restart php php74 redis
  restart_redis
}



web_del() {

	send_stats "删除站点数据"
	yuming_list="${1:-}"
	if [ -z "$yuming_list" ]; then
		read -e -p "删除站点数据，请输入你的域名（多个域名用空格隔开）: " yuming_list
		if [[ -z "$yuming_list" ]]; then
			return
		fi
	fi

	for yuming in $yuming_list; do
echo "Deleting domain name: $yuming"
		rm -r /home/web/html/$yuming > /dev/null 2>&1
		rm /home/web/conf.d/$yuming.conf > /dev/null 2>&1
		rm /home/web/certs/${yuming}_key.pem > /dev/null 2>&1
		rm /home/web/certs/${yuming}_cert.pem > /dev/null 2>&1

		# 将域名转换为数据库名
		dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
		dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

		# 删除数据库前检查是否存在，避免报错
echo "Deleting database: $dbname"
		docker exec mysql mysql -u root -p"$dbrootpasswd" -e "DROP DATABASE ${dbname};" > /dev/null 2>&1
	done

	docker exec nginx nginx -s reload

}


nginx_waf() {
	local mode=$1

	if ! grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		wget -O /home/web/nginx.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf"
	fi

	# 根据 mode 参数来决定开启或关闭 WAF
	if [ "$mode" == "on" ]; then
		# 开启 WAF：去掉注释
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity on;|\1modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	elif [ "$mode" == "off" ]; then
		# 关闭 WAF：加上注释
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity on;|\1# modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	else
echo "Invalid parameter: use 'on' or 'off'"
		return 1
	fi

	# 检查 nginx 镜像并根据情况处理
	if grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		docker exec nginx nginx -s reload
	else
		sed -i 's|nginx:alpine|kjlion/nginx:alpine|g' /home/web/docker-compose.yml
		nginx_upgrade
	fi

}

check_waf_status() {
	if grep -q "^\s*#\s*modsecurity on;" /home/web/nginx.conf; then
		waf_status=""
	elif grep -q "modsecurity on;" /home/web/nginx.conf; then
		waf_status=" WAF已开启"
	else
		waf_status=""
	fi
}


check_cf_mode() {
	if [ -f "/path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf" ]; then
		CFmessage=" cf模式已开启"
	else
		CFmessage=""
	fi
}


nginx_http_on() {

local ipv4_pattern='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
local ipv6_pattern='^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))))$'
if [[ ($yuming =~ $ipv4_pattern || $yuming =~ $ipv6_pattern) ]]; then
	sed -i '/if (\$scheme = http) {/,/}/s/^/#/' /home/web/conf.d/${yuming}.conf
fi

}




















check_docker_app() {

if docker inspect "$docker_name" &>/dev/null; then
	check_docker="${gl_lv}已安装${gl_bai}"
else
	check_docker="${gl_hui}未安装${gl_bai}"
fi

}


check_docker_app_ip() {
echo "------------------------"
echo "Access Address:"
ip_address
if [ -n "$ipv4_address" ]; then
	echo "http://$ipv4_address:$docker_port"
fi

if [ -n "$ipv6_address" ]; then
	echo "http://[$ipv6_address]:$docker_port"
fi

local search_pattern="$ipv4_address:$docker_port"

for file in /home/web/conf.d/*; do
	if [ -f "$file" ]; then
		if grep -q "$search_pattern" "$file" 2>/dev/null; then
			echo "https://$(basename "$file" | sed 's/\.conf$//')"
		fi
	fi
done

}


check_docker_image_update() {

	local container_name=$1

	local country=$(curl -s ipinfo.io/country)
	if [[ "$country" == "CN" ]]; then
		update_status=""
		return
	fi

	# 获取容器的创建时间和镜像名称
	local container_info=$(docker inspect --format='{{.Created}},{{.Config.Image}}' "$container_name" 2>/dev/null)
	local container_created=$(echo "$container_info" | cut -d',' -f1)
	local image_name=$(echo "$container_info" | cut -d',' -f2)

	# 提取镜像仓库和标签
	local image_repo=${image_name%%:*}
	local image_tag=${image_name##*:}

	# 默认标签为 latest
	[[ "$image_repo" == "$image_tag" ]] && image_tag="latest"

	# 添加对官方镜像的支持
	[[ "$image_repo" != */* ]] && image_repo="library/$image_repo"

	# 从 Docker Hub API 获取镜像发布时间
	local hub_info=$(curl -s "https://hub.docker.com/v2/repositories/$image_repo/tags/$image_tag")
	local last_updated=$(echo "$hub_info" | jq -r '.last_updated' 2>/dev/null)

	# 验证获取的时间
	if [[ -n "$last_updated" && "$last_updated" != "null" ]]; then
		local container_created_ts=$(date -d "$container_created" +%s 2>/dev/null)
		local last_updated_ts=$(date -d "$last_updated" +%s 2>/dev/null)

		# 比较时间戳
		if [[ $container_created_ts -lt $last_updated_ts ]]; then
			update_status="${gl_huang}发现新版本!${gl_bai}"
		else
			update_status=""
		fi
	else
		update_status=""
	fi

}




block_container_port() {
	local container_name_or_id=$1
	local allowed_ip=$2

	# 获取容器的 IP 地址
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
echo "Error: Unable to get the IP address of container $container_name_or_id. Please check if the container name or ID is correct."
		return 1
	fi

	install iptables


	# 检查并封禁其他所有 IP
	if ! iptables -C DOCKER-USER -p tcp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -d "$container_ip" -j DROP
	fi

	# 检查并放行指定 IP
	if ! iptables -C DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# 检查并放行本地网络 127.0.0.0/8
	if ! iptables -C DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi



	# 检查并封禁其他所有 IP
	if ! iptables -C DOCKER-USER -p udp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -I DOCKER-USER -p udp -d "$container_ip" -j DROP
	fi

	# 检查并放行指定 IP
	if ! iptables -C DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# 检查并放行本地网络 127.0.0.0/8
	if ! iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi

	if ! iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT
	fi


echo "IP+ ports are blocked from accessing this service"
	save_iptables_rules
}




clear_container_rules() {
	local container_name_or_id=$1
	local allowed_ip=$2

	# 获取容器的 IP 地址
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
echo "Error: Unable to get the IP address of container $container_name_or_id. Please check if the container name or ID is correct."
		return 1
	fi

	install iptables


	# 清除封禁其他所有 IP 的规则
	if iptables -C DOCKER-USER -p tcp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -d "$container_ip" -j DROP
	fi

	# 清除放行指定 IP 的规则
	if iptables -C DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# 清除放行本地网络 127.0.0.0/8 的规则
	if iptables -C DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi





	# 清除封禁其他所有 IP 的规则
	if iptables -C DOCKER-USER -p udp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -D DOCKER-USER -p udp -d "$container_ip" -j DROP
	fi

	# 清除放行指定 IP 的规则
	if iptables -C DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# 清除放行本地网络 127.0.0.0/8 的规则
	if iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi


	if iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT
	fi


echo "IP+ports are allowed to access the service"
	save_iptables_rules
}






block_host_port() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
echo "Error: Please provide the port number and the IP that is allowed to access."
echo "Usage: block_host_port <port number> <authorized IP>"
		return 1
	fi

	install iptables


	# 拒绝其他所有 IP 访问
	if ! iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -j DROP
	fi

	# 允许指定 IP 访问
	if ! iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# 允许本机访问
	if ! iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi





	# 拒绝其他所有 IP 访问
	if ! iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -j DROP
	fi

	# 允许指定 IP 访问
	if ! iptables -C INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# 允许本机访问
	if ! iptables -C INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 允许已建立和相关连接的流量
	if ! iptables -C INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT &>/dev/null; then
		iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	fi

echo "IP+ ports are blocked from accessing this service"
	save_iptables_rules
}




clear_host_port_rules() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
echo "Error: Please provide the port number and the IP that is allowed to access."
echo "Usage: clear_host_port_rules <port number> <authorized IP>"
		return 1
	fi

	install iptables


	# 清除封禁所有其他 IP 访问的规则
	if iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -j DROP
	fi

	# 清除允许本机访问的规则
	if iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 清除允许指定 IP 访问的规则
	if iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi


	# 清除封禁所有其他 IP 访问的规则
	if iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -j DROP
	fi

	# 清除允许本机访问的规则
	if iptables -C INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 清除允许指定 IP 访问的规则
	if iptables -C INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi


echo "IP+ports are allowed to access the service"
	save_iptables_rules

}





docker_app() {
send_stats "${docker_name}管理"

while true; do
	clear
	check_docker_app
	check_docker_image_update $docker_name
	echo -e "$docker_name $check_docker $update_status"
	echo "$docker_describe"
	echo "$docker_url"
	if docker inspect "$docker_name" &>/dev/null; then
		check_docker_app_ip
	fi
	echo ""
	echo "------------------------"
echo "1. Install 2. Update 3. Uninstall"
	echo "------------------------"
echo "5. Add domain name access 6. Delete domain name access"
echo "7. Allow IP+port access 8. Block IP+port access"
	echo "------------------------"
echo "0. Return to previous menu"
	echo "------------------------"
	read -e -p "请输入你的选择: " choice
	 case $choice in
		1)
			check_disk_space $app_size
			install jq
			install_docker
			$docker_rum
			clear
echo "$docker_name has been installed"
			check_docker_app_ip
			echo ""
			$docker_use
			$docker_passwd
			send_stats "安装$docker_name"
			;;
		2)
			docker rm -f "$docker_name"
			docker rmi -f "$docker_img"
			$docker_rum
			clear
echo "$docker_name has been installed"
			check_docker_app_ip
			echo ""
			$docker_use
			$docker_passwd
			send_stats "更新$docker_name"
			;;
		3)
			docker rm -f "$docker_name"
			docker rmi -f "$docker_img"
			rm -rf "/home/docker/$docker_name"
echo "App uninstalled"
			send_stats "卸载$docker_name"
			;;

		5)
echo "${docker_name}Domain Access Settings"
			send_stats "${docker_name}域名访问设置"
			add_yuming
			ldnmp_Proxy ${yuming} ${ipv4_address} ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"
			;;

		6)
echo "Domain name format example.com does not come with https://"
			web_del
			;;

		7)
			send_stats "允许IP访问 ${docker_name}"
			clear_container_rules "$docker_name" "$ipv4_address"
			;;

		8)
			send_stats "阻止IP访问 ${docker_name}"
			block_container_port "$docker_name" "$ipv4_address"
			;;

		*)
			break
			;;
	 esac
	 break_end
done

}






docker_app_plus() {
	send_stats "$app_name"
	while true; do
		clear
		check_docker_app
		check_docker_image_update $docker_name
		echo -e "$app_name $check_docker $update_status"
		echo "$app_text"
		echo "$app_url"
		if docker inspect "$docker_name" &>/dev/null; then
			check_docker_app_ip
		fi
		echo ""
		echo "------------------------"
echo "1. Install 2. Update 3. Uninstall"
		echo "------------------------"
echo "5. Add domain name access 6. Delete domain name access"
echo "7. Allow IP+port access 8. Block IP+port access"
		echo "------------------------"
echo "0. Return to previous menu"
		echo "------------------------"
		read -e -p "输入你的选择: " choice
		case $choice in
			1)
				check_disk_space $app_size
				install jq
				install_docker
				docker_app_install
				;;
			2)
				docker_app_update
				;;
			3)
				docker_app_uninstall
				;;
			5)
echo "${docker_name}Domain Access Settings"
				send_stats "${docker_name}域名访问设置"
				add_yuming
				ldnmp_Proxy ${yuming} ${ipv4_address} ${docker_port}
				block_container_port "$docker_name" "$ipv4_address"
				;;
			6)
echo "Domain name format example.com does not come with https://"
				web_del
				;;
			7)
				send_stats "允许IP访问 ${docker_name}"
				clear_container_rules "$docker_name" "$ipv4_address"
				;;
			8)
				send_stats "阻止IP访问 ${docker_name}"
				block_container_port "$docker_name" "$ipv4_address"
				;;
			*)
				break
				;;
		esac
		break_end
	done
}





prometheus_install() {

local PROMETHEUS_DIR="/home/docker/monitoring/prometheus"
local GRAFANA_DIR="/home/docker/monitoring/grafana"
local NETWORK_NAME="monitoring"

# Create necessary directories
mkdir -p $PROMETHEUS_DIR
mkdir -p $GRAFANA_DIR

# Set correct ownership for Grafana directory
chown -R 472:472 $GRAFANA_DIR

if [ ! -f "$PROMETHEUS_DIR/prometheus.yml" ]; then
	curl -o "$PROMETHEUS_DIR/prometheus.yml" ${gh_proxy}raw.githubusercontent.com/kejilion/config/refs/heads/main/prometheus/prometheus.yml
fi

# Create Docker network for monitoring
docker network create $NETWORK_NAME

# Run Node Exporter container
docker run -d \
  --name=node-exporter \
  --network $NETWORK_NAME \
  --restart unless-stopped \
  prom/node-exporter

# Run Prometheus container
docker run -d \
  --name prometheus \
  -v $PROMETHEUS_DIR/prometheus.yml:/etc/prometheus/prometheus.yml \
  -v $PROMETHEUS_DIR/data:/prometheus \
  --network $NETWORK_NAME \
  --restart unless-stopped \
  --user 0:0 \
  prom/prometheus:latest

# Run Grafana container
docker run -d \
  --name grafana \
  -p 8047:3000 \
  -v $GRAFANA_DIR:/var/lib/grafana \
  --network $NETWORK_NAME \
  --restart unless-stopped \
  grafana/grafana:latest

}




tmux_run() {
	# Check if the session already exists
	tmux has-session -t $SESSION_NAME 2>/dev/null
	# $? is a special variable that holds the exit status of the last executed command
	if [ $? != 0 ]; then
	  # Session doesn't exist, create a new one
	  tmux new -s $SESSION_NAME
	else
	  # Session exists, attach to it
	  tmux attach-session -t $SESSION_NAME
	fi
}


tmux_run_d() {

local base_name="tmuxd"
local tmuxd_ID=1

# 检查会话是否存在的函数
session_exists() {
  tmux has-session -t $1 2>/dev/null
}

# 循环直到找到一个不存在的会话名称
while session_exists "$base_name-$tmuxd_ID"; do
  local tmuxd_ID=$((tmuxd_ID + 1))
done

# 创建新的 tmux 会话
tmux new -d -s "$base_name-$tmuxd_ID" "$tmuxd"


}



f2b_status() {
	 docker exec -it fail2ban fail2ban-client reload
	 sleep 3
	 docker exec -it fail2ban fail2ban-client status
}

f2b_status_xxx() {
	docker exec -it fail2ban fail2ban-client status $xxx
}

f2b_install_sshd() {

	docker run -d \
		--name=fail2ban \
		--net=host \
		--cap-add=NET_ADMIN \
		--cap-add=NET_RAW \
		-e PUID=1000 \
		-e PGID=1000 \
		-e TZ=Etc/UTC \
		-e VERBOSITY=-vv \
		-v /path/to/fail2ban/config:/config \
		-v /var/log:/var/log:ro \
		-v /home/web/log/nginx/:/remotelogs/nginx:ro \
		--restart unless-stopped \
		lscr.io/linuxserver/fail2ban:latest

	sleep 3
	if grep -q 'Alpine' /etc/issue; then
		cd /path/to/fail2ban/config/fail2ban/filter.d
		curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/alpine-sshd.conf
		curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/alpine-sshd-ddos.conf
		cd /path/to/fail2ban/config/fail2ban/jail.d/
		curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/alpine-ssh.conf
	elif command -v dnf &>/dev/null; then
		cd /path/to/fail2ban/config/fail2ban/jail.d/
		curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/centos-ssh.conf
	else
		install rsyslog
		systemctl start rsyslog
		systemctl enable rsyslog
		cd /path/to/fail2ban/config/fail2ban/jail.d/
		curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/linux-ssh.conf
	fi
}

f2b_sshd() {
	if grep -q 'Alpine' /etc/issue; then
		xxx=alpine-sshd
		f2b_status_xxx
	elif command -v dnf &>/dev/null; then
		xxx=centos-sshd
		f2b_status_xxx
	else
		xxx=linux-sshd
		f2b_status_xxx
	fi
}






server_reboot() {

	read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}现在重启服务器吗？(Y/N): ")" rboot
	case "$rboot" in
	  [Yy])
echo "Restarted"
		reboot
		;;
	  *)
echo "Canceled"
		;;
	esac


}

output_status() {
	output=$(awk 'BEGIN { rx_total = 0; tx_total = 0 }
		# 匹配常见的公网网卡命名: eth*, ens*, enp*, eno*
		$1 ~ /^(eth|ens|enp|eno)[0-9]+/ {
			rx_total += $2
			tx_total += $10
		}
		END {
			rx_units = "Bytes";
			tx_units = "Bytes";
			if (rx_total > 1024) { rx_total /= 1024; rx_units = "K"; }
			if (rx_total > 1024) { rx_total /= 1024; rx_units = "M"; }
			if (rx_total > 1024) { rx_total /= 1024; rx_units = "G"; }

			if (tx_total > 1024) { tx_total /= 1024; tx_units = "K"; }
			if (tx_total > 1024) { tx_total /= 1024; tx_units = "M"; }
			if (tx_total > 1024) { tx_total /= 1024; tx_units = "G"; }

			printf("总接收:       %.2f%s\n总发送:       %.2f%s\n", rx_total, rx_units, tx_total, tx_units);
		}' /proc/net/dev)
	# echo "$output"
}



ldnmp_install_status_one() {

   if docker inspect "php" &>/dev/null; then
	clear
	send_stats "无法再次安装LDNMP环境"
echo -e "${gl_huang} Tip: The ${gl_bai} website building environment is installed. No need to install again!"
	break_end
	linux_ldnmp
   fi

}


ldnmp_install_all() {
cd ~
send_stats "安装LDNMP环境"
root_use
clear
echo -e "${gl_huang}LDNMP environment is not installed, start installing the LDNMP environment...${gl_bai}"
check_disk_space 3
check_port
install_dependency
install_docker
install_certbot
install_ldnmp_conf
install_ldnmp

}


nginx_install_all() {
cd ~
send_stats "安装nginx环境"
root_use
clear
echo -e "${gl_huang}nginx is not installed, start installing nginx environment...${gl_bai}"
check_disk_space 1
check_port
install_dependency
install_docker
install_certbot
install_ldnmp_conf
nginx_upgrade
clear
local nginx_version=$(docker exec nginx nginx -v 2>&1)
local nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
echo "nginx installed complete"
echo -e "Current version: ${gl_huang}v$nginx_version${gl_bai}"
echo ""

}




ldnmp_install_status() {

	if ! docker inspect "php" &>/dev/null; then
		send_stats "请先安装LDNMP环境"
		ldnmp_install_all
	fi

}


nginx_install_status() {

	if ! docker inspect "nginx" &>/dev/null; then
		send_stats "请先安装nginx环境"
		nginx_install_all
	fi

}




ldnmp_web_on() {
	  clear
echo "Your $webname is built!"
	  echo "https://$yuming"
	  echo "------------------------"
echo "The $webname installation information is as follows: "

}

nginx_web_on() {
	  clear
echo "Your $webname is built!"
	  echo "https://$yuming"

}



ldnmp_wp() {
  clear
  # wordpress
  webname="WordPress"
  yuming="${1:-}"
  send_stats "安装$webname"
echo "Start deploy $webname"
  if [ -z "$yuming" ]; then
	add_yuming
  fi
  repeat_add_yuming
  ldnmp_install_status
  install_ssltls
  certs_status
  add_db
  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/wordpress.com.conf
  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
  nginx_http_on

  cd /home/web/html
  mkdir $yuming
  cd $yuming
  wget -O latest.zip ${gh_proxy}github.com/kejilion/Website_source_code/raw/refs/heads/main/wp-latest.zip
  # wget -O latest.zip https://cn.wordpress.org/latest-zh_CN.zip
  # wget -O latest.zip https://wordpress.org/latest.zip
  unzip latest.zip
  rm latest.zip
  echo "define('FS_METHOD', 'direct'); define('WP_REDIS_HOST', 'redis'); define('WP_REDIS_PORT', '6379');" >> /home/web/html/$yuming/wordpress/wp-config-sample.php
  sed -i "s|database_name_here|$dbname|g" /home/web/html/$yuming/wordpress/wp-config-sample.php
  sed -i "s|username_here|$dbuse|g" /home/web/html/$yuming/wordpress/wp-config-sample.php
  sed -i "s|password_here|$dbusepasswd|g" /home/web/html/$yuming/wordpress/wp-config-sample.php
  sed -i "s|localhost|mysql|g" /home/web/html/$yuming/wordpress/wp-config-sample.php
  cp /home/web/html/$yuming/wordpress/wp-config-sample.php /home/web/html/$yuming/wordpress/wp-config.php

  restart_ldnmp
  nginx_web_on
#   echo "数据库名: $dbname"
#   echo "用户名: $dbuse"
#   echo "密码: $dbusepasswd"
#   echo "数据库地址: mysql"
#   echo "表前缀: wp_"

}


ldnmp_Proxy() {
	clear
	webname="反向代理-IP+端口"
	yuming="${1:-}"
	reverseproxy="${2:-}"
	port="${3:-}"

	send_stats "安装$webname"
echo "Start deploy $webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi
	if [ -z "$reverseproxy" ]; then
		read -e -p "请输入你的反代IP: " reverseproxy
	fi

	if [ -z "$port" ]; then
		read -e -p "请输入你的反代端口: " port
	fi
	nginx_install_status
	install_ssltls
	certs_status
	wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy.conf
	sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	sed -i "s/0.0.0.0/$reverseproxy/g" /home/web/conf.d/$yuming.conf
	sed -i "s|0000|$port|g" /home/web/conf.d/$yuming.conf
	nginx_http_on
	docker exec nginx nginx -s reload
	nginx_web_on
}



ldnmp_web_status() {
	root_use
	while true; do
		local cert_count=$(ls /home/web/certs/*_cert.pem 2>/dev/null | wc -l)
		local output="站点: ${gl_lv}${cert_count}${gl_bai}"

		local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
		local db_count=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2> /dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys" | wc -l)
		local db_output="数据库: ${gl_lv}${db_count}${gl_bai}"

		clear
		send_stats "LDNMP站点管理"
echo "LDNMP environment"
		echo "------------------------"
		ldnmp_v

		# ls -t /home/web/conf.d | sed 's/\.[^.]*$//'
echo -e "${output} Certificate Expiration Time"
		echo -e "------------------------"
		for cert_file in /home/web/certs/*_cert.pem; do
		  local domain=$(basename "$cert_file" | sed 's/_cert.pem//')
		  if [ -n "$domain" ]; then
			local expire_date=$(openssl x509 -noout -enddate -in "$cert_file" | awk -F'=' '{print $2}')
			local formatted_date=$(date -d "$expire_date" '+%Y-%m-%d')
			printf "%-30s%s\n" "$domain" "$formatted_date"
		  fi
		done

		echo "------------------------"
		echo ""
		echo -e "${db_output}"
		echo -e "------------------------"
		local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
		docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2> /dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys"

		echo "------------------------"
		echo ""
echo "Site Directory"
		echo "------------------------"
echo -e "Data ${gl_hui}/home/web/html${gl_bai} Certificate ${gl_hui}/home/web/certs${gl_bai} Configuration ${gl_hui}/home/web/conf.d${gl_bai}"
		echo "------------------------"
		echo ""
echo "operate"
		echo "------------------------"
echo "1. Apply for/update the domain name certificate 2. Replace the site domain name"
echo "3. Clean up the site cache 4. Create an associated site"
echo "5. View access log 6. View error log"
echo "7. Edit Global Configuration 8. Edit Site Configuration"
echo "9. Manage Site Database 10. View Site Analysis Report"
		echo "------------------------"
echo "20. Delete the specified site data"
		echo "------------------------"
echo "0. Return to previous menu"
		echo "------------------------"
		read -e -p "请输入你的选择: " sub_choice
		case $sub_choice in
			1)
				send_stats "申请域名证书"
				read -e -p "请输入你的域名: " yuming
				install_certbot
				docker run -it --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
				install_ssltls
				certs_status

				;;

			2)
				send_stats "更换站点域名"
echo -e "${gl_hong} strongly recommends: ${gl_bai}Back up the entire site data first and then change the site domain name!"
				read -e -p "请输入旧域名: " oddyuming
				read -e -p "请输入新域名: " yuming
				install_certbot
				install_ssltls
				certs_status

				# mysql替换
				add_db

				local odd_dbname=$(echo "$oddyuming" | sed -e 's/[^A-Za-z0-9]/_/g')
				local odd_dbname="${odd_dbname}"

				docker exec mysql mysqldump -u root -p"$dbrootpasswd" $odd_dbname | docker exec -i mysql mysql -u root -p"$dbrootpasswd" $dbname
				docker exec mysql mysql -u root -p"$dbrootpasswd" -e "DROP DATABASE $odd_dbname;"


				local tables=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -D $dbname -e "SHOW TABLES;" | awk '{ if (NR>1) print $1 }')
				for table in $tables; do
					columns=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -D $dbname -e "SHOW COLUMNS FROM $table;" | awk '{ if (NR>1) print $1 }')
					for column in $columns; do
						docker exec mysql mysql -u root -p"$dbrootpasswd" -D $dbname -e "UPDATE $table SET $column = REPLACE($column, '$oddyuming', '$yuming') WHERE $column LIKE '%$oddyuming%';"
					done
				done

				# 网站目录替换
				mv /home/web/html/$oddyuming /home/web/html/$yuming

				find /home/web/html/$yuming -type f -exec sed -i "s/$odd_dbname/$dbname/g" {} +
				find /home/web/html/$yuming -type f -exec sed -i "s/$oddyuming/$yuming/g" {} +

				mv /home/web/conf.d/$oddyuming.conf /home/web/conf.d/$yuming.conf
				sed -i "s/$oddyuming/$yuming/g" /home/web/conf.d/$yuming.conf

				rm /home/web/certs/${oddyuming}_key.pem
				rm /home/web/certs/${oddyuming}_cert.pem

				docker exec nginx nginx -s reload

				;;


			3)
				web_cache
				;;
			4)
				send_stats "创建关联站点"
echo -e "Associate a new domain name for the existing site for access"
				read -e -p "请输入现有的域名: " oddyuming
				read -e -p "请输入新域名: " yuming
				install_certbot
				install_ssltls
				certs_status

				cp /home/web/conf.d/$oddyuming.conf /home/web/conf.d/$yuming.conf
				sed -i "s|server_name $oddyuming|server_name $yuming|g" /home/web/conf.d/$yuming.conf
				sed -i "s|/etc/nginx/certs/${oddyuming}_cert.pem|/etc/nginx/certs/${yuming}_cert.pem|g" /home/web/conf.d/$yuming.conf
				sed -i "s|/etc/nginx/certs/${oddyuming}_key.pem|/etc/nginx/certs/${yuming}_key.pem|g" /home/web/conf.d/$yuming.conf

				docker exec nginx nginx -s reload

				;;
			5)
				send_stats "查看访问日志"
				tail -n 200 /home/web/log/nginx/access.log
				break_end
				;;
			6)
				send_stats "查看错误日志"
				tail -n 200 /home/web/log/nginx/error.log
				break_end
				;;
			7)
				send_stats "编辑全局配置"
				install nano
				nano /home/web/nginx.conf
				docker exec nginx nginx -s reload
				;;

			8)
				send_stats "编辑站点配置"
				read -e -p "编辑站点配置，请输入你要编辑的域名: " yuming
				install nano
				nano /home/web/conf.d/$yuming.conf
				docker exec nginx nginx -s reload
				;;
			9)
				phpmyadmin_upgrade
				break_end
				;;
			10)
				send_stats "查看站点数据"
				install goaccess
				goaccess --log-format=COMBINED /home/web/log/nginx/access.log
				;;

			20)
echo "Domain name format example.com does not come with https://"
				web_del

				;;
			*)
				break  # 跳出循环，退出菜单
				;;
		esac
	done


}


check_panel_app() {
if $lujing ; then
	check_panel="${gl_lv}已安装${gl_bai}"
else
	check_panel=""
fi
}



install_panel() {
send_stats "${panelname}管理"
while true; do
	clear
	check_panel_app
	echo -e "$panelname $check_panel"
echo "${panelname} is a popular and powerful operation and maintenance management panel nowadays."
echo "Official website introduction: $panelurl"

	echo ""
	echo "------------------------"
echo "1. Install 2. Management 3. Uninstall"
	echo "------------------------"
echo "0. Return to previous menu"
	echo "------------------------"
	read -e -p "请输入你的选择: " choice
	 case $choice in
		1)
			check_disk_space 1
			install wget
			iptables_open
			panel_app_install
			send_stats "${panelname}安装"
			;;
		2)
			panel_app_manage
			send_stats "${panelname}控制"

			;;
		3)
			panel_app_uninstall
			send_stats "${panelname}卸载"
			;;
		*)
			break
			;;
	 esac
	 break_end
done

}



check_frp_app() {

if [ -d "/home/frp/" ]; then
	check_frp="${gl_lv}已安装${gl_bai}"
else
	check_frp="${gl_hui}未安装${gl_bai}"
fi

}



donlond_frp() {
	mkdir -p /home/frp/ && cd /home/frp/
	rm -rf /home/frp/frp_0.61.0_linux_amd64

	arch=$(uname -m)
	frp_v=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep -oP '"tag_name": "v\K.*?(?=")')

	if [[ "$arch" == "x86_64" ]]; then
		curl -L ${gh_proxy}github.com/fatedier/frp/releases/download/v${frp_v}/frp_${frp_v}_linux_amd64.tar.gz -o frp_${frp_v}_linux_amd64.tar.gz
	elif [[ "$arch" == "armv7l" || "$arch" == "aarch64" ]]; then
		curl -L ${gh_proxy}github.com/fatedier/frp/releases/download/v${frp_v}/frp_${frp_v}_linux_arm.tar.gz -o frp_${frp_v}_linux_amd64.tar.gz
	else
echo "The current CPU architecture is not supported: $arch"
	fi

	# 找到最新下载的 frp 文件
	latest_file=$(ls -t /home/frp/frp_*.tar.gz | head -n 1)

	# 解压该文件
	tar -zxvf "$latest_file"

	# 获取解压后文件夹的名字
	dir_name=$(tar -tzf "$latest_file" | head -n 1 | cut -f 1 -d '/')

	# 重命名解压后的文件夹为统一的版本名
	mv "$dir_name" "frp_0.61.0_linux_amd64"



}



generate_frps_config() {

	send_stats "安装frp服务端"
	# 生成随机端口和凭证
	local bind_port=8055
	local dashboard_port=8056
	local token=$(openssl rand -hex 16)
	local dashboard_user="user_$(openssl rand -hex 4)"
	local dashboard_pwd=$(openssl rand -hex 8)

	donlond_frp

	# 创建 frps.toml 文件
	cat <<EOF > /home/frp/frp_0.61.0_linux_amd64/frps.toml
[common]
bind_port = $bind_port
authentication_method = token
token = $token
dashboard_port = $dashboard_port
dashboard_user = $dashboard_user
dashboard_pwd = $dashboard_pwd
EOF

	# 输出生成的信息
	ip_address
	echo "------------------------"
echo "Parameters required for client deployment"
echo "Service IP: $ipv4_address"
	echo "token: $token"
	echo
echo "FRP Panel Information"
echo "FRP panel address: http://$ipv4_address:$dashboard_port"
echo "FRP panel username: $dashboard_user"
echo "FRP panel password: $dashboard_pwd"
	echo
	echo "------------------------"
	install tmux
	tmux kill-session -t frps >/dev/null 2>&1
	tmux new -d -s "frps" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frps -c frps.toml"
	check_crontab_installed
	crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
	(crontab -l ; echo '@reboot tmux new -d -s "frps" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frps -c frps.toml"') | crontab - > /dev/null 2>&1

	open_port 8055 8056

}



configure_frpc() {
	send_stats "安装frp客户端"
	read -e -p "请输入外网对接IP: " server_addr
	read -e -p "请输入外网对接token: " token
	echo

	donlond_frp

	cat <<EOF > /home/frp/frp_0.61.0_linux_amd64/frpc.toml
[common]
server_addr = ${server_addr}
server_port = 8055
token = ${token}

EOF

	install tmux
	tmux kill-session -t frpc >/dev/null 2>&1
	tmux new -d -s "frpc" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frpc -c frpc.toml"
	check_crontab_installed
	crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
	(crontab -l ; echo '@reboot tmux new -d -s "frpc" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frpc -c frpc.toml"') | crontab - > /dev/null 2>&1

	open_port 8055

}

add_forwarding_service() {
	send_stats "添加frp内网服务"
	# 提示用户输入服务名称和转发信息
	read -e -p "请输入服务名称: " service_name
	read -e -p "请输入转发类型 (tcp/udp) [回车默认tcp]: " service_type
	local service_type=${service_type:-tcp}
	read -e -p "请输入内网IP [回车默认127.0.0.1]: " local_ip
	local local_ip=${local_ip:-127.0.0.1}
	read -e -p "请输入内网端口: " local_port
	read -e -p "请输入外网端口: " remote_port

	# 将用户输入写入配置文件
	cat <<EOF >> /home/frp/frp_0.61.0_linux_amd64/frpc.toml
[$service_name]
type = ${service_type}
local_ip = ${local_ip}
local_port = ${local_port}
remote_port = ${remote_port}

EOF

	# 输出生成的信息
echo "Service $service_name was successfully added to frpc.toml"

	tmux kill-session -t frpc >/dev/null 2>&1
	tmux new -d -s "frpc" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frpc -c frpc.toml"

	open_port $local_port

}



delete_forwarding_service() {
	send_stats "删除frp内网服务"
	# 提示用户输入需要删除的服务名称
	read -e -p "请输入需要删除的服务名称: " service_name
	# 使用 sed 删除该服务及其相关配置
	sed -i "/\[$service_name\]/,/^$/d" /home/frp/frp_0.61.0_linux_amd64/frpc.toml
echo "Service $service_name has been successfully deleted from frpc.toml"

	tmux kill-session -t frpc >/dev/null 2>&1
	tmux new -d -s "frpc" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frpc -c frpc.toml"

}


list_forwarding_services() {
	local config_file="$1"

	# 打印表头
	printf "%-20s %-25s %-30s %-10s\n" "服务名称" "内网地址" "外网地址" "协议"

	awk '
	BEGIN {
		server_addr=""
		server_port=""
		current_service=""
	}

	/^server_addr = / {
		gsub(/"|'"'"'/, "", $3)
		server_addr=$3
	}

	/^server_port = / {
		gsub(/"|'"'"'/, "", $3)
		server_port=$3
	}

	/^\[.*\]/ {
		# 如果已有服务信息，在处理新服务之前打印当前服务
		if (current_service != "" && current_service != "common" && local_ip != "" && local_port != "") {
			printf "%-16s %-21s %-26s %-10s\n", \
				current_service, \
				local_ip ":" local_port, \
				server_addr ":" remote_port, \
				type
		}

		# 更新当前服务名称
		if ($1 != "[common]") {
			gsub(/[\[\]]/, "", $1)
			current_service=$1
			# 清除之前的值
			local_ip=""
			local_port=""
			remote_port=""
			type=""
		}
	}

	/^local_ip = / {
		gsub(/"|'"'"'/, "", $3)
		local_ip=$3
	}

	/^local_port = / {
		gsub(/"|'"'"'/, "", $3)
		local_port=$3
	}

	/^remote_port = / {
		gsub(/"|'"'"'/, "", $3)
		remote_port=$3
	}

	/^type = / {
		gsub(/"|'"'"'/, "", $3)
		type=$3
	}

	END {
		# 打印最后一个服务的信息
		if (current_service != "" && current_service != "common" && local_ip != "" && local_port != "") {
			printf "%-16s %-21s %-26s %-10s\n", \
				current_service, \
				local_ip ":" local_port, \
				server_addr ":" remote_port, \
				type
		}
	}' "$config_file"
}



# 获取 FRP 服务端端口
get_frp_ports() {
	mapfile -t ports < <(ss -tulnape | grep frps | awk '{print $5}' | awk -F':' '{print $NF}' | sort -u)
}

# 生成访问地址
generate_access_urls() {
	# 首先获取所有端口
	get_frp_ports

	# 检查是否有非 8055/8056 的端口
	local has_valid_ports=false
	for port in "${ports[@]}"; do
		if [[ $port != "8055" && $port != "8056" ]]; then
			has_valid_ports=true
			break
		fi
	done

	# 只在有有效端口时显示标题和内容
	if [ "$has_valid_ports" = true ]; then
echo "FRP service external access address:"

		# 处理 IPv4 地址
		for port in "${ports[@]}"; do
			if [[ $port != "8055" && $port != "8056" ]]; then
				echo "http://${ipv4_address}:${port}"
			fi
		done

		# 处理 IPv6 地址（如果存在）
		if [ -n "$ipv6_address" ]; then
			for port in "${ports[@]}"; do
				if [[ $port != "8055" && $port != "8056" ]]; then
					echo "http://[${ipv6_address}]:${port}"
				fi
			done
		fi

		# 处理 HTTPS 配置
		for port in "${ports[@]}"; do
			if [[ $port != "8055" && $port != "8056" ]]; then
				frps_search_pattern="${ipv4_address}:${port}"
				for file in /home/web/conf.d/*.conf; do
					if [ -f "$file" ]; then
						if grep -q "$frps_search_pattern" "$file" 2>/dev/null; then
							echo "https://$(basename "$file" .conf)"
						fi
					fi
				done
			fi
		done
	fi
}


frps_main_ports() {
	ip_address
	generate_access_urls
}




frps_panel() {
	send_stats "FRP服务端"
	local docker_port=8056
	while true; do
		clear
		check_frp_app
echo -e "FRP server $check_frp"
echo "Build a FRP intranet penetration service environment to expose devices without public IP to the Internet"
echo "Official website introduction: https://github.com/fatedier/frp/"
echo "Video Teaching: https://www.bilibili.com/video/BV1yMw6e2EwL?t=124.0"
		if [ -d "/home/frp/" ]; then
			check_docker_app_ip
			frps_main_ports
		fi
		echo ""
		echo "------------------------"
echo "1. Install 2. Update 3. Uninstall"
		echo "------------------------"
echo "5. Domain name access for intranet service 6. Delete domain name access"
		echo "------------------------"
echo "7. Allow IP+port access 8. Block IP+port access"
		echo "------------------------"
echo "00. Refresh service status 0. Return to the previous menu"
		echo "------------------------"
		read -e -p "输入你的选择: " choice
		case $choice in
			1)
				generate_frps_config
				rm -rf /home/frp/*.tar.gz
echo "FRP server has been installed"
				;;
			2)
				cp -f /home/frp/frp_0.61.0_linux_amd64/frps.toml /home/frp/frps.toml
				donlond_frp
				cp -f /home/frp/frps.toml /home/frp/frp_0.61.0_linux_amd64/frps.toml
				tmux kill-session -t frps >/dev/null 2>&1
				tmux new -d -s "frps" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frps -c frps.toml"
				crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
				(crontab -l ; echo '@reboot tmux new -d -s "frps" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frps -c frps.toml"') | crontab - > /dev/null 2>&1
				rm -rf /home/frp/*.tar.gz
echo "The FRP server has been updated"
				;;
			3)
				crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
				tmux kill-session -t frps >/dev/null 2>&1
				rm -rf /home/frp
				close_port 8055 8056

echo "App uninstalled"
				;;
			5)
echo "Replace intranet penetration services into domain name access"
				send_stats "FRP对外域名访问"
				add_yuming
				read -e -p "请输入你的内网穿透服务端口: " frps_port
				ldnmp_Proxy ${yuming} ${ipv4_address} ${frps_port}
				block_host_port "$frps_port" "$ipv4_address"
				;;
			6)
echo "Domain name format example.com does not come with https://"
				web_del
				;;

			7)
				send_stats "允许IP访问"
				read -e -p "请输入需要放行的端口: " frps_port
				clear_host_port_rules "$frps_port" "$ipv4_address"
				;;

			8)
				send_stats "阻止IP访问"
echo "If you have accessed an anti-generation domain name, use this feature to block IP+ port access, which is more secure."
				read -e -p "请输入需要阻止的端口: " frps_port
				block_host_port "$frps_port" "$ipv4_address"
				;;

			00)
				send_stats "刷新FRP服务状态"
echo "FRP service status has been refreshed"
				;;

			*)
				break
				;;
		esac
		break_end
	done
}


frpc_panel() {
	send_stats "FRP客户端"
	local docker_port=8055
	while true; do
		clear
		check_frp_app
echo -e "FRP client $check_frp"
echo "Dooring with the server, after docking, you can create an intranet penetration service to the Internet access"
echo "Official website introduction: https://github.com/fatedier/frp/"
echo "Video Teaching: https://www.bilibili.com/video/BV1yMw6e2EwL?t=173.9"
		echo "------------------------"
		if [ -d "/home/frp/" ]; then
			list_forwarding_services "/home/frp/frp_0.61.0_linux_amd64/frpc.toml"
		fi
		echo ""
		echo "------------------------"
echo "1. Install 2. Update 3. Uninstall"
		echo "------------------------"
echo "4. Add external services 5. Delete external services 6. Configure services manually"
		echo "------------------------"
echo "0. Return to previous menu"
		echo "------------------------"
		read -e -p "输入你的选择: " choice
		case $choice in
			1)
				configure_frpc
				rm -rf /home/frp/*.tar.gz
echo "The FRP client has been installed"
				;;
			2)
				cp -f /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
				donlond_frp
				cp -f /home/frp/frpc.toml /home/frp/frp_0.61.0_linux_amd64/frpc.toml
				tmux kill-session -t frpc >/dev/null 2>&1
				tmux new -d -s "frpc" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frpc -c frpc.toml"
				crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
				(crontab -l ; echo '@reboot tmux new -d -s "frpc" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frpc -c frpc.toml"') | crontab - > /dev/null 2>&1
				rm -rf /home/frp/*.tar.gz
echo "The FRP client has been updated"
				;;

			3)
				crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
				tmux kill-session -t frpc >/dev/null 2>&1
				rm -rf /home/frp
				close_port 8055
echo "App uninstalled"
				;;

			4)
				add_forwarding_service
				;;

			5)
				delete_forwarding_service
				;;

			6)
				install nano
				nano /home/frp/frp_0.61.0_linux_amd64/frpc.toml
				tmux kill-session -t frpc >/dev/null 2>&1
				tmux new -d -s "frpc" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frpc -c frpc.toml"
				;;

			*)
				break
				;;
		esac
		break_end
	done
}




current_timezone() {
	if grep -q 'Alpine' /etc/issue; then
	   date +"%Z %z"
	else
	   timedatectl | grep "Time zone" | awk '{print $3}'
	fi

}


set_timedate() {
	local shiqu="$1"
	if grep -q 'Alpine' /etc/issue; then
		install tzdata
		cp /usr/share/zoneinfo/${shiqu} /etc/localtime
		hwclock --systohc
	else
		timedatectl set-timezone ${shiqu}
	fi
}



# 修复dpkg中断问题
fix_dpkg() {
	pkill -9 -f 'apt|dpkg'
	rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
	DEBIAN_FRONTEND=noninteractive dpkg --configure -a
}


linux_update() {
echo -e "${gl_huang} is being updated in system...${gl_bai}"
	if command -v dnf &>/dev/null; then
		dnf -y update
	elif command -v yum &>/dev/null; then
		yum -y update
	elif command -v apt &>/dev/null; then
		fix_dpkg
		DEBIAN_FRONTEND=noninteractive apt update -y
		DEBIAN_FRONTEND=noninteractive apt full-upgrade -y
	elif command -v apk &>/dev/null; then
		apk update && apk upgrade
	elif command -v pacman &>/dev/null; then
		pacman -Syu --noconfirm
	elif command -v zypper &>/dev/null; then
		zypper refresh
		zypper update
	elif command -v opkg &>/dev/null; then
		opkg update
	else
echo "Unknown package manager!"
		return
	fi
}



linux_clean() {
echo -e "${gl_huang} is cleaning up the system...${gl_bai}"
	if command -v dnf &>/dev/null; then
		rpm --rebuilddb
		dnf autoremove -y
		dnf clean all
		dnf makecache
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v yum &>/dev/null; then
		rpm --rebuilddb
		yum autoremove -y
		yum clean all
		yum makecache
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v apt &>/dev/null; then
		fix_dpkg
		apt autoremove --purge -y
		apt clean -y
		apt autoclean -y
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v apk &>/dev/null; then
echo "Clean the package manager cache..."
		apk cache clean
echo "Delete the system log..."
		rm -rf /var/log/*
echo "Delete APK cache..."
		rm -rf /var/cache/apk/*
echo "Delete temporary files..."
		rm -rf /tmp/*

	elif command -v pacman &>/dev/null; then
		pacman -Rns $(pacman -Qdtq) --noconfirm
		pacman -Scc --noconfirm
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v zypper &>/dev/null; then
		zypper clean --all
		zypper refresh
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v opkg &>/dev/null; then
echo "Delete the system log..."
		rm -rf /var/log/*
echo "Delete temporary files..."
		rm -rf /tmp/*

	elif command -v pkg &>/dev/null; then
echo "Clean unused dependencies..."
		pkg autoremove -y
echo "Clean the package manager cache..."
		pkg clean -y
echo "Delete the system log..."
		rm -rf /var/log/*
echo "Delete temporary files..."
		rm -rf /tmp/*

	else
echo "Unknown package manager!"
		return
	fi
	return
}



bbr_on() {

cat > /etc/sysctl.conf << EOF
net.ipv4.tcp_congestion_control=bbr
EOF
sysctl -p

}


set_dns() {

ip_address

rm /etc/resolv.conf
touch /etc/resolv.conf

if [ -n "$ipv4_address" ]; then
	echo "nameserver $dns1_ipv4" >> /etc/resolv.conf
	echo "nameserver $dns2_ipv4" >> /etc/resolv.conf
fi

if [ -n "$ipv6_address" ]; then
	echo "nameserver $dns1_ipv6" >> /etc/resolv.conf
	echo "nameserver $dns2_ipv6" >> /etc/resolv.conf
fi

}


set_dns_ui() {
root_use
send_stats "优化DNS"
while true; do
	clear
echo "Optimize DNS Addresses"
	echo "------------------------"
echo "Current DNS Address"
	cat /etc/resolv.conf
	echo "------------------------"
	echo ""
echo "1. Foreign DNS optimization: "
	echo " v4: 1.1.1.1 8.8.8.8"
	echo " v6: 2606:4700:4700::1111 2001:4860:4860::8888"
echo "2. Domestic DNS optimization: "
	echo " v4: 223.5.5.5 183.60.83.19"
	echo " v6: 2400:3200::1 2400:da00::6666"
echo "3. Manually edit DNS configuration"
	echo "------------------------"
echo "0. Return to previous menu"
	echo "------------------------"
	read -e -p "请输入你的选择: " Limiting
	case "$Limiting" in
	  1)
		local dns1_ipv4="1.1.1.1"
		local dns2_ipv4="8.8.8.8"
		local dns1_ipv6="2606:4700:4700::1111"
		local dns2_ipv6="2001:4860:4860::8888"
		set_dns
		send_stats "国外DNS优化"
		;;
	  2)
		local dns1_ipv4="223.5.5.5"
		local dns2_ipv4="183.60.83.19"
		local dns1_ipv6="2400:3200::1"
		local dns2_ipv6="2400:da00::6666"
		set_dns
		send_stats "国内DNS优化"
		;;
	  3)
		install nano
		nano /etc/resolv.conf
		send_stats "手动编辑DNS配置"
		;;
	  *)
		break
		;;
	esac
done

}



restart_ssh() {
	restart sshd ssh > /dev/null 2>&1

}



correct_ssh_config() {

	local sshd_config="/etc/ssh/sshd_config"

	# 如果找到 PasswordAuthentication 设置为 yes
	if grep -Eq "^PasswordAuthentication\s+yes" "$sshd_config"; then
		sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' "$sshd_config"
		sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' "$sshd_config"
	fi

	# 如果找到 PubkeyAuthentication 设置为 yes
	if grep -Eq "^PubkeyAuthentication\s+yes" "$sshd_config"; then
		sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
			   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
			   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
			   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' "$sshd_config"
	fi

	# 如果 PasswordAuthentication 和 PubkeyAuthentication 都没有匹配，则设置默认值
	if ! grep -Eq "^PasswordAuthentication\s+yes" "$sshd_config" && ! grep -Eq "^PubkeyAuthentication\s+yes" "$sshd_config"; then
		sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' "$sshd_config"
		sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' "$sshd_config"
	fi

}


new_ssh_port() {

  # 备份 SSH 配置文件
  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

  sed -i 's/^\s*#\?\s*Port/Port/' /etc/ssh/sshd_config
  sed -i "s/Port [0-9]\+/Port $new_port/g" /etc/ssh/sshd_config

  correct_ssh_config
  rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*

  restart_ssh
  open_port $new_port
  remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1

echo "SSH port has been modified to: $new_port"

  sleep 1

}



add_sshkey() {

	ssh-keygen -t ed25519 -C "xxxx@gmail.com" -f /root/.ssh/sshkey -N ""

	cat ~/.ssh/sshkey.pub >> ~/.ssh/authorized_keys
	chmod 600 ~/.ssh/authorized_keys


	ip_address
echo -e "The private key information has been generated, be sure to copy and save it. It can be saved as ${gl_huang}${ipv4_address}_ssh.key${gl_bai} file for future SSH login"

	echo "--------------------------------"
	cat ~/.ssh/sshkey
	echo "--------------------------------"

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
echo -e "${gl_lv}ROOT private key login is enabled, ROOT password login has been closed, reconnection will take effect ${gl_bai}"

}


import_sshkey() {

	read -e -p "请输入您的SSH公钥内容（通常以 'ssh-rsa' 或 'ssh-ed25519' 开头）: " public_key

	if [[ -z "$public_key" ]]; then
echo -e "${gl_hong} Error: Public key content was not entered. ${gl_bai}"
		return 1
	fi

	echo "$public_key" >> ~/.ssh/authorized_keys
	chmod 600 ~/.ssh/authorized_keys

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config

	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
echo -e "${gl_lv} public key has been imported successfully, ROOT private key login has been enabled, ROOT password login has been closed, reconnection will take effect ${gl_bai}"

}




add_sshpasswd() {

echo "Set your ROOT password"
passwd
sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
restart_ssh
echo -e "${gl_lv}ROOT login setting is completed!${gl_bai}"

}


root_use() {
clear
[ "$EUID" -ne 0 ] && echo -e "${gl_huang}提示: ${gl_bai}该功能需要root用户才能运行！" && break_end && kejilion
}



dd_xitong() {
		send_stats "重装系统"
		dd_xitong_MollyLau() {
			wget --no-check-certificate -qO InstallNET.sh "${gh_proxy}raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh" && chmod a+x InstallNET.sh

		}

		dd_xitong_bin456789() {
			curl -O ${gh_proxy}raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
		}

		dd_xitong_1() {
echo -e "Initial username after reinstallation: ${gl_huang}root${gl_bai} Initial password: ${gl_huang}LeitboGi0ro${gl_bai} Initial port: ${gl_huang}22${gl_bai}"
echo -e "Press any key to continue..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_2() {
echo -e "Initial username after reinstallation: ${gl_huang}Administrator${gl_bai} Initial password: ${gl_huang}Teddysun.com${gl_bai} Initial port: ${gl_huang}3389${gl_bai}"
echo -e "Press any key to continue..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_3() {
echo -e "Initial username after reinstallation: ${gl_huang}root${gl_bai} Initial password: ${gl_huang}123@@@${gl_bai} Initial port: ${gl_huang}22${gl_bai}"
echo -e "Press any key to continue..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		dd_xitong_4() {
echo -e "Initial username after reinstallation: ${gl_huang}Administrator${gl_bai} Initial password: ${gl_huang}123@@@${gl_bai} Initial port: ${gl_huang}3389${gl_bai}"
echo -e "Press any key to continue..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		  while true; do
			root_use
echo "Reinstall the system"
			echo "--------------------------------"
echo -e "${gl_hong}Note: ${gl_bai} has the risk of losing contact when reinstalling. Those who are not satisfied with it are used with caution. Reinstalling is expected to take 15 minutes, please back up the data in advance."
echo -e "${gl_hui}Thanks to MollyLau and bin456789 for the script support! ${gl_bai} "
			echo "------------------------"
			echo "1. Debian 12                  2. Debian 11"
			echo "3. Debian 10                  4. Debian 9"
			echo "------------------------"
			echo "11. Ubuntu 24.04              12. Ubuntu 22.04"
			echo "13. Ubuntu 20.04              14. Ubuntu 18.04"
			echo "------------------------"
			echo "21. Rocky Linux 9             22. Rocky Linux 8"
			echo "23. Alma Linux 9              24. Alma Linux 8"
			echo "25. oracle Linux 9            26. oracle Linux 8"
			echo "27. Fedora Linux 41           28. Fedora Linux 40"
			echo "29. CentOS 10                 30. CentOS 9"
			echo "------------------------"
			echo "31. Alpine Linux              32. Arch Linux"
			echo "33. Kali Linux                34. openEuler"
echo "35. openSUSE Tumbleweed 36. fnos Feiniu Public Beta"
			echo "------------------------"
			echo "41. Windows 11                42. Windows 10"
			echo "43. Windows 7                 44. Windows Server 2022"
			echo "45. Windows Server 2019       46. Windows Server 2016"
			echo "47. Windows 11 ARM"
			echo "------------------------"
echo "0. Return to previous menu"
			echo "------------------------"
			read -e -p "请选择要重装的系统: " sys_choice
			case "$sys_choice" in
			  1)
				send_stats "重装debian 12"
				dd_xitong_1
				bash InstallNET.sh -debian 12
				reboot
				exit
				;;
			  2)
				send_stats "重装debian 11"
				dd_xitong_1
				bash InstallNET.sh -debian 11
				reboot
				exit
				;;
			  3)
				send_stats "重装debian 10"
				dd_xitong_1
				bash InstallNET.sh -debian 10
				reboot
				exit
				;;
			  4)
				send_stats "重装debian 9"
				dd_xitong_1
				bash InstallNET.sh -debian 9
				reboot
				exit
				;;
			  11)
				send_stats "重装ubuntu 24.04"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 24.04
				reboot
				exit
				;;
			  12)
				send_stats "重装ubuntu 22.04"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 22.04
				reboot
				exit
				;;
			  13)
				send_stats "重装ubuntu 20.04"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 20.04
				reboot
				exit
				;;
			  14)
				send_stats "重装ubuntu 18.04"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 18.04
				reboot
				exit
				;;


			  21)
				send_stats "重装rockylinux9"
				dd_xitong_3
				bash reinstall.sh rocky
				reboot
				exit
				;;

			  22)
				send_stats "重装rockylinux8"
				dd_xitong_3
				bash reinstall.sh rocky 8
				reboot
				exit
				;;

			  23)
				send_stats "重装alma9"
				dd_xitong_3
				bash reinstall.sh almalinux
				reboot
				exit
				;;

			  24)
				send_stats "重装alma8"
				dd_xitong_3
				bash reinstall.sh almalinux 8
				reboot
				exit
				;;

			  25)
				send_stats "重装oracle9"
				dd_xitong_3
				bash reinstall.sh oracle
				reboot
				exit
				;;

			  26)
				send_stats "重装oracle8"
				dd_xitong_3
				bash reinstall.sh oracle 8
				reboot
				exit
				;;

			  27)
				send_stats "重装fedora41"
				dd_xitong_3
				bash reinstall.sh fedora
				reboot
				exit
				;;

			  28)
				send_stats "重装fedora40"
				dd_xitong_3
				bash reinstall.sh fedora 40
				reboot
				exit
				;;

			  29)
				send_stats "重装centos10"
				dd_xitong_3
				bash reinstall.sh centos 10
				reboot
				exit
				;;

			  30)
				send_stats "重装centos9"
				dd_xitong_3
				bash reinstall.sh centos 9
				reboot
				exit
				;;

			  31)
				send_stats "重装alpine"
				dd_xitong_1
				bash InstallNET.sh -alpine
				reboot
				exit
				;;

			  32)
				send_stats "重装arch"
				dd_xitong_3
				bash reinstall.sh arch
				reboot
				exit
				;;

			  33)
				send_stats "重装kali"
				dd_xitong_3
				bash reinstall.sh kali
				reboot
				exit
				;;

			  34)
				send_stats "重装openeuler"
				dd_xitong_3
				bash reinstall.sh openeuler
				reboot
				exit
				;;

			  35)
				send_stats "重装opensuse"
				dd_xitong_3
				bash reinstall.sh opensuse
				reboot
				exit
				;;

			  36)
				send_stats "重装飞牛"
				dd_xitong_3
				bash reinstall.sh fnos
				reboot
				exit
				;;


			  41)
				send_stats "重装windows11"
				dd_xitong_2
				bash InstallNET.sh -windows 11 -lang "cn"
				reboot
				exit
				;;
			  42)
				dd_xitong_2
				send_stats "重装windows10"
				bash InstallNET.sh -windows 10 -lang "cn"
				reboot
				exit
				;;
			  43)
				send_stats "重装windows7"
				dd_xitong_4
				bash reinstall.sh windows --iso="https://drive.massgrave.dev/cn_windows_7_professional_with_sp1_x64_dvd_u_677031.iso" --image-name='Windows 7 PROFESSIONAL'
				reboot
				exit
				;;

			  44)
				send_stats "重装windows server 22"
				dd_xitong_2
				bash InstallNET.sh -windows 2022 -lang "cn"
				reboot
				exit
				;;
			  45)
				send_stats "重装windows server 19"
				dd_xitong_2
				bash InstallNET.sh -windows 2019 -lang "cn"
				reboot
				exit
				;;
			  46)
				send_stats "重装windows server 16"
				dd_xitong_2
				bash InstallNET.sh -windows 2016 -lang "cn"
				reboot
				exit
				;;

			  47)
				send_stats "重装windows11 ARM"
				dd_xitong_4
				bash reinstall.sh dd --img https://r2.hotdog.eu.org/win11-arm-with-pagefile-15g.xz
				reboot
				exit
				;;

			  *)
				break
				;;
			esac
		  done
}


bbrv3() {
		  root_use
		  send_stats "bbrv3管理"

		  local cpu_arch=$(uname -m)
		  if [ "$cpu_arch" = "aarch64" ]; then
			bash <(curl -sL jhb.ovh/jb/bbrv3arm.sh)
			break_end
			linux_Settings
		  fi

		  if dpkg -l | grep -q 'linux-xanmod'; then
			while true; do
				  clear
				  local kernel_version=$(uname -r)
echo "You have installed xanmod's BBRv3 kernel"
echo "Current kernel version: $kernel_version"

				  echo ""
echo "Kernel Management"
				  echo "------------------------"
echo "1. Update the BBRv3 kernel 2. Uninstall the BBRv3 kernel"
				  echo "------------------------"
echo "0. Return to previous menu"
				  echo "------------------------"
				  read -e -p "请输入你的选择: " sub_choice

				  case $sub_choice in
					  1)
						apt purge -y 'linux-*xanmod1*'
						update-grub

						# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
						wget -qO - ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

						# 步骤3：添加存储库
						echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

						# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
						local version=$(wget -q ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

						apt update -y
						apt install -y linux-xanmod-x64v$version

echo "XanMod kernel has been updated. Take effect after restart"
						rm -f /etc/apt/sources.list.d/xanmod-release.list
						rm -f check_x86-64_psabi.sh*

						server_reboot

						  ;;
					  2)
						apt purge -y 'linux-*xanmod1*'
						update-grub
echo "XanMod kernel has been uninstalled. Take effect after restart"
						server_reboot
						  ;;

					  *)
						  break  # 跳出循环，退出菜单
						  ;;

				  esac
			done
		else

		  clear
echo "Set BBR3 acceleration"
echo "Video introduction: https://www.bilibili.com/video/BV14K421x7BS?t=0.1"
		  echo "------------------------------------------------"
echo "Support only Debian/Ubuntu"
echo "Please back up the data, and it will enable BBR3 for you to upgrade the Linux kernel"
echo "VPS has 512M memory, please add 1G virtual memory in advance to prevent missing contact due to insufficient memory!"
		  echo "------------------------------------------------"
		  read -e -p "确定继续吗？(Y/N): " choice

		  case "$choice" in
			[Yy])
			if [ -r /etc/os-release ]; then
				. /etc/os-release
				if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
echo "The current environment does not support it, only Debian and Ubuntu systems are supported"
					break_end
					linux_Settings
				fi
			else
echo "Operational system type cannot be determined"
				break_end
				linux_Settings
			fi

			check_swap
			install wget gnupg

			# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
			wget -qO - ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

			# 步骤3：添加存储库
			echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

			# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
			local version=$(wget -q ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

			apt update -y
			apt install -y linux-xanmod-x64v$version

			bbr_on

echo "XanMod kernel installation and BBR3 enabled successfully. Take effect after restart"
			rm -f /etc/apt/sources.list.d/xanmod-release.list
			rm -f check_x86-64_psabi.sh*
			server_reboot

			  ;;
			[Nn])
echo "Canceled"
			  ;;
			*)
echo "Invalid selection, please enter Y or N."
			  ;;
		  esac
		fi

}


elrepo_install() {
	# 导入 ELRepo GPG 公钥
echo "Import ELRepo GPG public key..."
	rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
	# 检测系统版本
	local os_version=$(rpm -q --qf "%{VERSION}" $(rpm -qf /etc/os-release) 2>/dev/null | awk -F '.' '{print $1}')
	local os_name=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
	# 确保我们在一个支持的操作系统上运行
	if [[ "$os_name" != *"Red Hat"* && "$os_name" != *"AlmaLinux"* && "$os_name" != *"Rocky"* && "$os_name" != *"Oracle"* && "$os_name" != *"CentOS"* ]]; then
echo "Not supported operating system: $os_name"
		break_end
		linux_Settings
	fi
	# 打印检测到的操作系统信息
echo "Detected operating system: $os_name $os_version"
	# 根据系统版本安装对应的 ELRepo 仓库配置
	if [[ "$os_version" == 8 ]]; then
echo "Installing ELRepo Repository Configuration (version 8)...."
		yum -y install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
	elif [[ "$os_version" == 9 ]]; then
echo "Installing ELRepo Repository Configuration (version 9)...."
		yum -y install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm
	else
echo "Unsupported system version: $os_version"
		break_end
		linux_Settings
	fi
	# 启用 ELRepo 内核仓库并安装最新的主线内核
echo "Enable the ELRepo kernel repository and install the latest mainline kernel..."
	# yum -y --enablerepo=elrepo-kernel install kernel-ml
	yum --nogpgcheck -y --enablerepo=elrepo-kernel install kernel-ml
echo "The ELRepo repository configuration is installed and updated to the latest mainline kernel."
	server_reboot

}


elrepo() {
		  root_use
		  send_stats "红帽内核管理"
		  if uname -r | grep -q 'elrepo'; then
			while true; do
				  clear
				  kernel_version=$(uname -r)
echo "You have installed the elrepo kernel"
echo "Current kernel version: $kernel_version"

				  echo ""
echo "Kernel Management"
				  echo "------------------------"
echo "1. Update the elrepo kernel 2. Uninstall the elrepo kernel"
				  echo "------------------------"
echo "0. Return to previous menu"
				  echo "------------------------"
				  read -e -p "请输入你的选择: " sub_choice

				  case $sub_choice in
					  1)
						dnf remove -y elrepo-release
						rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
						elrepo_install
						send_stats "更新红帽内核"
						server_reboot

						  ;;
					  2)
						dnf remove -y elrepo-release
						rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
echo "elrepo kernel has been uninstalled. Take effect after restart"
						send_stats "卸载红帽内核"
						server_reboot

						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;

				  esac
			done
		else

		  clear
echo "Please back up the data, it will upgrade the Linux kernel for you"
echo "Video introduction: https://www.bilibili.com/video/BV1mH4y1w7qA?t=529.2"
		  echo "------------------------------------------------"
echo "Only support Red Hat series distributions CentOS/RedHat/Alma/Rocky/oracle"
echo "Upgrading the Linux kernel can improve system performance and security. It is recommended to try it if conditions permit, and upgrade the production environment with caution!"
		  echo "------------------------------------------------"
		  read -e -p "确定继续吗？(Y/N): " choice

		  case "$choice" in
			[Yy])
			  check_swap
			  elrepo_install
			  send_stats "升级红帽内核"
			  server_reboot
			  ;;
			[Nn])
echo "Canceled"
			  ;;
			*)
echo "Invalid selection, please enter Y or N."
			  ;;
		  esac
		fi

}




clamav_freshclam() {
echo -e "${gl_huang} is updating the virus library...${gl_bai}"
	docker run --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		clamav/clamav-debian:latest \
		freshclam
}

clamav_scan() {
	if [ $# -eq 0 ]; then
echo "Please specify the directory to scan."
		return
	fi

echo -e "${gl_huang} is scanning directory $@... ${gl_bai}"

	# 构建 mount 参数
	local MOUNT_PARAMS=""
	for dir in "$@"; do
		MOUNT_PARAMS+="--mount type=bind,source=${dir},target=/mnt/host${dir} "
	done

	# 构建 clamscan 命令参数
	local SCAN_PARAMS=""
	for dir in "$@"; do
		SCAN_PARAMS+="/mnt/host${dir} "
	done

	mkdir -p /home/docker/clamav/log/ > /dev/null 2>&1
	> /home/docker/clamav/log/scan.log > /dev/null 2>&1

	# 执行 Docker 命令
	docker run -it --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		$MOUNT_PARAMS \
		-v /home/docker/clamav/log/:/var/log/clamav/ \
		clamav/clamav-debian:latest \
		clamscan -r --log=/var/log/clamav/scan.log $SCAN_PARAMS

echo -e "${gl_lv}$@ Scan complete, virus report is stored in ${gl_huang}/home/docker/clamav/log/scan.log${gl_bai}"
echo -e "${gl_lv}If there is a virus, please search the FOUND keyword in the ${gl_huang}scan.log${gl_lv} file to confirm the virus location ${gl_bai}"

}







clamav() {
		  root_use
		  send_stats "病毒扫描管理"
		  while true; do
				clear
echo "clamav virus scanning tool"
echo "Video introduction: https://www.bilibili.com/video/BV1TqvZe4EQm?t=0.1"
				echo "------------------------"
echo "It is an open source antivirus software tool that is mainly used to detect and remove various types of malware."
echo "Including viruses, Trojan horses, spyware, malicious scripts and other harmful software."
				echo "------------------------"
echo -e "${gl_lv}1. Full disk scan ${gl_bai} ${gl_huang}2. Important directory scan ${gl_bai} ${gl_kjlan} 3. Custom directory scan ${gl_bai}"
				echo "------------------------"
echo "0. Return to previous menu"
				echo "------------------------"
				read -e -p "请输入你的选择: " sub_choice
				case $sub_choice in
					1)
					  send_stats "全盘扫描"
					  install_docker
					  docker volume create clam_db > /dev/null 2>&1
					  clamav_freshclam
					  clamav_scan /
					  break_end

						;;
					2)
					  send_stats "重要目录扫描"
					  install_docker
					  docker volume create clam_db > /dev/null 2>&1
					  clamav_freshclam
					  clamav_scan /etc /var /usr /home /root
					  break_end
						;;
					3)
					  send_stats "自定义目录扫描"
					  read -e -p "请输入要扫描的目录，用空格分隔（例如：/etc /var /usr /home /root）: " directories
					  install_docker
					  clamav_freshclam
					  clamav_scan $directories
					  break_end
						;;
					*)
					  break  # 跳出循环，退出菜单
						;;
				esac
		  done

}




# 高性能模式优化函数
optimize_high_performance() {
echo -e "${gl_lv}Switch to ${tiaoyou_moshi}...${gl_bai}"

echo -e "${gl_lv}optimized file descriptor...${gl_bai}"
	ulimit -n 65535

echo -e "${gl_lv}optimized virtual memory...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=15 2>/dev/null
	sysctl -w vm.dirty_background_ratio=5 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

echo -e "${gl_lv}optimize network settings...${gl_bai}"
	sysctl -w net.core.rmem_max=16777216 2>/dev/null
	sysctl -w net.core.wmem_max=16777216 2>/dev/null
	sysctl -w net.core.netdev_max_backlog=250000 2>/dev/null
	sysctl -w net.core.somaxconn=4096 2>/dev/null
	sysctl -w net.ipv4.tcp_rmem='4096 87380 16777216' 2>/dev/null
	sysctl -w net.ipv4.tcp_wmem='4096 65536 16777216' 2>/dev/null
	sysctl -w net.ipv4.tcp_congestion_control=bbr 2>/dev/null
	sysctl -w net.ipv4.tcp_max_syn_backlog=8192 2>/dev/null
	sysctl -w net.ipv4.tcp_tw_reuse=1 2>/dev/null
	sysctl -w net.ipv4.ip_local_port_range='1024 65535' 2>/dev/null

echo -e "${gl_lv}optimized cache management...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

echo -e "${gl_lv}optimize CPU settings...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

echo -e "${gl_lv}Other optimizations...${gl_bai}"
	# 禁用透明大页面，减少延迟
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	# 禁用 NUMA balancing
	sysctl -w kernel.numa_balancing=0 2>/dev/null


}

# 均衡模式优化函数
optimize_balanced() {
echo -e "${gl_lv} switch to equalization mode...${gl_bai}"

echo -e "${gl_lv}optimized file descriptor...${gl_bai}"
	ulimit -n 32768

echo -e "${gl_lv}optimized virtual memory...${gl_bai}"
	sysctl -w vm.swappiness=30 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=32768 2>/dev/null

echo -e "${gl_lv}optimize network settings...${gl_bai}"
	sysctl -w net.core.rmem_max=8388608 2>/dev/null
	sysctl -w net.core.wmem_max=8388608 2>/dev/null
	sysctl -w net.core.netdev_max_backlog=125000 2>/dev/null
	sysctl -w net.core.somaxconn=2048 2>/dev/null
	sysctl -w net.ipv4.tcp_rmem='4096 87380 8388608' 2>/dev/null
	sysctl -w net.ipv4.tcp_wmem='4096 32768 8388608' 2>/dev/null
	sysctl -w net.ipv4.tcp_congestion_control=bbr 2>/dev/null
	sysctl -w net.ipv4.tcp_max_syn_backlog=4096 2>/dev/null
	sysctl -w net.ipv4.tcp_tw_reuse=1 2>/dev/null
	sysctl -w net.ipv4.ip_local_port_range='1024 49151' 2>/dev/null

echo -e "${gl_lv}optimized cache management...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=75 2>/dev/null

echo -e "${gl_lv}optimize CPU settings...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

echo -e "${gl_lv}Other optimizations...${gl_bai}"
	# 还原透明大页面
	echo always > /sys/kernel/mm/transparent_hugepage/enabled
	# 还原 NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null


}

# 还原默认设置函数
restore_defaults() {
echo -e "${gl_lv}Restore to default settings...${gl_bai}"

echo -e "${gl_lv}Restore file descriptor...${gl_bai}"
	ulimit -n 1024

echo -e "${gl_lv}Restore virtual memory...${gl_bai}"
	sysctl -w vm.swappiness=60 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=16384 2>/dev/null

echo -e "${gl_lv}Restore network settings...${gl_bai}"
	sysctl -w net.core.rmem_max=212992 2>/dev/null
	sysctl -w net.core.wmem_max=212992 2>/dev/null
	sysctl -w net.core.netdev_max_backlog=1000 2>/dev/null
	sysctl -w net.core.somaxconn=128 2>/dev/null
	sysctl -w net.ipv4.tcp_rmem='4096 87380 6291456' 2>/dev/null
	sysctl -w net.ipv4.tcp_wmem='4096 16384 4194304' 2>/dev/null
	sysctl -w net.ipv4.tcp_congestion_control=cubic 2>/dev/null
	sysctl -w net.ipv4.tcp_max_syn_backlog=2048 2>/dev/null
	sysctl -w net.ipv4.tcp_tw_reuse=0 2>/dev/null
	sysctl -w net.ipv4.ip_local_port_range='32768 60999' 2>/dev/null

echo -e "${gl_lv}Restore cache management...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=100 2>/dev/null

echo -e "${gl_lv}Restore CPU settings...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

echo -e "${gl_lv}restore other optimizations...${gl_bai}"
	# 还原透明大页面
	echo always > /sys/kernel/mm/transparent_hugepage/enabled
	# 还原 NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null

}



# 网站搭建优化函数
optimize_web_server() {
echo -e "${gl_lv}Switch to website building optimization mode...${gl_bai}"

echo -e "${gl_lv}optimized file descriptor...${gl_bai}"
	ulimit -n 65535

echo -e "${gl_lv}optimized virtual memory...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

echo -e "${gl_lv}optimize network settings...${gl_bai}"
	sysctl -w net.core.rmem_max=16777216 2>/dev/null
	sysctl -w net.core.wmem_max=16777216 2>/dev/null
	sysctl -w net.core.netdev_max_backlog=5000 2>/dev/null
	sysctl -w net.core.somaxconn=4096 2>/dev/null
	sysctl -w net.ipv4.tcp_rmem='4096 87380 16777216' 2>/dev/null
	sysctl -w net.ipv4.tcp_wmem='4096 65536 16777216' 2>/dev/null
	sysctl -w net.ipv4.tcp_congestion_control=bbr 2>/dev/null
	sysctl -w net.ipv4.tcp_max_syn_backlog=8192 2>/dev/null
	sysctl -w net.ipv4.tcp_tw_reuse=1 2>/dev/null
	sysctl -w net.ipv4.ip_local_port_range='1024 65535' 2>/dev/null

echo -e "${gl_lv}optimized cache management...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

echo -e "${gl_lv}optimize CPU settings...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

echo -e "${gl_lv}Other optimizations...${gl_bai}"
	# 禁用透明大页面，减少延迟
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	# 禁用 NUMA balancing
	sysctl -w kernel.numa_balancing=0 2>/dev/null


}


Kernel_optimize() {
	root_use
	while true; do
	  clear
	  send_stats "Linux内核调优管理"
echo "Linux system kernel parameter optimization"
echo "Video introduction: https://www.bilibili.com/video/BV1Kb421J7yg?t=0.1"
	  echo "------------------------------------------------"
echo "Providing a variety of system parameter tuning modes, users can choose and switch according to their own usage scenarios."
echo -e "${gl_huang}Tip: Please use it with caution in the production environment of ${gl_bai}!"
	  echo "--------------------"
echo "1. High-performance optimization mode: Maximize system performance, optimize file descriptors, virtual memory, network settings, cache management, and CPU settings."
echo "2. Balanced Optimization Mode: Balance between performance and resource consumption, suitable for daily use."
echo "3. Website optimization mode: Optimize for website servers to improve concurrent connection processing capabilities, response speed and overall performance."
echo "4. Live streaming optimization mode: Optimize for the special needs of live streaming, reduce latency and improve transmission performance."
echo "5. Game server optimization mode: Optimize for game servers to improve concurrent processing capabilities and response speed."
echo "6. Restore the default settings: Restore the system settings to the default configuration."
	  echo "--------------------"
echo "0. Return to previous menu"
	  echo "--------------------"
	  read -e -p "请输入你的选择: " sub_choice
	  case $sub_choice in
		  1)
			  cd ~
			  clear
			  local tiaoyou_moshi="高性能优化模式"
			  optimize_high_performance
			  send_stats "高性能模式优化"
			  ;;
		  2)
			  cd ~
			  clear
			  optimize_balanced
			  send_stats "均衡模式优化"
			  ;;
		  3)
			  cd ~
			  clear
			  optimize_web_server
			  send_stats "网站优化模式"
			  ;;
		  4)
			  cd ~
			  clear
			  local tiaoyou_moshi="直播优化模式"
			  optimize_high_performance
			  send_stats "直播推流优化"
			  ;;
		  5)
			  cd ~
			  clear
			  local tiaoyou_moshi="游戏服优化模式"
			  optimize_high_performance
			  send_stats "游戏服优化"
			  ;;
		  6)
			  cd ~
			  clear
			  restore_defaults
			  send_stats "还原默认设置"
			  ;;
		  *)
			  break
			  ;;
	  esac
	  break_end
	done
}





update_locale() {
	local lang=$1
	local locale_file=$2

	if [ -f /etc/os-release ]; then
		. /etc/os-release
		case $ID in
			debian|ubuntu|kali)
				install locales
				sed -i "s/^\s*#\?\s*${locale_file}/${locale_file}/" /etc/locale.gen
				locale-gen
				echo "LANG=${lang}" > /etc/default/locale
				export LANG=${lang}
echo -e "${gl_lv} system language has been modified to: $lang Reconnect SSH to take effect. ${gl_bai}"
				hash -r
				break_end

				;;
			centos|rhel|almalinux|rocky|fedora)
				install glibc-langpack-zh
				localectl set-locale LANG=${lang}
				echo "LANG=${lang}" | tee /etc/locale.conf
echo -e "${gl_lv} system language has been modified to: $lang Reconnect SSH to take effect. ${gl_bai}"
				hash -r
				break_end
				;;
			*)
echo "Unsupported systems: $ID"
				break_end
				;;
		esac
	else
echo "Unsupported system, system type cannot be recognized."
		break_end
	fi
}




linux_language() {
root_use
send_stats "切换系统语言"
while true; do
  clear
echo "Current system language: $LANG"
  echo "------------------------"
echo "1. English 2. Simplified Chinese 3. Traditional Chinese"
  echo "------------------------"
echo "0. Return to previous menu"
  echo "------------------------"
  read -e -p "输入你的选择: " choice

  case $choice in
	  1)
		  update_locale "en_US.UTF-8" "en_US.UTF-8"
		  send_stats "切换到英文"
		  ;;
	  2)
		  update_locale "zh_CN.UTF-8" "zh_CN.UTF-8"
		  send_stats "切换到简体中文"
		  ;;
	  3)
		  update_locale "zh_TW.UTF-8" "zh_TW.UTF-8"
		  send_stats "切换到繁体中文"
		  ;;
	  *)
		  break
		  ;;
  esac
done
}



shell_bianse_profile() {

if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
	sed -i '/^PS1=/d' ~/.bashrc
	echo "${bianse}" >> ~/.bashrc
	# source ~/.bashrc
else
	sed -i '/^PS1=/d' ~/.profile
	echo "${bianse}" >> ~/.profile
	# source ~/.profile
fi
echo -e "${gl_lv} change is completed. You can view the changes after reconnecting SSH! ${gl_bai}"

hash -r
break_end

}



shell_bianse() {
  root_use
  send_stats "命令行美化工具"
  while true; do
	clear
echo "Command Line Beautification Tool"
	echo "------------------------"
	echo -e "1. \033[1;32mroot \033[1;34mlocalhost \033[1;31m~ \033[0m${gl_bai}#"
	echo -e "2. \033[1;35mroot \033[1;36mlocalhost \033[1;33m~ \033[0m${gl_bai}#"
	echo -e "3. \033[1;31mroot \033[1;32mlocalhost \033[1;34m~ \033[0m${gl_bai}#"
	echo -e "4. \033[1;36mroot \033[1;33mlocalhost \033[1;37m~ \033[0m${gl_bai}#"
	echo -e "5. \033[1;37mroot \033[1;31mlocalhost \033[1;32m~ \033[0m${gl_bai}#"
	echo -e "6. \033[1;33mroot \033[1;34mlocalhost \033[1;35m~ \033[0m${gl_bai}#"
	echo -e "7. root localhost ~ #"
	echo "------------------------"
echo "0. Return to previous menu"
	echo "------------------------"
	read -e -p "输入你的选择: " choice

	case $choice in
	  1)
		local bianse="PS1='\[\033[1;32m\]\u\[\033[0m\]@\[\033[1;34m\]\h\[\033[0m\] \[\033[1;31m\]\w\[\033[0m\] # '"
		shell_bianse_profile

		;;
	  2)
		local bianse="PS1='\[\033[1;35m\]\u\[\033[0m\]@\[\033[1;36m\]\h\[\033[0m\] \[\033[1;33m\]\w\[\033[0m\] # '"
		shell_bianse_profile
		;;
	  3)
		local bianse="PS1='\[\033[1;31m\]\u\[\033[0m\]@\[\033[1;32m\]\h\[\033[0m\] \[\033[1;34m\]\w\[\033[0m\] # '"
		shell_bianse_profile
		;;
	  4)
		local bianse="PS1='\[\033[1;36m\]\u\[\033[0m\]@\[\033[1;33m\]\h\[\033[0m\] \[\033[1;37m\]\w\[\033[0m\] # '"
		shell_bianse_profile
		;;
	  5)
		local bianse="PS1='\[\033[1;37m\]\u\[\033[0m\]@\[\033[1;31m\]\h\[\033[0m\] \[\033[1;32m\]\w\[\033[0m\] # '"
		shell_bianse_profile
		;;
	  6)
		local bianse="PS1='\[\033[1;33m\]\u\[\033[0m\]@\[\033[1;34m\]\h\[\033[0m\] \[\033[1;35m\]\w\[\033[0m\] # '"
		shell_bianse_profile
		;;
	  7)
		local bianse=""
		shell_bianse_profile
		;;
	  *)
		break
		;;
	esac

  done
}




linux_trash() {
  root_use
  send_stats "系统回收站"

  local bashrc_profile="/root/.bashrc"
  local TRASH_DIR="$HOME/.local/share/Trash/files"

  while true; do

	local trash_status
	if ! grep -q "trash-put" "$bashrc_profile"; then
		trash_status="${gl_hui}未启用${gl_bai}"
	else
		trash_status="${gl_lv}已启用${gl_bai}"
	fi

	clear
echo -e "Current Recycle Bin ${trash_status}"
echo -e "Files deleted by rm are first entered into the recycling bin after enabling it to prevent the mistaken deletion of important files!"
	echo "------------------------------------------------"
	ls -l --color=auto "$TRASH_DIR" 2>/dev/null || echo "回收站为空"
	echo "------------------------"
echo "1. Enable Recycle Bin 2. Close Recycle Bin"
echo "3. Restore content 4. Clear the recycling bin"
	echo "------------------------"
echo "0. Return to previous menu"
	echo "------------------------"
	read -e -p "输入你的选择: " choice

	case $choice in
	  1)
		install trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='trash-put'" >> "$bashrc_profile"
		source "$bashrc_profile"
echo "The Recycle Bin is enabled and deleted files will be moved to the Recycle Bin."
		sleep 2
		;;
	  2)
		remove trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='rm -i'" >> "$bashrc_profile"
		source "$bashrc_profile"
echo "The recycle bin is closed and the file will be deleted directly."
		sleep 2
		;;
	  3)
		read -e -p "输入要还原的文件名: " file_to_restore
		if [ -e "$TRASH_DIR/$file_to_restore" ]; then
		  mv "$TRASH_DIR/$file_to_restore" "$HOME/"
echo "$file_to_restore has been restored to the home directory."
		else
echo "The file does not exist."
		fi
		;;
	  4)
		read -e -p "确认清空回收站？[y/n]: " confirm
		if [[ "$confirm" == "y" ]]; then
		  trash-empty
echo "The recycling bin has been cleared."
		fi
		;;
	  *)
		break
		;;
	esac
  done
}



# 创建备份
create_backup() {
	send_stats "创建备份"
	local TIMESTAMP=$(date +"%Y%m%d%H%M%S")

	# 提示用户输入备份目录
echo "Create backup example:"
echo " - Backup a single directory: /var/www"
echo " - Backup multiple directories: /etc /home /var/log"
echo " - Direct Enter will use the default directory (/etc /usr /home)"
	read -r -p "请输入要备份的目录（多个目录用空格分隔，直接回车则使用默认目录）：" input

	# 如果用户没有输入目录，则使用默认目录
	if [ -z "$input" ]; then
		BACKUP_PATHS=(
			"/etc"              # 配置文件和软件包配置
			"/usr"              # 已安装的软件文件
			"/home"             # 用户数据
		)
	else
		# 将用户输入的目录按空格分隔成数组
		IFS=' ' read -r -a BACKUP_PATHS <<< "$input"
	fi

	# 生成备份文件前缀
	local PREFIX=""
	for path in "${BACKUP_PATHS[@]}"; do
		# 提取目录名称并去除斜杠
		dir_name=$(basename "$path")
		PREFIX+="${dir_name}_"
	done

	# 去除最后一个下划线
	local PREFIX=${PREFIX%_}

	# 生成备份文件名
	local BACKUP_NAME="${PREFIX}_$TIMESTAMP.tar.gz"

	# 打印用户选择的目录
echo "The backup directory you selected is:"
	for path in "${BACKUP_PATHS[@]}"; do
		echo "- $path"
	done

	# 创建备份
echo "Creating a backup $BACKUP_NAME..."
	install tar
	tar -czvf "$BACKUP_DIR/$BACKUP_NAME" "${BACKUP_PATHS[@]}"

	# 检查命令是否成功
	if [ $? -eq 0 ]; then
echo "Backup creation successfully: $BACKUP_DIR/$BACKUP_NAME"
	else
echo "Backup creation failed!"
		exit 1
	fi
}

# 恢复备份
restore_backup() {
	send_stats "恢复备份"
	# 选择要恢复的备份
	read -e -p "请输入要恢复的备份文件名: " BACKUP_NAME

	# 检查备份文件是否存在
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
echo "The backup file does not exist!"
		exit 1
	fi

echo "Restored backup $BACKUP_NAME..."
	tar -xzvf "$BACKUP_DIR/$BACKUP_NAME" -C /

	if [ $? -eq 0 ]; then
echo "Backup recovery succeeded!"
	else
echo "Backup recovery failed!"
		exit 1
	fi
}

# 列出备份
list_backups() {
echo "Available backups:"
	ls -1 "$BACKUP_DIR"
}

# 删除备份
delete_backup() {
	send_stats "删除备份"

	read -e -p "请输入要删除的备份文件名: " BACKUP_NAME

	# 检查备份文件是否存在
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
echo "The backup file does not exist!"
		exit 1
	fi

	# 删除备份
	rm -f "$BACKUP_DIR/$BACKUP_NAME"

	if [ $? -eq 0 ]; then
echo "Backup deleted successfully!"
	else
echo "Backup deletion failed!"
		exit 1
	fi
}

# 备份主菜单
linux_backup() {
	BACKUP_DIR="/backups"
	mkdir -p "$BACKUP_DIR"
	while true; do
		clear
		send_stats "系统备份功能"
echo "System Backup Function"
		echo "------------------------"
		list_backups
		echo "------------------------"
echo "1. Create a backup 2. Restore a backup 3. Delete a backup"
		echo "------------------------"
echo "0. Return to previous menu"
		echo "------------------------"
		read -e -p "请输入你的选择: " choice
		case $choice in
			1) create_backup ;;
			2) restore_backup ;;
			3) delete_backup ;;
			*) break ;;
		esac
		read -e -p "按回车键继续..."
	done
}









# 显示连接列表
list_connections() {
echo "Saved connection:"
	echo "------------------------"
	cat "$CONFIG_FILE" | awk -F'|' '{print NR " - " $1 " (" $2 ")"}'
	echo "------------------------"
}


# 添加新连接
add_connection() {
	send_stats "添加新连接"
echo "Create a new connection example:"
echo " - Connection name: my_server"
echo " - IP address: 192.168.1.100"
echo " - Username: root"
echo " - Port: 22"
	echo "------------------------"
	read -e -p "请输入连接名称: " name
	read -e -p "请输入IP地址: " ip
	read -e -p "请输入用户名 (默认: root): " user
	local user=${user:-root}  # 如果用户未输入，则使用默认值 root
	read -e -p "请输入端口号 (默认: 22): " port
	local port=${port:-22}  # 如果用户未输入，则使用默认值 22

echo "Please select authentication method:"
echo "1. Password"
echo "2. Key"
	read -e -p "请输入选择 (1/2): " auth_choice

	case $auth_choice in
		1)
			read -s -p "请输入密码: " password_or_key
echo  # Line break
			;;
		2)
echo "Please paste the key content (press press Enter twice after pasting):"
			local password_or_key=""
			while IFS= read -r line; do
				# 如果输入为空行且密钥内容已经包含了开头，则结束输入
				if [[ -z "$line" && "$password_or_key" == *"-----BEGIN"* ]]; then
					break
				fi
				# 如果是第一行或已经开始输入密钥内容，则继续添加
				if [[ -n "$line" || "$password_or_key" == *"-----BEGIN"* ]]; then
					local password_or_key+="${line}"$'\n'
				fi
			done

			# 检查是否是密钥内容
			if [[ "$password_or_key" == *"-----BEGIN"* && "$password_or_key" == *"PRIVATE KEY-----"* ]]; then
				local key_file="$KEY_DIR/$name.key"
				echo -n "$password_or_key" > "$key_file"
				chmod 600 "$key_file"
				local password_or_key="$key_file"
			fi
			;;
		*)
echo "Invalid choice!"
			return
			;;
	esac

	echo "$name|$ip|$user|$port|$password_or_key" >> "$CONFIG_FILE"
echo "The connection is saved!"
}



# 删除连接
delete_connection() {
	send_stats "删除连接"
	read -e -p "请输入要删除的连接编号: " num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
echo "Error: The corresponding connection was not found."
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<< "$connection"

	# 如果连接使用的是密钥文件，则删除该密钥文件
	if [[ "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
echo "The connection has been deleted!"
}

# 使用连接
use_connection() {
	send_stats "使用连接"
	read -e -p "请输入要使用的连接编号: " num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
echo "Error: The corresponding connection was not found."
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<< "$connection"

echo "Connecting to $name ($ip)...."
	if [[ -f "$password_or_key" ]]; then
		# 使用密钥连接
		ssh -o StrictHostKeyChecking=no -i "$password_or_key" -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
echo "Connection failed! Please check the following:"
echo "1. Is the key file path correct: $password_or_key"
echo "2. Is the key file permission correct (should be 600)."
echo "3. Whether the target server allows login with the key."
		fi
	else
		# 使用密码连接
		if ! command -v sshpass &> /dev/null; then
echo "Error: sshpass is not installed, please install sshpass first."
echo "Installation method:"
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
echo "Connection failed! Please check the following:"
echo "1. Is the username and password correct?"
echo "2. Whether the target server allows password login."
echo "3. Is the SSH service on the target server running normally?"
		fi
	fi
}


ssh_manager() {
	send_stats "ssh远程连接工具"

	CONFIG_FILE="$HOME/.ssh_connections"
	KEY_DIR="$HOME/.ssh/ssh_manager_keys"

	# 检查配置文件和密钥目录是否存在，如果不存在则创建
	if [[ ! -f "$CONFIG_FILE" ]]; then
		touch "$CONFIG_FILE"
	fi

	if [[ ! -d "$KEY_DIR" ]]; then
		mkdir -p "$KEY_DIR"
		chmod 700 "$KEY_DIR"
	fi

	while true; do
		clear
echo "SSH Remote Connection Tool"
echo "Can be connected to other Linux systems via SSH"
		echo "------------------------"
		list_connections
echo "1. Create a new connection 2. Use a connection 3. Delete a connection"
		echo "------------------------"
echo "0. Return to previous menu"
		echo "------------------------"
		read -e -p "请输入你的选择: " choice
		case $choice in
			1) add_connection ;;
			2) use_connection ;;
			3) delete_connection ;;
			0) break ;;
			*) echo "无效的选择，请重试。" ;;
		esac
	done
}












# 列出可用的硬盘分区
list_partitions() {
echo "Available hard disk partitions:"
	lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -v "sr\|loop"
}

# 挂载分区
mount_partition() {
	send_stats "挂载分区"
	read -p "请输入要挂载的分区名称（例如 sda1）: " PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
echo "The partition does not exist!"
		return
	fi

	# 检查分区是否已经挂载
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" > /dev/null; then
echo "The partition is already mounted!"
		return
	fi

	# 创建挂载点
	MOUNT_POINT="/mnt/$PARTITION"
	mkdir -p "$MOUNT_POINT"

	# 挂载分区
	mount "/dev/$PARTITION" "$MOUNT_POINT"

	if [ $? -eq 0 ]; then
echo "Partition mount successfully: $MOUNT_POINT"
	else
echo "Partition mount failed!"
		rmdir "$MOUNT_POINT"
	fi
}

# 卸载分区
unmount_partition() {
	send_stats "卸载分区"
	read -p "请输入要卸载的分区名称（例如 sda1）: " PARTITION

	# 检查分区是否已经挂载
	MOUNT_POINT=$(lsblk -o MOUNTPOINT | grep -w "$PARTITION")
	if [ -z "$MOUNT_POINT" ]; then
echo "The partition is not mounted!"
		return
	fi

	# 卸载分区
	umount "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
echo "Partition uninstalled successfully: $MOUNT_POINT"
		rmdir "$MOUNT_POINT"
	else
echo "Partition uninstall failed!"
	fi
}

# 列出已挂载的分区
list_mounted_partitions() {
echo "mounted partition:"
	df -h | grep -v "tmpfs\|udev\|overlay"
}

# 格式化分区
format_partition() {
	send_stats "格式化分区"
	read -p "请输入要格式化的分区名称（例如 sda1）: " PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
echo "The partition does not exist!"
		return
	fi

	# 检查分区是否已经挂载
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" > /dev/null; then
echo "The partition has been mounted, please uninstall it first!"
		return
	fi

	# 选择文件系统类型
echo "Please select the file system type:"
	echo "1. ext4"
	echo "2. xfs"
	echo "3. ntfs"
	echo "4. vfat"
	read -p "请输入你的选择: " FS_CHOICE

	case $FS_CHOICE in
		1) FS_TYPE="ext4" ;;
		2) FS_TYPE="xfs" ;;
		3) FS_TYPE="ntfs" ;;
		4) FS_TYPE="vfat" ;;
		*) echo "无效的选择！"; return ;;
	esac

	# 确认格式化
	read -p "确认格式化分区 /dev/$PARTITION 为 $FS_TYPE 吗？(y/n): " CONFIRM
	if [ "$CONFIRM" != "y" ]; then
echo "The operation has been cancelled."
		return
	fi

	# 格式化分区
echo "Format partition /dev/$PARTITION to $FS_TYPE..."
	mkfs.$FS_TYPE "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
echo "Partition formatting successfully!"
	else
echo "Partition formatting failed!"
	fi
}

# 检查分区状态
check_partition() {
	send_stats "检查分区状态"
	read -p "请输入要检查的分区名称（例如 sda1）: " PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
echo "The partition does not exist!"
		return
	fi

	# 检查分区状态
echo "Check the status of partition /dev/$PARTITION:"
	fsck "/dev/$PARTITION"
}

# 主菜单
disk_manager() {
	send_stats "硬盘管理功能"
	while true; do
		clear
echo "Hard disk partition management"
echo -e "${gl_huang}This function is internally tested, please do not use it in production environment. ${gl_bai}"
		echo "------------------------"
		list_partitions
		echo "------------------------"
echo "1. Mount the partition 2. Uninstall the partition 3. View mounted partition"
echo "4. Format the partition 5. Check the partition status"
		echo "------------------------"
echo "0. Return to previous menu"
		echo "------------------------"
		read -p "请输入你的选择: " choice
		case $choice in
			1) mount_partition ;;
			2) unmount_partition ;;
			3) list_mounted_partitions ;;
			4) format_partition ;;
			5) check_partition ;;
			*) break ;;
		esac
		read -p "按回车键继续..."
	done
}




# 显示任务列表
list_tasks() {
echo "Saved Sync Tasks:"
	echo "---------------------------------"
	awk -F'|' '{print NR " - " $1 " ( " $2 " -> " $3":"$4 " )"}' "$CONFIG_FILE"
	echo "---------------------------------"
}

# 添加新任务
add_task() {
	send_stats "添加新同步任务"
echo "Create a new synchronization task example:"
echo " - Task name: backup_www"
echo " - Local Directory: /var/www"
echo " - Remote address: user@192.168.1.100"
echo " - Remote Directory: /backup/www"
echo " - Port number (default 22)"
	echo "---------------------------------"
	read -e -p "请输入任务名称: " name
	read -e -p "请输入本地目录: " local_path
	read -e -p "请输入远程目录: " remote_path
	read -e -p "请输入远程用户@IP: " remote
	read -e -p "请输入 SSH 端口 (默认 22): " port
	port=${port:-22}

echo "Please select authentication method:"
echo "1. Password"
echo "2. Key"
	read -e -p "请选择 (1/2): " auth_choice

	case $auth_choice in
		1)
			read -s -p "请输入密码: " password_or_key
echo  # Line break
			auth_method="password"
			;;
		2)
echo "Please paste the key content (press press Enter twice after pasting):"
			local password_or_key=""
			while IFS= read -r line; do
				# 如果输入为空行且密钥内容已经包含了开头，则结束输入
				if [[ -z "$line" && "$password_or_key" == *"-----BEGIN"* ]]; then
					break
				fi
				# 如果是第一行或已经开始输入密钥内容，则继续添加
				if [[ -n "$line" || "$password_or_key" == *"-----BEGIN"* ]]; then
					password_or_key+="${line}"$'\n'
				fi
			done

			# 检查是否是密钥内容
			if [[ "$password_or_key" == *"-----BEGIN"* && "$password_or_key" == *"PRIVATE KEY-----"* ]]; then
				local key_file="$KEY_DIR/${name}_sync.key"
				echo -n "$password_or_key" > "$key_file"
				chmod 600 "$key_file"
				password_or_key="$key_file"
				auth_method="key"
			else
echo "Invalid key content!"
				return
			fi
			;;
		*)
echo "Invalid choice!"
			return
			;;
	esac

echo "Please select the synchronization mode:"
echo "1. Standard Mode (-avz)"
echo "2. Delete the target file (-avz --delete)"
	read -e -p "请选择 (1/2): " mode
	case $mode in
		1) options="-avz" ;;
		2) options="-avz --delete" ;;
		*) echo "无效选择，使用默认 -avz"; options="-avz" ;;
	esac

	echo "$name|$local_path|$remote|$remote_path|$port|$options|$auth_method|$password_or_key" >> "$CONFIG_FILE"

	install rsync rsync

echo "The task has been saved!"
}

# 删除任务
delete_task() {
	send_stats "删除同步任务"
	read -e -p "请输入要删除的任务编号: " num

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
echo "Error: The corresponding task was not found."
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<< "$task"

	# 如果任务使用的是密钥文件，则删除该密钥文件
	if [[ "$auth_method" == "key" && "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
echo "Task deleted!"
}


run_task() {
	send_stats "执行同步任务"

	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	# 解析参数
	local direction="push"  # 默认是推送到远端
	local num

	if [[ "$1" == "push" || "$1" == "pull" ]]; then
		direction="$1"
		num="$2"
	else
		num="$1"
	fi

	# 如果没有传入任务编号，提示用户输入
	if [[ -z "$num" ]]; then
		read -e -p "请输入要执行的任务编号: " num
	fi

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
echo "Error: The task was not found!"
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<< "$task"

	# 根据同步方向调整源和目标路径
	if [[ "$direction" == "pull" ]]; then
echo "Pulling synchronization to local: $remote:$local_path -> $remote_path"
		source="$remote:$local_path"
		destination="$remote_path"
	else
echo "Pusing synchronization to remote: $local_path -> $remote:$remote_path"
		source="$local_path"
		destination="$remote:$remote_path"
	fi

	# 添加 SSH 连接通用参数
	local ssh_options="-p $port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

	if [[ "$auth_method" == "password" ]]; then
		if ! command -v sshpass &> /dev/null; then
echo "Error: sshpass is not installed, please install sshpass first."
echo "Installation method:"
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" rsync $options -e "ssh $ssh_options" "$source" "$destination"
	else
		# 检查密钥文件是否存在和权限是否正确
		if [[ ! -f "$password_or_key" ]]; then
echo "Error: The key file does not exist: $password_or_key"
			return
		fi

		if [[ "$(stat -c %a "$password_or_key")" != "600" ]]; then
echo "Warning: The key file permissions are incorrect, repairing..."
			chmod 600 "$password_or_key"
		fi

		rsync $options -e "ssh -i $password_or_key $ssh_options" "$source" "$destination"
	fi

	if [[ $? -eq 0 ]]; then
echo "Synchronous completion!"
	else
echo "Synchronization failed! Please check the following:"
echo "1. Is the network connection normal?"
echo "2. Is the remote host accessible?"
echo "3. Is the authentication information correct?"
echo "4. Are there correct access rights for local and remote directories"
	fi
}


# 创建定时任务
schedule_task() {
	send_stats "添加同步定时任务"

	read -e -p "请输入要定时同步的任务编号: " num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
echo "Error: Please enter a valid task number!"
		return
	fi

echo "Please select the timed execution interval:"
echo "1) Execute once per hour"
echo "2) Perform once a day"
echo "3) Execute once a week"
	read -e -p "请输入选项 (1/2/3): " interval

	local random_minute=$(shuf -i 0-59 -n 1)  # 生成 0-59 之间的随机分钟数
	local cron_time=""
	case "$interval" in
		1) cron_time="$random_minute * * * *" ;;  # 每小时，随机分钟执行
		2) cron_time="$random_minute 0 * * *" ;;  # 每天，随机分钟执行
		3) cron_time="$random_minute 0 * * 1" ;;  # 每周，随机分钟执行
		*) echo "错误: 请输入有效的选项！" ; return ;;
	esac

	local cron_job="$cron_time k rsync_run $num"
	local cron_job="$cron_time k rsync_run $num"

	# 检查是否已存在相同任务
	if crontab -l | grep -q "k rsync_run $num"; then
echo "Error: The timing synchronization of this task already exists!"
		return
	fi

	# 创建到用户的 crontab
	(crontab -l 2>/dev/null; echo "$cron_job") | crontab -
echo "Timed task has been created: $cron_job"
}

# 查看定时任务
view_tasks() {
echo "Current timing task:"
	echo "---------------------------------"
	crontab -l | grep "k rsync_run"
	echo "---------------------------------"
}

# 删除定时任务
delete_task_schedule() {
	send_stats "删除同步定时任务"
	read -e -p "请输入要删除的任务编号: " num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
echo "Error: Please enter a valid task number!"
		return
	fi

	crontab -l | grep -v "k rsync_run $num" | crontab -
echo "Timed tasks with task number $num deleted"
}


# 任务管理主菜单
rsync_manager() {
	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	while true; do
		clear
echo "Rsync Remote Synchronization Tool"
echo "Synchronization between remote directories supports incremental synchronization, efficient and stable."
		echo "---------------------------------"
		list_tasks
		echo
		view_tasks
		echo
echo "1. Create a new task 2. Delete a task"
echo "3. Perform local synchronization to the remote end 4. Perform remote synchronization to the local end"
echo "5. Create a timing task 6. Delete a timing task"
		echo "---------------------------------"
echo "0. Return to previous menu"
		echo "---------------------------------"
		read -e -p "请输入你的选择: " choice
		case $choice in
			1) add_task ;;
			2) delete_task ;;
			3) run_task push;;
			4) run_task pull;;
			5) schedule_task ;;
			6) delete_task_schedule ;;
			0) break ;;
			*) echo "无效的选择，请重试。" ;;
		esac
		read -p "按回车键继续..."
	done
}









linux_ps() {

	clear
	send_stats "系统信息查询"

	ip_address

	local cpu_info=$(lscpu | awk -F': +' '/Model name:/ {print $2; exit}')

	local cpu_usage_percent=$(awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else printf "%.0f\n", (($2+$4-u1) * 100 / (t-t1))}' \
		<(grep 'cpu ' /proc/stat) <(sleep 1; grep 'cpu ' /proc/stat))

	local cpu_cores=$(nproc)

	local cpu_freq=$(cat /proc/cpuinfo | grep "MHz" | head -n 1 | awk '{printf "%.1f GHz\n", $4/1000}')

	local mem_info=$(free -b | awk 'NR==2{printf "%.2f/%.2fM (%.2f%%)", $3/1024/1024, $2/1024/1024, $3*100/$2}')

	local disk_info=$(df -h | awk '$NF=="/"{printf "%s/%s (%s)", $3, $2, $5}')

	local ipinfo=$(curl -s ipinfo.io)
	local country=$(echo "$ipinfo" | grep 'country' | awk -F': ' '{print $2}' | tr -d '",')
	local city=$(echo "$ipinfo" | grep 'city' | awk -F': ' '{print $2}' | tr -d '",')
	local isp_info=$(echo "$ipinfo" | grep 'org' | awk -F': ' '{print $2}' | tr -d '",')

	local load=$(uptime | awk '{print $(NF-2), $(NF-1), $NF}')
	local dns_addresses=$(awk '/^nameserver/{printf "%s ", $2} END {print ""}' /etc/resolv.conf)


	local cpu_arch=$(uname -m)

	local hostname=$(uname -n)

	local kernel_version=$(uname -r)

	local congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
	local queue_algorithm=$(sysctl -n net.core.default_qdisc)

	local os_info=$(grep PRETTY_NAME /etc/os-release | cut -d '=' -f2 | tr -d '"')

	output_status

	local current_time=$(date "+%Y-%m-%d %I:%M %p")


	local swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}')

	local runtime=$(cat /proc/uptime | awk -F. '{run_days=int($1 / 86400);run_hours=int(($1 % 86400) / 3600);run_minutes=int(($1 % 3600) / 60); if (run_days > 0) printf("%d天 ", run_days); if (run_hours > 0) printf("%d时 ", run_hours); printf("%d分\n", run_minutes)}')

	local timezone=$(current_timezone)


	echo ""
echo -e "System Information Query"
	echo -e "${gl_kjlan}-------------"
echo -e "${gl_kjlan}hostname: ${gl_bai}$hostname"
echo -e "${gl_kjlan} system version: ${gl_bai}$os_info"
echo -e "${gl_kjlan}Linux version: ${gl_bai}$kernel_version"
	echo -e "${gl_kjlan}-------------"
echo -e "${gl_kjlan}CPU stack: ${gl_bai}$cpu_arch"
echo -e "${gl_kjlan}CPU type number: ${gl_bai}$cpu_info"
echo -e "${gl_kjlan}CPU cores: ${gl_bai}$cpu_cores"
echo -e "${gl_kjlan}CPUFactor Rate: ${gl_bai}$cpu_freq"
	echo -e "${gl_kjlan}-------------"
echo -e "${gl_kjlan}CPU占用:      ${gl_bai}$cpu_usage_percent%"
echo -e "${gl_kjlan} system load: ${gl_bai}$load"
echo -e "${gl_kjlan}Physical memory: ${gl_bai}$mem_info"
echo -e "${gl_kjlan}Virtual memory: ${gl_bai}$swap_info"
echo -e "${gl_kjlan}hard disk occupancy: ${gl_bai}$disk_info"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}$output"
	echo -e "${gl_kjlan}-------------"
echo -e "${gl_kjlan}Network Algorithm: ${gl_bai}$congestion_algorithm $queue_algorithm"
	echo -e "${gl_kjlan}-------------"
echo -e "${gl_kjlan}operator: ${gl_bai}$isp_info"
	if [ -n "$ipv4_address" ]; then
echo -e "$ {GL_KJLAN} ipv4 地址: $ {gl_bai} $ ipv4_address"
	fi

	if [ -n "$ipv6_address" ]; then
echo -e "$ {GL_KJLAN} ipv6 地址: $ {gl_bai} $ ipv6_address"
	fi
echo -e "${gl_kjlan}DNS地址:      ${gl_bai}$dns_addresses"
echo -e "${gl_kjlan}Geolocation: ${gl_bai}$country $city"
echo -e "${gl_kjlan}System time: ${gl_bai}$timezone $current_time"
	echo -e "${gl_kjlan}-------------"
echo -e "${gl_kjlan}runtime: ${gl_bai}$runtime"
	echo



}



linux_tools() {

  while true; do
	  clear
	  # send_stats "基础工具"
echo -e "Basic Tools"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}1. ${gl_bai}curl Download Tool ${gl_huang}★${gl_bai} ${gl_kjlan}2. ${gl_bai}wget Download Tool ${gl_huang}★${gl_bai}"
echo -e "${gl_kjlan}3. ${gl_bai}sudo Super Management Permission Tool ${gl_kjlan}4. ${gl_bai}socat Communication Connection Tool"
echo -e "${gl_kjlan}5. ${gl_bai}htop System Monitoring Tool ${gl_kjlan}6. ${gl_bai}iftop Network Traffic Monitoring Tool"
echo -e "${gl_kjlan}7. ${gl_bai}unzip ZIP compression and decompression tool ${gl_kjlan}8. ${gl_bai}tar GZ compression and decompression tool"
echo -e "${gl_kjlan}9. ${gl_bai}tmux multi-channel background running tool ${gl_kjlan}10. ${gl_bai}ffmpeg video encoding live streaming tool"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}11. ${gl_bai}btop Modern monitoring tool ${gl_huang}★${gl_bai} ${gl_kjlan}12. ${gl_bai}ranger File Management Tool"
echo -e "${gl_kjlan}13. ${gl_bai}ncdu Disk occupancy viewing tool ${gl_kjlan}14. ${gl_bai}fzf Global Search Tool"
echo -e "${gl_kjlan}15. ${gl_bai}vim Text Editor ${gl_kjlan}16. ${gl_bai}nano Text Editor ${gl_huang}★${gl_bai}"
echo -e "${gl_kjlan}17. ${gl_bai}git version control system"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}21. ${gl_bai}Matrix Screensaver ${gl_kjlan}22. ${gl_bai}Sports Screensaver"
echo -e "${gl_kjlan}26. ${gl_bai}tetris game ${gl_kjlan}27. ${gl_bai}snake game"
echo -e "${gl_kjlan}28. ${gl_bai}Space Invader Game"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}31. ${gl_bai}all installation ${gl_kjlan}32. ${gl_bai}all installation (excluding screen savers and games)${gl_huang}★${gl_bai}"
echo -e "${gl_kjlan}33. ${gl_bai} uninstall all"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}41. ${gl_bai}install the specified tool ${gl_kjlan}42. ${gl_bai}uninstall the specified tool"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}0. ${gl_bai} returns to main menu"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "请输入你的选择: " sub_choice

	  case $sub_choice in
		  1)
			  clear
			  install curl
			  clear
echo "The tool has been installed, and the usage is as follows:"
			  curl --help
			  send_stats "安装curl"
			  ;;
		  2)
			  clear
			  install wget
			  clear
echo "The tool has been installed, and the usage is as follows:"
			  wget --help
			  send_stats "安装wget"
			  ;;
			3)
			  clear
			  install sudo
			  clear
echo "The tool has been installed, and the usage is as follows:"
			  sudo --help
			  send_stats "安装sudo"
			  ;;
			4)
			  clear
			  install socat
			  clear
echo "The tool has been installed, and the usage is as follows:"
			  socat -h
			  send_stats "安装socat"
			  ;;
			5)
			  clear
			  install htop
			  clear
			  htop
			  send_stats "安装htop"
			  ;;
			6)
			  clear
			  install iftop
			  clear
			  iftop
			  send_stats "安装iftop"
			  ;;
			7)
			  clear
			  install unzip
			  clear
echo "The tool has been installed, and the usage is as follows:"
			  unzip
			  send_stats "安装unzip"
			  ;;
			8)
			  clear
			  install tar
			  clear
echo "The tool has been installed, and the usage is as follows:"
			  tar --help
			  send_stats "安装tar"
			  ;;
			9)
			  clear
			  install tmux
			  clear
echo "The tool has been installed, and the usage is as follows:"
			  tmux --help
			  send_stats "安装tmux"
			  ;;
			10)
			  clear
			  install ffmpeg
			  clear
echo "The tool has been installed, and the usage is as follows:"
			  ffmpeg --help
			  send_stats "安装ffmpeg"
			  ;;

			11)
			  clear
			  install btop
			  clear
			  btop
			  send_stats "安装btop"
			  ;;
			12)
			  clear
			  install ranger
			  cd /
			  clear
			  ranger
			  cd ~
			  send_stats "安装ranger"
			  ;;
			13)
			  clear
			  install ncdu
			  cd /
			  clear
			  ncdu
			  cd ~
			  send_stats "安装ncdu"
			  ;;
			14)
			  clear
			  install fzf
			  cd /
			  clear
			  fzf
			  cd ~
			  send_stats "安装fzf"
			  ;;
			15)
			  clear
			  install vim
			  cd /
			  clear
			  vim -h
			  cd ~
			  send_stats "安装vim"
			  ;;
			16)
			  clear
			  install nano
			  cd /
			  clear
			  nano -h
			  cd ~
			  send_stats "安装nano"
			  ;;


			17)
			  clear
			  install git
			  cd /
			  clear
			  git --help
			  cd ~
			  send_stats "安装git"
			  ;;

			21)
			  clear
			  install cmatrix
			  clear
			  cmatrix
			  send_stats "安装cmatrix"
			  ;;
			22)
			  clear
			  install sl
			  clear
			  sl
			  send_stats "安装sl"
			  ;;
			26)
			  clear
			  install bastet
			  clear
			  bastet
			  send_stats "安装bastet"
			  ;;
			27)
			  clear
			  install nsnake
			  clear
			  nsnake
			  send_stats "安装nsnake"
			  ;;
			28)
			  clear
			  install ninvaders
			  clear
			  ninvaders
			  send_stats "安装ninvaders"
			  ;;

		  31)
			  clear
			  send_stats "全部安装"
			  install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders vim nano git
			  ;;

		  32)
			  clear
			  send_stats "全部安装（不含游戏和屏保）"
			  install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf vim nano git
			  ;;


		  33)
			  clear
			  send_stats "全部卸载"
			  remove htop iftop tmux ffmpeg btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders vim nano git
			  ;;

		  41)
			  clear
			  read -e -p "请输入安装的工具名（wget curl sudo htop）: " installname
			  install $installname
			  send_stats "安装指定软件"
			  ;;
		  42)
			  clear
			  read -e -p "请输入卸载的工具名（htop ufw tmux cmatrix）: " removename
			  remove $removename
			  send_stats "卸载指定软件"
			  ;;

		  0)
			  kejilion
			  ;;

		  *)
echo "Invalid input!"
			  ;;
	  esac
	  break_end
  done




}


linux_bbr() {
	clear
	send_stats "bbr管理"
	if [ -f "/etc/alpine-release" ]; then
		while true; do
			  clear
			  local congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
			  local queue_algorithm=$(sysctl -n net.core.default_qdisc)
echo "Current TCP blocking algorithm: $congestion_algorithm $queue_algorithm"

			  echo ""
echo "BBR Management"
			  echo "------------------------"
echo "1. Turn on BBRv3 2. Turn off BBRv3 (restarts)"
			  echo "------------------------"
echo "0. Return to previous menu"
			  echo "------------------------"
			  read -e -p "请输入你的选择: " sub_choice

			  case $sub_choice in
				  1)
					bbr_on
					send_stats "alpine开启bbr3"
					  ;;
				  2)
					sed -i '/net.ipv4.tcp_congestion_control=bbr/d' /etc/sysctl.conf
					sysctl -p
					server_reboot
					  ;;
				  *)
					  break  # 跳出循环，退出菜单
					  ;;

			  esac
		done
	else
		install wget
		wget --no-check-certificate -O tcpx.sh ${gh_proxy}raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcpx.sh
		chmod +x tcpx.sh
		./tcpx.sh
	fi


}





linux_docker() {

	while true; do
	  clear
	  # send_stats "docker管理"
echo -e "Docker Management"
	  docker_tato
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}1. ${gl_bai}install and update Docker environment ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}2. ${gl_bai}View Docker global status ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}3. ${gl_bai}Docker container management ${gl_huang}★${gl_bai}"
echo -e "${gl_kjlan}4. ${gl_bai}Docker image management"
echo -e "${gl_kjlan}5. ${gl_bai}Docker Network Management"
echo -e "${gl_kjlan}6. ${gl_bai}Docker volume management"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}7. ${gl_bai}Clean useless docker containers and mirror network data volumes"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}8. ${gl_bai}Replace Docker source"
echo -e "${gl_kjlan}9. ${gl_bai}edit daemon.json file"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}11. ${gl_bai} enable Docker-ipv6 access"
echo -e "${gl_kjlan}12. ${gl_bai}Close Docker-ipv6 access"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}20. ${gl_bai}Uninstall Docker environment"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}0. ${gl_bai} returns to main menu"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "请输入你的选择: " sub_choice

	  case $sub_choice in
		  1)
			clear
			send_stats "安装docker环境"
			install_add_docker

			  ;;
		  2)
			  clear
			  local container_count=$(docker ps -a -q 2>/dev/null | wc -l)
			  local image_count=$(docker images -q 2>/dev/null | wc -l)
			  local network_count=$(docker network ls -q 2>/dev/null | wc -l)
			  local volume_count=$(docker volume ls -q 2>/dev/null | wc -l)

			  send_stats "docker全局状态"
echo "Docker Version"
			  docker -v
			  docker compose version

			  echo ""
echo -e "Docker image: ${gl_lv}$image_count${gl_bai}"
			  docker image ls
			  echo ""
echo -e "Docker container: ${gl_lv}$container_count${gl_bai}"
			  docker ps -a
			  echo ""
echo -e "Docker卷: ${gl_lv}$volume_count${gl_bai}"
			  docker volume ls
			  echo ""
echo -e "Docker Network: ${gl_lv}$network_count${gl_bai}"
			  docker network ls
			  echo ""

			  ;;
		  3)
			  docker_ps
			  ;;
		  4)
			  docker_image
			  ;;

		  5)
			  while true; do
				  clear
				  send_stats "Docker网络管理"
echo "Docker Network List"
				  echo "------------------------------------------------------------"
				  docker network ls
				  echo ""

				  echo "------------------------------------------------------------"
				  container_ids=$(docker ps -q)
				  printf "%-25s %-25s %-25s\n" "容器名称" "网络名称" "IP地址"

				  for container_id in $container_ids; do
					  local container_info=$(docker inspect --format '{{ .Name }}{{ range $network, $config := .NetworkSettings.Networks }} {{ $network }} {{ $config.IPAddress }}{{ end }}' "$container_id")

					  local container_name=$(echo "$container_info" | awk '{print $1}')
					  local network_info=$(echo "$container_info" | cut -d' ' -f2-)

					  while IFS= read -r line; do
						  local network_name=$(echo "$line" | awk '{print $1}')
						  local ip_address=$(echo "$line" | awk '{print $2}')

						  printf "%-20s %-20s %-15s\n" "$container_name" "$network_name" "$ip_address"
					  done <<< "$network_info"
				  done

				  echo ""
echo "Network Operation"
				  echo "------------------------"
echo "1. Create a network"
echo "2. Join the Internet"
echo "3. Exit the network"
echo "4. Delete the network"
				  echo "------------------------"
echo "0. Return to previous menu"
				  echo "------------------------"
				  read -e -p "请输入你的选择: " sub_choice

				  case $sub_choice in
					  1)
						  send_stats "创建网络"
						  read -e -p "设置新网络名: " dockernetwork
						  docker network create $dockernetwork
						  ;;
					  2)
						  send_stats "加入网络"
						  read -e -p "加入网络名: " dockernetwork
						  read -e -p "那些容器加入该网络（多个容器名请用空格分隔）: " dockernames

						  for dockername in $dockernames; do
							  docker network connect $dockernetwork $dockername
						  done
						  ;;
					  3)
						  send_stats "加入网络"
						  read -e -p "退出网络名: " dockernetwork
						  read -e -p "那些容器退出该网络（多个容器名请用空格分隔）: " dockernames

						  for dockername in $dockernames; do
							  docker network disconnect $dockernetwork $dockername
						  done

						  ;;

					  4)
						  send_stats "删除网络"
						  read -e -p "请输入要删除的网络名: " dockernetwork
						  docker network rm $dockernetwork
						  ;;

					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done
			  ;;

		  6)
			  while true; do
				  clear
				  send_stats "Docker卷管理"
echo "Docker volume list"
				  docker volume ls
				  echo ""
echo "Volume Operation"
				  echo "------------------------"
echo "1. Create a new volume"
echo "2. Delete the specified volume"
echo "3. Delete all volumes"
				  echo "------------------------"
echo "0. Return to previous menu"
				  echo "------------------------"
				  read -e -p "请输入你的选择: " sub_choice

				  case $sub_choice in
					  1)
						  send_stats "新建卷"
						  read -e -p "设置新卷名: " dockerjuan
						  docker volume create $dockerjuan

						  ;;
					  2)
						  read -e -p "输入删除卷名（多个卷名请用空格分隔）: " dockerjuans

						  for dockerjuan in $dockerjuans; do
							  docker volume rm $dockerjuan
						  done

						  ;;

					   3)
						  send_stats "删除所有卷"
						  read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有未使用的卷吗？(Y/N): ")" choice
						  case "$choice" in
							[Yy])
							  docker volume prune -f
							  ;;
							[Nn])
							  ;;
							*)
echo "Invalid selection, please enter Y or N."
							  ;;
						  esac
						  ;;

					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done
			  ;;
		  7)
			  clear
			  send_stats "Docker清理"
			  read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}将清理无用的镜像容器网络，包括停止的容器，确定清理吗？(Y/N): ")" choice
			  case "$choice" in
				[Yy])
				  docker system prune -af --volumes
				  ;;
				[Nn])
				  ;;
				*)
echo "Invalid selection, please enter Y or N."
				  ;;
			  esac
			  ;;
		  8)
			  clear
			  send_stats "Docker源"
			  bash <(curl -sSL https://linuxmirrors.cn/docker.sh)
			  ;;

		  9)
			  clear
			  install nano
			  mkdir -p /etc/docker && nano /etc/docker/daemon.json
			  restart docker
			  ;;

		  11)
			  clear
			  send_stats "Docker v6 开"
			  docker_ipv6_on
			  ;;

		  12)
			  clear
			  send_stats "Docker v6 关"
			  docker_ipv6_off
			  ;;

		  20)
			  clear
			  send_stats "Docker卸载"
			  read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定卸载docker环境吗？(Y/N): ")" choice
			  case "$choice" in
				[Yy])
				  docker ps -a -q | xargs -r docker rm -f && docker images -q | xargs -r docker rmi && docker network prune -f && docker volume prune -f
				  remove docker docker-compose docker-ce docker-ce-cli containerd.io
				  rm -f /etc/docker/daemon.json
				  hash -r
				  ;;
				[Nn])
				  ;;
				*)
echo "Invalid selection, please enter Y or N."
				  ;;
			  esac
			  ;;

		  0)
			  kejilion
			  ;;
		  *)
echo "Invalid input!"
			  ;;
	  esac
	  break_end


	done


}



linux_test() {

	while true; do
	  clear
	  # send_stats "测试脚本合集"
echo -e "Test script collection"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}IP and unlock status detection"
echo -e "${gl_kjlan}1. ${gl_bai}ChatGPT Unlocked Status Detection"
echo -e "${gl_kjlan}2. ${gl_bai}Region Streaming Media Unlock Test"
echo -e "${gl_kjlan}3. ${gl_bai}yeahwu Streaming Media Unlock Detection"
echo -e "${gl_kjlan}4. ${gl_bai}xykt IP quality physical examination script ${gl_huang}★${gl_bai}"

	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}Network Line Speed ​​Test"
echo -e "${gl_kjlan}11. ${gl_bai}besttrace Three-network backhaul delay routing test"
echo -e "${gl_kjlan}12. ${gl_bai}mtr_trace Three-net backhaul line test"
echo -e "${gl_kjlan}13. ${gl_bai}Superspeed three-net speed test"
echo -e "${gl_kjlan}14. ${gl_bai}nxtrace fast backhaul test script"
echo -e "${gl_kjlan}15. ${gl_bai}nxtrace Specifies IP backhaul test script"
echo -e "${gl_kjlan}16. ${gl_bai}ludashi2020 Three-network line test"
echo -e "${gl_kjlan}17. ${gl_bai}i-abc multifunction speed test script"
echo -e "${gl_kjlan}18. ${gl_bai}NetQuality Network Quality Physical Examination Script ${gl_huang}★${gl_bai}"

	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}hardware performance test"
echo -e "${gl_kjlan}21. ${gl_bai}yabs performance test"
echo -e "${gl_kjlan}22. ${gl_bai}icu/gb5 CPU performance test script"

	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}comprehensive test"
echo -e "${gl_kjlan}31. ${gl_bai}bench performance test"
echo -e "${gl_kjlan}32. ${gl_bai}spiritsdx Fusion Monster Evaluation ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}0. ${gl_bai} returns to main menu"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "请输入你的选择: " sub_choice

	  case $sub_choice in
		  1)
			  clear
			  send_stats "ChatGPT解锁状态检测"
			  bash <(curl -Ls https://cdn.jsdelivr.net/gh/missuo/OpenAI-Checker/openai.sh)
			  ;;
		  2)
			  clear
			  send_stats "Region流媒体解锁测试"
			  bash <(curl -L -s check.unlock.media)
			  ;;
		  3)
			  clear
			  send_stats "yeahwu流媒体解锁检测"
			  install wget
			  wget -qO- ${gh_proxy}github.com/yeahwu/check/raw/main/check.sh | bash
			  ;;
		  4)
			  clear
			  send_stats "xykt_IP质量体检脚本"
			  bash <(curl -Ls IP.Check.Place)
			  ;;


		  11)
			  clear
			  send_stats "besttrace三网回程延迟路由测试"
			  install wget
			  wget -qO- git.io/besttrace | bash
			  ;;
		  12)
			  clear
			  send_stats "mtr_trace三网回程线路测试"
			  curl ${gh_proxy}raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh | bash
			  ;;
		  13)
			  clear
			  send_stats "Superspeed三网测速"
			  bash <(curl -Lso- https://git.io/superspeed_uxh)
			  ;;
		  14)
			  clear
			  send_stats "nxtrace快速回程测试脚本"
			  curl nxtrace.org/nt |bash
			  nexttrace --fast-trace --tcp
			  ;;
		  15)
			  clear
			  send_stats "nxtrace指定IP回程测试脚本"
echo "Referenced IP List"
			  echo "------------------------"
echo "Beijing Telecom: 219.141.136.12"
echo "Beijing Unicom: 202.106.50.1"
echo "Beijing Mobile: 221.179.155.161"
echo "Shanghai Telecom: 202.96.209.133"
echo "Shanghai Unicom: 210.22.97.1"
echo "Shanghai Mobile: 211.136.112.200"
echo "Guangzhou Telecom: 58.60.188.222"
echo "Guangzhou Unicom: 210.21.196.6"
echo "Guangzhou Mobile: 120.196.165.24"
echo "Chengdu Telecom: 61.139.2.69"
echo "Chengdu Unicom: 119.6.6.6"
echo "Chengdu Mobile: 211.137.96.205"
echo "Hunan Telecom: 36.111.200.100"
echo "Hunan Unicom: 42.48.16.100"
echo "Hunan Mobile: 39.134.254.6"
			  echo "------------------------"

			  read -e -p "输入一个指定IP: " testip
			  curl nxtrace.org/nt |bash
			  nexttrace $testip
			  ;;

		  16)
			  clear
			  send_stats "ludashi2020三网线路测试"
			  curl ${gh_proxy}raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh -sSf | sh
			  ;;

		  17)
			  clear
			  send_stats "i-abc多功能测速脚本"
			  bash <(curl -sL ${gh_proxy}raw.githubusercontent.com/i-abc/Speedtest/main/speedtest.sh)
			  ;;

		  18)
			  clear
			  send_stats "网络质量测试脚本"
			  bash <(curl -sL Net.Check.Place)
			  ;;

		  21)
			  clear
			  send_stats "yabs性能测试"
			  check_swap
			  curl -sL yabs.sh | bash -s -- -i -5
			  ;;
		  22)
			  clear
			  send_stats "icu/gb5 CPU性能测试脚本"
			  check_swap
			  bash <(curl -sL bash.icu/gb5)
			  ;;

		  31)
			  clear
			  send_stats "bench性能测试"
			  curl -Lso- bench.sh | bash
			  ;;
		  32)
			  send_stats "spiritysdx融合怪测评"
			  clear
			  curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh
			  ;;

		  0)
			  kejilion

			  ;;
		  *)
echo "Invalid input!"
			  ;;
	  esac
	  break_end

	done


}


linux_Oracle() {


	 while true; do
	  clear
	  send_stats "甲骨文云脚本合集"
echo -e "Oracle Cloud Script Collection"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}1. ${gl_bai}installs idle machine active script"
echo -e "${gl_kjlan}2. ${gl_bai}Uninstalling the idle machine active script"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}3. ${gl_bai}DD reinstall system script"
echo -e "${gl_kjlan}4. ${gl_bai}R Detective Startup Script"
echo -e "${gl_kjlan}5. ${gl_bai} enable ROOT password login mode"
echo -e "${gl_kjlan}6. ${gl_bai}IPV6 recovery tool"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}0. ${gl_bai} returns to main menu"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "请输入你的选择: " sub_choice

	  case $sub_choice in
		  1)
			  clear
echo "Active script: CPU occupies 10-20% memory occupies 20%"
			  read -e -p "确定安装吗？(Y/N): " choice
			  case "$choice" in
				[Yy])

				  install_docker

				  # 设置默认值
				  local DEFAULT_CPU_CORE=1
				  local DEFAULT_CPU_UTIL="10-20"
				  local DEFAULT_MEM_UTIL=20
				  local DEFAULT_SPEEDTEST_INTERVAL=120

				  # 提示用户输入CPU核心数和占用百分比，如果回车则使用默认值
				  read -e -p "请输入CPU核心数 [默认: $DEFAULT_CPU_CORE]: " cpu_core
				  local cpu_core=${cpu_core:-$DEFAULT_CPU_CORE}

				  read -e -p "请输入CPU占用百分比范围（例如10-20） [默认: $DEFAULT_CPU_UTIL]: " cpu_util
				  local cpu_util=${cpu_util:-$DEFAULT_CPU_UTIL}

				  read -e -p "请输入内存占用百分比 [默认: $DEFAULT_MEM_UTIL]: " mem_util
				  local mem_util=${mem_util:-$DEFAULT_MEM_UTIL}

				  read -e -p "请输入Speedtest间隔时间（秒） [默认: $DEFAULT_SPEEDTEST_INTERVAL]: " speedtest_interval
				  local speedtest_interval=${speedtest_interval:-$DEFAULT_SPEEDTEST_INTERVAL}

				  # 运行Docker容器
				  docker run -itd --name=lookbusy --restart=always \
					  -e TZ=Asia/Shanghai \
					  -e CPU_UTIL="$cpu_util" \
					  -e CPU_CORE="$cpu_core" \
					  -e MEM_UTIL="$mem_util" \
					  -e SPEEDTEST_INTERVAL="$speedtest_interval" \
					  fogforest/lookbusy
				  send_stats "甲骨文云安装活跃脚本"

				  ;;
				[Nn])

				  ;;
				*)
echo "Invalid selection, please enter Y or N."
				  ;;
			  esac
			  ;;
		  2)
			  clear
			  docker rm -f lookbusy
			  docker rmi fogforest/lookbusy
			  send_stats "甲骨文云卸载活跃脚本"
			  ;;

		  3)
		  clear
echo "Reinstall the system"
		  echo "--------------------------------"
echo -e "${gl_hong}Note: ${gl_bai} has the risk of losing contact when reinstalling. Those who are not satisfied with it are used with caution. Reinstalling is expected to take 15 minutes, please back up the data in advance."
		  read -e -p "确定继续吗？(Y/N): " choice

		  case "$choice" in
			[Yy])
			  while true; do
				read -e -p "请选择要重装的系统:  1. Debian12 | 2. Ubuntu20.04 : " sys_choice

				case "$sys_choice" in
				  1)
					local xitong="-d 12"
					break  # 结束循环
					;;
				  2)
					local xitong="-u 20.04"
					break  # 结束循环
					;;
				  *)
echo "Invalid selection, please re-enter."
					;;
				esac
			  done

			  read -e -p "请输入你重装后的密码: " vpspasswd
			  install wget
			  bash <(wget --no-check-certificate -qO- "${gh_proxy}raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh") $xitong -v 64 -p $vpspasswd -port 22
			  send_stats "甲骨文云重装系统脚本"
			  ;;
			[Nn])
echo "Canceled"
			  ;;
			*)
echo "Invalid selection, please enter Y or N."
			  ;;
		  esac
			  ;;

		  4)
			  clear
echo "This feature is in development stage, so stay tuned!"
			  ;;
		  5)
			  clear
			  add_sshpasswd

			  ;;
		  6)
			  clear
			  bash <(curl -L -s jhb.ovh/jb/v6.sh)
echo "This feature is provided by the master jhb, thanks!"
			  send_stats "ipv6修复"
			  ;;
		  0)
			  kejilion

			  ;;
		  *)
echo "Invalid input!"
			  ;;
	  esac
	  break_end

	done



}


docker_tato() {

	local container_count=$(docker ps -a -q 2>/dev/null | wc -l)
	local image_count=$(docker images -q 2>/dev/null | wc -l)
	local network_count=$(docker network ls -q 2>/dev/null | wc -l)
	local volume_count=$(docker volume ls -q 2>/dev/null | wc -l)

	if command -v docker &> /dev/null; then
		echo -e "${gl_kjlan}------------------------"
echo -e "${gl_lv} environment has installed ${gl_bai} container: ${gl_lv}$container_count${gl_bai} Mirror: ${gl_lv}$image_count${gl_bai} Network: ${gl_lv}$network_count${gl_bai} Volume: ${gl_lv}$volume_count${gl_bai}"
	fi
}



ldnmp_tato() {
local cert_count=$(ls /home/web/certs/*_cert.pem 2>/dev/null | wc -l)
local output="站点: ${gl_lv}${cert_count}${gl_bai}"

local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml 2>/dev/null | tr -d '[:space:]')
if [ -n "$dbrootpasswd" ]; then
	local db_count=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys" | wc -l)
fi

local db_output="数据库: ${gl_lv}${db_count}${gl_bai}"


if command -v docker &>/dev/null; then
	if docker ps --filter "name=nginx" --filter "status=running" | grep -q nginx; then
		echo -e "${gl_huang}------------------------"
echo -e "${gl_lv} environment has installed ${gl_bai} $output $db_output"
	fi
fi

}


linux_ldnmp() {
  while true; do

	clear
	# send_stats "LDNMP建站"
echo -e "${gl_huang}LDNMP website building"
	ldnmp_tato
	echo -e "${gl_huang}------------------------"
echo -e "${gl_huang}1. ${gl_bai}install LDNMP environment ${gl_huang}★${gl_bai} ${gl_huang}2. ${gl_bai}install WordPress ${gl_huang}★${gl_bai}"
echo -e "${gl_huang}3. ${gl_bai}install Discuz forum ${gl_huang}4. ${gl_bai}install Taodai Cloud Desktop"
echo -e "${gl_huang}5. ${gl_bai}install Apple CMS film and television station ${gl_huang}6. ${gl_bai}install Unicorn Digital Card Network"
echo -e "${gl_huang}7. ${gl_bai}install the flarum forum website ${gl_huang}8. ${gl_bai}install the typecho lightweight blog website"
echo -e "${gl_huang}9. ${gl_bai}install LinkStack Shared Link Platform ${gl_huang}20. ${gl_bai}Customized Dynamic Site"
	echo -e "${gl_huang}------------------------"
echo -e "${gl_huang}21. ${gl_bai} Install nginx only ${gl_huang}★${gl_bai} ${gl_huang}22. ${gl_bai} Site redirection"
echo -e "${gl_huang}23. ${gl_bai} site reverse proxy-IP+port ${gl_huang}★${gl_bai} ${gl_huang}24. ${gl_bai} site reverse proxy-domain name"
echo -e "${gl_huang}25. ${gl_bai}install Bitwarden password management platform ${gl_huang}26. ${gl_bai}install Halo blog website"
echo -e "${gl_huang}27. ${gl_bai}install AI painting prompt word generator ${gl_huang}30. ${gl_bai}custom static site"
	echo -e "${gl_huang}------------------------"
echo -e "${gl_huang}31. ${gl_bai} Site data management ${gl_huang}★${gl_bai} ${gl_huang}32. ${gl_bai} Backup the entire site data"
echo -e "${gl_huang}33. ${gl_bai} timed remote backup ${gl_huang}34. ${gl_bai} restores the entire site data"
	echo -e "${gl_huang}------------------------"
echo -e "${gl_huang}35. ${gl_bai}Protect LDNMP environment ${gl_huang}36. ${gl_bai}Optimize LDNMP environment"
echo -e "${gl_huang}37. ${gl_bai}Update LDNMP environment ${gl_huang}38. ${gl_bai}Uninstall LDNMP environment"
	echo -e "${gl_huang}------------------------"
echo -e "${gl_huang}0. ${gl_bai} returns to main menu"
	echo -e "${gl_huang}------------------------${gl_bai}"
	read -e -p "请输入你的选择: " sub_choice


	case $sub_choice in
	  1)
	  ldnmp_install_status_one
	  ldnmp_install_all
		;;
	  2)
	  ldnmp_wp
		;;

	  3)
	  clear
	  # Discuz论坛
	  webname="Discuz论坛"
	  send_stats "安装$webname"
echo "Start deploy $webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/discuz.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  wget -O latest.zip ${gh_proxy}github.com/kejilion/Website_source_code/raw/main/Discuz_X3.5_SC_UTF8_20240520.zip
	  unzip latest.zip
	  rm latest.zip

	  restart_ldnmp


	  ldnmp_web_on
echo "Database address: mysql"
echo "Database name: $dbname"
echo "Username: $dbuse"
echo "Password: $dbusepasswd"
echo "Table prefix: discuz_"


		;;

	  4)
	  clear
	  # 可道云桌面
	  webname="可道云桌面"
	  send_stats "安装$webname"
echo "Start deploy $webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/kdy.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  wget -O latest.zip ${gh_proxy}github.com/kalcaddle/kodbox/archive/refs/tags/1.50.02.zip
	  unzip -o latest.zip
	  rm latest.zip
	  mv /home/web/html/$yuming/kodbox* /home/web/html/$yuming/kodbox
	  restart_ldnmp

	  ldnmp_web_on
echo "Database address: mysql"
echo "Username: $dbuse"
echo "Password: $dbusepasswd"
echo "Database name: $dbname"
echo "redis host: redis"

		;;

	  5)
	  clear
	  # 苹果CMS
	  webname="苹果CMS"
	  send_stats "安装$webname"
echo "Start deploy $webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/maccms.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  # wget ${gh_proxy}github.com/magicblack/maccms_down/raw/master/maccms10.zip && unzip maccms10.zip && rm maccms10.zip
	  wget ${gh_proxy}github.com/magicblack/maccms_down/raw/master/maccms10.zip && unzip maccms10.zip && mv maccms10-*/* . && rm -r maccms10-* && rm maccms10.zip
	  cd /home/web/html/$yuming/template/ && wget ${gh_proxy}github.com/kejilion/Website_source_code/raw/main/DYXS2.zip && unzip DYXS2.zip && rm /home/web/html/$yuming/template/DYXS2.zip
	  cp /home/web/html/$yuming/template/DYXS2/asset/admin/Dyxs2.php /home/web/html/$yuming/application/admin/controller
	  cp /home/web/html/$yuming/template/DYXS2/asset/admin/dycms.html /home/web/html/$yuming/application/admin/view/system
	  mv /home/web/html/$yuming/admin.php /home/web/html/$yuming/vip.php && wget -O /home/web/html/$yuming/application/extra/maccms.php ${gh_proxy}raw.githubusercontent.com/kejilion/Website_source_code/main/maccms.php

	  restart_ldnmp


	  ldnmp_web_on
echo "Database address: mysql"
echo "Database Port: 3306"
echo "Database name: $dbname"
echo "Username: $dbuse"
echo "Password: $dbusepasswd"
echo "Database prefix: mac_"
	  echo "------------------------"
echo "Login the background address after installation"
	  echo "https://$yuming/vip.php"

		;;

	  6)
	  clear
	  # 独脚数卡
	  webname="独脚数卡"
	  send_stats "安装$webname"
echo "Start deploy $webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/dujiaoka.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  wget ${gh_proxy}github.com/assimon/dujiaoka/releases/download/2.0.6/2.0.6-antibody.tar.gz && tar -zxvf 2.0.6-antibody.tar.gz && rm 2.0.6-antibody.tar.gz

	  restart_ldnmp


	  ldnmp_web_on
echo "Database address: mysql"
echo "Database Port: 3306"
echo "Database name: $dbname"
echo "Username: $dbuse"
echo "Password: $dbusepasswd"
	  echo ""
echo "redis Address: redis"
echo "redis password: not filled in by default"
echo "redis port: 6379"
	  echo ""
echo "Website url: https://$yuming"
echo "Background login path: /admin"
	  echo "------------------------"
echo "Username: admin"
echo "Password: admin"
	  echo "------------------------"
echo "If red error0 appears in the upper right corner when logging in, please use the following command: "
echo "I'm also very angry that the unicorn number card is so troublesome, and there will be such a problem!"
	  echo "sed -i 's/ADMIN_HTTPS=false/ADMIN_HTTPS=true/g' /home/web/html/$yuming/dujiaoka/.env"

		;;

	  7)
	  clear
	  # flarum论坛
	  webname="flarum论坛"
	  send_stats "安装$webname"
echo "Start deploy $webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/flarum.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  docker exec php rm -f /usr/local/etc/php/conf.d/optimized_php.ini

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming

	  docker exec php sh -c "php -r \"copy('https://getcomposer.org/installer', 'composer-setup.php');\""
	  docker exec php sh -c "php composer-setup.php"
	  docker exec php sh -c "php -r \"unlink('composer-setup.php');\""
	  docker exec php sh -c "mv composer.phar /usr/local/bin/composer"

	  docker exec php composer create-project flarum/flarum /var/www/html/$yuming
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require flarum-lang/chinese-simplified"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/polls"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/sitemap"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/oauth"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/best-answer:*"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require v17development/flarum-seo"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require clarkwinkelmann/flarum-ext-emojionearea"


	  restart_ldnmp


	  ldnmp_web_on
echo "Database address: mysql"
echo "Database name: $dbname"
echo "Username: $dbuse"
echo "Password: $dbusepasswd"
echo "Table prefix: flarum_"
echo "Administrator information is set by yourself"

		;;

	  8)
	  clear
	  # typecho
	  webname="typecho"
	  send_stats "安装$webname"
echo "Start deploy $webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/typecho.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  wget -O latest.zip ${gh_proxy}github.com/typecho/typecho/releases/latest/download/typecho.zip
	  unzip latest.zip
	  rm latest.zip

	  restart_ldnmp


	  clear
	  ldnmp_web_on
echo "Database prefix: typecho_"
echo "Database address: mysql"
echo "Username: $dbuse"
echo "Password: $dbusepasswd"
echo "Database name: $dbname"

		;;


	  9)
	  clear
	  # LinkStack
	  webname="LinkStack"
	  send_stats "安装$webname"
echo "Start deploy $webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/refs/heads/main/index_php.conf
	  sed -i "s|/var/www/html/yuming.com/|/var/www/html/yuming.com/linkstack|g" /home/web/conf.d/$yuming.conf
	  sed -i "s|yuming.com|$yuming|g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  wget -O latest.zip ${gh_proxy}github.com/linkstackorg/linkstack/releases/latest/download/linkstack.zip
	  unzip latest.zip
	  rm latest.zip

	  restart_ldnmp


	  clear
	  ldnmp_web_on
echo "Database address: mysql"
echo "Database Port: 3306"
echo "Database name: $dbname"
echo "Username: $dbuse"
echo "Password: $dbusepasswd"
		;;

	  20)
	  clear
	  webname="PHP动态站点"
	  send_stats "安装$webname"
echo "Start deploy $webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/index_php.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming

	  clear
echo -e "[${gl_huang}1/6${gl_bai}] Upload PHP source code"
	  echo "-------------"
echo "At present, only zip-format source code packages are allowed to be uploaded. Please put the source code packages in the /home/web/html/${yuming} directory"
	  read -e -p "也可以输入下载链接，远程下载源码包，直接回车将跳过远程下载： " url_download

	  if [ -n "$url_download" ]; then
		  wget "$url_download"
	  fi

	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  clear
echo -e "[${gl_huang}2/6${gl_bai}] index.php path"
	  echo "-------------"
	  # find "$(realpath .)" -name "index.php" -print
	  find "$(realpath .)" -name "index.php" -print | xargs -I {} dirname {}

	  read -e -p "请输入index.php的路径，类似（/home/web/html/$yuming/wordpress/）： " index_lujing

	  sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
	  sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

	  clear
echo -e "[${gl_huang}3/6${gl_bai}] Please select the PHP version"
	  echo "-------------"
	  read -e -p "1. php最新版 | 2. php7.4 : " pho_v
	  case "$pho_v" in
		1)
		  sed -i "s#php:9000#php:9000#g" /home/web/conf.d/$yuming.conf
		  local PHP_Version="php"
		  ;;
		2)
		  sed -i "s#php:9000#php74:9000#g" /home/web/conf.d/$yuming.conf
		  local PHP_Version="php74"
		  ;;
		*)
echo "Invalid selection, please re-enter."
		  ;;
	  esac


	  clear
echo -e "[${gl_huang}4/6${gl_bai}] Install the specified extension"
	  echo "-------------"
echo "Assembled Extensions"
	  docker exec php php -m

	  read -e -p "$(echo -e "输入需要安装的扩展名称，如 ${gl_huang}SourceGuardian imap ftp${gl_bai} 等等。直接回车将跳过安装 ： ")" php_extensions
	  if [ -n "$php_extensions" ]; then
		  docker exec $PHP_Version install-php-extensions $php_extensions
	  fi


	  clear
echo -e "[${gl_huang}5/6${gl_bai}] Edit site configuration"
	  echo "-------------"
echo "Press any key to continue, and you can set the site configuration in detail, such as pseudo-static contents."
	  read -n 1 -s -r -p ""
	  install nano
	  nano /home/web/conf.d/$yuming.conf


	  clear
echo -e "[${gl_huang}6/6${gl_bai}] Database Management"
	  echo "-------------"
	  read -e -p "1. 我搭建新站        2. 我搭建老站有数据库备份： " use_db
	  case $use_db in
		  1)
			  echo
			  ;;
		  2)
echo "The database backup must be a compressed package ending with .gz. Please put it in the /home/ directory to support the import of pagoda/1panel backup data."
			  read -e -p "也可以输入下载链接，远程下载备份数据，直接回车将跳过远程下载： " url_download_db

			  cd /home/
			  if [ -n "$url_download_db" ]; then
				  wget "$url_download_db"
			  fi
			  gunzip $(ls -t *.gz | head -n 1)
			  latest_sql=$(ls -t *.sql | head -n 1)
			  dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
			  docker exec -i mysql mysql -u root -p"$dbrootpasswd" $dbname < "/home/$latest_sql"
echo "Table data imported by database"
			  docker exec -i mysql mysql -u root -p"$dbrootpasswd" -e "USE $dbname; SHOW TABLES;"
			  rm -f *.sql
echo "Database import completed"
			  ;;
		  *)
			  echo
			  ;;
	  esac

	  restart_ldnmp
	  ldnmp_web_on
	  prefix="web$(shuf -i 10-99 -n 1)_"
echo "Database address: mysql"
echo "Database name: $dbname"
echo "Username: $dbuse"
echo "Password: $dbusepasswd"
echo "Table prefix: $prefix"
echo "Administrator login information is set by yourself"

		;;


	  21)
	  ldnmp_install_status_one
	  nginx_install_all
		;;

	  22)
	  clear
	  webname="站点重定向"
	  send_stats "安装$webname"
echo "Start deploy $webname"
	  add_yuming
	  read -e -p "请输入跳转域名: " reverseproxy
	  nginx_install_status
	  install_ssltls
	  certs_status

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/rewrite.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  sed -i "s/baidu.com/$reverseproxy/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  docker exec nginx nginx -s reload

	  nginx_web_on


		;;

	  23)
	  ldnmp_Proxy
		;;

	  24)
	  clear
	  webname="反向代理-域名"
	  send_stats "安装$webname"
echo "Start deploy $webname"
	  add_yuming
echo -e "Domain name format: ${gl_huang}google.com${gl_bai}"
	  read -e -p "请输入你的反代域名: " fandai_yuming
	  nginx_install_status
	  install_ssltls
	  certs_status

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-domain.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  sed -i "s|fandaicom|$fandai_yuming|g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  docker exec nginx nginx -s reload

	  nginx_web_on

		;;


	  25)
	  clear
	  webname="Bitwarden"
	  send_stats "安装$webname"
echo "Start deploy $webname"
	  add_yuming
	  nginx_install_status
	  install_ssltls
	  certs_status

	  docker run -d \
		--name bitwarden \
		--restart always \
		-p 3280:80 \
		-v /home/web/html/$yuming/bitwarden/data:/data \
		vaultwarden/server
	  duankou=3280
	  reverse_proxy

	  nginx_web_on

		;;

	  26)
	  clear
	  webname="halo"
	  send_stats "安装$webname"
echo "Start deploy $webname"
	  add_yuming
	  nginx_install_status
	  install_ssltls
	  certs_status

	  docker run -d --name halo --restart always -p 8010:8090 -v /home/web/html/$yuming/.halo2:/root/.halo2 halohub/halo:2
	  duankou=8010
	  reverse_proxy

	  nginx_web_on

		;;

	  27)
	  clear
	  webname="AI绘画提示词生成器"
	  send_stats "安装$webname"
echo "Start deploy $webname"
	  add_yuming
	  nginx_install_status
	  install_ssltls
	  certs_status

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/html.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming

	  wget ${gh_proxy}github.com/kejilion/Website_source_code/raw/refs/heads/main/ai_prompt_generator.zip
	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  docker exec nginx chmod -R nginx:nginx /var/www/html
	  docker exec nginx nginx -s reload

	  nginx_web_on

		;;


	  30)
	  clear
	  webname="静态站点"
	  send_stats "安装$webname"
echo "Start deploy $webname"
	  add_yuming
	  repeat_add_yuming
	  nginx_install_status
	  install_ssltls
	  certs_status

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/html.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming


	  clear
echo -e "[${gl_huang}1/2${gl_bai}] Upload static source code"
	  echo "-------------"
echo "At present, only zip-format source code packages are allowed to be uploaded. Please put the source code packages in the /home/web/html/${yuming} directory"
	  read -e -p "也可以输入下载链接，远程下载源码包，直接回车将跳过远程下载： " url_download

	  if [ -n "$url_download" ]; then
		  wget "$url_download"
	  fi

	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  clear
echo -e "[${gl_huang}2/2${gl_bai}] index.html path"
	  echo "-------------"
	  # find "$(realpath .)" -name "index.html" -print
	  find "$(realpath .)" -name "index.html" -print | xargs -I {} dirname {}

	  read -e -p "请输入index.html的路径，类似（/home/web/html/$yuming/index/）： " index_lujing

	  sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
	  sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

	  docker exec nginx chmod -R nginx:nginx /var/www/html
	  docker exec nginx nginx -s reload

	  nginx_web_on

		;;



	31)
	  ldnmp_web_status
	  ;;


	32)
	  clear
	  send_stats "LDNMP环境备份"

	  local backup_filename="web_$(date +"%Y%m%d%H%M%S").tar.gz"
echo -e "${gl_huang} is backing up $backup_filename ...${gl_bai}"
	  cd /home/ && tar czvf "$backup_filename" web

	  while true; do
		clear
echo "Backup file has been created: /home/$backup_filename"
		read -e -p "要传送备份数据到远程服务器吗？(Y/N): " choice
		case "$choice" in
		  [Yy])
			read -e -p "请输入远端服务器IP:  " remote_ip
			if [ -z "$remote_ip" ]; then
echo "Error: Please enter the remote server IP."
			  continue
			fi
			local latest_tar=$(ls -t /home/*.tar.gz | head -1)
			if [ -n "$latest_tar" ]; then
			  ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
			  sleep 2  # 添加等待时间
			  scp -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/home/"
echo "The file has been transferred to the remote server home directory."
			else
echo "No file to be transferred was found."
			fi
			break
			;;
		  [Nn])
			break
			;;
		  *)
echo "Invalid selection, please enter Y or N."
			;;
		esac
	  done
	  ;;

	33)
	  clear
	  send_stats "定时远程备份"
	  read -e -p "输入远程服务器IP: " useip
	  read -e -p "输入远程服务器密码: " usepasswd

	  cd ~
	  wget -O ${useip}_beifen.sh ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/beifen.sh > /dev/null 2>&1
	  chmod +x ${useip}_beifen.sh

	  sed -i "s/0.0.0.0/$useip/g" ${useip}_beifen.sh
	  sed -i "s/123456/$usepasswd/g" ${useip}_beifen.sh

	  echo "------------------------"
echo "1. Weekly backup 2. Daily backup"
	  read -e -p "请输入你的选择: " dingshi

	  case $dingshi in
		  1)
			  check_crontab_installed
			  read -e -p "选择每周备份的星期几 (0-6，0代表星期日): " weekday
			  (crontab -l ; echo "0 0 * * $weekday ./${useip}_beifen.sh") | crontab - > /dev/null 2>&1
			  ;;
		  2)
			  check_crontab_installed
			  read -e -p "选择每天备份的时间（小时，0-23）: " hour
			  (crontab -l ; echo "0 $hour * * * ./${useip}_beifen.sh") | crontab - > /dev/null 2>&1
			  ;;
		  *)
			  break  # 跳出
			  ;;
	  esac

	  install sshpass

	  ;;

	34)
	  root_use
	  send_stats "LDNMP环境还原"
echo "Available site backups"
	  echo "-------------------------"
	  ls -lt /home/*.gz | awk '{print $NF}'
	  echo ""
	  read -e -p  "回车键还原最新的备份，输入备份文件名还原指定的备份，输入0退出：" filename

	  if [ "$filename" == "0" ]; then
		  break_end
		  linux_ldnmp
	  fi

	  # 如果用户没有输入文件名，使用最新的压缩包
	  if [ -z "$filename" ]; then
		  local filename=$(ls -t /home/*.tar.gz | head -1)
	  fi

	  if [ -n "$filename" ]; then
		  cd /home/web/ > /dev/null 2>&1
		  docker compose down > /dev/null 2>&1
		  rm -rf /home/web > /dev/null 2>&1

echo -e "${gl_huang} is decompressing $filename ...${gl_bai}"
		  cd /home/ && tar -xzf "$filename"

		  check_port
		  install_dependency
		  install_docker
		  install_certbot
		  install_ldnmp
	  else
echo "No zip package found."
	  fi

	  ;;

	35)
	  send_stats "LDNMP环境防御"
	  while true; do
		check_waf_status
		check_cf_mode
		if [ -x "$(command -v fail2ban-client)" ] ; then
			clear
			remove fail2ban
			rm -rf /etc/fail2ban
		else
			  clear
			  docker_name="fail2ban"
			  check_docker_app
echo -e "Server Website Defense Program ${check_docker}${gl_lv}${CFmessage}${waf_status}${gl_bai}"
			  echo "------------------------"
echo "1. Install the defense program"
			  echo "------------------------"
echo "5. View SSH interception record 6. View website interception record"
echo "7. View the list of defense rules 8. View the real-time monitoring of the log"
			  echo "------------------------"
echo "11. Configure intercept parameters 12. Clear all blocked IPs"
			  echo "------------------------"
echo "21. cloudflare mode 22. High load on 5 seconds shield"
			  echo "------------------------"
echo "31. Turn on WAF 32. Turn off WAF"
echo "33. Turn on DDOS Defense 34. Turn off DDOS Defense"
			  echo "------------------------"
echo "9. Uninstall the defense program"
			  echo "------------------------"
echo "0. Return to previous menu"
			  echo "------------------------"
			  read -e -p "请输入你的选择: " sub_choice
			  case $sub_choice in
				  1)
					  f2b_install_sshd
					  cd /path/to/fail2ban/config/fail2ban/filter.d
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/fail2ban-nginx-cc.conf
					  cd /path/to/fail2ban/config/fail2ban/jail.d/
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf
					  sed -i "/cloudflare/d" /path/to/fail2ban/config/fail2ban/jail.d/nginx-docker-cc.conf
					  f2b_status
					  ;;
				  5)
					  echo "------------------------"
					  f2b_sshd
					  echo "------------------------"
					  ;;
				  6)

					  echo "------------------------"
					  local xxx="fail2ban-nginx-cc"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="docker-nginx-bad-request"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="docker-nginx-botsearch"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="docker-nginx-http-auth"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="docker-nginx-limit-req"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="docker-php-url-fopen"
					  f2b_status_xxx
					  echo "------------------------"

					  ;;

				  7)
					  docker exec -it fail2ban fail2ban-client status
					  ;;
				  8)
					  tail -f /path/to/fail2ban/config/log/fail2ban/fail2ban.log

					  ;;
				  9)
					  docker rm -f fail2ban
					  rm -rf /path/to/fail2ban
					  crontab -l | grep -v "CF-Under-Attack.sh" | crontab - 2>/dev/null
echo "Fail2Ban Defense Program Uninstalled"
					  ;;

				  11)
					  install nano
					  nano /path/to/fail2ban/config/fail2ban/jail.d/nginx-docker-cc.conf
					  f2b_status
					  break
					  ;;

				  12)
					  docker exec -it fail2ban fail2ban-client unban --all
					  ;;

				  21)
					  send_stats "cloudflare模式"
echo "Go to the upper right corner of the cf background, select the API token on the left, and obtain the Global API Key"
					  echo "https://dash.cloudflare.com/login"
					  read -e -p "输入CF的账号: " cfuser
					  read -e -p "输入CF的Global API Key: " cftoken

					  wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default11.conf
					  docker exec nginx nginx -s reload

					  cd /path/to/fail2ban/config/fail2ban/jail.d/
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf

					  cd /path/to/fail2ban/config/fail2ban/action.d
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/cloudflare-docker.conf

					  sed -i "s/kejilion@outlook.com/$cfuser/g" /path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf
					  sed -i "s/APIKEY00000/$cftoken/g" /path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf
					  f2b_status

echo "Configured cloudflare mode, you can view intercept records in cf background, site-security-events"
					  ;;

				  22)
					  send_stats "高负载开启5秒盾"
echo -e "${gl_huang} website automatically detects every 5 minutes. When high load is detected, the shield will be automatically turned on, and low load will also automatically turn off the 5-second shield. ${gl_bai}"
					  echo "--------------"
echo "Get CF parameters: "
echo -e "Go to the upper right corner of the cf background, select the API token on the left, and get ${gl_huang}Global API Key${gl_bai}"
echo -e "Get ${gl_huang} area ID${gl_bai} in the lower right of the cf background domain name summary page"
					  echo "https://dash.cloudflare.com/login"
					  echo "--------------"
					  read -e -p "输入CF的账号: " cfuser
					  read -e -p "输入CF的Global API Key: " cftoken
					  read -e -p "输入CF中域名的区域ID: " cfzonID

					  cd ~
					  install jq bc
					  check_crontab_installed
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/CF-Under-Attack.sh
					  chmod +x CF-Under-Attack.sh
					  sed -i "s/AAAA/$cfuser/g" ~/CF-Under-Attack.sh
					  sed -i "s/BBBB/$cftoken/g" ~/CF-Under-Attack.sh
					  sed -i "s/CCCC/$cfzonID/g" ~/CF-Under-Attack.sh

					  local cron_job="*/5 * * * * ~/CF-Under-Attack.sh"

					  local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

					  if [ -z "$existing_cron" ]; then
						  (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
echo "High load automatic shield script has been added"
					  else
echo "Automatic shield script already exists, no need to add it"
					  fi

					  ;;

				  31)
					  nginx_waf on
echo "Site WAF is enabled"
					  send_stats "站点WAF已开启"
					  ;;

				  32)
				  	  nginx_waf off
echo "Site WAF is closed"
					  send_stats "站点WAF已关闭"
					  ;;

				  33)
					  enable_ddos_defense
					  ;;

				  34)
					  disable_ddos_defense
					  ;;

				  *)
					  break
					  ;;
			  esac
		fi
	  break_end
	  done
		;;

	36)
		  while true; do
			  clear
			  send_stats "优化LDNMP环境"
echo "Optimize LDNMP environment"
			  echo "------------------------"
echo "1. Standard mode 2. High performance mode (recommended 2H2G or above)"
			  echo "------------------------"
echo "0. Return to previous menu"
			  echo "------------------------"
			  read -e -p "请输入你的选择: " sub_choice
			  case $sub_choice in
				  1)
				  send_stats "站点标准模式"

				  # nginx调优
				  sed -i 's/worker_connections.*/worker_connections 10240;/' /home/web/nginx.conf
				  sed -i 's/worker_processes.*/worker_processes 4;/' /home/web/nginx.conf

				  # php调优
				  wget -O /home/optimized_php.ini ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/optimized_php.ini
				  docker cp /home/optimized_php.ini php:/usr/local/etc/php/conf.d/optimized_php.ini
				  docker cp /home/optimized_php.ini php74:/usr/local/etc/php/conf.d/optimized_php.ini
				  rm -rf /home/optimized_php.ini

				  # php调优
				  wget -O /home/www.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/www-1.conf
				  docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
				  docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
				  rm -rf /home/www.conf

				  # mysql调优
				  wget -O /home/custom_mysql_config.cnf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config-1.cnf
				  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
				  rm -rf /home/custom_mysql_config.cnf


				  cd /home/web && docker compose restart

				  restart_redis
				  optimize_balanced


echo "LDNMP environment has been set to standard mode"

					  ;;
				  2)
				  send_stats "站点高性能模式"

				  # nginx调优
				  sed -i 's/worker_connections.*/worker_connections 20480;/' /home/web/nginx.conf
				  sed -i 's/worker_processes.*/worker_processes 8;/' /home/web/nginx.conf

				  # php调优
				  wget -O /home/optimized_php.ini ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/optimized_php.ini
				  docker cp /home/optimized_php.ini php:/usr/local/etc/php/conf.d/optimized_php.ini
				  docker cp /home/optimized_php.ini php74:/usr/local/etc/php/conf.d/optimized_php.ini
				  rm -rf /home/optimized_php.ini

				  # php调优
				  wget -O /home/www.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/www.conf
				  docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
				  docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
				  rm -rf /home/www.conf

				  # mysql调优
				  wget -O /home/custom_mysql_config.cnf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config.cnf
				  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
				  rm -rf /home/custom_mysql_config.cnf

				  cd /home/web && docker compose restart

				  restart_redis
				  optimize_web_server

echo "LDNMP environment has been set to high performance mode"

					  ;;
				  *)
					  break
					  ;;
			  esac
			  break_end

		  done
		;;


	37)
	  root_use
	  while true; do
		  clear
		  send_stats "更新LDNMP环境"
echo "Update LDNMP environment"
		  echo "------------------------"
		  ldnmp_v
echo "Discover new version of components"
		  echo "------------------------"
		  check_docker_image_update nginx
		  if [ -n "$update_status" ]; then
			echo -e "${gl_huang}nginx $update_status${gl_bai}"
		  fi
		  check_docker_image_update php
		  if [ -n "$update_status" ]; then
			echo -e "${gl_huang}php $update_status${gl_bai}"
		  fi
		  check_docker_image_update mysql
		  if [ -n "$update_status" ]; then
			echo -e "${gl_huang}mysql $update_status${gl_bai}"
		  fi
		  check_docker_image_update redis
		  if [ -n "$update_status" ]; then
			echo -e "${gl_huang}redis $update_status${gl_bai}"
		  fi
		  echo "------------------------"
		  echo
echo "1. Update nginx 2. Update mysql 3. Update php 4. Update redis"
		  echo "------------------------"
echo "5. Update the complete environment"
		  echo "------------------------"
echo "0. Return to previous menu"
		  echo "------------------------"
		  read -e -p "请输入你的选择: " sub_choice
		  case $sub_choice in
			  1)
			  nginx_upgrade

				  ;;

			  2)
			  local ldnmp_pods="mysql"
			  read -e -p "请输入${ldnmp_pods}版本号 （如: 8.0 8.3 8.4 9.0）（回车获取最新版）: " version
			  local version=${version:-latest}

			  cd /home/web/
			  cp /home/web/docker-compose.yml /home/web/docker-compose1.yml
			  sed -i "s/image: mysql/image: mysql:${version}/" /home/web/docker-compose.yml
			  docker rm -f $ldnmp_pods
			  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
			  docker compose up -d --force-recreate $ldnmp_pods
			  docker restart $ldnmp_pods
			  cp /home/web/docker-compose1.yml /home/web/docker-compose.yml
			  send_stats "更新$ldnmp_pods"
echo "Update ${ldnmp_pods} completed"

				  ;;
			  3)
			  local ldnmp_pods="php"
			  read -e -p "请输入${ldnmp_pods}版本号 （如: 7.4 8.0 8.1 8.2 8.3）（回车获取最新版）: " version
			  local version=${version:-8.3}
			  cd /home/web/
			  cp /home/web/docker-compose.yml /home/web/docker-compose1.yml
			  sed -i "s/kjlion\///g" /home/web/docker-compose.yml > /dev/null 2>&1
			  sed -i "s/image: php:fpm-alpine/image: php:${version}-fpm-alpine/" /home/web/docker-compose.yml
			  docker rm -f $ldnmp_pods
			  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
  			  docker images --filter=reference="kjlion/${ldnmp_pods}*" -q | xargs docker rmi > /dev/null 2>&1
			  docker compose up -d --force-recreate $ldnmp_pods
			  docker exec php chown -R www-data:www-data /var/www/html

			  run_command docker exec php sed -i "s/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g" /etc/apk/repositories > /dev/null 2>&1

			  docker exec php apk update
			  curl -sL ${gh_proxy}github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o /usr/local/bin/install-php-extensions
			  docker exec php mkdir -p /usr/local/bin/
			  docker cp /usr/local/bin/install-php-extensions php:/usr/local/bin/
			  docker exec php chmod +x /usr/local/bin/install-php-extensions

			  docker exec php sh -c "\
							apk add --no-cache imagemagick imagemagick-dev \
							&& apk add --no-cache git autoconf gcc g++ make pkgconfig \
							&& rm -rf /tmp/imagick \
							&& git clone ${gh_proxy}github.com/Imagick/imagick /tmp/imagick \
							&& cd /tmp/imagick \
							&& phpize \
							&& ./configure \
							&& make \
							&& make install \
							&& echo 'extension=imagick.so' > /usr/local/etc/php/conf.d/imagick.ini \
							&& rm -rf /tmp/imagick"


			  docker exec php install-php-extensions mysqli pdo_mysql gd intl zip exif bcmath opcache redis


			  docker exec php sh -c 'echo "upload_max_filesize=50M " > /usr/local/etc/php/conf.d/uploads.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "post_max_size=50M " > /usr/local/etc/php/conf.d/post.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "memory_limit=256M" > /usr/local/etc/php/conf.d/memory.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "max_execution_time=1200" > /usr/local/etc/php/conf.d/max_execution_time.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "max_input_time=600" > /usr/local/etc/php/conf.d/max_input_time.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "max_input_vars=3000" > /usr/local/etc/php/conf.d/max_input_vars.ini' > /dev/null 2>&1


			  docker restart $ldnmp_pods > /dev/null 2>&1
			  cp /home/web/docker-compose1.yml /home/web/docker-compose.yml
			  send_stats "更新$ldnmp_pods"
echo "Update ${ldnmp_pods} completed"

				  ;;
			  4)
			  local ldnmp_pods="redis"
			  cd /home/web/
			  docker rm -f $ldnmp_pods
			  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
			  docker compose up -d --force-recreate $ldnmp_pods
			  restart_redis
			  docker restart $ldnmp_pods > /dev/null 2>&1
			  send_stats "更新$ldnmp_pods"
echo "Update ${ldnmp_pods} completed"

				  ;;
			  5)
				read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}长时间不更新环境的用户，请慎重更新LDNMP环境，会有数据库更新失败的风险。确定更新LDNMP环境吗？(Y/N): ")" choice
				case "$choice" in
				  [Yy])
					send_stats "完整更新LDNMP环境"
					cd /home/web/
					docker compose down --rmi all

					check_port
					install_dependency
					install_docker
					install_certbot
					install_ldnmp
					;;
				  *)
					;;
				esac
				  ;;
			  *)
				  break
				  ;;
		  esac
		  break_end
	  done


	  ;;

	38)
		root_use
		send_stats "卸载LDNMP环境"
		read -e -p "$(echo -e "${gl_hong}强烈建议：${gl_bai}先备份全部网站数据，再卸载LDNMP环境。确定删除所有网站数据吗？(Y/N): ")" choice
		case "$choice" in
		  [Yy])
			cd /home/web/
			docker compose down --rmi all
			docker compose -f docker-compose.phpmyadmin.yml down > /dev/null 2>&1
			docker compose -f docker-compose.phpmyadmin.yml down --rmi all > /dev/null 2>&1
			rm -rf /home/web
			;;
		  [Nn])

			;;
		  *)
echo "Invalid selection, please enter Y or N."
			;;
		esac
		;;

	0)
		kejilion
	  ;;

	*)
echo "Invalid input!"
	esac
	break_end

  done

}



linux_panel() {

	while true; do
	  clear
	  # send_stats "应用市场"
echo -e "Application Market"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}1. ${gl_bai}Baota Panel Official Version ${gl_kjlan}2. ${gl_bai}aaPanelBaota International Version"
echo -e "${gl_kjlan}3. ${gl_bai}1Panel new generation management panel ${gl_kjlan}4. ${gl_bai}NginxProxyManager visual panel"
echo -e "${gl_kjlan}5. ${gl_bai}AList multi-store file list program ${gl_kjlan}6. ${gl_bai}Ubuntu remote desktop web version"
echo -e "${gl_kjlan}7. ${gl_bai}Nezha Probe VPS Monitoring Panel ${gl_kjlan}8. ${gl_bai}QB Offline BT Magnetic Download Panel"
echo -e "${gl_kjlan}9. ${gl_bai}Poste.io mail server program ${gl_kjlan}10. ${gl_bai}RocketChat multiplayer online chat system"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}11. ${gl_bai}Zendao Project Management Software ${gl_kjlan}12. ${gl_bai}Qinglong Panel Timed Task Management Platform"
echo -e "${gl_kjlan}13. ${gl_bai}Cloudreve network disk ${gl_huang}★${gl_bai} ${gl_kjlan}14. ${gl_bai} Simple picture bed picture management program"
echo -e "${gl_kjlan}15. ${gl_bai}emby multimedia management system ${gl_kjlan}16. ${gl_bai}Speedtest speed test panel"
echo -e "${gl_kjlan}17. ${gl_bai}AdGuardHome Adware ${gl_kjlan}18. ${gl_bai}onlyoffice Online Office OFFICE"
echo -e "${gl_kjlan}19. ${gl_bai}Thunder Pool WAF Firewall Panel ${gl_kjlan}20. ${gl_bai}portainer Container Management Panel"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}21. ${gl_bai}VScode web version ${gl_kjlan}22. ${gl_bai}UptimeKuma monitoring tool"
echo -e "${gl_kjlan}23. ${gl_bai}Memos Web Memo ${gl_kjlan}24. ${gl_bai}Webtop Remote Desktop Web Version ${gl_huang}★${gl_bai}"
echo -e "${gl_kjlan}25. ${gl_bai}Nextcloud network disk ${gl_kjlan}26. ${gl_bai}QD-Today timing task management framework"
echo -e "${gl_kjlan}27. ${gl_bai}Dockge Container Stack Management Panel ${gl_kjlan}28. ${gl_bai}LibreSpeed ​​Speed ​​Test Tool"
echo -e "${gl_kjlan}29. ${gl_bai}searxng aggregation search site ${gl_huang}★${gl_bai} ${gl_kjlan}30. ${gl_bai}PhotoPrism private photo album system"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}31. ${gl_bai}StringPDF tool collection ${gl_kjlan}32. ${gl_bai}drawio free online charting software ${gl_huang}★${gl_bai}"
echo -e "${gl_kjlan}33. ${gl_bai}Sun-Panel navigation panel ${gl_kjlan}34. ${gl_bai}Pingvin-Share file sharing platform"
echo -e "${gl_kjlan}35. ${gl_bai}Minimal Friends Circle ${gl_kjlan}36. ${gl_bai}LobeChatAI Chat Aggregation Website"
echo -e "${gl_kjlan}37. ${gl_bai}MyIP Toolbox ${gl_huang}★${gl_bai} ${gl_kjlan}38. ${gl_bai} Xiaoya alist family bucket"
echo -e "${gl_kjlan}39. ${gl_bai}Bililive live recording tool ${gl_kjlan}40. ${gl_bai}webssh web version SSH connection tool"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}41. ${gl_bai}Mouse Management Panel ${gl_kjlan}42. ${gl_bai}Nexterm Remote Connection Tool"
echo -e "${gl_kjlan}43. ${gl_bai}RustDesk Remote Desk (Server) ${gl_kjlan}44. ${gl_bai}RustDesk Remote Desk (Relay)"
echo -e "${gl_kjlan}45. ${gl_bai}Docker acceleration station ${gl_kjlan}46. ${gl_bai}GitHub acceleration station"
echo -e "${gl_kjlan}47. ${gl_bai}Prometheus Monitoring ${gl_kjlan}48. ${gl_bai}Prometheus (host monitoring)"
echo -e "${gl_kjlan}49. ${gl_bai}Prometheus (Container Monitoring) ${gl_kjlan}50. ${gl_bai}Replenishment Monitoring Tool"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}51. ${gl_bai}PVE open chick panel ${gl_kjlan}52. ${gl_bai}DPanel container management panel"
echo -e "${gl_kjlan}53. ${gl_bai}llama3 Chat AI Model ${gl_kjlan}54. ${gl_bai}AMH Host Website Building Management Panel"
echo -e "${gl_kjlan}55. ${gl_bai}FRP intranet penetration (server) ${gl_kjlan}56. ${gl_bai}FRP intranet penetration (client)"
echo -e "${gl_kjlan}57. ${gl_bai}Deepseek Chat AI Mockup ${gl_kjlan}58. ${gl_bai}Dify Mockup Knowledge Base"
echo -e "${gl_kjlan}59. ${gl_bai}NewAPI Big Model Asset Management ${gl_kjlan}60. ${gl_bai}JumpServer Open Source Bastion Machine"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}61. ${gl_bai}Online Translation Server ${gl_kjlan}62. ${gl_bai}RAGFlow Mockup Knowledge Base"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}0. ${gl_bai} returns to main menu"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "请输入你的选择: " sub_choice

	  case $sub_choice in
		  1)

			local lujing="[ -d "/www/server/panel" ]"
			local panelname="宝塔面板"
			local panelurl="https://www.bt.cn/new/index.html"

			panel_app_install() {
				if [ -f /usr/bin/curl ];then curl -sSO https://download.bt.cn/install/install_panel.sh;else wget -O install_panel.sh https://download.bt.cn/install/install_panel.sh;fi;bash install_panel.sh ed8484bec
			}

			panel_app_manage() {
				bt
			}

			panel_app_uninstall() {
				curl -o bt-uninstall.sh http://download.bt.cn/install/bt-uninstall.sh > /dev/null 2>&1 && chmod +x bt-uninstall.sh && ./bt-uninstall.sh
				chmod +x bt-uninstall.sh
				./bt-uninstall.sh
			}

			install_panel



			  ;;
		  2)

			local lujing="[ -d "/www/server/panel" ]"
			local panelname="aapanel"
			local panelurl="https://www.aapanel.com/new/index.html"

			panel_app_install() {
				URL=https://www.aapanel.com/script/install_7.0_en.sh && if [ -f /usr/bin/curl ];then curl -ksSO "$URL" ;else wget --no-check-certificate -O install_7.0_en.sh "$URL";fi;bash install_7.0_en.sh aapanel
			}

			panel_app_manage() {
				bt
			}

			panel_app_uninstall() {
				curl -o bt-uninstall.sh http://download.bt.cn/install/bt-uninstall.sh > /dev/null 2>&1 && chmod +x bt-uninstall.sh && ./bt-uninstall.sh
				chmod +x bt-uninstall.sh
				./bt-uninstall.sh
			}

			install_panel

			  ;;
		  3)

			local lujing="command -v 1pctl > /dev/null 2>&1"
			local panelname="1Panel"
			local panelurl="https://1panel.cn/"

			panel_app_install() {
				install bash
				curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && bash quick_start.sh
			}

			panel_app_manage() {
				1pctl user-info
				1pctl update password
			}

			panel_app_uninstall() {
				1pctl uninstall
			}

			install_panel

			  ;;
		  4)

			local docker_name="npm"
			local docker_img="jc21/nginx-proxy-manager:latest"
			local docker_port=81
			local docker_rum="docker run -d \
						  --name=$docker_name \
						  -p 80:80 \
						  -p 81:$docker_port \
						  -p 443:443 \
						  -v /home/docker/npm/data:/data \
						  -v /home/docker/npm/letsencrypt:/etc/letsencrypt \
						  --restart=always \
						  $docker_img"
			local docker_describe="如果您已经安装了其他面板或者LDNMP建站环境，建议先卸载，再安装npm！"
			local docker_url="官网介绍: https://nginxproxymanager.com/"
			local docker_use="echo \"初始用户名: admin@example.com\""
			local docker_passwd="echo \"初始密码: changeme\""
			local app_size="1"

			docker_app

			  ;;

		  5)

			local docker_name="alist"
			local docker_img="xhofe/alist-aria2:latest"
			local docker_port=5244
			local docker_rum="docker run -d \
								--restart=always \
								-v /home/docker/alist:/opt/alist/data \
								-p 5244:5244 \
								-e PUID=0 \
								-e PGID=0 \
								-e UMASK=022 \
								--name="alist" \
								xhofe/alist-aria2:latest"
			local docker_describe="一个支持多种存储，支持网页浏览和 WebDAV 的文件列表程序，由 gin 和 Solidjs 驱动"
			local docker_url="官网介绍: https://alist.nn.ci/zh/"
			local docker_use="docker exec -it alist ./alist admin random"
			local docker_passwd=""
			local app_size="1"
			docker_app

			  ;;

		  6)

			local docker_name="webtop-ubuntu"
			local docker_img="lscr.io/linuxserver/webtop:ubuntu-kde"
			local docker_port=3006
			local docker_rum="docker run -d \
						  --name=webtop-ubuntu \
						  --security-opt seccomp=unconfined \
						  -e PUID=1000 \
						  -e PGID=1000 \
						  -e TZ=Etc/UTC \
						  -e SUBFOLDER=/ \
						  -e TITLE=Webtop \
						  -p 3006:3000 \
						  -v /home/docker/webtop/data:/config \
						  -v /var/run/docker.sock:/var/run/docker.sock \
						  --shm-size="1gb" \
						  --restart unless-stopped \
						  lscr.io/linuxserver/webtop:ubuntu-kde"

			local docker_describe="webtop基于Ubuntu的容器，包含官方支持的完整桌面环境，可通过任何现代 Web 浏览器访问"
			local docker_url="官网介绍: https://docs.linuxserver.io/images/docker-webtop/"
			local docker_use=""
			local docker_passwd=""
			local app_size="2"
			docker_app


			  ;;
		  7)
			clear
			send_stats "搭建哪吒"
			local docker_name="nezha-dashboard"
			local docker_port=8008
			while true; do
				check_docker_app
				check_docker_image_update $docker_name
				clear
echo -e "Nezha Monitoring $check_docker $update_status"
echo "Open source, lightweight, easy-to-use server monitoring and operation and maintenance tools"
echo "Video introduction: https://www.bilibili.com/video/BV1wv421C71t?t=0.1"
				if docker inspect "$docker_name" &>/dev/null; then
					local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
					check_docker_app_ip
				fi
				echo ""
				echo "------------------------"
echo "1. Use"
				echo "------------------------"
echo "5. Add domain name access 6. Delete domain name access"
echo "7. Allow IP+port access 8. Block IP+port access"
				echo "------------------------"
echo "0. Return to previous menu"
				echo "------------------------"
				read -e -p "输入你的选择: " choice

				case $choice in
					1)
						check_disk_space 1
						install unzip jq
						install_docker
						curl -sL ${gh_proxy}raw.githubusercontent.com/nezhahq/scripts/refs/heads/main/install.sh -o nezha.sh && chmod +x nezha.sh && ./nezha.sh
						local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
						check_docker_app_ip
						;;
					5)
echo "${docker_name}Domain Access Settings"
						send_stats "${docker_name}域名访问设置"
						add_yuming
						ldnmp_Proxy ${yuming} ${ipv4_address} ${docker_port}
						block_container_port "$docker_name" "$ipv4_address"
						;;

					6)
echo "Domain name format example.com does not come with https://"
						web_del
						;;

					7)
						send_stats "允许IP访问 ${docker_name}"
						clear_container_rules "$docker_name" "$ipv4_address"
						;;

					8)
						send_stats "阻止IP访问 ${docker_name}"
						block_container_port "$docker_name" "$ipv4_address"
						;;

					*)
						break
						;;

				esac
				break_end
			done
			  ;;

		  8)

			local docker_name="qbittorrent"
			local docker_img="lscr.io/linuxserver/qbittorrent:latest"
			local docker_port=8081
			local docker_rum="docker run -d \
								  --name=qbittorrent \
								  -e PUID=1000 \
								  -e PGID=1000 \
								  -e TZ=Etc/UTC \
								  -e WEBUI_PORT=8081 \
								  -p 8081:8081 \
								  -p 6881:6881 \
								  -p 6881:6881/udp \
								  -v /home/docker/qbittorrent/config:/config \
								  -v /home/docker/qbittorrent/downloads:/downloads \
								  --restart unless-stopped \
								  lscr.io/linuxserver/qbittorrent:latest"
			local docker_describe="qbittorrent离线BT磁力下载服务"
			local docker_url="官网介绍: https://hub.docker.com/r/linuxserver/qbittorrent"
			local docker_use="sleep 3"
			local docker_passwd="docker logs qbittorrent"
			local app_size="1"
			docker_app

			  ;;

		  9)
			send_stats "搭建邮局"
			clear
			install telnet
			local docker_name=“mailserver”
			while true; do
				check_docker_app
				check_docker_image_update $docker_name

				clear
echo -e "Post Office Service $check_docker $update_status"
echo "poste.io is an open source mail server solution,"
echo "Video introduction: https://www.bilibili.com/video/BV1wv421C71t?t=0.1"

				echo ""
echo "Port Detection"
				port=25
				timeout=3
				if echo "quit" | timeout $timeout telnet smtp.qq.com $port | grep 'Connected'; then
echo -e "${gl_lv}port $port Currently available ${gl_bai}"
				else
echo -e "${gl_hong}port $port is currently not available ${gl_bai}"
				fi
				echo ""

				if docker inspect "$docker_name" &>/dev/null; then
					yuming=$(cat /home/docker/mail.txt)
echo "Access Address: "
					echo "https://$yuming"
				fi

				echo "------------------------"
echo "1. Install 2. Update 3. Uninstall"
				echo "------------------------"
echo "0. Return to previous menu"
				echo "------------------------"
				read -e -p "输入你的选择: " choice

				case $choice in
					1)
						check_disk_space 2
						read -e -p "请设置邮箱域名 例如 mail.yuming.com : " yuming
						mkdir -p /home/docker
						echo "$yuming" > /home/docker/mail.txt
						echo "------------------------"
						ip_address
echo "Parse these DNS records first"
						echo "A           mail            $ipv4_address"
						echo "CNAME       imap            $yuming"
						echo "CNAME       pop             $yuming"
						echo "CNAME       smtp            $yuming"
						echo "MX          @               $yuming"
						echo "TXT         @               v=spf1 mx ~all"
						echo "TXT         ?               ?"
						echo ""
						echo "------------------------"
echo "Press any key to continue..."
						read -n 1 -s -r -p ""

						install jq
						install_docker

						docker run \
							--net=host \
							-e TZ=Europe/Prague \
							-v /home/docker/mail:/data \
							--name "mailserver" \
							-h "$yuming" \
							--restart=always \
							-d analogic/poste.io

						clear
echo "poste.io has been installed"
						echo "------------------------"
echo "You can access poste.io using the following address:"
						echo "https://$yuming"
						echo ""

						;;

					2)
						docker rm -f mailserver
						docker rmi -f analogic/poste.i
						yuming=$(cat /home/docker/mail.txt)
						docker run \
							--net=host \
							-e TZ=Europe/Prague \
							-v /home/docker/mail:/data \
							--name "mailserver" \
							-h "$yuming" \
							--restart=always \
							-d analogic/poste.i
						clear
echo "poste.io has been installed"
						echo "------------------------"
echo "You can access poste.io using the following address:"
						echo "https://$yuming"
						echo ""
						;;
					3)
						docker rm -f mailserver
						docker rmi -f analogic/poste.io
						rm /home/docker/mail.txt
						rm -rf /home/docker/mail
echo "App uninstalled"
						;;

					*)
						break
						;;

				esac
				break_end
			done

			  ;;

		  10)

			local app_name="Rocket.Chat聊天系统"
			local app_text="Rocket.Chat 是一个开源的团队通讯平台，支持实时聊天、音视频通话、文件共享等多种功能，"
			local app_url="官方介绍: https://www.rocket.chat/"
			local docker_name="rocketchat"
			local docker_port="3897"
			local app_size="2"

			docker_app_install() {
				docker run --name db -d --restart=always \
					-v /home/docker/mongo/dump:/dump \
					mongo:latest --replSet rs5 --oplogSize 256
				sleep 1
				docker exec -it db mongosh --eval "printjson(rs.initiate())"
				sleep 5
				docker run --name rocketchat --restart=always -p 3897:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat

				clear
				ip_address
echo "Installed"
				check_docker_app_ip
			}

			docker_app_update() {
				docker rm -f rocketchat
				docker rmi -f rocket.chat:latest
				docker run --name rocketchat --restart=always -p 3897:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat
				clear
				ip_address
echo "rocket.chat has been installed"
				check_docker_app_ip
			}

			docker_app_uninstall() {
				docker rm -f rocketchat
				docker rmi -f rocket.chat
				docker rm -f db
				docker rmi -f mongo:latest
				rm -rf /home/docker/mongo
echo "App uninstalled"
			}

			docker_app_plus
			  ;;



		  11)
			local docker_name="zentao-server"
			local docker_img="idoop/zentao:latest"
			local docker_port=82
			local docker_rum="docker run -d -p 82:80 -p 3308:3306 \
							  -e ADMINER_USER="root" -e ADMINER_PASSWD="password" \
							  -e BIND_ADDRESS="false" \
							  -v /home/docker/zentao-server/:/opt/zbox/ \
							  --add-host smtp.exmail.qq.com:163.177.90.125 \
							  --name zentao-server \
							  --restart=always \
							  idoop/zentao:latest"
			local docker_describe="禅道是通用的项目管理软件"
			local docker_url="官网介绍: https://www.zentao.net/"
			local docker_use="echo \"初始用户名: admin\""
			local docker_passwd="echo \"初始密码: 123456\""
			local app_size="2"
			docker_app

			  ;;

		  12)
			local docker_name="qinglong"
			local docker_img="whyour/qinglong:latest"
			local docker_port=5700
			local docker_rum="docker run -d \
					  -v /home/docker/qinglong/data:/ql/data \
					  -p 5700:5700 \
					  --name qinglong \
					  --hostname qinglong \
					  --restart unless-stopped \
					  whyour/qinglong:latest"
			local docker_describe="青龙面板是一个定时任务管理平台"
			local docker_url="官网介绍: ${gh_proxy}github.com/whyour/qinglong"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			  ;;
		  13)

			local app_name="cloudreve网盘"
			local app_text="cloudreve是一个支持多家云存储的网盘系统"
			local app_url="视频介绍: https://www.bilibili.com/video/BV13F4m1c7h7?t=0.1"
			local docker_name="cloudreve"
			local docker_port="5212"
			local app_size="2"

			docker_app_install() {
				cd /home/ && mkdir -p docker/cloud && cd docker/cloud && mkdir temp_data && mkdir -vp cloudreve/{uploads,avatar} && touch cloudreve/conf.ini && touch cloudreve/cloudreve.db && mkdir -p aria2/config && mkdir -p data/aria2 && chmod -R 777 data/aria2
				curl -o /home/docker/cloud/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/cloudreve-docker-compose.yml
				cd /home/docker/cloud/ && docker compose up -d
				clear
echo "Installed"
				check_docker_app_ip
				sleep 3
				docker logs cloudreve
			}


			docker_app_update() {
				cd /home/docker/cloud/ && docker compose down --rmi all
				cd /home/docker/cloud/ && docker compose up -d
			}


			docker_app_uninstall() {
				cd /home/docker/cloud/ && docker compose down --rmi all
				rm -rf /home/docker/cloud
echo "App uninstalled"
			}

			docker_app_plus
			  ;;

		  14)
			local docker_name="easyimage"
			local docker_img="ddsderek/easyimage:latest"
			local docker_port=85
			local docker_rum="docker run -d \
					  --name easyimage \
					  -p 85:80 \
					  -e TZ=Asia/Shanghai \
					  -e PUID=1000 \
					  -e PGID=1000 \
					  -v /home/docker/easyimage/config:/app/web/config \
					  -v /home/docker/easyimage/i:/app/web/i \
					  --restart unless-stopped \
					  ddsderek/easyimage:latest"
			local docker_describe="简单图床是一个简单的图床程序"
			local docker_url="官网介绍: ${gh_proxy}github.com/icret/EasyImages2.0"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  15)
			local docker_name="emby"
			local docker_img="linuxserver/emby:latest"
			local docker_port=8096
			local docker_rum="docker run -d --name=emby --restart=always \
						-v /home/docker/emby/config:/config \
						-v /home/docker/emby/share1:/mnt/share1 \
						-v /home/docker/emby/share2:/mnt/share2 \
						-v /mnt/notify:/mnt/notify \
						-p 8096:8096 -p 8920:8920 \
						-e UID=1000 -e GID=100 -e GIDLIST=100 \
						linuxserver/emby:latest"
			local docker_describe="emby是一个主从式架构的媒体服务器软件，可以用来整理服务器上的视频和音频，并将音频和视频流式传输到客户端设备"
			local docker_url="官网介绍: https://emby.media/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  16)
			local docker_name="looking-glass"
			local docker_img="wikihostinc/looking-glass-server"
			local docker_port=89
			local docker_rum="docker run -d --name looking-glass --restart always -p 89:80 wikihostinc/looking-glass-server"
			local docker_describe="Speedtest测速面板是一个VPS网速测试工具，多项测试功能，还可以实时监控VPS进出站流量"
			local docker_url="官网介绍: ${gh_proxy}github.com/wikihost-opensource/als"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			  ;;
		  17)

			local docker_name="adguardhome"
			local docker_img="adguard/adguardhome"
			local docker_port=3000
			local docker_rum="docker run -d \
							--name adguardhome \
							-v /home/docker/adguardhome/work:/opt/adguardhome/work \
							-v /home/docker/adguardhome/conf:/opt/adguardhome/conf \
							-p 53:53/tcp \
							-p 53:53/udp \
							-p 3000:3000/tcp \
							--restart always \
							adguard/adguardhome"
			local docker_describe="AdGuardHome是一款全网广告拦截与反跟踪软件，未来将不止是一个DNS服务器。"
			local docker_url="官网介绍: https://hub.docker.com/r/adguard/adguardhome"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			  ;;


		  18)

			local docker_name="onlyoffice"
			local docker_img="onlyoffice/documentserver"
			local docker_port=8082
			local docker_rum="docker run -d -p 8082:80 \
						--restart=always \
						--name onlyoffice \
						-v /home/docker/onlyoffice/DocumentServer/logs:/var/log/onlyoffice  \
						-v /home/docker/onlyoffice/DocumentServer/data:/var/www/onlyoffice/Data  \
						 onlyoffice/documentserver"
			local docker_describe="onlyoffice是一款开源的在线office工具，太强大了！"
			local docker_url="官网介绍: https://www.onlyoffice.com/"
			local docker_use=""
			local docker_passwd=""
			local app_size="2"
			docker_app

			  ;;

		  19)
			send_stats "搭建雷池"

			local docker_name=safeline-mgt
			local docker_port=9443
			while true; do
				check_docker_app
				clear
echo -e "Thunder Pool Service $check_docker"
echo "Lei Chi is a WAF site firewall program panel developed by Changting Technology, which can reverse the agency site for automated defense"
echo "Video introduction: https://www.bilibili.com/video/BV1mZ421T74c?t=0.1"
				if docker inspect "$docker_name" &>/dev/null; then
					check_docker_app_ip
				fi
				echo ""

				echo "------------------------"
echo "1. Install 2. Update 3. Reset Password 4. Uninstall"
				echo "------------------------"
echo "0. Return to previous menu"
				echo "------------------------"
				read -e -p "输入你的选择: " choice

				case $choice in
					1)
						install_docker
						check_disk_space 5
						bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/setup.sh)"
						clear
echo "Thunder Pool WAF panel has been installed"
						check_docker_app_ip
						docker exec safeline-mgt resetadmin

						;;

					2)
						bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/upgrade.sh)"
						docker rmi $(docker images | grep "safeline" | grep "none" | awk '{print $3}')
						echo ""
						clear
echo "Thunder Pool WAF panel has been updated"
						check_docker_app_ip
						;;
					3)
						docker exec safeline-mgt resetadmin
						;;
					4)
						cd /data/safeline
						docker compose down --rmi all
echo "If you are the default installation directory, the project has been uninstalled now. If you are the custom installation directory, you need to go to the installation directory to execute it yourself:"
						echo "docker compose down && docker compose down --rmi all"
						;;
					*)
						break
						;;

				esac
				break_end
			done

			  ;;

		  20)
			local docker_name="portainer"
			local docker_img="portainer/portainer"
			local docker_port=9050
			local docker_rum="docker run -d \
					--name portainer \
					-p 9050:9000 \
					-v /var/run/docker.sock:/var/run/docker.sock \
					-v /home/docker/portainer:/data \
					--restart always \
					portainer/portainer"
			local docker_describe="portainer是一个轻量级的docker容器管理面板"
			local docker_url="官网介绍: https://www.portainer.io/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			  ;;

		  21)
			local docker_name="vscode-web"
			local docker_img="codercom/code-server"
			local docker_port=8180
			local docker_rum="docker run -d -p 8180:8080 -v /home/docker/vscode-web:/home/coder/.local/share/code-server --name vscode-web --restart always codercom/code-server"
			local docker_describe="VScode是一款强大的在线代码编写工具"
			local docker_url="官网介绍: ${gh_proxy}github.com/coder/code-server"
			local docker_use="sleep 3"
			local docker_passwd="docker exec vscode-web cat /home/coder/.config/code-server/config.yaml"
			local app_size="1"
			docker_app
			  ;;
		  22)
			local docker_name="uptime-kuma"
			local docker_img="louislam/uptime-kuma:latest"
			local docker_port=3003
			local docker_rum="docker run -d \
							--name=uptime-kuma \
							-p 3003:3001 \
							-v /home/docker/uptime-kuma/uptime-kuma-data:/app/data \
							--restart=always \
							louislam/uptime-kuma:latest"
			local docker_describe="Uptime Kuma 易于使用的自托管监控工具"
			local docker_url="官网介绍: ${gh_proxy}github.com/louislam/uptime-kuma"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  23)
			local docker_name="memos"
			local docker_img="ghcr.io/usememos/memos:latest"
			local docker_port=5230
			local docker_rum="docker run -d --name memos -p 5230:5230 -v /home/docker/memos:/var/opt/memos --restart always ghcr.io/usememos/memos:latest"
			local docker_describe="Memos是一款轻量级、自托管的备忘录中心"
			local docker_url="官网介绍: ${gh_proxy}github.com/usememos/memos"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  24)
			local docker_name="webtop"
			local docker_img="lscr.io/linuxserver/webtop:latest"
			local docker_port=3083
			local docker_rum="docker run -d \
						  --name=webtop \
						  --security-opt seccomp=unconfined \
						  -e PUID=1000 \
						  -e PGID=1000 \
						  -e TZ=Etc/UTC \
						  -e SUBFOLDER=/ \
						  -e TITLE=Webtop \
						  -e LC_ALL=zh_CN.UTF-8 \
						  -e DOCKER_MODS=linuxserver/mods:universal-package-install \
						  -e INSTALL_PACKAGES=font-noto-cjk \
						  -p 3083:3000 \
						  -v /home/docker/webtop/data:/config \
						  -v /var/run/docker.sock:/var/run/docker.sock \
						  --shm-size="1gb" \
						  --restart unless-stopped \
						  lscr.io/linuxserver/webtop:latest"

			local docker_describe="webtop基于 Alpine、Ubuntu、Fedora 和 Arch 的容器，包含官方支持的完整桌面环境，可通过任何现代 Web 浏览器访问"
			local docker_url="官网介绍: https://docs.linuxserver.io/images/docker-webtop/"
			local docker_use=""
			local docker_passwd=""
			local app_size="2"
			docker_app
			  ;;

		  25)
			local docker_name="nextcloud"
			local docker_img="nextcloud:latest"
			local docker_port=8989
			local rootpasswd=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
			local docker_rum="docker run -d --name nextcloud --restart=always -p 8989:80 -v /home/docker/nextcloud:/var/www/html -e NEXTCLOUD_ADMIN_USER=nextcloud -e NEXTCLOUD_ADMIN_PASSWORD=$rootpasswd nextcloud"
			local docker_describe="Nextcloud拥有超过 400,000 个部署，是您可以下载的最受欢迎的本地内容协作平台"
			local docker_url="官网介绍: https://nextcloud.com/"
			local docker_use="echo \"账号: nextcloud  密码: $rootpasswd\""
			local docker_passwd=""
			local app_size="3"
			docker_app
			  ;;

		  26)
			local docker_name="qd"
			local docker_img="qdtoday/qd:latest"
			local docker_port=8923
			local docker_rum="docker run -d --name qd -p 8923:80 -v /home/docker/qd/config:/usr/src/app/config qdtoday/qd"
			local docker_describe="QD-Today是一个HTTP请求定时任务自动执行框架"
			local docker_url="官网介绍: https://qd-today.github.io/qd/zh_CN/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;
		  27)
			local docker_name="dockge"
			local docker_img="louislam/dockge:latest"
			local docker_port=5003
			local docker_rum="docker run -d --name dockge --restart unless-stopped -p 5003:5001 -v /var/run/docker.sock:/var/run/docker.sock -v /home/docker/dockge/data:/app/data -v  /home/docker/dockge/stacks:/home/docker/dockge/stacks -e DOCKGE_STACKS_DIR=/home/docker/dockge/stacks louislam/dockge"
			local docker_describe="dockge是一个可视化的docker-compose容器管理面板"
			local docker_url="官网介绍: ${gh_proxy}github.com/louislam/dockge"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  28)
			local docker_name="speedtest"
			local docker_img="ghcr.io/librespeed/speedtest"
			local docker_port=8028
			local docker_rum="docker run -d -p 8028:8080 --name speedtest --restart always ghcr.io/librespeed/speedtest"
			local docker_describe="librespeed是用Javascript实现的轻量级速度测试工具，即开即用"
			local docker_url="官网介绍: ${gh_proxy}github.com/librespeed/speedtest"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  29)
			local docker_name="searxng"
			local docker_img="alandoyle/searxng:latest"
			local docker_port=8700
			local docker_rum="docker run --name=searxng \
							-d --init \
							--restart=unless-stopped \
							-v /home/docker/searxng/config:/etc/searxng \
							-v /home/docker/searxng/templates:/usr/local/searxng/searx/templates/simple \
							-v /home/docker/searxng/theme:/usr/local/searxng/searx/static/themes/simple \
							-p 8700:8080/tcp \
							alandoyle/searxng:latest"
			local docker_describe="searxng是一个私有且隐私的搜索引擎站点"
			local docker_url="官网介绍: https://hub.docker.com/r/alandoyle/searxng"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  30)
			local docker_name="photoprism"
			local docker_img="photoprism/photoprism:latest"
			local docker_port=2342
			local rootpasswd=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
			local docker_rum="docker run -d \
							--name photoprism \
							--restart always \
							--security-opt seccomp=unconfined \
							--security-opt apparmor=unconfined \
							-p 2342:2342 \
							-e PHOTOPRISM_UPLOAD_NSFW="true" \
							-e PHOTOPRISM_ADMIN_PASSWORD="$rootpasswd" \
							-v /home/docker/photoprism/storage:/photoprism/storage \
							-v /home/docker/photoprism/Pictures:/photoprism/originals \
							photoprism/photoprism"
			local docker_describe="photoprism非常强大的私有相册系统"
			local docker_url="官网介绍: https://www.photoprism.app/"
			local docker_use="echo \"账号: admin  密码: $rootpasswd\""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;


		  31)
			local docker_name="s-pdf"
			local docker_img="frooodle/s-pdf:latest"
			local docker_port=8020
			local docker_rum="docker run -d \
							--name s-pdf \
							--restart=always \
							 -p 8020:8080 \
							 -v /home/docker/s-pdf/trainingData:/usr/share/tesseract-ocr/5/tessdata \
							 -v /home/docker/s-pdf/extraConfigs:/configs \
							 -v /home/docker/s-pdf/logs:/logs \
							 -e DOCKER_ENABLE_SECURITY=false \
							 frooodle/s-pdf:latest"
			local docker_describe="这是一个强大的本地托管基于 Web 的 PDF 操作工具，使用 docker，允许您对 PDF 文件执行各种操作，例如拆分合并、转换、重新组织、添加图像、旋转、压缩等。"
			local docker_url="官网介绍: ${gh_proxy}github.com/Stirling-Tools/Stirling-PDF"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  32)
			local docker_name="drawio"
			local docker_img="jgraph/drawio"
			local docker_port=7080
			local docker_rum="docker run -d --restart=always --name drawio -p 7080:8080 -v /home/docker/drawio:/var/lib/drawio jgraph/drawio"
			local docker_describe="这是一个强大图表绘制软件。思维导图，拓扑图，流程图，都能画"
			local docker_url="官网介绍: https://www.drawio.com/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  33)
			local docker_name="sun-panel"
			local docker_img="hslr/sun-panel"
			local docker_port=3009
			local docker_rum="docker run -d --restart=always -p 3009:3002 \
							-v /home/docker/sun-panel/conf:/app/conf \
							-v /home/docker/sun-panel/uploads:/app/uploads \
							-v /home/docker/sun-panel/database:/app/database \
							--name sun-panel \
							hslr/sun-panel"
			local docker_describe="Sun-Panel服务器、NAS导航面板、Homepage、浏览器首页"
			local docker_url="官网介绍: https://doc.sun-panel.top/zh_cn/"
			local docker_use="echo \"账号: admin@sun.cc  密码: 12345678\""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  34)
			local docker_name="pingvin-share"
			local docker_img="stonith404/pingvin-share"
			local docker_port=3060
			local docker_rum="docker run -d \
							--name pingvin-share \
							--restart always \
							-p 3060:3000 \
							-v /home/docker/pingvin-share/data:/opt/app/backend/data \
							stonith404/pingvin-share"
			local docker_describe="Pingvin Share 是一个可自建的文件分享平台，是 WeTransfer 的一个替代品"
			local docker_url="官网介绍: ${gh_proxy}github.com/stonith404/pingvin-share"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;


		  35)
			local docker_name="moments"
			local docker_img="kingwrcy/moments:latest"
			local docker_port=8035
			local docker_rum="docker run -d --restart unless-stopped \
							-p 8035:3000 \
							-v /home/docker/moments/data:/app/data \
							-v /etc/localtime:/etc/localtime:ro \
							-v /etc/timezone:/etc/timezone:ro \
							--name moments \
							kingwrcy/moments:latest"
			local docker_describe="极简朋友圈，高仿微信朋友圈，记录你的美好生活"
			local docker_url="官网介绍: ${gh_proxy}github.com/kingwrcy/moments?tab=readme-ov-file"
			local docker_use="echo \"账号: admin  密码: a123456\""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;



		  36)
			local docker_name="lobe-chat"
			local docker_img="lobehub/lobe-chat:latest"
			local docker_port=8036
			local docker_rum="docker run -d -p 8036:3210 \
							--name lobe-chat \
							--restart=always \
							lobehub/lobe-chat"
			local docker_describe="LobeChat聚合市面上主流的AI大模型，ChatGPT/Claude/Gemini/Groq/Ollama"
			local docker_url="官网介绍: ${gh_proxy}github.com/lobehub/lobe-chat"
			local docker_use=""
			local docker_passwd=""
			local app_size="2"
			docker_app
			  ;;

		  37)
			local docker_name="myip"
			local docker_img="ghcr.io/jason5ng32/myip:latest"
			local docker_port=8037
			local docker_rum="docker run -d -p 8037:18966 --name myip --restart always ghcr.io/jason5ng32/myip:latest"
			local docker_describe="是一个多功能IP工具箱，可以查看自己IP信息及连通性，用网页面板呈现"
			local docker_url="官网介绍: ${gh_proxy}github.com/jason5ng32/MyIP/blob/main/README_ZH.md"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  38)
			send_stats "小雅全家桶"
			clear
			install_docker
			check_disk_space 1
			bash -c "$(curl --insecure -fsSL https://ddsrem.com/xiaoya_install.sh)"
			  ;;

		  39)

			if [ ! -d /home/docker/bililive-go/ ]; then
				mkdir -p /home/docker/bililive-go/ > /dev/null 2>&1
				wget -O /home/docker/bililive-go/config.yml ${gh_proxy}raw.githubusercontent.com/hr3lxphr6j/bililive-go/master/config.yml > /dev/null 2>&1
			fi

			local docker_name="bililive-go"
			local docker_img="chigusa/bililive-go"
			local docker_port=8039
			local docker_rum="docker run --restart=always --name bililive-go -v /home/docker/bililive-go/config.yml:/etc/bililive-go/config.yml -v /home/docker/bililive-go/Videos:/srv/bililive -p 8039:8080 -d chigusa/bililive-go"
			local docker_describe="Bililive-go是一个支持多种直播平台的直播录制工具"
			local docker_url="官网介绍: ${gh_proxy}github.com/hr3lxphr6j/bililive-go"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  40)
			local docker_name="webssh"
			local docker_img="jrohy/webssh"
			local docker_port=8040
			local docker_rum="docker run -d -p 8040:5032 --restart always --name webssh -e TZ=Asia/Shanghai jrohy/webssh"
			local docker_describe="简易在线ssh连接工具和sftp工具"
			local docker_url="官网介绍: ${gh_proxy}github.com/Jrohy/webssh"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  41)

			local lujing="[ -d "/www/server/panel" ]"
			local panelname="耗子面板"
			local panelurl="官方地址: ${gh_proxy}github.com/TheTNB/panel"

			panel_app_install() {
				mkdir -p ~/haozi && cd ~/haozi && curl -fsLm 10 -o install.sh https://dl.cdn.haozi.net/panel/install.sh && bash install.sh
				cd ~
			}

			panel_app_manage() {
				panel-cli
			}

			panel_app_uninstall() {
				mkdir -p ~/haozi && cd ~/haozi && curl -fsLm 10 -o uninstall.sh https://dl.cdn.haozi.net/panel/uninstall.sh && bash uninstall.sh
				cd ~
			}

			install_panel

			  ;;


		  42)
			local docker_name="nexterm"
			local docker_img="germannewsmaker/nexterm:latest"
			local docker_port=8042
			local docker_rum="docker run -d \
						  --name nexterm \
						  -p 8042:6989 \
						  -v /home/docker/nexterm:/app/data \
						  --restart unless-stopped \
						  germannewsmaker/nexterm:latest"
			local docker_describe="nexterm是一款强大的在线SSH/VNC/RDP连接工具。"
			local docker_url="官网介绍: ${gh_proxy}github.com/gnmyt/Nexterm"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  43)
			local docker_name="hbbs"
			local docker_img="rustdesk/rustdesk-server"
			local docker_port=21116
			local docker_rum="docker run --name hbbs -v /home/docker/hbbs/data:/root -td --net=host --restart unless-stopped rustdesk/rustdesk-server hbbs"
			local docker_describe="rustdesk开源的远程桌面(服务端)，类似自己的向日葵私服。"
			local docker_url="官网介绍: https://rustdesk.com/zh-cn/"
			local docker_use="docker logs hbbs"
			local docker_passwd="echo \"把你的IP和key记录下，会在远程桌面客户端中用到。去44选项装中继端吧！\""
			local app_size="1"
			docker_app
			  ;;

		  44)
			local docker_name="hbbr"
			local docker_img="rustdesk/rustdesk-server"
			local docker_port=21116
			local docker_rum="docker run --name hbbr -v /home/docker/hbbr/data:/root -td --net=host --restart unless-stopped rustdesk/rustdesk-server hbbr"
			local docker_describe="rustdesk开源的远程桌面(中继端)，类似自己的向日葵私服。"
			local docker_url="官网介绍: https://rustdesk.com/zh-cn/"
			local docker_use="echo \"前往官网下载远程桌面的客户端: https://rustdesk.com/zh-cn/\""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  45)
			local docker_name="registry"
			local docker_img="registry:2"
			local docker_port=8045
			local docker_rum="docker run -d \
							-p 8045:5000 \
							--name registry \
							-v /home/docker/registry:/var/lib/registry \
							-e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
							--restart always \
							registry:2"
			local docker_describe="Docker Registry 是一个用于存储和分发 Docker 镜像的服务。"
			local docker_url="官网介绍: https://hub.docker.com/_/registry"
			local docker_use=""
			local docker_passwd=""
			local app_size="2"
			docker_app
			  ;;

		  46)
			local docker_name="ghproxy"
			local docker_img="wjqserver/ghproxy:latest"
			local docker_port=8046
			local docker_rum="docker run -d --name ghproxy --restart always -p 8046:8080 wjqserver/ghproxy:latest"
			local docker_describe="使用Go实现的GHProxy，用于加速部分地区Github仓库的拉取。"
			local docker_url="官网介绍: https://github.com/WJQSERVER-STUDIO/ghproxy"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  47)



			local app_name="普罗米修斯监控"
			local app_text="Prometheus+Grafana企业级监控系统"
			local app_url="官网介绍: https://prometheus.io"
			local docker_name="grafana"
			local docker_port="8047"
			local app_size="2"

			docker_app_install() {
				prometheus_install
				clear
				ip_address
echo "Installed"
				check_docker_app_ip
echo "The initial username and password are: admin"
			}

			docker_app_update() {
				docker rm -f node-exporter prometheus grafana
				docker rmi -f prom/node-exporter
				docker rmi -f prom/prometheus:latest
				docker rmi -f grafana/grafana:latest
				docker_app_install
			}

			docker_app_uninstall() {
				docker rm -f node-exporter prometheus grafana
				docker rmi -f prom/node-exporter
				docker rmi -f prom/prometheus:latest
				docker rmi -f grafana/grafana:latest

				rm -rf /home/docker/monitoring
echo "App uninstalled"
			}

			docker_app_plus
			  ;;

		  48)
			local docker_name="node-exporter"
			local docker_img="prom/node-exporter"
			local docker_port=8048
			local docker_rum="docker run -d \
  								--name=node-exporter \
  								-p 8048:9100 \
  								--restart unless-stopped \
  								prom/node-exporter"
			local docker_describe="这是一个普罗米修斯的主机数据采集组件，请部署在被监控主机上。"
			local docker_url="官网介绍: https://github.com/prometheus/node_exporter"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  49)
			local docker_name="cadvisor"
			local docker_img="gcr.io/cadvisor/cadvisor:latest"
			local docker_port=8049
			local docker_rum="docker run -d \
  								--name=cadvisor \
  								--restart unless-stopped \
  								-p 8049:8080 \
  								--volume=/:/rootfs:ro \
  								--volume=/var/run:/var/run:rw \
  								--volume=/sys:/sys:ro \
  								--volume=/var/lib/docker/:/var/lib/docker:ro \
  								gcr.io/cadvisor/cadvisor:latest \
  								-housekeeping_interval=10s \
  								-docker_only=true"
			local docker_describe="这是一个普罗米修斯的容器数据采集组件，请部署在被监控主机上。"
			local docker_url="官网介绍: https://github.com/google/cadvisor"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;


		  50)
			local docker_name="changedetection"
			local docker_img="dgtlmoon/changedetection.io:latest"
			local docker_port=8050
			local docker_rum="docker run -d --restart always -p 8050:5000 \
								-v /home/docker/datastore:/datastore \
								--name changedetection dgtlmoon/changedetection.io:latest"
			local docker_describe="这是一款网站变化检测、补货监控和通知的小工具"
			local docker_url="官网介绍: https://github.com/dgtlmoon/changedetection.io"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;


		  51)
			clear
			send_stats "PVE开小鸡"
			check_disk_space 1
			curl -L ${gh_proxy}raw.githubusercontent.com/oneclickvirt/pve/main/scripts/install_pve.sh -o install_pve.sh && chmod +x install_pve.sh && bash install_pve.sh
			  ;;


		  52)
			local docker_name="dpanel"
			local docker_img="dpanel/dpanel:lite"
			local docker_port=8052
			local docker_rum="docker run -it -d --name dpanel --restart=always \
  								-p 8052:8080 -e APP_NAME=dpanel \
  								-v /var/run/docker.sock:/var/run/docker.sock \
  								-v /home/docker/dpanel:/dpanel \
  								dpanel/dpanel:lite"
			local docker_describe="Docker可视化面板系统，提供完善的docker管理功能。"
			local docker_url="官网介绍: https://github.com/donknap/dpanel"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  53)
			local docker_name="ollama"
			local docker_img="ghcr.io/open-webui/open-webui:ollama"
			local docker_port=8053
			local docker_rum="docker run -d -p 8053:8080 -v /home/docker/ollama:/root/.ollama -v /home/docker/ollama/open-webui:/app/backend/data --name ollama --restart always ghcr.io/open-webui/open-webui:ollama"
			local docker_describe="OpenWebUI一款大语言模型网页框架，接入全新的llama3大语言模型"
			local docker_url="官网介绍: https://github.com/open-webui/open-webui"
			local docker_use="docker exec ollama ollama run llama3.2:1b"
			local docker_passwd=""
			local app_size="5"
			docker_app
			  ;;

		  54)

			local lujing="[ -d "/www/server/panel" ]"
			local panelname="AMH面板"
			local panelurl="官方地址: https://amh.sh/index.htm?amh"

			panel_app_install() {
				cd ~
				wget https://dl.amh.sh/amh.sh && bash amh.sh
			}

			panel_app_manage() {
				panel_app_install
			}

			panel_app_uninstall() {
				panel_app_install
			}

			install_panel
			  ;;


		  55)
		  	frps_panel
			  ;;

		  56)
			frpc_panel
			  ;;

		  57)
			local docker_name="ollama"
			local docker_img="ghcr.io/open-webui/open-webui:ollama"
			local docker_port=8053
			local docker_rum="docker run -d -p 8053:8080 -v /home/docker/ollama:/root/.ollama -v /home/docker/ollama/open-webui:/app/backend/data --name ollama --restart always ghcr.io/open-webui/open-webui:ollama"
			local docker_describe="OpenWebUI一款大语言模型网页框架，接入全新的DeepSeek R1大语言模型"
			local docker_url="官网介绍: https://github.com/open-webui/open-webui"
			local docker_use="docker exec ollama ollama run deepseek-r1:1.5b"
			local docker_passwd=""
			local app_size="5"
			docker_app
			  ;;


		  58)
			local app_name="Dify知识库"
			local app_text="是一款开源的大语言模型(LLM) 应用开发平台。自托管训练数据用于AI生成"
			local app_url="官方网站: https://docs.dify.ai/zh-hans"
			local docker_name="docker-web-1"
			local docker_port="8058"
			local app_size="3"

			docker_app_install() {
				install git
				mkdir -p  /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/langgenius/dify.git && cd dify/docker && cp .env.example .env
				sed -i 's/^EXPOSE_NGINX_PORT=.*/EXPOSE_NGINX_PORT=8058/; s/^EXPOSE_NGINX_SSL_PORT=.*/EXPOSE_NGINX_SSL_PORT=8858/' /home/docker/dify/docker/.env
				docker compose up -d
				clear
echo "Installed"
				check_docker_app_ip
			}

			docker_app_update() {
				cd  /home/docker/dify/docker/ && docker compose down --rmi all
				cd  /home/docker/dify/
				git pull origin main
				sed -i 's/^EXPOSE_NGINX_PORT=.*/EXPOSE_NGINX_PORT=8058/; s/^EXPOSE_NGINX_SSL_PORT=.*/EXPOSE_NGINX_SSL_PORT=8858/' /home/docker/dify/docker/.env
				cd  /home/docker/dify/docker/ && docker compose up -d
			}

			docker_app_uninstall() {
				cd  /home/docker/dify/docker/ && docker compose down --rmi all
				rm -rf /home/docker/dify
echo "App uninstalled"
			}

			docker_app_plus

			  ;;

		  59)
			local app_name="New API"
			local app_text="新一代大模型网关与AI资产管理系统"
			local app_url="官方网站: https://github.com/Calcium-Ion/new-api"
			local docker_name="new-api"
			local docker_port="8059"
			local app_size="3"

			docker_app_install() {
				install git
				mkdir -p  /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/Calcium-Ion/new-api.git && cd new-api
				sed -i -e 's/- "3000:3000"/- "8059:3000"/g' \
					   -e 's/container_name: redis/container_name: redis-new-api/g' \
					   -e 's/container_name: mysql/container_name: mysql-new-api/g' docker-compose.yml

				docker compose up -d
				clear
echo "Installed"
				check_docker_app_ip
			}

			docker_app_update() {
				cd  /home/docker/new-api/ && docker compose down --rmi all
				cd  /home/docker/new-api/
				git pull origin main
				sed -i -e 's/- "3000:3000"/- "8059:3000"/g' \
					   -e 's/container_name: redis/container_name: redis-new-api/g' \
					   -e 's/container_name: mysql/container_name: mysql-new-api/g' docker-compose.yml
				docker compose up -d
				clear
echo "Installed"
				check_docker_app_ip

			}

			docker_app_uninstall() {
				cd  /home/docker/new-api/ && docker compose down --rmi all
				rm -rf /home/docker/new-api
echo "App uninstalled"
			}

			docker_app_plus

			  ;;


		  60)

			local app_name="JumpServer开源堡垒机"
			local app_text="是一个开源的特权访问管理 (PAM) 工具，该程序占用80端口不支持添加域名访问了"
			local app_url="官方介绍: https://github.com/jumpserver/jumpserver"
			local docker_name="jms_web"
			local docker_port="80"
			local app_size="2"

			docker_app_install() {
				curl -sSL ${gh_proxy}github.com/jumpserver/jumpserver/releases/latest/download/quick_start.sh | bash
				clear
echo "Installed"
				check_docker_app_ip
echo "Initial Username: admin"
echo "Initial Password: ChangeMe"
			}


			docker_app_update() {
				cd /opt/jumpserver-installer*/
				./jmsctl.sh upgrade
echo "App updated"
			}


			docker_app_uninstall() {
				cd /opt/jumpserver-installer*/
				./jmsctl.sh uninstall
				cd /opt
				rm -rf jumpserver-installer*/
				rm -rf jumpserver
echo "App uninstalled"
			}

			docker_app_plus
			  ;;

		  61)
			local docker_name="libretranslate"
			local docker_img="libretranslate/libretranslate:latest"
			local docker_port=8061
			local docker_rum="docker run -d \
  								-p 8061:5000 \
  								--name libretranslate \
  								libretranslate/libretranslate \
  								--load-only ko,zt,zh,en,ja,pt,es,fr,de,ru"
			local docker_describe="免费开源机器翻译 API，完全自托管，它的翻译引擎由开源Argos Translate库提供支持。"
			local docker_url="官网介绍: https://github.com/LibreTranslate/LibreTranslate"
			local docker_use=""
			local docker_passwd=""
			local app_size="5"
			docker_app
			  ;;



		  62)
			local app_name="RAGFlow知识库"
			local app_text="基于深度文档理解的开源 RAG（检索增强生成）引擎"
			local app_url="官方网站: https://github.com/infiniflow/ragflow"
			local docker_name="ragflow-server"
			local docker_port="8062"
			local app_size="8"

			docker_app_install() {
				install git
				mkdir -p  /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/infiniflow/ragflow.git && cd ragflow/docker
				sed -i 's/- 80:80/- 8062:80/; /- 443:443/d' docker-compose.yml
				docker compose up -d
				clear
echo "Installed"
				check_docker_app_ip
			}

			docker_app_update() {
				cd  /home/docker/ragflow/docker/ && docker compose down --rmi all
				cd  /home/docker/ragflow/
				git pull origin main
				cd  /home/docker/ragflow/docker/
				sed -i 's/- 80:80/- 8062:80/; /- 443:443/d' docker-compose.yml
				docker compose up -d
			}

			docker_app_uninstall() {
				cd  /home/docker/ragflow/docker/ && docker compose down --rmi all
				rm -rf /home/docker/ragflow
echo "App uninstalled"
			}

			docker_app_plus

			  ;;




		  0)
			  kejilion
			  ;;
		  *)
echo "Invalid input!"
			  ;;
	  esac
	  break_end

	done
}


linux_work() {

	while true; do
	  clear
	  send_stats "我的工作区"
echo -e "My Workspace"
echo -e "The system will provide you with a workspace that can be run on the backend, which you can use to perform long-term tasks"
echo -e "Even if you disconnect SSH, tasks in the workspace will not be interrupted, and tasks in the background will be resident."
echo -e "${gl_huang} prompt: After entering the workspace, use Ctrl+b and press d alone to exit the workspace!"
	  echo -e "${gl_kjlan}------------------------"
echo "Currently existing workspace list"
	  echo -e "${gl_kjlan}------------------------"
	  tmux list-sessions
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}1. ${gl_bai}1 workspace"
echo -e "${gl_kjlan}2. ${gl_bai}2 workspace"
echo -e "${gl_kjlan}3. ${gl_bai}3 workspace"
echo -e "${gl_kjlan}4. ${gl_bai}4 workspace"
echo -e "${gl_kjlan}5. ${gl_bai}5 workspace"
echo -e "${gl_kjlan}6. ${gl_bai}6 workspace"
echo -e "${gl_kjlan}7. ${gl_bai}7 workspace"
echo -e "${gl_kjlan}8. ${gl_bai}8 workspace"
echo -e "${gl_kjlan}9. ${gl_bai}9 workspace"
echo -e "${gl_kjlan}10. ${gl_bai}10 workspace"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}21. ${gl_bai}SSH resident mode ${gl_huang}★${gl_bai}"
echo -e "${gl_kjlan}22. ${gl_bai}Create/enter the workspace"
echo -e "${gl_kjlan}23. ${gl_bai} inject command into background workspace"
echo -e "${gl_kjlan}24. ${gl_bai}Delete the specified workspace"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}0. ${gl_bai} returns to main menu"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "请输入你的选择: " sub_choice

	  case $sub_choice in

		  1)
			  clear
			  install tmux
			  local SESSION_NAME="work1"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run

			  ;;
		  2)
			  clear
			  install tmux
			  local SESSION_NAME="work2"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;
		  3)
			  clear
			  install tmux
			  local SESSION_NAME="work3"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;
		  4)
			  clear
			  install tmux
			  local SESSION_NAME="work4"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;
		  5)
			  clear
			  install tmux
			  local SESSION_NAME="work5"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;
		  6)
			  clear
			  install tmux
			  local SESSION_NAME="work6"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;
		  7)
			  clear
			  install tmux
			  local SESSION_NAME="work7"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;
		  8)
			  clear
			  install tmux
			  local SESSION_NAME="work8"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;
		  9)
			  clear
			  install tmux
			  local SESSION_NAME="work9"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;
		  10)
			  clear
			  install tmux
			  local SESSION_NAME="work10"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;

		  21)
			while true; do
			  clear
			  if grep -q 'tmux attach-session -t sshd || tmux new-session -s sshd' ~/.bashrc; then
				  local tmux_sshd_status="${gl_lv}开启${gl_bai}"
			  else
				  local tmux_sshd_status="${gl_hui}关闭${gl_bai}"
			  fi
			  send_stats "SSH常驻模式 "
echo -e "SSH resident mode ${tmux_sshd_status}"
echo "After opening, SSH connection will be directly entered into the resident mode and will directly return to the previous working state."
			  echo "------------------------"
echo "1. Turn on 2. Turn off"
			  echo "------------------------"
echo "0. Return to previous menu"
			  echo "------------------------"
			  read -e -p "请输入你的选择: " gongzuoqu_del
			  case "$gongzuoqu_del" in
				1)
			  	  install tmux
			  	  local SESSION_NAME="sshd"
			  	  send_stats "启动工作区$SESSION_NAME"
				  grep -q "tmux attach-session -t sshd" ~/.bashrc || echo -e "\n# 自动进入 tmux 会话\nif [[ -z \"\$TMUX\" ]]; then\n    tmux attach-session -t sshd || tmux new-session -s sshd\nfi" >> ~/.bashrc
				  source ~/.bashrc
			  	  tmux_run
				  ;;
				2)
				  sed -i '/# 自动进入 tmux 会话/,+4d' ~/.bashrc
				  tmux kill-window -t sshd
				  ;;
				*)
				  break
				  ;;
			  esac
			done
			  ;;

		  22)
			  read -e -p "请输入你创建或进入的工作区名称，如1001 kj001 work1: " SESSION_NAME
			  tmux_run
			  send_stats "自定义工作区"
			  ;;


		  23)
			  read -e -p "请输入你要后台执行的命令，如:curl -fsSL https://get.docker.com | sh: " tmuxd
			  tmux_run_d
			  send_stats "注入命令到后台工作区"
			  ;;

		  24)
			  read -e -p "请输入要删除的工作区名称: " gongzuoqu_name
			  tmux kill-window -t $gongzuoqu_name
			  send_stats "删除工作区"
			  ;;

		  0)
			  kejilion
			  ;;
		  *)
echo "Invalid input!"
			  ;;
	  esac
	  break_end

	done


}












linux_Settings() {

	while true; do
	  clear
	  # send_stats "系统工具"
echo -e "System Tools"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}1. ${gl_bai}Set script startup shortcut key ${gl_kjlan}2. ${gl_bai}Modify login password"
echo -e "${gl_kjlan}3. ${gl_bai}ROOT password login mode ${gl_kjlan}4. ${gl_bai}install Python specified version"
echo -e "${gl_kjlan}5. ${gl_bai}Open all ports ${gl_kjlan}6. ${gl_bai}Modify SSH connection port"
echo -e "${gl_kjlan}7. ${gl_bai}Optimized DNS address ${gl_kjlan}8. ${gl_bai}One-click reinstall system ${gl_huang}★${gl_bai}"
echo -e "${gl_kjlan}9. ${gl_bai}Disable ROOT account to create a new account ${gl_kjlan}10. ${gl_bai}Switch priority ipv4/ipv6"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}11. ${gl_bai}View port occupation status ${gl_kjlan}12. ${gl_bai}Modify virtual memory size"
echo -e "${gl_kjlan}13. ${gl_bai}User Management ${gl_kjlan}14. ${gl_bai}User/Password Generator"
echo -e "${gl_kjlan}15. ${gl_bai}System time zone adjustment ${gl_kjlan}16. ${gl_bai}Set BBR3 acceleration"
echo -e "${gl_kjlan}17. ${gl_bai}Firewall Advanced Manager ${gl_kjlan}18. ${gl_bai}Modify the hostname"
echo -e "${gl_kjlan}19. ${gl_bai}Switch system update source ${gl_kjlan}20. ${gl_bai}Timed Task Management"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}21. ${gl_bai}Native host parsing ${gl_kjlan}22. ${gl_bai}SSH defense program"
echo -e "${gl_kjlan}23. ${gl_bai} current limit automatic shutdown ${gl_kjlan}24. ${gl_bai}ROOT private key login mode"
echo -e "${gl_kjlan}25. ${gl_bai}TG-bot system monitoring and warning ${gl_kjlan}26. ${gl_bai} fix OpenSSH high-risk vulnerability (Xiuyuan)"
echo -e "${gl_kjlan}27. ${gl_bai}Red Hat Linux kernel upgrade ${gl_kjlan}28. ${gl_bai}Linux system kernel parameter optimization ${gl_huang}★${gl_bai}"
echo -e "${gl_kjlan}29. ${gl_bai}Virus Scan Tool ${gl_huang}★${gl_bai} ${gl_kjlan}30. ${gl_bai} File Manager"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}31. ${gl_bai}Switch system language ${gl_kjlan}32. ${gl_bai}Command line beautification tool ${gl_huang}★${gl_bai}"
echo -e "${gl_kjlan}33. ${gl_bai}Set the system recycling bin ${gl_kjlan}34. ${gl_bai}System backup and recovery"
echo -e "${gl_kjlan}35. ${gl_bai}ssh remote connection tool ${gl_kjlan}36. ${gl_bai}hard disk partition management tool"
echo -e "${gl_kjlan}37. ${gl_bai}Command line history ${gl_kjlan}38. ${gl_bai}rsync Remote Synchronization Tool"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}41. ${gl_bai}Message Board ${gl_kjlan}66. ${gl_bai} One-stop system tuning ${gl_huang}★${gl_bai}"
echo -e "${gl_kjlan}99. ${gl_bai}Restart the server ${gl_kjlan}100. ${gl_bai}Privacy and Security"
echo -e "${gl_kjlan}101. Advanced usage of ${gl_bai}k command ${gl_huang}★${gl_bai} ${gl_kjlan}102. ${gl_bai} Uninstall the technology lion script"
	  echo -e "${gl_kjlan}------------------------"
echo -e "${gl_kjlan}0. ${gl_bai} returns to main menu"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "请输入你的选择: " sub_choice

	  case $sub_choice in
		  1)
			  while true; do
				  clear
				  read -e -p "请输入你的快捷按键（输入0退出）: " kuaijiejian
				  if [ "$kuaijiejian" == "0" ]; then
					   break_end
					   linux_Settings
				  fi
				  find /usr/local/bin/ -type l -exec bash -c 'test "$(readlink -f {})" = "/usr/local/bin/k" && rm -f {}' \;
				  ln -s /usr/local/bin/k /usr/local/bin/$kuaijiejian
echo "Shortcut keys set"
				  send_stats "脚本快捷键已设置"
				  break_end
				  linux_Settings
			  done
			  ;;

		  2)
			  clear
			  send_stats "设置你的登录密码"
echo "Set your login password"
			  passwd
			  ;;
		  3)
			  root_use
			  send_stats "root密码模式"
			  add_sshpasswd
			  ;;

		  4)
			root_use
			send_stats "py版本管理"
echo "python version management"
echo "Video introduction: https://www.bilibili.com/video/BV1Pm42157cK?t=0.1"
			echo "---------------------------------------"
echo "This feature seamlessly installs any version officially supported by python!"
			local VERSION=$(python3 -V 2>&1 | awk '{print $2}')
echo -e "Current python version number: ${gl_huang}$VERSION${gl_bai}"
			echo "------------"
echo "Recommended version: 3.12 3.11 3.10 3.9 3.8 2.7"
echo "Query more versions: https://www.python.org/downloads/"
			echo "------------"
			read -e -p "输入你要安装的python版本号（输入0退出）: " py_new_v


			if [[ "$py_new_v" == "0" ]]; then
				send_stats "脚本PY管理"
				break_end
				linux_Settings
			fi


			if ! grep -q 'export PYENV_ROOT="\$HOME/.pyenv"' ~/.bashrc; then
				if command -v yum &>/dev/null; then
					yum update -y && yum install git -y
					yum groupinstall "Development Tools" -y
					yum install openssl-devel bzip2-devel libffi-devel ncurses-devel zlib-devel readline-devel sqlite-devel xz-devel findutils -y

					curl -O https://www.openssl.org/source/openssl-1.1.1u.tar.gz
					tar -xzf openssl-1.1.1u.tar.gz
					cd openssl-1.1.1u
					./config --prefix=/usr/local/openssl --openssldir=/usr/local/openssl shared zlib
					make
					make install
					echo "/usr/local/openssl/lib" > /etc/ld.so.conf.d/openssl-1.1.1u.conf
					ldconfig -v
					cd ..

					export LDFLAGS="-L/usr/local/openssl/lib"
					export CPPFLAGS="-I/usr/local/openssl/include"
					export PKG_CONFIG_PATH="/usr/local/openssl/lib/pkgconfig"

				elif command -v apt &>/dev/null; then
					apt update -y && apt install git -y
					apt install build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev libgdbm-dev libnss3-dev libedit-dev -y
				elif command -v apk &>/dev/null; then
					apk update && apk add git
					apk add --no-cache bash gcc musl-dev libffi-dev openssl-dev bzip2-dev zlib-dev readline-dev sqlite-dev libc6-compat linux-headers make xz-dev build-base  ncurses-dev
				else
echo "Unknown package manager!"
					return
				fi

				curl https://pyenv.run | bash
				cat << EOF >> ~/.bashrc

export PYENV_ROOT="\$HOME/.pyenv"
if [[ -d "\$PYENV_ROOT/bin" ]]; then
  export PATH="\$PYENV_ROOT/bin:\$PATH"
fi
eval "\$(pyenv init --path)"
eval "\$(pyenv init -)"
eval "\$(pyenv virtualenv-init -)"

EOF

			fi

			sleep 1
			source ~/.bashrc
			sleep 1
			pyenv install $py_new_v
			pyenv global $py_new_v

			rm -rf /tmp/python-build.*
			rm -rf $(pyenv root)/cache/*

			local VERSION=$(python -V 2>&1 | awk '{print $2}')
echo -e "Current python version number: ${gl_huang}$VERSION${gl_bai}"
			send_stats "脚本PY版本切换"

			  ;;

		  5)
			  root_use
			  send_stats "开放端口"
			  iptables_open
			  remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1
echo "The ports are all open"

			  ;;
		  6)
			root_use
			send_stats "修改SSH端口"

			while true; do
				clear
				sed -i 's/#Port/Port/' /etc/ssh/sshd_config

				# 读取当前的 SSH 端口号
				local current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

				# 打印当前的 SSH 端口号
echo -e "The current SSH port number is: ${gl_huang}$current_port ${gl_bai}"

				echo "------------------------"
echo "Numbers between port number range 1 and 65535. (Input 0 to exit)"

				# 提示用户输入新的 SSH 端口号
				read -e -p "请输入新的 SSH 端口号: " new_port

				# 判断端口号是否在有效范围内
				if [[ $new_port =~ ^[0-9]+$ ]]; then  # 检查输入是否为数字
					if [[ $new_port -ge 1 && $new_port -le 65535 ]]; then
						send_stats "SSH端口已修改"
						new_ssh_port
					elif [[ $new_port -eq 0 ]]; then
						send_stats "退出SSH端口修改"
						break
					else
echo "The port number is invalid, please enter a number between 1 and 65535."
						send_stats "输入无效SSH端口"
						break_end
					fi
				else
echo "Input is invalid, please enter the number."
					send_stats "输入无效SSH端口"
					break_end
				fi
			done


			  ;;


		  7)
			set_dns_ui
			  ;;

		  8)

			dd_xitong
			  ;;
		  9)
			root_use
			send_stats "新用户禁用root"
			read -e -p "请输入新用户名（输入0退出）: " new_username
			if [ "$new_username" == "0" ]; then
				break_end
				linux_Settings
			fi

			useradd -m -s /bin/bash "$new_username"
			passwd "$new_username"

			echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

			passwd -l root

echo "The operation has been completed."
			;;


		  10)
			root_use
			send_stats "设置v4/v6优先级"
			while true; do
				clear
echo "Set v4/v6 priority"
				echo "------------------------"
				local ipv6_disabled=$(sysctl -n net.ipv6.conf.all.disable_ipv6)

				if [ "$ipv6_disabled" -eq 1 ]; then
echo -e "Current network priority setting: ${gl_huang}IPv4${gl_bai} priority"
				else
echo -e "Current network priority setting: ${gl_huang}IPv6${gl_bai} priority"
				fi
				echo ""
				echo "------------------------"
echo "1. IPv4 priority 2. IPv6 priority 3. IPv6 repair tool"
				echo "------------------------"
echo "0. Return to previous menu"
				echo "------------------------"
				read -e -p "选择优先的网络: " choice

				case $choice in
					1)
						sysctl -w net.ipv6.conf.all.disable_ipv6=1 > /dev/null 2>&1
echo "Switched to IPv4 priority"
						send_stats "已切换为 IPv4 优先"
						;;
					2)
						sysctl -w net.ipv6.conf.all.disable_ipv6=0 > /dev/null 2>&1
echo "Switched to IPv6 first"
						send_stats "已切换为 IPv6 优先"
						;;

					3)
						clear
						bash <(curl -L -s jhb.ovh/jb/v6.sh)
echo "This feature is provided by the master jhb, thanks!"
						send_stats "ipv6修复"
						;;

					*)
						break
						;;

				esac
			done
			;;

		  11)
			clear
			ss -tulnape
			;;

		  12)
			root_use
			send_stats "设置虚拟内存"
			while true; do
				clear
echo "Set virtual memory"
				local swap_used=$(free -m | awk 'NR==3{print $3}')
				local swap_total=$(free -m | awk 'NR==3{print $2}')
				local swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}')

echo -e "Current virtual memory: ${gl_huang}$swap_info${gl_bai}"
				echo "------------------------"
echo "1. Allocate 1024M 2. Allocate 2048M 3. Allocate 4096M 4. Customize Size"
				echo "------------------------"
echo "0. Return to previous menu"
				echo "------------------------"
				read -e -p "请输入你的选择: " choice

				case "$choice" in
				  1)
					send_stats "已设置1G虚拟内存"
					add_swap 1024

					;;
				  2)
					send_stats "已设置2G虚拟内存"
					add_swap 2048

					;;
				  3)
					send_stats "已设置4G虚拟内存"
					add_swap 4096

					;;

				  4)
					read -e -p "请输入虚拟内存大小（单位M）: " new_swap
					add_swap "$new_swap"
					send_stats "已设置自定义虚拟内存"
					;;

				  *)
					break
					;;
				esac
			done
			;;

		  13)
			  while true; do
				root_use
				send_stats "用户管理"
echo "User List"
				echo "----------------------------------------------------------------------------"
				printf "%-24s %-34s %-20s %-10s\n" "用户名" "用户权限" "用户组" "sudo权限"
				while IFS=: read -r username _ userid groupid _ _ homedir shell; do
					local groups=$(groups "$username" | cut -d : -f 2)
					local sudo_status=$(sudo -n -lU "$username" 2>/dev/null | grep -q '(ALL : ALL)' && echo "Yes" || echo "No")
					printf "%-20s %-30s %-20s %-10s\n" "$username" "$homedir" "$groups" "$sudo_status"
				done < /etc/passwd


				  echo ""
echo "Account Operation"
				  echo "------------------------"
echo "1. Create a normal account 2. Create a premium account"
				  echo "------------------------"
echo "3. Grant the highest permissions 4. Cancel the highest permissions"
				  echo "------------------------"
echo "5. Delete the account"
				  echo "------------------------"
echo "0. Return to previous menu"
				  echo "------------------------"
				  read -e -p "请输入你的选择: " sub_choice

				  case $sub_choice in
					  1)
					   # 提示用户输入新用户名
					   read -e -p "请输入新用户名: " new_username

					   # 创建新用户并设置密码
					   useradd -m -s /bin/bash "$new_username"
					   passwd "$new_username"

echo "The operation has been completed."
						  ;;

					  2)
					   # 提示用户输入新用户名
					   read -e -p "请输入新用户名: " new_username

					   # 创建新用户并设置密码
					   useradd -m -s /bin/bash "$new_username"
					   passwd "$new_username"

					   # 赋予新用户sudo权限
					   echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

echo "The operation has been completed."

						  ;;
					  3)
					   read -e -p "请输入用户名: " username
					   # 赋予新用户sudo权限
					   echo "$username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers
						  ;;
					  4)
					   read -e -p "请输入用户名: " username
					   # 从sudoers文件中移除用户的sudo权限
					   sed -i "/^$username\sALL=(ALL:ALL)\sALL/d" /etc/sudoers

						  ;;
					  5)
					   read -e -p "请输入要删除的用户名: " username
					   # 删除用户及其主目录
					   userdel -r "$username"
						  ;;

					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done
			  ;;

		  14)
			clear
			send_stats "用户信息生成器"
echo "Random Username"
			echo "------------------------"
			for i in {1..5}; do
				username="user$(< /dev/urandom tr -dc _a-z0-9 | head -c6)"
echo "Random username $i: $username"
			done

			echo ""
echo "Random Name"
			echo "------------------------"
			local first_names=("John" "Jane" "Michael" "Emily" "David" "Sophia" "William" "Olivia" "James" "Emma" "Ava" "Liam" "Mia" "Noah" "Isabella")
			local last_names=("Smith" "Johnson" "Brown" "Davis" "Wilson" "Miller" "Jones" "Garcia" "Martinez" "Williams" "Lee" "Gonzalez" "Rodriguez" "Hernandez")

			# 生成5个随机用户姓名
			for i in {1..5}; do
				local first_name_index=$((RANDOM % ${#first_names[@]}))
				local last_name_index=$((RANDOM % ${#last_names[@]}))
				local user_name="${first_names[$first_name_index]} ${last_names[$last_name_index]}"
echo "Random user name $i: $user_name"
			done

			echo ""
echo "Random UUID"
			echo "------------------------"
			for i in {1..5}; do
				uuid=$(cat /proc/sys/kernel/random/uuid)
echo "Random UUID $i: $uid"
			done

			echo ""
echo "16-bit random password"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
echo "Random Password $i: $password"
			done

			echo ""
echo "32-bit random password"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
echo "Random Password $i: $password"
			done
			echo ""

			  ;;

		  15)
			root_use
			send_stats "换时区"
			while true; do
				clear
echo "System Time Information"

				# 获取当前系统时区
				local timezone=$(current_timezone)

				# 获取当前系统时间
				local current_time=$(date +"%Y-%m-%d %H:%M:%S")

				# 显示时区和时间
echo "Current system time zone: $timezone"
echo "Current system time: $current_time"

				echo ""
echo "Time Zone Switch"
				echo "------------------------"
echo "Asia"
echo "1. Shanghai Time in China 2. Hong Kong Time in China"
echo "3. Tokyo time in Japan 4. Seoul time in South Korea"
echo "5. Singapore time 6. Kolkata time in India"
echo "7. Dubai time in the UAE 8. Sydney time in Australia"
echo "9. Bangkok Time, Thailand"
				echo "------------------------"
echo "Europe"
echo "11. London time in the UK 12. Paris time in France"
echo "13. Berlin time in Germany 14. Moscow time in Russia"
echo "15. Utrecht time in the Netherlands 16. Madrid time in Spain"
				echo "------------------------"
echo "America"
echo "21. Western Time 22. Eastern Time"
echo "23. Canadian time 24. Mexican time"
echo "25. Brazil time 26. Argentina time"
				echo "------------------------"
echo "31. UTC Global Standard Time"
				echo "------------------------"
echo "0. Return to previous menu"
				echo "------------------------"
				read -e -p "请输入你的选择: " sub_choice


				case $sub_choice in
					1) set_timedate Asia/Shanghai ;;
					2) set_timedate Asia/Hong_Kong ;;
					3) set_timedate Asia/Tokyo ;;
					4) set_timedate Asia/Seoul ;;
					5) set_timedate Asia/Singapore ;;
					6) set_timedate Asia/Kolkata ;;
					7) set_timedate Asia/Dubai ;;
					8) set_timedate Australia/Sydney ;;
					9) set_timedate Asia/Bangkok ;;
					11) set_timedate Europe/London ;;
					12) set_timedate Europe/Paris ;;
					13) set_timedate Europe/Berlin ;;
					14) set_timedate Europe/Moscow ;;
					15) set_timedate Europe/Amsterdam ;;
					16) set_timedate Europe/Madrid ;;
					21) set_timedate America/Los_Angeles ;;
					22) set_timedate America/New_York ;;
					23) set_timedate America/Vancouver ;;
					24) set_timedate America/Mexico_City ;;
					25) set_timedate America/Sao_Paulo ;;
					26) set_timedate America/Argentina/Buenos_Aires ;;
					31) set_timedate UTC ;;
					*) break ;;
				esac
			done
			  ;;

		  16)

			bbrv3
			  ;;

		  17)
			  iptables_panel

			  ;;

		  18)
		  root_use
		  send_stats "修改主机名"

		  while true; do
			  clear
			  local current_hostname=$(uname -n)
echo -e "Current hostname: ${gl_huang}$current_hostname${gl_bai}"
			  echo "------------------------"
			  read -e -p "请输入新的主机名（输入0退出）: " new_hostname
			  if [ -n "$new_hostname" ] && [ "$new_hostname" != "0" ]; then
				  if [ -f /etc/alpine-release ]; then
					  # Alpine
					  echo "$new_hostname" > /etc/hostname
					  hostname "$new_hostname"
				  else
					  # 其他系统，如 Debian, Ubuntu, CentOS 等
					  hostnamectl set-hostname "$new_hostname"
					  sed -i "s/$current_hostname/$new_hostname/g" /etc/hostname
					  systemctl restart systemd-hostnamed
				  fi

				  if grep -q "127.0.0.1" /etc/hosts; then
					  sed -i "s/127.0.0.1 .*/127.0.0.1       $new_hostname localhost localhost.localdomain/g" /etc/hosts
				  else
					  echo "127.0.0.1       $new_hostname localhost localhost.localdomain" >> /etc/hosts
				  fi

				  if grep -q "^::1" /etc/hosts; then
					  sed -i "s/^::1 .*/::1             $new_hostname localhost localhost.localdomain ipv6-localhost ipv6-loopback/g" /etc/hosts
				  else
					  echo "::1             $new_hostname localhost localhost.localdomain ipv6-localhost ipv6-loopback" >> /etc/hosts
				  fi

echo "Hostname has been changed to: $new_hostname"
				  send_stats "主机名已更改"
				  sleep 1
			  else
echo "Exited, hostname not changed."
				  break
			  fi
		  done
			  ;;

		  19)
		  root_use
		  send_stats "换系统更新源"
		  clear
echo "Select update source area"
echo "Add to LinuxMirrors to switch system update source"
		  echo "------------------------"
echo "1. Mainland China [default] 2. Mainland China [education network] 3. Overseas regions"
		  echo "------------------------"
echo "0. Return to previous menu"
		  echo "------------------------"
		  read -e -p "输入你的选择: " choice

		  case $choice in
			  1)
				  send_stats "中国大陆默认源"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh)
				  ;;
			  2)
				  send_stats "中国大陆教育源"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh) --edu
				  ;;
			  3)
				  send_stats "海外源"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh) --abroad
				  ;;
			  *)
echo "Canceled"
				  ;;

		  esac

			  ;;

		  20)
		  send_stats "定时任务管理"
			  while true; do
				  clear
				  check_crontab_installed
				  clear
echo "Timed Task List"
				  crontab -l
				  echo ""
echo "operate"
				  echo "------------------------"
echo "1. Add timing tasks 2. Delete timing tasks 3. Edit timing tasks"
				  echo "------------------------"
echo "0. Return to previous menu"
				  echo "------------------------"
				  read -e -p "请输入你的选择: " sub_choice

				  case $sub_choice in
					  1)
						  read -e -p "请输入新任务的执行命令: " newquest
						  echo "------------------------"
echo "1. Monthly Tasks 2. Weekly Tasks"
echo "3. Daily Tasks 4. Hourly Tasks"
						  echo "------------------------"
						  read -e -p "请输入你的选择: " dingshi

						  case $dingshi in
							  1)
								  read -e -p "选择每月的几号执行任务？ (1-30): " day
								  (crontab -l ; echo "0 0 $day * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  2)
								  read -e -p "选择周几执行任务？ (0-6，0代表星期日): " weekday
								  (crontab -l ; echo "0 0 * * $weekday $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  3)
								  read -e -p "选择每天几点执行任务？（小时，0-23）: " hour
								  (crontab -l ; echo "0 $hour * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  4)
								  read -e -p "输入每小时的第几分钟执行任务？（分钟，0-60）: " minute
								  (crontab -l ; echo "$minute * * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  *)
								  break  # 跳出
								  ;;
						  esac
						  send_stats "添加定时任务"
						  ;;
					  2)
						  read -e -p "请输入需要删除任务的关键字: " kquest
						  crontab -l | grep -v "$kquest" | crontab -
						  send_stats "删除定时任务"
						  ;;
					  3)
						  crontab -e
						  send_stats "编辑定时任务"
						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done

			  ;;

		  21)
			  root_use
			  send_stats "本地host解析"
			  while true; do
				  clear
echo "Native host parsing list"
echo "If you add parse matches here, dynamic parse will no longer be used"
				  cat /etc/hosts
				  echo ""
echo "operate"
				  echo "------------------------"
echo "1. Add a new parsing 2. Delete the parsing address"
				  echo "------------------------"
echo "0. Return to previous menu"
				  echo "------------------------"
				  read -e -p "请输入你的选择: " host_dns

				  case $host_dns in
					  1)
						  read -e -p "请输入新的解析记录 格式: 110.25.5.33 kejilion.pro : " addhost
						  echo "$addhost" >> /etc/hosts
						  send_stats "本地host解析新增"

						  ;;
					  2)
						  read -e -p "请输入需要删除的解析内容关键字: " delhost
						  sed -i "/$delhost/d" /etc/hosts
						  send_stats "本地host解析删除"
						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done
			  ;;

		  22)
		  root_use
		  send_stats "ssh防御"
		  while true; do
			if [ -x "$(command -v fail2ban-client)" ] ; then
				clear
				remove fail2ban
				rm -rf /etc/fail2ban
			else
				clear
				docker_name="fail2ban"
				check_docker_app
echo -e "SSH Defense Program $check_docker"
echo "fail2ban is an SSH brute-proof tool"
echo "Official website introduction: ${gh_proxy}github.com/fail2ban/fail2ban"
				echo "------------------------"
echo "1. Install the defense program"
				echo "------------------------"
echo "2. View SSH intercept record"
echo "3. Real-time log monitoring"
				echo "------------------------"
echo "9. Uninstall the defense program"
				echo "------------------------"
echo "0. Return to previous menu"
				echo "------------------------"
				read -e -p "请输入你的选择: " sub_choice
				case $sub_choice in
					1)
						install_docker
						f2b_install_sshd

						cd ~
						f2b_status
						break_end
						;;
					2)
						echo "------------------------"
						f2b_sshd
						echo "------------------------"
						break_end
						;;
					3)
						tail -f /path/to/fail2ban/config/log/fail2ban/fail2ban.log
						break
						;;
					9)
						docker rm -f fail2ban
						rm -rf /path/to/fail2ban
echo "Fail2Ban Defense Program Uninstalled"
						;;
					*)
						break
						;;
				esac
			fi
		  done
			  ;;


		  23)
			root_use
			send_stats "限流关机功能"
			while true; do
				clear
echo "Current-limited shutdown function"
echo "Video introduction: https://www.bilibili.com/video/BV1mC411j7Qd?t=0.1"
				echo "------------------------------------------------"
echo "Current traffic usage, restarting the server traffic calculation will be cleared!"
				output_status
				echo "$output"

				# 检查是否存在 Limiting_Shut_down.sh 文件
				if [ -f ~/Limiting_Shut_down.sh ]; then
					# 获取 threshold_gb 的值
					local rx_threshold_gb=$(grep -oP 'rx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					local tx_threshold_gb=$(grep -oP 'tx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
echo -e "${gl_lv}The current set pit stop current limit threshold is: ${gl_huang}${rx_threshold_gb}${gl_lv}G${gl_bai}"
echo -e "${gl_lv}The current set out of the outbound current limit threshold is: ${gl_huang}${tx_threshold_gb}${gl_lv}GB${gl_bai}"
				else
echo -e "${gl_hui}The current limit shutdown function is not currently enabled${gl_bai}"
				fi

				echo
				echo "------------------------------------------------"
echo "The system will detect whether the actual traffic reaches the threshold every minute, and the server will be automatically shut down after it arrives!"
				echo "------------------------"
echo "1. Turn on the current limit shutdown function 2. Deactivate the current limit shutdown function"
				echo "------------------------"
echo "0. Return to previous menu"
				echo "------------------------"
				read -e -p "请输入你的选择: " Limiting

				case "$Limiting" in
				  1)
					# 输入新的虚拟内存大小
echo "If the actual server has 100G traffic, you can set the threshold to 95G and shut down the power in advance to avoid traffic errors or overflows."
					read -e -p "请输入进站流量阈值（单位为G，默认100G）: " rx_threshold_gb
					rx_threshold_gb=${rx_threshold_gb:-100}
					read -e -p "请输入出站流量阈值（单位为G，默认100G）: " tx_threshold_gb
					tx_threshold_gb=${tx_threshold_gb:-100}
					read -e -p "请输入流量重置日期（默认每月1日重置）: " cz_day
					cz_day=${cz_day:-1}

					cd ~
					curl -Ss -o ~/Limiting_Shut_down.sh ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/Limiting_Shut_down1.sh
					chmod +x ~/Limiting_Shut_down.sh
					sed -i "s/110/$rx_threshold_gb/g" ~/Limiting_Shut_down.sh
					sed -i "s/120/$tx_threshold_gb/g" ~/Limiting_Shut_down.sh
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					(crontab -l ; echo "* * * * * ~/Limiting_Shut_down.sh") | crontab - > /dev/null 2>&1
					crontab -l | grep -v 'reboot' | crontab -
					(crontab -l ; echo "0 1 $cz_day * * reboot") | crontab - > /dev/null 2>&1
echo "Current limit shutdown has been set"
					send_stats "限流关机已设置"
					;;
				  2)
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					crontab -l | grep -v 'reboot' | crontab -
					rm ~/Limiting_Shut_down.sh
echo "Current limit shutdown function has been turned off"
					;;
				  *)
					break
					;;
				esac
			done
			  ;;


		  24)

			  root_use
			  send_stats "私钥登录"
			  while true; do
				  clear
echo "ROOT private key login mode"
echo "Video introduction: https://www.bilibili.com/video/BV1Q4421X78n?t=209.4"
			  	  echo "------------------------------------------------"
echo "The key pair will be generated, a more secure way to SSH login"
				  echo "------------------------"
echo "1. Generate a new key 2. Import an existing key 3. View the native key"
				  echo "------------------------"
echo "0. Return to previous menu"
				  echo "------------------------"
				  read -e -p "请输入你的选择: " host_dns

				  case $host_dns in
					  1)
				  		send_stats "生成新密钥"
				  		add_sshkey
						break_end

						  ;;
					  2)
						send_stats "导入已有公钥"
						import_sshkey
						break_end

						  ;;
					  3)
						send_stats "查看本机密钥"
						echo "------------------------"
echo "Public Key Information"
						cat ~/.ssh/authorized_keys
						echo "------------------------"
echo "Private Key Information"
						cat ~/.ssh/sshkey
						echo "------------------------"
						break_end

						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done

			  ;;

		  25)
			  root_use
			  send_stats "电报预警"
echo "TG-bot monitoring and early warning function"
echo "Video introduction: https://youtu.be/vLL-eb3Z_TY"
			  echo "------------------------------------------------"
echo "You need to configure the tg robot API and the user ID to receive early warnings to realize real-time monitoring and early warnings for native CPU, memory, hard disk, traffic, and SSH login"
echo "A warning message will be sent to the user after the threshold is reached"
echo -e "${gl_hui}- Regarding traffic, restarting the server will recalculate -${gl_bai}"
			  read -e -p "确定继续吗？(Y/N): " choice

			  case "$choice" in
				[Yy])
				  send_stats "电报预警启用"
				  cd ~
				  install nano tmux bc jq
				  check_crontab_installed
				  if [ -f ~/TG-check-notify.sh ]; then
					  chmod +x ~/TG-check-notify.sh
					  nano ~/TG-check-notify.sh
				  else
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/TG-check-notify.sh
					  chmod +x ~/TG-check-notify.sh
					  nano ~/TG-check-notify.sh
				  fi
				  tmux kill-session -t TG-check-notify > /dev/null 2>&1
				  tmux new -d -s TG-check-notify "~/TG-check-notify.sh"
				  crontab -l | grep -v '~/TG-check-notify.sh' | crontab - > /dev/null 2>&1
				  (crontab -l ; echo "@reboot tmux new -d -s TG-check-notify '~/TG-check-notify.sh'") | crontab - > /dev/null 2>&1

				  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/TG-SSH-check-notify.sh > /dev/null 2>&1
				  sed -i "3i$(grep '^TELEGRAM_BOT_TOKEN=' ~/TG-check-notify.sh)" TG-SSH-check-notify.sh > /dev/null 2>&1
				  sed -i "4i$(grep '^CHAT_ID=' ~/TG-check-notify.sh)" TG-SSH-check-notify.sh
				  chmod +x ~/TG-SSH-check-notify.sh

				  # 添加到 ~/.profile 文件中
				  if ! grep -q 'bash ~/TG-SSH-check-notify.sh' ~/.profile > /dev/null 2>&1; then
					  echo 'bash ~/TG-SSH-check-notify.sh' >> ~/.profile
					  if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
						 echo 'source ~/.profile' >> ~/.bashrc
					  fi
				  fi

				  source ~/.profile

				  clear
echo "TG-bot early warning system is started"
echo -e "${gl_hui} You can also put the TG-check-notify.sh warning file in the root directory on other machines and use it directly! ${gl_bai}"
				  ;;
				[Nn])
echo "Canceled"
				  ;;
				*)
echo "Invalid selection, please enter Y or N."
				  ;;
			  esac
			  ;;

		  26)
			  root_use
			  send_stats "修复SSH高危漏洞"
			  cd ~
			  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/upgrade_openssh9.8p1.sh
			  chmod +x ~/upgrade_openssh9.8p1.sh
			  ~/upgrade_openssh9.8p1.sh
			  rm -f ~/upgrade_openssh9.8p1.sh
			  ;;

		  27)
			  elrepo
			  ;;
		  28)
			  Kernel_optimize
			  ;;

		  29)
			  clamav
			  ;;

		  30)
			  linux_file
			  ;;

		  31)
			  linux_language
			  ;;

		  32)
			  shell_bianse
			  ;;
		  33)
			  linux_trash
			  ;;
		  34)
			  linux_backup
			  ;;
		  35)
			  ssh_manager
			  ;;
		  36)
			  disk_manager
			  ;;
		  37)
			  clear
			  send_stats "命令行历史记录"
			  get_history_file() {
				  for file in "$HOME"/.bash_history "$HOME"/.ash_history "$HOME"/.zsh_history "$HOME"/.local/share/fish/fish_history; do
					  [ -f "$file" ] && { echo "$file"; return; }
				  done
				  return 1
			  }

			  history_file=$(get_history_file) && cat -n "$history_file"
			  ;;

		  38)
			  rsync_manager
			  ;;


		  41)
			clear
			send_stats "留言板"
echo "The technology lion message board has been moved to the official community! Please leave a message in the official community!"
			echo "https://bbs.kejilion.pro/"
			  ;;

		  66)

			  root_use
			  send_stats "一条龙调优"
echo "One-stop system tuning"
			  echo "------------------------------------------------"
echo "The following will be operated and optimized"
echo "1. Update the system to the latest"
echo "2. Clean up system junk files"
echo -e "3. Set virtual memory ${gl_huang}1G${gl_bai}"
echo -e "4. Set the SSH port number to ${gl_huang}5522${gl_bai}"
echo -e "5. Open all ports"
echo -e "6. Turn on ${gl_huang}BBR${gl_bai} acceleration"
echo -e "7. Set the time zone to ${gl_huang}Shanghai${gl_bai}"
echo -e "8. Automatically optimize DNS address ${gl_huang} Overseas: 1.1.1.1 8.8.8.8 Domestic: 223.5.5.5 ${gl_bai}"
echo -e "9. Install basic tool ${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
echo -e "10. Switch to ${gl_huang}balance optimization mode ${gl_bai}"
			  echo "------------------------------------------------"
			  read -e -p "确定一键保养吗？(Y/N): " choice

			  case "$choice" in
				[Yy])
				  clear
				  send_stats "一条龙调优启动"
				  echo "------------------------------------------------"
				  linux_update
echo -e "[${gl_lv}OK${gl_bai}] 1/10. Update the system to the latest"

				  echo "------------------------------------------------"
				  linux_clean
echo -e "[${gl_lv}OK${gl_bai}] 2/10. Clean up system junk files"

				  echo "------------------------------------------------"
				  add_swap 1024
echo -e "[${gl_lv}OK${gl_bai}] 3/10. Set virtual memory ${gl_huang}1G${gl_bai}"

				  echo "------------------------------------------------"
				  local new_port=5522
				  new_ssh_port
echo -e "[${gl_lv}OK${gl_bai}] 4/10. Set the SSH port number to ${gl_huang}5522${gl_bai}"
				  echo "------------------------------------------------"
echo -e "[${gl_lv}OK${gl_bai}] 5/10. Open all ports"

				  echo "------------------------------------------------"
				  bbr_on
echo -e "[${gl_lv}OK${gl_bai}] 6/10. Turn on ${gl_huang}BBR${gl_bai} acceleration"

				  echo "------------------------------------------------"
				  set_timedate Asia/Shanghai
echo -e "[${gl_lv}OK${gl_bai}] 7/10. Set the time zone to ${gl_huang}Shanghai${gl_bai}"

				  echo "------------------------------------------------"
				  local country=$(curl -s ipinfo.io/country)
				  if [ "$country" = "CN" ]; then
					 local dns1_ipv4="223.5.5.5"
					 local dns2_ipv4="183.60.83.19"
					 local dns1_ipv6="2400:3200::1"
					 local dns2_ipv6="2400:da00::6666"
				  else
					 local dns1_ipv4="1.1.1.1"
					 local dns2_ipv4="8.8.8.8"
					 local dns1_ipv6="2606:4700:4700::1111"
					 local dns2_ipv6="2001:4860:4860::8888"
				  fi

				  set_dns
echo -e "[${gl_lv}OK${gl_bai}] 8/10. Automatically optimize DNS address ${gl_huang}${gl_bai}"

				  echo "------------------------------------------------"
				  install_docker
				  install wget sudo tar unzip socat btop nano vim
echo -e "[${gl_lv}OK${gl_bai}] 9/10. Install the basic tool ${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
				  echo "------------------------------------------------"

				  echo "------------------------------------------------"
				  optimize_balanced
echo -e "[${gl_lv}OK${gl_bai}] 10/10. Optimization of kernel parameters for Linux system"
echo -e "${gl_lv}One-stop system tuning has been completed${gl_bai}"

				  ;;
				[Nn])
echo "Canceled"
				  ;;
				*)
echo "Invalid selection, please enter Y or N."
				  ;;
			  esac

			  ;;

		  99)
			  clear
			  send_stats "重启系统"
			  server_reboot
			  ;;
		  100)

			root_use
			while true; do
			  clear
			  if grep -q '^ENABLE_STATS="true"' /usr/local/bin/k > /dev/null 2>&1; then
			  	local status_message="${gl_lv}正在采集数据${gl_bai}"
			  elif grep -q '^ENABLE_STATS="false"' /usr/local/bin/k > /dev/null 2>&1; then
			  	local status_message="${gl_hui}采集已关闭${gl_bai}"
			  else
			  	local status_message="无法确定的状态"
			  fi

echo "Privacy and Security"
echo "The script will collect data on user functions, optimize script experience, and create more fun and useful functions"
echo "The script version number, the time of use, the system version, the CPU architecture, the country of the machine and the name of the function used,"
			  echo "------------------------------------------------"
echo -e "Current status: $status_message"
			  echo "--------------------"
echo "1. Turn on acquisition"
echo "2. Close the collection"
			  echo "--------------------"
echo "0. Return to previous menu"
			  echo "--------------------"
			  read -e -p "请输入你的选择: " sub_choice
			  case $sub_choice in
				  1)
					  cd ~
					  sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' /usr/local/bin/k
					  sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' ~/kejilion.sh
echo "Collection is enabled"
					  send_stats "隐私与安全已开启采集"
					  ;;
				  2)
					  cd ~
					  sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' /usr/local/bin/k
					  sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' ~/kejilion.sh
echo "Collection closed"
					  send_stats "隐私与安全已关闭采集"
					  ;;
				  *)
					  break
					  ;;
			  esac
			done
			  ;;

		  101)
			  clear
			  k_info
			  ;;

		  102)
			  clear
			  send_stats "卸载科技lion脚本"
echo "Uninstall tech lion script"
			  echo "------------------------------------------------"
echo "The kejilion script will be completely uninstalled and will not affect your other functions"
			  read -e -p "确定继续吗？(Y/N): " choice

			  case "$choice" in
				[Yy])
				  clear
				  (crontab -l | grep -v "kejilion.sh") | crontab -
				  rm -f /usr/local/bin/k
				  rm ~/kejilion.sh
echo "The script has been uninstalled, goodbye!"
				  break_end
				  clear
				  exit
				  ;;
				[Nn])
echo "Canceled"
				  ;;
				*)
echo "Invalid selection, please enter Y or N."
				  ;;
			  esac
			  ;;

		  0)
			  kejilion

			  ;;
		  *)
echo "Invalid input!"
			  ;;
	  esac
	  break_end

	done



}






linux_file() {
	root_use
	send_stats "文件管理器"
	while true; do
		clear
echo "File Manager"
		echo "------------------------"
echo "Current Path"
		pwd
		echo "------------------------"
		ls --color=auto -x
		echo "------------------------"
echo "1. Enter the directory 2. Create the directory 3. Modify the directory permissions 4. Rename the directory"
echo "5. Delete the directory 6. Return to the previous menu directory"
		echo "------------------------"
echo "11. Create a file 12. Edit a file 13. Modify file permissions 14. Rename a file"
echo "15. Delete File"
		echo "------------------------"
echo "21. Compress file directory 22. Unzip file directory 23. Move file directory 24. Copy file directory"
echo "25. Pass the file to another server"
		echo "------------------------"
echo "0. Return to previous menu"
		echo "------------------------"
		read -e -p "请输入你的选择: " Limiting

		case "$Limiting" in
			1)  # 进入目录
				read -e -p "请输入目录名: " dirname
				cd "$dirname" 2>/dev/null || echo "无法进入目录"
				send_stats "进入目录"
				;;
			2)  # 创建目录
				read -e -p "请输入要创建的目录名: " dirname
				mkdir -p "$dirname" && echo "目录已创建" || echo "创建失败"
				send_stats "创建目录"
				;;
			3)  # 修改目录权限
				read -e -p "请输入目录名: " dirname
				read -e -p "请输入权限 (如 755): " perm
				chmod "$perm" "$dirname" && echo "权限已修改" || echo "修改失败"
				send_stats "修改目录权限"
				;;
			4)  # 重命名目录
				read -e -p "请输入当前目录名: " current_name
				read -e -p "请输入新目录名: " new_name
				mv "$current_name" "$new_name" && echo "目录已重命名" || echo "重命名失败"
				send_stats "重命名目录"
				;;
			5)  # 删除目录
				read -e -p "请输入要删除的目录名: " dirname
				rm -rf "$dirname" && echo "目录已删除" || echo "删除失败"
				send_stats "删除目录"
				;;
			6)  # 返回上一级选单目录
				cd ..
				send_stats "返回上一级选单目录"
				;;
			11) # 创建文件
				read -e -p "请输入要创建的文件名: " filename
				touch "$filename" && echo "文件已创建" || echo "创建失败"
				send_stats "创建文件"
				;;
			12) # 编辑文件
				read -e -p "请输入要编辑的文件名: " filename
				install nano
				nano "$filename"
				send_stats "编辑文件"
				;;
			13) # 修改文件权限
				read -e -p "请输入文件名: " filename
				read -e -p "请输入权限 (如 755): " perm
				chmod "$perm" "$filename" && echo "权限已修改" || echo "修改失败"
				send_stats "修改文件权限"
				;;
			14) # 重命名文件
				read -e -p "请输入当前文件名: " current_name
				read -e -p "请输入新文件名: " new_name
				mv "$current_name" "$new_name" && echo "文件已重命名" || echo "重命名失败"
				send_stats "重命名文件"
				;;
			15) # 删除文件
				read -e -p "请输入要删除的文件名: " filename
				rm -f "$filename" && echo "文件已删除" || echo "删除失败"
				send_stats "删除文件"
				;;
			21) # 压缩文件/目录
				read -e -p "请输入要压缩的文件/目录名: " name
				install tar
				tar -czvf "$name.tar.gz" "$name" && echo "已压缩为 $name.tar.gz" || echo "压缩失败"
				send_stats "压缩文件/目录"
				;;
			22) # 解压文件/目录
				read -e -p "请输入要解压的文件名 (.tar.gz): " filename
				install tar
				tar -xzvf "$filename" && echo "已解压 $filename" || echo "解压失败"
				send_stats "解压文件/目录"
				;;

			23) # 移动文件或目录
				read -e -p "请输入要移动的文件或目录路径: " src_path
				if [ ! -e "$src_path" ]; then
echo "Error: The file or directory does not exist."
					send_stats "移动文件或目录失败: 文件或目录不存在"
					continue
				fi

				read -e -p "请输入目标路径 (包括新文件名或目录名): " dest_path
				if [ -z "$dest_path" ]; then
echo "Error: Please enter the target path."
					send_stats "移动文件或目录失败: 目标路径未指定"
					continue
				fi

				mv "$src_path" "$dest_path" && echo "文件或目录已移动到 $dest_path" || echo "移动文件或目录失败"
				send_stats "移动文件或目录"
				;;


		   24) # 复制文件目录
				read -e -p "请输入要复制的文件或目录路径: " src_path
				if [ ! -e "$src_path" ]; then
echo "Error: The file or directory does not exist."
					send_stats "复制文件或目录失败: 文件或目录不存在"
					continue
				fi

				read -e -p "请输入目标路径 (包括新文件名或目录名): " dest_path
				if [ -z "$dest_path" ]; then
echo "Error: Please enter the target path."
					send_stats "复制文件或目录失败: 目标路径未指定"
					continue
				fi

				# 使用 -r 选项以递归方式复制目录
				cp -r "$src_path" "$dest_path" && echo "文件或目录已复制到 $dest_path" || echo "复制文件或目录失败"
				send_stats "复制文件或目录"
				;;


			 25) # 传送文件至远端服务器
				read -e -p "请输入要传送的文件路径: " file_to_transfer
				if [ ! -f "$file_to_transfer" ]; then
echo "Error: The file does not exist."
					send_stats "传送文件失败: 文件不存在"
					continue
				fi

				read -e -p "请输入远端服务器IP: " remote_ip
				if [ -z "$remote_ip" ]; then
echo "Error: Please enter the remote server IP."
					send_stats "传送文件失败: 未输入远端服务器IP"
					continue
				fi

				read -e -p "请输入远端服务器用户名 (默认root): " remote_user
				remote_user=${remote_user:-root}

				read -e -p "请输入远端服务器密码: " -s remote_password
				echo
				if [ -z "$remote_password" ]; then
echo "Error: Please enter the remote server password."
					send_stats "传送文件失败: 未输入远端服务器密码"
					continue
				fi

				read -e -p "请输入登录端口 (默认22): " remote_port
				remote_port=${remote_port:-22}

				# 清除已知主机的旧条目
				ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
				sleep 2  # 等待时间

				# 使用scp传输文件
				scp -P "$remote_port" -o StrictHostKeyChecking=no "$file_to_transfer" "$remote_user@$remote_ip:/home/" <<EOF
$remote_password
EOF

				if [ $? -eq 0 ]; then
echo "The file has been transferred to the remote server home directory."
					send_stats "文件传送成功"
				else
echo "File transfer failed."
					send_stats "文件传送失败"
				fi

				break_end
				;;



			0)  # 返回上一级选单
				send_stats "返回上一级选单菜单"
				break
				;;
			*)  # 处理无效输入
echo "Invalid selection, please re-enter"
				send_stats "无效选择"
				;;
		esac
	done
}






cluster_python3() {
	install python3 python3-paramiko
	cd ~/cluster/
	curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/python-for-vps/main/cluster/$py_task
	python3 ~/cluster/$py_task
}


run_commands_on_servers() {

	install sshpass

	local SERVERS_FILE="$HOME/cluster/servers.py"
	local SERVERS=$(grep -oP '{"name": "\K[^"]+|"hostname": "\K[^"]+|"port": \K[^,]+|"username": "\K[^"]+|"password": "\K[^"]+' "$SERVERS_FILE")

	# 将提取的信息转换为数组
	IFS=$'\n' read -r -d '' -a SERVER_ARRAY <<< "$SERVERS"

	# 遍历服务器并执行命令
	for ((i=0; i<${#SERVER_ARRAY[@]}; i+=5)); do
		local name=${SERVER_ARRAY[i]}
		local hostname=${SERVER_ARRAY[i+1]}
		local port=${SERVER_ARRAY[i+2]}
		local username=${SERVER_ARRAY[i+3]}
		local password=${SERVER_ARRAY[i+4]}
		echo
echo -e "${gl_huang}connect to $name ($hostname)...${gl_bai}"
		# sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$username@$hostname" -p "$port" "$1"
		sshpass -p "$password" ssh -t -o StrictHostKeyChecking=no "$username@$hostname" -p "$port" "$1"
	done
	echo
	break_end

}


linux_cluster() {
mkdir cluster
if [ ! -f ~/cluster/servers.py ]; then
	cat > ~/cluster/servers.py << EOF
servers = [

]
EOF
fi

while true; do
	  clear
	  send_stats "集群控制中心"
echo "Server Cluster Control"
	  cat ~/cluster/servers.py
	  echo
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}Server List Management${gl_bai}"
echo -e "${gl_kjlan}1. ${gl_bai}Add server ${gl_kjlan}2. ${gl_bai}Delete server ${gl_kjlan}3. ${gl_bai}Edit server"
echo -e "${gl_kjlan}4. ${gl_bai}Backup cluster ${gl_kjlan}5. ${gl_bai}Restore cluster"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}Batch execution of tasks ${gl_bai}"
echo -e "${gl_kjlan}11. ${gl_bai}install tech lion script ${gl_kjlan}12. ${gl_bai}update system ${gl_kjlan}13. ${gl_bai}clean system"
echo -e "${gl_kjlan}14. ${gl_bai}install docker ${gl_kjlan}15. ${gl_bai}install BBR3 ${gl_kjlan}16. ${gl_bai}set 1G virtual memory"
echo -e "${gl_kjlan}17. ${gl_bai}Set the time zone to Shanghai ${gl_kjlan}18. ${gl_bai}Open all ports ${gl_kjlan}51. ${gl_bai}Custom directive"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}0. ${gl_bai} returns to main menu"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "请输入你的选择: " sub_choice

	  case $sub_choice in
		  1)
			  send_stats "添加集群服务器"
			  read -e -p "服务器名称: " server_name
			  read -e -p "服务器IP: " server_ip
			  read -e -p "服务器端口（22）: " server_port
			  local server_port=${server_port:-22}
			  read -e -p "服务器用户名（root）: " server_username
			  local server_username=${server_username:-root}
			  read -e -p "服务器用户密码: " server_password

			  sed -i "/servers = \[/a\    {\"name\": \"$server_name\", \"hostname\": \"$server_ip\", \"port\": $server_port, \"username\": \"$server_username\", \"password\": \"$server_password\", \"remote_path\": \"/home/\"}," ~/cluster/servers.py

			  ;;
		  2)
			  send_stats "删除集群服务器"
			  read -e -p "请输入需要删除的关键字: " rmserver
			  sed -i "/$rmserver/d" ~/cluster/servers.py
			  ;;
		  3)
			  send_stats "编辑集群服务器"
			  install nano
			  nano ~/cluster/servers.py
			  ;;

		  4)
			  clear
			  send_stats "备份集群"
echo -e "Please download the ${gl_huang}/root/cluster/servers.py${gl_bai} file and complete the backup!"
			  break_end
			  ;;

		  5)
			  clear
			  send_stats "还原集群"
echo "Please upload your servers.py and press any key to start uploading!"
echo -e "Please upload your ${gl_huang}servers.py${gl_bai} file to ${gl_huang}/root/cluster/${gl_bai} to complete the restore!"
			  break_end
			  ;;

		  11)
			  local py_task="install_kejilion.py"
			  cluster_python3
			  ;;
		  12)
			  run_commands_on_servers "k update"
			  ;;
		  13)
			  run_commands_on_servers "k clean"
			  ;;
		  14)
			  run_commands_on_servers "k docker install"
			  ;;
		  15)
			  run_commands_on_servers "k bbr3"
			  ;;
		  16)
			  run_commands_on_servers "k swap 1024"
			  ;;
		  17)
			  run_commands_on_servers "k time Asia/Shanghai"
			  ;;
		  18)
			  run_commands_on_servers "k iptables_open"
			  ;;

		  51)
			  send_stats "自定义执行命令"
			  read -e -p "请输入批量执行的命令: " mingling
			  run_commands_on_servers "${mingling}"
			  ;;

		  *)
			  kejilion
			  ;;
	  esac
done

}




kejilion_Affiliates() {

clear
send_stats "广告专栏"
echo "Advertising Column"
echo "------------------------"
echo "It will provide users with a simpler and more elegant promotion and purchasing experience!"
echo ""
echo -e "Server Offer"
echo "------------------------"
echo -e "${gl_lan}Lycra Cloud Hong Kong CN2 GIA South Korea Dual ISP US CN2 GIA Discount ${gl_bai}"
echo -e "${gl_bai} URL: https://www.lcayun.com/aff/ZEXUQBIM${gl_bai}"
echo "------------------------"
echo -e "${gl_lan}RackNerd $10.99 per year United States 1 core 1G memory 20G hard drive 1T traffic ${gl_bai} per month"
echo -e "${gl_bai} URL: https://my.racknerd.com/aff.php?aff=5501&pid=879${gl_bai}"
echo "------------------------"
echo -e "${gl_zi}Hostinger $52.7 per year United States 1 core 4G memory 50G hard drive 4T traffic ${gl_bai} per month"
echo -e "${gl_bai} URL: https://cart.hostinger.com/pay/d83c51e9-0c28-47a6-8414-b8ab010ef94f?_ga=GA1.3.942352702.1711283207${gl_bai}"
echo "------------------------"
echo -e "${gl_huang}Brandman, $49 per quarter, US CN2GIA, Japan SoftBank, 2 cores, 1G memory, 20G hard drive, 1T traffic per month, ${gl_bai}"
echo -e "${gl_bai} URL: https://bandwagonhost.com/aff.php?aff=69004&pid=87${gl_bai}"
echo "------------------------"
echo -e "${gl_lan}DMIT $28 per quarter US CN2GIA 1 core 2G memory 20G hard drive 800G traffic ${gl_bai} per month"
echo -e "${gl_bai} URL: https://www.dmit.io/aff.php?aff=4966&pid=100${gl_bai}"
echo "------------------------"
echo -e "${gl_zi}V.PS $6.9 per month Tokyo SoftBank 2 core 1G memory 20G hard drive 1T traffic ${gl_bai}"
echo -e "${gl_bai} URL: https://vps.hosting/cart/tokyo-cloud-kvm-vps/?id=148&?affid=1355&?affid=1355${gl_bai}"
echo "------------------------"
echo -e "${gl_kjlan}VPSMore Popular Offers${gl_bai}"
echo -e "${gl_bai} URL: https://kejilion.pro/topvps/${gl_bai}"
echo "------------------------"
echo ""
echo -e "Domain Name Discount"
echo "------------------------"
echo -e "${gl_lan}GNAME 8.8 first year COM domain name 6.68 first year CC domain name ${gl_bai}"
echo -e "${gl_bai} URL: https://www.gname.com/register?tt=86836&ttcode=KEJILION86836&ttbj=sh${gl_bai}"
echo "------------------------"
echo ""
echo -e "Technology lion peripheral"
echo "------------------------"
echo -e "${gl_kjlan}B site: ${gl_bai}https://b23.tv/2mqnQyh ${gl_kjlan}Oil pipe: ${gl_bai}https://www.youtube.com/@kejilion${gl_bai}"
echo -e "${gl_kjlan}Official website: ${gl_bai}https://kejilion.pro/ ${gl_kjlan}Navigation: ${gl_bai}https://dh.kejilion.pro/${gl_bai}"
echo -e "${gl_kjlan}Blog: ${gl_bai}https://blog.kejilion.pro/ ${gl_kjlan}Software Center: ${gl_bai}https://app.kejilion.pro/${gl_bai}"
echo "------------------------"
echo ""
}





kejilion_update() {

send_stats "脚本更新"
cd ~
while true; do
	clear
echo "Update Log"
	echo "------------------------"
echo "All logs: ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt"
	echo "------------------------"

	curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt | tail -n 30
	local sh_v_new=$(curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion.sh | grep -o 'sh_v="[0-9.]*"' | cut -d '"' -f 2)

	if [ "$sh_v" = "$sh_v_new" ]; then
echo -e "${gl_lv}You are already the latest version!${gl_huang}v$sh_v${gl_bai}"
		send_stats "脚本已经最新了，无需更新"
	else
echo "Discover a new version!"
echo -e "Current version v$sh_v latest version ${gl_huang}v$sh_v_new${gl_bai}"
	fi


	local cron_job="kejilion.sh"
	local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

	if [ -n "$existing_cron" ]; then
		echo "------------------------"
echo -e "${gl_lv} automatic update is enabled, and the script will be automatically updated at 2 a.m. every day! ${gl_bai}"
	fi

	echo "------------------------"
echo "1. Update now 2. Turn on automatic update 3. Turn off automatic update"
	echo "------------------------"
echo "0. Return to main menu"
	echo "------------------------"
	read -e -p "请输入你的选择: " choice
	case "$choice" in
		1)
			clear
			local country=$(curl -s ipinfo.io/country)
			if [ "$country" = "CN" ]; then
				curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/cn/kejilion.sh && chmod +x kejilion.sh
			else
				curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh
			fi
			canshu_v6
			CheckFirstRun_true
			yinsiyuanquan2
			cp -f ~/kejilion.sh /usr/local/bin/k > /dev/null 2>&1
echo -e "${gl_lv} script has been updated to the latest version! ${gl_huang}v$sh_v_new${gl_bai}"
			send_stats "脚本已经最新$sh_v_new"
			break_end
			~/kejilion.sh
			exit
			;;
		2)
			clear
			local country=$(curl -s ipinfo.io/country)
			local ipv6_address=$(curl -s --max-time 1 ipv6.ip.sb)
			if [ "$country" = "CN" ]; then
				SH_Update_task="curl -sS -O https://gh.kejilion.pro/raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh && sed -i 's/canshu=\"default\"/canshu=\"CN\"/g' ./kejilion.sh"
			elif [ -n "$ipv6_address" ]; then
				SH_Update_task="curl -sS -O https://gh.kejilion.pro/raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh && sed -i 's/canshu=\"default\"/canshu=\"V6\"/g' ./kejilion.sh"
			else
				SH_Update_task="curl -sS -O https://raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh"
			fi
			check_crontab_installed
			(crontab -l | grep -v "kejilion.sh") | crontab -
			# (crontab -l 2>/dev/null; echo "0 2 * * * bash -c \"$SH_Update_task\"") | crontab -
			(crontab -l 2>/dev/null; echo "$(shuf -i 0-59 -n 1) 2 * * * bash -c \"$SH_Update_task\"") | crontab -
echo -e "${gl_lv} automatic update is enabled, and the script will be automatically updated at 2 a.m. every day! ${gl_bai}"
			send_stats "开启脚本自动更新"
			break_end
			;;
		3)
			clear
			(crontab -l | grep -v "kejilion.sh") | crontab -
echo -e "${gl_lv}Auto update has been closed${gl_bai}"
			send_stats "关闭脚本自动更新"
			break_end
			;;
		*)
			kejilion_sh
			;;
	esac
done

}





kejilion_sh() {
while true; do
clear
echo -e "${gl_kjlan}"
echo "╦╔═╔═╗ ╦╦╦  ╦╔═╗╔╗╔ ╔═╗╦ ╦"
echo "╠╩╗║╣  ║║║  ║║ ║║║║ ╚═╗╠═╣"
echo "╩ ╩╚═╝╚╝╩╩═╝╩╚═╝╝╚╝o╚═╝╩ ╩"
echo -e "Technology lion script toolbox v$sh_v"
echo -e "Enter ${gl_huang}k${gl_kjlan} on the command line to quickly start the script ${gl_bai}"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}1. ${gl_bai} system information query"
echo -e "${gl_kjlan}2. ${gl_bai} system update"
echo -e "${gl_kjlan}3. ${gl_bai} system cleaning"
echo -e "${gl_kjlan}4. ${gl_bai}Basic Tool"
echo -e "${gl_kjlan}5. ${gl_bai}BBR Management"
echo -e "gl_kjlan}
echo -e "${gl_kjlan}7. ${gl_bai}WARP Management"
echo -e "${gl_kjlan}8. ${gl_bai}test script collection"
echo -e "${gl_kjlan}9. ${gl_bai} Oracle Cloud Script Collection"
echo -e "${gl_huang}10. ${gl_bai}LDNMP website building"
echo -e "${gl_kjlan}11. ${gl_bai}application market"
echo -e "${gl_kjlan}12. ${gl_bai}my workspace"
echo -e "${gl_kjlan}13. ${gl_bai}system tool"
echo -e "${gl_kjlan}14. ${gl_bai}server cluster control"
echo -e "${gl_kjlan}15. ${gl_bai}Advertising Column"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}p. ${gl_bai}Palu server script"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}00. ${gl_bai} script update"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}0. ${gl_bai}Exit script"
echo -e "${gl_kjlan}------------------------${gl_bai}"
read -e -p "请输入你的选择: " choice

case $choice in
  1) linux_ps ;;
  2) clear ; send_stats "系统更新" ; linux_update ;;
  3) clear ; send_stats "系统清理" ; linux_clean ;;
  4) linux_tools ;;
  5) linux_bbr ;;
  6) linux_docker ;;
  7) clear ; send_stats "warp管理" ; install wget
	wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh ; bash menu.sh [option] [lisence/url/token]
	;;
  8) linux_test ;;
  9) linux_Oracle ;;
  10) linux_ldnmp ;;
  11) linux_panel ;;
  12) linux_work ;;
  13) linux_Settings ;;
  14) linux_cluster ;;
  15) kejilion_Affiliates ;;
  p) send_stats "幻兽帕鲁开服脚本" ; cd ~
	 curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/palworld.sh ; chmod +x palworld.sh ; ./palworld.sh
	 exit
	 ;;
  00) kejilion_update ;;
  0) clear ; exit ;;
  *) echo "无效的输入!" ;;
esac
	break_end
done
}


k_info() {
send_stats "k命令参考用例"
echo "-------------------"
echo "Video introduction: https://www.bilibili.com/video/BV1ib421E7it?t=0.1"
echo "The following is a k-command reference use case:"
echo "Start script k"
echo "Installing package k install nano wget | k add nano wget | k install nano wget"
echo "Uninstall package k remove nano wget | k del nano wget | k uninstall nano wget | k uninstall nano wget"
echo "Update system k update | k update"
echo "Cleaning system garbage k clean | k clean"
echo "Reinstall the system panel k dd | k reinstall"
echo "bbr3 Control Panel k bbr3 | k bbrv3"
echo "Kernel Tuning Panel k nhyh | k kernel optimization"
echo "Set virtual memory k swap 2048"
echo "Set virtual time zone k time Asia/Shanghai | k time zone Asia/Shanghai"
echo "System Recycle Bin k trash | k hsz | k Recycle Bin"
echo "System backup function k backup | k bf | k backup"
echo "ssh remote connection tool k ssh | k remote connection"
echo "rsync remote synchronization tool k rsync | k remote synchronization"
echo "Hard disk management tool k disk | k hard disk management"
echo "Intranet penetration (server side) k frps"
echo "Intranet penetration (client) k frpc"
echo "Software start k start sshd | k start sshd"
echo "Software stop k stop sshd | k stop sshd "
echo "Software restart k restart sshd | k restart sshd"
echo "Software Status View k status sshd | k status sshd "
echo "Software boot k enable docker | k autostart docke | k startup docker "
echo "Domain Certificate Application K SSL"
echo "Domain name certificate expiration query k ssl ps"
echo "Docker environment installation k docker install |k docker installation"
echo "docker container management k docker ps |k docker container"
echo "docker image management k docker img |k docker image"
echo "LDNMP Site Management k web"
echo "LDNMP cache cleanup k web cache"
echo "安装WordPress       k wp |k wordpress |k wp xxx.com"
echo "Installing the reverse proxy k fd |k rp |k anti-generation |k fd xxx.com"
echo "Firewall Panel k fhq |k Firewall"
echo "Open port k dkdk 8080 |k Open port 8080"
echo "Close port k gbdk 7800 |kClose port 7800"
echo "Release IP k fxip 127.0.0.0/8 |k Release IP 127.0.0.0/8"
echo "Block IP k zzip 177.5.25.36 |k Block IP 177.5.25.36"


}



if [ "$#" -eq 0 ]; then
	# 如果没有参数，运行交互式逻辑
	kejilion_sh
else
	# 如果有参数，执行相应函数
	case $1 in
		install|add|安装)
			shift
			send_stats "安装软件"
			install "$@"
			;;
		remove|del|uninstall|卸载)
			shift
			send_stats "卸载软件"
			remove "$@"
			;;
		update|更新)
			linux_update
			;;
		clean|清理)
			linux_clean
			;;
		dd|重装)
			dd_xitong
			;;
		bbr3|bbrv3)
			bbrv3
			;;
		nhyh|内核优化)
			Kernel_optimize
			;;
		trash|hsz|回收站)
			linux_trash
			;;
		backup|bf|备份)
			linux_backup
			;;
		ssh|远程连接)
			ssh_manager
			;;

		rsync|远程同步)
			rsync_manager
			;;

		rsync_run)
			shift
			send_stats "定时rsync同步"
			run_task "$@"
			;;

		disk|硬盘管理)
			disk_manager
			;;

		wp|wordpress)
			shift
			ldnmp_wp "$@"

			;;
		fd|rp|反代)
			shift
			ldnmp_Proxy "$@"
			;;

		swap)
			shift
			send_stats "快速设置虚拟内存"
			add_swap "$@"
			;;

		time|时区)
			shift
			send_stats "快速设置时区"
			set_timedate "$@"
			;;


		iptables_open)
			iptables_open
			;;

		frps)
			frps_panel
			;;

		frpc)
			frpc_panel
			;;


		打开端口|dkdk)
			shift
			open_port "$@"
			;;

		关闭端口|gbdk)
			shift
			close_port "$@"
			;;

		放行IP|fxip)
			shift
			allow_ip "$@"
			;;

		阻止IP|zzip)
			shift
			block_ip "$@"
			;;

		防火墙|fhq)
			iptables_panel
			;;

		status|状态)
			shift
			send_stats "软件状态查看"
			status "$@"
			;;
		start|启动)
			shift
			send_stats "软件启动"
			start "$@"
			;;
		stop|停止)
			shift
			send_stats "软件暂停"
			stop "$@"
			;;
		restart|重启)
			shift
			send_stats "软件重启"
			restart "$@"
			;;

		enable|autostart|开机启动)
			shift
			send_stats "软件开机自启"
			enable "$@"
			;;

		ssl)
			shift
			if [ "$1" = "ps" ]; then
				send_stats "查看证书状态"
				ssl_ps
			elif [ -z "$1" ]; then
				add_ssl
				send_stats "快速申请证书"
			elif [ -n "$1" ]; then
				add_ssl "$1"
				send_stats "快速申请证书"
			else
				k_info
			fi
			;;

		docker)
			shift
			case $1 in
				install|安装)
					send_stats "快捷安装docker"
					install_docker
					;;
				ps|容器)
					send_stats "快捷容器管理"
					docker_ps
					;;
				img|镜像)
					send_stats "快捷镜像管理"
					docker_image
					;;
				*)
					k_info
					;;
			esac
			;;

		web)
		   shift
			if [ "$1" = "cache" ]; then
				web_cache
			elif [ -z "$1" ]; then
				ldnmp_web_status
			else
				k_info
			fi
			;;
		*)
			k_info
			;;
	esac
fi
