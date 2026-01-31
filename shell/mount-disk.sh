#!/bin/bash

# 安装插件
yum install lvm2 -y

# 定义要挂载的硬盘列表和分区号
disks=(
    "/dev/vdb"
)
partitions=(
    "1"
    "1"
    "1"
)

# 创建分区并格式化
for i in "${!disks[@]}"; do
    disk="${disks[$i]}"

    partition="${disk}${partitions[$i]}"

    echo ${disk}
    echo ${partition}
    # 创建分区,不要删除下面的空格
    # parted -s "$disk" mkpart primary ext4 0% 100%
    fdisk "$disk" <<EOF
n
p
1


t
8e
w
EOF

    # 格式化分区
    mkfs.ext4 "$partition"

    # 创建物理卷
    pvcreate "$partition" -y

    # 创建逻辑卷组
    vgcreate datavg "$partition"

    # 创建逻辑卷
    lvcreate -l 100%FREE -n datalv datavg

    # 创建 ext4 文件系统
    mkfs.ext4 /dev/datavg/datalv

    # 创建挂载点
    mkdir /data

    # 挂载逻辑卷
    mount /dev/datavg/datalv /data

    # 更新 /etc/fstab
    echo "/dev/datavg/datalv   /data   ext4   defaults   0   0" >> /etc/fstab
done
