import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/presentation/screens/post_card.dart';
import 'package:frontend/presentation/screens/scrollable_tab.dart';
import 'package:provider/provider.dart';

import '../../data/models/user_profile.dart';
import '../view_models/user_view_model.dart';

class ProfilePage extends StatefulWidget {

  const ProfilePage({
    super.key
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<PostCard> myAllPosts = const [];

  final List<PostCard> myPhotoPosts = const [];

  final List<PostCard> myVideoPosts = const []; // chưa có video

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = FirebaseAuth.instance.currentUser;
      final uid = currentUser?.uid;
      print(uid);
      if (uid != null) {
        final vm = Provider.of<UserViewModel>(context, listen: false);
        vm.loadProfile(uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(121, 171, 222, 1),
      body: Consumer<UserViewModel>(
          builder: (context, vm, _){
            final profile = vm.profile;
            return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    // Header có thể ẩn khi cuộn
                    SliverAppBar(
                      automaticallyImplyLeading: false,
                      expandedHeight: screenHeight * 0.38,
                      pinned: false, // set true nếu muốn giữ 1 phần nhỏ lại
                      floating: false,
                      flexibleSpace: LayoutBuilder(
                        builder: (context, constraints) {
                          // Tính toán tỉ lệ ẩn/hiện để làm hiệu ứng mờ dần
                          double opacity = 1.0;
                          if (constraints.maxHeight < screenHeight * 0.45) {
                            opacity = (constraints.maxHeight - kToolbarHeight) /
                                (screenHeight * 0.45 - kToolbarHeight);
                            opacity = opacity.clamp(0.0, 1.0);
                          }

                          return FlexibleSpaceBar(
                              background: Column(
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          height: screenHeight * 0.3,
                                          decoration: const BoxDecoration(
                                            image: DecorationImage(
                                              image: AssetImage('assets/images/mountain.png'),
                                              fit: BoxFit.cover,
                                              colorFilter: ColorFilter.mode(
                                                Color.fromRGBO(121, 171, 222, 100),
                                                BlendMode.darken,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: screenHeight * 0.03,
                                          left: 15,
                                          child: IconButton(
                                            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                                            onPressed: ()=> Navigator.pushNamed(context, '/home'),
                                          ),
                                        ),
                                        Positioned(
                                          top: screenHeight * 0.2,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            width: double.infinity,
                                            height: screenHeight,
                                            padding: EdgeInsets.only(
                                              top: screenHeight * 0.04,
                                              bottom: screenHeight * 0.02,
                                            ),
                                            decoration: const BoxDecoration(
                                              color: Color.fromRGBO(121, 171, 222, 100),
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(40),
                                                topRight: Radius.circular(40),
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                  spacing: screenWidth * 0.45,
                                                  children: [
                                                    _FollowInfo(label: "Followers", count: profile != null
                                                        ? "${profile.followersCount}"
                                                        : "0"),
                                                    _FollowInfo(label: "Following", count: profile != null
                                                        ? "${profile.followingCount}"
                                                        : "0"),
                                                  ],
                                                ),
                                                const SizedBox(height: 40),
                                                Text(
                                                  profile != null ? profile.bio : "blank tittle",
                                                  style:
                                                  TextStyle(fontSize: 20, color: Colors.black54),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        Positioned(
                                          top: screenHeight * 0.14,
                                          left: (screenWidth / 2) - 65, // center horizontally
                                          child: Column(
                                            children: [
                                              Container(
                                              height: 130,
                                              width: 130,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                image:  DecorationImage(
                                                  image: profile != null
                                                      ? NetworkImage(profile.photoUrl)
                                                      : AssetImage('assets/images/man.png'),
                                                  fit: BoxFit.cover,
                                                ),
                                                border: Border.all(color: Colors.white, width: 3),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withAlpha(150),
                                                    spreadRadius: 5,
                                                    blurRadius: 7,
                                                  ),
                                                ],
                                              ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                profile != null
                                                    ? "@${profile.fullName}"
                                                    : "@Loading",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 22,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ]
                              )
                          );
                        },
                      ),
                    ),
                  ];
                },
                //Nội dung cuộn (tab view)
                body: Container(
                  constraints: BoxConstraints.expand(),
                  width: double.infinity,
                  height: double.infinity,
                  // color: const Color.fromRGBO(121, 171, 222, 1),
                  child:  Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 80),
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: Colors.black,
                          dividerColor: Colors.transparent,
                          labelColor: Colors.black,
                          unselectedLabelColor: Colors.black45,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          tabs: const [
                            Tab(text: "All"),
                            Tab(text: "Photos"),
                            Tab(text: "Videos"),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color.fromRGBO(231, 231, 231, 0.5),
                                Color.fromRGBO(121, 171, 222, 1),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Column(
                              children: [
                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      ScrollableTab(items: myAllPosts),
                                      ScrollableTab(items: myPhotoPosts),
                                      ScrollableTab(items: myVideoPosts),
                                    ],
                                  ),
                                )
                              ]
                          ),
                        ),
                      ),
                    ],
                  ),
                )
            );
          }
      )
    );
  }
}

class _FollowInfo extends StatelessWidget {
  final String label;
  final String count;

  const _FollowInfo({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(count,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        Text(label, style: const TextStyle(fontSize: 18)),
      ],
    );
  }
}