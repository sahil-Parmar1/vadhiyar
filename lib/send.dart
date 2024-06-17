



import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'home_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'news.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import "pdfview.dart";
Future<List<String>> _getVillageSuggestions(String query) async {
  final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('village').get();
  final List<String> villages = snapshot.docs.map((doc) => doc.id).toList();

  // Filter villages based on the query
  List<String> filteredVillages = villages.where((village) => village.toLowerCase().startsWith(query.toLowerCase())).toList();
  print("$filteredVillages");
  print("hello check");
  return filteredVillages;
}

class MessageInputScreen extends StatefulWidget {

  @override
  _MessageInputScreenState createState() => _MessageInputScreenState();
}

class _MessageInputScreenState extends State<MessageInputScreen> {
  final ImagePicker picker = ImagePicker();
  TextEditingController titleController = TextEditingController();
  TextEditingController contentController = TextEditingController();
  TextEditingController _villageController = TextEditingController();
  XFile? attachedFile;
  List<String> sendto = ['all'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('send Message'),
        actions: [
          IconButton(
            icon: Icon(Icons.send),
            onPressed: contentController.text.isNotEmpty
                ? () async {
              String? downloadUrl;
              if (attachedFile != null) {
                downloadUrl = await uploadAndShowProgress(context, attachedFile!);
              }
              await sendPost(downloadUrl, contentController.text, titleController.text,sendto);

              // Clear fields after sending
              titleController.clear();
              contentController.clear();
              setState(() {
                attachedFile = null;
              });

              Navigator.pop(context);
            }
                : null,
            iconSize: 30,
            color: contentController.text.isNotEmpty ? Colors.blue : Colors.grey,
          )

        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: sendto.length,
                  itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                      onTap: () {
                        if (sendto.length > 1) {
                          setState(() {
                            sendto.removeAt(index);
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1), // Light blue background
                          borderRadius: BorderRadius.circular(20), // Rounded corners
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              sendto[index],
                              style: TextStyle(
                                color: Colors.blue, // Blue text color
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 5),
                            Icon(
                              Icons.close,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );


                  },
                ),
              ),
              SizedBox(height: 20,),
              TypeAheadFormField<String?>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _villageController,
                  decoration: InputDecoration(
                    labelText: 'ગામ',
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                  ),
                ),
                suggestionsCallback: _getVillageSuggestions,
                itemBuilder: (context, String? suggestion) {
                  return ListTile(
                    title: Text(suggestion ?? ''),
                  );
                },
                onSuggestionSelected: (String? suggestion) {
                  setState(() {
                    _villageController.text = suggestion ?? '';
                    sendto.add(_villageController.text);
                  });
                  _villageController.clear();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'કૃપા કરીને તમારું ગામ દાખલ કરો';
                  }
                  return null;
                },
              ),
              Container(color: Colors.black12,
                height: 1,
                width: double.infinity,),
              SizedBox(height: 20),
              if (attachedFile != null) ...[
                if (attachedFile!.path.endsWith('.mp4'))
                  Container(
                    height: 400,
                    child: Center(
                      child: CustomVideoPlayer(videoPath: attachedFile!.path), // replace with CustomVideoPlayer widget
                    ),
                  )
                else if (attachedFile!.path.endsWith('.pdf'))
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfPreviewScreen(filePath: attachedFile!.path),
                        ),
                      );
                    },
                    child: Text(
                      "PDF👉${path.basename(attachedFile!.path)}",
                      style: TextStyle(
                        color: Colors.blue,
                          fontSize: 15
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
                  border: OutlineInputBorder(),
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
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final XFile? photo = await picker.pickImage(source: ImageSource.gallery);
                      if (photo != null) {
                        setState(() {
                          attachedFile = photo;
                        });
                      }
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.white),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                    ),
                    child: Icon(
                      Icons.photo,
                      color: Colors.blue,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
                      if (video != null) {
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
                      backgroundColor: MaterialStateProperty.all(Colors.white),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                    ),
                    child: Icon(
                      Icons.videocam,
                      color: Colors.blue,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: ()async {

                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                      );

                      if (result != null && result.files.single.path != null) {
                        setState(() {
                          attachedFile = XFile(result.files.single.path!);
                        });
                      } else {
                        print("File not selected.");
                      }
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.white),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                    ),
                    child: Icon(Icons.picture_as_pdf),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
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
  //String fileType = file.path.endsWith('.mp4') ? '.mp4' : '.jpg';
  String fileType = path.extension(file.path).toLowerCase(); // Get the file extension and convert to lowercase

  // Ensure the file is either an image, video, or PDF
  if (fileType != '.jpg' && fileType != '.jpeg' && fileType != '.png' && fileType != '.mp4' && fileType != '.pdf') {
    throw Exception('File type not supported. Please upload an image, video, or PDF file.');
  }
  final storageRef = FirebaseStorage.instance
      .ref()
      .child('user_files/${prefs.getString('phonenumber')}/${DateTime.now()}$fileType');

  UploadTask task = storageRef.putFile(File(file.path));
  return task;
}



Future<void> sendPost(String? downloadUrl, String content, String? title,List<String> sendto) async {
  final prefs = await SharedPreferences.getInstance();
  final phoneNumber = prefs.getString('phonenumber') ?? 'unknown';
  final timestamp=DateTime.now().toIso8601String();
  final formatDate=DateTime.now().add(Duration(days: 7)).toIso8601String();
  print("endtime is =======>>>$formatDate");
  Map<String, dynamic> data = {
    'content': content,
    'sender': phoneNumber,
    'endtime': formatDate,
    'timestamp': timestamp,
    'sendto':sendto,
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