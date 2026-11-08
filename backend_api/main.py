# Kişi Yönetim Sistemi - REST API (FastAPI)
# Backend'in tamamı bu dosyada: veri modeli, veritabanı bağlantısı, örnek veriler, fotoğraflar ve 5 uç nokta.
import sqlite3  # Python ile gelen veritabanı kütüphanesi; ayrı bir veritabanı sunucusu gerekmez
from pathlib import Path  # Dosya yollarını işletim sisteminden bağımsız "/" ile birleştirmek için

import uvicorn  # FastAPI uygulamasını çalıştıran web sunucusu; gelen HTTP isteklerini dinler
from fastapi import FastAPI, HTTPException, Response  # HTTPException: 404 gibi hata, Response: gövdesiz cevap (204)
from fastapi.staticfiles import StaticFiles  # Bir klasördeki dosyaları (fotoğrafları) olduğu gibi sunar
from pydantic import BaseModel  # Gelen JSON'u doğrulayan modellerin temeli (FastAPI ile birlikte gelir)

BASE_DIR = Path(__file__).parent  # Bu dosyanın bulunduğu klasör (backend_api)
DB_PATH = BASE_DIR / "persons.db"  # Veritabanı: SQLite, proje klasöründeki "persons.db" dosyası

# Örnek kişilerin fotoğraf adresi. 10.0.2.2 = emülatörün içinden bakınca bu bilgisayar (api.dart ile aynı mantık).
PHOTO_BASE = "http://10.0.2.2:5000/photos"

# Uç noktalar aşağıda @app.get, @app.post ile bu nesneye bağlanır. title: localhost:5000/docs sayfasındaki ad.
app = FastAPI(title="Kişi Yönetim Sistemi API")

# /photos/ahmet.jpg gibi adresler photos klasöründeki dosyayı döndürür; uygulama fotoğrafları buradan indirir.
app.mount("/photos", StaticFiles(directory=BASE_DIR / "photos"), name="photos")


# Kişi modeli: POST/PUT ile gelen JSON bu sınıfa göre doğrulanır (eksik alan "" olur, yanlış tip 422 hatası verir).
# Alan adları mobil uygulamayla aynı (camelCase). id yok: yeni kişide veritabanı verir, güncellemede URL'den gelir.
class PersonIn(BaseModel):
    fullName: str = ""  # str: metin tipi. = "": alan gönderilmezse kullanılacak değer
    department: str = ""
    photoUrl: str = ""
    birthPlace: str = ""
    birthDate: str = ""  # "1994-04-12" biçiminde
    email: str = ""
    phone: str = ""


# Veritabanı bağlantısı açar. row_factory sayesinde satırlar sözlüğe (dict) çevrilebilir: row["fullName"].
# "with get_db() as db:" bloğu hatasız biterse değişiklikler otomatik kaydedilir (commit).
def get_db():
    db = sqlite3.connect(DB_PATH)  # Dosya yoksa SQLite onu boş olarak oluşturur
    db.row_factory = sqlite3.Row
    return db


# Uygulama açılırken: tablo yoksa oluştur, tablo boşsa örnek kişileri ekle.
def init_db():
    with get_db() as db:
        # TEXT = metin, NOT NULL = boş (NULL) olamaz. IF NOT EXISTS: tablo varsa dokunmaz, veriler korunur.
        db.execute("""
            CREATE TABLE IF NOT EXISTS persons (
                id INTEGER PRIMARY KEY AUTOINCREMENT,  -- Yeni kayıtta veritabanı otomatik verir
                fullName TEXT NOT NULL,
                department TEXT NOT NULL,
                photoUrl TEXT NOT NULL,
                birthPlace TEXT NOT NULL,
                birthDate TEXT NOT NULL,
                email TEXT NOT NULL,
                phone TEXT NOT NULL
            )
        """)
        # Kayıt sayısı 0 ise (ilk çalıştırma) 3 örnek kişi ekle. fetchone()[0]: ilk satırın ilk sütunu (sayı).
        if db.execute("SELECT COUNT(*) FROM persons").fetchone()[0] == 0:
            # executemany: sorguyu her kişi için çalıştırır. ? yer tutucu: değer ayrı verilir (SQL injection'a karşı).
            db.executemany(
                "INSERT INTO persons (fullName, department, photoUrl, birthPlace, birthDate, email, phone) "
                "VALUES (?, ?, ?, ?, ?, ?, ?)",
                [
                    ("Ahmet Yılmaz", "Yazılım Geliştirme", f"{PHOTO_BASE}/ahmet.jpg",
                     "Adana", "1994-04-12", "ahmet.yilmaz@sirket.com", "+905550123456"),
                    ("Ayşe Kaya", "İnsan Kaynakları", f"{PHOTO_BASE}/ayse.jpg",
                     "İzmir", "1990-09-03", "ayse.kaya@sirket.com", "+905551112233"),
                    ("Mehmet Demir", "Bilgi Teknolojileri", f"{PHOTO_BASE}/mehmet.jpg",
                     "Ankara", "1988-01-25", "mehmet.demir@sirket.com", "+905554445566"),
                ],
            )


