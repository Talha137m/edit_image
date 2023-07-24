import 'dart:io';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:edit_the_image/controller.dart';
import 'package:edit_the_image/custom_painter.dart';
import 'package:edit_the_image/drawing_points.dart';
import 'package:edit_the_image/second_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui' as ui;
import 'capture_frames.dart/core.dart';
import 'capture_frames.dart/formats.dart/abstract.dart';
import 'capture_frames.dart/services/notifier.dart';
import 'capture_frames.dart/services/setting.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'talha'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with editController {
  List<XFile> listOfImages = [];
  List<dynamic> drawingPoints = [];
  Offset offset = const Offset(0, 0);

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.sizeOf(context).width;
    var height = MediaQuery.sizeOf(context).height;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Stack(
          children: [
            SizedBox(
              width: width,
              height: height * 0.7,
              child: listOfImages.isNotEmpty
                  ? Image.file(
                      File(listOfImages[0].path),
                    )
                  : Container(
                      child: const Text('no image'),
                    ),
            ),
            Positioned(
              left: width * 0.1,
              height: height * 0.4,
              child: Render(
                controller: renderController,
                child: SizedBox(
                  width: width * 0.5,
                  height: height * 0.4,
                  child: GestureDetector(
                    onPanUpdate: onPanUpdate,
                    onPanStart: onPanStart,
                    onPanEnd: onPanEnd,
                    child: CustomPaint(
                      painter: MyPainter(drawingPoints: drawingPoints),
                      child: Opacity(
                        opacity: 0.7,
                        child: listOfImages.length == 2
                            ? Image.file(
                              File(listOfImages[1].path),
                              fit: BoxFit.fill,
                            )
                            : Container(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      persistentFooterButtons: <TextButton>[
        TextButton(
          onPressed: pickImages,
          child: const Icon(Icons.add),
        ),
        TextButton(
          onPressed: requestStoragePermission,
          child: const Text('capture'),
         ),
        TextButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SecondPage(),
                ));
          },
          child: const Text('Go'),
        ),
      ],
    );
  }

  void pickImages() async {
    ImagePicker imagePicker = ImagePicker();
    try {
      final pickedImages = await imagePicker.pickMultiImage(imageQuality: 95);
      setState(() {
        listOfImages = pickedImages;
      });
    } catch (e) {
      print(e);
    }
  }

  void onPanStart(DragStartDetails details) {
    print('user started drawing');
    setState(() {
      final box = context.findRenderObject() as RenderBox;
      final ponits = box.globalToLocal(details.localPosition);
      drawingPoints.add(DrawingPoints(
          paint: Paint()
            ..color = Colors.transparent
            ..strokeWidth = 10
            ..strokeCap = StrokeCap.round,
          points: ponits));
    });
  }

  void onPanUpdate(DragUpdateDetails details) {
    // double pixels = MediaQuery.of(context).devicePixelRatio;
    // Image image = Image.file(File(listOfImages[1].path));
    var width = MediaQuery.sizeOf(context).width;
    var height = MediaQuery.sizeOf(context).height;
    setState(() {
      final box = context.findRenderObject() as RenderBox;
      Offset points = box.globalToLocal(details.localPosition);
      if (points >= Offset.zero &&
          points <= Offset(width * 0.5, height * 0.4)) {
        drawingPoints.add(DrawingPoints(
            paint: Paint()
              ..color = Colors.black
              ..strokeWidth = 10
              ..strokeCap = StrokeCap.round,
            points: points));
      } else {
        drawingPoints.add(null);
      }
      // Float64List deviceTransform = Float64List(16)
      //   ..[0] = pixels
      //   ..[5] = pixels
      //   ..[10] = 1.0
      //   ..[15] = 2.0;
    });
  }

  void onPanEnd(DragEndDetails details) {
    setState(() {
      drawingPoints.add(null);
    });
    print('user end painting');
  }

  void captureFrames() async {
    Stream<RenderNotifier> frames = renderController.captureImageWithStream(
      format: ImageFormat.png,
      settings: const ImageSettings(pixelRatio: 7),
    );
    frames.listen((event) {
      if (event.isActivity) {
        final activity = event as RenderActivity;
        print('process:${activity.progressPercentage}');
      }
    });
    final result = await frames
        .firstWhere((event) => event.isResult || event.isFatalError);
    if (result.isError) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred'),
        ),
      );
    } else {
      print(
          'elseeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee');
      final imageOutput = result as RenderResult;
      File file = imageOutput.output;
      Uint8List data = await file.readAsBytes();
      File imageFile = File('$imagesPath.png');
      await imageFile.writeAsBytes(data);
      file.delete(recursive: true);
      if (await imageFile.exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('image store successfully')));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('image not store')));
      }
    }
  }

  void requestStoragePermission() async {
    var androidInfo = await DeviceInfoPlugin().androidInfo;
    var sdkInt = androidInfo.version.sdkInt;
    //sdkInt >= 29
    if (false) {
      print('android11android11android11android11android11android11android11android11android11android11android11android11android11android11android11android11');
      PermissionStatus status;
      status = await Permission.storage.request();
      switch (status) {
        case PermissionStatus.granted:

          ///1->create the required director
          createDirectory();
          captureFrames();
          break;
        case PermissionStatus.denied:
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission is denied'),
            ),
          );
          break;
        case PermissionStatus.restricted:
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission is restricted'),
            ),
          );

          break;
        case PermissionStatus.limited:
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission is Limited'),
            ),
          );

          break;
        case PermissionStatus.permanentlyDenied:
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Permission is permanently denied'),
              action: SnackBarAction(
                  label: 'Allow',
                  onPressed: () async {
                    if (!(await openAppSettings())) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unable to access'),
                        ),
                      );
                    }
                  }),
            ),
          );
          break;
        default:
          print('no action is required');
      }
    } else {
      PermissionStatus externalStatus;
      externalStatus = await Permission.manageExternalStorage.request();
      switch (externalStatus) {
        case PermissionStatus.granted:

          ///1->create the required director
          createDirectory();
          captureFrames();
          break;
        case PermissionStatus.denied:
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission is denied'),
            ),
          );
          break;
        case PermissionStatus.restricted:
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission is restricted'),
            ),
          );
          break;
        case PermissionStatus.limited:
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission is Limited'),
            ),
          );

          break;
        case PermissionStatus.permanentlyDenied:
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Permission is permanently denied'),
              action: SnackBarAction(
                  label: 'Allow',
                  onPressed: () async {
                    if (!(await openAppSettings())) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unable to access'),
                        ),
                      );
                    }
                  }),
            ),
          );
          break;
        default:
          print('no action is required');
      }
    }
  }

  void createDirectory() async {
    await Directory(folderPath).create().then((value) async {
      await Directory(imagesPath)
          .create()
          .then((value) {})
          .catchError((error) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      });
    });

    if (!(await Directory(imagesPath).exists())) {
      await Directory(imagesPath).create();
    }
  }
}
