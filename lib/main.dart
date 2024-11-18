import 'dart:ffi';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as Html;
import 'package:html/parser.dart'  as Html;
import 'package:path_provider/path_provider.dart';

import 'message_utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '动漫花园小工具',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Convert Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey _formKey = GlobalKey<FormState>();
  String _httpProxy = "";
  String _namePrefix = "links-";
  int _singleFileLinkCounts = 50;
  int _maxLinkCounts = 1000;
  String _url = "";
  bool _isConverting = false;
  bool _isFetching = false;
  int _total = 0;
  int _current = 0;
  int _reqProgress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: kToolbarHeight), // 距离顶部一个工具栏的高度
            TextFormField(
              initialValue: _httpProxy,
              decoration: const InputDecoration(labelText: 'HTTP代理，例子：http://127.0.0.1:7899'),
              onSaved: (v) => _httpProxy = v!,
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: _namePrefix,
              decoration: const InputDecoration(labelText: '输出文件名前缀'),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return '请输入输出文件名前缀';
                }
                return null;
              },
              onSaved: (v) => _namePrefix = v!,
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: _maxLinkCounts.toString(),
              decoration: const InputDecoration(labelText: '最大提取的链接数量'),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return '请输入最大提取的链接数量';
                }
                return null;
              },
              onSaved: (v) => _maxLinkCounts = int.parse(v!),
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: _singleFileLinkCounts.toString(),
              decoration: const InputDecoration(labelText: '单个文件的链接数量'),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return '请输入输出单个文件的链接数量';
                }
                return null;
              },
              onSaved: (v) => _singleFileLinkCounts = int.parse(v!),
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: _url,
              decoration: const InputDecoration(labelText: '动漫花园Url'),
              // maxLines: 2,
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return '请输入动漫花园Url';
                }
                return null;
              },
              onSaved: (v) => _url = v!,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ButtonStyle(
                  shape: WidgetStateProperty.all(const StadiumBorder(
                      side: BorderSide(style: BorderStyle.none)))),
              onPressed: _doConvert,
              child: const Text('转换', style: TextStyle(color: Colors.blue)),
            ),
            const SizedBox(height: 10),
            if (_reqProgress > 0) Text("[${_isFetching ? "获取中" : "完毕"}]获取链接数：$_reqProgress"),
            const SizedBox(height: 10),
            if (_total != 0) Text("[${_isConverting ? "转换中" : "完毕"}]保存进度：$_current / $_total"),
          ],
        ),
      ),
    );
  }

  void _doConvert() async {
    var state = (_formKey.currentState as FormState);
    bool result = state.validate();
    if (!result) {
      Toast.show(context, "操作中止参数不全。");
      return;
    }
    state.save();

    setState(() {
      _isConverting = true;
    });

    List<String> links = await _getLinks();

    await _writeFiles(links);

    setState(() {
      _isConverting = false;
    });
  }

  Future<Html.Document> fetchRssFeed(String url) async {
    Dio? dio = Dio();
    if (_httpProxy != "") {
      String hostPort = _httpProxy.substring(_httpProxy.indexOf("http://") + 7);
      // 配置 HttpClientAdapter 设置代理
      (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
          (client) {
        // 创建 HttpClient
        client.findProxy = (uri) {
          // 设置代理地址
          return "PROXY $hostPort"; // 替换为你的代理地址和端口
        };

        // 忽略证书校验 (仅适用于开发环境)
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

        return client;
      };
    }
    final response = await dio.get<String?>(url);
    if (response.statusCode == 200) {
      return Html.parse(response.data);
    } else {
      throw Exception('Failed to load RSS feed');
    }
  }

  Future<List<String>> _getLinks() async {
    List<String> links = [];
    bool hasNext = true;
    String prefix = _url.substring(0, _url.lastIndexOf('/') + 1);
    if (!prefix.contains("page")) prefix = '${prefix}list/page/';
    String postfix = _url.substring(_url.indexOf('?'));
    String pageStr = _url.substring(_url.lastIndexOf('/') + 1, _url.indexOf('?'));
    int page = pageStr == 'list' ? 1 : int.parse(pageStr);

    setState(() {
      _isFetching = true;
    });
    int i = 0;
    while(hasNext && i <= _maxLinkCounts) {
      String newUrl = prefix + page.toString() + postfix;
      try {
        Html.Document doc = await fetchRssFeed(newUrl);
        List<String?> magnets = doc
            .querySelectorAll("div.table div.clear tr a.arrow-magnet")
            .map((el) => el.attributes['href'])
            .toList();

        Html.Element? nextEl = doc.querySelectorAll("div.table div.fl a")
        .where((el)=>el.text.contains("下")).firstOrNull;
        hasNext = nextEl != null;

        i += magnets.length;

        for(var magnet in magnets) {
          if (magnet != null && magnet.isNotEmpty) links.add(magnet);
        }

        setState(() {
          _reqProgress = links.length;
        });

        page++;
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      }
    }

    setState(() {
      _isFetching = false;
    });
    return links;
  }

  Future<void> _writeFiles(List<String> links) async {
    setState(() {
      _total = links.length;
    });
    const postfix = ".txt";

    Map<int, String> sbMap = {};
    StringBuffer sb = StringBuffer("");
    for (int i = 0; i < links.length; i++) {
      final String url = links[i];
      final int fileIndex = ((_current / _singleFileLinkCounts) + 1).toInt();
      if (sbMap.containsKey(fileIndex)) {
        sb.write(sbMap[fileIndex]);
        sb.writeln();
      }
      sb.write(url);
      sbMap[fileIndex] = sb.toString();
      sb.clear();
      setState(() {
        _current++;
      });
    }

    DateTime now = DateTime.now();
    Directory docDir = await getApplicationDocumentsDirectory();
    Directory subDir = Directory('${docDir.path}/run.ikaros.ch.dmhytool/${now.year}.${now.month}.${now.day}');
    if (!subDir.existsSync()) {
      subDir.createSync(recursive: true);
    }

    for (var entry in sbMap.entries) {
      String fileName = _namePrefix + entry.key.toString() + postfix;
      File file = File('${subDir.path}/$fileName');
      if (!file.existsSync()) file.createSync();
      file.writeAsStringSync(entry.value);
      if (kDebugMode) print("Write file: ${file.path}");
    }
  }
}
