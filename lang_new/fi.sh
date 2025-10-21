## PERUSTIEDOT
LANG_CODE="fi"
LANGUAGE_NAME="Suomi"
LANGUAGE_NAME_EN="Finnish"

# TEKSTIKOODIT (001000–001999) – KÄYTTÖLIITTYMÄN ELEMENTIT
TXT_001000="Jatka"
TXT_001001="OK"
TXT_001002="Peruuta"
TXT_001003="Poistu"
TXT_001101="Kyllä"
TXT_001102="Ei"
TXT_001103="Takaisin"
TXT_001104="Seuraava"

# VIESTIKOORDIT (002000–200999) – KÄYTTÄJÄVIESTIT
MSG_002000="Toiminto suoritettu"
MSG_002100="Onnistui"
MSG_002101="Toiminto suoritettu onnistuneesti"
MSG_002200="Käsitellään..."
MSG_002300="Varoitus"

# TYYPPIKOODIT (003000–003999) – LUOKAT
TYPE_003000="Yleinen"
TYPE_003100="Asetukset"
TYPE_003200="Hakemisto"
TYPE_003300="Tiedosto"
TYPE_003400="Verkko"
TYPE_003500="Järjestelmä"

# VIRHEKOODIT (004000–004999) – VIRHEVIESTIT
ERR_004000="Tapahtui virhe"
ERR_004100="Asetusvirhe"
ERR_004200="Hakemistovirhe"
ERR_004300="Tiedostovirhe"
ERR_004400="Verkkovirhe"
ERR_004500="Järjestelmävirhe"

# LOKIKOORDIT (005000–005999) – LOKITIEDOT
LOG_005000="Tapahtuma kirjattu"
LOG_005100="Sovellus käynnistetty"
LOG_005101="Sovellus suljettu"
LOG_005200="Asetukset ladattu"
LOG_005201="Asetukset tallennettu"
LOG_005300="Tiedosto käsitelty"
LOG_005301="Tiedosto luotu"
LOG_005302="Tiedosto poistettu"

# ASETUSKOODIT (006000–006999) – ASETUSKÄYTTÖLIITTYMÄ
CFG_006000="Asetukset"
CFG_006100="Määritykset"
CFG_006101="Yleiset asetukset"
CFG_006102="Verkkoasetukset"
CFG_006103="Turva-asetukset"
CFG_006200="Asennusohjattu"
CFG_006201="Tervetuloa asennukseen"
CFG_006202="Asennus valmis"

# OHJEKOODIT (007000–007999) – --help-TULOSTE
HELP_007000="Ohje"
HELP_007100="Käyttö"
HELP_007101="Syntaksi"
HELP_007102="Parametrit"
HELP_007103="Valinnat"
HELP_007200="Esimerkit"
HELP_007300="Kuvaus"

# EDISTYMISKOODIT (008000–008999) – EDISTYMISEN TILA
PROG_008000="Edistyminen"
PROG_008100="Asennetaan..."
PROG_008101="Ladataan..."
PROG_008102="Käsitellään..."
PROG_008104="Alustetaan..."
PROG_008200="Valmis"
PROG_008201="Asennus valmis"
PROG_008202="Lataus valmis"

# SYÖTEKOODIT (009000–009999) – KÄYTTÄJÄN SYÖTE
INPUT_009000="Syöte vaaditaan"
INPUT_009100="Anna arvo"
INPUT_009101="Anna polku"
INPUT_009102="Anna nimi"
INPUT_009200="Vahvistus"
INPUT_009201="Oletko varma?"
INPUT_009202="Vahvista poistaminen"

# VALIKKOKOODIT (010000–010999) – VALIKKOJÄRJESTELMÄ (heksa 10. ryhmälle)
MENU_010000="Valikko"
MENU_010100="Päävalikko"
MENU_010101="Asetusvalikko"
MENU_010102="Työkalut-valikko"
MENU_010200="Valitse vaihtoehto"
MENU_010201="Navigointi"

CODE_META_MAP=(
  # Käyttöliittymätekstit (010000–019999)
  [001]="TXT:Tuntematon teksti"
  [002]="MSG:Tuntematon viesti"
  [003]="TYPE:Tuntematon tyyppi"

  # Virheet, lokit, asetukset (040000–069999)
  [004]="ERR:Tuntematon virhe"
  [005]="LOG:Tuntematon lokitapahtuma"
  [006]="CFG:Tuntematon asetus"

  # Ohje, edistyminen, syöte, valikko (070000–100000)
  [007]="HELP:Tuntematon ohje"
  [008]="PROG:Tuntematon edistys"
  [009]="INPUT:Tuntematon syöte"
  [010]="MENU:Tuntematon valikko"
)
