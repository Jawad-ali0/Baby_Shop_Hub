class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final List<Address> addresses;
  final List<PaymentMethod> paymentMethods;
  final int createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.addresses,
    required this.paymentMethods,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    uid: json['uid'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    role: json['role'] as String? ?? 'user',
    addresses:
        (json['addresses'] as List?)
            ?.map((e) => Address.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [],
    paymentMethods:
        (json['paymentMethods'] as List?)
            ?.map(
              (e) =>
                  PaymentMethod.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList() ??
        [],
    createdAt: json['createdAt'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'email': email,
    'role': role,
    'addresses': addresses.map((e) => e.toJson()).toList(),
    'paymentMethods': paymentMethods.map((e) => e.toJson()).toList(),
    'createdAt': createdAt,
  };

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    List<Address>? addresses,
    List<PaymentMethod>? paymentMethods,
    int? createdAt,
  }) => UserModel(
    uid: uid ?? this.uid,
    name: name ?? this.name,
    email: email ?? this.email,
    role: role ?? this.role,
    addresses: addresses ?? this.addresses,
    paymentMethods: paymentMethods ?? this.paymentMethods,
    createdAt: createdAt ?? this.createdAt,
  );
}

class Address {
  final String id;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final bool isDefault;

  Address({
    required this.id,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: json['id'] as String,
    street: json['street'] as String,
    city: json['city'] as String,
    state: json['state'] as String,
    zipCode: json['zipCode'] as String,
    country: json['country'] as String,
    isDefault: json['isDefault'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'street': street,
    'city': city,
    'state': state,
    'zipCode': zipCode,
    'country': country,
    'isDefault': isDefault,
  };

  String get fullAddress => '$street, $city, $state $zipCode, $country';

  Address copyWith({
    String? id,
    String? street,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    bool? isDefault,
  }) => Address(
    id: id ?? this.id,
    street: street ?? this.street,
    city: city ?? this.city,
    state: state ?? this.state,
    zipCode: zipCode ?? this.zipCode,
    country: country ?? this.country,
    isDefault: isDefault ?? this.isDefault,
  );
}

class PaymentMethod {
  final String id;
  final String type; // 'card', 'paypal', etc.
  final String lastFourDigits;
  final String cardHolderName;
  final String expiryDate;
  final bool isDefault;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.lastFourDigits,
    required this.cardHolderName,
    required this.expiryDate,
    this.isDefault = false,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => PaymentMethod(
    id: json['id'] as String,
    type: json['type'] as String,
    lastFourDigits: json['lastFourDigits'] as String,
    cardHolderName: json['cardHolderName'] as String,
    expiryDate: json['expiryDate'] as String,
    isDefault: json['isDefault'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'lastFourDigits': lastFourDigits,
    'cardHolderName': cardHolderName,
    'expiryDate': expiryDate,
    'isDefault': isDefault,
  };

  PaymentMethod copyWith({
    String? id,
    String? type,
    String? lastFourDigits,
    String? cardHolderName,
    String? expiryDate,
    bool? isDefault,
  }) => PaymentMethod(
    id: id ?? this.id,
    type: type ?? this.type,
    lastFourDigits: lastFourDigits ?? this.lastFourDigits,
    cardHolderName: cardHolderName ?? this.cardHolderName,
    expiryDate: expiryDate ?? this.expiryDate,
    isDefault: isDefault ?? this.isDefault,
  );
}
