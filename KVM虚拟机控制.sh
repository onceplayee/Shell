#!/bin/bash

# 定义红色输出函数
echo_red() { echo -e "\e[31m$1\e[0m"; }
# 定义绿色输出函数
echo_green() { echo -e "\e[32m$1\e[0m"; }
echo "正在进行前置检查"
# 判断是否支持虚拟化，是否安装相关软件，是否可以进行KVM虚拟化
# 检查CPU是否支持虚拟化技术（VT-x或AMD-V）
lscpu | grep -i -E "vt-x|amd-v" &>/dev/null
# 如果上一条命令的退出状态码不为0，表示CPU不支持虚拟化
if [ $? -ne 0 ]; then
    # 输出错误信息，提示CPU不支持虚拟化
    echo_red "您的CPU不支持虚拟化！"
    # 退出脚本，返回状态码99
    exit 99
else
    # 检查系统中是否已安装libvirt软件包
    rpm -qa libvirt &>/dev/null
    # 如果上一条命令的退出状态码不为0，表示libvirt未安装
    if [ $? -ne 0 ]; then
        # 提示用户是否要进行KVM虚拟化初始部署，并读取用户输入
        read -p "是否要进行KVM虚拟化初始部署(y/n)" choice
        # 如果用户输入为"y"，表示同意进行初始部署
        if [ "${choice}" == "y" ]; then
            # 安装KVM及相关依赖软件包
            yum install -y qemu-kvm qemu-img libvirt virt-install virt-manager libvirt-python libvirt-client virt-viewer &>/dev/null
            # 检查KVM模块是否已加载
            lsmod | grep -i kvm &>/dev/null
            # 如果上一条命令的退出状态码为0，表示KVM模块已加载
            if [ $? -eq 0 ]; then
                # 输出成功信息，提示KVM虚拟化初始环境部署完成
                echo_green "KVM虚拟化初始环境部署完成"
                # 启动libvirtd服务
                systemctl start libvirtd

                # 检查libvirtd服务的状态
                if systemctl status libvirtd; then
                    # 输出成功信息，提示KVM虚拟化服务开启成功
                    echo_green "KVM虚拟化服务开启成功"
                else
                    # 输出错误信息，提示KVM虚拟化服务开启失败
                    echo_red "KVM虚拟化服务开启失败"
                fi

            else
                # 输出错误信息，提示初始化失败，可能是网络问题或yum仓库问题
                echo_red "初始化失败，请检查网络连通性或者是否存在合适的yum仓库"
            fi
        else
            # 如果用户输入不为"y"，直接启动libvirtd服务
            systemctl start libvirtd
            # 检查libvirtd服务的状态
            if systemctl status libvirtd; then
                # 输出成功信息，提示KVM虚拟化服务开启成功
                echo_green "KVM虚拟化服务开启成功"
            else
                # 输出错误信息，提示KVM虚拟化服务开启失败
                echo_red "KVM虚拟化服务开启失败"
            fi
        fi
    fi
fi
echo "检查完成，脚本可正常运行"

# 新建虚拟机
create_vm() {
    # 定义KVM配置文件和磁盘文件的路径
    kvm_config_file=/kvm/iso/base.xml
    kvm_disk_file=/kvm/iso/base.img

    # 提示用户输入要创建的虚拟机数量
    read -p "请输入创建的虚拟机数量: " number
    
    # 如果用户输入"cancel"，则跳过后续操作
    if [ "${number}" == "cancel" ]; then
        continue
    fi
            
    # 循环创建指定数量的虚拟机
    for i in $(seq $number); do
        # 生成虚拟机名称，格式为vmX_centos
        vm_name=vm${i}_centos
        # 复制基础配置文件到指定路径，并重命名为虚拟机名称的配置文件
        cp ${kvm_config_file} /etc/libvirt/qemu/${vm_name}.xml
        # 创建一个新的磁盘文件，基于基础磁盘文件，使用qcow2格式
        qemu-img create -f qcow2 -b ${kvm_disk_file} /var/lib/libvirt/images/${vm_name}.img &>/dev/null

        # 修改配置文件中的虚拟机名称
        sed -ri "s/vm_base/${vm_name}/g" /etc/libvirt/qemu/${vm_name}.xml
        # 生成一个新的UUID并替换配置文件中的UUID
        sed -ri "/uuid/c \ <uuid>$(uuidgen)</uuid>" /etc/libvirt/qemu/${vm_name}.xml

        # 生成一个随机的MAC地址
        vm_mac=52:54:00:$(openssl rand -hex 10 | sed -r 's/(..)(..)(..).*/\1:\2:\3/')
        # 替换配置文件中的MAC地址
        sed -ri "/<mac/c \ <mac address='${vm_mac}'/>" /etc/libvirt/qemu/${vm_name}.xml

        # 使用virsh命令定义新的虚拟机
        virsh define /etc/libvirt/qemu/${vm_name}.xml &>/dev/null
        # 输出创建完成的信息
        echo "虚拟机 ${vm_name} 创建完成"
    done
}

