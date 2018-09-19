#!/bin/bash

base_path="/usr/local/"
#安装客户端
status_agent(){
   read -p "开始安装Serverstatus yes:no: " agent_select
   if [ "$agent_select" == "yes" ];then
     yum install git -y
     cd $base_path
     git clone https://github.com/vikenlau/ServerStatus.git
     yum -y install epel-release;yum -y install python-pip;
     pip install --upgrade pip
     yum clean all;yum -y install gcc; yum -y install python-devel;pip install psutil
     cd ServerStatus/clients
     c_file="client.py"
     read -p "输入SERVER地址: " server_name
     sed -i "s#^SERVER.*#SERVER = \"$server_name\"#g" $c_file
     read -p "输入USER: " user
     sed -i "s#^USER.*#USER = \"$user\"#g" $c_file
     read -p "输入PASSWORD: " password
     sed -i "s#^PASSWORD.*#PASSWORD = \"$password\"#g" $c_file
     echo "nohup python $base_path/Serverstatus/client.py &" >>/etc/rc.local
     echo "开始启动客户端"
     nohup python client.py &
     sleep 3
  fi

}

#安装服务端
shadow(){
   read -p "开始安装shadow yes:no: " shadow_select
   if [ "$shadow_select" == "yes" ];then

     install python-setuptools && easy_install pip && pip install cymysql speedtest-cli && yum install git
     yum -y groupinstall "Development Tools" 
     wget -P $base_path https://raw.githubusercontent.com/mmmwhy/ss-panel-and-ss-py-mu/master/libsodium-1.0.13.tar.gz
     cd $base_path
     tar xf libsodium-1.0.13.tar.gz && cd libsodium-1.0.13
     ./configure && make -j2 && make install&&echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf&&ldconfig
     rm -rf /base_path/libsodium-1.0.13.tar.gz && cd $base_path
     git clone -b manyuser https://github.com/vikenlau/shadowsocks.git
     yum -y install python-devel
     yum -y install libffi-devel
     yum -y install openssl-devel
     cd shadowsocks
     pip install -r requirements.txt
     cp apiconfig.py userapiconfig.py
     cp config.json user-config.json
     api_conf=userapiconfig.py
     read -p "请输入NODE_ID 编号: " node_id
     sed -i "s#^NODE_ID.*#NODE_ID = $node_id#g" $api_conf

     read -p "请输入连接方式 glzjinmod 或者 modwebapi 回车默认为modwebapi: " api
     if [ -z "$api" ];then
      api=modwebapi
     fi
     sed -i "s#^API_INTERFACE.*#API_INTERFACE = \'$api\'#g" $api_conf
     echo $api
     if [ "$api" == "modwebapi" ];then
        echo "webapi 模式"
     #webapi 
        read -p "请输入webapi url地址 默认为https://zhaoj.in 回车即可: " api_url
        [ -z "$api_url" ]&&api_url="https://zhaoj.in"
        sed -i "s#^WEBAPI_URL.*#WEBAPI_URL = \'$api_url\'#g" $api_conf
     #token
        read -p "请输入WEBAPI_TOKEN 默认为glzjin :" token
        [ -z "$token" ] && token="glzjin"
        sed -i "s#^WEBAPI_TOKEN.*#WEBAPI_TOKEN = \'$token\'#g" $api_conf
     elif [ "$api" == "glzjinmod" ];then
        echo "sql模式 下面要配置数据库"
#mysql_host
        read -p "请输入MYSQL_HOST 默认为127.0.0.1 : " mysql_host
        [ -z $mysql_host ]&& mysql_host="127.0.0.1"
        sed -i "s#^MYSQL_HOST.*#MYSQL_HOST = \"$mysql_host\"#g" $api_conf

#mysql_port
        read -p "请输入MYSQL_PORT 默认为3306: " mysql_port
        [ -z $mysql_port ]&& mysql_port="3306"
        echo $mysql_port
        sed -i "s#^MYSQL_PORT.*#MYSQL_PORT = $mysql_port#g" $api_conf
#mysql_user
        read -p "请输入MYSQL_USER 默认为xxx: " mysql_user
        [ -z $mysql_user ]&& mysql_user="default_user"
        sed -i "s#^MYSQL_USER.*#MYSQL_USER = \"$mysql_user\"#g" $api_conf
#mysql_pass
        read -p "请输入MYSQL_PASS 默认为xxx : " mysql_pass
        [ -z $mysql_pass ]&& mysql_pass="default_pass"
        sed -i "s#^MYSQL_PASS.*#MYSQL_PASS = \"$mysql_pass\"#g" $api_conf
#mysql_db
        read -p "请输入MYSQL_DB 默认为xxx: " mysql_db
        sed -i "s#^MYSQL_DB.*#MYSQL_DB = \"$mysql_db\"#g" $api_conf
        [ -z $mysql_pass ]&& mysql_db="default_db"
     fi
     echo "开始启动服务端程序"
     ./logrun.sh
     sleep 3
   fi
}


#其他设置
ddns(){
   read -p "开始配置安装ddns yes:no: " ddns_select
   if [ "$ddns_select" == "yes" ];then
      #设置ddns
      echo "配置ddns"
      yum install wget -y
      curl https://raw.githubusercontent.com/vikenlau/cfddns/master/cf-ddns.sh > /usr/local/bin/cf-ddns.sh
      chmod +x /usr/local/bin/cf-ddns.sh
      ddns_path=/usr/local/bin/cf-ddns.sh
      read -p "输入ddns认证邮箱: " email
      sed -i "s#^auth_email.*#auth_email=\"$(echo "$email")\"#g" $ddns_path
      read -p "输入auth_key: " key
      sed -i "s#^auth_key.*#auth_key=\"$(echo $key)\"#g" $ddns_path
      read -p "输入zone_name: " zone_name
      sed -i "s#^zone_name.*#zone_name=\"$(echo $zone_name)\"#g" $ddns_path
      read -p "输入record_name: " record_name
      sed -i "s#^record_name.*#record_name=\"$(echo $record_name)\"#g" $ddns_path
      read -p "ddns是否加入定时任务:yes|no" cron_ddns
      if [ $cron_ddns == "yes" ];then
      #设置定时任务
      echo "*/1 * * * *  /usr/local/bin/cf-ddns.sh >/dev/null 2>&1" >>crontab.txt
      /usr/bin/crontab crontab.txt
      fi
        
      
      #修改系统时间为北京
      rm -rf /etc/localtime
      ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
   fi
}

#安装bbr
bbr(){
read -p "开始配置安装bbr yes:no: " bbr_select
if [ "$bbr_select" == "yes" ];then
#导入ELRepo公钥
wget https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm --import RPM-GPG-KEY-elrepo.org
#安装ELRepo
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
#升级最新内核
yum --enablerepo=elrepo-kernel install kernel-ml -y
#调整内核启动顺序
grub2-mkconfig -o /boot/grub2/grub.cfg && grub2-set-default 0
cat >>/etc/sysctl.conf << EOF
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
#使配置生效
sysctl -p
echo "检查生效，输出带有tcp_bbr 20480  a0即生效"

echo "检查结果为:`lsmod | grep bbr`"

echo "请手动重启服务器"
fi
}

main(){
  #执行对应功能的函数
  status_agent&&shadow&&ddns&&bbr
}

main
