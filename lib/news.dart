import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vadhiyar/send.dart';
import 'home_screen.dart';
import 'death.dart';
import 'mypost.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import "package:chewie/chewie.dart";
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';

class custome extends StatefulWidget
{
  late int index;
  custome({required this.index});

  @override
  State<custome> createState() => _customeState();
}

class _customeState extends State<custome> {

  @override
  Widget build(BuildContext context)
  {
    if(widget.index == 0)
    return news();
    else if(widget.index == 1)
      return death();
    else
      return MyPost();
  }
}

class news extends StatefulWidget
{
  @override
  State<news> createState() => _newsState();
}

class _newsState extends State<news> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('news').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No news available.'));
          }

          final newsDocs = snapshot.data!.docs;

          // Sort the news items by likes in descending order
          newsDocs.sort((a, b) => (b['like'] ?? 0).compareTo(a['like'] ?? 0));

          return ListView.builder(
            itemCount: newsDocs.length,
            itemBuilder: (context, index) {
              var newsData = newsDocs[index].data() as Map<String, dynamic>;
              Widget mediaWidget = SizedBox.shrink();

              // Check if media is a video (.mp4)
              if (newsData['media'] != null && getFileExtension(newsData['media']) == 'mp4') {
                mediaWidget = VideoPlayerWidget(videoUrl: newsData['media']);
              } else if (newsData['media'] != null) {
                mediaWidget = Image.network(
                  newsData['media'],
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                );
              }

              String content = newsData['content'] ?? 'No Content';
              bool showReadMore = content.length > 100;

              return FutureBuilder<bool>(
                future: checkIfLiked(newsData['timestamp']),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator(); // Show a loading indicator while waiting
                  }
                  bool islike = snapshot.data!;
                      print("the video is liked===========>$islike");
                  return Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                margin: EdgeInsets.only(right: 10),
                                child: buildSenderLogo(newsData['sendername']),
                              ),
                              SizedBox(width: 8),
                              Text("${newsData['sendername']}"),
                            ],
                          ),
                          SizedBox(height: 8),
                          mediaWidget,
                          SizedBox(height: 8),
                          Text(newsData['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text(
                            showReadMore ? content.substring(0, 100) + '...' : content,
                            style: TextStyle(color: Colors.black87),
                          ),
                          if (showReadMore)
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => FullArticleScreen(timestamp: newsData['timestamp'])),
                                );
                              },
                              child: Text("Read More"),
                            ),
                        ],
                      ),
                      subtitle: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () async {
                                  setState(() {
                                    islike = !islike;
                                  });
                                  if (islike) {
                                    await mypost('', newsData['timestamp']);
                                  }
                                },
                                icon: islike
                                    ? Icon(Icons.thumb_up_off_alt_sharp, color: Colors.blue)
                                    : Icon(Icons.thumb_up_alt_sharp),
                              ),
                              Text('${newsData['like'] ?? 0}'),
                            ],
                          ),
                          TextButton(
                            onPressed: () {

                              showCommentBottomSheet(context, newsData['timestamp']);
                           },
                            child: Row(
                              children: [
                                Icon(Icons.comment),
                                SizedBox(width: 5),
                                Text("${newsData['totalcomments'] ??0}"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );

        },
      ),

    );
  }


}

//for video player


class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  VideoPlayerWidget({required this.videoUrl});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      autoPlay: true,
      looping: true,
      // Additional options can be configured here
    );
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _videoPlayerController.value.isInitialized
            ? AspectRatio(
          aspectRatio: _videoPlayerController.value.aspectRatio,
          child: Chewie(
            controller: _chewieController,

          ),
        )
            : Container(),
      ],
    );
  }
}



String getFileExtension(String url) {
  // Split the URL by '?' to separate the file extension and query parameters
  List<String> parts = url.split('?');

  // Get the first part of the URL which should be the file extension
  String extension = parts.first.split('.').last;

  print("===>>>>>>>$extension");

  // Return the file extension
  return extension;
}


class FullArticleScreen extends StatefulWidget
{
  final String timestamp;
  FullArticleScreen({required this.timestamp});
  @override
  State<FullArticleScreen> createState() => _FullArticleScreenState(timestamp:timestamp);
}

class _FullArticleScreenState extends State<FullArticleScreen> {
  final String timestamp;

