#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
partition_ville_propre.py — mettre au propre la saisie des villes partagées

    /usr/bin/python3 circo/partition_ville_propre.py            # contrôle seul
    /usr/bin/python3 circo/partition_ville_propre.py --ecrit    # réécrit le CSV

LA SAISIE (`archives/partition_ville_saisie_2026-10-21.csv`, Adrien) dit, ville
par ville : « Toulouse centre, sud », Toulouse-1, « 1876-1885, 1889-1919 ».
LA VERSION PROPRE (`circo/partition_ville.csv`, lue par `sql/123`) veut une
ligne par (fraction, période), avec le code du canton dans la base.

Ce script ne réécrit que les villes qui ne sont pas encore dans le CSV propre :
les 67 premières lignes de la saisie ont été remises au propre à la main le
21 octobre 2026, et leur colonne `etat` porte le résultat de `123`.

LA RÉSOLUTION se fait À LA DATE de la ligne : les noms de canton changent
(« Rennes-Centre » devient « Rennes-Nord-Est », « Orléans-Nord-Est » devient
« Orléans-Bannier »). Pour une ligne [depuis, jusqu], on ne regarde que les
fractions de la ville qui ont un canton dans la fenêtre, sous les noms en
vigueur dans la fenêtre. Un libellé qui ne se résout pas, ou se résout de deux
façons, est montré et la ligne n'est pas écrite : CORRESPONDANCE ci-dessous
tranche à la main, avec sa raison.

UN CANTON NOMMÉ DANS DEUX CIRCONSCRIPTIONS À LA MÊME PÉRIODE (Bordeaux 5e en
1928-1940, coupé par la rue Sainte-Catherine) est écrit une fois, avec
`circonscription` = « 2-3 » : partagé. `123` le range dans l'unité fusionnée
de sa mère (« Bordeaux (1-2-3-4) »), seule chose vraie à cette échelle.

