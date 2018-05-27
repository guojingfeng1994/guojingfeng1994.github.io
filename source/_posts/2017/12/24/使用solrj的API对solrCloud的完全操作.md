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

附加供测试的sql,[tb_item.sql](tb_item.sql)

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
    // 对schema添加域，假设在数据库中有id,title,price字段，solr的域要与数据库中的字段对应
    // 由于first_coll使用了_default的配置,id域默认已存在，省略之

    // 添加title域
    Map<String, Object> titleFieldAttributes = new HashMap<String, Object>();
    titleFieldAttributes.put("name", "title"); // 域名称
//    titleFieldAttributes.put("type", "string"); // 域类型
    titleFieldAttributes.put("type", "text_cn"); // 支持中文分词的域类型，使用前需要先定义该域类型
    titleFieldAttributes.put("indexed", true); // 域是否可索引
    titleFieldAttributes.put("stored", true); // 域是否存储
    SchemaRequest.AddField addTitleField = new SchemaRequest.AddField(titleFieldAttributes);
    // 添加price域
    Map<String, Object> priceFieldAttributes = new HashMap<String, Object>();
    priceFieldAttributes.put("name", "price"); // 域名称
    priceFieldAttributes.put("type", "pint"); // 域类型
    priceFieldAttributes.put("indexed", true); // 域是否可索引
    priceFieldAttributes.put("stored", true); // 域是否存储
    SchemaRequest.AddField addPriceField = new SchemaRequest.AddField(priceFieldAttributes);

    // 发起添加域请求
    addTitleField.process(solrClient, "first_coll");
    addPriceField.process(solrClient, "first_coll");
  }

  /**
   * 删除域
   * @throws IOException
   * @throws SolrServerException
   */
  @Test
  public void deleteField() throws IOException, SolrServerException {
    SchemaRequest.DeleteField name = new SchemaRequest.DeleteField("title");
    name.process(solrClient, "first_coll");
  }

  /**
   * 查询域信息
   * @throws IOException
   * @throws SolrServerException
   */
  @Test
  public void queryField() throws IOException, SolrServerException {
    // 获取first_coll当中所有域信息
    SchemaRequest.Fields fields = new SchemaRequest.Fields();
    SchemaResponse.FieldsResponse response = fields.process(solrClient, "first_coll");

    List<Map<String, Object>> list = response.getFields();
    for (Map<String, Object>  map : list) {
      System.out.println(map);
    }
  }
{% endcodeblock %}

### 域类型API

{% codeblock lang:java %}
  /**
   * 创建一个域类型，并添加中文分词器
   * @throws IOException
   * @throws SolrServerException
   */
  @Test
  public void createFieldType() throws IOException, SolrServerException {
    // 分词器定义
    AnalyzerDefinition ad = new AnalyzerDefinition();
    Map<String, Object> adTokenizer = new HashMap<String, Object>();
    List<Map<String, Object>> adFilterList = new ArrayList<Map<String, Object>>();
    Map<String, Object> adFilterMap;

    adTokenizer.put("class", "solr.HMMChineseTokenizerFactory");

    String[] adFilterArr = {"solr.CJKWidthFilterFactory", "solr.StopFilterFactory", "solr.PorterStemFilterFactory", "solr.LowerCaseFilterFactory"};
    for (String s : adFilterArr) {
      adFilterMap = new HashMap<String, Object>();
      adFilterMap.put("class", s);
      if ("solr.StopFilterFactory".equals(s))
        adFilterMap.put("words", "org/apache/lucene/analysis/cn/smart/stopwords.txt");
      adFilterList.add(adFilterMap);
    }

    ad.setTokenizer(adTokenizer);
    ad.setFilters(adFilterList);

    // 域类型定义
    FieldTypeDefinition ftd = new FieldTypeDefinition();
    Map<String, Object> ftdAttr = new HashMap<String, Object>();

    ftdAttr.put("name", "text_cn");
    ftdAttr.put("class", "solr.TextField");

    ftd.setAttributes(ftdAttr);
    ftd.setAnalyzer(ad); // 为域类型添加分词器

    SchemaRequest.AddFieldType addFieldType = new SchemaRequest.AddFieldType(ftd);
    addFieldType.process(solrClient, "first_coll");
  }

  /**
   * 查询域类型
   * @throws IOException
   * @throws SolrServerException
   */
  @Test
  public void queryFieldType() throws IOException, SolrServerException {
    // 获取first_coll中所有域类型，通过域类型可以定义分词器
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
  }
{% endcodeblock %}

