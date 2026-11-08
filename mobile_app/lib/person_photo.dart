import 'package:flutter/material.dart';

// Dairesel profil fotoğrafı. Liste ve detay sayfasında ortak kullanılır.
// Fotoğraf ağdan (API'den) yüklenirken dönen bir animasyon, yüklenemezse kişi ikonu gösterir.
// Kendi içinde değişen bir veri tutmadığı için StatelessWidget.
class PersonPhoto extends StatelessWidget {
  final String url;
  final double radius; // Dairenin yarıçapı; genişlik ve yükseklik bunun 2 katı

  // Kullanım: PersonPhoto(url: ..., radius: 20). Listede 20, detayda 60 verilir.
  const PersonPhoto({super.key, required this.url, required this.radius});

  @override
  Widget build(BuildContext context) {
    // Fotoğraf yoksa veya yüklenemezse gösterilecek yedek görünüm: içinde kişi ikonu olan daire.
    final placeholder = CircleAvatar(radius: radius, child: Icon(Icons.person, size: radius));
    // Adres boşsa ağa hiç istek atmadan yedek görünümü döndür.
    if (url.isEmpty) return placeholder;

    // ClipOval: kare resmi daire şeklinde kırpar.
    return ClipOval(
      // Image.network: resmi verilen internet adresinden indirip gösterir.
      child: Image.network(
        url,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover, // Resmi bozmadan daireyi tamamen dolduracak şekilde ölçekle
        // Yüklenirken: progress null değilse indirme sürüyor demektir, dönen çember göster.
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child; // Yükleme bitti, resmin kendisini göster
          // Çember, fotoğrafla aynı boyutta bir kutuya konur; böylece yükleme bitince düzen kaymaz.
          return SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
        // Hata olursa (sunucu kapalı, adres yanlış, internet yok): kişi ikonu göster.
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}
