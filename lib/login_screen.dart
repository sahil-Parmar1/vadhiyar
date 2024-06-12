import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vadhiyar/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'news.dart';

String? phonenumber;
class UserDataInputScreen extends StatefulWidget {
  @override
  _UserDataInputScreenState createState() => _UserDataInputScreenState();
}
//getvillage suggestion
Future<List<String>> _getVillageSuggestions(String query) async {
  final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('village').get();
  final List<String> villages = snapshot.docs.map((doc) => doc.id).toList();

  // Filter villages based on the query
  List<String> filteredVillages = villages.where((village) => village.toLowerCase().startsWith(query.toLowerCase())).toList();
  print("$filteredVillages");
  return filteredVillages;
}

class _UserDataInputScreenState extends State<UserDataInputScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedVillage;



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
        await saveUserInformation(_nameController.text, _phoneController.text,
            _surnameController.text, _lastNameController.text,
            _selectedVillage??'');
        await incrementVillagePopulation(_selectedVillage);
        //updateing the buttons
        List<String> buttons=[];
        buttons.add('all');
        buttons.add("$_selectedVillage");

        print("buttons on login =>$buttons");
        SharedPreferences got= await SharedPreferences.getInstance();
        await got.setStringList('buttons', buttons);
        //end
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SignInScreen()),
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
          await saveUserInformation(_nameController.text, _phoneController.text,
              _surnameController.text, _lastNameController.text,
              _selectedVillage??'');
          await incrementVillagePopulation(_selectedVillage);
          //updateing the buttons
          List<String> buttons=[];
          buttons.add('all');
          buttons.add("$_selectedVillage");

          print("buttons on login =>$buttons");
          SharedPreferences got= await SharedPreferences.getInstance();
          await got.setStringList('buttons', buttons);
          //end
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SignInScreen()),
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
          await saveUserInformation(_nameController.text, _phoneController.text,
              _surnameController.text, _lastNameController.text,
              _selectedVillage??'');
          await incrementVillagePopulation(_selectedVillage);
          //updateing the buttons
          List<String> buttons=[];
          buttons.add('all');
          buttons.add("$_selectedVillage");
          print("buttons on login =>$buttons");
          SharedPreferences got= await SharedPreferences.getInstance();
          await got.setStringList('buttons', buttons);
          //end
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SignInScreen()),
          );
        }
      }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: Center(
        child: Text(
            'વઢીયાર',
            style: TextStyle(color: Colors.white),
                 ),
            ),
            backgroundColor: Colors.blue,
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
                    'https://img.icons8.com/officel/80/edit-user-male.png',
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
                    Center(
                                      child: ElevatedButton(
                                        onPressed: _saveUserDataAndNavigate,
                                        child: Text(
                                          'સબમિટ કરો',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          primary: Colors.greenAccent,
                                          textStyle: TextStyle(
                                            fontSize: 18,
                                          ),
                                        ),
                                    ),
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
}




class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isSigningIn = true; // Set to true to initiate sign-in automatically

  @override
  void initState() {
    super.initState();
    _signInWithGoogle(); // Initiate sign-in when screen is initialized
  }

  Future<void> _signInWithGoogle() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final GoogleSignIn _googleSignIn = GoogleSignIn();

    try {
      // Check if a user is already signed in
      if (_auth.currentUser == null) {
        // Sign in with Google
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser != null) {
          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          // Sign in to Firebase with Google credentials
          await _auth.signInWithCredential(credential);

          // Navigate to HomeScreen after successful sign-in
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
      } else {
        // If already signed in, directly navigate to HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      print("Failed to sign in with Google: $e");
    } finally {
      // Set _isSigningIn to false once sign-in process is complete
      setState(() {
        _isSigningIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: _isSigningIn
            ? CircularProgressIndicator()
            : Text('Sign-in complete!'), // Display this when sign-in process is complete
      ),
    );
  }
}



//save user info in device storage


Future<void> saveUserInformation(String name, String phonenumber, String surname, String lastname, String village) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('name', name);
  await prefs.setString('phonenumber', phonenumber);
  await prefs.setString('surname', surname);
  await prefs.setString('lastname', lastname);
  await prefs.setString('village', village);
}
Future<Map<String, String?>> getUserInformation() async {

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  phonenumber=prefs.getString('phonenumber');
  return {
    'name': prefs.getString('name'),
    'phonenumber': prefs.getString('phonenumber'),
    'surname': prefs.getString('surname'),
    'lastname': prefs.getString('lastname'),
    'village': prefs.getString('village'),
  };
}

