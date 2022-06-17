# Elasticsearch

[toc]

## 1. Elasticsearch 介绍

Elasticsearch是一个分布式的搜索和分析引擎。

内容大纲：

1、聊一个人

2、货比三家

3、安装部署

4、生态圈

5、分词器 ik

6、RestFul操作ES

7、CRUD

8、SpringBoot集成ES（从原理分析）

9、爬虫爬取数据

10、实战、模拟全文检索

以后只要用到搜索，就可以使用ES（大数据的情况下使用）



### 1.1 聊聊Doug Cutting

1998年9月4日，Goolge公司在美国硅谷成立。正如大家所知，它是一家做搜索起家的公司。

无独有偶，一位名叫**Doug Cutting**的美国工程师，也迷上了搜索引擎。他做了一个用于文本搜索的函数库（姑且理解为软件的功能组件），命名为**Lucene**。

**Lucene**是用java写成的，目标是为各种中小型应用软件加入全文检索功能。因为好用而且开源，非常受程序员们的欢迎。

早期的时候，这个项目被发布在Doug Cutting的个人网站和SourceForge。后来，2001年底，Lucene成为Apache软件基金会jakarta项目的一个子项目。

2004年，Doug Cutting再接再厉，在Lucene的基础上和Apache开源伙伴Mike Cafarella合作，开发了一款可以代替当时的主流搜索的开源搜索引擎，命名为**Nutch**。

Nutch是一个建立在Lucene核心之上的网页搜索应用程序，可以下载下来直接使用。它在Lucene的基础上加了网络爬虫和一些网页相关的功能，目的就是从一个简单的站内检索推广到全球网络的搜索上，就像Google一样。

Nutch在业界的影响力比Lucene更大。