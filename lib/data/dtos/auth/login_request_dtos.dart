class LoginRequestDtos {
  final String email;
  final String passWord;

  const LoginRequestDtos({required this.email, required this.passWord});

  /// Chuyển object thành Map để gửi API
  Map<String, dynamic> toJson() => {'email': email, 'passWord': passWord};
}
