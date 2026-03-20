class PaperlessAuthTokenResponse {
  const PaperlessAuthTokenResponse({required this.token});

  factory PaperlessAuthTokenResponse.fromJson(Map<String, dynamic> json) {
    return PaperlessAuthTokenResponse(token: json['token'] as String? ?? '');
  }

  final String token;
}
