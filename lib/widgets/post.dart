import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/custom_image.dart';
import 'package:fluttershare/widgets/progress.dart';

class Post extends StatefulWidget {

  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;

  Post({this.postId, this.ownerId, this.username, this.location, this.description, this.mediaUrl, this.likes});

  factory Post.fromDocument(DocumentSnapshot doc){
    return Post(
    postId: doc['postId'],
    ownerId: doc['ownerId'],
    username: doc['username'],
    description: doc['description'],
    mediaUrl: doc['mediaUrl'],
    location: doc['location'],
    likes: doc['likes'],
    );
}

  int getLikeCount(likes){
    if(likes == null)
      return 0;
    int count = 0;
    likes.values.forEach((val){
      if(val == true){
        count += 1;
      }
    });
    return count;
  }


  @override
  _PostState createState() => _PostState(
      postId: this.postId,
      ownerId: this.ownerId,
      username: this.username,
      location: this.location,
      description: this.description,
      mediaUrl: this.mediaUrl,
      likes: this.likes,
      likeCount: getLikeCount(this.likes),
  );
}

class _PostState extends State<Post> {

  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  Map likes;
  int likeCount;

  _PostState({this.postId, this.ownerId, this.username, this.location, this.description, this.mediaUrl, this.likes, this.likeCount});

  buildPostHeader() {
    return FutureBuilder(
      future: usersRef.document(ownerId).get(),
      builder: (context, snapshot){
        if(!snapshot.hasData){
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user.photoUrl != null ? CachedNetworkImageProvider(user.photoUrl) : AssetImage('assets/images/user.png'),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            onTap: () => print('ShowProfile'),
            child: Text(
              user.username,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Text(location),
          trailing: IconButton(
            onPressed: ()=> print('deleting post'),
            icon: Icon(Icons.more_vert),
          ),
        );
      },
    );
  }

  buildPostImage(){
   return GestureDetector(
     onDoubleTap: ()=> print('liking post'),
     child: Stack(
       alignment: Alignment.center,
       children: [
         cachedNetworkImage(mediaUrl),
       ],
     ),
   ) ;
  }

  buildPostFooter(){
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 40.0, left: 20.0),
            ),
            GestureDetector(
              onTap: ()=> print('liking post'),
              child: Icon(
                Icons.favorite_border,
                size: 28.0,
                color: Colors.pink,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 20.0),
            ),
            GestureDetector(
              onTap: ()=> print('commenting post'),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 28.0,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
        Row(
          children: [
          Container(
            margin: EdgeInsets.only(left: 20.0),
            child: Text(
              '$likeCount likes',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                '$username:',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 10.0,),
            Expanded(
              child: Text(
                description,
              ),
            ),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
      ],
    );
  }
}
