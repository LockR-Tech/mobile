class AdvertisementModel {
  final String id;
  final String title;
  final String? description;
  final String imageUrl;
  final String? videoUrl;
  final String target;

  AdvertisementModel({
    required this.id,
    required this.title,
    this.description,
    required this.imageUrl,
    this.videoUrl,
    required this.target,
  });

  factory AdvertisementModel.fromJson(Map<String, dynamic> json) {
    return AdvertisementModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'] ?? '',
      videoUrl: json['videoUrl'],
      target: json['target'] ?? 'ALL',
    );
  }
}
