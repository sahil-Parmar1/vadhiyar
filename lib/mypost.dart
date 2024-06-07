import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vadhiyar/news.dart';

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

  Future<void> _fetchUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String phoneNumber = prefs.getString('phonenumber') ?? '';

      if (phoneNumber.isNotEmpty) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(phoneNumber)
            .get();
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

  Future<void> _fetchFollowCounts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String phoneNumber = prefs.getString('phonenumber') ?? '';

      if (phoneNumber.isNotEmpty) {
        DocumentSnapshot followersDoc = await FirebaseFirestore.instance
            .collection(phoneNumber)
            .doc('followers')
            .get();
        DocumentSnapshot followingDoc = await FirebaseFirestore.instance
            .collection(phoneNumber)
            .doc('following')
            .get();

        setState(() {
          _followersCount = followersDoc['followerscount'] ?? 0;
          _followingCount = followingDoc['followingcount'] ?? 0;
        });
      }
    } catch (e) {
      print("Error fetching follow counts: $e");
    }
  }

  Future<void> _fetchMyPosts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String phoneNumber = prefs.getString('phonenumber') ?? '';

      if (phoneNumber.isNotEmpty) {
        DocumentSnapshot sendDoc = await FirebaseFirestore.instance
            .collection(phoneNumber)
            .doc('send')
            .get();
        if (sendDoc.exists) {
          List<String> timestamps = List<String>.from(sendDoc['timestamp'] ?? []);
          setState(() {
            _myPosts = timestamps;
          });
        }
      }
    } catch (e) {
      print("Error fetching my posts: $e");
    }
  }

  Future<void> _fetchLikedPosts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String phoneNumber = prefs.getString('phonenumber') ?? '';

      if (phoneNumber.isNotEmpty) {
        DocumentSnapshot likeDoc = await FirebaseFirestore.instance
            .collection(phoneNumber)
            .doc('like')
            .get();
        if (likeDoc.exists) {
          List<String> timestamps = List<String>.from(likeDoc['timestamp'] ?? []);
          setState(() {
            _likedPosts = timestamps;
          });
        }
      }
    } catch (e) {
      print("Error fetching liked posts: $e");
    }
  }

  Future<DocumentSnapshot> _fetchPostDetails(String timestamp) async {
    try {
      DocumentSnapshot postDoc = await FirebaseFirestore.instance
          .collection('news')
          .doc(timestamp)
          .get();
      return postDoc;
    } catch (e) {
      print("Error fetching post details: $e");
      throw e;
    }
  }

  int _currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 120.0,
        title: _buildProfileInfo(),
        bottom: _buildTabBar(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: PageView(
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              children: [
                _buildPostList(_myPosts),
                _buildPostList(_likedPosts),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Padding _buildProfileInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 40,
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                _village,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Followers: $_followersCount',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(width: 20),
                  Text(
                    'Following: $_followingCount',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSize _buildTabBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(48.0),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: _buildTabBarItem(Icons.send, 0)),
            SizedBox(width: 50),
            Expanded(child: _buildTabBarItem(Icons.favorite, 1)),
          ],
        ),
      ),
    );
  }

  IconButton _buildTabBarItem(IconData icon, int index) {
    return IconButton(
      onPressed: () {
        setState(() {
          _currentPageIndex = index;
        });
      },
      icon: Icon(icon, color: _currentPageIndex == index ? Colors.blue : Colors.grey),
    );
  }

  ListView _buildPostList(List<String> posts) {
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return FutureBuilder<DocumentSnapshot>(
          future: _fetchPostDetails(posts[index]),
          builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text('No posts'));
            } else {
              var post = snapshot.data!.data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.all(10.0),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: GestureDetector(
                    onTap: (){
                      Navigator.push(context, 
                      MaterialPageRoute(builder: (context)=>FullArticleScreen(timestamp: post['timestamp']))
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post['title'] ?? '',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          post['content'] ?? '',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}
