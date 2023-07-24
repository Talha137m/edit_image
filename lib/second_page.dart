
import 'dart:io';
import 'package:edit_the_image/controller.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

class SecondPage extends StatefulWidget {
  const SecondPage({super.key});

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> with editController {
  List<FileSystemEntity> list=[];
  @override
  void initState() {
    super.initState();
    if(Directory(folderPath).existsSync()){
      list= Directory(folderPath).listSync(recursive: true);
      print(list);
    }
    else{
      print('directory not existMMMMMMMMMMMMMMMMMMMMMMMMMMMM');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:list.isNotEmpty? ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, index) {
        return GestureDetector(
          onTap: ()async{
            OpenResult openResult=await OpenFile.open(list[index].path);
            if(openResult.message!='done'){
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      'can\'t open file ${openResult.message}')));
            }
          },
          child: ListTile(
            leading: const CircleAvatar(
              foregroundColor: Colors.amber,
              backgroundColor:Colors.transparent,
              child: Icon(Icons.image_outlined),
            ),
            title: Text(list[index].path),
          ),
        );
      },):const Center(child:Text('no data'),),
    );
  }
}
