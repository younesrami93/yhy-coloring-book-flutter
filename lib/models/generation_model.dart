class Generation {
  final int id;
  final String? originalImageUrl;
  final String? original_thumb_sm;
  final String? original_thumb_md;
  final String? processedImageUrl;
  final String? processed_thumb_sm;
  final String? processed_thumb_md;
  final String styleName;
  final String status; // 'pending', 'processing', 'completed', 'failed'
  final String createdAt;

  Generation({
    required this.id,
    this.originalImageUrl,
    this.original_thumb_sm,
    this.original_thumb_md,
    this.processedImageUrl,
    this.processed_thumb_sm,
    this.processed_thumb_md,
    required this.styleName,
    required this.status,
    required this.createdAt,
  });

  factory Generation.fromJson(Map<String, dynamic> json) {
    return Generation(
      id: json['id'],
      originalImageUrl: json['original_image_url'],
      original_thumb_sm: json['original_thumb_sm'],
      original_thumb_md: json['original_thumb_md'],
      processedImageUrl: json['processed_image_url'],
      processed_thumb_sm: json['processed_thumb_sm'],
      processed_thumb_md: json['processed_thumb_md'],
      styleName: json['style_name'] ?? 'Unknown Style',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'],
    );
  }
}

class GenerationResponse {
  final List<Generation> data;
  final int currentPage;
  final int lastPage;

  GenerationResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
  });

  factory GenerationResponse.fromJson(Map<String, dynamic> json) {
    return GenerationResponse(
      data: (json['data'] as List).map((e) => Generation.fromJson(e)).toList(),
      currentPage: json['current_page'],
      lastPage: json['last_page'],
    );
  }
}
