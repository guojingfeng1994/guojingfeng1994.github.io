---
title: zookeeper的环境搭建
categories:
  - Java
  - 服务器环境搭建
date: 2017-11-12 11:12:09
tags:
  - zookeeper
  - zookeeper集群
---
## 系统环境检查
1. zookeeper依赖的JDK要高于1.6版本。
2. 集群模式至少要3个节点，原因与选举机制有关，2个节点无法实现高可用，不如单机

## 下载
{% link 进入下载页面 http://zookeeper.apache.org/releases.html#download %},下载最新版本，这里使用的是zookeeper-3.4.5.tar.gz。

## 安装
安装过程非常简单，进入下载的文件夹，解压到app目录下
{% codeblock lang:shell %}
cd ~
tar zxf zookeeper-3.4.5.tar.gz -C app
{% endcodeblock %}

## 配置
单机版的配置非常简单，只需要配置一个dataDir就可以了，这里以集群配置为例。

<!-- more --> 
 进入配置文件目录
{% codeblock lang:shell %}
 cd app/zookeeper-3.4.5/conf
{% endcodeblock %}
 
 默认里面是没有zoo.cfg配置文件的，但是提供了一个模板文件zoo_sample.cfg，直接复制就行了。
 {% codeblock lang:shell %}
 cp zoo_sample.cfg zoo.cfg
 {% endcodeblock %}
 
 使用vi编辑zoo.cfg内容
 首先配置dataDir，这个是数据存放目录，我把它放在安装目录的data目录下，这个目录一会还有用，可以手动先创建。
{% codeblock lang:shell %}
dataDir=/home/hadoop/app/zookeeper-3.4.5/data
{% endcodeblock %}

然后在最后面添加下面服务节点的地址。

这里server.1，server.2，server.3，后面的数字代表服务器ID，后面要把ID配置进myid文件。

zk1,zk2,zk3表示的是zookeeper服务器地址的主机名称，这里我已经把IP写入我本机的host里面了，所以这里我用主机名代替IP地址了。端口不用管，用默认的就行。

{% codeblock lang:shell %}
server.1 = zk1:2888:3888
server.2 = zk2:2888:3888
server.3 = zk3:2888:3888
{% endcodeblock %}
 
 配置好后，把配置好的zoo.cfg文件复制到其它2台机器对应目录下。
 
 最后，也是最重要的，为每个zookeeper节点配置一个ID，每一台机器都需要，因为server.id不一样。
 
 进入到zookeeper安装目录，创建data数据文件目录并且进入该目录
{% codeblock lang:shell %}
mkdir data && cd data
{% endcodeblock %}

执行下面的命令

{% codeblock lang:shell %}
echo 1 > myid
{% endcodeblock %}

_**注意**：1代表的是刚才配置的zookeeper节点对应的ID，比如zk1对应的server.1中的ID就是1，相应的zk2就是2，以此类推。myid是输出文件的名称，这个名称是固定的。_

## 运行

配置好各个服务器上的myid后，进入到各个服务器的zookeeper安装目录，执行
{% codeblock lang:shell %}
bin/zkServer.sh start
{% endcodeblock %}

查看当前机器状态,如果所有机器以及启动成功，其中一台机器将会显示为Mode: leader，另外的机器将会显示Mode: follower。
{% codeblock lang:shell %}
bin/zkServer.sh status
{% endcodeblock %}

至此，zookeeper集群安装完毕。
 
## 遇到的问题
暂无。