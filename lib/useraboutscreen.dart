import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vadhiyar/login_screen.dart';
import 'package:vadhiyar/news.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getUserData(String phoneNumber) async {
    DocumentSnapshot userDoc = await _db.collection('users').doc(phoneNumber).get();
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    } else {
      return {
        'profilePhotoUrl': '',
        'name': 'Unknown',
        'village': 'Unknown'
      };
    }
  }

  Future<int> getFollowersCount(String phoneNumber) async {
    DocumentSnapshot followersDoc = await _db.collection(phoneNumber).doc('followers').get();
    return followersDoc.exists ? followersDoc['followerscount'] ?? 0 : 0;
  }

  Future<int> getFollowingCount(String phoneNumber) async {
    DocumentSnapshot followingDoc = await _db.collection(phoneNumber).doc('following').get();
    return followingDoc.exists ? followingDoc['followingcount'] ?? 0 : 0;
  }

  Future<List<String>> getUserPostTimestamps(String phoneNumber) async {
    DocumentSnapshot sendDoc = await _db.collection(phoneNumber).doc('send').get();
    return sendDoc.exists ? List<String>.from(sendDoc['timestamp'] ?? []) : [];
  }

  Future<List<Map<String, dynamic>>> getUserPostsByTimestamps(List<String> timestamps) async {
    List<Map<String, dynamic>> posts = [];
    for (String timestamp in timestamps) {
      DocumentSnapshot postDoc = await _db.collection('news').doc(timestamp).get();
      if (postDoc.exists) {
        posts.add(postDoc.data() as Map<String, dynamic>);
      }
    }
    return posts;
  }

  Future<List<Map<String, dynamic>>> getUserPosts(String phoneNumber) async {
    List<String> timestamps = await getUserPostTimestamps(phoneNumber);
    return await getUserPostsByTimestamps(timestamps);
  }
  Future<bool> isFollowing(String currentUserPhoneNumber) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String targetUserPhoneNumber = prefs.getString('phonenumber') ?? 'unknown';
    DocumentSnapshot followingDoc = await _db.collection(currentUserPhoneNumber).doc('following').get();
    if (followingDoc.exists) {
      List<dynamic> following = followingDoc['following'] ?? [];
      return following.contains(targetUserPhoneNumber);
    }
    return false;
  }

  Future<void> followUser(String targetUserPhoneNumber) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String currentUserPhoneNumber = prefs.getString('phonenumber') ?? 'unknown';

    DocumentReference currentUserFollowingDoc = _db.collection(currentUserPhoneNumber).doc('following');
    DocumentReference targetUserFollowersDoc = _db.collection(targetUserPhoneNumber).doc('followers');

    await _db.runTransaction((transaction) async {
      DocumentSnapshot currentUserFollowingSnapshot = await transaction.get(currentUserFollowingDoc);
      DocumentSnapshot targetUserFollowersSnapshot = await transaction.get(targetUserFollowersDoc);

      if (currentUserFollowingSnapshot.exists && targetUserFollowersSnapshot.exists) {
        List<dynamic> currentUserFollowing = currentUserFollowingSnapshot['following'] ?? [];
        List<dynamic> targetUserFollowers = targetUserFollowersSnapshot['followers'] ?? [];

        if (!currentUserFollowing.contains(targetUserPhoneNumber)) {
          currentUserFollowing.add(targetUserPhoneNumber);
          targetUserFollowers.add(currentUserPhoneNumber);

          transaction.update(currentUserFollowingDoc, {
            'following': FieldValue.arrayUnion([targetUserPhoneNumber]),
            'followingcount': FieldValue.increment(1)
          });
          transaction.update(targetUserFollowersDoc, {
            'followers': FieldValue.arrayUnion([currentUserPhoneNumber]),
            'followerscount': FieldValue.increment(1)
          });
        }
      } else {
        transaction.set(currentUserFollowingDoc, {
          'following': [targetUserPhoneNumber],
          'followingcount': 1
        }, SetOptions(merge: true));
        transaction.set(targetUserFollowersDoc, {
          'followers': [currentUserPhoneNumber],
          'followerscount': 1
        }, SetOptions(merge: true));
      }
    });
  }

  Future<void> unfollowUser(String targetUserPhoneNumber) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String currentUserPhoneNumber = prefs.getString('phonenumber') ?? 'unknown';

    DocumentReference currentUserFollowingDoc = _db.collection(currentUserPhoneNumber).doc('following');
    DocumentReference targetUserFollowersDoc = _db.collection(targetUserPhoneNumber).doc('followers');

    await _db.runTransaction((transaction) async {
      DocumentSnapshot currentUserFollowingSnapshot = await transaction.get(currentUserFollowingDoc);
      DocumentSnapshot targetUserFollowersSnapshot = await transaction.get(targetUserFollowersDoc);

      if (currentUserFollowingSnapshot.exists && targetUserFollowersSnapshot.exists) {
        List<dynamic> currentUserFollowing = currentUserFollowingSnapshot['following'] ?? [];
        List<dynamic> targetUserFollowers = targetUserFollowersSnapshot['followers'] ?? [];

        if (currentUserFollowing.contains(targetUserPhoneNumber)) {
          currentUserFollowing.remove(targetUserPhoneNumber);
          targetUserFollowers.remove(currentUserPhoneNumber);

          transaction.update(currentUserFollowingDoc, {
            'following': FieldValue.arrayRemove([targetUserPhoneNumber]),
            'followingcount': FieldValue.increment(-1)
          });
          transaction.update(targetUserFollowersDoc, {
            'followers': FieldValue.arrayRemove([currentUserPhoneNumber]),
            'followerscount': FieldValue.increment(-1)
          });
        }
      }
    });
  }
}

