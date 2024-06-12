import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vadhiyar/send.dart';
import 'death.dart';
import 'mypost.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'useraboutscreen.dart';
import 'videoplayer.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'login_screen.dart';
//getvillage suggestion
Future<List<String>> _getVillageSuggestions(String query) async {
  final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('village').get();
  final List<String> villages = snapshot.docs.map((doc) => doc.id).toList();

  // Filter villages based on the query
  List<String> filteredVillages = villages.where((village) => village.toLowerCase().startsWith(query.toLowerCase())).toList();
  print("$filteredVillages");
  return filteredVillages;
}
String sendtogam='all';

class custome extends StatefulWidget
{
  late int index;
  custome({required this.index});

  @override
  State<custome> createState() => _customeState();
}
Future<List<String>> getbuttons() async
{
  SharedPreferences got= await SharedPreferences.getInstance();
  print(got.getStringList('buttons')??[]);
  return got.getStringList('buttons')??[];
}
class _customeState extends State<custome> {

   List<String> buttons=[];
   void _loadbuttons() async
   {
     buttons=await getbuttons();
     setState(() {
       print("buttons => $buttons");
     });
   }
  @override
  void initState()
  {
    super.initState();
    _loadbuttons();
    setState(() {});
  }
  @override
  Widget build(BuildContext context)
  {
    if(widget.index == 0)
    return news(buttons:buttons);
    else
    return MyPost();


  }
}

class news extends StatefulWidget
{
  List<String> buttons;
  news({required this.buttons});
  @override
  State<news> createState() => _newsState();
}

class _newsState extends State<news> {
  TextEditingController _villageController = TextEditingController();
   PageController _pageController = PageController();
  @override
  void dispose() {
    _villageController.dispose();
    super.dispose();
    _pageController.dispose();
  }
   @override
  Widget build(BuildContext context) {
    print("buttons is scaffold ${widget.buttons}");

    return Scaffold(
      appBar: AppBar(

        title:Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                height: 50.0,  // Adjust the height as needed
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.buttons.length+1,
                  itemBuilder: (context, index) {
                    if(index == widget.buttons.length)
                      return TextButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true, // Add this line
                            builder: (BuildContext context) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  left: 16.0,
                                  right: 16.0,
                                  top: 16.0,
                                  bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
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
                                            if(!(widget.buttons.contains(_villageController.text)))
                                              {
                                                widget.buttons.add(_villageController.text);
                                                SharedPreferences.getInstance().then((value) {
                                                  value.setStringList('buttons', widget.buttons);
                                                }); 
                                              }

                                          });
                                          _villageController.clear();
                                          Navigator.of(context).pop();
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'કૃપા કરીને તમારું ગામ દાખલ કરો';
                                          }
                                          // You can add validation rules for village here
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: 200),
                                      ElevatedButton(onPressed: (){
                                        _villageController.clear();
                                        Navigator.pop(context);
                                      }, child: Text("Cancel"))
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Icon(Icons.add),
                      );
                    else
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 8.0), // Increase margin for better spacing
                        padding: EdgeInsets.all(4.0), // Add padding for better touch area
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0), // Rounded corners

                          gradient: LinearGradient(
                            colors: sendtogam!=widget.buttons[index]?[Colors.white,Colors.white]:[Colors.blueAccent, Colors.lightBlueAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              sendtogam = widget.buttons[index];
                              _pageController.jumpToPage(index);
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            primary: Colors.transparent, // Use gradient color from container
                            shadowColor: Colors.transparent, // Remove button shadow
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Better padding for larger touch area
                          ),
                          child: Text(
                            widget.buttons[index],
                            style: TextStyle(
                              color: sendtogam!=widget.buttons[index]?Colors.blue:Colors.white,
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );


                  },
                ),
              ),
            ),


          ],
        ),

      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.buttons.length,
        onPageChanged: (index)
          {
            setState(() {
              sendtogam=widget.buttons[index];
            });
          },
        itemBuilder: (context,index) {
          return StreamBuilder<QuerySnapshot>(
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
                        if (!(newsData['sendto']?.contains(sendtogam)==true)) {
                          return SizedBox.shrink();
                        }
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
                            return Container(); // Show a loading indicator while waiting
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
                                  GestureDetector(
                                    onTap: (){
                                      print("${newsData['sender']}is pressed..");
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProfileScreen(phoneNumber: newsData['sender']??''),
                                        ),
                                      );

                                    },
                                    child: Row(
                                      children: [
                                        Container(
                                          margin: EdgeInsets.only(right: 10),
                                          child: buildSenderLogo(newsData['sendername']),
                                        ),
                                        SizedBox(width: 8),
                                        Text("${newsData['sendername']}"),
                                      ],
                                    ),
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
                    }


              );

            },
          );
        }
      ),

    );
  }


}

