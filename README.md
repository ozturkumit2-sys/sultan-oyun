# FUSE CHEF: Çılgın Mutfak Savaşı

Malzemeleri birleştir, çılgın yemekler pişir, rakiplerin sabotajlarına karşı koy ve üç eksantrik jüriden sağ çık!
Godot 4.5 (GDScript) ile geliştirilmiş, dikey ekranlı, tamamen çevrimdışı oynanan bir Android oyunu.

**İndirme:** En güncel APK bu deponun [Releases](../../releases) sayfasında (`fusechef-v...` etiketli sürümler).

## Oyunda neler var?

- **Füzyon motoru:** 33 malzeme (+3 laboratuvara özel fermente malzeme), 37 el yapımı tarif (5 tanesi gizli), sınırsız dinamik tarif. Aynı malzemeler + aynı yöntem = her zaman aynı tarif; malzeme sırası önemsiz. Keşfedilen füzyonlar tekrar malzeme olarak kullanılabilir (zincir sınırı 2, uzmanlıkla 3).
- **6 pişirme yöntemi** ve her biri için etkileşimli mini oyun (zamanlama, basılı tutma, rün yakalama).
- **8 rakip:** Cadı Morgana, Robot X-3000, Zombi Nine Gülizar, Kont Velvet, Kaptan Barbunya, Uzaylı Zorp, Peri Lila ve son boss Şef Obscura. Her birinin kişiliği, tercih ettiği malzemeleri, özel sabotajı, boss kuralı ve zafer/yenilgi replikleri var. Yapay zekâ temaya, skor durumuna ve jüri mutasyonlarına göre karar verir.
- **Sabotaj sistemi:** Her sabotaj önceden uyarılır; *Savun* (mini oyun), *Uyum Sağla* veya *Riski Kabul Et* (geri tepme şansı). Hiçbir sabotaj kaçınılmaz yenilgi yaratmaz.
- **Canlı yemekler:** Zıplayan, koşan, saklanan, süzülen, çatal çalan ve kılık değiştiren yemekler için 6 dokunmatik yakalama oyunu.
- **3 jüri:** Şef Bruno (lezzet), Profesör Mira (yaratıcılık), Lord Max (sunum). Her puan yemeğin gerçek özelliklerinden ve oyuncu kararlarından hesaplanır ve gerekçesiyle gösterilir.
- **8 jüri mutasyonu** (görsel, damak değişimi, kaos), **jüri tartışmaları** (puanı en fazla ±1 etkileyen adil seçenekler), 10 tepki animasyonu.
- **Kariyer:** 5 lig × 3 maç, yıldızlar, lig kuralları, boss maçları, tekrar oynama.
- **Kaos Lab**, **Tarif Kitabı** (ipuçları, deneyler, gizli karakterler, mutasyon koleksiyonu, başarımlar), **Günlük Meydan Okuma** (tarihten deterministik), **Dükkân**, **Şef özelleştirme** ve **4 uzmanlık ağacı**.
- Sürümlü, doğrulanan ve atomik yazılan **yerel kayıt** (yedekli).
- Tüm karakterler, yemekler, ikonlar, müzikler ve ses efektleri bu proje için **özgün olarak üretildi** (telifli içerik yok).

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
data/                 Oyun içeriği (JSON): malzemeler, tarifler, temalar, jüri, rakipler, ligler, kozmetikler
scenes/               Gerekli sahneler (Boot, MainMenu, ChefCustomization, CareerMap, KitchenBattle,
                      FusionLab, JudgingStage, Results, RecipeBook, DailyChallenge, Settings, Shop)
scripts/autoload/     GameManager, SaveManager, AudioManager, IngredientDatabase, RecipeBookManager,
                      ProgressionManager, BattleManager, DailyChallengeManager, MonetizationService
scripts/systems/      FusionEngine, JudgeSystem, MutationSystem, SabotageSystem, OpponentAI, LivingFoodController
scripts/visual/       DrawKit, CharacterFigure, CharacterAnimationController, DishView, IngredientIcon, Backdrop, FxBurst
scripts/ui/           Arayüz bileşenleri (KitchenStation, CookingMinigame, DefendMinigame, SabotageDialog, ...)
scripts/ui/scenes/    Sahne betikleri
assets/               Yazı tipi (Baloo 2, OFL), UI ikonları, ses ve müzik
tools_src/            Ses/ikon üretim betikleri (Python)
_dev/                 Geliştirme testleri (dışa aktarıma dahil edilmez)
```

Oyun mantığı (`scripts/systems`, `scripts/autoload`) görsel sunumdan ayrıdır. Yeni tarif, tema veya rakip eklemek için çoğu zaman sadece `data/` altındaki JSON dosyalarını düzenlemek yeterlidir.

## Geliştirme testleri

```bash
godot --headless res://_dev/sim.tscn          # mantık testi: determinizm, puanlama, tüm kariyerin bot ile simülasyonu
godot --headless res://_dev/check_all.tscn    # tüm betiklerin derlenme kontrolü
godot --headless res://_dev/flow.tscn -- soak # gerçek arayüz akışlarıyla rastgele maçlar oynayan dayanıklılık testi
```

## Bilinen sınırlamalar

- Günlük meydan okuma cihaz saatine bağlıdır; çevrim içi sıralama yoktur (mimari buna hazırdır).
- Reklam/satın alma entegrasyonu yoktur; `MonetizationService` yalnızca gelecekteki kozmetik/ödüllü reklam seçenekleri için arayüz sağlar. Temel ilerleme hiçbir zaman reklama bağlı değildir.
- Karakterler prosedürel vektör çizimdir (sprite sanatı değil); bu sayede kozmetikler ve mutasyonlar gerçek zamanlı birleşir.

## Lisans notları

- Yazı tipi: Baloo 2 — SIL Open Font License 1.1 (`assets/fonts/Baloo2-OFL.txt`).
- Diğer tüm görsel ve işitsel içerik bu proje için üretilmiştir.