class ProfileScreen extends StatefulWidget {
  final String phoneNumber;

  ProfileScreen({required this.phoneNumber});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
 late  Future<bool> _isfollow;
 late  bool _isfollowbutton;
  final FirestoreService _firestoreService = FirestoreService();
  late Future<Map<String, dynamic>> userData;
  late Future<int> followersCount;
  late Future<int> followingCount;

  @override
  void initState() {
    super.initState();
    userData = _firestoreService.getUserData(widget.phoneNumber);
    followersCount = _firestoreService.getFollowersCount(widget.phoneNumber);
    followingCount = _firestoreService.getFollowingCount(widget.phoneNumber);
    _isfollow= _firestoreService.isFollowing(widget.phoneNumber);
    print("============>>>>>>?/${_isfollow}");
  _setFollowButtonState();
  }
 Future<void> _setFollowButtonState() async {
   bool isFollow = await _isfollow;
   setState(() {
     _isfollowbutton = isFollow;
     print("${_isfollowbutton}");
   });
 }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: FutureBuilder(
        future: Future.wait([userData, followersCount, followingCount]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            Map<String, dynamic> userData = snapshot.data![0] ?? {};
            int followersCount = snapshot.data![1] ?? 0;
            int followingCount = snapshot.data![2] ?? 0;

            String profilePhotoUrl = userData['profilephoto'] ?? '';
            String name = "${userData['surname'] ?? ''} ${userData['name'] ?? ''} ${userData['lastname'] ?? ''}";
            String village = userData['village'] ?? 'Unknown';

            return SingleChildScrollView(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: profilePhotoUrl.isNotEmpty
                        ? NetworkImage(profilePhotoUrl)
                        : NetworkImage(
                        "https://img.icons8.com/?size=100&id=6oAufRlrYpcN&format=png&color=000000") as ImageProvider,
                  ),
                  SizedBox(height: 10),
                  Text(
                    name,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    village,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async{

                      setState(() {
                        _isfollowbutton = !_isfollowbutton;
                      });
                      if(_isfollowbutton == true)
                        await _firestoreService.followUser(widget.phoneNumber);
                      else
                        await _firestoreService.unfollowUser(widget.phoneNumber);
                    },
                    child: _isfollowbutton
                        ? Text(
                      'Unfollow',
                      style: TextStyle(color: Colors.blue),
                    )
                        : Text(
                      'Follow',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: _isfollowbutton? Colors.white : Colors.blue,
                      side: BorderSide(color: Colors.blue),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            '$followersCount',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text('Followers'),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '$followingCount',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text('Following'),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Divider(),
                  SizedBox(height: 10),
                  Text(
                    'પોસ્ટ્સ',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  PostsWidget(phoneNumber: widget.phoneNumber)
                  // Add a widget to display user's posts here
                  // For example, a GridView for photos or a ListView for text posts
                ],
              ),
            );
          }
        },
      ),
    );
  }
}



class PostsWidget extends StatelessWidget {
  final String phoneNumber;


  PostsWidget({required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    final FirestoreService _firestoreService = FirestoreService();

    return FutureBuilder(
      future: _firestoreService.getUserPosts(phoneNumber),
      builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No posts found.'));
        } else {
          List<Map<String, dynamic>> posts = snapshot.data!;

          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> post = posts[index];
              String content = post['content'] ?? '';
              String title = post['title'] ?? '';

              return GestureDetector(
                onTap: (){
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => FullArticleScreen(timestamp: post['timestamp'])));
                },
                child: Card(
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          title,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          content,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
}