//for video player






String getFileExtension(String url) {
  // Split the URL by '?' to separate the file extension and query parameters
  List<String> parts = url.split('?');

  // Get the first part of the URL which should be the file extension
  String extension = parts.first.split('.').last;

  print("===>>>>>>>$extension");

  // Return the file extension
  return extension;
}


class FullArticleScreen extends StatefulWidget {
  final String timestamp;

  FullArticleScreen({required this.timestamp});

  @override
  State<FullArticleScreen> createState() => _FullArticleScreenState(timestamp: timestamp);
}

class _FullArticleScreenState extends State<FullArticleScreen> {
  final String timestamp;
  bool isLiked = false;


  _FullArticleScreenState({required this.timestamp});

  @override
  void initState() {
    super.initState();
    checkLikeStatus();
  }

  Future<void> checkLikeStatus() async {
    bool liked = await checkIfLiked(timestamp);
    setState(() {
      isLiked = liked;
    });
  }

  void toggleLike() async {
    await mypost('', timestamp); // Call mypost with liketimestamp
    setState(() {
      isLiked = !isLiked;

    });
  }

  void openCommentScreen(BuildContext context) {
    showCommentBottomSheet(context, timestamp);
  }

  @override
  Widget build(BuildContext context) {
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

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  newsData['title'] ?? '',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
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
                  'By ${newsData['sendername']}',
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                            color: isLiked ? Colors.blue : Colors.grey,
                          ),
                          onPressed: toggleLike,
                        ),
                        Text('${newsData['like']}'),
                      ],
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.comment),
                      label: Row(
                        children: [
                          Text('${newsData['totalcomments']??0}'),
                        ],
                      ),
                      onPressed: () {
                        openCommentScreen(context);
                      },
                    ),
                  ],
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

    // Fetch timestamps from 'send' and 'like' collections
    List<String> sendTimestamps = await _fetchTimestamps('send');
    List<String> likeTimestamps = await _fetchTimestamps('like');

    // Combine all timestamps
    List<String> allTimestamps = [...sendTimestamps, ...likeTimestamps];

    // Fetch documents from 'news' collection using the timestamps
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('news')
        .where(FieldPath.documentId, whereIn: allTimestamps)
        .get();

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

            // Delete the media from Firebase Storage
            await _deleteMedia(mediaUrl);
            print('Deleted media file from storage: $mediaUrl');
          }

          // Delete the document from Firestore
          // Delete only the expired timestamps from 'send' and 'like' collections
          await _deleteExpiredTimestamps('send', data['timestamp']);
          await _deleteExpiredTimestamps('like', data['timestamp']);
          await doc.reference.delete();
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

Future<List<String>> _fetchTimestamps(String collectionName) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String phoneNumber = prefs.getString('phonenumber') ?? '';

    List<String> timestamps = [];

    if (phoneNumber.isNotEmpty) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection(phoneNumber).doc(collectionName).get();
      if (doc.exists) {
        timestamps = List<String>.from(doc['timestamp'] ?? []);
      }
    }

    return timestamps;
  } catch (e) {
    print('Error fetching timestamps: $e');
    return [];
  }
}

Future<void> _deleteMedia(String mediaUrl) async {
  try {
    // Create a reference to the file to delete
    Reference storageRef = FirebaseStorage.instance.refFromURL(mediaUrl);

    // Delete the file from Firebase Storage
    await storageRef.delete();
  } catch (e) {
    print('Error deleting media: $e');
  }
}

Future<void> _deleteExpiredTimestamps(String collectionName,String timestamp) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String phoneNumber = prefs.getString('phonenumber') ?? '';

    if (phoneNumber.isNotEmpty) {
      // Filter expired timestamps
      await FirebaseFirestore.instance.collection(phoneNumber).doc(
          collectionName).update(
          {'timestamp': FieldValue.arrayRemove([timestamp])});
    }
  } catch (e) {
    print('Error deleting expired timestamps from $collectionName: $e');
  }
}








