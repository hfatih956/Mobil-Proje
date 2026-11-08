# Kişi Yönetim Sistemi

Flutter istemci + FastAPI REST API. Kişiler üzerinde CRUD.

| Katman | Teknoloji | Klasör |
|---|---|---|
| Mobil | Flutter (Dart), `http`, `url_launcher` | `mobile_app/` |
| Backend | FastAPI, Uvicorn, SQLite (`sqlite3`) | `backend_api/` |

## Yapı

```
backend_api/
  main.py            PersonIn modeli, SQLite, seed verisi, /photos, 5 endpoint
  requirements.txt
  photos/            seed kişilerin fotoğrafları
mobile_app/lib/
  main.dart          MaterialApp, tema, home: ListPage
  person.dart        Person modeli, fromJson / toJson
  api.dart           baseUrl ve 5 HTTP fonksiyonu
  list_page.dart     liste, FAB
  detail_page.dart   detay, mailto/tel, düzenle, sil (onaylı)
  form_page.dart     ekleme (POST) ve düzenleme (PUT) için ortak form
  person_photo.dart  CircleAvatar + Image.network, hata durumunda ikon
mobile_app/apk/
  kisi-rehberi.apk   release build (arm64, x64)
```

## Gereksinimler

Python 3.10+, Flutter SDK, Android SDK ve bir emülatör.

## Backend

```bash
cd backend_api
pip install -r requirements.txt
python main.py
```

- `0.0.0.0:5000` üzerinde çalışır, `reload=True`.
- İlk açılışta `persons.db` oluşturulur ve 3 kişi eklenir. Seed verisine dönmek için sunucu kapalıyken `persons.db` silinir.
- Swagger: http://localhost:5000/docs

## Mobil

```bash
cd mobile_app
flutter pub get
flutter run
```

`baseUrl` (`lib/api.dart`) ve `PHOTO_BASE` (`main.py`) emülatör için `10.0.2.2` kullanır. Fiziksel cihazda ikisi de bilgisayarın LAN IP'si ile değiştirilir ve `persons.db` silinir.

### APK

`mobile_app/apk/kisi-rehberi.apk`, emülatöre sürükle bırak ile kurulur. Yeniden derlemek için:

```bash
flutter build apk --target-platform android-arm64,android-x64
```

## API

| Metot | Endpoint | Yanıt |
|---|---|---|
| GET | `/api/persons` | 200, kişi dizisi |
| GET | `/api/persons/{id}` | 200, 404 |
| POST | `/api/persons` | 201 |
| PUT | `/api/persons/{id}` | 200, 404 |
| DELETE | `/api/persons/{id}` | 204, 404 |

Fotoğraflar `GET /photos/{dosya}` ile statik sunulur. Hatalı tipte gövde 422 döner.

```json
{
  "id": 1,
  "fullName": "Ahmet Yılmaz",
  "department": "Yazılım Geliştirme",
  "photoUrl": "http://10.0.2.2:5000/photos/ahmet.jpg",
  "birthPlace": "Adana",
  "birthDate": "1994-04-12",
  "email": "ahmet.yilmaz@sirket.com",
  "phone": "+905550123456"
}
```

POST ve PUT gövdesinde `id` gönderilmez; POST'ta veritabanı atar, PUT'ta URL'den alınır.
