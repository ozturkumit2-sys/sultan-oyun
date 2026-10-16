# Translation conventions (Office Poltergeist)

Files: `_dev/i18n/<code>/c000.txt` … one line per unit: `id|text` (`\n` = line break).
English source: `_dev/i18n/chunks/en_NNN.txt` (`id|key|text`). Build: `python3 _dev/i18n/build_lang.py`.

## Placeholders
- `{x}` keep every placeholder of the English line (names, items, numbers).
- `{x:case}` grammar endings. Turkish: `in` (Selin'in), `i` (Selin'i), `e` (Selin'e), `de` (Selin'de),
  `den` (Selin'den), `le` (Selin'le), `dir`, `si` (3rd person possessive: kupa → kupası, bellek → belleği). Irregular words: `tr/extra.json` "gram.<case>.<word>". German: `s` (Selins / Deniz’). Names get the apostrophe
  automatically in Turkish. Do not use endings on times/numbers.
- `{x?masc|fem}` word chosen by the gender of the person in x. `{me?..|..}` = the speaker (speech lines,
  memories, mood/emotion words, plans), `{to?..|..}` = the person spoken to (speech lines only).
- Ahmet, Mert, Burak, Deniz = male; Selin, Zeynep, Ece, Ceren = female.

## Names
| id | zh | hi |
|---|---|---|
| ahmet | 艾哈迈特 | अहमत |
| selin | 塞琳 | सेलिन |
| mert | 梅尔特 | मेर्ट |
| zeynep | 泽内普 | ज़ेनेप |
| burak | 布拉克 | बुराक |
| ece | 艾杰 | एजे |
| deniz | 德尼兹 | डेनिज़ |
| ceren | 婕伦 | जेरेन |
Other languages keep the Latin names. "Ahmet Bey" stays "Ahmet Bey" (tr/de/es/fr), zh 艾哈迈特先生, hi अहमत साहब.

## Register
- tr: colleagues "sen", boss addressed "siz"/"Ahmet Bey". Lively, colloquial Istanbul office Turkish.
- de: colleagues "du", the boss is addressed with "Sie". Colloquial.
- es: neutral Spanish, "tú", plural "ustedes" (no vosotros), "computadora".
- fr: "tu" between colleagues, "vous" to the boss. Typography: « » and space before : ; ! ?
- zh: Simplified, colloquial, punchy; full-width punctuation.
- hi: colloquial Hindustani office Hindi; common English office words in Devanagari (ऑफ़िस, मीटिंग, बॉस,
  प्रिंटर, ईमेल, प्रमोशन, फ़ाइल). Verb gender via {x?..|..}.

## Terms
| en | tr | de | es | fr | zh | hi |
|---|---|---|---|---|---|---|
| the ghost (player) | hayalet | der Geist | el fantasma | le fantôme | 幽灵 | भूत |
| meddle / meddling | müdahale (etmek), kurcalamak | sich einmischen / Einmischung | entrometerse / travesura | manigancer / manigance | 捣乱 | दखल / शरारत |
| Meddles (journal) | Müdahaleler | Einmischungen | Travesuras | Manigances | 捣乱手段 | शरारतें |
| Discovery Journal | Keşif Günlüğü | Entdeckungsbuch | Diario de descubrimientos | Carnet de découvertes | 发现日志 | खोज डायरी |
| Gossip Board | Dedikodu Panosu | Tratsch-Pinnwand | Tablón de chismes | Tableau des ragots | 八卦板 | गपशप बोर्ड |
| Personnel file | Personel Dosyası | Personalakte | Expediente | Dossier du personnel | 人事档案 | कर्मचारी फ़ाइल |
| Promotion file | Terfi Dosyası | Beförderungsakte | Expediente de ascensos | Dossier des promotions | 晋升档案 | प्रमोशन फ़ाइल |
| Meeting board | Toplantı Panosu | Meeting-Tafel | Tablero de reuniones | Tableau des réunions | 会议白板 | मीटिंग बोर्ड |
| Light breaker | Sigorta Kutusu | Sicherungskasten | Cuadro eléctrico | Disjoncteur | 电闸 | मेन स्विच |
| rumour | söylenti | Gerücht | rumor | rumeur | 传言 | अफ़वाह |
| secret combination | GİZLİ KOMBİNASYON | GEHEIME KOMBINATION | COMBINACIÓN SECRETA | COMBINAISON SECRÈTE | 秘密组合 | गुप्त कॉम्बो |
| story (arc) | hikâye | Geschichte | historia | histoire | 故事 | कहानी |
| promotion | terfi | Beförderung | ascenso | promotion | 晋升 | प्रमोशन |
| meeting | toplantı | Meeting | reunión | réunion | 会议 | मीटिंग |
| desk | masa | Schreibtisch | escritorio | bureau | 工位 | डेस्क |
| The Daily Grind (paper) | GÜNLÜK KOŞTURMACA | DER TÄGLICHE TROTT | LA RUTINA DIARIA | LE TRAIN-TRAIN | 每日打工报 | रोज़ की चक्की |

