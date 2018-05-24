---
title: hadoop的环境搭建
categories:
  - Java
  - 服务器环境搭建
date: 2017-11-12 19:19:23
tags:
  - hadoop
---
## 系统环境检查

1. hadoop2.7之后需要Java 7以上的支持
2. hadoop的HA机制依赖于ZooKeeper，安装请参考{% post_link zookeeper的环境搭建 zookeeper的环境搭建 %}
3. ssh环境，用于运行sshd远程管理Hadoop守护程序。（无密登录这里早已配好，这里不再赘述）。

## 下载
{% link 进入下载页面 http://hadoop.apache.org/releases.html %},下载最新版本，这里使用的是hadoop-2.8.3.tar.gz。

进入下载目录，解压到app目录下
{% codeblock lang:shell %}
cd ~
tar zxf hadoop-2.8.3.tar.gz -C app
{% endcodeblock %}
<!-- more -->

## 单机模式安装

### 配置

在配置前最好把HADOOP_HOME，方便命令的执行。
{% codeblock lang:shell %}
...
done

unset i
unset -f pathmunge
export JAVA_HOME=/home/hadoop/app/jdk1.7.0_65
export HADOOP_HOME=/home/hadoop/app/hadoop-2.8.3
export PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
{% endcodeblock %}

进入hadoop配置文件目录
{% codeblock lang:shell %}
cd app/hadoop-2.8.3/etc/hadoop/
{% endcodeblock %}

先编辑hadoop-env.sh，修改默认的JAVA_HOME为JDK安装的绝对路径，不然后面可能会报JAVA_HOME not found之类的。
{% codeblock lang:shell %}
export JAVA_HOME=/home/hadoop/app/jdk1.7.0_65
{% endcodeblock %}

用vi编辑core-site.xml，这个是hdfs文件系统服务器地址，在configuration中配置属性，如下所示
{% codeblock lang:shell %}
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>
{% endcodeblock %}

编辑hdfs-site.xml，配置副本数量，一个节点也只有1个副本了
{% codeblock lang:shell %}
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
</configuration>
{% endcodeblock %}

配置mapred-site.xml，用于mapreduce计算，只用hdfs的话，上面的配置已经可以启动了

默认这个文件是没有的，直接从模板复制过来
{% codeblock lang:shell %}
cp mapred-site.xml.template mapred-site.xml
{% endcodeblock %}

编辑mapred-site.xml
{% codeblock lang:shell %}
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
</configuration>
{% endcodeblock %}

配置yarn-site.xml，yarn资源调度器
{% codeblock lang:shell %}
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
</configuration>
{% endcodeblock %}


### 运行测试

进入hadoop安装目录，使用前先格式化namenode
{% codeblock lang:shell %}
bin/hdfs namenode -format
{% endcodeblock %}

启动hdfs
{% codeblock lang:shell %}
sbin/start-dfs.sh
{% endcodeblock %}

启动yarn
{% codeblock lang:shell %}
sbin/start-yarn.sh
{% endcodeblock %}

浏览器访问一下namenode访问地址，{% raw %}http://192.168.147.131:50070/{% endraw %},能访问成功说明hdfs已经安装上了。

mapreduce这里不测了，等下测试集群版。

## 集群安装

### 安装说明

这里使用7台虚拟机配置，IP192.168.147.131、192.168.147.132...192.168.147.137对应的host主机名称为weekend01、weekend02...weekend07.

01、02为namenode节点、03、04为yarn的ResourceManager节点、05、06、07为DataNode节点、JournalNode节点、nodemanager节点以及zookeeper集群。下面以一台机器的配置为例。

### 配置

我直接改造单机版配置了（清空再重新配置），另外，hadoop的HA机制依赖于zookeeper，zookeeper安装过程参考{% post_link zookeeper的环境搭建 zookeeper的环境搭建 %}

进入hadoop的配置文件目录。

#### 配置HDFS
编辑hdfs-site.xml，副本数量改为3，再配置一对namenode服务的集群名称
{% codeblock lang:shell %}
<property>
  <name>dfs.replication</name>
  <value>3</value>
</property>
<property>
  <name>dfs.nameservices</name>
  <value>mycluster</value>
</property>
{% endcodeblock %}

配置集群中包含的namenode节点名称别名
{% codeblock lang:shell %}
<property>
  <name>dfs.ha.namenodes.mycluster</name>
  <value>nn1,nn2</value>
</property>
{% endcodeblock %}

配置namonode别名对应的IP（主机）地址和端口，用于RPC通信
{% codeblock lang:shell %}
<property>
  <name>dfs.namenode.rpc-address.mycluster.nn1</name>
  <value>weekend01:9000</value>
</property>
<property>
  <name>dfs.namenode.rpc-address.mycluster.nn2</name>
  <value>weekend02:9000</value>
</property>
{% endcodeblock %}

配置namonode别名对应的IP地址和端口，用于http端口访问
{% codeblock lang:shell %}
<property>
  <name>dfs.namenode.http-address.mycluster.nn1</name>
  <value>weekend01:50070</value>
</property>
<property>
  <name>dfs.namenode.http-address.mycluster.nn2</name>
  <value>weekend02:50070</value>
</property>
{% endcodeblock %}

JournalNode节点存放的位置，edits文件是namenode的读写日志，单机版一个namenode对应一个edit文件，namenode的HA机制就是剥离edits文件共享给所有namenode，实现数据同步。
{% codeblock lang:shell %}
<property>
  <name>dfs.namenode.shared.edits.dir</name>
  <value>qjournal://weekend05:8485;weekend06:8485;weekend07:8485/mycluster</value>
</property>
{% endcodeblock %}

配置namenode的自动切换模式
{% codeblock lang:shell %}
<property>
  <name>dfs.client.failover.proxy.provider.mycluster</name>
  <value>org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider</value>
</property>
 <property>
   <name>dfs.ha.automatic-failover.enabled</name>
   <value>true</value>
 </property>
{% endcodeblock %}

配置fencing机制，主要是用于namenode切换过程中，如果active的namenode在心跳机制中超时未响应，standby的namenode就会进行自动激活（切换active状态），保证高可用。

原理是先通过ssh发送一条kill的指令，保证原先的active状态是真的死了（因为有可能是网络状态不好引起的假死状态），如果当kill指令也没有返回状态的时候，也会执行一条自定义的切换脚本（这里我直接用shell(/bin/true)，表示不做其他事情）
{% codeblock lang:shell %}
<property>
      <name>dfs.ha.fencing.methods</name>
      <value>sshfence</value>
    </property>
    <property>
      <name>dfs.ha.fencing.ssh.private-key-files</name>
      <value>/home/hadoop/.ssh/id_rsa</value>
    </property>
    <property>
      <name>dfs.ha.fencing.methods</name>
      <value>
        sshfence
        shell(/bin/true)
      </value>
    </property>
    <property>
      <name>dfs.ha.fencing.ssh.connect-timeout</name>
      <value>30000</value>
    </property>
{% endcodeblock %}

编辑core-site.xml，配置hdfs默认文件系统服务器、hadoop临时文件目录、journalnode存放目录、zookeeper服务器地址
{% codeblock lang:shell %}
<property>
  <name>fs.defaultFS</name>
  <value>hdfs://mycluster</value>
</property>
<property>
  <name>hadoop.tmp.dir</name>
  <value>/home/hadoop/app/hadoop-2.8.3/data/</value>
</property>
<property>
  <name>dfs.journalnode.edits.dir</name>
  <value>/home/hadoop/app/hadoop-2.8.3/journaldata</value>
</property>
 <property>
   <name>ha.zookeeper.quorum</name>
   <value>weekend05:2181,weekend06:2181,weekend07:2181</value>
 </property>
{% endcodeblock %}

#### 配置YARN

下面是yarn-site.xml最简洁的配置
{% codeblock lang:shell %}
<property>
  <name>yarn.resourcemanager.ha.enabled</name>
  <value>true</value>
</property>
<property>
   <name>yarn.resourcemanager.cluster-id</name>
   <value>cluster1</value>
</property>
<property>
   <name>yarn.resourcemanager.ha.rm-ids</name>
   <value>rm1,rm2</value>
</property>
<property>
   <name>yarn.resourcemanager.hostname.rm1</name>
   <value>weekend03</value>
</property>
<property>
   <name>yarn.resourcemanager.hostname.rm2</name>
   <value>weekend04</value>
</property>
<property>
   <name>yarn.resourcemanager.webapp.address.rm1</name>
   <value>weekend03:8088</value>
</property>
<property>
   <name>yarn.resourcemanager.webapp.address.rm2</name>
   <value>weekend04:8088</value>
</property>
<property>
   <name>yarn.resourcemanager.zk-address</name>
   <value>weekend05:2181,weekend06:2181,weekend07:2181</value>
</property>
<property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
</property>
{% endcodeblock %}

编辑mapred-site.xml，和单机版一样，基本不用变
{% codeblock lang:shell %}
<property>
	<name>mapreduce.framework.name</name>
	<value>yarn</value>
</property>
{% endcodeblock %}

#### 修改slaves
slaves是指定子节点的位置，因为要在weekend01上启动namenode、在weekend03启动yarn，所以weekend01、weekend02上的slaves文件指定的是datanode的位置，weekend03、weekend04上的slaves文件指定的是nodemanager的位置

**注意**这里的DataNode节点以及nodemanager都配置在了一起，所以这个slaves文件在这里对于weekend01、02、03、04都是一样的，可以通用

{% codeblock lang:shell %}
weekend05
weekend06
weekend07
{% endcodeblock %}

以上配置，集群所有节点通用，也可以把配好的这台机器上的hadoop安装目录整个拷贝过去其他的机器

进入app目录，执行复制命令，以复制到weekend02为例（建议先删除doc文件，在share目录下，不然那等待时间有你受的）
{% codeblock lang:shell %}
scp -r hadoop-2.8.3/ weekend02://home/hadoop/app/
{% endcodeblock %}

### 运行测试

weekend01上执行下面命令

在ZooKeeper中初始化HA状态，请先保证zookeeper已经正常启动
{% codeblock lang:shell %}
bin/hdfs zkfc -formatZK
{% endcodeblock %}

启动HDFS，第一次执行的时候，出现了下面的问题1，问题描述及解决请看最后，解决后可以看到namenode已经启动
{% codeblock lang:shell %}
sbin/hadoop-daemon.sh start namenode
{% endcodeblock %}

在对weekend01的namenode进行格式化后，在weekend02执行同步命令并进入standby模式，然后再启动namenode进程，HA启动就完成了。
{% codeblock lang:shell %}
hdfs namenode -bootstrapStandby
sbin/hadoop-daemon.sh start namenode
{% endcodeblock %}

如果要测试namenode能否自动切换，把active节点kill掉，正常情况下等待一定时间，原先standby的机器就会变成active，kill掉的再启动，会变成standby状态。

启动浏览器访问namenode地址，如：{% raw %}http://192.168.147.131:50070{% endraw %}，发现问题2，2个nnamenode都处于standby状态。

接下来启动weekend03、04上的ResourceManager，访问任意其中一台地址，如：{% raw %}http://192.168.147.133:8088{% endraw %}，看到页面，说明启动成功。
{% codeblock lang:shell %}
sbin/yarn-daemon.sh start resourcemanager
{% endcodeblock %}

接下来启动weekend05、06、07上的nodemanager节点
{% codeblock lang:shell %}
sbin/yarn-daemon.sh start nodemanager
{% endcodeblock %}

启动完成后，写一个测试文件用于测试HDFS和mapreduce，文件内容大致如下：
{% codeblock lang:shell %}
hello tom
hello jerry
hello baby
i love you baby
{% endcodeblock %}

生成文件上传到hdfs目录,这里上传到新建文件夹/wordcount/input下，可以在namenode管理界面看到已经上传成功，hdfs没问题。
{% codeblock lang:shell %}
hadoop fs -mkdir /wordcount
hadoop fs -mkdir /wordcount/input
hadoop fs -put word.txt /wordcount/input
{% endcodeblock %}

接下里测试mapreduce
进入到hadoop提供的mapreduce例子目录/home/hadoop/app/hadoop-2.8.3/share/hadoop/mapreduce，执行
{% codeblock lang:shell %}
hadoop jar hadoop-mapreduce-examples-2.8.3.jar wordcount /wordcount/input /wordcount/output
{% endcodeblock %}

运行完后会自动生成一个输出文件夹，看下计算结果。
{% codeblock lang:shell %}
hadoop fs -ls /wordcount/output
hadoop fs -cat /wordcount/output/part-r-00000
{% endcodeblock %}

得到：
{% codeblock lang:shell %}
baby    2
hello   3
i       1
jerry   1
love    1
tom     1
you     1
{% endcodeblock %}

OK，至此，hadoop的HA集群搭建完毕，边搭边写可能有点乱，在此只是做一个记录，方便下次安装，所以就将就下吧。

## 遇到的问题

### 问题1

执行sbin/start-dfs.sh命令后，使用jps查看，发现namenode并没有启动，其他机器上也没有任何进程启动
   
{% codeblock lang:shell %}
[hadoop@weekend01 hadoop-2.8.3]$ jps
2904 Jps
{% endcodeblock %}

#### 日志

进入logs目录，查看日志
{% codeblock lang:shell %}
less hadoop-hadoop-namenode-weekend01.log
{% endcodeblock %}

翻阅查看注意到提示，没有对namenode进行格式化
{% codeblock lang:shell %}
2017-11-12 22:26:54,111 INFO org.mortbay.log: Stopped HttpServer2$SelectChannelConnectorWithSafeStartup@weekend01:50070
2017-11-12 22:26:54,111 WARN org.apache.hadoop.http.HttpServer2: HttpServer Acceptor: isRunning is false. Rechecking.
2017-11-12 22:26:54,111 WARN org.apache.hadoop.http.HttpServer2: HttpServer Acceptor: isRunning is false
2017-11-12 22:26:54,114 INFO org.apache.hadoop.metrics2.impl.MetricsSystemImpl: Stopping NameNode metrics system...
2017-11-12 22:26:54,115 INFO org.apache.hadoop.metrics2.impl.MetricsSystemImpl: NameNode metrics system stopped.
2017-11-12 22:26:54,115 INFO org.apache.hadoop.metrics2.impl.MetricsSystemImpl: NameNode metrics system shutdown complete.
2017-11-12 22:26:54,115 ERROR org.apache.hadoop.hdfs.server.namenode.NameNode: Failed to start namenode.
org.apache.hadoop.hdfs.server.common.InconsistentFSStateException: Directory /home/hadoop/app/hadoop-2.8.3/data/dfs/name is in an inconsistent state: storage directory does not exist or is not accessible.
        at org.apache.hadoop.hdfs.server.namenode.FSImage.recoverStorageDirs(FSImage.java:369)
        at org.apache.hadoop.hdfs.server.namenode.FSImage.recoverTransitionRead(FSImage.java:220)
        at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.loadFSImage(FSNamesystem.java:1044)
        at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.loadFromDisk(FSNamesystem.java:707)
        at org.apache.hadoop.hdfs.server.namenode.NameNode.loadNamesystem(NameNode.java:635)
        at org.apache.hadoop.hdfs.server.namenode.NameNode.initialize(NameNode.java:696)
        at org.apache.hadoop.hdfs.server.namenode.NameNode.<init>(NameNode.java:906)
        at org.apache.hadoop.hdfs.server.namenode.NameNode.<init>(NameNode.java:885)
        at org.apache.hadoop.hdfs.server.namenode.NameNode.createNameNode(NameNode.java:1626)
        at org.apache.hadoop.hdfs.server.namenode.NameNode.main(NameNode.java:1694)
2017-11-12 22:26:54,117 INFO org.apache.hadoop.util.ExitUtil: Exiting with status 1
2017-11-12 22:26:54,136 INFO org.apache.hadoop.hdfs.server.namenode.NameNode: SHUTDOWN_MSG: 
/************************************************************
SHUTDOWN_MSG: Shutting down NameNode at weekend01/192.168.147.131
************************************************************/
{% endcodeblock %}

#### 解决

要解决问题1，执行一次namenode的格式化

在格式化之前，先启动所有journalnode节点上的journalnode进程，不然会出现连接不上的错误而无法格式化

{% codeblock lang:shell %}
sbin/hadoop-daemon.sh start journalnode
{% endcodeblock %}

执行对namenode的格式化
{% codeblock lang:shell %}
hdfs namenode -format
{% endcodeblock %}

### 问题2
2个nnamenode都处于standby状态

#### 解决
启动namonode前先启动zkfc就行了
{% codeblock lang:shell %}
sbin/hadoop-daemon.sh start zkfc
{% endcodeblock %}