### 索引的API

{% codeblock lang:java %}
  /**
   * 添加索引文档，更新只要设置相同主键就可以就是覆盖更新
   * @throws IOException
   * @throws SolrServerException
   */
  @Test
  public void saveDoc() throws IOException, SolrServerException {
    Map<String,SolrInputField> fieldMap = new HashMap<String, SolrInputField>();

    SolrInputField id = new SolrInputField("id");
    id.setValue("536563");
    fieldMap.put("id", id);

    SolrInputField title = new SolrInputField("title");
    title.setValue("new2 - 阿尔卡特 (OT-927) 炭黑 联通3G手机 双卡双待");
    fieldMap.put("title", title);

    SolrInputField price = new SolrInputField("price");
    price.setValue(29900000); // 单位：分
    fieldMap.put("price", price);

    SolrInputDocument solrInputFields = new SolrInputDocument(fieldMap);

    solrClient.add("first_coll", solrInputFields);
    solrClient.commit("first_coll");
  }

  /**
   * 删除索引文档
   * @throws IOException
   * @throws SolrServerException
   */
  @Test
  public void deleteDoc() throws IOException, SolrServerException {
    solrClient.deleteById("first_coll", "536563");
    solrClient.commit("first_coll");
  }

  /**
   * 查询索引
   * @throws IOException
   * @throws SolrServerException
   */
  @Test
  public void queryDoc() throws IOException, SolrServerException {
    HashMap<String, String> map = new HashMap<>();
    // 要查询的域中的索引
    map.put("q", "title:手机");
    // 根据域排序排序
    map.put("sort", "id desc");
    // 分页查询
    map.put("start", "0");
    map.put("row", "10");
    // 响应格式
    map.put("wt", "json");
    // ...所有参数参见官方文档中搜索一章

    SolrParams solrParams = new MapSolrParams(map);
    QueryRequest queryRequest = new QueryRequest(solrParams);

    QueryResponse response = queryRequest.process(solrClient, "first_coll");
    List<Object> list = (List<Object>) response.getResponse().asShallowMap().get("response");
    for (Object o : list) {
      System.out.println(o);
    }
  }
{% endcodeblock %}

### SolrZkClient的API

{% codeblock lang:java %}
  /**
   * 对zookeeper中的配置文件进行上传和下载
   * @throws IOException
   * @throws SolrServerException
   */
  @Test
  public void updateSolrConfig() throws IOException, SolrServerException {
    // 对于一些无法使用REST API修改的配置，需要从zookeeper中把配置下载下来手动更改，再上传
    SolrZkClient solrZkClient = new SolrZkClient(zkHostString, 30000);
    String localPath = "D:\\web\\configs\\solrconfig.xml";
    String zkPath = "/configs/first_coll/solrconfig.xml";

    Path path = FileSystems.getDefault().getPath(localPath);
    solrZkClient.downloadFromZK(zkPath, path);

    // 可以直接操作xml修改，懒得写了，手动修改过程同样略
    // 添加中文分词器的语句
    //    <lib dir="${solr.install.dir:../../../..}/contrib/analysis-extras/lucene-libs" regex="lucene-analyzers-smartcn-.\..\..\.jar" />

    // 修改完成后上传修改的配置文件，修改配置文件后需要重新加载配置才能生效

//    String configName = "first_coll/solrconfig.xml";
    // 更新配置方法1
//    ZkConfigManager zkConfigManager = new ZkConfigManager(solrZkClient);
//    zkConfigManager.uploadConfigDir(path, configName);
    // 更新配置方法2
//    solrZkClient.upConfig(path, configName);
    
    solrZkClient.close();
  }
{% endcodeblock %}

### 将来...