import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:frontend/presentation/screens/post_card.dart';
import 'search_screen.dart';

class MomentsPage extends StatefulWidget {
  const MomentsPage({super.key});

  @override
  State<MomentsPage> createState() => _MomentsPageState();
}

class _MomentsPageState extends State<MomentsPage> {
  final PageController _pageController = PageController();
  final List<PostCard> friendMoments = [];

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _cameraController =
          CameraController(_cameras![0], ResolutionPreset.medium);
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Moments",
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black, size: 36),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => FractionallySizedBox(
                  heightFactor: 0.9,
                  child: const SearchScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          const Icon(Icons.notifications_none, color: Colors.black, size: 36),
          const SizedBox(width: 16),
        ],
      ),
      body: PageView(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        children: [
          _buildCameraView(screenHeight),
          for (var post in friendMoments) _buildMoment(post, screenHeight),
        ],
      ),
    );
  }

  /// CAMERA VIEW THỰC TẾ
  Widget _buildCameraView(double screenHeight) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          height: screenHeight * 0.45,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(40),
            border:
            Border.all(color: const Color.fromRGBO(121, 171, 222, 1), width: 3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: CameraPreview(_cameraController!),
          ),
        ),
        const SizedBox(height: 40),
        _bottomBar(screenHeight),
      ],
    );
  }

  Widget _buildMoment(PostCard post, double screenHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          height: screenHeight * 0.45,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(40),
            border:
            Border.all(color: const Color.fromRGBO(121, 171, 222, 1), width: 3),
          ),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(),
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white, width: 3),
                image: const DecorationImage(
                  image: NetworkImage(
                      "https://images.unsplash.com/photo-1501785888041-af3ef285b470"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _bottomBar(double screenHeight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      color: Colors.white,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.flash_on_outlined, size: 45),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 45),
                onPressed: () {},
              ),
            ],
          ),
          Transform.translate(
            offset: const Offset(0, 20),
            child: SizedBox(
              width: 115,
              height: 115,
              child: FloatingActionButton(
                onPressed: () {},
                backgroundColor: Colors.blue,
                elevation: 4,
                shape: const CircleBorder(),
                child: const Icon(Icons.camera, size: 70, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
