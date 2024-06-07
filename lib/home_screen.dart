import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:async';
import 'news.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "send.dart";
import 'package:flutter_typeahead/flutter_typeahead.dart';

int count=0;
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PageController _pageController = PageController();
  int _selectedIndex = 0;
   String? profilephotourl;
  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onItemTapped(int index) async{
    _pageController.jumpToPage(index);
    await _onRefresh();
  }
  //show pop up
  Future<void> _fetchShowPopupFromFirebase() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String phoneNumber = prefs.getString('phonenumber') ?? '';

    // Fetch the value from Firestore
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('owner')
          .where('show', isEqualTo: true)
          .limit(1)
          .get();

      // Update showPopup based on the value from Firestore
      if (snapshot.docs.isNotEmpty) {
        // If show is true, check if phone number is in views array
        dynamic data = snapshot.docs.first.data();
        List<dynamic> views = (data['viewer'] as List<dynamic>?) ?? [];
        if (!views.contains(phoneNumber)) {
          // Phone number not in views array, show popup
          _showPopup(context,data['message'],data['content'],phoneNumber);
        }
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  void _showPopup(BuildContext context,String link,String content,String phoneNumber) async{
    QuerySnapshot querySnapshot =
    await FirebaseFirestore.instance.collection('owner').get();

    // Loop through each document and update the 'viewer' field
    querySnapshot.docs.forEach((doc) async {
      await doc.reference.update({
        'viewer': FieldValue.arrayUnion([phoneNumber]),
      });
    });
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$link'),
          content: Text('$content'),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  @override
  void initState()
  {
    super.initState();
    _fetchShowPopupFromFirebase();

  }
  Future<void> _onRefresh() async {
    // Simulate a network call
    await Future.delayed(Duration(milliseconds: 10));
    // Update state or perform any necessary actions here
    profilephotourl=await getprofilephoto();
    setState(() {
      count++;

      print("===>>$profilephotourl");
    });
    await deleteExpiredDocuments();
    print('Page refreshed');
  }
  @override
  Widget build(BuildContext context) {


    return Scaffold(

      appBar: AppBar(
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
        title: Text(
          'વઢીયાર',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(onPressed: (){

        }, icon: Icon(Icons.chat,color: Colors.white)),
          TextButton(
            onPressed: ()async{

              _showUserProfile(context);

            },
            child:  Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.green, // Border color
                  width: 3, // Border width
                ),
              ),
              child: CircleAvatar(
                radius: 19, // Adjust the radius as needed
                backgroundImage: profilephotourl != null && profilephotourl!.isNotEmpty
                    ? NetworkImage(profilephotourl??'')
                    : null,
                child: profilephotourl == null || profilephotourl!.isEmpty
                    ? Icon(Icons.person, size: 30) // Adjust the icon size as needed
                    : null,
              )

            ),),

        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: <Widget>[
          _buildPage(0),
          _buildPage(1),

        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? null
          : FloatingActionButton(
              onPressed: () {
               showMessageInput(context,_selectedIndex);
            },
            backgroundColor: Colors.green,
            child: Icon(
              Icons.send,
              color: Colors.white,
            ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper),
            label: 'સમાચાર',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.send_and_archive),
            label: 'મારી પોસ્ટ',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
  void _showUserProfile(BuildContext context) async {
    Map<String, String?> userInfo = await getUserInformation();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    DocumentSnapshot<Map<String, dynamic>> userSnapshot =
    await FirebaseFirestore.instance.collection('users').doc(prefs.getString('phonenumber')).get();

    showModalBottomSheet(
      context: context,
      builder: (context){
      return StatefulBuilder(
          builder:(BuildContext context,StateSetter setState)
          {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          userSnapshot.data()?['profilephoto'] != null
                              ? CircleAvatar(
                            radius: 60,
                            backgroundImage: NetworkImage(
                                userSnapshot.data()?['profilephoto'] ?? ''),
                          )
                              : CircleAvatar(
                            radius: 60,
                            child: Icon(Icons.person),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0.005,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () async {
                                  // Implement the function to change the profile photo
                                  setState((){
                                    pickImageAndUpload(context);
                                  });
                                  setState((){});
                                },
                                icon: Icon(Icons.add_a_photo, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 20),
                    ],
                  ),
                  SizedBox(height: 20),
                  ListTile(
                    title: Text(
                      '${userInfo['surname'] ?? 'N/A'} ${userInfo['name'] ??
                          'N/A'} ${userInfo['lastname'] ?? 'N/A'}',
                      style: TextStyle(color: Colors.blue, fontSize: 20),
                    ),
                  ),
                  ListTile(
                    title: Text('ફોન નંબર'),
                    subtitle: Text(userInfo['phonenumber'] ?? 'N/A'),
                  ),
                  ListTile(
                    title: Text('ગામ'),
                    subtitle: Text(userInfo['village'] ?? 'N/A'),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                        },
                        child: Text('Cancel'),
                      ),
                      SizedBox(width: 100),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(context,
                          MaterialPageRoute(builder: (context)=>Update())
                          );
                          // Implement the function to update the profile information
                        },
                        child: Text('Update'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }


  Widget _buildPage(int index) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: custome(index:index),
    );
  }


}



//for image
void pickImageAndUpload(BuildContext context) async {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    File image = File(pickedFile.path);
    UploadTask task = await uploadImageToFirebase(image, _auth, _firestore);
    await showUploadProgress(context, task);
    String? url= await getDownloadURL(task);
    await saveImageURLToFirestore(url??'');
  }
}

Future<UploadTask> uploadImageToFirebase(
    File image, FirebaseAuth auth, FirebaseFirestore firestore) async{
  final SharedPreferences prefs= await SharedPreferences.getInstance();
  final storageRef = FirebaseStorage.instance
      .ref()
      .child('user_profiles/${prefs.getString('phonenumber')}/profilephoto.jpg');

  UploadTask task = storageRef.putFile(image);

  return task;
}

Future<void> showUploadProgress(BuildContext context, UploadTask task) async {
  Completer<void> completer = Completer<void>();

  showDialog(
    context: context,
    barrierDismissible: false, // Prevent users from dismissing the dialog
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20,),
                  Text(
                    'Uploading file',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              StreamBuilder<TaskSnapshot>(
                stream: task.snapshotEvents,
                builder: (context, snapshot) {
                  double progress = snapshot.hasData
                      ? snapshot.data!.bytesTransferred /
                      snapshot.data!.totalBytes
                      : 0.0;
                  return LinearProgressIndicator(value: progress);
                },
              ),
              SizedBox(height: 20),
              Text(
                'Please wait while we upload your file...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    },
  );

  task.whenComplete(() {
    // Close the dialog after the upload is complete
    Navigator.of(context).pop();
    completer.complete();
  });

  return completer.future;
}

Future<String?> getDownloadURL(UploadTask task) async {
  try {
    await task;
    String downloadURL =
    await task.snapshot.ref.getDownloadURL();
    return downloadURL;
  } catch (e) {
    print('Error uploading file: $e');
    return null;
  }
}

Future<void> saveImageURLToFirestore(String url) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final userRef =
  _firestore.collection('users').doc(prefs.getString('phonenumber'));
  await userRef.set({'profilephoto': url}, SetOptions(merge: true));
}



Future<String?> getprofilephoto() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  phonenumber = prefs.getString('phonenumber');
  if (phonenumber != null) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    DocumentSnapshot<Map<String, dynamic>> userSnapshot =
    await _firestore.collection('users').doc(phonenumber).get();
    print("--->>>>>>$phonenumber");
    return (userSnapshot.data()?['profilephoto']).toString();

  }
  else
    return null;
}



