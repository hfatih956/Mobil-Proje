// Flutter'ın hazır arayüz parçaları (Material Design): MaterialApp, Scaffold, Text, Colors vb.
import 'package:flutter/material.dart';

// Açılışta gösterilecek liste sayfası.
import 'list_page.dart';

// Uygulamanın başlangıç noktası.
// Dart her programı main() fonksiyonundan başlatır. runApp verilen widget'ı ekrana yerleştirir.
void main() {
  runApp(const MyApp());
}

// Uygulamanın kök widget'ı. İçinde zamanla değişen bir veri olmadığı için StatelessWidget.
class MyApp extends StatelessWidget {
  // super.key: Flutter'ın widget'ları birbirinden ayırt etmek için kullandığı anahtarı üst sınıfa iletir.
  const MyApp({super.key});

  // build: bu widget'ın ekranda neye benzeyeceğini döndürür.
  // @override: üst sınıftaki (StatelessWidget) build metodunu kendi versiyonumuzla değiştirdiğimizi belirtir.
  @override
  Widget build(BuildContext context) {
    // MaterialApp: tema, sayfa geçişleri (Navigator) ve uygulama adı gibi genel ayarları sağlar.
    return MaterialApp(
      title: 'Kişi Rehberi',
      debugShowCheckedModeBanner: false, // Sağ üstteki "DEBUG" etiketini gizler.
      theme: ThemeData(colorSchemeSeed: Colors.indigo), // Uygulamanın tema rengi; bütün renkler bundan türetilir.
      home: const ListPage(), // Açılışta gösterilen sayfa.
    );
  }
}
