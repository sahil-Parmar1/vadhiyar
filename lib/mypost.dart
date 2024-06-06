import 'package:flutter/material.dart';
class MyPost extends StatefulWidget
{
  @override
  State<MyPost> createState() => _MyPostState();
}

class _MyPostState extends State<MyPost> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ListTile(
            title: Text('mypost'),
          )
        ],
      ),
    );
  }
}