## Where the gender of a person is known
`{me?..|..}` works only in: speech lines (D), `mem.*`, `mood.*`, `emo.*`, `plan.*`, `bond.*`.
Everywhere else (ui.*, why.*, state.*, iv.*, …) write gender-neutral; role placeholders like
`{actor?..|..}` work wherever that placeholder exists in the English line.

## Word genders and special forms (extra.json per language)
- `gender.<word>`: "m" / "f" / "n" / "p" for nouns that get inserted (items, objects).
  `{item?A|B|C|D}` = masculine | feminine | neuter | plural (missing slots → first).
- `gram.<case>.<word>`: any custom form, e.g. fr `gram.le.étui à lunettes` = "l'étui à lunettes",
  tr `gram.i.şarj aleti` = "şarj aletini". A template uses it as `{item:le}`.
- Turkish built-in cases also: `m` (my: kupam, belleğim), `n` (your: kupan).
- Items: tr şarj aleti, okuma gözlüğü, uğurlu kupa, ajanda, USB bellek
  de Ladegerät(n), Lesebrille(f), Glückstasse(f), Terminplaner(m), USB-Stick(m) — no article in the value
  es cargador(m), estuche de gafas(m), taza de la suerte(f), agenda(f), memoria USB(f) — no article
  fr chargeur(m), étui à lunettes(m), tasse porte-bonheur(f), agenda(m), clé USB(f) — no article; cases le/du/mon/ton/son in extra
  zh 笔记本充电器, 老花镜, 幸运马克杯, 日程本, U盘
  hi लैपटॉप चार्जर, पढ़ने का चश्मा, लकी मग, प्लानर, यूएसबी — all masculine
- Turkish possessed+case: `sini` (kupasını, belleğini), `sine`, `sinde`, `sinden`, `sinin`. "found their mug" → `{item:sini} buldu`.
- German items in sentences: use the article form `{item?den|die|das} {item}` (accusative) or the name genitive `{owner:s} {item}`.
- `{choice}` (only in log.iv.confidential_doc) is an internal id — leave it out of translations.

## Running jokes
- 'World's Best Boss' mug: tr 'Dünyanın En İyi Patronu', de „Bester Chef der Welt“, es «El mejor jefe del mundo»,
  fr « Meilleur patron du monde », zh “世界最佳老板”, hi 'दुनिया का सबसे अच्छा बॉस'.
- misprinted replacement 'World's Best Bass': tr 'Dünyanın En İyi Paronu', de „Bester Chaf der Welt“,
  es «El mejor jefe del mudo», fr « Meilleur poltron du monde », zh “世界最佳老扳”, hi 'दुनिया का सबसे अच्छा बोस'.
- lira: de Lira, es liras, fr lires, zh 里拉, hi लीरा.
- Ece's "Uncle" slip and her lie (chunk 22 dialogue + log 1902). Ahmet is her MOTHER's brother (line 4320), so:
  tr Dayı → "daha dedim", de Onkel → „Knöchel“, es tío → «frío», fr Tonton → « menton », zh 舅舅 → “救救”,
  hi मामा → "मामला". niece: tr yeğen, zh 外甥女, hi भांजी.

## Dialogue register (decided at chunk 14)
- Colleague ↔ colleague: tr sen, de du, es tú, fr tu, hi तुम.
- Anyone → Ahmet: tr siz / "Ahmet Bey", de Sie, es usted, fr vous, hi आप / "अहमत साहब".
- Ahmet → employees: tr sen, de Sie, es tú, fr vous, hi आप.
- Generic speaker lines ("_") can be said by anyone: gendered words via {me?m|f}; Hindi first-person verbs always {me?..|..}.
- obj values carry their article in es/fr ({obj} = "la impresora"); de has no article → {obj?der|die|das} {obj}
  (m|f|n: Drucker m, Kaffeemaschine f, Tastatur f, Licht n); lights are plural in es/fr/hi (4th slot "p").
- what.boss_folder/dayoff_vanish/job_ads/layoff_mail/prank_call are spoken by Ahmet (ivm_boss_ask) → formal "your" in de (Ihr), fr (votre), hi (आपका).
