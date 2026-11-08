import 'package:flutter/material.dart';

import 'api.dart' as api;
import 'person.dart';

// Ekleme ve düzenleme için ortak form.
// person verilirse düzenleme (PUT), verilmezse yeni kişi ekleme (POST) yapılır.
class FormPage extends StatefulWidget {
  final Person? person; // Soru işareti: null olabilir (yeni kişi eklerken boş gelir).

  // person isteğe bağlı olduğu için required değil.
  const FormPage({super.key, this.person});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  // Her metin kutusu için bir controller: kutudaki yazıyı okumak ve doldurmak için.
  final fullName = TextEditingController();
  final department = TextEditingController();
  final photoUrl = TextEditingController();
  final birthPlace = TextEditingController();
  final birthDate = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();

  bool saving = false; // İstek gönderildi, cevap bekleniyor mu? (Kaydet'e tekrar basılmasını engeller)

  @override
  void initState() {
    super.initState();
    // Düzenleme modundaysak kutuları kişinin mevcut bilgileriyle doldur.
    // widget.person: State sınıfından, üstteki FormPage'e verilen kişiye böyle erişilir.
    final p = widget.person;
    if (p != null) {
      fullName.text = p.fullName;
      department.text = p.department;
      photoUrl.text = p.photoUrl;
      birthPlace.text = p.birthPlace;
      birthDate.text = p.birthDate;
      email.text = p.email;
      phone.text = p.phone;
    }
  }

  // Kaydet: kutulardaki yazılardan Person oluştur, API'ye gönder, önceki sayfaya dön.
  Future<void> save() async {
    // trim(): baştaki ve sondaki boşlukları siler; sadece boşluk yazılmışsa da boş sayılır.
    if (fullName.text.trim().isEmpty) { // Zorunlu alan: ad soyad boşsa kaydetme
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ad Soyad boş olamaz')));
      return;
    }

    // Kutulardaki yazılardan yeni bir Person nesnesi oluştur.
    final person = Person(
      id: widget.person?.id, // Yeni kişide null, düzenlemede mevcut id
      fullName: fullName.text,
      department: department.text,
      photoUrl: photoUrl.text,
      birthPlace: birthPlace.text,
      birthDate: birthDate.text,
      email: email.text,
      phone: phone.text,
    );

    setState(() => saving = true); // Butonu devre dışı bırak, yerine dönen çember göster

    // id yoksa yeni kişi (POST), varsa mevcut kişi (PUT).
    try {
      if (person.id == null) {
        await api.createPerson(person); // POST
      } else {
        await api.updatePerson(person); // PUT
      }
    } catch (e) {
      // Sunucu kapalı veya hata döndü: kullanıcıya söyle, butonu tekrar aç.
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kaydedilemedi. Sunucu çalışıyor mu?')));
      return;
    }

    // Beklerken kullanıcı geri tuşuyla çıktıysa devam etme. mounted burada yetmez: sayfa kapanma
    // animasyonu bitene kadar true kalır. isCurrentOf ise geri basıldığı anda false olur. Bu kontrol
    // olmazsa pop, zaten kapanmakta olan bu sayfa yerine alttaki sayfayı kapatır (liste → siyah ekran).
    if (!mounted || ModalRoute.isCurrentOf(context) != true) return;
    // Formu kapat ve önceki sayfaya dön. O sayfa da kendini yeniler.
    Navigator.pop(context);
  }

  // Tek bir metin kutusu oluşturur (aynı kodu 7 kez yazmamak için).
  // keyboard: kutuya dokununca açılacak klavye. Verilmezse normal harf klavyesi açılır.
  Widget field(TextEditingController controller, String label, {TextInputType keyboard = TextInputType.text}) {
    // Padding: her kutunun altına 12 piksel boşluk bırakır.
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        // labelText: kutunun üstündeki etiket. OutlineInputBorder: kutunun etrafındaki çerçeve.
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Başlık moda göre değişir: kişi verilmediyse "Yeni Kişi", verildiyse "Kişiyi Düzenle".
      appBar: AppBar(title: Text(widget.person == null ? 'Yeni Kişi' : 'Kişiyi Düzenle')),
      // ListView: klavye açılınca kutular ekrana sığmazsa kaydırılabilsin diye.
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          field(fullName, 'Ad Soyad'),
          field(department, 'Departman'),
          field(photoUrl, 'Fotoğraf URL'),
          field(birthPlace, 'Doğum Yeri'),
          field(birthDate, 'Doğum Tarihi (YYYY-AA-GG)'),
          field(email, 'E-posta', keyboard: TextInputType.emailAddress), // @ tuşu olan klavye
          field(phone, 'Telefon', keyboard: TextInputType.phone), // Rakam klavyesi
          // Kaydederken onPressed null olur: buton gri görünür ve basılamaz.
          FilledButton(
            onPressed: saving ? null : save,
            child: saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