# 虚拟机存在检查
check_exist_vm() {
    # 获取所有虚拟机列表，并删除前两行标题信息
    vm_list=$(virsh list --all | sed '1,2d')
    # 统计虚拟机列表中非空行的数量
    number=$(echo "$vm_list" | sed '/^$/d' | wc -l)
    # 如果没有虚拟机存在
    if [ ${number} -eq 0 ]; then
    # 提示用户是否需要创建新的虚拟机
        echo "检测到您还没有任何虚拟机存在，是否需要现在创建(y/n)"
        read choice
        # 如果用户选择创建虚拟机
            if [ "${choice}" == "y" ] || [ "${choice}" == "Y" ]; then
                create_vm
                return
            else
         # 如果用户选择不创建，退出脚本
            echo "您选择不创建虚拟机"
            echo "此脚本无法在没有虚拟机的前提下使用，您可以选择创建虚拟机在使用本脚本，已为您退出脚本！"
            exit 99
        fi
        return
     fi
}

check_exist_vm


# 获取所有虚拟机列表以及运行状态
get_vm_state() {
check_exist_vm
    # 获取所有虚拟机列表，并删除前两行标题信息
    vm_list=$(virsh list --all | sed '1,2d')
    # 统计虚拟机列表中非空行的数量
    number=$(echo "$vm_list" | sed '/^$/d' | wc -l)
    # 遍历每个虚拟机
    for i in $(seq 1 $number); do
        # 获取当前虚拟机的名称
        vm_name=$(echo "$vm_list" | awk -v line=$i 'NR == line {print $2}')
        # 获取当前虚拟机的状态
        vm_state=$(echo "$vm_list" | awk -v line=$i 'NR == line {print $3}')
        # 如果虚拟机正在运行
        if [ "${vm_state}" == "running" ]; then
            state="运行中"
            # 以绿色显示虚拟机名称和状态
            echo -e "${vm_name}\t\e[032m${state}\e[0m"
        else
            state="未运行"
            # 以红色显示虚拟机名称和状态
            echo -e "${vm_name}\t\e[031m${state}\e[0m"
        fi
    done
}

# 定义一个函数start_vm，用于启动虚拟机
start_vm() {
    # 调用check_exist_vm函数，检查虚拟机是否存在（假设该函数已定义）
check_exist_vm
    # 初始化一个空数组search_list，用于存储待启动的虚拟机名称
    search_list=()
    # 进入一个无限循环，等待用户输入虚拟机编号
    while true; do
        # 提示用户输入要启动的虚拟机编号，输入'over'表示输入完成
        read -p "请输入要启动的虚拟机编号(输入'over'表示输入完成，回车以输入下一个虚拟机编号)： " vm_bum
        # 检查用户输入是否为'over'，如果是则跳出循环
        if [ "${vm_bum}" == "over" ]; then
            break
        fi

        # 使用virsh list --all命令列出所有虚拟机，并通过grep查找编号为vm_bum的虚拟机名称
        vm_name=$(virsh list --all | grep -w "vm${vm_bum}_centos" | awk '{print $2}')
        # 再次使用virsh list --all和grep检查虚拟机是否存在，输出重定向到/dev/null
        virsh list --all | grep "vm${vm_bum}_centos" &>/dev/null
        # 检查输入的虚拟机名称是否在列表中
        if [ $? -eq 0 ]; then
            vm_state=$(virsh dominfo "vm${vm_bum}_centos" | grep State | awk '{print $2}')
            echo "${vm_state}"
            if [ "${vm_state}" == "running" ];then
                echo_red "错误：'$vm_name' 虚拟机已经在运行，请重新输入。"
                continue
            fi
            # 如果存在，添加到待启动列表
            search_list+=("$vm_name")
            echo_green "${vm_name}添加成功"
        else
            # 如果不存在，提示错误并让用户重新输入
            echo_red "错误：'$vm_bum' 不是有效的虚拟机编号，请重新输入。"
        fi
    done

    # 批量启动虚拟机
    for vm in "${search_list[@]}"; do
        echo "正在启动虚拟机：${vm}"
        virsh start ${vm}
        if [ $? -eq 0 ]; then
            echo_green "${vm}启动成功"
        else
            echo_red "${vm}启动失败"
        fi
    done
}

