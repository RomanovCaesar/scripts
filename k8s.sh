#!/bin/bash

ip_address() {
ipv4_address=$(curl -s ipv4.ip.sb)
ipv6_address=$(curl -s --max-time 1 ipv6.ip.sb)
}


install() {
    if [ $# -eq 0 ]; then
        echo "未提供软件包参数!"
        return 1
    fi

    for package in "$@"; do
        if ! command -v "$package" &>/dev/null; then
            if command -v apt &>/dev/null; then
                apt update -y && apt install -y "$package"
            elif command -v yum &>/dev/null; then
                yum -y update && yum -y install "$package"
            elif command -v apk &>/dev/null; then
                apk update && apk add "$package"
            else
                echo "未知的包管理器!"
                return 1
            fi
        fi
    done

    return 0
}


remove() {
    if [ $# -eq 0 ]; then
        echo "未提供软件包参数!"
        return 1
    fi

    for package in "$@"; do
        if command -v apt &>/dev/null; then
            apt purge -y "$package"
        elif command -v yum &>/dev/null; then
            yum remove -y "$package"
        elif command -v apk &>/dev/null; then
            apk del "$package"
        else
            echo "未知的包管理器!"
            return 1
        fi
    done

    return 0
}

break_end() {
      echo -e "\033[0;32m操作完成\033[0m"
      echo "按任意键继续..."
      read -n 1 -s -r -p ""
      echo ""
      clear
}

install_k8s() {
    clear

    rc-update add local default
    rc-update show | grep local

    cat <<EOF >  /etc/local.d/mount-rshared.start
#!/bin/sh
mount --make-rshared /
EOF
    chmod +x /etc/local.d/mount-rshared.start
    /etc/local.d/mount-rshared.start

    echo "$hostname_use" > /etc/hostname
    hostname "$hostname_use"
    cat > /etc/hosts << EOF
127.0.0.1 localhost
$ipv4_address $hostname_use
EOF

    cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward=1
vm.max_map_count=262144
EOF

    modprobe br_netfilter
    sysctl -p /etc/sysctl.d/k8s.conf

    apk update && apk upgrade
    apk add containerd kubelet kubeadm kubectl
    rc-update add containerd default
    service containerd start
    rc-update add kubelet default
    service kubelet start
    containerd config default > /etc/containerd/config.toml
    service containerd restart

    cat <<EOF >  /var/lib/kubelet/kubeadm-flags.env
    KUBELET_KUBEADM_ARGS="--container-runtime-endpoint=unix:///var/run/containerd/containerd.sock --pod-infra-container-image=registry.k8s.io/pause:3.9 --cluster-dns=10.96.0.10,8.8.8.8,1.1.1.1 --cluster-domain=cluster.local"
EOF

    cat <<EOF >  /etc/resolv.conf
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF

  service kubelet restart
  echo "Kubernetes环境安装完成"

}





while true; do
clear
echo -e "\033[96mK8S脚本工具v0.1  by KEJILION 目前支持Alpine\033[0m"
hostname=$(hostname)
echo "主机名: $hostname"
echo "------------------------"
echo "1. 安装环境并创建集群"
echo "2. 安装环境并加入集群"
echo "3. 加入集群"
echo "------------------------"
echo "5. 集群管理（仅限主节点）"
echo "------------------------"
echo "31. 重装系统"
echo "------------------------"
echo "0. 退出脚本"
echo "------------------------"
read -p "请输入你的选择: " choice

case $choice in
  1)

    ip_address
    current_date=$(date +%y%m%d)
    hostname_use="k8s-Master-$current_date-$ipv4_address"
    echo "随机获取的 Kubernetes 名称: $hostname_use"

    install_k8s
    kubeadm init

    mkdir -p $HOME/.kube
    cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    chown $(id -u):$(id -g) $HOME/.kube/config
    kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
    sleep 10
    kubectl get componentstatuses
    kubectl get nodes
    kubectl get all --all-namespaces
    kubectl get pods -A -o wide
    echo "------------"
    echo "这是加入集群的命令，在其他机器上使用，可以加入到本集群"
    kubeadm token create --print-join-command
    echo "Kubernetes集群搭建完成"

    ;;

  2)

    ip_address
    current_date=$(date +%y%m%d)
    hostname_use="k8s-Worker-$current_date-$ipv4_address"
    echo "随机获取的 Kubernetes 名称: $hostname_use"

    install_k8s
    read -p "输入集群加入命令: " jiaruk8s
    $jiaruk8s

    ;;

  3)

    read -p "输入集群加入命令: " jiaruk8s
    $jiaruk8s

    ;;

  5)
    echo "Kubernetes集群状态"
    kubectl get componentstatuses
    kubectl get nodes
    kubectl get all --all-namespaces
    kubectl get pods -A -o wide

    ;;

  31)
    dd_xitong_1() {
      read -p "请输入你重装后的密码: " vpspasswd
      echo "任意键继续，重装后初始用户名: root  初始密码: $vpspasswd  初始端口: 22"
      read -n 1 -s -r -p ""
      install wget
      bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh') $xitong -v 64 -p $vpspasswd -port 22
    }

    dd_xitong_2() {
      echo "任意键继续，重装后初始用户名: root  初始密码: LeitboGi0ro  初始端口: 22"
      read -n 1 -s -r -p ""
      install wget
      wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh' && chmod a+x InstallNET.sh
    }

    dd_xitong_3() {
      echo "任意键继续，重装后初始用户名: Administrator  初始密码: Teddysun.com  初始端口: 3389"
      read -n 1 -s -r -p ""
      install wget
      wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh' && chmod a+x InstallNET.sh
    }

    clear
    echo "请备份数据，将为你重装系统，预计花费15分钟。"
    echo -e "\e[37m感谢MollyLau和MoeClub的脚本支持！\e[0m "
    read -p "确定继续吗？(Y/N): " choice

    case "$choice" in
      [Yy])
        while true; do

          echo "------------------------"
          echo "1. Debian 12"
          echo "2. Debian 11"
          echo "3. Debian 10"
          echo "4. Debian 9"
          echo "------------------------"
          echo "11. Ubuntu 24.04"
          echo "12. Ubuntu 22.04"
          echo "13. Ubuntu 20.04"
          echo "14. Ubuntu 18.04"
          echo "------------------------"
          echo "21. CentOS 9"
          echo "22. CentOS 8"
          echo "23. CentOS 7"
          echo "------------------------"
          echo "31. Alpine 3.19"
          echo "------------------------"
          echo "41. Windows 11"
          echo "42. Windows 10"
          echo "43. Windows Server 2022"
          echo "44. Windows Server 2019"
          echo "44. Windows Server 2016"
          echo "------------------------"
          read -p "请选择要重装的系统: " sys_choice

          case "$sys_choice" in
            1)
              xitong="-d 12"
              dd_xitong_1
              exit
              reboot
              ;;

            2)
              xitong="-d 11"
              dd_xitong_1
              reboot
              exit
              ;;

            3)
              xitong="-d 10"
              dd_xitong_1
              reboot
              exit
              ;;
            4)
              xitong="-d 9"
              dd_xitong_1
              reboot
              exit
              ;;

            11)
              dd_xitong_2
              bash InstallNET.sh -ubuntu 24.04
              reboot
              exit
              ;;
            12)
              dd_xitong_2
              bash InstallNET.sh -ubuntu 22.04
              reboot
              exit
              ;;

            13)
              xitong="-u 20.04"
              dd_xitong_1
              reboot
              exit
              ;;
            14)
              xitong="-u 18.04"
              dd_xitong_1
              reboot
              exit
              ;;


            21)
              dd_xitong_2
              bash InstallNET.sh -centos 9
              reboot
              exit
              ;;


            22)
              dd_xitong_2
              bash InstallNET.sh -centos 8
              reboot
              exit
              ;;

            23)
              dd_xitong_2
              bash InstallNET.sh -centos 7
              reboot
              exit
              ;;



            31)
              dd_xitong_2
              bash InstallNET.sh -alpine
              reboot
              exit
              ;;



            41)
              dd_xitong_3
              bash InstallNET.sh -windows 11 -lang "cn"
              reboot
              exit
              ;;

            42)
              dd_xitong_3
              bash InstallNET.sh -windows 10 -lang "cn"
              reboot
              exit
              ;;

            43)
              dd_xitong_3
              bash InstallNET.sh -windows 2022 -lang "cn"
              reboot
              exit
              ;;

            44)
              dd_xitong_3
              bash InstallNET.sh -windows 2019 -lang "cn"
              reboot
              exit
              ;;

            45)
              dd_xitong_3
              bash InstallNET.sh -windows 2016 -lang "cn"
              reboot
              exit
              ;;


            *)
              echo "无效的选择，请重新输入。"
              ;;
          esac
        done
        ;;
      [Nn])
        echo "已取消"
        ;;
      *)
        echo "无效的选择，请输入 Y 或 N。"
        ;;
    esac

    ;;


  0)
    clear
    exit
    ;;

  *)
    echo "无效的输入!"
    ;;
esac
    break_end
done
