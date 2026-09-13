class PaginatedResult<T> {
  final List<T> items;
  final Pagination pagination;

  const PaginatedResult({required this.items, required this.pagination});
}

class Pagination {
  final int total;
  final int page;
  final int limit;

  const Pagination({
    required this.total,
    required this.page,
    required this.limit,
  });

  int get totalPages => (total / limit).ceil();
  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;
}
