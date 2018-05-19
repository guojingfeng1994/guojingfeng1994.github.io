---
title: solr的集群环境搭建
categories: 
  - java
  - 服务器环境搭建
date: 2017-12-19 20:13:37
tags:
  - Solr
  - SolrCloud
---
## 系统环境检查
根据Solr的官方说明，从Solr 6（包括SolrJ客户端库）开始，Java支持版本最低为Java 8。

这里以Solr7.0.1版本作为示例。

## 下载
首先，{% link 进入下载页面 http://archive.apache.org/dist/lucene/solr/ %},找到solr-7.0.1.tgz。

## 安装
进入下载的文件夹，解压到app目录下
{% codeblock lang:shell %}
cd ~
tar zxf solr-7.0.1.tgz -C app
{% endcodeblock %}
<!-- more -->

## 单机版运行模式
进入到解压目录
{% codeblock lang:shell %}
cd app/solr-7.0.1/
{% endcodeblock %}

运行
{% codeblock lang:shell %}
bin/solr start
{% endcodeblock %}

打开浏览器，访问{% raw %}http://192.168.147.191:8983/solr{% endraw %}（注意更换IP）
看到如下画面，单机版完成，然后重复安装多2台机器。

{% asset_img 'QQ图片20180519215719.png' %}


## SolrCloud运行模式

在使用前，必须有一个ZooKeeper服务器，并且已启动服务，安装过程参考。

停止刚才运行的单机实例(如果有启动)
{% codeblock lang:shell %}
bin/solr stop
{% endcodeblock %}

以SolrCloud模式运行Solr实例，-could指定启动方式，-z 后面指定ZooKeeper服务器地址
{% codeblock lang:shell %}
bin/solr start -cloud -z 192.168.147.191:2181
{% endcodeblock %}

打开浏览器，访问任意节点http地址（如{% raw %}http://192.168.147.191:8983/solr{% endraw %}），此时菜单会多出个cloud选项,但目前右边还看不到有其他节点。

{% asset_img 'QQ图片20180519222340.png' %}

以SolrCloud运行模式再启动其他2台机器,能够访问到对应http地址说明启动成功。

创建一个Collections ，Collections 名称随便，config set使用默认就好，numShards分片数量默认，replicationFactor分片副本数量定义为3（为了看到集群状态，定义为我配置的机器节点数量）
{% asset_img 'QQ图片20180519233743.png' %}

然后可以在cloud的graph中看到以下画面，说明SolrCloud搭建完成。
{% asset_img 'QQ图片20180519234500.png' %}

## 搭建时遇到的问题
暂无。





