import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:isolate';
import 'dart:io';
import 'dart:ui';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterDownloader.initialize(debug: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Player',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Video Downloader and Player'),
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
  late VideoPlayerController _controller;
  String _videoUrl = 'https://t.tarahipro.ir/1403/05/06/Dreamcoin.2024.480p.WEB-DL.mkv';
  String? _localPath;
  ReceivePort _port = ReceivePort();

  @override
  void initState() {
    super.initState();
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      if (data[1] == DownloadTaskStatus.complete) {
        setState(() {
          _localPath = data[2];
          _controller = VideoPlayerController.file(File(_localPath!))
            ..initialize().then((_) {
              setState(() {});
              _controller.play();
            });
        });
      }
    });
    FlutterDownloader.registerCallback(downloadCallback);
    _requestPermissions();
  }

  @override
  void dispose() {
    _controller.dispose();
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

  void _requestPermissions() async {
    if (await Permission.storage.request().isGranted) {
      _prepareSaveDir();
    } else {
      print('Not access');
    }
  }

  void _prepareSaveDir() async {
    final directory = await getApplicationDocumentsDirectory();
    _localPath = directory.path;
    _startDownload();
  }

  void _startDownload() async {
    await FlutterDownloader.enqueue(
      url: _videoUrl,
      savedDir: _localPath!,
      showNotification: true,
      openFileFromNotification: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: _localPath == null
            ? CircularProgressIndicator()
            : _controller.value.isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
            : CircularProgressIndicator(),
      ),
    );
  }
}
