class ApiResponse<T> {
  final bool success;
  final T? data;
  final String message;
  final String? error;

  ApiResponse({
    required this.success,
    this.data,
    required this.message,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      data: json['data'] != null && fromJsonT != null 
          ? fromJsonT(json['data']) 
          : null,
      message: json['message'] ?? '',
      error: json['error'],
    );
  }
}

class PaginationMeta {
  final int currentPage;
  final int totalPages;
  final int totalRecords;
  final int limit;
  final bool hasNextPage;
  final bool hasPrevPage;

  PaginationMeta({
    required this.currentPage,
    required this.totalPages,
    required this.totalRecords,
    required this.limit,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 0,
      totalRecords: json['totalRecords'] ?? 0,
      limit: json['limit'] ?? 20,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPrevPage: json['hasPrevPage'] ?? false,
    );
  }
}