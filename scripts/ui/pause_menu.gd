class_name PauseMenu
extends BasePanel
## Oyun içi menü.

var game: Node


func open(g: Node) -> void:
	game = g
	setup_frame("Menü", 0.5, 0.86, "Devam Et")
	var v := UI.vbox(12)
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(v)
	v.add_child(UI.label(GameState.summary_text(), 20, UI.MUTED))
	v.add_child(UI.button("Oyunu Kaydet", func(): game.open_save_load(true), 60, true))
	v.add_child(UI.button("Kayıt Yükle", func(): game.open_save_load(false), 60))
	v.add_child(UI.button("Ayarlar", func(): game.open_settings(), 60))
	v.add_child(UI.button("Nasıl Oynanır?", func(): game.open_help(), 60))
	v.add_child(UI.button("Ana Menüye Dön", _to_menu, 60))


func _to_menu() -> void:
	if Settings.autosave:
		SaveSystem.save_game("oto")
	close_panel()
	game.to_main_menu()


class HelpPanel:
	extends BasePanel

	func open() -> void:
		setup_frame("Nasıl Oynanır?", 0.86, 0.9)
		var sc := UI.scroll()
		body.add_child(sc)
		var v := UI.vbox(10)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(v)
		var items := [
			["Hareket", "Sol alttaki joystick ile yürüyün; joystick'i sonuna kadar itince koşarsınız. Ekranın sağ tarafını sürükleyerek kamerayı döndürün, iki parmakla yakınlaştırın. Bilgisayarda: WASD, fare ile kamera, E etkileşim, Shift koşma, ESC menü."],
			["Etkileşim", "Bir karaktere ya da nesneye yaklaşınca sağ altta büyük bir düğme belirir: 'Konuş', 'Tahta Otur', 'Divanı Topla', 'Uyu' gibi. Boş bir sedirin yanında 'Otur' çıkar."],
			["Saray halkı", "Her karakterin kendi kişiliği, hedefleri, sırları ve günlük rutini vardır. Sevgi, güven, saygı, korku, kıskançlık gibi on ilişki boyutu ayrı ayrı izlenir. Ne söylediğiniz kadar, kime ve kimin önünde söylediğiniz de önemlidir; tanıklar hatırlar ve söylenti yayılır."],
			["Geçmişi keşfetmek", "'Kişisel konular' güven arttıkça karakterlerin sırlarını açar. Bazı sırlar yeni olayların ve özel konuşmaların kapısını aralar."],
			["Divan", "Divan Salonu'ndaki başköşeye oturup 'Divanı Topla' deyin. Gündem maddeleri eyaletlerin gerçek durumundan doğar. Vergiler, saray ve ordu bütçesi, eyalet yatırımları ve makam atamaları da buradadır. Devlet adamları kararlarınızı kişiliklerine göre destekler ya da hoşnutsuz olur."],
			["Halk", "Halk Kabul Salonu'nda 'Dilekçeleri Dinle' ile halkın şikâyetlerine hüküm verin. Adalet itibarınız ve eyaletlerin huzuru bundan etkilenir."],
			["Zaman", "Sol üstteki düğmelerle zamanı durdurun ya da hızlandırın. Gece Özel Daire'deki yatakta uyuyarak sabaha geçebilirsiniz. Ekonomi her ay başında hesaplanır."],
			["Kayıt", "Oyun her sabah ve uygulamadan çıkarken otomatik kaydedilir (ayarlardan kapatılabilir). Menüden üç ayrı yuvaya elle kaydedebilirsiniz."],
		]
		for it in items:
			v.add_child(UI.label(it[0], 24, UI.GOLD2, UI.font_semi))
			v.add_child(UI.wrap_label(it[1], 19, UI.CREAM))
