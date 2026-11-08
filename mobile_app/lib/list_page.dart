import 'package:flutter/material.dart';

// "as api": api.dart'taki fonksiyonları api.getPersons() diye çağırırız; nereden geldikleri belli olur.
import 'api.dart' as api;
import 'person.dart';
import 'person_photo.dart';
import 'detail_page.dart';
import 'form_page.dart';

// Ana sayfa: kişi listesi.
// StatefulWidget: içindeki veri (kişiler, yükleniyor, hata) zamanla değiştiği için.
// Widget sınıfı sadece ayarları tutar; değişen veri ve build aşağıdaki State sınıfındadır.
class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}

// Alt çizgi (_) ile başlayan isimler sadece bu dosyadan erişilebilir (private).
class _ListPageState extends State<ListPage> {
  List<Person> persons = []; // Ekranda gösterilen kişiler
  bool loading = true; // Veri yükleniyor mu?
  bool error = false; // Sunucuya bağlanırken hata oldu mu?

  // Sayfa ilk açıldığında bir kez çalışır.
  @override
  void initState() {
    super.initState();
    load();
  }

  // Kişileri API'den çek, sonra setState ile ekranı yeniden çiz.
  // setState: içindeki değişikliği yapar ve Flutter'a "build'i tekrar çalıştır" der.
  Future<void> load() async {
    try {
      final result = await api.getPersons();
      setState(() {
        persons = result;
        loading = false;
        error = false;
      });
    } catch (e) {
      // Sunucu kapalıysa veya hata döndüyse buraya düşer: listenin yerine hata yazısı çıkar.
      setState(() {
        loading = false;
        error = true;
      });
    }
  }

  // Satıra tıklanınca: kişinin id'si ile detay sayfasını aç. Geri dönülünce listeyi yenile.
  // Navigator.push yeni sayfayı üste açar; await, o sayfa kapanana kadar bekler.
  // person.id! : listedeki kişiler sunucudan geldiği için id'leri kesin dolu, "!" bunu belirtir.
  Future<void> openDetail(Person person) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage(id: person.id!)));
    load();
  }

  // + butonuna basılınca: boş formu aç (yeni kişi). Geri dönülünce listeyi yenile.
  // FormPage'e kişi verilmediği için form "ekleme" modunda açılır.
  Future<void> openForm() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const FormPage()));
    load();
  }

  // Ekranı çizer. setState her çağrıldığında tekrar çalışır.
  // Scaffold: sayfa iskeleti; üstte AppBar, ortada liste, sağ altta + butonu (FloatingActionButton, FAB).
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kişiler')), // Liste sayfasının başlığı
      body: buildBody(),
      floatingActionButton: FloatingActionButton(onPressed: openForm, child: const Icon(Icons.add)),
    );
  }

  // Duruma göre: yükleniyor göstergesi, hata mesajı veya kişi listesi.
  Widget buildBody() {
    // Veri henüz gelmediyse ortada dönen çember.
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    // Hata olduysa tıklanabilir yazı; tıklanınca load() tekrar denenir.
    if (error) {
      return Center(
        child: TextButton(onPressed: load, child: const Text('Sunucuya bağlanılamadı. Tekrar dene')),
      );
    }
    return ListView.builder(
      // ListView.builder: satırları sadece ekranda göründükçe oluşturur, uzun listelerde hızlıdır.
      itemCount: persons.length,
      // Her satır için bir kez çağrılır; index o satırın sırasıdır (0, 1, 2...).
      itemBuilder: (context, index) {
        final person = persons[index];
        // Listedeki her kart bir ListTile: solda fotoğraf, ortada kalın ad soyad, altında departman.
        return ListTile(
          leading: PersonPhoto(url: person.photoUrl, radius: 20), // Karttaki fotoğrafın boyutu
          title: Text(person.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(person.department), // Kartta adın altındaki yazı
          onTap: () => openDetail(person),
        );
      },
    );
  }
}
