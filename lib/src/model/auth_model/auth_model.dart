class Organization {
  final String name;
  final String logo;
  final String address;
  final String postal;
  final String city;
  final String phone;
  final String email;
  final String coc;
  final String vat;
  final String bankAccount;
  final bool isContactActive;
  final String whatsappUrl;

  Organization({
    required this.name,
    required this.logo,
    required this.address,
    required this.postal,
    required this.city,
    required this.phone,
    required this.email,
    required this.coc,
    required this.vat,
    required this.bankAccount,
    required this.isContactActive,
    required this.whatsappUrl,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    final contact = json['contact'] as Map<String, dynamic>?;

    return Organization(
      name: json['name'] ?? '',
      logo: json['logo'] ?? '',
      address: json['address'] ?? '',
      postal: json['postal'] ?? '',
      city: json['city'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      coc: json['coc'] ?? '',
      vat: json['vat'] ?? '',
      bankAccount: json['bank_account'] ?? '',
      isContactActive: contact?['active'] == true,
      whatsappUrl: contact?['url'] ?? '',
    );
  }
}

class LoginResponse {
  final bool success;
  final String? token;
  final String? message;

  LoginResponse({required this.success, this.token, this.message});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] == true || json['status'] == 'ok',
      token: json['token'],
      message: json['message'],
    );
  }
}

class MagicLinkData {
  final String org;
  final String user;
  final String code;

  MagicLinkData({required this.org, required this.user, required this.code});
  bool get isValid => org.isNotEmpty && user.isNotEmpty && code.isNotEmpty;
}
