import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../pages/activity_feed.dart';
import '../pages/create_account.dart';
import '../pages/profile.dart';
import '../pages/search.dart';
import '../pages/timeline.dart';
import '../pages/upload.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final StorageReference storageRef = FirebaseStorage.instance.ref();
final usersRef = Firestore.instance.collection('users');
final postRef = Firestore.instance.collection('posts');
final commentsRef = Firestore.instance.collection('comments');
final activityFeedRef = Firestore.instance.collection('feed');
final followersRef = Firestore.instance.collection('followers');
final followingRef = Firestore.instance.collection('following');
final timelineRef = Firestore.instance.collection('timeline');
final DateTime timestamp = DateTime.now();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _scaffoldkey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  bool isAuth = false;
  int pageIndex = 0;
  PageController pageController;



  @override
  void initState() {
    super.initState();
    pageController = PageController();
    //detects when user signed in
    googleSignIn.onCurrentUserChanged.listen((account) {
      handelSignIn(account);
    }, onError: (err) {
      print('Error signing in : $err');
    });
    //Reauthenticate user when app is opened
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handelSignIn(account);
    }).catchError((err) {
      print('Error signing in : $err');
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  handelSignIn(GoogleSignInAccount account) async {
    if (account != null) {
      await createUserInFirestore();
      setState(() {
        isAuth = true;
      });
      configurePushNotifications();
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  configurePushNotifications(){
    final GoogleSignInAccount user = googleSignIn.currentUser;
    if(Platform.isIOS) getiOSPermission();

    _firebaseMessaging.getToken().then((token)  {
      print("Firebase messaging token : $token \n");
      usersRef
        .document(user.id)
        .updateData({"androidNotificationToken": token});
    });

    _firebaseMessaging.configure(
//      onLaunch: (Map<String, dynamic> message) async{},
//    onResume: (Map<String, dynamic> message) async{},
    onMessage: (Map<String, dynamic> message) async{
      print("on message: $message\n");
      final String receipientId = message['data']['recipient'];
    final String body = message['notification']['body'];
    if(receipientId == user.id){
      print("Notification shown!");
      SnackBar snackBar = SnackBar(content: Text(body, overflow: TextOverflow.ellipsis,),);
      _scaffoldkey.currentState.showSnackBar(snackBar);
    }
    else{
      print("Notification not shown");
    }
    },

    );
  }

  getiOSPermission(){
    _firebaseMessaging.requestNotificationPermissions(IosNotificationSettings(alert: true, badge: true, sound: true));
    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      print("Settings registered: $settings");
    });
  }

  createUserInFirestore() async {
    // 1) check if user exists in users collection in database(according to id)
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.document(user.id).get();

    // 2) if the user dose'nt exist, then we want to take hem to the create account page
    if (!doc.exists) {
      final username = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));
      // 3) get username from create account, use it to make new user document in users collection
      usersRef.document(user.id).setData({
        'id': user.id,
        'username': username,
        'photoUrl': user.photoUrl,
        'email': user.email,
        'displayName': user.displayName,
        'bio': '',
        'timestamp': timestamp,
      });
      // MAKE THE NEW USER THEIR OWN FOLLOWER (TO INCLUDE THEIR POST IN THEIR TIMELINE)
      await followersRef
          .document(user.id)
          .collection("userFollowers")
          .document(user.id)
          .setData({});

      doc = await usersRef.document(user.id).get();
    }
    currentUser = User.fromDocument(doc);
    print(currentUser);
    print(currentUser.username);
  }

  login() {
    googleSignIn.signIn();
  }

  logout() {
    googleSignIn.signOut();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      key: _scaffoldkey,
      body: PageView(
        children: <Widget>[
          Timeline(currentUser: currentUser),
          Search(),
          Upload(currentUser: currentUser),
          ActivityFeed(),
          Profile(profileId: currentUser?.id),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: pageIndex,
        onTap: onTap,
        activeColor: Theme.of(context).primaryColor,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.whatshot)),
          BottomNavigationBarItem(icon: Icon(Icons.search)),
          BottomNavigationBarItem(
              icon: Icon(
            Icons.photo_camera,
            size: 35.0,
          )),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active)),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle)),
        ],
      ),
    );
  }

  onTap(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Theme.of(context).accentColor,
            Theme.of(context).primaryColor,
          ],
        )),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'FlutterGram',
              style: TextStyle(
                fontFamily: 'Signatra',
                fontSize: 90.0,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: login,
              child: Container(
                width: 260.0,
                height: 60.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/google_signin_button.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
