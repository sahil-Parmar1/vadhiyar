import 'package:flutter/material.dart';

class death extends StatefulWidget
{
  @override
  State<death> createState() => _deathState();
}

class _deathState extends State<death> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ListTile(
            title: Text('death'),
          )
        ],
      ),
    );
  }
}