# 定义一个函数stop_vm，用于停止虚拟机
stop_vm() {
    # 调用check_exist_vm函数，检查是否存在虚拟机（假设该函数已定义）
check_exist_vm
    # 初始化一个空数组search_list，用于存储待停止的虚拟机名称
    search_list=()
    # 进入一个无限循环，等待用户输入虚拟机编号
    while true; do
        # 提示用户输入要停止的虚拟机编号，输入'over'表示输入完成
        read -p "请输入要停止的虚拟机编号(输入'over'表示输入完成，回车以输入下一个虚拟机编号)： " vm_bum
        # 检查用户输入是否为'over'，如果是则跳出循环
        if [ "${vm_bum}" == "over" ]; then
            break
        fi

        # 使用virsh list --all命令列出所有虚拟机，并通过grep和awk获取指定编号的虚拟机名称
        vm_name=$(virsh list --all | grep -w "vm${vm_bum}_centos" | awk '{print $2}')
        # 使用virsh list --all命令列出所有虚拟机，并通过grep检查指定编号的虚拟机是否存在
        virsh list --all | grep "vm${vm_bum}_centos" &>/dev/null
        # 检查输入的虚拟机名称是否在列表中
        if [ $? -eq 0 ]; then
            vm_state=$(virsh dominfo "vm${vm_bum}_centos" | grep State | awk '{print $2,$3}')
            if [ "${vm_state}" == "shut off" ]; then
                echo_red "错误：'$vm_name' 虚拟机已经停止，请重新输入。"
                continue
            fi
            # 如果存在，添加到待停止列表
            search_list+=("$vm_name")
            echo_green "${vm_name}添加成功"
        else
            # 如果不存在，提示错误并让用户重新输入
            echo_red "错误：'$vm_bum' 不是有效的虚拟机编号，请重新输入。"
        fi
    done
    # 批量停止虚拟机
    for vm in "${search_list[@]}"; do
        echo "正在停止虚拟机：${vm}"
        virsh destroy ${vm}
        if [ $? -eq 0 ]; then
            echo_green "${vm}停止成功"
        else
            echo_red "${vm}停止失败"
        fi
    done
}

restart_vm() {
    # 调用check_exist_vm函数，检查虚拟机是否存在
check_exist_vm
    # 初始化一个空数组，用于存储待重启的虚拟机名称
    search_list=()
    # 进入一个无限循环，等待用户输入虚拟机编号
    while true; do
        # 提示用户输入虚拟机编号，输入'over'表示输入完成
        read -p "请输入要重启的虚拟机编号(输入'over'表示输入完成，回车以输入下一个虚拟机编号)： " vm_bum
        # 检查用户输入是否为'over'，如果是则跳出循环
        if [ "${vm_bum}" == "over" ]; then
            break
        fi

        # 使用virsh命令列出所有虚拟机，并通过grep查找编号为vm_bum的虚拟机名称
        vm_name=$(virsh list --all | grep -w "vm${vm_bum}_centos" | awk '{print $2}')
        # 使用virsh命令列出所有虚拟机，并通过grep检查编号为vm_bum的虚拟机是否存在
        virsh list --all | grep "vm${vm_bum}_centos" &>/dev/null
        # 检查输入的虚拟机名称是否在列表中
        if [ $? -eq 0 ]; then
            vm_state=$(virsh dominfo "vm${vm_bum}_centos" | grep State | awk '{print $2,$3}')
            if [ "${vm_state}" == "shut off" ]; then
                echo_red "错误：'$vm_bum' 虚拟机已经停止，请重新输入。"
                continue
            fi
            # 如果存在，添加到待重启列表
            search_list+=("$vm_name")
            echo_green "${vm_name}添加成功"
        else
            # 如果不存在，提示错误并让用户重新输入
            echo_red "错误：'$vm_bum' 不是有效的虚拟机编号，请重新输入。"
        fi
    done
    # 批量重启虚拟机
    for vm in "${search_list[@]}"; do
        echo "正在重启虚拟机：${vm}"
        virsh reboot ${vm}
        if [ $? -eq 0 ]; then
            echo_green "${vm}重启成功"
        else
            echo_red "${vm}重启失败"
        fi
    done
}

