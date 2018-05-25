---
title: 使用solrj的API对solrCloud的完全操作
categories:
  - Java
date: 2017-12-24 17:01:41
tags:
---
## 测试样例说明

这里是使用solrJ提供的API对solrCloud的一些操作，主要是想避免对solrCloud服务器的直接配置，也省去了操作服务器的繁琐过程。

以下代码属于主要的API测试样例，其他API请自行参考，所有代码均可对solrCloud运行的服务器进行操作，所有测试方法本人已通过，测试结果可利用solrCloud的UI界面等查看。

solrCloud安装过程请参考{% post_link solr的环境搭建 solr的环境搭建 %}。

参考官方文档：{% link Using SolrJ http://lucene.apache.org/solr/guide/7_0/using-solrj.html#using-solrj %}

## 测试样例代码
<!-- more -->

### Collection的API
{% codeblock lang:java %}
package com.guojingfeng.solrj;

import org.apache.solr.client.solrj.SolrClient;
import org.apache.solr.client.solrj.SolrRequest;
import org.apache.solr.client.solrj.SolrServerException;
import org.apache.solr.client.solrj.impl.CloudSolrClient;
import org.apache.solr.client.solrj.request.CollectionAdminRequest;
import org.apache.solr.client.solrj.request.ConfigSetAdminRequest;
import org.apache.solr.common.util.NamedList;
import org.junit.Test;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.Properties;

/**
 * Created by guojingfeng on 2017/12/24.
 */
public class solrCloudAPI {
  String zkHostString = "192.168.147.191:2181"; // zookeeper服务地址，多个地址用','隔开
  SolrClient solrClient = new CloudSolrClient.Builder().withZkHost(zkHostString).build(); // 用于发起请求的客户端

  /**
   * 创建Collection
   * @throws IOException
   * @throws SolrServerException
   */
  @Test
  public void createCollection() throws IOException, SolrServerException {
    // 查看Collection列表
    List<String> list = CollectionAdminRequest.listCollections(solrClient);
    for (String s:list) {
      System.out.println(s);
    }

    // 确保创建的Collection名称不存在，否则会抛出异常
    String collName = "first_coll";

    // 以此方法创建的Collection默认使用_default的configset，分片数量和副本数量根据自己的情况而定
    SolrRequest solrRequest = CollectionAdminRequest.Create.createCollection(collName, 1, 3);
    NamedList<Object> request = solrClient.request(solrRequest);

    // 输出响应信息
    Map<String, Object> stringObjectMap = request.asShallowMap();
    for (String s: stringObjectMap.keySet()) {
      Object o = stringObjectMap.get(s);
      System.out.println(o);
    }
  }

  /**
   * 删除Collection
   * @throws IOException
   * @throws SolrServerException
   */
  @Test
  public void deleteCollection() throws IOException, SolrServerException {
    SolrRequest solrRequest = CollectionAdminRequest.deleteCollection("first_coll");
    solrClient.request(solrRequest);
  }
}
{% endcodeblock %}

### Schema API

{% codeblock lang:java %}
  /**
   * 查询Collection中的schema信息
   * @throws IOException
   * @throws SolrServerException
   */
  @Test
  public void querySchema() throws IOException, SolrServerException {
    // 获取first_coll中schema的信息
    SchemaRequest schemaRequest = new SchemaRequest();
    schemaRequest.process(solrClient, "first_coll");

    // 获取first_coll中schema的名称
    SchemaRequest.SchemaName schemaName = new SchemaRequest.SchemaName();
    schemaName.process(solrClient, "first_coll");

    // 获取first_coll中schema版本信息
    SchemaRequest.SchemaVersion schemaVersion = new SchemaRequest.SchemaVersion();
    schemaVersion.process(solrClient, "first_coll");
  }
{% endcodeblock %}

###  域的API

{% codeblock lang:java %}
  /**
   * 创建域信息
   * @throws IOException
   * @throws SolrServerException
   */
  @Test
  public void createField() throws IOException, SolrServerException {
    // 对schema添加域，假设在数据库中有id,name,age字段，solr的域要与数据库中的字段对应
    // id域默认已存在，省略之

    // 添加name域
    Map<String, Object> nameFieldAttributes = new HashMap<String, Object>();
    nameFieldAttributes.put("name", "name"); // 域名称
    nameFieldAttributes.put("type", "string"); // 域类型
    nameFieldAttributes.put("indexed", true); // 域是否可索引
    nameFieldAttributes.put("stored", true); // 域是否存储
    SchemaRequest.AddField addNameField = new SchemaRequest.AddField(nameFieldAttributes);
    // 添加age域
    Map<String, Object> ageFieldAttributes = new HashMap<String, Object>();
    ageFieldAttributes.put("name", "age"); // 域名称
    ageFieldAttributes.put("type", "pint"); // 域类型
    ageFieldAttributes.put("indexed", true); // 域是否可索引
    ageFieldAttributes.put("stored", true); // 域是否存储
    SchemaRequest.AddField addAgeField = new SchemaRequest.AddField(ageFieldAttributes);

    // 发起添加域请求
    addNameField.process(solrClient, "first_coll");
    addAgeField.process(solrClient, "first_coll");
  }

  /**
   * 删除域
   * @throws IOException
   * @throws SolrServerException
   */
  @Test
  public void deleteField() throws IOException, SolrServerException {
    SchemaRequest.DeleteField name = new SchemaRequest.DeleteField("name");
    name.process(solrClient, "first_coll");
  }

  /**
   * 查询跟域有关的信息
   * @throws IOException
   * @throws SolrServerException
   */
  @Test
  public void queryField() throws IOException, SolrServerException {
    // 获取first_coll中所有域类型
    SchemaRequest.FieldTypes fieldTypes = new SchemaRequest.FieldTypes();
    SchemaResponse.FieldTypesResponse fieldTypesResponse = fieldTypes.process(solrClient, "first_coll");

    Map<String, Object> map = fieldTypesResponse.getResponse().asShallowMap();
    for (String s : map.keySet()) {
      if (map.get(s) instanceof List) {
        for (Object o: (List)map.get(s)) {
          System.out.println(o);
        }
      }
    }

    // 获取first_coll当中所有域信息
    SchemaRequest.Fields fields = new SchemaRequest.Fields();
    SchemaResponse.FieldsResponse response = fields.process(solrClient, "first_coll");

    List<Map<String, Object>> list = response.getFields();
    for (Map<String, Object>  map2 : list) {
      System.out.println(map2);
    }
  }
{% endcodeblock %}

### 索引文档API

{% codeblock lang:java %}
  /**
   * 添加索引文档
   * @throws IOException
   * @throws SolrServerException
   */
  @Test
  public void saveDoc() throws IOException, SolrServerException {
    Map<String,SolrInputField> fieldMap = new HashMap<String, SolrInputField>();

    SolrInputField id = new SolrInputField("id");
    id.setValue("id_01");
    fieldMap.put("id", id);

    SolrInputField name = new SolrInputField("name");
    name.setValue("first_name");
    fieldMap.put("name", name);

    SolrInputField age = new SolrInputField("age");
    age.setValue(16);
    fieldMap.put("age", age);

    SolrInputDocument solrInputFields = new SolrInputDocument(fieldMap);

    UpdateResponse response = solrClient.add("first_coll", solrInputFields);
  }

  /**
   * 删除索引文档
   * @throws IOException
   * @throws SolrServerException
   */
  @Test
  public void deleteDoc() throws IOException, SolrServerException {
    UpdateResponse response = solrClient.deleteById("first_coll", "id_01");
  }
{% endcodeblock %}

### 未完待续...