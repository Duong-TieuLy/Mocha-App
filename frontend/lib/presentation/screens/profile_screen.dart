import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  // final String name;
  // final String backgroundImage;
  // final int followers;
  // final int following;
  // final String title;
  const ProfilePage({
    // required this.name,
    // required this.backgroundImage,
    // required this.followers,
    // required this.following,
    // required this.title,
    super.key
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      body: NestedScrollView(
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
                                      children: const [
                                        _FollowInfo(label: "Followers", count: "0"),
                                        _FollowInfo(label: "Following", count: "0"),
                                      ],
                                    ),
                                    const SizedBox(height: 40),
                                    const Text(
                                      "blank title",
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
                                      image: const DecorationImage(
                                        image: AssetImage('assets/images/man.png'),
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
                                  const Text(
                                    "@You",
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
          padding: const EdgeInsets.only(top: 10),
          decoration: const BoxDecoration(
            color: Color.fromRGBO(121, 171, 222, 1), //Giữ màu xanh này
          ),
          child:  Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 80),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.black,
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

              // TabBarView (phần nội dung cuộn)
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      _ScrollableTab(title: "No posts yet"),
                      _ScrollableTab(title: "No photos yet"),
                      _ScrollableTab(title: "No videos yet"),
                    ],
                  ),
                )
              ),
            ],
          ),
        )
      ),
    );
  }
}

class _ScrollableTab extends StatelessWidget {
  final String title;
  const _ScrollableTab({required this.title});

  @override
  Widget build(BuildContext context) {
    final List<String> items = []; // 👈 nếu rỗng thì hiện "Empty Folder"

    if (items.isEmpty) {
      return const Center(
        child: Text(
          "Empty Folder",
          style: TextStyle(
            color: Colors.black54,
            fontSize: 16,
          ),
        ),
      );
    }

    // Nếu có dữ liệu -> ListView
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text("${items[index]}"),
        ),
      ),
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