LA COLONNE `circo_ville` : le nom que porte la circonscription quand ce n'est
pas celui de la ville — Roubaix et Tourcoing votent dans « Lille-7 »,
« Lille-9 », Lens dans « Béthune-2 », Strasbourg dans « Strasbourg-Ville-1 ».
"""
import csv
import re
import sys
import unicodedata

import psycopg2

SAISIE = "archives/partition_ville_saisie_2026-10-21.csv"
PROPRE = "circo/partition_ville.csv"
DEJA_PROPRES = 67          # lignes de données de la saisie déjà au propre

# clé normalisée du début de libellé -> (dep, insee, ville, préfixes des noms)
VILLES = [
    ("brest", "29", "29019", "Brest", ["brest"]),
    ("ales", "30", "30007", "Alès", ["ales", "alais"]),
    ("nime", "30", "30189", "Nîmes", ["nimes"]),
    ("toulouse", "31", "31555", "Toulouse", ["toulouse"]),
    ("bordeaux", "33", "33063", "Bordeaux", ["bordeaux"]),
    ("bezier", "34", "34032", "Béziers", ["beziers"]),
    ("montpellier", "34", "34172", "Montpellier", ["montpellier"]),
    ("rennes", "35", "35238", "Rennes", ["rennes"]),
    ("tours", "37", "37261", "Tours", ["tours"]),
    ("bourgoin-jallieu", "38", "38053", "Bourgoin-Jallieu", ["bourgoin-jallieu", "bourgoin"]),
    ("fontaine", "38", "38169", "Fontaine", ["fontaine"]),
    ("grenoble", "38", "38185", "Grenoble", ["grenoble"]),
    ("saint-etienne", "42", "42218", "Saint-Étienne", ["saint-etienne"]),
    ("le-puy", "43", "43157", "Le Puy-en-Velay", ["le-puy", "puy-en-velay"]),
    ("nantes", "44", "44109", "Nantes", ["nantes"]),
    ("orleans", "45", "45234", "Orléans", ["orleans"]),
    ("angers", "49", "49007", "Angers", ["angers"]),
    ("saumur", "49", "49328", "Saumur", ["saumur"]),
    ("reims", "51", "51454", "Reims", ["reims"]),
    ("laval", "53", "53130", "Laval", ["laval"]),
    ("mayenne", "53", "53147", "Mayenne", ["mayenne"]),
    ("nancy", "54", "54395", "Nancy", ["nancy"]),
    ("metz", "57", "57463", "Metz", ["metz-ville", "metz"]),
    ("douai", "59", "59178", "Douai", ["douai"]),
    ("dunkerque", "59", "59183", "Dunkerque", ["dunkerque"]),
    ("lille", "59", "59350", "Lille", ["lille"]),
    ("roubaix", "59", "59512", "Roubaix", ["roubaix"]),
    ("tourcoing", "59", "59599", "Tourcoing", ["tourcoing"]),
    ("valenciennes", "59", "59606", "Valenciennes", ["valenciennes"]),
    ("wattrelos", "59", "59650", "Wattrelos", ["roubaix"]),
    ("beauvais", "60", "60057", "Beauvais", ["beauvais"]),
    ("compiegne", "60", "60159", "Compiègne", ["compiegne"]),
    ("creil", "60", "60175", "Creil", ["creil"]),
    ("arras", "62", "62041", "Arras", ["arras"]),
    ("lens", "62", "62498", "Lens", ["lens"]),
    ("boulogne-sur-mer", "62", "62160", "Boulogne-sur-Mer", ["boulogne-sur-mer"]),
    ("calais", "62", "62193", "Calais", ["calais"]),
    ("mericourt", "62", "62570", "Méricourt", ["mericourt"]),
    ("clermont-ferrand", "63", "63113", "Clermont-Ferrand", ["clermont-ferrand"]),
    ("clermont-errand", "63", "63113", "Clermont-Ferrand", ["clermont-ferrand"]),
    ("pau", "64", "64445", "Pau", ["pau"]),
    ("tarbes", "65", "65440", "Tarbes", ["tarbes"]),
    ("perpignan", "66", "66136", "Perpignan", ["perpignan"]),
    ("strasbourg", "67", "67482", "Strasbourg", ["strasbourg"]),
    ("mulhouse", "68", "68224", "Mulhouse", ["mulhouse"]),
]

# Le nom de la circonscription quand ce n'est pas celui de la ville.
CIRCO_VILLE = {"lille": "Lille", "bethune": "Béthune",
               "strasbourg-ville": "Strasbourg-Ville", "le-puy": "Le Puy"}

# Fautes de frappe de la saisie, corrigées avant tout.
COQUILLES = {
    ("tourcoing nord-est, sud", "Lille-9", "1928-1941"): "1928-1940",
}

# Libellés que les noms de la base ne résolvent pas : (ville, début, jeton)
# -> (codes de canton, raison), ou (None, raison) pour écarter le libellé.
# Tranchés le 25 octobre 2026 ; « coquille présumée » = le seul canton de la
# ville que la ligne de saisie ne nomme pas ailleurs.
_PAU = (None, "1986 : la partition (3, 1, 2 cantons) concorde avec la base ; "
              "numérotation des cantons de Pau non résolue, rien à poser")
_BREST = (None, "1986 : les huit cantons numérotés n'existent pas en base avant 1992 ; "
                "la base porte déjà 1986")
CORRESPONDANCE = {
    ("Brest", 1869, "1"): (["2903"], "Brest 1 = Brest-Ville, nom de la base"),
    **{("Brest", 1986, n): _BREST for n in "12345678"},
    ("Grenoble", 1958, "nord"): (["3813"], "Grenoble-Nord, « 2e canton » dans la base"),
    ("Saint-Étienne", 1857, "ouest"): (["4221", "4222"],
        "la base a quatre cantons dès 1815 : ouest = Nord-Ouest et Sud-Ouest"),
    ("Saint-Étienne", 1857, "est"): (["4219", "4220"],
        "la base a quatre cantons dès 1815 : est = Nord-Est et Sud-Est"),
    ("Nantes", 1986, "13"): (None, "pas de 13e canton de Nantes en base"),
    ("Orléans", 1958, "sud ouest"): (["4524"],
        "coquille présumée : Orléans-Nord-Ouest (pas de Sud-Ouest)"),
    ("Orléans", 1986, "carmes"): (["4522"],
        "Carmes = Orléans-Ouest en base, dans la 2e comme en 1986"),
    ("Orléans", 1986, "bourgogne"): (["4521"],
        "Bourgogne = Orléans-Est en base, dans la 3e comme en 1986"),
    ("Saumur", 1958, "nord"): (["4928"], "Saumur-Nord (Nord-Ouest en base)"),
    ("Laval", 1986, "sud-est"): (["5329"],
        "coquille présumée : Laval-Sud-Ouest (pas de Sud-Est)"),
    ("Metz", 1831, "1"): (None, "pas de fraction de Metz en base avant 1870"),
    ("Metz", 1831, "2"): (None, "pas de fraction de Metz en base avant 1870"),
    ("Metz", 1831, "3"): (None, "pas de fraction de Metz en base avant 1870"),
    ("Douai", 1928, "est"): (["5922"], "coquille présumée : Douai-Nord (pas d'Est)"),
    ("Douai", 1958, "est"): (["5922"], "coquille présumée : Douai-Nord (pas d'Est)"),
    ("Boulogne-sur-Mer", 1958, "nord"): (["6213"], "Boulogne-sur-Mer-Nord (Nord-Est en base)"),
    **{("Pau", 1986, n): _PAU for n in "123456"},
}

# Les années où commence un découpage (1815-1928).
DEBUTS = {1820, 1821, 1824, 1828, 1831, 1834, 1848, 1852, 1857, 1860, 1863,
          1869, 1870, 1876, 1881, 1885, 1889, 1893, 1898, 1902, 1910, 1914,
          1919, 1924, 1928}

ORDINAL = re.compile(r"^(\d+)\s*(er|e|eme|ème)?(\s+canton)?$")
ROMAIN = {"i": 1, "ii": 2, "iii": 3, "iv": 4, "v": 5, "vi": 6, "vii": 7,
          "viii": 8, "ix": 9, "x": 10, "xi": 11, "xii": 12, "xiii": 13,
          "xiv": 14, "xv": 15}


def norm(s):
    s = unicodedata.normalize("NFD", s or "").encode("ascii", "ignore").decode()
    s = s.lower().replace("’", "'").strip()
    s = re.sub(r"\s+", " ", s)
    s = s.replace("saint etienne", "saint-etienne").replace("le puy ", "le-puy ")
    return s


def cle(s):
    """Forme comparable d'un morceau de nom : tirets, ordinaux, romains."""
    s = norm(s).strip(" -")
    s = {"oust": "ouest"}.get(s, s)              # Clermont-Ferrand 1986
    s = re.sub(r"^(la|le|les) ", "", s)
    m = ORDINAL.match(s)
    if m:
        return m.group(1)
    if s in ROMAIN:
        return str(ROMAIN[s])
    s = re.sub(r"\s+canton$", "", s)
    s = re.sub(r"\s*&\s*", "-", s)
    return re.sub(r"[\s']+", "-", s)


