import '../entities/user_profile.dart';

abstract class UserRepository {
  Future<UserProfile?> getCurrentProfile();
  Future<UserProfile> saveProfile(UserProfile profile);
  Future<EquipmentProfile?> getEquipmentProfile(String userId);
  Future<EquipmentProfile> saveEquipmentProfile(EquipmentProfile profile);
}
