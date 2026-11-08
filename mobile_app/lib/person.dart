// Kişi modeli: API'den gelen JSON bu sınıfa, bu sınıf da JSON'a dönüştürülür.
// Bu dosyada ekran kodu yok, sadece veri yapısı var. Bu yüzden Flutter import etmeye gerek yok.
class Person {
  final int? id; // Yeni kişinin henüz id'si yoktur (sunucu verir), bu yüzden null olabilir.
  // Alan adları yönergedeki JSON şemasıyla birebir aynı.
  // final: nesne oluşturulduktan sonra alanlar değiştirilemez.
  final String fullName;
  final String department;
  final String photoUrl;
  final String birthPlace;
  final String birthDate; // "1994-04-12" biçiminde
  final String email;
  final String phone;

  // Kurucu (constructor). Süslü parantez isimli parametre demektir: Person(fullName: ..., phone: ...)
  // required: bu parametre verilmeden nesne oluşturulamaz. id isteğe bağlı olduğu için required değil.
  Person({
    this.id,
    required this.fullName,
    required this.department,
    required this.photoUrl,
    required this.birthPlace,
    required this.birthDate,
    required this.email,
    required this.phone,
  });

  // JSON (Map) → Person nesnesi
  // factory: her çağrıda yeni nesneyi kendisi oluşturup döndüren özel kurucu.
  // json['fullName']: Map'ten "fullName" anahtarının değerini okur.
  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'],
      fullName: json['fullName'],
      department: json['department'],
      photoUrl: json['photoUrl'],
      birthPlace: json['birthPlace'],
      birthDate: json['birthDate'],
      email: json['email'],
      phone: json['phone'],
    );
  }

  // Person nesnesi → JSON (Map). id gönderilmez: yeni kişide sunucu verir, güncellemede URL'de gider.
  // Bu Map, api.dart'ta jsonEncode ile metne çevrilip isteğin gövdesine konur.
  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'department': department,
      'photoUrl': photoUrl,
      'birthPlace': birthPlace,
      'birthDate': birthDate,
      'email': email,
      'phone': phone,
    };
  }
}
