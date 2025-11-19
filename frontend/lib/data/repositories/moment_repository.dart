import '../models/moment_model.dart';
import '../services/moment_service.dart';

class MomentRepository {
  final MomentService momentService;

  MomentRepository({required this.momentService});

  Future<List<Moment>> getFeed(int page, int size) async {
    return await momentService.getFeed(page: page, size: size);
  }

  Future<Moment> createMoment(String imageUrl, String? caption) async {
    return await momentService.createMoment(imageUrl: imageUrl, caption: caption);
  }
}
