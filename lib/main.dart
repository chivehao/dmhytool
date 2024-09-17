import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rss Tool',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Rss Tool Home Page'),
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
  String _namePrefix = "links";
  int _singleFileLinkCounts = 50;
  String _rssUrl = "";

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
              initialValue: _namePrefix,
              decoration: const InputDecoration(labelText: '输出文件名前缀'),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return '请输入输出文件名前缀';
                }
                return _namePrefix;
              },
              onSaved: (v) => _namePrefix = v!,
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(labelText: '单个文件的链接数量'),
              onSaved: (v) => _singleFileLinkCounts = int.parse(v!),
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: _rssUrl,
              decoration: const InputDecoration(labelText: 'RSS Url'),
              maxLines: 5,
              onSaved: (v) => _rssUrl = v!,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ButtonStyle(
                  shape: WidgetStateProperty.all(const StadiumBorder(
                      side: BorderSide(style: BorderStyle.none)))),
              onPressed: _doConvert,
              child: const Text('登录', style: TextStyle(color: Colors.blue)),
            )
          ],
        ),
      ),
    );
  }

  void _doConvert() async {
    List<String> links = await _getLinks();

  }

  Future<List<String>> _getLinks()async {
    List<String> links = [];
    // TODO
    return links;
  }

  Future<void> _writeFiles(List<String> links)async {
    // TODO
  }
}
