class BlogModel {
  final String id;
  final String title;
  final String? subTitle;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;

  BlogModel({
    required this.id,
    required this.title,
    this.subTitle,
    required this.content,
    this.imageUrl,
    required this.createdAt,
  });

  factory BlogModel.fromJson(Map<String, dynamic> json) {
    return BlogModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subTitle: json['subTitle'],
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
