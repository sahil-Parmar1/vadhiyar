import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyPost extends StatefulWidget {
  @override
  State<MyPost> createState() => _MyPostState();
}

class _MyPostState extends State<MyPost> {
  late String _profilePhotoUrl = '';
  late String _name = '';
  late String _village = '';
  late int _followersCount = 0;
  late int _followingCount = 0;
  late List<String> _myPosts = [];
  late List<String> _likedPosts = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchFollowCounts();
    _fetchMyPosts();
    _fetchLikedPosts();
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String phoneNumber = prefs.getString('phonenumber') ?? '';

      if (phoneNumber.isNotEmpty) {
        DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(phoneNumber).get();
        if (userDoc.exists) {
          setState(() {
            _profilePhotoUrl = userDoc['profilephoto'] ?? '';
            _name =
            "${userDoc['surname'] ?? ''} ${userDoc['name'] ?? ''} ${userDoc['lastname'] ?? ''}";
            _village = userDoc['village'] ?? '';
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  // Fetch followers and following counts from Firestore
  Future<void> _fetchFollowCounts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String phoneNumber = prefs.getString('phonenumber') ?? '';

      if (phoneNumber.isNotEmpty) {
        DocumentSnapshot followersDoc =
        await FirebaseFirestore.instance.collection(phoneNumber).doc('followers').get();
        DocumentSnapshot followingDoc =
        await FirebaseFirestore.instance.collection(phoneNumber).doc('following').get();

        setState(() {
          _followersCount = followersDoc['followerscount'] ?? 0;
          _followingCount = followingDoc['followingcount'] ?? 0;
        });
      }
    } catch (e) {
      print("Error fetching follow counts: $e");
    }
  }

  // Fetch my posts from Firestore
  Future<void> _fetchMyPosts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String phoneNumber = prefs.getString('phonenumber') ?? '';

      if (phoneNumber.isNotEmpty) {
        DocumentSnapshot sendDoc =
        await FirebaseFirestore.instance.collection(phoneNumber).doc('send').get();
        if (sendDoc.exists) {
          List<String> timestamps = List<String>.from(sendDoc['timestamp'] ?? []);
          setState(() {
            _myPosts = timestamps;
            print(".......${_myPosts}........");
          });
        }
      }
    } catch (e) {
      print("Error fetching my posts: $e");
    }
  }

  // Fetch liked posts from Firestore
  Future<void> _fetchLikedPosts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String phoneNumber = prefs.getString('phonenumber') ?? '';

      if (phoneNumber.isNotEmpty) {
        DocumentSnapshot likeDoc =
        await FirebaseFirestore.instance.collection(phoneNumber).doc('like').get();
        if (likeDoc.exists) {
          List<String> timestamps = List<String>.from(likeDoc['timestamp'] ?? []);
          setState(() {
            _likedPosts = timestamps;
            print(".......${_likedPosts}........");
          });
        }
      }
    } catch (e) {
      print("Error fetching liked posts: $e");
    }
  }

  // Fetch post details from Firestore by timestamp
  Future<DocumentSnapshot> _fetchPostDetails(String timestamp) async {
    try {
      DocumentSnapshot postDoc =
      await FirebaseFirestore.instance.collection('news').doc(timestamp).get();
      return postDoc;
    } catch (e) {
      print("Error fetching post details: $e");
      throw e; // Throw the error to handle it properly
    }
  }
  int _currentPageIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: _profilePhotoUrl.isNotEmpty
                    ? NetworkImage(_profilePhotoUrl)
                    : NetworkImage(
                    "https://img.icons8.com/?size=100&id=mj4zUKpD4IjJ&format=png&color=000000"),
              ),
              SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _village,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Followers: $_followersCount',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(width: 20),
                      Text(
                        'Following: $_followingCount',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.0),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _currentPageIndex = 0;
                  });
                },
                icon: Icon(Icons.menu_book,
                    color: _currentPageIndex == 0 ? Colors.blue : Colors.grey),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _currentPageIndex = 1;
                  });
                },
                icon: Icon(Icons.favorite,
                    color: _currentPageIndex == 1 ? Colors.blue : Colors.grey),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 20),
          // My Posts and Liked Posts Section
          Expanded(
            child: PageView(
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              children: [
                // My Posts
                ListView.builder(
                  itemCount: _myPosts.length,
                  itemBuilder: (context, index) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: _fetchPostDetails(_myPosts[index]),
                      builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
                          return Center(child: Text('Error fetching post details'));
                        } else {
                          var post = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                          if (post.isEmpty) {
                            return Center(child: Text('No posts'));
                          } else {
                            return Card(
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 8.0),
                                color: Colors.grey[300],
                                padding: EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post['title'] ?? '',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      post['content'] ?? '',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
                // Liked Posts
                ListView.builder(
                  itemCount: _likedPosts.length,
                  itemBuilder: (context, index) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: _fetchPostDetails(_likedPosts[index]),
                      builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
                          return Center(child: Text('Error fetching post details'));
                        } else {
                          var post = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                          if (post.isEmpty) {
                            return Center(child: Text('No posts'));
                          } else {
                            return Card(
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 8.0),
                                color: Colors.grey[300],
                                padding: EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post['title'] ?? '',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      post['content'] ?? '',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );




  }
}