class Update extends StatefulWidget {
  @override
  _UpdateState createState() => _UpdateState();
}
class _UpdateState extends State<Update> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedVillage;

//getvillage suggestion
  Future<List<String>> _getVillageSuggestions(String query) async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('village').get();
    final List<String> villages = snapshot.docs.map((doc) => doc.id).toList();

    // Filter villages based on the query
    List<String> filteredVillages = villages.where((village) => village.toLowerCase().startsWith(query.toLowerCase())).toList();
    print("$filteredVillages");
    return filteredVillages;
  }

  Future<void> _saveUserDataAndNavigate() async {

    if (_formKey.currentState!.validate()) {
      final usersRef = FirebaseFirestore.instance.collection('users');
      if (_selectedVillage != null) {
        // selected village
        await usersRef.doc(_phoneController.text).set(
          {
            'surname': _surnameController.text,
            'lastname': _lastNameController.text,
            'village': _selectedVillage,
            'name': _nameController.text,
            'phonenumber': _phoneController.text,
          },
          SetOptions(merge: true), // Use SetOptions to merge the data
        );
        await decrementVillagePopulation();
        await saveUserInformation(_nameController.text, _phoneController.text,
            _surnameController.text, _lastNameController.text,
            _selectedVillage??'');

        await incrementVillagePopulation(_selectedVillage);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        // Village not selected from suggestions
        final villageRef = FirebaseFirestore.instance.collection('village').doc(_villageController.text);
        final villageDoc = await villageRef.get();
        if (villageDoc.exists) {
          // Village already exists in Firestore
          _selectedVillage = _villageController.text.trim();
          await usersRef.doc(_phoneController.text).set(
            {
              'surname': _surnameController.text,
              'lastname': _lastNameController.text,
              'village': _selectedVillage,
              'name': _nameController.text,
              'phonenumber': _phoneController.text,
            },
            SetOptions(merge: true), // Use SetOptions to merge the data
          );
          await decrementVillagePopulation();
          await saveUserInformation(_nameController.text, _phoneController.text,
              _surnameController.text, _lastNameController.text,
              _selectedVillage??'');

          await incrementVillagePopulation(_selectedVillage);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          // Village doesn't exist in Firestore, add it
          await villageRef.set({'people': 0});
          _selectedVillage = _villageController.text.trim();
          await usersRef.doc(_phoneController.text).set(
            {
              'surname': _surnameController.text,
              'lastname': _lastNameController.text,
              'village': _selectedVillage,
              'name': _nameController.text,
              'phonenumber': _phoneController.text,
            },
            SetOptions(merge: true), // Use SetOptions to merge the data
          );
          await decrementVillagePopulation();
          await saveUserInformation(_nameController.text, _phoneController.text,
              _surnameController.text, _lastNameController.text,
              _selectedVillage??'');

          await incrementVillagePopulation(_selectedVillage);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
      }

    }
  }

  Future<void> decrementVillagePopulation() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? villageName = prefs.getString('village');

    if (villageName == null || villageName.isEmpty) {
      print('No village name stored in preferences.');
      return;
    }

    final villageRef = FirebaseFirestore.instance.collection('village').doc(villageName);
    final villageDoc = await villageRef.get();

    if (villageDoc.exists) {
      final currentPeople = villageDoc.data()?['people'] ?? 0;
      print('Current population for $villageName: $currentPeople');

      if (currentPeople > 0) {
        villageRef.update({
          'people': FieldValue.increment(-1),
        }).then((_) {
          print('Population decremented successfully.');
        }).catchError((error) {
          print('Error updating population: $error');
        });
      } else {
        print('Population is already zero or negative, not decrementing.');
      }
    } else {
      print('Village document does not exist.');
    }
  }

  Future<void> incrementVillagePopulation(String? villageName) async {
    final villageRef = FirebaseFirestore.instance.collection('village').doc(villageName);
    final villageDoc = await villageRef.get();

    if (villageDoc.exists) {
      villageRef.update({
        'people': FieldValue.increment(1),
      });
    } else {
      // If the village doesn't exist, create it with an initial population of 1
      villageRef.set({'people': 1});
    }
  }

  void updatefirst()async
  {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('name') ?? '';
      _surnameController.text = prefs.getString('surname') ?? '';
      _lastNameController.text = prefs.getString('lastname') ?? '';
      _phoneController.text = prefs.getString('phonenumber') ?? '';
      _villageController.text = prefs.getString('village') ?? '';
      _selectedVillage = prefs.getString('village') ?? '';

    });
  }
  @override
  void initState()
  {
    super.initState();
    updatefirst();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'પ્રોફાઇલ અપડેટ',
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
          onPressed: (){
            _showLogoutConfirmationDialog(context);
          },
           icon: Icon(Icons.logout,color: Colors.white,),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 150,
                child: Image.network(
                  'https://img.icons8.com/ios/50/update-file.png',
                  errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.person,
                        size: 100,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          _selectedVillage = suggestion;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'કૃપા કરીને તમારું ગામ દાખલ કરો';
                        }
                        // You can add validation rules for village here
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _surnameController,
                      decoration: InputDecoration(
                        labelText: 'અટક',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'કૃપા કરીને તમારું અટક દાખલ કરો';
                        }
                        // You can add validation rules for surname here
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'નામ',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'કૃપા કરીને તમારું નામ દાખલ કરો';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: 'પિતાનું નામ',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'કૃપા કરીને તમારું પિતાનું નામ દાખલ કરો';
                        }
                        // You can add validation rules for last name here
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'ફોન નંબર',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 10,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'કૃપા કરીને તમારો ફોન નંબર દાખલ કરો.';
                        }
                        if (value.length != 10) {
                          return 'ફોન નંબર 10 અંકોનો હોવો જોઈએ.';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                            onPressed: (){
                              Navigator.pop(context);
                            }, child: Text("Cancel")),
                        ElevatedButton(
                          onPressed: _saveUserDataAndNavigate,
                          child: Text(
                            'સબમિટ કરો',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.green,
                            textStyle: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _lastNameController.dispose();
    _surnameController.dispose();
    _villageController.dispose();
    super.dispose();
  }
  //sign out
  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('શું તમે ખરેખર લોગઆઉટ કરવા માંગો છો'),
          actions: [

            TextButton(
              child: Text('હા,હું ઈચ્છું છું'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _logout(context); // Perform logout
              },
            ),
            TextButton(
              child: Text('Cancel',style: TextStyle(color: Colors.green,fontSize: 20),),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    // Log out from Firebase
    await FirebaseAuth.instance.signOut();

    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Navigate to login screen or home screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => UserDataInputScreen()),
          (Route<dynamic> route) => false,
    );
  }
}
