class StyleModel {
  final int id; // Changed from String to int
  final String title;
  final String thumbnailUrl;
  final String exampleBeforeUrl;
  final String exampleAfterUrl;
  final String prompt;

  const StyleModel({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.exampleBeforeUrl,
    required this.exampleAfterUrl,
    required this.prompt,
  });

  factory StyleModel.fromJson(Map<String, dynamic> json) {
    return StyleModel(
      id: json['id'],
      title: json['title'],
      thumbnailUrl: json['thumbnail_url'],
      exampleBeforeUrl: json['example_before_url'],
      exampleAfterUrl: json['example_after_url'],
      prompt: json['prompt'],
    );
  }
}