# Translation conventions (Office Poltergeist)

Files: `_dev/i18n/<code>/c000.txt` … one line per unit: `id|text` (`\n` = line break).
English source: `_dev/i18n/chunks/en_NNN.txt` (`id|key|text`). Build: `python3 _dev/i18n/build_lang.py`.

## Placeholders
- `{x}` keep every placeholder of the English line (names, items, numbers).
- `{x:case}` grammar endings. Turkish: `in` (Selin'in), `i` (Selin'i), `e` (Selin'e), `de` (Selin'de),
  `den` (Selin'den), `le` (Selin'le), `dir`. German: `s` (Selins / Deniz’). Names get the apostrophe
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
