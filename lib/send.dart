

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'home_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
void showMessageInput(BuildContext context, int index) {
  final ImagePicker picker = ImagePicker();
  TextEditingController titleController = TextEditingController();
  TextEditingController contentController = TextEditingController();
  XFile? attachedFile;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  if (attachedFile != null) ...[
                    if (attachedFile!.path.endsWith('.mp4'))
                      Expanded(
                        child: Container(
                          color: Colors.white,
                          child: Center(
                            child: CustomVideoPlayer(videoPath: attachedFile!.path),
                          ),
                        ),
                      )
                    else
                      Image.file(
                        File(attachedFile!.path),
                        height: 150,
                      ),
                    SizedBox(height: 10),
                  ],
                  TextField(
                    controller: titleController,
                    style: TextStyle(
                      fontFamily: 'NotoSansGujarati',

                    ),
                    decoration: InputDecoration(
                      hintText: 'વિષય',

                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: contentController,
                    maxLines: null,


                    style: TextStyle(
                      fontFamily: 'NotoSansGujarati',

                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a Message here..',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),

                      ),
                    ),
                    onChanged: (text) {
                      setState(() {});
                    },
                  ),
                  SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final XFile? photo = await picker.pickImage(source: ImageSource.gallery);
                          if (photo != null) {
                            setState(() {
                              attachedFile = photo;
                            });
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                                (Set<MaterialState> states) {
                              return Colors.white;
                            },
                          ),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                        ),
                        icon: Icon(
                          Icons.photo,
                          color: Colors.blue,
                        ),
                        label: Text(
                          'Photo',
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
                          if (video != null) {
                            // Check the file size
                            final File file = File(video.path);
                            final int maxSizeInBytes = 200 * 1024 * 1024; // 200MB in bytes
                            final int fileSize = await file.length();
                            if (fileSize > maxSizeInBytes) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('ફાઇલ ખૂબ મોટી છે'),
                                    content: Text('કૃપા કરીને 200MB કરતા નાની વિડિઓ પસંદ કરો.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            } else {
                              setState(() {
                                attachedFile = video;
                              });
                            }
                          }
                        },
                        style: ButtonStyle(

                          backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                                (Set<MaterialState> states) {
                              return Colors.white;
                            },
                          ),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                        ),
                        icon: Icon(
                          Icons.videocam,
                          color: Colors.blue,
                        ),
                        label: Text(
                          'Video',
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: contentController.text.isNotEmpty
                            ? () async{
                            String? downloadUrl;
                          if(attachedFile!=null)
                            {
                              downloadUrl=await uploadAndShowProgress(context, attachedFile!);
                            }
                           await sendPost(downloadUrl,contentController.text,titleController.text);

                          // Handle send message logic
                          print('Title: ${titleController.text}');
                          print('Content: ${contentController.text}');
                          if (attachedFile != null) {
                            print('Attached File: ${attachedFile!.path}');
                          }
                          titleController.clear();
                          contentController.clear();
                          setState(() {
                            attachedFile = null;
                          });

                          Navigator.pop(context);
                        }
                            : null,
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                                (Set<MaterialState> states) {
                              return contentController.text.isNotEmpty ? Colors.blue : Colors.grey;
                            },
                          ),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                        ),
                        icon: Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Send',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),
          );
        },
      );
    },
  );
}


class CustomVideoPlayer extends StatefulWidget {
  final String videoPath;

  const CustomVideoPlayer({Key? key, required this.videoPath}) : super(key: key);

