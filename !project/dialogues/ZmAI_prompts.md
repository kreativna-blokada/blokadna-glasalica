# ZmAI upiti

Sve što `ZmAI_updater.py` šalje ZmAI-ju, osim pravila iz `ZmAI_dialogues.md` (`# Deo 1: Pravila za prompt`).

- Skripta čita samo tekst unutar `~~~` bloka ispod svakog `##` naslova; naslove ne menjati.
- `$ime` je mesto koje skripta popunjava; dozvoljena su samo imena navedena iznad bloka.
- Tonovi moraju ostati `angry` i `polite`, jer se po njima imenuju fajlovi dijaloga.
- Nivoi odgovora su u obliku `+nivo: značenje`; najviši pozitivan nivo vredi najviše bodova u postojećem sadržaju.

## Upit za dijalog

Mesta: `$prompt_rules`, `$stop_title`, `$stop_content`, `$personality`, `$tone`, `$sample_dialogues`, `$covered_scenarios`, `$crta_material`.

~~~
$prompt_rules

# Tačka izbornog procesa: $stop_title

$stop_content

## Ton dijaloga: $personality

$tone

## Postojeći dijalozi za ovu tačku

Ovi dijalozi određuju ton, stil, dužinu i ceo pristup budućih dijaloga. Prati ih.

$sample_dialogues

## Već pokriveni scenariji, ne ponavljati ih

$covered_scenarios

## Crta Q&A o ovoj tački

$crta_material

## Zahtev

Napiši JEDAN novi dijalog za tačku „$stop_title”, sa novim scenarijom greške ili prekršaja birača ili člana biračkog odbora, tačan prema zakonu i materijalu Crte.
- Ista JSON struktura kao u postojećim dijalozima: "root", "text", "speaker" (LEFT je član odbora, RIGHT birač), "next", "choices" sa "text", "explanation", "next".
- Svaki čvor sa izborima ima bar jedan ispravan odgovor, a dijalog ima bar jedan pogrešan.
- Bez oznaka [ANG] ili [POL] u tekstu.
- Vrati samo JSON, bez ikakvog drugog teksta.
~~~

## Deo upita

Šalje se kada je upit duži od jedne poruke, za svaki deo osim poslednjeg. Mesta: `$part_index`, `$part_count`, `$part_text`.

~~~
Upit stiže u $part_count delova, ovo je deo $part_index. Samo potvrdi prijem jednom rečju i ne odgovaraj na upit dok ne stigne poslednji deo.

$part_text
~~~

## Poslednji deo upita

Šalje se kao poslednji deo upita podeljenog na delove. Mesta: `$part_index`, `$part_count`, `$part_text`.

~~~
Ovo je poslednji deo upita, deo $part_index od $part_count. Spoji ga sa prethodnim delovima i odgovori na ceo upit.

$part_text
~~~

## Ton: angry

~~~
Član biračkog odbora (LEFT) je nestrpljiv, grub i nervozan.
~~~

## Ton: polite

~~~
Član biračkog odbora (LEFT) je ljubazan, smiren i strpljiv.
~~~

## Bez materijala Crte

Šalje se umesto `$crta_material` kada za tačku nema Crta Q&A teksta.

~~~
Nema dodatnog materijala, osloni se na svoju bazu znanja Crte.
~~~

## Upit za ocenu

Mesta: `$answer_levels`, `$dialogue`.

~~~
Oceni svaki odgovor u ovom dijalogu jednim nivoom sa skale. Ispravni odgovori dobijaju pozitivan nivo, a pogrešni negativan, čija veličina zavisi od težine prekršaja.

$answer_levels

$dialogue

Vrati samo JSON u obliku {"id_čvora": [nivo prvog odgovora, nivo drugog odgovora, ...]}, za svaki čvor sa izborima, redom kojim su odgovori navedeni.
~~~

## Nivoi odgovora

~~~
+10: potpuno ispravno, štiti proceduru i prava birača
+8: ispravno, ali tek nakon ispravke ili uz manji propust
+5: delimično ispravno, npr. traženje objašnjenja ili popuštanje
+3: prihvatljivo, ali stvara zastoj ili nepotrebnu tenziju
-1: sitna greška bez posledica po zakonitost, npr. dobrovoljno otkrivanje glasa
-2: nepristojnost ili proceduralna greška bez zloupotrebe
-3: preskakanje ili odbijanje obavezne procedure
-4: ugrožavanje tajnosti glasanja ili identifikacije birača
-5: omogućavanje nezakonitog glasanja
-6: izborna prevara: glasanje ili potpis za drugog, više listića, iznošenje listića
~~~

## Ispravka odgovora

Šalje se kada ZmAI vrati neispravan JSON. Mesta: `$answer_error`.

~~~
Odgovor nije ispravan: $answer_error. Vrati ponovo samo ispravljen JSON, bez ikakvog teksta.
~~~
