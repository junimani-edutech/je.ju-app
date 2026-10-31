import '../models/business.dart';
import '../models/business_member.dart';

abstract class BusinessService {
  Future<bool> hasAnyBusiness();

  Future<String> createBusiness({
    required String name,
    String timezone = 'Asia/Jakarta',
  });

  Future<List<Business>> listMyBusinesses();

  Future<BusinessMember?> getMemberForCurrentUser(String businessId);
}