# 批量查询指定虚拟机
batch_get_vm_info() {
check_exist_vm
    search_list=()
    while true; do
        read -p "请在此键入需要查询的虚拟机编号，例如vm3_centos，输入3，键入'over'表示输入完成，回车以输入下一个虚拟机编号：" vm_bum
        if [ "${vm_bum}" == "over" ]; then
            break
        fi

        vm_name=$(virsh list --all | grep -w "vm${vm_bum}_centos" | awk '{print $2}')
        virsh list --all | grep "vm${vm_bum}_centos" &>/dev/null
        # 检查输入的虚拟机名称是否在列表中
        if [ $? -eq 0 ]; then
            # 如果存在，添加到待查询列表
            search_list+=("$vm_name")
            echo_green "${vm_name}添加成功"
        else
            # 如果不存在，提示错误并让用户重新输入
            echo_red "错误：'$vm_bum' 不是有效的虚拟机编号，请重新输入。"
        fi
    done

    # 批量查询虚拟机
    for vm in "${search_list[@]}"; do
        echo "正在查询虚拟机：${vm}"
        virsh dominfo ${vm}
    done
}

# 删除所有虚拟机
delete_all_vm() {
    # 使用virsh list --all列出所有虚拟机，并通过awk获取虚拟机名称
    for vm_name in $(virsh list --all | awk 'NR>2{print $2}'); do
        # 使用virsh destroy强制关闭虚拟机，&>/dev/null表示忽略输出
        virsh destroy ${vm_name} &>/dev/null
        # 使用virsh undefine删除虚拟机定义，&>/dev/null表示忽略输出
        virsh undefine ${vm_name} &>/dev/null
    done
    # 删除所有虚拟机镜像文件，&>/dev/null表示忽略输出
    rm -rf /var/lib/libvirt/images/* &>/dev/null
}

# 批量删除指定虚拟机
delete_vm() {
check_exist_vm
    # 初始化待删除虚拟机列表
    delete_list=()
    # 无限循环，直到用户输入'over'
    while true; do
        # 提示用户输入需要删除的虚拟机编号
        read -p "请在此键入需要删除的虚拟机编号，例如vm3_centos，输入3，键入'over'表示输入完成，回车以输入下一个虚拟机编号：" vm_bum
        # 检查用户输入是否为'over'
        if [ "${vm_bum}" == "over" ]; then
            # 如果是，退出循环
            break
        fi

        # 使用virsh list --all和grep查找虚拟机名称
        vm_name=$(virsh list --all | grep -w "vm${vm_bum}_centos" | awk '{print $2}')

        # 使用virsh list --all和grep检查虚拟机是否存在
        virsh list --all | grep "vm${vm_bum}_centos" &>/dev/null
        # 检查输入的虚拟机名称是否在列表中
        if [ $? -eq 0 ]; then
            # 如果存在，添加到待删除列表
            delete_list+=("$vm_name")
            echo_green "${vm_name}添加成功"
        else
            # 如果不存在，提示错误并让用户重新输入
            echo_red "错误：'$vm_bum' 不是有效的虚拟机编号，请重新输入。"
        fi
    done

    # 确认要删除的虚拟机列表
    # 输出用户选择的要删除的虚拟机列表
    echo "您选择删除以下虚拟机：${delete_list[@]}"
    # 提示用户确认是否要删除这些虚拟机，并读取用户输入
    read -p "确认删除这些虚拟机吗？(y/n): " confirm
    # 检查用户输入是否为 "y"，如果不是则取消删除操作
    if [ "$confirm" != "y" ]; then
        echo "删除操作已取消。"
        return
    fi

    # 删除虚拟机
    for vm in "${delete_list[@]}"; do
        echo "正在删除虚拟机：${vm}"
        virsh destroy "${vm}" &>/dev/null
        virsh undefine "${vm}" &>/dev/null
        echo_green "虚拟机 '${vm}' 删除完成。"
    done
    rm -rf /var/lib/libvirt/images/${vm}.img &>/dev/null
}

# 更新虚拟机内存设置
update_vm_memory() {
check_exist_vm
    # 初始化一个空数组用于存储待修改的虚拟机编号
    search_list=()
    # 进入一个无限循环，直到用户输入"over"为止
    while true; do
        # 提示用户输入虚拟机编号
        read -p "请在此键入需要更改的虚拟机编号，例如vm3_centos，输入3，键入'over'表示输入完成，回车以输入下一个虚拟机编号：" vm_bum
        # 检查用户是否输入了"over"
        if [ "${vm_bum}" == "over" ]; then
            break
        fi

        # 使用virsh命令列出所有虚拟机，并使用grep和awk找到匹配的虚拟机名称
        vm_name=$(virsh list --all | grep -w "vm${vm_bum}_centos" | awk '{print $2}')

        # 使用virsh命令列出所有虚拟机，并检查输入的编号是否在列表中
        virsh list --all | grep "${vm_bum}" &>/dev/null
        # 检查输入的虚拟机名称是否在列表中
        if [ $? -eq 0 ]; then
            # 如果存在，添加到待修改列表
            change_list+=("$vm_name")
            echo_green "${vm_name}添加成功"
        else
            # 如果不存在，提示错误并让用户重新输入
            echo_red "错误：'$vm_bum' 不是有效的虚拟机编号，请重新输入。"
        fi
    done

    # 批量更改虚拟机
    for vm in "${change_list[@]}"; do
        # 从虚拟机配置文件中提取内存单位（如MB, GB）
        unit=$(grep "memory" /etc/libvirt/qemu/vm1_centos.xml | grep -oP "'[^']*'" | sed "s/'//g")
        # 从虚拟机配置文件中提取当前内存大小
        old_memory$(grep memory /etc/libvirt/qemu/vm1_centos.xml | sed -n 's/^[^0-9]*\([0-9]\+\).*/\1/p')
        # 输出当前内存量
        echo "当前内存量为${old_memory}${unit}"
        # 提示用户输入新的内存大小
        read -p "请输入更改后的内存：" new_memory
        # 输出正在更改的虚拟机名称
        echo "正在更改虚拟机内存：${vm}"
        # 关闭虚拟机
        virsh destroy $vm
        # 更新虚拟机配置文件中的内存大小
        memory /etc/libvirt/qemu/vm1_centos.xml | sed -i "s/${old_memory}/${new_memory}/g"
        # 启动虚拟机
        virsh start $vm
        # 获取当前虚拟机的最大内存
        now_memory=$(virsh dominfo vm1_centos | grep Max | awk '{print $3}')
        # 检查内存是否更改成功
        if [ ${now_memory} -eq ${new_memory} ];then
            # 输出更改成功的消息
            echo_green "更改成功当前内存为${now_memory}${unit}"
        else
            # 输出更改失败的消息
            echo_red "更改失败当前内存为${now_memory}${unit}"
        fi
    done
}

