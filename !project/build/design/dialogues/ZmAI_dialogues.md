# Dijalozi na izbornom mestu

- [Deo 1: Rezultat (JSON)](#deo-1-rezultat-json)
  - [1) UV lampa](#1-uv-lampa)
  - [2) ID kontrola](#2-id-kontrola)
  - [3) Birački spisak](#3-birački-spisak)
  - [4) Nevidljivi sprej](#4-nevidljivi-sprej)
  - [5) Listić za glasanje](#5-listić-za-glasanje)
  - [6) Popunjavanje listića](#6-popunjavanje-listića)
- [Deo 2: Pravila za prompt](#deo-2-pravila-za-prompt)
  - [Zadatak](#zadatak)
  - [Pravila na izborima](#pravila-na-izborima)
  - [Neka moguća scenarija](#neka-moguća-scenarija)
  - [Struktura dijaloga (uzorak)](#struktura-dijaloga-uzorak)

---

# Deo 1: Rezultat (JSON)

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

### voter_lamp_dialog_angry_01.json

```json
{
  "root": {
    "text": "[ANG] Pružite ruku pod lampu, nemamo ceo dan!",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Evo ruke, samo polako.",
        "explanation": "Ispravno, birač poštuje proceduru.",
        "score": 100,
        "next": "check_passed"
      },
      {
        "text": "Ma pusti me, neću da mi neko sija u facu!",
        "explanation": "Birač odbija proveru, što je ozbiljan prekršaj.",
        "score": -200,
        "next": "check_insisted"
      }
    ]
  },
  "check_passed": {
    "text": "Nema tragova spreja, možete dalje.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Hvala, prijatno.",
        "explanation": "Korektna komunikacija.",
        "score": 100
      },
      {
        "text": "Ajde više, gubim vreme zbog vas!",
        "explanation": "Nepristojan odgovor birača ometa rad biračkog odbora.",
        "score": -100
      }
    ]
  },
  "check_insisted": {
    "text": "Bez UV provere ne možeš da glasaš, to je pravilo.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Ma ne zanima me, zovi šefa!",
        "explanation": "Birač eskalira situaciju, ometa rad biračkog mesta.",
        "score": -300
      },
      {
        "text": "Dobro, ajde, proveri brzo.",
        "explanation": "Birač popušta, vraća se proceduri.",
        "score": 50
      }
    ]
  }
}
```

### voter_lamp_dialog_polite_01.json

```json
{
  "root": {
    "text": "[POL] Dobar dan, molim vas da pružite ruku da proverimo sprej UV lampom.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Naravno, izvolite.",
        "explanation": "Birač poštuje proceduru.",
        "score": 100,
        "next": "check_passed"
      },
      {
        "text": "Zašto to radite?",
        "explanation": "Birač traži objašnjenje, što je dozvoljeno.",
        "score": 50,
        "next": "procedure_explained"
      },
      {
        "text": "Neću, žurim.",
        "explanation": "Birač odbija proveru, što je prekršaj.",
        "score": -200,
        "next": "check_refused"
      }
    ]
  },
  "check_passed": {
    "text": "Hvala, možete nastaviti dalje.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Hvala i vama, prijatan dan.",
        "explanation": "Korektna komunikacija.",
        "score": 100
      }
    ]
  },
  "procedure_explained": {
    "text": "Proveravamo da li je neko već glasao, to je obavezna procedura.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Razumem, izvolite ruku.",
        "explanation": "Birač prihvata objašnjenje.",
        "score": 80
      },
      {
        "text": "I dalje mi nije jasno, ali ajde.",
        "explanation": "Birač je nepoverljiv, ali ne pravi problem.",
        "score": 50
      }
    ]
  },
  "check_refused": {
    "text": "Nažalost, bez UV provere ne možete pristupiti glasanju.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Dobro, evo ruka.",
        "explanation": "Birač se vraća proceduri.",
        "score": 50
      },
      {
        "text": "Onda neću ni da glasam!",
        "explanation": "Birač odustaje, što je njegovo pravo, ali nije preporučljivo.",
        "score": -50
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

### voter_id_dialog_angry_01.json

```json
{
  "root": {
    "text": "[ANG] Dajte ličnu kartu odmah, nemamo ceo dan!",
    "speaker": "LEFT",
    "next": "voter_reply"
  },
  "voter_reply": {
    "text": "Nemam ličnu kartu kod sebe, može vozačka?",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "Ne može, potrebna je lična karta, pasoš ili potvrda MUP-a.",
        "explanation": "Ispravno – glasa se samo sa važećom ličnom kartom, pasošem ili potvrdom MUP-a o promeni lične karte.",
        "score": 100,
        "next": "voter_leaves"
      },
      {
        "text": "Može, samo brzo.",
        "explanation": "Prekršaj – vozačka dozvola nije dokument sa kojim se može glasati.",
        "score": -100,
        "next": "voter_passes"
      }
    ]
  },
  "voter_leaves": {
    "text": "Dobro, idem po ličnu kartu.",
    "speaker": "RIGHT"
  },
  "voter_passes": {
    "text": "Evo vozačke, hvala.",
    "speaker": "RIGHT"
  }
}
```

### voter_id_dialog_angry_02.json

```json
{
  "root": {
    "text": "[ANG] Dajte dokument, brzo!",
    "speaker": "LEFT",
    "next": "voter_reply"
  },
  "voter_reply": {
    "text": "Evo, ovo je od mog brata, isti smo.",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "Ne možete glasati sa tuđim dokumentom.",
        "explanation": "Glasanje sa tuđim dokumentom je ozbiljan prekršaj.",
        "score": 100,
        "next": "voter_leaves"
      },
      {
        "text": "Ma nema veze, prođi.",
        "explanation": "Ozbiljan prekršaj – omogućavanje glasanja sa tuđim dokumentom.",
        "score": -100,
        "next": "voter_passes"
      }
    ]
  },
  "voter_leaves": {
    "text": "Dobro, idem po svoj dokument.",
    "speaker": "RIGHT"
  },
  "voter_passes": {
    "text": "Hvala, brate, znao sam da nećeš praviti problem.",
    "speaker": "RIGHT"
  }
}
```

### voter_id_dialog_polite_01.json

```json
{
  "root": {
    "text": "[POL] Dobar dan, možete li mi dati ličnu kartu?",
    "speaker": "LEFT",
    "next": "voter_reply"
  },
  "voter_reply": {
    "text": "Izvolite.",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "Samo je prebacite, ne moram da gledam.",
        "explanation": "Greška – kontrolor mora pažljivo proveriti identitet.",
        "score": -50,
        "next": "voter_objects"
      },
      {
        "text": "Hvala, proveriću podatke.",
        "explanation": "Ispravno – svaki birač mora biti identifikovan.",
        "score": 100,
        "next": "voter_passes"
      }
    ]
  },
  "voter_objects": {
    "text": "Molim vas da proverite, red je da se poštuje procedura.",
    "speaker": "RIGHT"
  },
  "voter_passes": {
    "text": "Hvala, prijatno.",
    "speaker": "RIGHT"
  }
}
```

### voter_id_dialog_polite_02.json

```json
{
  "root": {
    "text": "[POL] Molim Vas, ličnu kartu radi provere identiteta.",
    "speaker": "LEFT",
    "next": "voter_reply"
  },
  "voter_reply": {
    "text": "Neću da dajem, znate me, dolazim svake godine.",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "Nažalost, bez dokumenta ne možete glasati.",
        "explanation": "Ispravno – bez identifikacije nije dozvoljeno glasanje.",
        "score": 100,
        "next": "voter_leaves"
      },
      {
        "text": "Ma nema veze, prođite.",
        "explanation": "Prekršaj – glasanje bez provere identiteta.",
        "score": -100,
        "next": "voter_passes"
      }
    ]
  },
  "voter_leaves": {
    "text": "Dobro, idem po dokument.",
    "speaker": "RIGHT"
  },
  "voter_passes": {
    "text": "Hvala, znao sam da ste čovek.",
    "speaker": "RIGHT"
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

### voter_list_dialog_angry_01.json

```json
{
  "root": {
    "text": "[ANG] Potpišite se ovde, na ovu liniju, i to brzo!",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Šta radite to, ovo nije moje ime!",
        "explanation": "Svaki glasač mora biti zaveden samo pod svojim imenom. Potpisivanje na tuđem mestu je ozbiljan prekršaj.",
        "score": 100,
        "next": "controller_apologizes"
      },
      {
        "text": "Ma nema veze, potpisujem se tu.",
        "explanation": "Potpisivanje na pogrešnom mestu može dovesti do izborne prevare.",
        "score": -100
      }
    ]
  },
  "controller_apologizes": {
    "text": "Ju, nisam obratio pažnju, izvinite. Evo, pronaći ćemo vaše ime.",
    "speaker": "LEFT"
  }
}
```

### voter_list_dialog_polite_01.json

```json
{
  "root": {
    "text": "[POL] Molim vas, potpišite se ovde, na ovu liniju.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Izvinite, ali to nije moje ime. Molim vas da proverite još jednom.",
        "explanation": "Birač mora biti potpisan isključivo pored svog imena.",
        "score": 100,
        "next": "controller_apologizes"
      },
      {
        "text": "U redu, potpisujem se gde ste rekli.",
        "explanation": "Potpisivanje na pogrešnom mestu može omogućiti zloupotrebe.",
        "score": -100
      }
    ]
  },
  "controller_apologizes": {
    "text": "Hvala što ste ukazali, odmah ćemo pronaći vaše ime.",
    "speaker": "LEFT"
  }
}
```

### voter_list_dialog_angry_02.json

```json
{
  "root": {
    "text": "[ANG] Potpišite se odmah, nema vremena za proveru!",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Neću da se potpišem dok ne proverite moj identitet!",
        "explanation": "Potpis bez provere identiteta je ozbiljan prekršaj i može dovesti do zloupotreba.",
        "score": 100,
        "next": "controller_apologizes"
      },
      {
        "text": "Dobro, potpisujem se bez provere.",
        "explanation": "Ovo omogućava da neko drugi glasa umesto vas.",
        "score": -100
      }
    ]
  },
  "controller_apologizes": {
    "text": "U redu, izvinjavam se, proverićemo vaš identitet pre potpisa.",
    "speaker": "LEFT"
  }
}
```

### voter_list_dialog_polite_02.json

```json
{
  "root": {
    "text": "[POL] Molim vas, potpišite se pored svog imena. Hm, ovde već postoji potpis...",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Neko se već potpisao umesto mene! Tražim da se ovo prijavi.",
        "explanation": "Ako je neko drugi potpisao umesto vas, to je ozbiljan prekršaj i mora se odmah prijaviti biračkom odboru.",
        "score": 100,
        "next": "controller_reports"
      },
      {
        "text": "Nema veze, potpisujem se na drugo slobodno mesto.",
        "explanation": "Potpisivanje na tuđem mestu ili više puta nije dozvoljeno.",
        "score": -100
      }
    ]
  },
  "controller_reports": {
    "text": "Odmah ćemo prijaviti ovu nepravilnost i uneti je u zapisnik.",
    "speaker": "LEFT"
  }
}
```

### voter_list_dialog_angry_03.json

```json
{
  "root": {
    "text": "[ANG] Dajte mi da potpišem i za suprugu, ona neće doći.",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "Ne možete potpisivati za druge, to je zabranjeno!",
        "explanation": "Ispravno – potpisivanje za drugu osobu je ozbiljan prekršaj i može biti krivično delo.",
        "score": 100,
        "next": "voter_backs_down"
      },
      {
        "text": "Ajde, potpišite, niko neće primetiti.",
        "explanation": "Težak prekršaj – član biračkog odbora omogućava potpisivanje za drugu osobu, što je pokušaj izborne prevare.",
        "score": -200
      }
    ]
  },
  "voter_backs_down": {
    "text": "Dobro, dobro, potpisaću samo za sebe.",
    "speaker": "RIGHT"
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

### voter_spray_dialog_angry_01.json

```json
{
  "root": {
    "text": "[ANG] Dajte ruku, brzo, nemam ceo dan!",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Neću da mi prskate ruku, to je glupost!",
        "explanation": "Odbijanje obeležavanja sprejem je prekršaj – birač ne može dobiti glasački listić bez spreja.",
        "score": -100
      },
      {
        "text": "Samo polako, imam pravo da pitam čemu ovo služi.",
        "explanation": "Birač ima pravo da bude informisan o proceduri, ali ne sme ometati rad biračkog odbora.",
        "score": 50
      },
      {
        "text": "Nemam kažiprst na desnoj ruci, prskajte drugi prst.",
        "explanation": "U slučaju da birač nema kažiprst, sprej se nanosi na sledeći dostupan prst ili na levoj ruci.",
        "score": 100
      }
    ]
  }
}
```

### voter_spray_dialog_polite_01.json

```json
{
  "root": {
    "text": "[POL] Molim Vas, da li biste mogli da mi pokažete desnu ruku za sprej?",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Naravno, izvolite.",
        "explanation": "Ispravno – birač daje ruku za obeležavanje sprejem.",
        "score": 100
      },
      {
        "text": "Možete li mi objasniti zašto se ovo radi?",
        "explanation": "Ispravno – birač ima pravo da traži objašnjenje, član odbora mora da objasni svrhu spreja.",
        "score": 100
      },
      {
        "text": "Ne želim da mi prskate ruku.",
        "explanation": "Odbijanje spreja znači da birač ne može dobiti listić – prekršaj.",
        "score": -100
      }
    ]
  }
}
```

### voter_spray_dialog_angry_02.json

```json
{
  "root": {
    "text": "[ANG] Ma nema veze, preskočićemo sprej, požuri dalje!",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Ne, tražim da mi obeležite prst sprejem, tako je po pravilima!",
        "explanation": "Ispravno – birač ima pravo da zahteva sprovođenje svih propisanih mera.",
        "score": 100
      },
      {
        "text": "Super, brže ćemo završiti.",
        "explanation": "Nepravilno – birač ne sme pristati na preskakanje obavezne procedure.",
        "score": -100
      }
    ]
  }
}
```

### voter_spray_dialog_polite_02.json

```json
{
  "root": {
    "text": "[POL] Izvinite, zaboravio sam da Vas obeležim sprejem, evo listić.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Molim Vas, prvo obeležite prst sprejem, pa tek onda listić.",
        "explanation": "Ispravno – birač insistira na poštovanju procedure.",
        "score": 100
      },
      {
        "text": "Nema veze, može i bez toga.",
        "explanation": "Nepravilno – birač ne sme prihvatiti listić bez obeležavanja sprejem.",
        "score": -100
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

### voter_ballot_dialog_angry_01.json

```json
{
  "root": {
    "text": "[ANG] Dajte mi odmah listić, nemam vremena da čekam vaše procedure!",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "Ne možete dobiti listić dok ne prođete sve korake.",
        "explanation": "Ispravno – birački odbor mora da proveri identitet i upiše birača u izvod iz biračkog spiska pre izdavanja listića.",
        "score": 100
      },
      {
        "text": "Evo vam listić, ali sledeći put poštujte pravila.",
        "explanation": "Ovo je prekršaj člana biračkog odbora – listić se ne može izdati bez prethodne provere identiteta i upisa u spisak.",
        "score": -100
      }
    ]
  }
}
```

### voter_ballot_dialog_polite_01.json

```json
{
  "root": {
    "text": "[POL] Izvinite, ali nisam siguran da li sam prošao sve korake pre nego što dobijem listić?",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "Hvala što ste pažljivi, proverićemo zajedno.",
        "explanation": "Ispravno postupanje – birač ima pravo da traži proveru procedure.",
        "score": 100
      },
      {
        "text": "Nema veze, evo vam listić odmah.",
        "explanation": "Prekršaj – listić se ne može izdati bez kompletne procedure.",
        "score": -100
      }
    ]
  }
}
```

### voter_ballot_dialog_angry_02.json

```json
{
  "root": {
    "text": "[ANG] Zašto mi ne dajete listić, svi pre mene su ga već dobili!",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "Moramo da proverimo vaš identitet pre izdavanja listića.",
        "explanation": "Ispravno – identitet i upis u spisak su obavezni pre izdavanja listića.",
        "score": 100
      },
      {
        "text": "U redu, evo listić, požurite.",
        "explanation": "Prekršaj – preskakanje procedure je zabranjeno.",
        "score": -100
      }
    ]
  }
}
```

### voter_ballot_dialog_polite_02.json

```json
{
  "root": {
    "text": "[POL] Da li mogu da dobijem dva listića, prijatelj me je zamolio da glasam i za njega?",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "Nije dozvoljeno glasati u tuđe ime, svaki birač glasa lično.",
        "explanation": "Ispravno – glasanje u tuđe ime je zabranjeno.",
        "score": 100
      },
      {
        "text": "U redu, evo vam još jedan listić.",
        "explanation": "Težak prekršaj – izdavanje više listića jednom biraču nije dozvoljeno.",
        "score": -200
      }
    ]
  }
}
```

### voter_ballot_dialog_angry_03.json

```json
{
  "root": {
    "text": "[ANG] Hoću da slikam listić kao dokaz, niko mi ne može zabraniti!",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "Zabranjeno je fotografisanje listića na biračkom mestu.",
        "explanation": "Ispravno – fotografisanje narušava tajnost glasanja.",
        "score": 100
      },
      {
        "text": "Slikajte, ali brzo.",
        "explanation": "Prekršaj – član biračkog odbora ne sme dozvoliti fotografisanje.",
        "score": -100
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

### voter_booth_dialog_angry_01.json

```json
{
  "root": {
    "text": "[ANG] Sklonite taj telefon, ne smete da slikate listić!",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Slikam listić i šaljem kome hoću.",
        "explanation": "Fotografisanje glasačkog listića je zabranjeno i predstavlja ozbiljan prekršaj. Tajnost glasanja je zagarantovana zakonom.",
        "score": -100
      },
      {
        "text": "Neću slikati listić, ali ću reći svima za koga sam glasao.",
        "explanation": "Otkrivanje načina glasanja nije zabranjeno ako to birač sam želi, ali je važno da niko ne vrši pritisak na birača.",
        "score": -10
      }
    ]
  }
}
```

### voter_booth_dialog_polite_01.json

```json
{
  "root": {
    "text": "[POL] Izvinite, vidim da vadite telefon. Znate li da ne smete da slikate listić?",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Naravno da smem, to je moj listić.",
        "explanation": "Fotografisanje glasačkog listića nije dozvoljeno. Tajnost glasanja mora biti zaštićena.",
        "score": -100
      },
      {
        "text": "Bolje da ne slikam, poštujem pravila.",
        "explanation": "Ispravno ste postupili. Fotografisanje listića je zabranjeno radi zaštite tajnosti glasanja.",
        "score": 100
      }
    ]
  }
}
```

### voter_booth_dialog_angry_02.json

```json
{
  "root": {
    "text": "[ANG] Morate mi pokazati za koga ste glasali, inače ne možete ubaciti listić.",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Neću da pokažem, to je moja privatna stvar!",
        "explanation": "Ispravno ste reagovali. Niko nema pravo da traži da pokažete za koga ste glasali.",
        "score": 100
      },
      {
        "text": "Dobro, evo, pogledajte.",
        "explanation": "Ovo je ozbiljan prekršaj tajnosti glasanja. Niko ne sme da vidi kako ste glasali.",
        "score": -100
      }
    ]
  }
}
```

### voter_booth_dialog_polite_02.json

```json
{
  "root": {
    "text": "[POL] Molim Vas, da li biste mogli da mi pokažete za koga ste glasali, čisto da proverim?",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Izvinite, ali to je tajna, ne mogu da pokažem.",
        "explanation": "Ispravno ste postupili. Tajnost glasanja je zagarantovana zakonom.",
        "score": 100
      },
      {
        "text": "Može, evo, pogledajte.",
        "explanation": "Ovo je prekršaj pravila o tajnosti glasanja.",
        "score": -100
      }
    ]
  }
}
```

### voter_booth_dialog_angry_03.json

```json
{
  "root": {
    "text": "[ANG] Presavijte listić pre ubacivanja, da se ne vidi za koga ste glasali!",
    "speaker": "LEFT",
    "choices": [
      {
        "text": "Neću da presavijem, neka svi vide za koga sam glasao!",
        "explanation": "Nepravilno postupate. Listić mora biti presavijen tako da se ne vidi kako ste glasali.",
        "score": -50
      },
      {
        "text": "Presaviću ga, ali ću svima reći za koga sam glasao.",
        "explanation": "Presavijanje listića je obavezno, ali otkrivanje načina glasanja nije zabranjeno ako to birač sam želi.",
        "score": -10
      },
      {
        "text": "Dobro, presaviću ga.",
        "explanation": "Ispravno postupate. Listić mora biti presavijen radi zaštite tajnosti glasanja.",
        "score": 100
      }
    ]
  }
}
```

### voter_booth_dialog_polite_03.json

```json
{
  "root": {
    "text": "[POL] Izvinite, zaboravio sam da presavijem listić, da li je to problem?",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "Nije problem, samo ga ubacite tako.",
        "explanation": "To je prekršaj pravila. Listić mora biti presavijen radi zaštite tajnosti glasanja.",
        "score": -50
      },
      {
        "text": "Molim Vas, presavijte listić pre ubacivanja.",
        "explanation": "Ispravno postupate. Listić mora biti presavijen tako da se ne vidi način glasanja.",
        "score": 100
      }
    ]
  }
}
```

---

# Deo 2: Pravila za prompt

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
- Bodovati dijaloge po veličini greške ili prekršaja, staviti svaki bod u odnos sa svim dijalozima i bodovima.

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

### voter_lamp_dialog_angry_01.json

```json
{
  "root": {
    "text": "[ANG] Uf što sam ljut lele",
    "choices": [
      {
        "text": "a nemoj brate",
        "explanation": "Odlican izbor",
        "score": 100,
        "next": "node1"
      },
      {
        "text": "e sad ću da te ulemam",
        "explanation": "Mnogo loša varijanta",
        "score": -200,
        "next": "node2"
      }
    ],
    "speaker": "LEFT"
  },
  "node1": {
    "text": "ok neću",
    "choices": [
      {
        "text": "e fala ti brate",
        "explanation": "Sjajan izbor",
        "score": 200
      },
      {
        "text": "mrš",
        "explanation": "Nemoj tako :(",
        "score": -200
      }
    ],
    "speaker": "RIGHT"
  },
  "node2": {
    "text": "ok ajde idem ja",
    "speaker": "LEFT"
  }
}
```

### voter_lamp_dialog_polite_01.json

```json
{
  "root": {
    "text": "[POL] Blablabla ovo je prvi tekst",
    "choices": [
      {
        "text": "ovo je prvi izbor haha",
        "explanation": "Odlican izbor",
        "score": 100,
        "next": "node1"
      },
      {
        "text": "ovo je drugi izbor",
        "explanation": "Najbolji izbor",
        "score": 200,
        "next": "node2"
      },
      {
        "text": "ovo zavrsava konverzaciju",
        "explanation": "Katastrofa izbor",
        "score": -20
      }
    ],
    "speaker": "RIGHT"
  },
  "node1": {
    "text": "lele šta mi reče",
    "choices": [
      {
        "text": "opa",
        "explanation": "Sjajan izbor",
        "score": 200
      },
      {
        "text": "ahaa aha",
        "explanation": "Podjednako dobar izbor",
        "score": 200
      }
    ],
    "speaker": "LEFT"
  },
  "node2": {
    "text": "DOBAR DAN",
    "next": "node3",
    "speaker": "RIGHT"
  },
  "node3": {
    "text": "I to je to brate",
    "speaker": "RIGHT"
  }
}
```

### voter_id_dialog_angry_01.json

```json
{
  "root": {
    "text": "[ANG] Sada moramo da uzmemo Vaše lične podatke",
    "next": "response"
  },
  "response": {
    "text": "A nemoj sada, žurim baš",
    "next": "choice01"
  },
  "choice01": {
    "text": " ",
    "choices": [
      {
        "text": "Moramo proveriti podatke",
        "explanation": "Svaki kandidat mora biti proveren.",
        "score": 100,
        "next": "reluctant"
      },
      {
        "text": "Naši smo mi, teraj dalje",
        "explanation": "Svaki kandidat mora biti proveren.",
        "score": -100,
        "next": "thankful"
      }
    ]
  },
  "reluctant": {
    "text": "Dobro, ajde, zakasniću kući, ubiće me žena..."
  },
  "thankful": {
    "text": "Hvala za prođu brate, dužan sam ti"
  }
}
```

### voter_id_dialog_polite_01.json

```json
{
  "root": {
    "text": "[POL] Sada moramo da uzmemo Vaše lične podatke",
    "next": "response"
  },
  "response": {
    "text": "A nemoj sada, žurim baš",
    "next": "choice01"
  },
  "choice01": {
    "text": " ",
    "choices": [
      {
        "text": "Moramo proveriti podatke",
        "explanation": "Svaki kandidat mora biti proveren.",
        "score": 100,
        "next": "reluctant"
      },
      {
        "text": "Naši smo mi, teraj dalje",
        "explanation": "Svaki kandidat mora biti proveren.",
        "score": -100,
        "next": "thankful"
      }
    ]
  },
  "reluctant": {
    "text": "Dobro, ajde, zakasniću kući, ubiće me žena..."
  },
  "thankful": {
    "text": "Hvala za prođu brate, dužan sam ti"
  }
}
```

### voter_list_dialog_angry_01.json

```json
{
  "root": {
    "text": "[ANG] Vreme je da proverimo da li ste u biračkom spisku",
    "next": "response"
  },
  "response": {
    "text": "Vidim da ovlaš pregledaju spisak, i kažu mi da se potpišem negde bezveze...",
    "choices": [
      {
        "text": "Šta radite to, ovo nije moje ime!",
        "explanation": "Svaki glasač mora biti zaveden samo pod svojim imenom",
        "score": 100,
        "next": "oops"
      },
      {
        "text": "Ma potpisaću se ja...",
        "explanation": "Svaki kandidat mora biti zaveden samo pod svojim imenom. U suprotnom može doći do prevara.",
        "score": -100
      }
    ]
  },
  "oops": {
    "text": "Ju, nisam obratio pažnju, izvinite"
  }
}
```

### voter_list_dialog_polite_01.json

```json
{
  "root": {
    "text": "[POL] Vreme je da proverimo da li ste u biračkom spisku",
    "next": "response"
  },
  "response": {
    "text": "Vidim da ovlaš pregledaju spisak, i kažu mi da se potpišem negde bezveze...",
    "choices": [
      {
        "text": "Šta radite to, ovo nije moje ime!",
        "explanation": "Svaki glasač mora biti zaveden samo pod svojim imenom",
        "score": 100,
        "next": "oops"
      },
      {
        "text": "Ma potpisaću se ja...",
        "explanation": "Svaki kandidat mora biti zaveden samo pod svojim imenom. U suprotnom može doći do prevara.",
        "score": -100
      }
    ]
  },
  "oops": {
    "text": "Ju, nisam obratio pažnju, izvinite"
  }
}
```

### voter_spray_dialog_angry_01.json

```json
{
  "root": {
    "text": "[ANG] Ponestaje mi spreja...",
    "choices": [
      {
        "text": "...Samo da uzmem drugi, biće gotovo odmah!",
        "explanation": "Svaki kandidat mora biti označen sprejem koji se vidi pod UV svetlom.",
        "score": 100
      },
      {
        "text": "Terajte Vi dalje, posle ćemo da sredimo.",
        "explanation": "Svaki kandidat mora biti označen sprejem koji se vidi pod UV svetlom.",
        "score": -100
      }
    ]
  }
}
```

### voter_spray_dialog_polite_01.json

```json
{
  "root": {
    "text": "[POL] Ponestaje mi spreja...",
    "choices": [
      {
        "text": "...Samo da uzmem drugi, biće gotovo odmah!",
        "explanation": "Svaki kandidat mora biti označen sprejem koji se vidi pod UV svetlom.",
        "score": 100
      },
      {
        "text": "Terajte Vi dalje, posle ćemo da sredimo.",
        "explanation": "Svaki kandidat mora biti označen sprejem koji se vidi pod UV svetlom.",
        "score": -100
      }
    ]
  }
}
```

### voter_ballot_dialog_angry_01.json

```json
{
  "root": {
    "text": "[ANG] Izvolite glasački listić! Glasate iza paravana zaokruživanjem rednog broja ispred naziva željene liste.",
    "speaker": "LEFT",
    "next": "response"
  },
  "response": {
    "text": "Primećuje se da je listić pocepan na jednom mestu",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "Moram da tražim drugi!",
        "explanation": "Potencijalno nevalidan listić mora odmah da se prijavi.",
        "score": 250
      },
      {
        "text": "Ovaj je okej, znamo se mi.",
        "explanation": "Potencijalno nevalidan listić mora odmah da se prijavi. Pocepan lisitć se možda neće računati kao validan glas",
        "score": -100
      }
    ]
  }
}
```

### voter_ballot_dialog_polite_01.json

```json
{
  "root": {
    "text": "[POL] Izvolite glasački listić!",
    "next": "response",
    "speaker": "LEFT"
  },
  "response": {
    "text": "Primećuje se da je listić pocepan na jednom mestu",
    "speaker": "RIGHT",
    "choices": [
      {
        "text": "Moram da tražim drugi!",
        "explanation": "Potencijalno nevalidan listić mora odmah da se prijavi.",
        "score": 250
      },
      {
        "text": "Ovaj je okej, znamo se mi.",
        "explanation": "Potencijalno nevalidan listić mora odmah da se prijavi. Pocepan lisitć se možda neće računati kao validan glas",
        "score": -100
      }
    ]
  }
}
```

### voter_booth_dialog_angry_01.json

```json
{
  "root": {
    "text": "[ANG] Rekli su mi da ću izgubiti posao ako ne slikam ličnu kartu pored listića...",
    "choices": [
      {
        "text": "Moram da slikam listić.",
        "explanation": "Ne dozvolite ucenama da utiču na Vaše lične stavove! Možete slikati listić, i poništiti ga.",
        "score": 100
      },
      {
        "text": "Zaokružiću listić, slikaću, a potom ću poništiti svoj izbor.",
        "explanation": "Ne dozvolite ucenama da utiču na Vaše lične stavove!",
        "score": -100
      }
    ]
  }
}
```

### voter_booth_dialog_polite_01.json

```json
{
  "root": {
    "text": "[POL] Rekli su mi da ću izgubiti posao ako ne slikam ličnu kartu pored listića...",
    "choices": [
      {
        "text": "Moram da slikam listić.",
        "explanation": "Ne dozvolite ucenama da utiču na Vaše lične stavove! Možete slikati listić, i poništiti ga.",
        "score": 100
      },
      {
        "text": "Zaokružiću listić, slikaću, a potom ću poništiti svoj izbor.",
        "explanation": "Ne dozvolite ucenama da utiču na Vaše lične stavove!",
        "score": -100
      }
    ]
  }
}
```
