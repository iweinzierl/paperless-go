class PaperlessAuthTokenRequest {
  const PaperlessAuthTokenRequest({
    required this.username,
    required this.password,
    this.code,
  });

  final String username;
  final String password;
  final String? code;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'username': username,
      'password': password,
      if (code != null && code!.isNotEmpty) 'code': code,
    };
  }
}