init_db()  # Sunucu başlarken bir kez çalışır


# id'si verilen kişiyi sözlük olarak döner; yoksa 404 fırlatır. 4 uç nokta bunu kullanır.
def find_person(db, id: int):
    # (id,): tek elemanlı demet, ? yerine konur. fetchone(): ilk satır, kayıt yoksa None.
    row = db.execute("SELECT * FROM persons WHERE id = ?", (id,)).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Kişi bulunamadı")  # FastAPI bunu 404 cevabına çevirir
    return dict(row)  # Satır → sözlük; FastAPI sözlüğü otomatik JSON'a çevirir


# GET /api/persons → tüm kişileri liste (dizi) olarak döner.
# @app.get: dekoratör; altındaki fonksiyonu bu adrese gelen GET isteklerine bağlar.
@app.get("/api/persons")
def get_persons():
    with get_db() as db:
        rows = db.execute("SELECT * FROM persons").fetchall()  # Eklenme sırasıyla gelir; isme göre sıralamak için ORDER BY eklenir
    return [dict(row) for row in rows]  # Her satır sözlüğe çevrilir, liste JSON dizisi olarak gider


# GET /api/persons/5 → id'si 5 olan kişiyi döner, yoksa 404.
# {id}: adresin değişken kısmı. "id: int" ile sayıya çevrilir; sayı değilse 422 döner.
@app.get("/api/persons/{id}")
def get_person(id: int):
    with get_db() as db:
        return find_person(db, id)


# POST /api/persons → gövdedeki JSON'dan yeni kişi oluşturur, 201 ("Created") döner.
# person: PersonIn → FastAPI gövdedeki JSON'u okur, doğrular ve bu nesneye çevirir.
@app.post("/api/persons", status_code=201)
def create_person(person: PersonIn):
    with get_db() as db:
        cursor = db.execute(
            "INSERT INTO persons (fullName, department, photoUrl, birthPlace, birthDate, email, phone) "
            "VALUES (?, ?, ?, ?, ?, ?, ?)",
            (person.fullName, person.department, person.photoUrl, person.birthPlace,
             person.birthDate, person.email, person.phone),
        )
        return find_person(db, cursor.lastrowid)  # lastrowid = veritabanının yeni kişiye verdiği id


# PUT /api/persons/5 → id'si 5 olan kişiyi günceller. id adresten, yeni bilgiler gövdeden gelir.
@app.put("/api/persons/{id}")
def update_person(id: int, person: PersonIn):
    with get_db() as db:
        find_person(db, id)  # Kişi yoksa burada 404 fırlatılır
        db.execute(  # WHERE id = ?: sadece bu id'li satır güncellenir
            "UPDATE persons SET fullName = ?, department = ?, photoUrl = ?, birthPlace = ?, "
            "birthDate = ?, email = ?, phone = ? WHERE id = ?",
            (person.fullName, person.department, person.photoUrl, person.birthPlace,
             person.birthDate, person.email, person.phone, id),
        )
        return find_person(db, id)  # Güncel hâli tekrar okunup döndürülür


# DELETE /api/persons/5 → kişiyi kalıcı olarak siler. 204 "No Content": başarılı, cevapta gövde yok.
@app.delete("/api/persons/{id}", status_code=204)
def delete_person(id: int):
    with get_db() as db:
        find_person(db, id)  # Kişi yoksa burada 404 fırlatılır
        db.execute("DELETE FROM persons WHERE id = ?", (id,))
    return Response(status_code=204)


# "python main.py" ile çalıştırılınca: main.py'deki app'i 5000 portunda başlat.
# 0.0.0.0 = bilgisayarın tüm ağ adreslerinden gelen isteklere açık. reload=True: dosya kaydedilince sunucu yeniden başlar.
if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=5000, reload=True)
