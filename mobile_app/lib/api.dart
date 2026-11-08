// API ile konuşan 5 fonksiyon: her biri bir REST uç noktasına HTTP isteği atar.
// jsonEncode / jsonDecode için: Dart nesnesi ↔ JSON metni dönüşümü.
import 'dart:convert';

// http paketi (pubspec.yaml'da tanımlı): GET, POST, PUT, DELETE istekleri atmak için.
// "as http": fonksiyonlarını http.get, http.post diye ön ekle çağırırız.
import 'package:http/http.dart' as http;

import 'person.dart';

// API adresi. 10.0.2.2 = Android emülatörünün içinden bakınca bilgisayarın kendisi (localhost).
const String baseUrl = 'http://10.0.2.2:5000/api/persons';

// Gövdesinde JSON gönderdiğimiz isteklerin başlığı.
const Map<String, String> headers = {'Content-Type': 'application/json'};

// Sunucu hata kodu döndürdüyse (200'lü değilse) hata fırlat.
// Fırlatılan hata, fonksiyonu çağıran sayfadaki try/catch bloğunda yakalanır.
void checkStatus(http.Response response) {
  if (response.statusCode >= 300) {
    throw Exception('Sunucu hatası: ${response.statusCode}');
  }
}

// Future: sonucu hemen değil, ileride (sunucu cevap verince) gelecek değer.
// async / await: cevabı beklerken uygulama donmaz, ekran çizilmeye devam eder.

// GET /api/persons → tüm kişiler
Future<List<Person>> getPersons() async {
  final response = await http.get(Uri.parse(baseUrl));
  checkStatus(response);
  // Gelen metni JSON listesine çevir, sonra her elemanı Person nesnesine dönüştür.
  final List list = jsonDecode(response.body);
  return list.map((item) => Person.fromJson(item)).toList();
}

// GET /api/persons/{id} → tek kişi
Future<Person> getPerson(int id) async {
  final response = await http.get(Uri.parse('$baseUrl/$id'));
  checkStatus(response);
  return Person.fromJson(jsonDecode(response.body));
}

// POST /api/persons → yeni kişi ekle
// Gövde: Person → Map (toJson) → JSON metni (jsonEncode)
Future<void> createPerson(Person person) async {
  final response = await http.post(Uri.parse(baseUrl), headers: headers, body: jsonEncode(person.toJson()));
  checkStatus(response);
}

// PUT /api/persons/{id} → kişiyi güncelle
// Hangi kişinin güncelleneceği adresteki id'den anlaşılır, yeni bilgiler gövdede gider.
Future<void> updatePerson(Person person) async {
  final response = await http.put(
    Uri.parse('$baseUrl/${person.id}'),
    headers: headers,
    body: jsonEncode(person.toJson()),
  );
  checkStatus(response);
}

// DELETE /api/persons/{id} → kişiyi sil
// Gövde gerekmez, id adreste gider.
Future<void> deletePerson(int id) async {
  final response = await http.delete(Uri.parse('$baseUrl/$id'));
  checkStatus(response);
}