def suffixe(nom, prefixes):
    n = norm(nom).replace(" ", "-") if False else norm(nom)
    for p in sorted(prefixes, key=len, reverse=True):
        for forme in (p, p.replace("-", " ")):
            if n.startswith(forme):
                reste = n[len(forme):]
                if reste == "" or reste[0] in " -":
                    return cle(reste)
    return cle(n)


def periodes(txt):
    out = []
    for morceau in str(txt).split(","):
        morceau = morceau.strip()
        if not morceau:
            continue
        a = re.match(r"^(\d{4})(?:\s*-\s*(\d{4}))?$", morceau)
        if not a:
            raise ValueError(f"période illisible : {txt!r}")
        d = int(a.group(1))
        f = int(a.group(2)) if a.group(2) else None
        if f and f in DEBUTS and f > d:
            # La saisie date comme Gaudillère : « 1820-1831 », « 1889-1893 »
            # finissent quand commence le découpage suivant. `jusqu` est une
            # année incluse. 1940 et 1986 sont de vraies fins d'année.
            f -= 1
        # « 1986 » seul : le découpage de 1986, jusqu'à 2012
        out.append((d, f))
    return out


def circo(txt):
    """'Toulouse-1' -> (1, ''), 'Lille -8' -> (8, 'Lille'), '3' -> (3, '')."""
    t = norm(txt)
    m = re.match(r"^(.*?)[\s-]*(\d+)$", t)
    if not m:
        raise ValueError(f"circonscription illisible : {txt!r}")
    prefixe = m.group(1).strip(" -").replace(" ", "-")
    return int(m.group(2)), prefixe


def ville_de(libelle):
    n = norm(libelle).replace(" ", "-")
    for v in sorted(VILLES, key=lambda v: len(v[0]), reverse=True):
        if n.startswith(v[0]):
            return v
    raise ValueError(f"ville inconnue : {libelle!r}")


