abstract class BusinessService {
  Future<bool> hasAnyBusiness();
  Future<String> createBusiness({
    required String name,
    String timezone = 'Asia/Jakarta',
  });
}
