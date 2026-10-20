# Dijalozi na izbornom mestu

- [Deo 1: Pravila za prompt](#deo-1-pravila-za-prompt)
  - [Zadatak](#zadatak)
  - [Pravila na izborima](#pravila-na-izborima)
  - [Neka moguća scenarija](#neka-moguća-scenarija)
  - [Struktura dijaloga (uzorak)](#struktura-dijaloga-uzorak)
- [Deo 2: Rezultat (JSON)](#deo-2-rezultat-json)
  - [1) UV lampa](#1-uv-lampa)
  - [2) ID kontrola](#2-id-kontrola)
  - [3) Birački spisak](#3-birački-spisak)
  - [4) Nevidljivi sprej](#4-nevidljivi-sprej)
  - [5) Listić za glasanje](#5-listić-za-glasanje)
  - [6) Popunjavanje listića](#6-popunjavanje-listića)

---

# Deo 1: Pravila za prompt

## Zadatak

Cilj ovog zadatka je da napišemo dijaloge, ispod su pravila na izborima a potom i jedna struktura dijaloga.

Izborno mesto ima 7 pozicija na kojima glasač zastaje i odrađuje odgovarajuće izborne radnje:

1. UV lampa
2. ID kontrola
3. Spisak
4. Sprej
5. Listić
6. Izbor
7. Glasanje

Dijalozi postoje u prvih 6 koraka, u sedmom nema dijaloga, samo ubacivanje listića.

- Potrebno je izmisliti više dijaloga između kontrolora i birača, igrač bira odgovor birača.
- Potrebno je da dijalozi reflektuju sve moguće greške i prekršaje na svakoj od 6 pozicija.
- Istražiti online kao i u bazi ovog alata koji sve prekršaji i greške mogu da se dogode.
- Napisati dijaloge da poštuju različite tonove komunikacije definisane kao `angry` i `polite`.
- Nekada kontrolor može da pravi greške ili prekršaje a da ga birač koriguje, a i obrnuto.
- Pisati različite scenarije koji pokrivaju greške ili prekršaje i kontrolora i birača.
- Pogledati priloženi uzorak dijaloga, izmisliti dijaloge ali **nipošto ne menjati JSON strukturu**.

## Pravila na izborima

### Kako se glasa na biračkom mestu?

1. Prvo se UV lampom proverava da li je birač već glasao.
2. Birač potom daje ličnu kartu ili pasoš kako bi se utvrdio njegov identitet.
3. Birački odbor zatim proverava da li se birač nalazi u biračkom spisku, a kada ga pronađe, birač se potpisuje na svoje mesto u izvodu iz biračkog spiska (za svaki nivo izbora postoji poseban izvod iz biračkog spiska).
4. Biraču se na prst nanosi nevidljivi sprej.
5. Tek nakon toga se biraču daje listić za glasanje.
6. Birač odlazi iza paravana i popunjava glasački listić.
7. Nakon što birač glasačke listiće ubaci u kutije, odmah napušta biračko mesto.

### Pre nego što pođete na biračko mesto, važno je da znate ove stvari

- Možete da glasate sa dokumentom koji sadrži JMBG (jedinstveni matični broj građana), tj. s važećom ličnom kartom ili važećom putnom ispravom (pasošem); ukoliko ste započeli proceduru promene lične karte, potrebno je da kod sebe imate potvrdu MUP-a.
- U slučaju da ste promenili prezime, svakako možete glasati ako su drugi podaci (ime i JMBG) ostali isti.
- Da biste bili sigurni, na veb sajtu upit.birackispisak.gov.rs proverite na kojem biračkom mestu glasate.
- Možete da glasate i bez poziva za glasanje – taj poziv ne morate da ponesete na biračko mesto, niti birački odbor sme kao uslov za glasanje da postavi pokazivanje tog poziva.
- U slučaju da zbog teške bolesti, starosti ili invaliditeta niste u mogućnosti da glasate na biračkom mestu, možete glasati van biračkog mesta; sve što treba da uradite je da o tome obavestite lokalnu izbornu komisiju odnosno birački odbor najkasnije do 11 sati na dan glasanja. Spisak lokalnih izbornih komisija dostupan je na ovom linku.
- Glasanje je tajno – nikome ne morate da odgovorite da li ste i za koga glasali i zašto jeste ili niste glasali, bez obzira na to da li vam je takvo pitanje postavio član biračkog odbora, posmatrač, novinar ili neki drugi birač.
- Birački odbor je u obavezi da svim biračima koji se u trenutku kada se zatvara biračko mesto (u 20 časova) zateknu u ili ispred biračkog mesta omogući da glasaju.

### Ko sme na biračko mesto

Na biračko mesto smeju da uđu samo birači koji tu glasaju, članovi biračkog odbora i akreditovani posmatrači. Ulazak medijskih ekipa moguć je samo uz dozvolu biračkog odbora, a u slučaju incidenta, policija dolazi na poziv predsednika biračkog odbora.

Posmatrači na biračkom mestu prate proces glasanja, ali ne smeju da se mešaju ili utiču na bilo koga. O primećenim nepravilnostima i incidentima izveštavaju posmatračku misiju, koja dalje obaveštava javnost o dešavanjima na biračkom mestu i koristi informacije za ocenu izbornog dana.

## Neka moguća scenarija

Učesnici dijaloga:

- **Član biračkog odbora (kontrolor)** – učesnik dijaloga
- **Birač** – drugi učesnik dijaloga, koji odgovara, ukazuje na greške, propuste

| Situacija | Kao član biračkog odbora (kontrolor) | Kao birač |
|---|---|---|
| Neko iznosi listić sa biračkog mesta | Možeš da sprečiš birača da iznese glasački listić sa biračkog mesta pošto to ukazuje na mogućnost „karusel glasanja“, odnosno „bugarskog voza“. Zahtevaj da se pozove policija i da se unese primedba u zapisnik o radu biračkog odbora. | Možeš da skreneš pažnju članovima BO i zahtevaš da spreče iznošenje listića. |
| Birač je ubacio više od jednog listića u kutiju | Možeš da sprečiš „punjenje“ kutija tako što ćeš se starati o tome da svaki birač dobije samo jedan glasački listić. | Možeš da skreneš pažnju BO i zahtevaš da spreče nedozvoljeno postupanje. |
| Biraču je onemogućeno da glasa | Postaraj se da se svakom biraču koji je upisan u izvod iz biračkog spiska omogući da glasa. Ako se to ne desi, pozovi lokalnu izbornu komisiju radi konsultacija i unesi primedbu u zapisnik. | Možeš da podneseš zahtev za poništavanje glasanja na BM u roku od 72h od zatvaranja BM. |
| Glasao je birač koji nije upisan u izvod iz biračkog spiska | Možeš to da sprečiš ili bar da uneseš primedbu u zapisnik. | Možeš da skreneš pažnju biračkom odboru. |
| Povređena je tajnost glasanja | Postaraj se da se pravilno postave paravani i da se spreči da bilo ko prilazi biraču iza paravana. | Možeš da podneseš zahtev za poništavanje glasanja na BM u roku od 72h od zatvaranja BM. |
| Fotografisanje glasačkih listića | Možeš da podučiš birača da je glasanje tajno i slobodno, da podsetiš druge članove BO da je to zabranjeno, pa i da zahtevaš da se prekine glasanje. Svakako da uneseš primedbu u zapisnik. | Možeš da skreneš pažnju BO da spreče fotografisanje listića. |
| Glasanje bez lične karte | Postaraj se da birači budu adekvatno identifikovani i da onemogućiš birače bez lične karte ili pasoša da glasaju. Ako drugi članovi BO ignorišu tvoj zahtev, traži da se prekine glasanje dok se ne uspostavi red. | Možeš da skreneš pažnju BO. |
| Ne vrši se provera nevidljivog spreja UV lampom | Postaraj se da se birači koji imaju nevidljivi sprej na prstu spreče da ponovo glasaju. Ako drugi članovi BO ignorišu tvoj zahtev, traži da se prekine glasanje dok se ne uspostavi red. | Možeš da skreneš pažnju BO. |
| Biraču nije obeležen prst nakon preuzimanja glasačkog listića | Postaraj se da se nanosi sprej na prst birača nakon što je preuzeo glasački listić. Ako drugi članovi BO ignorišu tvoj zahtev, traži da se prekine glasanje dok se ne uspostavi red. | Možeš da skreneš pažnju BO na propust. |
| Fizičko nasilje na biračkom mestu | Možeš da zahtevaš da predsednik BO pozove policiju. | Možeš da zahtevaš od BO da se uspostavi red ili pozove policija. |
| Onemogućeno glasanje biračima koji su se pre 20h našli ispred biračkog mesta | Zahtevaj da se tim biračima omogući da glasaju, odnosno da ostvare svoje izborno pravo. Ako drugi članovi BO ignorišu tvoj zahtev, pozovi Lokalnu izbornu komisiju. | Ako ti je onemogućeno da glasaš a stigao si do 20h ispred BM, možeš da podneseš zahtev za poništavanje glasanja na biračkom mestu u roku od 72h. |

## Struktura dijaloga (uzorak)

Dijalozi treba da koriste sledeću strukturu:

### voter_lamp_dialog_angry_02.json

```json
{
  "root": {
    "text": "Na prstu vam se pod UV lampom vidi trag spreja. Ne možete nastaviti ka glasanju.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Nemoguće, nisam glasao! Proverite još jednom, ali nemojte me odmah odbijati.",
        "explanation": "Birač ima pravo da traži pažljivu proveru, ali procedura UV kontrole mora da se sprovede.",
        "score": 66000,
        "next": "second_check"
      },
      {
        "text": "Ma kakav sprej, pustite me da prođem ili pravim haos.",
        "explanation": "Pretnja i pokušaj preskakanja UV kontrole ometaju rad biračkog mesta.",
        "score": -52000,
        "next": "warning"
      },
      {
        "text": "U redu, ako se zaista vidi trag, neću nastaviti.",
        "explanation": "Ispravno je poštovati ishod obavezne UV provere.",
        "score": 131000
      }
    ]
  },
  "second_check": {
    "text": "Proverili smo ponovo i trag je i dalje vidljiv. Ne možete glasati i morate napustiti biračko mesto.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Tražim da se ovo zabeleži i da predsednik biračkog odbora bude obavešten.",
        "explanation": "Ispravno je tražiti da se sporna situacija evidentira, ali potvrđen trag spreja znači da birač ne može nastaviti glasanje.",
        "score": 131000
      },
      {
        "text": "Baš me briga, idem dalje dok me neko ne zaustavi.",
        "explanation": "Birač ne sme samovoljno nastaviti postupak kada je UV provera pokazala trag spreja.",
        "score": -52000
      }
    ]
  },
  "warning": {
    "text": "Ako nastavite da ometate rad, moraćemo da pozovemo predsednika biračkog odbora.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Dobro, smiriću se. Neka predsednik biračkog odbora odluči šta dalje.",
        "explanation": "Povratak mirnoj proceduri je bolji izbor od eskalacije.",
        "score": 66000
      },
      {
        "text": "Neću da čekam nikoga, sklanjajte se.",
        "explanation": "Nastavak pritiska na članove odbora je ozbiljno ometanje postupka.",
        "score": -79000
      }
    ]
  }
}
```

### voter_lamp_dialog_polite_02.json

```json
{
  "root": {
    "text": "Dobar dan. Molim vas, prvo ćemo proveriti ruku UV lampom.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Naravno. Samo me zanima zašto se to radi pre provere dokumenta.",
        "explanation": "Birač sme da traži objašnjenje procedure.",
        "score": 66000,
        "next": "explanation"
      },
      {
        "text": "Izvolite, spreman sam.",
        "explanation": "Ispravno, birač poštuje prvi korak postupka.",
        "score": 131000,
        "next": "clear"
      },
      {
        "text": "Radije bih prvo dao dokument, lampu možemo posle.",
        "explanation": "Redosled postupka treba poštovati; UV provera se obavlja pre nastavka glasanja.",
        "score": -13000,
        "next": "order_explained"
      }
    ]
  },
  "explanation": {
    "text": "UV lampom proveravamo da li već postoji trag nevidljivog spreja, odnosno da li je birač već glasao.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Hvala na objašnjenju, izvolite.",
        "explanation": "Birač prihvata objašnjenje i nastavlja postupak.",
        "score": 131000
      },
      {
        "text": "Razumem, ali voleo bih da svi u redu čuju isto objašnjenje.",
        "explanation": "Traženje jasnog objašnjenja može pomoći pravilnom sprovođenju postupka.",
        "score": 105000
      }
    ]
  },
  "clear": {
    "text": "Nema tragova spreja, možete dalje na proveru identiteta.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Hvala, nastavljam dalje.",
        "explanation": "Korektno sprovedena procedura i mirna komunikacija.",
        "score": 131000
      }
    ]
  },
  "order_explained": {
    "text": "Razumem, ali redosled je takav da se prvo radi UV provera.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "U redu, poštovaću redosled.",
        "explanation": "Birač se vraća propisanoj proceduri.",
        "score": 105000
      },
      {
        "text": "Ako nije po mom redosledu, odustajem.",
        "explanation": "Odustajanje je izbor birača, ali odbijanje procedure sprečava nastavak glasanja.",
        "score": -13000
      }
    ]
  }
}
```

---

# Deo 2: Rezultat (JSON)

## 1) UV lampa

Nekoliko primera prekršaja za UV lampu.

### Objašnjenje bodovanja

| Situacija | Bodovi |
|---|---|
| Korektno poštovanje procedure, pristojna komunikacija | +100 |
| Povratak proceduri nakon greške, prihvatanje objašnjenja | +50 do +80 |
| Traženje objašnjenja | +50 |
| Odustajanje od glasanja | -50 |
| Nepristojan ili agresivan odgovor | -100 |
| Odbijanje UV provere, eskalacija | -200 do -300 |

Ovi dijalozi pokrivaju tipične greške i prekršaje na UV lampi, uključujući i situacije kada kontrolor može da bude nepristojan ili neprofesionalan, kao i kada birač odbija proceduru ili traži objašnjenje.

> Izvor: Pravilnik o radu biračkih odbora, Crta edukativni materijali, iskustva sa terena.

### voter_lamp_dialog_angry_02.json

```json
{
  "root": {
    "text": "Na prstu vam se pod UV lampom vidi trag spreja. Ne možete nastaviti ka glasanju.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Nemoguće, nisam glasao! Proverite još jednom, ali nemojte me odmah odbijati.",
        "explanation": "Birač ima pravo da traži pažljivu proveru, ali procedura UV kontrole mora da se sprovede.",
        "score": 66000,
        "next": "second_check"
      },
      {
        "text": "Ma kakav sprej, pustite me da prođem ili pravim haos.",
        "explanation": "Pretnja i pokušaj preskakanja UV kontrole ometaju rad biračkog mesta.",
        "score": -52000,
        "next": "warning"
      },
      {
        "text": "U redu, ako se zaista vidi trag, neću nastaviti.",
        "explanation": "Ispravno je poštovati ishod obavezne UV provere.",
        "score": 131000
      }
    ]
  },
  "second_check": {
    "text": "Proverili smo ponovo i trag je i dalje vidljiv. Ne možete glasati i morate napustiti biračko mesto.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Tražim da se ovo zabeleži i da predsednik biračkog odbora bude obavešten.",
        "explanation": "Ispravno je tražiti da se sporna situacija evidentira, ali potvrđen trag spreja znači da birač ne može nastaviti glasanje.",
        "score": 131000
      },
      {
        "text": "Baš me briga, idem dalje dok me neko ne zaustavi.",
        "explanation": "Birač ne sme samovoljno nastaviti postupak kada je UV provera pokazala trag spreja.",
        "score": -52000
      }
    ]
  },
  "warning": {
    "text": "Ako nastavite da ometate rad, moraćemo da pozovemo predsednika biračkog odbora.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Dobro, smiriću se. Neka predsednik biračkog odbora odluči šta dalje.",
        "explanation": "Povratak mirnoj proceduri je bolji izbor od eskalacije.",
        "score": 66000
      },
      {
        "text": "Neću da čekam nikoga, sklanjajte se.",
        "explanation": "Nastavak pritiska na članove odbora je ozbiljno ometanje postupka.",
        "score": -79000
      }
    ]
  }
}
```

### voter_lamp_dialog_angry_03.json

```json
{
  "root": {
    "text": "Red je predugačak, preskočićemo lampu danas. Dajte dokument i idite dalje.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Ne, prvo proverite UV lampom. Neću da učestvujem u preskakanju procedure.",
        "explanation": "Ispravno, UV provera je obavezan prvi korak i ne sme se preskakati zbog gužve.",
        "score": 131000,
        "next": "controller_corrects"
      },
      {
        "text": "Konačno neko normalan. Idem dalje.",
        "explanation": "Prihvatanje preskakanja UV provere ugrožava pravilnost postupka.",
        "score": -26000
      },
      {
        "text": "Ako već žurite, samo recite da sam prošao.",
        "explanation": "Birač ne sme tražiti da se upiše da je procedura sprovedena ako nije.",
        "score": -39000,
        "next": "controller_warns"
      }
    ]
  },
  "controller_corrects": {
    "text": "U pravu ste. Pružite ruku pod lampu da proverimo ima li tragova spreja.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Evo ruke. Važno je da svi prođemo isto.",
        "explanation": "Birač insistira na jednakoj primeni procedure bez konflikta.",
        "score": 131000
      },
      {
        "text": "Eto, kad moram ja da vas učim poslu.",
        "explanation": "Procedura je ispravljena, ali nepotrebno vređanje narušava komunikaciju.",
        "score": 66000
      }
    ]
  },
  "controller_warns": {
    "text": "Ne možemo upisati da je nešto provereno ako nije zaista provereno.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Dobro, onda uradite proveru kako treba.",
        "explanation": "Birač se vraća ispravnoj proceduri.",
        "score": 105000
      },
      {
        "text": "Onda ste vi krivi što sve traje.",
        "explanation": "Pritisak na odbor da radi brže ne opravdava kršenje procedure.",
        "score": -13000
      }
    ]
  }
}
```

### voter_lamp_dialog_polite_02.json

```json
{
  "root": {
    "text": "Dobar dan. Molim vas, prvo ćemo proveriti ruku UV lampom.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Naravno. Samo me zanima zašto se to radi pre provere dokumenta.",
        "explanation": "Birač sme da traži objašnjenje procedure.",
        "score": 66000,
        "next": "explanation"
      },
      {
        "text": "Izvolite, spreman sam.",
        "explanation": "Ispravno, birač poštuje prvi korak postupka.",
        "score": 131000,
        "next": "clear"
      },
      {
        "text": "Radije bih prvo dao dokument, lampu možemo posle.",
        "explanation": "Redosled postupka treba poštovati; UV provera se obavlja pre nastavka glasanja.",
        "score": -13000,
        "next": "order_explained"
      }
    ]
  },
  "explanation": {
    "text": "UV lampom proveravamo da li već postoji trag nevidljivog spreja, odnosno da li je birač već glasao.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Hvala na objašnjenju, izvolite.",
        "explanation": "Birač prihvata objašnjenje i nastavlja postupak.",
        "score": 131000
      },
      {
        "text": "Razumem, ali voleo bih da svi u redu čuju isto objašnjenje.",
        "explanation": "Traženje jasnog objašnjenja može pomoći pravilnom sprovođenju postupka.",
        "score": 105000
      }
    ]
  },
  "clear": {
    "text": "Nema tragova spreja, možete dalje na proveru identiteta.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Hvala, nastavljam dalje.",
        "explanation": "Korektno sprovedena procedura i mirna komunikacija.",
        "score": 131000
      }
    ]
  },
  "order_explained": {
    "text": "Razumem, ali redosled je takav da se prvo radi UV provera.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "U redu, poštovaću redosled.",
        "explanation": "Birač se vraća propisanoj proceduri.",
        "score": 105000
      },
      {
        "text": "Ako nije po mom redosledu, odustajem.",
        "explanation": "Odustajanje je izbor birača, ali odbijanje procedure sprečava nastavak glasanja.",
        "score": -13000
      }
    ]
  }
}
```

### voter_lamp_dialog_polite_03.json

```json
{
  "root": {
    "text": "Izvinite, lampa nam je trenutno kod drugog člana odbora. Možete vi ipak dalje, verovatno je sve u redu.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Sačekaću da proverite lampom, to je deo procedure.",
        "explanation": "Ispravno, birač ne pristaje na preskakanje obavezne kontrole.",
        "score": 131000,
        "next": "lamp_returns"
      },
      {
        "text": "Ako vi kažete da može, nastaviću.",
        "explanation": "Birač ne treba da pristane na nastavak bez UV provere.",
        "score": -26000
      },
      {
        "text": "Možemo li zamoliti predsednika odbora da obezbedi da se provera obavi?",
        "explanation": "Ispravno je mirno tražiti da se procedura organizuje kako treba.",
        "score": 131000,
        "next": "chair_called"
      }
    ]
  },
  "lamp_returns": {
    "text": "Hvala što ste sačekali. Sada možemo da proverimo.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Izvolite, važno mi je da sve bude pravilno.",
        "explanation": "Birač sarađuje i podržava pravilno sprovođenje izbora.",
        "score": 131000
      },
      {
        "text": "Dobro, ali ovo kašnjenje bi trebalo zabeležiti ako se ponavlja.",
        "explanation": "Ukazivanje na ponovljeni proceduralni problem je opravdano ako se problem nastavi.",
        "score": 66000
      }
    ]
  },
  "chair_called": {
    "text": "Predsednik odbora kaže da se mora sačekati lampa i da niko ne ide dalje bez provere.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Hvala, sačekaću proveru.",
        "explanation": "Birač prihvata pravilno rešenje.",
        "score": 131000
      },
      {
        "text": "Onda ću stati sa strane da ne zadržavam red.",
        "explanation": "Birač čeka proveru bez ometanja rada biračkog mesta.",
        "score": 105000
      }
    ]
  }
}
```

## 2) ID kontrola

Nekoliko primera prekršaja za ID kontrolu.

### Objašnjenje bodovanja

| Situacija | Bodovi |
|---|---|
| Ispravno postupanje, poštovanje zakona i procedure | +100 |
| Nepažljiva provera identiteta | -50 |
| Dozvoljavanje glasanja bez provere, sa tuđim ili neodgovarajućim dokumentom | -100 |

Ovi dijalozi pokrivaju najčešće greške i prekršaje na poziciji ID kontrole, uključujući i situacije kada birač ili kontrolor koriguju jedan drugog. Svi scenariji su u skladu sa propisima i praksom izbornog procesa u Srbiji.

> Izvor: Crta edukativni materijali, Zakon o izboru narodnih poslanika, Zakon o lokalnim izborima.

### voter_id_dialog_angry_03.json

```json
{
  "root": {
    "text": "Dajte dokument za proveru identiteta.",
    "speaker": "LEFT",
    "next": "voter_reply"
  },
  "voter_reply": {
    "text": "Evo pasoš, istekao je prošlog meseca, ali slika je moja. Nemojte sad da cepidlačite.",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "Ne mogu da prihvatim samo nevažeći pasoš. Potrebna je važeća lična karta, važeći pasoš ili potvrda MUP-a o podnetom zahtevu za novi dokument.",
        "explanation": "Ispravno, birač glasa sa važećom ličnom kartom, važećim pasošem ili potvrdom MUP-a ako je lična karta ili pasoš u postupku zamene.",
        "score": 131000,
        "next": "voter_leaves"
      },
      {
        "text": "Važno je da se vidi slika, možete dalje.",
        "explanation": "Prekršaj, nevažeći dokument nije dovoljan za utvrđivanje prava na glasanje.",
        "score": -26000,
        "next": "voter_passes"
      },
      {
        "text": "Sačekajte da predsednik odbora potvrdi, meni je ovo sumnjivo.",
        "explanation": "Delimično ispravno, ali osnovno pravilo je jasno: nevažeći dokument se ne prihvata.",
        "score": 66000,
        "next": "chair_confirms"
      }
    ]
  },
  "chair_confirms": {
    "text": "Predsednik odbora potvrđuje da je potreban važeći dokument ili potvrda MUP-a o podnetom zahtevu za novi dokument.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Razumem, bez važećeg dokumenta ne mogu da nastavim.",
        "explanation": "Ispravno zaključivanje nakon provere pravila.",
        "score": 131000
      },
      {
        "text": "Svejedno ću ga pustiti, čovek se već iznervirao.",
        "explanation": "Pritisak ili nervoza birača ne opravdavaju kršenje pravila identifikacije.",
        "score": -39000
      }
    ]
  },
  "voter_leaves": {
    "text": "Dobro, idem po važeći dokument, ali ovo je moglo brže.",
    "speaker": "RIGHT"
  },
  "voter_passes": {
    "text": "E tako, kad se hoće sve može.",
    "speaker": "RIGHT"
  }
}
```

### voter_id_dialog_angry_04.json

```json
{
  "root": {
    "text": "Molim dokument radi provere identiteta.",
    "speaker": "LEFT",
    "next": "voter_reply"
  },
  "voter_reply": {
    "text": "Promenila sam prezime, u spisku je staro. Nemojte odmah da me vraćate kući.",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "Proverićemo ime, JMBG i ostale podatke. Ako se identitet pouzdano utvrdi, možete nastaviti.",
        "explanation": "Ispravno, promena prezimena ne mora sprečiti glasanje ako se identitet može utvrditi po drugim podacima, naročito JMBG-u.",
        "score": 131000,
        "next": "identity_matches"
      },
      {
        "text": "Prezime se ne poklapa, odmah napustite biračko mesto.",
        "explanation": "Pogrešno, birača ne treba automatski odbiti ako se identitet može utvrditi drugim podacima.",
        "score": -26000,
        "next": "voter_objects"
      },
      {
        "text": "Nema veze šta piše, prođite bez provere.",
        "explanation": "Prekršaj, identitet ipak mora biti pažljivo proveren.",
        "score": -26000,
        "next": "voter_passes"
      }
    ]
  },
  "identity_matches": {
    "text": "JMBG i ostali podaci se poklapaju. Možete nastaviti ka proveri u spisku.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Hvala, važno mi je da se ovo rešilo po pravilima.",
        "explanation": "Korektna komunikacija i pravilno utvrđivanje identiteta.",
        "score": 131000
      },
      {
        "text": "Vidite da sam bila u pravu, sledeći put brže.",
        "explanation": "Ishod je ispravan, ali nepotrebno zaoštravanje nije dobra komunikacija.",
        "score": 66000
      }
    ]
  },
  "voter_objects": {
    "text": "Ali JMBG je isti. Zar ne treba to da proverite?",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "U pravu ste, proveriću podatke pažljivo.",
        "explanation": "Član odbora ispravlja grešku i vraća se pravilnoj proveri.",
        "score": 105000
      },
      {
        "text": "Neću ništa da proveravam, prezime mora biti isto.",
        "explanation": "Odbijanje provere može neopravdano uskratiti biraču pravo glasa.",
        "score": -39000
      }
    ]
  },
  "voter_passes": {
    "text": "Dobro, samo da završim što pre.",
    "speaker": "RIGHT"
  }
}
```

### voter_id_dialog_polite_03.json

```json
{
  "root": {
    "text": "Dobar dan, molim vas dokument za proveru identiteta.",
    "speaker": "LEFT",
    "next": "voter_reply"
  },
  "voter_reply": {
    "text": "Izvolite ličnu kartu. Poziv za glasanje nisam poneo, nadam se da to nije problem.",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "Nije problem, poziv za glasanje nije uslov. Proverićemo vaš identitet i spisak.",
        "explanation": "Ispravno, birač može da glasa bez poziva za glasanje ako se identitet i upis u spisak pravilno utvrde.",
        "score": 131000,
        "next": "voter_relief"
      },
      {
        "text": "Bez poziva ne možemo da vas primimo.",
        "explanation": "Pogrešno, poziv za glasanje nije obavezan dokument za ostvarivanje prava glasa.",
        "score": -26000,
        "next": "voter_questions"
      },
      {
        "text": "Možete dalje i bez provere, čim imate ličnu kartu.",
        "explanation": "Pogrešno, lična karta se mora proveriti i postupak mora ići redom.",
        "score": -26000
      }
    ]
  },
  "voter_questions": {
    "text": "Mislio sam da poziv nije neophodan. Možete li proveriti pravilo?",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "U pravu ste, nastavljamo proveru sa ličnom kartom.",
        "explanation": "Član odbora ispravlja grešku i omogućava nastavak postupka.",
        "score": 105000
      },
      {
        "text": "Neću da proveravam, bez poziva nema glasanja.",
        "explanation": "Neopravdano uslovljavanje pozivom može uskratiti biraču pravo glasa.",
        "score": -39000
      }
    ]
  },
  "voter_relief": {
    "text": "Hvala, nisam bio siguran i drago mi je da ste objasnili.",
    "speaker": "RIGHT"
  }
}
```

### voter_id_dialog_polite_04.json

```json
{
  "root": {
    "text": "Molim vas, dokument za identifikaciju.",
    "speaker": "LEFT",
    "next": "voter_reply"
  },
  "voter_reply": {
    "text": "Lična karta mi je u postupku zamene, ali imam potvrdu MUP-a i stari dokument.",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "Prihvatićemo potvrdu MUP-a i proveriti podatke pažljivo.",
        "explanation": "Ispravno, potvrda MUP-a o promeni lične karte može služiti za ostvarivanje prava glasa.",
        "score": 131000,
        "next": "data_checked"
      },
      {
        "text": "Bez nove lične karte ne možete glasati.",
        "explanation": "Pogrešno, potvrda MUP-a je predviđena za ovu situaciju.",
        "score": -26000,
        "next": "voter_explains"
      },
      {
        "text": "Ne treba ništa da proveravamo, dovoljno je što imate papir.",
        "explanation": "Pogrešno, i uz potvrdu MUP-a identitet mora biti proveren.",
        "score": -13000
      }
    ]
  },
  "voter_explains": {
    "text": "Koliko znam, potvrda postoji baš zato što je dokument u zameni.",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "U pravu ste, proveriću podatke na potvrdi.",
        "explanation": "Greška je ispravljena i postupak se nastavlja pravilno.",
        "score": 105000
      },
      {
        "text": "Ne prihvatam potvrdu, morate otići.",
        "explanation": "Odbijanje važeće potvrde može neopravdano sprečiti birača da glasa.",
        "score": -39000
      }
    ]
  },
  "data_checked": {
    "text": "Podaci se poklapaju. Možete nastaviti ka proveri u biračkom spisku.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Hvala, nastavljam dalje.",
        "explanation": "Procedura je sprovedena mirno i pravilno.",
        "score": 131000
      }
    ]
  }
}
```

## 3) Birački spisak

Nekoliko primera prekršaja za birački spisak.

### Objašnjenje bodovanja

| Situacija | Bodovi |
|---|---|
| Ispravno ukazivanje na grešku | +100 |
| Potpisivanje na tuđem mestu, bez provere identiteta ili za drugu osobu | -100 do -200 |

Ovi dijalozi pokrivaju najvažnije greške i prekršaje na poziciji „Birački spisak“ prema važećim zakonima i standardima izbornog procesa u Srbiji.

> Izvor: ZmAI-cutoff

### voter_list_dialog_angry_04.json

```json
{
  "root": {
    "text": "Ne nalazim vas u izvodu iz biračkog spiska za ovo biračko mesto.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Kako me nema? Proverite još jednom pre nego što me odbijete.",
        "explanation": "Birač opravdano traži pažljivu proveru spiska pre donošenja odluke.",
        "score": 66000,
        "next": "second_search"
      },
      {
        "text": "Upišite me rukom negde na kraj, neću da idem bez glasanja.",
        "explanation": "Birač ne sme biti dopisan mimo propisane evidencije.",
        "score": -52000,
        "next": "manual_entry_refused"
      },
      {
        "text": "Ako nisam u spisku, tražim da mi objasnite kome da se obratim.",
        "explanation": "Ispravno, birač može tražiti objašnjenje i dalje korake bez ometanja rada.",
        "score": 131000
      }
    ]
  },
  "second_search": {
    "text": "Proverili smo još jednom. Vašeg imena zaista nema u ovom izvodu.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "U redu, zabeležite da sam došao i recite mi kome da se obratim.",
        "explanation": "Mirno traženje informacije je pravilno ponašanje u spornoj situaciji.",
        "score": 105000
      },
      {
        "text": "Onda ću se potpisati kod nekog ko se nije pojavio.",
        "explanation": "Potpisivanje na tuđem mestu je ozbiljan prekršaj.",
        "score": -52000
      }
    ]
  },
  "manual_entry_refused": {
    "text": "Ne smemo nikoga dopisivati u izvod po sopstvenoj odluci.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Dobro, onda tražim uputstvo šta mogu dalje.",
        "explanation": "Birač odustaje od nepravilnog zahteva i traži proceduralno rešenje.",
        "score": 105000
      },
      {
        "text": "Ako me ne upišete, prekidam vam glasanje.",
        "explanation": "Pretnja prekidom rada biračkog mesta je ozbiljno ometanje postupka.",
        "score": -79000
      }
    ]
  }
}
```

### voter_list_dialog_angry_05.json

```json
{
  "root": {
    "text": "Pored vašeg imena već postoji potpis. Moramo da zaustavimo postupak i proverimo šta se dogodilo.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Nisam ja potpisao! Tražim da se odmah pozove predsednik odbora i unese primedba.",
        "explanation": "Ispravno, sumnja da je neko glasao ili se potpisao umesto birača mora se rešavati kroz birački odbor i zapisnik.",
        "score": 131000,
        "next": "chair_called"
      },
      {
        "text": "Dajte mi drugo mesto da se potpišem, nemam vremena za ovo.",
        "explanation": "Potpisivanje na drugo mesto ne rešava nepravilnost i može pogoršati evidenciju.",
        "score": -39000,
        "next": "refusal"
      },
      {
        "text": "Znao sam da ćete nešto smuljati, sad ću sam da precrtam taj potpis.",
        "explanation": "Birač ne sme samovoljno menjati birački spisak.",
        "score": -52000
      }
    ]
  },
  "chair_called": {
    "text": "Predsednik odbora prilazi i kaže da se situacija mora evidentirati pre bilo kakvog nastavka.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "U redu, sačekaću da se sve zabeleži.",
        "explanation": "Ispravno, birač omogućava da se nepravilnost dokumentuje.",
        "score": 131000
      },
      {
        "text": "Neću da čekam, samo mi dajte listić.",
        "explanation": "Nastavak bez razrešenja sporne evidencije bio bi nepravilnost.",
        "score": -39000
      }
    ]
  },
  "refusal": {
    "text": "Ne možemo vas potpisati na drugo mesto. Ovo mora da se proveri.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Dobro, proverite i zabeležite šta se desilo.",
        "explanation": "Birač se vraća pravilnom postupanju.",
        "score": 105000
      },
      {
        "text": "Onda niko neće glasati dok mene ne pustite.",
        "explanation": "Blokiranje glasanja zbog spora dodatno ometa rad biračkog mesta.",
        "score": -79000
      }
    ]
  }
}
```

### voter_list_dialog_polite_03.json

```json
{
  "root": {
    "text": "Molim vas, potpišite se pored svog imena. Samo trenutak, otvoren je pogrešan izvod.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Sačekaću da pronađete odgovarajući izvod, ne bih da se potpišem na pogrešno mesto.",
        "explanation": "Ispravno, birač treba da se potpiše samo u odgovarajući izvod i pored svog imena.",
        "score": 131000,
        "next": "correct_list"
      },
      {
        "text": "Ako vam je lakše, potpisaću se tu pa vi kasnije sredite.",
        "explanation": "Potpisivanje u pogrešan izvod ili na pogrešno mesto može izazvati ozbiljnu nepravilnost.",
        "score": -26000
      },
      {
        "text": "Možete li mi pokazati moje ime pre potpisa?",
        "explanation": "Birač razumno traži proveru da se potpisuje na pravilnom mestu.",
        "score": 131000,
        "next": "name_shown"
      }
    ]
  },
  "correct_list": {
    "text": "Hvala na strpljenju. Evo odgovarajućeg izvoda i vašeg imena.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Hvala, sada ću se potpisati.",
        "explanation": "Postupak se nastavlja pravilno nakon ispravke.",
        "score": 131000
      }
    ]
  },
  "name_shown": {
    "text": "Naravno, evo vašeg imena i mesta za potpis.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "U redu, potpisujem se ovde.",
        "explanation": "Birač se potpisuje tek nakon potvrde svog mesta u spisku.",
        "score": 131000
      },
      {
        "text": "Vidim slično ime iznad, možda je svejedno.",
        "explanation": "Nije svejedno; potpis mora biti pored tačnog imena birača.",
        "score": -13000
      }
    ]
  }
}
```

### voter_list_dialog_polite_04.json

```json
{
  "root": {
    "text": "Vidim da ste u spisku, ali niste se potpisali. Možete nastaviti, samo ćemo mi kasnije označiti.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Molim vas, potpisao bih se sada pored svog imena, kako procedura nalaže.",
        "explanation": "Ispravno, birač se mora potpisati u izvod pre nastavka postupka.",
        "score": 131000,
        "next": "signature_done"
      },
      {
        "text": "Ako je vama tako lakše, nastaviću bez potpisa.",
        "explanation": "Nastavak bez potpisa u biračkom spisku je nepravilnost.",
        "score": -26000
      },
      {
        "text": "Možete li proveriti da li je ovo za sve nivoe izbora na kojima glasam?",
        "explanation": "Razumno je proveriti odgovarajuće izvode kada postoji više nivoa izbora.",
        "score": 105000,
        "next": "all_lists_checked"
      }
    ]
  },
  "signature_done": {
    "text": "U pravu ste. Potpišite se ovde, pored svog imena.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Hvala, potpisujem se.",
        "explanation": "Procedura je ispravljena i birač nastavlja pravilno.",
        "score": 131000
      },
      {
        "text": "Dobro je da smo proverili pre nego što sam otišao dalje.",
        "explanation": "Birač je sprečio proceduralni propust bez sukoba.",
        "score": 131000
      }
    ]
  },
  "all_lists_checked": {
    "text": "Proverićemo izvode za nivoe izbora koji se održavaju na ovom biračkom mestu.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Hvala, potpisaću se tamo gde treba.",
        "explanation": "Birač poštuje evidenciju za svaki relevantan izvod.",
        "score": 131000
      },
      {
        "text": "Nema potrebe, dovoljan je jedan potpis bilo gde.",
        "explanation": "Potpisivanje mora pratiti propisanu evidenciju, ne proizvoljno mesto.",
        "score": -26000
      }
    ]
  }
}
```

## 4) Nevidljivi sprej

Nekoliko primera prekršaja za nevidljivi sprej.

### Objašnjenje bodovanja

| Situacija | Bodovi |
|---|---|
| Ispravno postupanje, insistiranje na pravilima, zaštita izbornog integriteta | +100 |
| Delimično ispravno, ali može dovesti do zastoja ili nesporazuma | +50 |
| Težak prekršaj ili prihvatanje prekršaja, ugrožavanje zakonitosti izbora | -100 |

Ovi dijalozi pokrivaju najčešće greške i prekršaje pri nanošenju nevidljivog spreja, uključujući i situacije kada birač odbija sprej ili kontrolor preskoči njegovo nanošenje.

> Izvor: ZmAI-cutoff

### voter_spray_dialog_angry_03.json

```json
{
  "root": {
    "text": "Dajte desni kažiprst da nanesemo nevidljivi sprej.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Neću, imam sastanak posle ovoga i neću fleke na ruci.",
        "explanation": "Odbijanje obeležavanja sprejem sprečava nastavak postupka.",
        "score": -26000,
        "next": "spray_required"
      },
      {
        "text": "Nemam desni kažiprst, možete obeležiti drugi dostupan prst.",
        "explanation": "Ispravno, ako birač nema desni kažiprst, sprej se nanosi na drugi dostupan prst prema proceduri.",
        "score": 131000,
        "next": "alternate_finger"
      },
      {
        "text": "Ajde brzo, samo nemojte mnogo.",
        "explanation": "Birač prihvata proceduru, iako je komunikacija nestrpljiva.",
        "score": 105000
      }
    ]
  },
  "spray_required": {
    "text": "Bez obeležavanja sprejem ne možemo vam izdati glasački listić.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Dobro, obeležite prst, samo da završimo.",
        "explanation": "Birač se vraća obaveznoj proceduri.",
        "score": 105000
      },
      {
        "text": "Onda mi dajte listić bez spreja, neću da čekam.",
        "explanation": "Listić ne sme biti izdat ako je obavezno obeležavanje sprejem odbijeno.",
        "score": -39000
      }
    ]
  },
  "alternate_finger": {
    "text": "U redu, obeležićemo drugi dostupan prst.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Hvala. Važno je samo da procedura bude sprovedena.",
        "explanation": "Birač sarađuje i omogućava sprovođenje procedure.",
        "score": 131000
      },
      {
        "text": "Vidite da može kad vas čovek pritisne.",
        "explanation": "Postupak je ispravan, ali nepotrebna agresivnost narušava komunikaciju.",
        "score": 66000
      }
    ]
  }
}
```

### voter_spray_dialog_angry_04.json

```json
{
  "root": {
    "text": "Sprej je pri kraju. Preskočićemo obeležavanje za vas da ne zaustavljamo red.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Ne, neću dalje dok me ne obeležite sprejem.",
        "explanation": "Ispravno, birač ne sme prihvatiti preskakanje obavezne procedure.",
        "score": 131000,
        "next": "replacement_spray"
      },
      {
        "text": "Odlično, ionako me nervira taj sprej.",
        "explanation": "Prihvatanje preskakanja spreja je nepravilno.",
        "score": -26000
      },
      {
        "text": "Zabeležite da spreja nema i pozovite predsednika odbora.",
        "explanation": "Ispravno je ukazati na proceduralni problem i tražiti da se reši kroz birački odbor.",
        "score": 131000,
        "next": "chair_organizes"
      }
    ]
  },
  "replacement_spray": {
    "text": "Pronašli smo rezervni sprej. Dajte prst da završimo postupak.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Evo prsta. Tako je trebalo odmah.",
        "explanation": "Procedura je sprovedena, iako birač ostaje nestrpljiv.",
        "score": 105000
      },
      {
        "text": "Sad više neću, namerno ste me zadržavali.",
        "explanation": "Odbijanje nakon što je problem rešen ponovo sprečava nastavak glasanja.",
        "score": -26000
      }
    ]
  },
  "chair_organizes": {
    "text": "Predsednik odbora nalaže da se obezbedi sprej i da niko ne dobije listić bez obeležavanja.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "U redu, sačekaću da se obeležavanje obavi.",
        "explanation": "Birač podržava pravilno rešenje problema.",
        "score": 131000
      },
      {
        "text": "Ako čekam, tražim da svi vide da ste pogrešili.",
        "explanation": "Ukazivanje na propust je opravdano, ali javno zaoštravanje može nepotrebno ometati rad.",
        "score": 39000
      }
    ]
  }
}
```

### voter_spray_dialog_polite_03.json

```json
{
  "root": {
    "text": "Molim vas, pružite prst da nanesemo nevidljivi sprej.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Naravno. Da li možete samo da mi kažete čemu služi sprej?",
        "explanation": "Birač sme da traži objašnjenje svrhe obeležavanja.",
        "score": 66000,
        "next": "spray_explained"
      },
      {
        "text": "Izvolite prst.",
        "explanation": "Ispravno, birač prihvata obavezno obeležavanje.",
        "score": 131000
      },
      {
        "text": "Radije ne bih, ali bih ipak želeo listić.",
        "explanation": "Birač ne može dobiti glasački listić ako odbije obavezno obeležavanje sprejem.",
        "score": -26000,
        "next": "refusal_explained"
      }
    ]
  },
  "spray_explained": {
    "text": "Sprej služi da se spreči da ista osoba glasa više puta; trag se kasnije vidi pod UV lampom.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Razumem, izvolite.",
        "explanation": "Birač prihvata objašnjenje i nastavlja postupak.",
        "score": 131000
      },
      {
        "text": "Hvala. Voleo bih da se ovo objasni i ljudima koji nisu sigurni.",
        "explanation": "Jasno objašnjenje procedure doprinosi poverenju u postupak.",
        "score": 105000
      }
    ]
  },
  "refusal_explained": {
    "text": "Nažalost, bez spreja ne možemo izdati listić.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "U redu, prihvatam obeležavanje.",
        "explanation": "Birač se vraća pravilnoj proceduri.",
        "score": 105000
      },
      {
        "text": "Onda odustajem od glasanja.",
        "explanation": "Birač može odustati, ali odbijanje spreja znači da postupak ne može biti nastavljen.",
        "score": -13000
      }
    ]
  }
}
```

### voter_spray_dialog_polite_04.json

```json
{
  "root": {
    "text": "Izvinite, pripremio sam listić, a još vam nisam naneo sprej.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Molim vas da prvo obavite obeležavanje, pa tek onda izdate listić.",
        "explanation": "Ispravno, birač ukazuje na propust i traži da se sprej nanese pre izdavanja listića.",
        "score": 131000,
        "next": "spray_applied"
      },
      {
        "text": "Ako je listić već spreman, nema potrebe da se vraćamo na to.",
        "explanation": "Pogrešno, obeležavanje sprejem mora prethoditi izdavanju listića.",
        "score": -26000
      },
      {
        "text": "Možete li obavestiti predsednika odbora da se propust ne ponavlja?",
        "explanation": "Ispravno je tražiti da se proceduralni propust evidentira ili spreči ubuduće.",
        "score": 105000,
        "next": "chair_notified"
      }
    ]
  },
  "spray_applied": {
    "text": "U pravu ste. Hvala što ste ukazali, sada ću naneti sprej pa vam izdati listić.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Hvala, posle toga preuzimam listić i nastavljam iza paravana.",
        "explanation": "Postupak je ispravljen pre izdavanja listića i nastavka glasanja.",
        "score": 131000
      }
    ]
  },
  "chair_notified": {
    "text": "Predsednik odbora je obavešten i podsetiće članove na redosled postupka.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "U redu, izvolite prst za sprej, pa onda mogu da preuzmem listić.",
        "explanation": "Birač kombinuje ukazivanje na propust sa nastavkom pravilne procedure.",
        "score": 131000
      },
      {
        "text": "Hvala, ali ipak ću otići bez spreja.",
        "explanation": "Odlazak dalje bez obeležavanja ostavlja propust nerešenim.",
        "score": -26000
      }
    ]
  }
}
```

## 5) Listić za glasanje

Nekoliko primera prekršaja za listić za glasanje.

### Objašnjenje bodovanja

| Situacija | Bodovi |
|---|---|
| Ispravno postupanje i zaštita prava birača | +100 |
| Ugrožavanje tajnosti glasanja, glasanje u tuđe ime ili preskakanje zakonom propisane procedure | -100 do -200 |

Ovi dijalozi pokrivaju najčešće greške i prekršaje pri preuzimanju listića za glasanje, uključujući i situacije kada kontrolor ili birač pokušaju da zaobiđu propisanu proceduru.

> Izvor: ZmAI-cutoff

### voter_ballot_dialog_angry_04.json

```json
{
  "root": {
    "text": "Dajte mi dva listića, glasam i za oca. Čeka u kolima, bolestan je.",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "Ne mogu vam dati drugi listić. Svaki birač glasa lično, osim posebnih procedura koje se ne rešavaju ovde ovako.",
        "explanation": "Ispravno, jedan birač ne sme preuzeti listić i glasati umesto druge osobe.",
        "score": 131000,
        "next": "voter_pushes"
      },
      {
        "text": "U redu, evo još jedan listić, samo nemojte da pravite gužvu.",
        "explanation": "Težak prekršaj, izdavanje dodatnog listića omogućava glasanje u tuđe ime.",
        "score": -52000
      },
      {
        "text": "Potpišite se za njega u spisku pa ću vam dati listić.",
        "explanation": "Još teži prekršaj, potpisivanje i glasanje za drugu osobu nije dozvoljeno.",
        "score": -66000
      }
    ]
  },
  "voter_pushes": {
    "text": "Neću da se vraćam bez listića, obećao sam mu.",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "Razumem, ali ne smem da izdam listić osobi koja nije prošla postupak.",
        "explanation": "Ispravno, listić se izdaje samo biraču koji lično prođe propisane korake.",
        "score": 131000
      },
      {
        "text": "Dobro, ali neka ostane između nas.",
        "explanation": "Dogovor o kršenju procedure ugrožava zakonitost glasanja.",
        "score": -52000
      }
    ]
  }
}
```

### voter_ballot_dialog_angry_05.json

```json
{
  "root": {
    "text": "Listić koji sam dobio je pocepan na uglu. Dajte drugi odmah, neću da mi propadne glas.",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "Zaustavićemo se i obavestiti predsednika odbora pre izdavanja zamenskog listića.",
        "explanation": "Ispravno, oštećen listić treba odmah prijaviti i rešiti kroz proceduru biračkog odbora.",
        "score": 131000,
        "next": "chair_checks"
      },
      {
        "text": "Samo uzmite drugi iz gomile, ovaj bacite.",
        "explanation": "Nepravilno rukovanje listićima može ugroziti evidenciju i kontrolu izdatih listića.",
        "score": -39000
      },
      {
        "text": "Nema veze, glasajte tim pocepanim listićem.",
        "explanation": "Ako je listić oštećen pre glasanja, problem treba rešiti odmah, a ne ignorisati.",
        "score": -26000,
        "next": "voter_objects"
      }
    ]
  },
  "chair_checks": {
    "text": "Predsednik odbora proverava listić i nalaže da se situacija evidentira pre nastavka.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "U redu, sačekaću da se evidentira i dobijem ispravan listić.",
        "explanation": "Birač omogućava da se problem reši pravilno.",
        "score": 131000
      },
      {
        "text": "Neću da čekam, uzeću sam drugi listić.",
        "explanation": "Birač ne sme sam uzimati glasačke listiće.",
        "score": -52000
      }
    ]
  },
  "voter_objects": {
    "text": "Neću da glasam listićem za koji se unapred vidi da je oštećen.",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "U pravu ste, pozvaćemo predsednika odbora.",
        "explanation": "Član odbora ispravlja grešku i vraća se proceduri.",
        "score": 105000
      },
      {
        "text": "Ako nećete taj listić, odustanite.",
        "explanation": "Odbijanje da se proveri oštećen listić može nepravilno uskratiti biraču glasanje.",
        "score": -39000
      }
    ]
  }
}
```

### voter_ballot_dialog_polite_03.json

```json
{
  "root": {
    "text": "Izvolite glasački listić. Možete ga popuniti ovde za stolom ako vam je lakše.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Hvala, ali listić ću popuniti iza paravana, zbog tajnosti glasanja.",
        "explanation": "Ispravno, birač treba da glasa iza paravana kako bi tajnost glasanja bila zaštićena.",
        "score": 131000,
        "next": "controller_accepts"
      },
      {
        "text": "Može, samo da završim brže.",
        "explanation": "Popunjavanje listića za stolom može ugroziti tajnost glasanja.",
        "score": -26000
      },
      {
        "text": "Da li je obavezno da idem iza paravana?",
        "explanation": "Birač sme da traži objašnjenje zašto se glasa iza paravana.",
        "score": 66000,
        "next": "privacy_explained"
      }
    ]
  },
  "controller_accepts": {
    "text": "U pravu ste. Iza paravana imate privatnost za popunjavanje listića.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Hvala, idem iza paravana.",
        "explanation": "Birač pravilno nastavlja postupak.",
        "score": 131000
      }
    ]
  },
  "privacy_explained": {
    "text": "Da, glasanje je tajno i treba da popunite listić tako da niko ne vidi vaš izbor.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Razumem, popuniću ga iza paravana.",
        "explanation": "Birač prihvata objašnjenje i štiti tajnost glasanja.",
        "score": 131000
      },
      {
        "text": "Svejedno mi je da drugi vide.",
        "explanation": "Tajnost glasanja se štiti procedurom čak i kada birač misli da mu nije važno.",
        "score": -13000
      }
    ]
  }
}
```

### voter_ballot_dialog_polite_04.json

```json
{
  "root": {
    "text": "Izvinite, pre nego što mi date listić, mislim da još nisam potpisan u birački spisak.",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "Hvala što ste ukazali. Vratićemo se korak nazad i proveriti potpis pre izdavanja listića.",
        "explanation": "Ispravno, listić se izdaje tek nakon prethodnih koraka, uključujući proveru i potpis u spisku.",
        "score": 131000,
        "next": "procedure_fixed"
      },
      {
        "text": "Nema veze, potpis ćemo kasnije, evo listić.",
        "explanation": "Pogrešno, redosled procedure ne treba preskakati.",
        "score": -26000
      },
      {
        "text": "Ako ste sigurni, možda mogu samo da potpišem posle glasanja.",
        "explanation": "Birač ne treba da predlaže naknadno ispravljanje preskočene procedure.",
        "score": -13000,
        "next": "order_explained"
      }
    ]
  },
  "procedure_fixed": {
    "text": "Proverili smo spisak i sada se možete potpisati na svoje mesto.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Potpisujem se, pa onda preuzimam listić.",
        "explanation": "Postupak je vraćen u pravilan redosled.",
        "score": 131000
      },
      {
        "text": "Dobro je da smo proverili pre nego što sam nastavio.",
        "explanation": "Birač je sprečio proceduralni propust.",
        "score": 131000
      }
    ]
  },
  "order_explained": {
    "text": "Ne, potpis mora biti završen pre izdavanja listića.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "U redu, onda prvo potpis.",
        "explanation": "Birač prihvata ispravan redosled.",
        "score": 105000
      },
      {
        "text": "Meni je svejedno, samo mi dajte listić.",
        "explanation": "Insistiranje na preskakanju koraka ugrožava pravilnost postupka.",
        "score": -26000
      }
    ]
  }
}
```

## 6) Popunjavanje listića

Nekoliko primera prekršaja za popunjavanje listića.

### Objašnjenje bodovanja

| Situacija | Bodovi |
|---|---|
| Ispravno odbijanje zahteva za narušavanje tajnosti, presavijanje listića | +100 |
| Otkrivanje načina glasanja iz lične volje | 0 do -10 |
| Fotografisanje listića, pokazivanje načina glasanja na zahtev kontrolora ili odbijanje da se listić presavije | -50 do -100 |

Ovi dijalozi pokrivaju najčešće greške i prekršaje pri popunjavanju listića iza paravana, uključujući i situacije kada kontrolor ili birač naruše tajnost glasanja.

> Izvor: ZmAI-cutoff

### voter_booth_dialog_angry_04.json

```json
{
  "root": {
    "text": "Za paravanom su dve osobe. Jedna govori drugoj šta da zaokruži.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Prekinite to, glasanje mora biti tajno i bez uticaja na birača.",
        "explanation": "Ispravno, niko ne sme uticati na birača niti narušavati tajnost glasanja iza paravana.",
        "score": 131000,
        "next": "intervention"
      },
      {
        "text": "Pustite ih, sigurno su porodica.",
        "explanation": "Porodični odnos ne opravdava narušavanje tajnosti glasanja ili pritisak.",
        "score": -26000
      },
      {
        "text": "Samo viknite da požure, nije važno šta rade unutra.",
        "explanation": "Odbor mora reagovati na moguće narušavanje tajnosti, ne samo ubrzavati red.",
        "score": -26000
      }
    ]
  },
  "intervention": {
    "text": "Druga osoba izlazi od paravana i tvrdi da je samo pomagala.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Neka birač sam potvrdi da li mu je potrebna pomoć, bez pritiska.",
        "explanation": "Ispravno, treba zaštititi birača od pritiska i proveriti situaciju mirno.",
        "score": 131000
      },
      {
        "text": "Ako kaže da pomaže, neka ostane i završi umesto njega.",
        "explanation": "Druga osoba ne sme preuzeti glasanje umesto birača.",
        "score": -39000
      }
    ]
  }
}
```

### voter_booth_dialog_angry_05.json

```json
{
  "root": {
    "text": "Birač izlazi od paravana sa nepresavijenim listićem tako da se vidi za koga je glasao.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Molim vas, odmah presavijte listić tako da se ne vidi izbor.",
        "explanation": "Ispravno, listić treba presaviti radi zaštite tajnosti glasanja.",
        "score": 131000,
        "next": "voter_reacts"
      },
      {
        "text": "Nema veze, ubacite ga tako.",
        "explanation": "Pogrešno, odbor treba da zaštiti tajnost glasanja pre ubacivanja listića.",
        "score": -13000
      },
      {
        "text": "Svi pogledajte, da znamo za koga je glasao.",
        "explanation": "To je direktno narušavanje tajnosti glasanja.",
        "score": -52000
      }
    ]
  },
  "voter_reacts": {
    "text": "Šta vas briga, hoću da svi vide moj izbor.",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "Vaš izbor je vaša stvar, ali listić se ubacuje presavijen da se zaštiti tajnost postupka.",
        "explanation": "Ispravno, birač može pričati o svom izboru, ali procedura presavijanja štiti tajnost glasanja.",
        "score": 131000
      },
      {
        "text": "Ako želite da pokažete, pokažite prvo meni.",
        "explanation": "Član odbora ne sme tražiti da vidi kako je birač glasao.",
        "score": -26000
      }
    ]
  }
}
```

### voter_booth_dialog_polite_04.json

```json
{
  "root": {
    "text": "Izvinite, paravan je okrenut tako da se sa strane vidi kako popunjavam listić.",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "Hvala što ste rekli. Zaustavićemo trenutak i namestiti paravan da se zaštiti tajnost glasanja.",
        "explanation": "Ispravno, birački odbor treba da obezbedi uslove za tajno glasanje.",
        "score": 131000,
        "next": "booth_adjusted"
      },
      {
        "text": "Nema veze, niko ne gleda.",
        "explanation": "Pogrešno, tajnost glasanja mora biti obezbeđena, a ne prepuštena pretpostavci.",
        "score": -26000
      },
      {
        "text": "Stanite telom da zaklonite listić, to je dovoljno.",
        "explanation": "Privremeno zaklanjanje nije dobro rešenje ako paravan ne obezbeđuje tajnost.",
        "score": -13000
      }
    ]
  },
  "booth_adjusted": {
    "text": "Paravan je pomeren tako da se listić ne vidi sa strane.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Hvala, sada mogu da glasam tajno.",
        "explanation": "Tajnost glasanja je zaštićena pre popunjavanja listića.",
        "score": 131000
      },
      {
        "text": "Dobro je da smo ovo rešili pre glasanja.",
        "explanation": "Birač je ukazao na nepravilnost na vreme.",
        "score": 131000
      }
    ]
  }
}
```

### voter_booth_dialog_polite_05.json

```json
{
  "root": {
    "text": "Dok popunjavam listić, jedan posmatrač stoji preblizu paravana i gleda ka meni.",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "Zamolićemo posmatrača da se udalji. Posmatrači ne smeju da utiču na birača niti narušavaju tajnost glasanja.",
        "explanation": "Ispravno, posmatrači mogu pratiti proces, ali ne smeju ugrožavati tajnost glasanja.",
        "score": 131000,
        "next": "observer_moves"
      },
      {
        "text": "On je posmatrač, ima pravo da stoji gde hoće.",
        "explanation": "Pogrešno, posmatrač ne sme narušavati tajnost glasanja ili uticati na birača.",
        "score": -26000
      },
      {
        "text": "Ako vam smeta, pokažite mu listić pa nastavite.",
        "explanation": "Pokazivanje listića posmatraču narušava tajnost glasanja.",
        "score": -39000
      }
    ]
  },
  "observer_moves": {
    "text": "Posmatrač se udaljava i kaže da nije nameravao da ometa glasanje.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Hvala, sada nastavljam iza paravana.",
        "explanation": "Problem je rešen bez konflikta, uz zaštitu tajnosti glasanja.",
        "score": 131000
      },
      {
        "text": "Molim vas da se ovo zabeleži ako se ponovi.",
        "explanation": "Traženje evidencije za ponovljenu nepravilnost je razumno.",
        "score": 105000
      }
    ]
  }
}
```