  _FullArticleScreenState({required this.timestamp});
  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(
        title: Text('Full Article'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('news').doc(timestamp).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Article not found.'));
          }

          var newsData = snapshot.data!.data() as Map<String, dynamic>;

          Widget mediaWidget = SizedBox.shrink();

          // Check if media is a video (.mp4)
          if (newsData['media'] != null && getFileExtension(newsData['media']) == 'mp4') {
            // Display video player
            //mediaWidget = CustomVideoPlayer(videoPath: newsData['media']);
            mediaWidget = VideoPlayerWidget(videoUrl: newsData['media']);
          } else if (newsData['media'] != null) {
            // Display image
            mediaWidget = Image.network(
              newsData['media'],
              width: double.infinity,
              height: 200, // Set a fixed height
              fit: BoxFit.cover, // Adjust image to cover the space
            );
          }

          String content = newsData['content'] ?? 'No Content';

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  newsData['title'] ?? '',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                SizedBox(height: 16),
                mediaWidget,
                SizedBox(height: 16),
                Text(
                  content,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  '${newsData['sendername']}'
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

//for logo maker
Widget buildSenderLogo(String senderName, {double fontSize = 12, double padding = 4}) {
  // Extract the initials from the sender's name
  List<String> initials = senderName.trim().split(' ').map((String name) {
    return name.isNotEmpty ? name[0] : '';
  }).toList();

  // Take the first two initials (or less if the sender's name has only one word)
  initials = initials.length > 1 ? [initials[0], initials[1]] : [initials[0]];

  // Combine the initials to create the logo text
  String logoText = initials.join().toUpperCase();

  // Return a container with rounded corners and background color
  return Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.blue, // You can change the color as needed
    ),
    child: Text(
      logoText,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
      ),
    ),
  );
}



Future<bool> checkIfLiked(String timestamp) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? phoneNumber = prefs.getString('phonenumber'); // Fetch phone number from SharedPreferences

    if (phoneNumber == null) {
      print("Phone number not found in SharedPreferences.");
      return false;
    }

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection(phoneNumber) // Assuming 'phonenumber' is the collection name
        .doc('like')
        .get();

    if (doc.exists) {
      List<dynamic> likedPosts = doc['timestamp'];
      print("$likedPosts");
      return likedPosts.contains(timestamp);
    } else {
      return false;
    }
  } catch (e) {
    print("Error checking liked status: $e");
    return false;
  }
}


//for comment screen








class CommentScreen extends StatefulWidget {
  final String timestamp;

  CommentScreen({required this.timestamp});

  @override
  _CommentScreenState createState() => _CommentScreenState();
}
String _formatTimestamp(String timestamp) {
  DateTime dateTime = DateTime.parse(timestamp);
  return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
}

class _CommentScreenState extends State<CommentScreen> {
  TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? senderName = "${prefs.getString('surname')} ${prefs.getString('name')} ${prefs.getString('lastname')}";
    String? senderPhoneNumber = prefs.getString('phonenumber');

    if (_commentController.text.isEmpty || senderName == null || senderPhoneNumber == null) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('news')
        .doc(widget.timestamp)
        .collection('comments')
        .doc(DateTime.now().toIso8601String())
        .set({
      'comment': _commentController.text,
      'sendername': senderName,
      'senderphonenumber': senderPhoneNumber,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await FirebaseFirestore.instance.collection('news').doc(widget.timestamp).set({
      'totalcomments': FieldValue.increment(1)
    },
      SetOptions(merge: true),
    );
    _commentController.clear();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Comments",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('news')
            .doc(widget.timestamp)
            .collection('comments')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var comments = snapshot.data!.docs;

          return ListView.builder(
            itemCount: comments.length,
            itemBuilder: (context, index) {
              var commentData = comments[index].data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Text(
                        commentData['sendername'][0].toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      ), // Display the first letter of the sender's name
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            commentData['sendername'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _formatTimestamp(commentData['timestamp']),
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          SizedBox(height: 5),
                          Text(commentData['comment']),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, -1),
              blurRadius: 4.0,
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: Colors.blue),
                onPressed: () async {
                  await _addComment();
                  setState(() {
                    _commentController.clear();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}



void showCommentBottomSheet(BuildContext context, String timestamp) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: CommentScreen(timestamp: timestamp),
    ),
  );
}










Future<void> deleteExpiredDocuments() async {
  try {
    // Get today's date
    DateTime today = DateTime.now();
    print('Today\'s date: ${today.toIso8601String()}');

    // Retrieve documents from the collection
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('news').get();

    // Iterate over the documents
    for (QueryDocumentSnapshot doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;

      // Check if the document has the 'endtime' field
      if (data.containsKey('endtime')) {
        // Get the 'endtime' field and parse it as a DateTime
        String endDateString = data['endtime'];
        DateTime endDate = DateTime.parse(endDateString);
        print('Document ID: ${doc.id}, endtime: ${endDate.toIso8601String()}');

        // Compare 'endtime' with today's date
        if (endDate.isBefore(today)) {
          // Check if the document has a 'media' field
          if (data.containsKey('media')) {
            // Get the 'media' URL
            String mediaUrl = data['media'];

            // Create a reference to the file to delete
            Reference storageRef = FirebaseStorage.instance.refFromURL(mediaUrl);

            // Delete the file from Firebase Storage
            await storageRef.delete();
            print('Deleted media file from storage: $mediaUrl');
          }

          // Delete the document from Firestore
          await FirebaseFirestore.instance.collection('news').doc(doc.id).delete();
          print('Deleted document with ID: ${doc.id}');
        } else {
          print('Document with ID: ${doc.id} is not expired.');
        }
      } else {
        print('Document with ID: ${doc.id} does not have endtime field.');
      }
    }

    print('Expired documents check complete.');
  } catch (e) {
    print('Error while deleting expired documents: $e');
  }
}