def jetons(libelle, ville):
    n = norm(libelle)
    # retirer le nom de ville en tête (avec ou sans tirets)
    k = ville[0]
    for forme in (k, k.replace("-", " ")):
        if n.replace(" ", "-").startswith(k) and n.startswith(forme):
            n = n[len(forme):]
            break
    else:
        n = re.sub(r"^\S+", "", n)
    morceaux = []
    for part in re.split(r",", n):
        part = part.strip()
        if not part:
            continue
        m = re.match(r"^(\D+?)\s+(\d(?:\s*&\s*\d)+)$", part)
        if m:                       # « nord-ouest 1 & 2 »
            for num in re.split(r"\s*&\s*", m.group(2)):
                morceaux.append(f"{m.group(1)} {num}")
            continue
        for sous in re.split(r"\s*&\s*|\s+et\s+", part):
            sous = sous.strip()
            for p in ville[4] + [ville[0]]:
                sous = re.sub(rf"^{re.escape(p)}[\s-]+", "", sous)
            if sous:
                morceaux.append(sous)
    return morceaux


def charge_noms(cur):
    insee = sorted({v[2] for v in VILLES})
    cur.execute("""
        SELECT a.insee_geofla, split_part(a.atom_id, '#', 2) AS cid,
               coalesce(v.nom, u.nom), coalesce(v.periode, 'empty'::daterange),
               (SELECT range_agg(m.periode) FROM membership m
                 WHERE m.atom_id = a.atom_id AND m.niveau = 'canton') AS vie,
               u.nom
          FROM atom a
          JOIN unit u ON u.unit_id = split_part(a.atom_id, '#', 2)
          LEFT JOIN unit_version v ON v.unit_id = u.unit_id
         WHERE a.fraction AND a.insee_geofla = ANY(%s)""", (insee,))
    return cur.fetchall()


def vivante(vie, d0, d1, cur):
    if vie is None:
        return False
    cur.execute("SELECT %s::datemultirange && daterange(%s, %s)", (vie, d0, d1))
    return cur.fetchone()[0]


DIRECTION = re.compile(r"^(nord|sud|est|ouest|centre)(-(nord|sud|est|ouest|centre))*(-\d+)?$")


def vie_de(noms, insee, cid):
    for i, c, _, _, vie, _ in noms:
        if i == insee and c == cid:
            return vie
    return None


def candidats(noms, ville, d0, d1, cur):
    """(fractions vivantes dans la fenêtre, toutes les fractions) -> {clé: {(cid, nom)}}"""
    par_fraction = {}
    for insee, cid, nom, per, vie, nom_unite in noms:
        if insee != ville[2]:
            continue
        info = par_fraction.setdefault(cid, {"unite": nom_unite, "noms": set(),
                                             "vive": vivante(vie, d0, d1, cur)})
        cur.execute("SELECT NOT isempty(%s::daterange) AND %s::daterange && daterange(%s, %s)",
                    (per, per, d0, d1))
        if cur.fetchone()[0]:
            info["noms"].add(nom)
    vives, toutes = {}, {}
    for cid, info in par_fraction.items():
        # sans version dans la fenêtre, le nom de l'unité
        for nom in info["noms"] or {info["unite"]}:
            k = suffixe(nom, ville[4])
            toutes.setdefault(k, set()).add((cid, nom))
            if info["vive"]:
                vives.setdefault(k, set()).add((cid, nom))
    return vives, toutes


def resout(k, cands):
    trouve = cands.get(k)
    if not trouve and not DIRECTION.match(k) and not k.isdigit():
        # « nogent » -> « nogent-sur-oise », « branche » -> « coudekerque-branche »
        proches = {kk: v for kk, v in cands.items()
                   if kk.endswith("-" + k) or kk.startswith(k + "-")}
        if len(proches) == 1:
            trouve = next(iter(proches.values()))
    if not trouve and re.search(r"-\d+$", k):
        # « nord-ouest 1 » quand la base n'a qu'un Nord-Ouest
        trouve = cands.get(re.sub(r"-\d+$", "", k))
    return trouve


def nom_a(noms, insee, cid, d0, d1, cur):
    vives, toutes = candidats([n for n in noms if n[0] == insee and n[1] == cid],
                              (None, None, insee, None, []), d0, d1, cur)
    return sorted(n for v in toutes.values() for _, n in v)[0]


