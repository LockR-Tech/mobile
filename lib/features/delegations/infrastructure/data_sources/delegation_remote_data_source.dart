abstract class DelegationRemoteDataSource {
  Future<Map<String, dynamic>> createDelegation(
    String orderId,
    String delegateeEmail,
  );

  Future<Map<String, dynamic>> getDelegationById(String id);

  Future<Map<String, dynamic>> revokeDelegation(String id);

  Future<Map<String, dynamic>> getMyDelegations();

  Future<Map<String, dynamic>> getDelegationsByPhone(String phoneNumber);

  Future<Map<String, dynamic>> getDelegationByOrderId(String orderId);
  Future<Map<String, dynamic>> findUserByPhone(String phoneNumber);
  Future<Map<String, dynamic>> openLocker({required String accessCode});
}
