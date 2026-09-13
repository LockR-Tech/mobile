class CourierProfile {
  final String id;
  final String vehicleType;
  final String licensePlate;
  final String? frontVehicleImageUrl;
  final String? backVehicleImageUrl;
  final String? portraitUrl;
  final String status;

  const CourierProfile({
    required this.id,
    required this.vehicleType,
    required this.licensePlate,
    this.frontVehicleImageUrl,
    this.backVehicleImageUrl,
    this.portraitUrl,
    required this.status,
  });
}