# 更新虚拟机CPU设置
update_vm_cpu() {
check_exist_vm
    # 初始化一个空数组，用于存储需要更改的虚拟机编号
    search_list=()
    # 进入一个无限循环，等待用户输入
    while true; do
        # 提示用户输入需要更改的虚拟机编号，例如vm3_centos，输入3，键入'over'表示输入完成
        read -p "请在此键入需要更改的虚拟机编号，例如vm3_centos，输入3，键入'over'表示输入完成，回车以输入下一个虚拟机编号：" vm_bum
        # 检查用户输入是否为'over'，如果是，则跳出循环
        if [ "${vm_bum}" == "over" ]; then
            break
        fi

        # 使用virsh命令列出所有虚拟机，并通过grep和awk找到与输入编号匹配的虚拟机名称
        vm_name=$(virsh list --all | grep -w "vm${vm_bum}_centos" | awk '{print $2}')

        # 使用virsh命令列出所有虚拟机，并通过grep检查输入的编号是否在列表中
        virsh list --all | grep "${vm_bum}" &>/dev/null
        # 检查输入的虚拟机名称是否在列表中
        if [ $? -eq 0 ]; then
            # 如果存在，添加到待修改列表
            change_list+=("$vm_name")
            echo_green "${vm_name}添加成功"
        else
            # 如果不存在，提示错误并让用户重新输入
            echo_red "错误：'$vm_bum' 不是有效的虚拟机编号，请重新输入。"
        fi
    done

    # 批量更改虚拟机
    for vm in "${change_list[@]}"; do
        # 输出当前正在更改的虚拟机名称
        echo "正在更改虚拟机CPU：${vm}"    
        # 获取当前虚拟机的CPU数目
        old_num=virsh dominfo ${vm_name} | grep -w "CPU(s)" | awk '{print $2}'
        # 输出当前虚拟机的CPU数目
        echo "当前虚拟机的CPU数目为：${old_num}"
        # 提示用户输入新的CPU数目
        read -p "您需要更改CPU数目为：" new_num
            
        # 判断用户输入的CPU数目是否大于当前CPU数目
            if [ ${new_num} -gt ${cpu_num} ]; then
            # 如果大于，则使用virsh命令实时更改CPU数目
                virsh setvcpus ${vm_name} ${i} --live
            elif [ ${new_num} -eq ${cpu_num} ]; then
            # 如果等于，则输出未做出改变
                echo "未做出改变"
            else

            # 如果小于，则先销毁虚拟机，再更改CPU数目，最后启动虚拟机
        virsh destroy ${vm}
        virsh setvcpus ${vm} ${i} --live
        virsh start ${vm_name}
            # 输出CPU数目更改完成
        echo_green "CPU数目更改完成"
    fi
    done
}

