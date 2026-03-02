class RegisterRequestDto {
  final String fullName;
  final String email;
  final String passWord;
  final String? dob;

  const RegisterRequestDto({
    required this.fullName,
    required this.email,
    required this.passWord,
    this.dob,
  });

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'email': email,
    'passWord': passWord,
    'dob': dob,
  };
}
