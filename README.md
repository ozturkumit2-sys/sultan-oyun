# Çatı Kedisi: İstanbul

Astro's Playroom tarzı, renkli bir 3B platform oyunu. Tarçın adlı turuncu tekir kedi, Karaköy rıhtımından Galata Kulesi'nin tepesine kadar çatılarda koşar, zıplar ve kayıp yavruları kurtarır.

**İndirme:** APK dosyası [Releases](../../releases) sayfasında, `cati-kedisi-v…` etiketiyle.

## Bölüm 1: Galata Çatıları
- Karaköy çatıları, tente sokağı ve halı köprüsü, bacalar ve martılar, nostaljik tramvay, duvar zıplama sokağı, Galata Kulesi tırmanışı
- 5 kayıp yavru: Duman, Kömür, Pamuk, Tekir, Bal
- Balıklar (hamsi) ve altın balıklar, kontrol noktası olarak mama kapları

## Kedi Evi (ana üs)
- Tarçın'ın çatı katı evi: kurtarılan yavrular burada yaşar, minderlerde uyur, Tarçın'ı karşılar
- Şapkacı Dede'nin dükkânı: toplanan balıklarla fes, kasket, sardunya, vapurcu şapkası, altın taç, gözlükler ve renkli atkılar
- Bölüm kapıları: Galata Çatıları (açık), Kapalıçarşı (yakında)

## Kontroller (dokunmatik)
- Sol tarafta kaydır: koş
- Pati düğmesi: zıpla. Havadayken tekrar bas: çift zıplama
- Ok düğmesi: atılma. Martıları kovalar, uzak boşlukları geçer
- Duvara doğru düşerken zıpla: duvar zıplaması
- Sağ tarafta kaydır: kamerayı çevir

## Teknik
- Godot 4.7.1, GL Compatibility renderer, Android (arm64 + armv7)
- Kedi, kuşlar ve balık modelleri Blender (bpy) betikleriyle üretildi: `_src/blender/`
- Şehir, kule ve sahne prosedürel olarak kodla kuruluyor: `scripts/city.gd`, `scripts/level_galata.gd`
- Ses efektleri ve müzik (Hicaz makamında saz, ney, darbuka) Python ile sentezlendi: `_src/audio/gen_audio.py`
- Yazı tipi: Baloo 2 (SIL Open Font License)
- `_keys/test-release.keystore` yalnızca test APK'ları içindir; Google Play için ayrı bir yükleme anahtarı kullanılacak.
- Oynanış testleri: `tools/autotest.tscn` (headless), ekran görüntüsü: `tools/shot.tscn`
