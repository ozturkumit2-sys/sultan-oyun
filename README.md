# FUSE CHEF: Çılgın Mutfak Savaşı

Malzemeleri birleştir, çılgın yemekler pişir, rakiplerin sabotajlarına karşı koy ve üç eksantrik jüriden sağ çık!
Godot 4.5 (GDScript) ile geliştirilmiş, dikey ekranlı, tamamen çevrimdışı oynanan bir Android oyunu.

**İndirme (telefon):** [FuseChef.apk — doğrudan indir](https://github.com/ozturkumit2-sys/sultan-oyun/raw/fuse-chef/apk/FuseChef.apk)

APK her zaman bu dalın `apk/` klasöründe en güncel hâliyle durur. İndirdikten sonra dosyayı aç; Android "bilinmeyen kaynak" izni isterse bu kurulum için izin ver. Yeni sürüm eskisinin üzerine kurulur, kayıtların korunur.

## Oyunda neler var?

- **Füzyon motoru:** 56 malzeme (tavuk, balık, et, karides, sucuk gibi normal malzemeler ve ejder yumurtası, kara delik tuzu gibi garip malzemeler; 3'ü laboratuvara özel), 50 el yapımı tarif (5 tanesi gizli), sınırsız dinamik tarif. Aynı malzemeler + aynı yöntem = her zaman aynı tarif; malzeme sırası önemsiz. Keşfedilen füzyonlar tekrar malzeme olarak kullanılabilir (zincir sınırı 2, uzmanlıkla 3).
- **Hikâyeli isimler:** 3 ve daha fazla malzemeli karışımlar malzemeleri saymayan, yemeğin karakterinden doğan bir isim ("Acı Ninja Hayalet", "Serin Yarasa: Tencerenin İntikamı") ve kısa bir efsane alır. İsimler her dilde o dilin dil bilgisine göre üretilir ("Spicy Ghost: The Return", "Fantasma Picante: El Regreso", "激辛ゴースト：帰還").
- **8 dil:** Türkçe, English, Español, Deutsch, العربية, हिन्दी, 简体中文, 日本語. İlk açılışta cihaz dili seçilir (desteklenmiyorsa İngilizce); **Ayarlar → Dil** ile istenildiği an değiştirilir. Arayüz, malzemeler, tarifler, jüri yorumları ve rakip replikleri dahil tüm metinler çevrilidir. Arapçada arayüz sağdan sola aynalanır; Arapça, Çince ve Japonca için ek yazı tipleri gömülüdür.
- **Dokunmatik kaydırma:** Tüm listeler parmakla yukarı/aşağı (ve yatay listeler sağa/sola) sürüklenerek, ataletle kaydırılır; kaydırırken kartlara yanlışlıkla dokunulmaz.
- **6 pişirme yöntemi** ve her biri için etkileşimli mini oyun (zamanlama, basılı tutma, rün yakalama).
- **15 farklı rakip:** Cadı Morgana, Robot X-3000, Zombi Nine Gülizar, Kont Velvet, Kaptan Barbunya, Uzaylı Zorp, Peri Lila, Palyaço Pofuduk, Dino Rexi, Ninja Kage, Yeti Kartopu, Mumya Nefer, Aşçıbaşı Kavukçu, Ejder Leydi Alevna ve son boss Şef Obscura. Kariyerdeki 15 maçın her birinde başka bir rakip var. Her birinin kendine özgü görünüşü, kişiliği, sevdiği malzemeleri, özel sabotajı (14 farklı sabotaj), boss kuralı ve replikleri var. Yapay zekâ temaya, skor durumuna ve jüri mutasyonlarına göre karar verir.
- **Sabotaj sistemi:** Her sabotaj önceden uyarılır; *Savun* (mini oyun), *Uyum Sağla* veya *Riski Kabul Et* (geri tepme şansı). Hiçbir sabotaj kaçınılmaz yenilgi yaratmaz.
- **Canlı yemekler:** Zıplayan, koşan, saklanan, süzülen, çatal çalan ve kılık değiştiren yemekler için 6 dokunmatik yakalama oyunu.
- **3 jüri:** Şef Bruno (lezzet), Profesör Mira (yaratıcılık), Lord Max (sunum). Her puan yemeğin gerçek özelliklerinden ve oyuncu kararlarından hesaplanır ve gerekçesiyle gösterilir. Her jürinin 150'den fazla bağlama duyarlı yorumu var (puan seviyesi, mutasyon, canlı yemek, ilk keşif, tekrar, lanetli malzeme, gizemli malzeme, sevdiği/sevmediği malzemeler, pişirme yöntemi, tartışmalar); yorumlar yemeğin ve malzemelerin adını anar ve kısa sürede tekrarlanmaz.
- **8 jüri mutasyonu** (görsel, damak değişimi, kaos), **jüri tartışmaları** (puanı en fazla ±1 etkileyen adil seçenekler), 10 tepki animasyonu.
- **Kariyer:** 5 lig × 3 maç, yıldızlar, lig kuralları, boss maçları, tekrar oynama.
- **Rövanş Ligi (6. lig):** Final bitince açılır; yenilen bosslar intikam görünümüyle geri döner: Kara Morgana, X-9000 Omega ve Kızıl Obscura (bütün sabotajları öğrenmiş, her turda iki saldırı).
- **İntikam ve rövanş maçları:** Kazandığın bir maçı tekrar oynarsan rakip *intikam modunda* gelir (daha usta, özel replikler); kaybettiğin bir maçı tekrar oynarsan *rövanş* olur. İkisinde de kazanırsan bonus para alırsın.
- **Kaos Lab**, **Tarif Kitabı** (ipuçları, deneyler, gizli karakterler, mutasyon koleksiyonu, başarımlar), **Günlük Meydan Okuma** (tarihten deterministik), **Dükkân**, **Şef özelleştirme** ve **4 uzmanlık ağacı**.
- Sürümlü, doğrulanan ve atomik yazılan **yerel kayıt** (yedekli).
- Tüm karakterler, yemekler, ikonlar, müzikler ve ses efektleri bu proje için **özgün olarak üretildi** (telifli içerik yok).

## Google Play sürümü (v1.0.0)

- **Play Console'a yüklenecek dosya:** [`release/FuseChef-v1.0.0-release.aab`](https://github.com/ozturkumit2-sys/sultan-oyun/raw/fuse-chef/release/FuseChef-v1.0.0-release.aab) — yükleme anahtarıyla imzalı Android App Bundle.
- **Telefonda deneme APK'sı:** [`release/FuseChef-v1.0.0-test.apk`](https://github.com/ozturkumit2-sys/sultan-oyun/raw/fuse-chef/release/FuseChef-v1.0.0-test.apk) — aynı paketin evrensel APK'sı. Play sürümünü kurmadan önce kaldırılmalıdır (imzalar farklıdır).
- Paket: `com.fusegames.fusechef` · Sürüm: 1.0.0 (kod 1) · minSdk 24 · targetSdk 36 · ABI: arm64-v8a, armeabi-v7a, x86_64.
- İzinler: yalnızca `VIBRATE` (titreşim ayarı için). İnternet izni yok; oyun tamamen çevrimdışıdır.
- 16 KB sayfa boyutu: `libgodot_android.so` ve `libc++_shared.so` ELF segmentleri 16 KB hizalı; AAB yapılandırması yerel kitaplıkları sıkıştırmasız ve 16 KB hizalı paketler.
- Play App Signing ile uyumludur: AAB yükleme anahtarıyla imzalanır, Google uygulamayı kendi uygulama imzalama anahtarıyla yeniden imzalar.
- **Keystore ve parola bu depoda yoktur ve asla eklenmemelidir** (depo herkese açık).

### AAB nasıl üretilir

Godot'nun Gradle'lı AAB yolu yerine Google'ın resmi araçlarıyla (aapt2 + bundletool) üretilir:

```bash
godot --headless --export-release Android build/release/FuseChef-v1.0.0.apk
FUSECHEF_KS_PASS='<keystore parolası>' python3 tools_src/android/build_aab.py \
    --apk build/release/FuseChef-v1.0.0.apk --out build/release/FuseChef-v1.0.0-release.aab \
    --bundletool bundletool-all-1.18.2.jar --keystore fusechef-upload.jks --alias fusechef-upload
```

Betik ayrıca Godot 4.5 dışa aktarımındaki iki kusuru düzeltir (silinmiş `themed_icon.xml` ve yinelenen `androidx.startup` sağlayıcı yetkisi) ve `targetSdkVersion` değerini 36'ya yükseltir. Her güncellemede `version/code` artırılmalı ve **aynı keystore** kullanılmalıdır.

## Projeyi açma ve çalıştırma

1. [Godot 4.5.x](https://godotengine.org/download) (standart sürüm, .NET gerekmez) indir.
2. Godot'yu aç → **İçe Aktar** → bu klasördeki `project.godot` dosyasını seç.
3. **F5** ile çalıştır. Oyun dikey (720×1280 tabanlı) tasarlanmıştır; masaüstünde pencere telefon oranında açılır.

Masaüstünde Esc tuşu Android'deki Geri tuşu gibi davranır.

## Android APK üretme

1. Godot'da **Editör → Dışa Aktarma Şablonlarını Yönet** ile 4.5.x şablonlarını indir.
2. **Editör Ayarları → Dışa Aktar → Android** bölümünde Android SDK ve Java (JDK 17+) yollarını ayarla.
3. **Proje → Dışa Aktar** → hazır "Android" ön ayarını seç → **Proje Dışa Aktar** (`build/FuseChef.apk`).
4. İmzalama: ön ayar imzasız APK üretir. Kendi anahtarınla imzalamak için `apksigner` kullanabilir ya da ön ayarda `package/signed` seçeneğini açıp keystore bilgilerini girebilirsin.

Komut satırından:

```bash
godot --headless --export-release Android build/FuseChef.apk
```

Mimari: `arm64-v8a` (2017 sonrası telefonların neredeyse tamamı). Paket adı: `com.umit.fusechef`.

## Klasör yapısı

```
data/                 Oyun içeriği (JSON): malzemeler, tarifler, temalar, jüri ve jüri replikleri, rakipler, ligler, kozmetikler
data/i18n/            Çeviriler: {"Türkçe kaynak metin": "çeviri"} (en, es, de, ar, hi, zh, ja)
data/names.json       Hikâyeli isim tabloları (her dil için; tools_src/names.py ile üretilir)
scenes/               Gerekli sahneler (Boot, MainMenu, ChefCustomization, CareerMap, KitchenBattle,
                      FusionLab, JudgingStage, Results, RecipeBook, DailyChallenge, Settings, Shop)
scripts/autoload/     GameManager, SaveManager, Loc (dil), AudioManager, IngredientDatabase, RecipeBookManager,
                      ProgressionManager, BattleManager, DailyChallengeManager, MonetizationService
scripts/systems/      FusionEngine, JudgeSystem, MutationSystem, SabotageSystem, OpponentAI, LivingFoodController
scripts/visual/       DrawKit, CharacterFigure, CharacterAnimationController, DishView, IngredientIcon, Backdrop, FxBurst
scripts/ui/           Arayüz bileşenleri (KitchenStation, CookingMinigame, DefendMinigame, SabotageDialog, ...)
scripts/ui/scenes/    Sahne betikleri
assets/               Yazı tipleri (OFL), UI ikonları, ses ve müzik
tools_src/            Ses/ikon/yazı tipi üretimi, jüri replikleri, isim tabloları ve çeviri betikleri (Python)
_dev/                 Geliştirme testleri (dışa aktarıma dahil edilmez)
```

Oyun mantığı (`scripts/systems`, `scripts/autoload`) görsel sunumdan ayrıdır. Yeni tarif, tema veya rakip eklemek için çoğu zaman sadece `data/` altındaki JSON dosyalarını düzenlemek yeterlidir.

### Çeviri iş akışı

Kaynak dil Türkçedir; koddaki görünür metinler `Loc.t("...")` ile, veri metinleri yüklenirken otomatik çevrilir.

```bash
python3 tools_src/i18n/extract.py .          # tüm Türkçe metinleri topla -> tools_src/i18n/keys.json
python3 tools_src/i18n/listing.py --stats    # eksik çevirileri listele
python3 tools_src/i18n/build.py . --strict   # tools_src/i18n/chunks/*.json -> data/i18n/*.json (yer tutucu denetimiyle)
python3 tools_src/names.py .                 # hikâyeli isim tabloları -> data/names.json
python3 tools_src/fonts.py <kaynak> .        # Arapça/Çince/Japonca yazı tipi alt kümeleri
```

## Geliştirme testleri

```bash
godot --headless res://_dev/sim.tscn          # mantık testi: determinizm, puanlama, tüm kariyerin bot ile simülasyonu
godot --headless res://_dev/check_all.tscn    # tüm betiklerin derlenme kontrolü
godot --headless res://_dev/flow.tscn -- soak # gerçek arayüz akışlarıyla rastgele maçlar oynayan dayanıklılık testi
godot --headless res://_dev/flow.tscn -- menus ar   # ekran görüntüleri (ikinci argüman: dil)
godot --headless res://_dev/names_test.tscn -- ja   # bir dilde hikâyeli isim örnekleri
```

## Bilinen sınırlamalar

- Günlük meydan okuma cihaz saatine bağlıdır; çevrim içi sıralama yoktur (mimari buna hazırdır).
- Reklam/satın alma entegrasyonu yoktur; `MonetizationService` yalnızca gelecekteki kozmetik/ödüllü reklam seçenekleri için arayüz sağlar. Temel ilerleme hiçbir zaman reklama bağlı değildir.
- Karakterler prosedürel vektör çizimdir (sprite sanatı değil); bu sayede kozmetikler ve mutasyonlar gerçek zamanlı birleşir.

## Lisans notları

- Yazı tipleri (hepsi SIL Open Font License 1.1, lisans metinleri `assets/fonts/` içinde): Baloo 2 (Latin, Devanagari), Baloo Bhaijaan 2 (Arapça), Noto Sans SC (Çince), M PLUS Rounded 1c (Japonca). CJK/Arapça yazı tipleri oyunda kullanılan karakterlere ve sık kullanılan karakter tablolarına göre alt kümelenmiştir.
- Diğer tüm görsel ve işitsel içerik bu proje için üretilmiştir.