  @override
  _CustomVideoPlayerState createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  late Timer _timer;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});
      });
    _controller.addListener(() {
      final bool isPlaying = _controller.value.isPlaying;
      if (isPlaying != _isPlaying) {
        setState(() {
          _isPlaying = isPlaying;
        });
      }
      if (_controller.value.duration != null && _controller.value.duration!.inMilliseconds > 0) {
        setState(() {
          _progress = _controller.value.position.inMilliseconds.toDouble() / _controller.value.duration!.inMilliseconds;
        });
      }
    });
    _timer = Timer.periodic(Duration(milliseconds: 500), (_) {
      if (_controller.value.duration != null && _controller.value.duration!.inMilliseconds > 0) {
        setState(() {
          _progress = _controller.value.position.inMilliseconds.toDouble() / _controller.value.duration!.inMilliseconds;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _controller.value.isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: Container(
            height: 200, // Adjust the height as needed
            child: VideoPlayer(_controller),
          ),
        )
            : Container(),
        SizedBox(height: 8),
        Container(
          color: Colors.black.withOpacity(0.4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    setState(() {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
                    });
                  },
                ),
                Expanded(
                  child: Slider(
                    value: _progress.isNaN ? 0.0 : _progress,
                    onChanged: (value) {
                      setState(() {
                        _progress = value;
                        final newPosition = Duration(milliseconds: (_controller.value.duration!.inMilliseconds * value).toInt());
                        _controller.seekTo(newPosition);
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.stop),
                  onPressed: () {
                    setState(() {
                      _controller.pause();
                      _controller.seekTo(Duration.zero);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


//for uploading the photo and video
Future<String?> uploadAndShowProgress(BuildContext context, XFile file) async {
  try {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    UploadTask uploadTask = await uploadFileToFirebase(file, auth, firestore);

    // Show upload progress dialog
    await showUploadProgress(context, uploadTask);

    // Get download URL
    String? downloadURL = await getDownloadURL(uploadTask);

    if (downloadURL == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload file.'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
    else
      return downloadURL;

  } catch (e) {
    print('Error uploading file: $e');
    // Show an error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('An error occurred while uploading file.'),
        backgroundColor: Colors.red,
      ),
    );
    return null;
  }
}
Future<UploadTask> uploadFileToFirebase(XFile file, FirebaseAuth auth, FirebaseFirestore firestore) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String fileType = file.path.endsWith('.mp4') ? '.mp4' : '.jpg';
  final storageRef = FirebaseStorage.instance
      .ref()
      .child('user_files/${prefs.getString('phonenumber')}/${DateTime.now()}.$fileType');

  UploadTask task = storageRef.putFile(File(file.path));
  return task;
}



Future<void> sendPost(String? downloadUrl, String content, String? title) async {
  final prefs = await SharedPreferences.getInstance();
  final phoneNumber = prefs.getString('phonenumber') ?? 'unknown';
  final timestamp=DateTime.now().toIso8601String();
  final formatDate=DateTime.now().add(Duration(days: 5)).toIso8601String();
  print("endtime is =======>>>$formatDate");
  Map<String, dynamic> data = {
    'content': content,
    'sender': phoneNumber,
    'endtime': formatDate,
    'timestamp': timestamp,
    'like':0,
    'views':0,
    'sendername':'${prefs.getString('surname')} ${prefs.getString('name')} ${prefs.getString('lastname')}',
  };

  if (downloadUrl != null) {
    data['media'] = downloadUrl;
  }
  if (title != null) {
    data['title'] = title;
  }

  await FirebaseFirestore.instance.collection('news').doc(timestamp).set(data,SetOptions(merge:true));
  await mypost(timestamp,'');
}
Future<void> mypost(String sendtimestamp,String liketimestamp) async
{
  final prefs = await SharedPreferences.getInstance();
   final phoneNumber = prefs.getString('phonenumber') ?? 'unknown';
  if(liketimestamp == '')
    {
      await FirebaseFirestore.instance.collection(phoneNumber).doc('send').set({
        'timestamp': FieldValue.arrayUnion([sendtimestamp])
      },
        SetOptions(merge: true),
      );
    }
  if(sendtimestamp == '')
    {
      await FirebaseFirestore.instance.collection(phoneNumber).doc('like').set({
        'timestamp': FieldValue.arrayUnion([liketimestamp])
      },
        SetOptions(merge: true),
      );
      await FirebaseFirestore.instance.collection('news').doc(liketimestamp).set({
        'like':FieldValue.increment(1),
      },SetOptions(merge:true));
    }

}