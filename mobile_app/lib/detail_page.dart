import 'package:flutter/material.dart';
// url_launcher paketi: telefonun e-posta ve arama uygulamalarını açmak için (mailto:, tel:).
import 'package:url_launcher/url_launcher.dart';

import 'api.dart' as api;
import 'person.dart';
import 'person_photo.dart';
import 'form_page.dart';

// Kişi detay sayfası. Listeden sadece id gelir, bilgiler API'den id ile çekilir.
class DetailPage extends StatefulWidget {
  final int id;

  const DetailPage({super.key, required this.id});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Person? person; // null = henüz yükleniyor
  bool error = false; // Sunucuya bağlanırken hata oldu mu?
  bool deleting = false; // Silme isteği gönderildi, cevap bekleniyor mu? (butonlara tekrar basılmasını engeller)

  // Sayfa açılır açılmaz kişiyi çekmeye başla.
  @override
  void initState() {
    super.initState();
    load();
  }

  // GET /api/persons/{id} ile kişiyi çek, ekranı yenile. Hata olursa "Tekrar dene" yazısı gösterilir.
  // widget.id: State sınıfından, üstteki DetailPage'e verilen id'ye böyle erişilir.
  Future<void> load() async {
    try {
      final result = await api.getPerson(widget.id);
      if (!mounted) return; // Beklerken sayfa kapandıysa (geri tuşu) ekranı güncelleme.
      setState(() {
        person = result;
        error = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = true);
    }
  }

  // Tekrar dene: hata yazısını kaldır (yükleniyor göstergesi çıkar) ve kişiyi yeniden çek.
  void retry() {
    setState(() => error = false);
    load();
  }

  // Düzenle: formu bu kişinin bilgileriyle aç. Geri dönülünce bilgileri yenile.
  // FormPage'e person verildiği için form "düzenleme" modunda açılır (kaydedince PUT).
  Future<void> edit() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => FormPage(person: person)));
    load();
  }

  // Sil: önce onay sor. "Sil" seçilirse API'ye DELETE gönder ve listeye geri dön.
  // showDialog ekrana bir pencere açar ve kapanana kadar bekler. Pencere kapanırken
  // Navigator.pop'a verilen değer (true / false) buraya sonuç olarak döner.
  Future<void> confirmDelete() async {
    final bool? approved = await showDialog<bool>(
      context: context,
      // AlertDialog: başlık, mesaj ve alt kısımda butonlar olan hazır onay penceresi.
      builder: (context) => AlertDialog(
        title: const Text('Kişiyi sil'),
        content: const Text('Bu kişi kalıcı olarak silinecek. Emin misiniz?'), // Silme onayı mesajı
        // Pencerenin altındaki butonlar: soldaki İptal, sağdaki kırmızı Sil.
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red), // Silme onayındaki Sil butonunun rengi
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    // Diyalog dışına tıklanırsa sonuç null gelir; sadece "Sil" (true) seçildiyse silinir.
    if (approved != true) return;

    setState(() => deleting = true); // Butonları devre dışı bırak

    try {
      await api.deletePerson(widget.id);
    } catch (e) {
      // Sunucu kapalı veya hata döndü: kullanıcıya söyle, butonları tekrar aç.
      if (!mounted) return;
      setState(() => deleting = false);
      // SnackBar: ekranın altında birkaç saniye görünüp kaybolan kısa mesaj.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silinemedi. Sunucu çalışıyor mu?')));
      return;
    }

    // Beklerken kullanıcı geri tuşuyla çıktıysa devam etme (form_page.dart'taki açıklamaya bakın).
    if (!mounted || ModalRoute.isCurrentOf(context) != true) return;
    // Detay sayfasını kapat: listeye dönülür, liste de kendini yeniler (list_page.dart, openDetail).
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // 1. durum: hata olduysa "Tekrar dene" yazısı.
    if (error) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: TextButton(onPressed: retry, child: const Text('Sunucuya bağlanılamadı. Tekrar dene')),
        ),
      );
    }
    // 2. durum: kişi henüz gelmediyse dönen çember.
    if (person == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    // 3. durum: kişi geldi, bilgileri göster.
    final p = person!; // Buraya geldiysek person artık null değil.

    return Scaffold(
      appBar: AppBar(title: const Text('Kişi Detayı')),
      // ListView: içerik ekrana sığmazsa kaydırılabilsin diye.
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Üst kısım: büyük fotoğraf, ad-soyad ve departman
          // Center: ListView öğeleri tam genişliğe yayar; Center olmadan fotoğraf şeride uzayıp aşırı büyür.
          Center(child: PersonPhoto(url: p.photoUrl, radius: 60)), // Detaydaki büyük fotoğrafın boyutu
          const SizedBox(height: 12), // Fotoğrafla isim arasında 12 piksel boşluk
          // headlineSmall: temadaki büyük başlık yazı stili.
          Text(p.fullName, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
          Text(p.department, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          // Alt kısım: bilgi satırları
          // Card: hafif gölgeli, köşeleri yuvarlak kutu. İçindeki Column satırları alt alta dizer.
          Card(
            child: Column(
              children: [
                // Her bilgi bir ListTile: solda ikon, üstte başlık, altta değer.
                ListTile(
                  leading: const Icon(Icons.place),
                  title: const Text('Doğum Yeri'),
                  subtitle: Text(p.birthPlace),
                ),
                ListTile(
                  leading: const Icon(Icons.cake),
                  title: const Text('Doğum Tarihi'),
                  // split('-'): "1994-04-12" → ["1994", "04", "12"], reversed: ters çevir, join('.'): noktayla birleştir.
                  subtitle: Text(p.birthDate.split('-').reversed.join('.')), // Tarih biçimi: 1994-04-12 → 12.04.1994
                ),
                // E-posta ve telefon satırlarında onTap var: tıklanınca url_launcher ilgili uygulamayı açar.
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('E-posta'),
                  subtitle: Text(p.email),
                  onTap: () => launchUrl(Uri.parse('mailto:${p.email}')), // E-posta uygulamasını açar
                ),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Telefon'),
                  subtitle: Text(p.phone),
                  onTap: () => launchUrl(Uri.parse('tel:${p.phone}')), // Telefon arama ekranını açar
                ),
              ],
            ),
          ),
        ],
      ),
      // En altta sabit duran butonlar
      // bottomNavigationBar: sayfa kaydırılsa bile ekranın altında sabit kalan alan.
      // SafeArea: telefonun alt çentiği / sistem çubuğu butonların üstüne binmesin diye.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          // Row: iki butonu yan yana dizer. Expanded: ikisi genişliği eşit paylaşır.
          child: Row(
            children: [
              Expanded(
                // Silinirken onPressed null olur: buton gri görünür ve basılamaz.
                child: OutlinedButton.icon(
                  onPressed: deleting ? null : edit,
                  icon: const Icon(Icons.edit),
                  label: const Text('Düzenle'),
                ),
              ),
              const SizedBox(width: 12), // İki buton arasında boşluk
              Expanded(
                child: FilledButton.icon(
                  onPressed: deleting ? null : confirmDelete,
                  style: FilledButton.styleFrom(backgroundColor: Colors.red), // Sayfanın altındaki Sil butonunun rengi
                  // Silme sürerken ikon yerine küçük dönen çember gösterilir.
                  icon: deleting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.delete),
                  label: const Text('Sil'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
