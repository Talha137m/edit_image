import 'dart:io';
import 'dart:typed_data';
import 'package:edit_the_image/custom_painter.dart';
import 'package:edit_the_image/drawing_points.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'custom_painter.dart';

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

class _MyHomePageState extends State<MyHomePage> {
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: pickImages,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
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
}