def main():
    ecrit = "--ecrit" in sys.argv
    cx = psycopg2.connect(dbname="histgis")
    cur = cx.cursor()
    cur.execute("SET search_path TO histgis, public")
    noms = charge_noms(cur)

    with open(SAISIE, newline="", encoding="utf-8") as f:
        lignes = list(csv.reader(f))[1 + DEJA_PROPRES:]

    sortie, refus, ecartes = [], [], []
    for rang, ligne in enumerate(lignes, start=DEJA_PROPRES + 2):
        if not any(c.strip() for c in ligne):
            continue
        lib, cir, ans = (ligne + ["", "", ""])[:3]
        note = ligne[3].strip() if len(ligne) > 3 else ""
        ans = COQUILLES.get((lib.strip(), cir.strip(), ans.strip()), ans)
        ville = ville_de(lib)
        num, pref = circo(cir)
        cv = ""
        if pref and pref != ville[0] and not ville[0].startswith(pref):
            if pref not in CIRCO_VILLE:
                raise ValueError(f"l. {rang} : préfixe de circonscription {pref!r}")
            cv = CIRCO_VILLE[pref]
        elif pref == "le-puy":
            cv = "Le Puy"
        for d, fin in periodes(ans):
            d0 = f"{d}-01-01"
            d1 = f"{(fin or 2012) + 1}-01-01"
            vives, toutes = candidats(noms, ville, d0, d1, cur)
            for j in jetons(lib, ville):
                k = cle(j)
                if (ville[3], d, j) in CORRESPONDANCE:
                    forcé, raison = CORRESPONDANCE[(ville[3], d, j)]
                    if forcé is None:
                        ecartes.append((rang, ville[3], d, fin, j, raison))
                        continue
                    for cid in forcé:
                        nom = nom_a(noms, ville[2], cid, d0, d1, cur)
                        sortie.append([ville[1], ville[2], ville[3], cid, nom, num, d,
                                       fin if fin else "", "",
                                       "; ".join(x for x in (note, raison) if x), cv])
                    continue
                trouve = resout(k, vives) or resout(k, toutes)
                ids = {c for c, _ in (trouve or set())}
                if len(ids) > 1:            # homonymes : celui qui vit au premier jour
                    d0p = f"{d}-01-02"
                    ids = {c for c in ids if vivante(vie_de(noms, ville[2], c), d0, d0p, cur)}
                if len(ids) != 1:
                    refus.append((rang, ville[3], d, fin, j, k,
                                  sorted(trouve or []), sorted(vives)))
                    continue
                cid = ids.pop()
                nom = sorted(n for c, n in trouve if c == cid)[0]
                sortie.append([ville[1], ville[2], ville[3], cid, nom, num,
                               d, fin if fin else "", "", note, cv])

    # un canton dans deux circonscriptions à la même période -> partagé
    vu = {}
    for r in sortie:
        vu.setdefault((r[1], r[3], r[6], r[7]), []).append(r)
    propre = []
    for groupe in vu.values():
        r = list(groupe[0])
        nums = sorted({g[5] for g in groupe})
        if len(nums) > 1:
            r[5] = "-".join(map(str, nums))
            r[9] = "; ".join(sorted({g[9] for g in groupe if g[9]})) or "canton partagé"
        notes = sorted({g[9] for g in groupe if g[9]})
        if len(nums) == 1 and notes:
            r[9] = "; ".join(notes)
        propre.append(r)

    print(f"{len(lignes)} lignes de saisie, {len(propre)} lignes propres, "
          f"{len(refus)} libellés non résolus")
    for r in ecartes:
        print("  ÉCARTÉ l.%d %s %s-%s %r : %s" % r)
    for r in refus:
        print("  REFUS l.%d %s %s-%s %r (clé %r) -> %s ; connus : %s" % r)
    for r in propre:
        if "-" in str(r[5]):
            print("  PARTAGÉ", r[2], r[4], r[5], r[6], r[7])

    if ecrit:
        if refus:
            sys.exit("Libellés non résolus : rien n'est écrit.")
        with open(PROPRE, newline="", encoding="utf-8") as f:
            anciennes = list(csv.reader(f))
        entete = anciennes[0]
        if "circo_ville" not in entete:
            entete = entete + ["circo_ville"]
            anciennes = [entete] + [l + [""] for l in anciennes[1:]]
        deja = {l[1] for l in anciennes[1:]}
        nouvelles = [r for r in propre if r[1] not in deja]
        with open(PROPRE, "w", newline="", encoding="utf-8") as f:
            w = csv.writer(f, lineterminator="\n")
            w.writerows(anciennes)
            w.writerows(nouvelles)
        print(f"{PROPRE} : {len(nouvelles)} lignes ajoutées.")


if __name__ == "__main__":
    main()
