import 'dart:typed_data';
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

  Future<void> updateProfile({
    required String businessId,
    required String name,
    String? legalName,
    String? contactEmail,
    String? contactPhone,
    String? address,
    String? timezone,
  });

  Future<String> uploadLogo(String businessId, Uint8List bytes, String fileName);
  Future<void> updateReceiptFooter(String businessId, String? footer);
}