quit() {
    exit 99
}

while true; do
    cat <<EOF
---KVM虚拟机操作菜单---
1、创建虚拟机
2、删除虚拟机
3、查看虚拟机
4、更改虚拟机
5、操作虚拟机
6、退出此脚本
-----------------------
EOF
    read number
    case $number in
    1)
        echo "输入cancel以取消创建操作"
        create_vm
        ;;
    2)
        echo -e "1、删除所有虚拟机\n2、删除指定虚拟机\n3、返回上一级\n4、退出脚本"
        read choice_2
        if [ ${choice_2} -eq 1 ]; then
            delete_all_vm
            continue
        elif [ ${choice_2} -eq 2 ]; then
            delete_vm
            continue
        elif [ ${choice_2} -eq 3 ]; then
            continue
        elif [ ${choice_2} -eq 4 ]; then
            quit
        else
            echo "请输入正确的选项"
            continue
        fi
        ;;
    3)
        echo -e "1、查询所有虚拟机运行状态\n2、批量查询虚拟机信息\n3、返回上一级\n4、退出脚本"
        read choice_3
        if [ ${choice_3} -eq 1 ]; then
            get_vm_state
            continue
        elif [ ${choice_3} -eq 2 ]; then
            batch_get_vm_info
            continue
        elif [ ${choice_3} -eq 3 ]; then
            batch_get_vm_info
        elif [ ${choice_3} -eq 4 ]; then
            continue
        else
            echo "请输入正确的选项"
            continue
        fi
        ;;
    4)
        echo -e "1、更改虚拟机CPU配置\n2、更改虚拟机内存\n3、返回上一级\n4、退出脚本"
        read choice_4
        if [ ${choice_4} -eq 1 ]; then
            update_vm_cpu
            continue
        elif [ ${choice_4} -eq 2 ]; then
            update_vm_memory
            continue
        elif [ ${choice_4} -eq 3 ]; then
            continue
        elif [ ${choice_4} -eq 3 ]; then
            quit
        else
            echo "请输入正确的选项"
            continue
        fi
        ;;
    5)
       echo -e "1、启动虚拟机\n2、关闭虚拟机\n3、重启虚拟机\n4、返回上一级\n5、退出脚本"
        read choice_4
        if [ ${choice_4} -eq 1 ]; then
            start_vm
            continue
        elif [ ${choice_4} -eq 2 ]; then
            stop_vm
        elif [ ${choice_4} -eq 3 ]; then
            restart_vm
        elif [ ${choice_4} -eq 4 ]; then
            continue
        elif [ ${choice_4} -eq 5 ];then
            quit
        else
            echo "请输入正确的选项"
            continue
        fi
        ;;
    6)  
        echo "感谢你的使用"
        quit
        ;;
    *)
        echo "请输入正确的选项！"
        continue
        ;;
    esac
done
# QAQ TAT ^_^ -_- -_- ^_^ QAQ TAT
