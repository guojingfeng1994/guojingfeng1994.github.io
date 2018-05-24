---
title: redis的环境搭建
categories:
  - Java
  - 服务器环境搭建
date: 2017-08-24 17:36:19
tags:
  - redis
---
## 系统环境检查

1. 编译需要GCC编译环境，Linux一般自带，可以不管
2. 集群搭建依赖于Ruby环境，因为要使用一个Ruby脚本对节点进行操作

## 下载

首先，进入官方{% link 下载 https://redis.io/download %}页面,下载redis-4.0.9.tar.gz。

## 安装

单节点的安装非常容易，解压以后再编译直接就可以使用了，不需要而外的配置。这里以集群安装为例。

集群建议最小节点数为3，然后各个节点一主一备，实际上最小是6个节点。

这里配置6台机器IP地址分别对应192.168.147.132，192.168.147.133，...，192.168.147.137，下面以其中一台机器的操作为例。
<!-- more -->

### 解压
{% codeblock lang:shell %}
cd ~
tar zxf redis-4.0.9.tar.gz -C app
{% endcodeblock %}

### 进入解压目录，编译

{% codeblock lang:shell %}
cd app/redis-4.0.9/ && make
{% endcodeblock %}

### 配置redis.conf

以下是节点最精简配置参考，这些配置默认是注释掉的，打开就行

**cluster-enabled:** 开启集群模式
**cluster-config-file:** 节点保存配置的文件名称，文件里保存着集群中各个节点的信息
**cluster-node-timeout:** 主节点超时时间，超过时间未响应会尝试对从属节点进行故障切换

{% codeblock lang:shell %}
cluster-enabled yes
cluster-config-file nodes-6379.conf
cluster-node-timeout 15000
{% endcodeblock %}

节点都配置好后，然后启动各个节点

{% codeblock lang:shell %}
src/redis-server ./redis.conf
{% endcodeblock %}

### 创建集群

节点启动后，就要使用redis-trib这个Ruby脚本创建集群了。

#### 安装Ruby环境
注意Ruby版本要2.2.2以上，用yum直接安装的话版本可能比较低，这里以rvm安装方式为例

1. 安装curl，如果没有的话
{% codeblock lang:shell %}
sudo yum install curl
{% endcodeblock %}

2. 安装RVM
{% codeblock lang:shell %}
curl -sSL https://get.rvm.io | bash -s stable
{% endcodeblock %}

看到最后有2句这样的提示说明成功
{% codeblock lang:shell %}
  * To start using RVM you need to run `source /home/hadoop/.rvm/scripts/rvm`
    in all your open shell windows, in rare cases you need to reopen all shell windows.
{% endcodeblock %}

根据提示执行脚本命令，这样就可以直接使用rvm命令了
{% codeblock lang:shell %}
source /home/hadoop/.rvm/scripts/rvm
{% endcodeblock %}

3. 查看可安装列表
{% codeblock lang:shell %}
rvm list known
{% endcodeblock %}

4. 选择安装版本（PS: 安装过程中可能会请求安装必要的环境，根据提示输入用户的密码执行安装）
{% codeblock lang:shell %}
rvm install ruby-2.4.1
{% endcodeblock %}

5. 查看安装列表，使用相应的版本
{% codeblock lang:shell %}
rvm list
rvm use 2.4.1
{% endcodeblock %}

6. 确认当前Ruby的使用版本
{% codeblock lang:shell %}
ruby -v
{% endcodeblock %}

#### 创建集群

1. 执行脚本
{% codeblock lang:shell %}
gem install redis
{% endcodeblock %}

2. 创建集群节点，并为每个节点分配1个副本，执行过程中发现问题1.
{% codeblock lang:shell %}
src/redis-trib.rb create --replicas 1 192.168.147.132:6379 192.168.147.133:6379 \
192.168.147.134:6379 192.168.147.135:6379 \
192.168.147.136:6379 192.168.147.137:6379
{% endcodeblock %}

### 运行测试

在其中一台机器执行，注意后面的-c参数为集群模式运行
{% codeblock lang:shell %}
src/redis-cli -h 192.168.147.137 -p 6379 -c
{% endcodeblock %}

#### 测试存储
设置key
{% codeblock lang:shell %}
set clusterTest success
{% endcodeblock %}

获取key
{% codeblock lang:shell %}
get clusterTest
{% endcodeblock %}

成功打印"success"，至此，redis集群搭建完毕。

#### 测试主备切换

获取当前节点信息
{% codeblock lang:shell %}
192.168.147.134:6379> cluster nodes
a06ea3a896ff01433b2056127f0b57324378d690 192.168.147.137:6379@16379 slave 81033cfa14f7c5b369d623075f8e0c93dbaa02b6 0 1527167571745 6 connected
c091fe55d45a3ec444070012ecfb41a8bcb304b5 192.168.147.134:6379@16379 myself,master - 0 1527167566000 3 connected 10923-16383
770816d355ecf6b3239fdbbf859ab8239faa06b1 192.168.147.132:6379@16379 master - 0 1527167569726 1 connected 0-5460
81033cfa14f7c5b369d623075f8e0c93dbaa02b6 192.168.147.133:6379@16379 master - 0 1527167568713 2 connected 5461-10922
8ea2b987e230d088a2f8ec887571d31b731293d1 192.168.147.135:6379@16379 slave c091fe55d45a3ec444070012ecfb41a8bcb304b5 0 1527167570735 4 connected
cc55b7daf14ce4922b077fdc3fc35523bf9d0f92 192.168.147.136:6379@16379 slave 770816d355ecf6b3239fdbbf859ab8239faa06b1 0 1527167569000 5 connected
{% endcodeblock %}

以192.168.147.132这台机器为例，使用kill命令杀掉一个master节点，然后过一段时间再使用cluster nodes观察情况，发现192.168.147.136这台机器成功切换成master。
{% codeblock %}
192.168.147.134:6379> cluster nodes
a06ea3a896ff01433b2056127f0b57324378d690 192.168.147.137:6379@16379 slave 81033cfa14f7c5b369d623075f8e0c93dbaa02b6 0 1527167785054 6 connected
c091fe55d45a3ec444070012ecfb41a8bcb304b5 192.168.147.134:6379@16379 myself,master - 0 1527167783000 3 connected 10923-16383
770816d355ecf6b3239fdbbf859ab8239faa06b1 192.168.147.132:6379@16379 master,fail - 1527167759596 1527167757566 1 disconnected
81033cfa14f7c5b369d623075f8e0c93dbaa02b6 192.168.147.133:6379@16379 master - 0 1527167784032 2 connected 5461-10922
8ea2b987e230d088a2f8ec887571d31b731293d1 192.168.147.135:6379@16379 slave c091fe55d45a3ec444070012ecfb41a8bcb304b5 0 1527167786071 4 connected
cc55b7daf14ce4922b077fdc3fc35523bf9d0f92 192.168.147.136:6379@16379 master - 0 1527167787094 7 connected 0-5460
{% endcodeblock %}

## 后台模式配置

先前的配置都是以前台模式启动进程，占用窗口，现在配置redis.conf文件设置成后台模式启动

搜索daemonize

将daemonize no那一行改为daemonize yes

OK，再启动就是后台模式了
{% codeblock lang:shell %}
src/redis-server ./redis.conf
{% endcodeblock %}

## 搭建时遇到的问题

### 问题1

创建集群时，发现连接不上已启动的节点
{% codeblock lang:shell %}
src/redis-trib.rb create --replicas 1 192.168.147.132:6379 192.168.147.133:6379 \
192.168.147.134:6379 192.168.147.135:6379 192.168.147.136:6379 192.168.147.137:6379

{% raw %}>>>{% endraw %} Creating cluster
[ERR] Sorry, can't connect to node 192.168.147.132:6379
{% endcodeblock %}

查其原因，是redis.conf文件中IP绑定了127.0.0.1，我们把它改成主机的公路IP

找到类似行配置
{% codeblock lang:shell %}
# IF YOU ARE SURE YOU WANT YOUR INSTANCE TO LISTEN TO ALL THE INTERFACES
# JUST COMMENT THE FOLLOWING LINE.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
bind 127.0.0.1
{% endcodeblock %}

更改bind中的当前机器IP，如192.168.147.132
{% codeblock lang:shell %}
bind 192.168.147.132
{% endcodeblock %}

所有节点配置好后，就可以使用节点创建集群了。











