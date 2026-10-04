#!/usr/bin/env python3
"""
trfgis_extract.py — nomenclatures COG_COMMUNES_YYYY.txt (TRF-GIS) vers
tables normalisées prêtes pour COPY dans le schéma histgis.

Deux commandes :

    check   effectifs par année, à confronter aux comptes publiés
    build   compaction en intervalles + tables unit / membership / atom

Usage :
    python3 trfgis_extract.py check ./sources/trfgis/communes/Nomenclatures
    python3 trfgis_extract.py build ./sources/trfgis/communes/Nomenclatures --out ./build

Notes de format, tirées de l'inspection réelle des fichiers :
  - séparateur virgule, en-tête nommé en première ligne, encodage latin-1 ;
  - le jeu de colonnes varie selon l'année (66 en 1870, 69 en 1900/1940 :
    mcor/mdiv deviennent pmreg/pmsub, insp/cl_insp apparaissent), d'où
    une lecture par nom et jamais par position ;
  - `deppct` et `deppcirco` portent déjà le préfixe département : ils
    servent d'identifiants d'unité.
"""

import argparse
import csv
import io
import os
import re
import signal
import sys
from collections import Counter, defaultdict

ENCODING = "latin-1"
YEAR_RE = re.compile(r"COG_COMMUNES_(\d{4})\.txt$", re.I)

# Seules colonnes utiles ici. Le reste (justice, armée, académies, diocèses)
# se charge sur le même modèle en ajoutant des couples id/nom à NIVEAUX.
NIVEAUX = {
    "canton": ("deppct", "pct_name_prop", "pct_type"),
    "circo":  ("deppcirco", "pcirco_name_prop", "pcirco_type"),
}
# La commune historique est identifiée par son code Cassini/EHESS. `insee`
# désigne la commune ACTUELLE (trame GEOFLA 2011) qui la contient : plusieurs
# communes anciennes absorbées depuis partagent le même code INSEE.
CLE = "cassini"
# Colonne portant le rattachement à la trame GEOFLA 2011. `insee` est le code
# propre de la commune historique, caduc si elle a fusionné depuis ; `com_act`
# est le code de la commune actuelle. Réglable par --geom-col.
CLE_GEOM = "com_act"

# pct_type : 1 = communes entières uniquement, 6 = pseudo-canton,
# 7 = arrondissement de Paris. 2 à 5 impliquent des fractions de commune.
PCT_FRACTION = {2, 3, 4, 5}


def annees(root):
    """Retourne [(année, chemin)] trié, à partir des noms de fichiers."""
    out = []
    for dirpath, _, filenames in os.walk(root):
        for fn in filenames:
            m = YEAR_RE.search(fn)
            if m:
                out.append((int(m.group(1)), os.path.join(dirpath, fn)))
    return sorted(out)


def lire(path):
    """Génère les lignes d'un fichier COG_COMMUNES en dictionnaires."""
    with open(path, newline="", encoding=ENCODING) as fh:
        for row in csv.DictReader(fh):
            yield row


def entier(v):
    try:
        return int(v)
    except (TypeError, ValueError):
        return None


# ------------------------------------------------------------------- check

def cmd_check(root):
    fichiers = annees(root)
    if not fichiers:
        sys.exit(f"Aucun COG_COMMUNES_YYYY.txt sous {root!r}.")

    print(f"{'année':>6} {'communes':>9} {'dép.':>5} {'pseudo-ct':>10} "
          f"{'dont frac':>10} {'dont pcant':>11} {'dont Paris':>11} "
          f"{'circos':>7} {'col':>4}")
    for an, path in fichiers:
        communes = 0
        deps = set()
        # type retenu par pseudo-canton : toutes ses communes portent le même
        type_pct = {}
        circos = set()
        ncols = None
        for row in lire(path):
            if ncols is None:
                ncols = len(row)
            communes += 1
            if row.get("dep"):
                deps.add(row["dep"])
            uid = row.get("deppct")
            if uid:
                type_pct.setdefault(uid, entier(row.get("pct_type")))
            if row.get("deppcirco"):
                circos.add(row["deppcirco"])

        frac = sum(1 for t in type_pct.values() if t in PCT_FRACTION)
        pcant = sum(1 for t in type_pct.values() if t == 6)
        paris = sum(1 for t in type_pct.values() if t == 7)
        print(f"{an:>6} {communes:>9} {len(deps):>5} {len(type_pct):>10} "
              f"{frac:>10} {pcant:>11} {paris:>11} {len(circos):>7} "
              f"{ncols:>4}")

    print("\nRepères publiés : 87 à 90 départements, 2 861 à 3 028 cantons,",
          file=sys.stderr)
    print("526 à 598 circonscriptions au scrutin uninominal, 87 à 100 au",
          file=sys.stderr)
    print("scrutin de liste départemental (1871, 1885, 1919, 1924).",
          file=sys.stderr)
    print("Les colonnes ci-dessus comptent des PSEUDO-cantons : la trame de",
          file=sys.stderr)
    print("Gay fusionne les cantons qui se partagent une commune. Passer par",
          file=sys.stderr)
    print("COG_CANTONS_YYYY_MAPPING pour retrouver les cantons réels.",
          file=sys.stderr)


# ------------------------------------------------------------------- build

def decode_best(raw):
    """Les nomenclatures sont en latin-1 ; les fichiers tabulés rendus par
    Dataverse peuvent être en UTF-8, parfois doublement encodé. On essaie
    dans cet ordre et on répare le double encodage s'il se détecte."""
    for enc in ("utf-8", "latin-1"):
        try:
            txt = raw.decode(enc)
        except UnicodeDecodeError:
            continue
        if enc == "utf-8" and "Ã" in txt:
            try:
                return txt.encode("latin-1").decode("utf-8")
            except (UnicodeEncodeError, UnicodeDecodeError):
                pass
        return txt
    return raw.decode("latin-1", errors="replace")


MAPPING_RE = re.compile(r"COG_CANTONS_(\d{4})_MAPPING\.(tab|txt|csv)$", re.I)


def lire_mapping(path):
    with open(path, "rb") as fh:
        txt = decode_best(fh.read())
    delim = "\t" if "\t" in txt.split("\n", 1)[0] else ","
    return list(csv.DictReader(io.StringIO(txt), delimiter=delim))


def cmd_cantons(root_com, root_map):
    """Réconcilie les pseudo-cantons des nomenclatures communales avec les
    cantons réels du mapping, année par année."""
    maps = {}
    for dirpath, _, filenames in os.walk(root_map):
        for fn in filenames:
            m = MAPPING_RE.search(fn)
            if m:
                maps[int(m.group(1))] = os.path.join(dirpath, fn)
    if not maps:
        sys.exit(f"Aucun COG_CANTONS_YYYY_MAPPING sous {root_map!r}.")

    communes = dict(annees(root_com))

    print(f"{'année':>6} {'pseudo-ct':>10} {'fusionnés':>10} "
          f"{'ct inédits':>14} {'total réel':>11} {'orphelins':>10}")
    for an in sorted(maps):
        if an not in communes:
            continue
        lignes = list(lire(communes[an]))
        # Même exclusion que dans build : l'entrée agrégée Paris fait doublon
        # avec les vingt arrondissements et ajoute un pseudo-canton fictif.
        if any((r.get("insee") or "").startswith(PREFIXE_ARR_PARIS)
               for r in lignes):
            lignes = [r for r in lignes
                      if (r.get("insee") or "") != DOUBLON_PARIS]
        pseudo = {r["deppct"] for r in lignes if r.get("deppct")}
        rows = lire_mapping(maps[an])
        m_pseudo = {r["deppct"] for r in rows if r.get("deppct")}
        m_reels = {r["depct"] for r in rows if r.get("depct")}
        orphelins = m_pseudo - pseudo
        # Un canton réel qui contient des communes entières figure déjà dans
        # la nomenclature communale : seuls s'ajoutent ceux qui n'y sont pas,
        # entièrement composés de fractions.
        inedits = m_reels - pseudo
        total = len(pseudo) - len(m_pseudo) + len(inedits)
        print(f"{an:>6} {len(pseudo):>10} {len(m_pseudo):>10} "
              f"{len(inedits):>14} {total:>11} {len(orphelins):>10}")
        if orphelins:
            ex = ", ".join(sorted(orphelins)[:5])
            print(f"       pseudo-cantons du mapping absents des communes : {ex}",
                  file=sys.stderr)

    print("\n'total réel' = pseudo-cantons, moins ceux de type 6 qu'éclate le",
          file=sys.stderr)
    print("mapping, plus les seuls cantons réels absents de la nomenclature",
          file=sys.stderr)
    print("communale. C'est ce nombre qui doit",
          file=sys.stderr)
    print("être confronté aux comptes publiés, jamais celui des pseudo-cantons.",
          file=sys.stderr)


SEP_MULTI = " / "

# Paris figure deux fois dans la nomenclature : les vingt arrondissements
# (75101-75120), chacun avec ses propres canton et circonscription, et une
# entrée agrégée 75056 rattachée aux unités fictives 7580 et 7599. Cette
# seconde entrée fait doublon — son territoire est intégralement couvert par
# les arrondissements — et fausse les effectifs d'une unité. On l'écarte dès
# lors que les arrondissements sont présents la même année.
DOUBLON_PARIS = "75056"
PREFIXE_ARR_PARIS = "751"


def _dbf_colonne(path, nom_colonne):
    """Extrait une colonne texte d'un .dbf sans dépendance externe."""
    with open(path, "rb") as fh:
        raw = fh.read()
    n_records = int.from_bytes(raw[4:8], "little")
    header_len = int.from_bytes(raw[8:10], "little")
    rec_len = int.from_bytes(raw[10:12], "little")
    champs, pos = [], 32
    while pos < header_len - 1 and raw[pos] != 0x0D:
        d = raw[pos:pos + 32]
        champs.append((d[:11].split(b"\x00")[0].decode("latin-1").strip(),
                       d[16]))
        pos += 32
    decalage, largeur = 1, None
    for nom, lg in champs:
        if nom == nom_colonne:
            largeur = lg
            break
        decalage += lg
    if largeur is None:
        sys.exit(f"Colonne {nom_colonne!r} absente. Colonnes : "
                 + ", ".join(n for n, _ in champs))
    valeurs = []
    for i in range(n_records):
        deb = header_len + i * rec_len + decalage
        valeurs.append(raw[deb:deb + largeur].decode("latin-1").strip())
    return valeurs


def cmd_geofla(out, dbf, colonne="INSEE_COM"):
    """Vérifie que chaque atome trouve son polygone dans la trame GEOFLA."""
    polygones = set(_dbf_colonne(dbf, colonne))

    atomes, sans_insee = {}, 0
    with open(os.path.join(out, "atom.csv"), newline="", encoding="utf-8") as fh:
        for r in csv.DictReader(fh):
            code = (r.get("insee") or "").strip()
            if not code:
                sans_insee += 1
            else:
                atomes[r["atom_id"]] = code

    references = set(atomes.values())
    orphelins = references - polygones
    inutilises = polygones - references
    touchés = [a for a, c in atomes.items() if c in orphelins]

    print(f"polygones GEOFLA            : {len(polygones)}")
    print(f"atomes                      : {len(atomes) + sans_insee}")
    print(f"  sans code INSEE           : {sans_insee}")
    print(f"codes INSEE référencés      : {len(references)}")
    print(f"  appariés                  : {len(references) - len(orphelins)}")
    print(f"  sans polygone             : {len(orphelins)}"
          + ("   <- atomes non cartographiables" if orphelins else ""))
    print(f"polygones jamais référencés : {len(inutilises)}")
    if orphelins:
        chemin = os.path.join(out, "atomes_sans_polygone.csv")
        with open(chemin, "w", newline="", encoding="utf-8") as fh:
            w = csv.writer(fh)
            w.writerow(["atom_id", "insee"])
            for a in sorted(touchés):
                w.writerow([a, atomes[a]])
        print(f"\nListe écrite dans {chemin}")
        print(f"{len(touchés)} atomes concernés. Premiers codes absents :")
        for c in sorted(orphelins)[:10]:
            print(f"    {c}")
    if inutilises:
        print("\nPremiers polygones inutilisés :")
        for c in sorted(inutilises)[:10]:
            print(f"    {c}")
    print("\nUn polygone inutilisé est une commune actuelle dont aucune",
          file=sys.stderr)
    print("commune historique ne relève : création postérieure à 1940.",
          file=sys.stderr)
    print("Un code sans polygone est plus grave : l'atome ne pourra pas",
          file=sys.stderr)
    print("être dessiné et doit être recensé avant chargement.",
          file=sys.stderr)


def cmd_codes(root, annees_voulues=None):
    """Mesure la largeur réelle de chaque code, pour fixer les règles de
    zéro-padding avant jointure avec les shapefiles (où ils sont numériques)."""
    from collections import Counter

    colonnes = ["cassini", "insee", "dep", "depar", "deppct", "pct",
                "deppcirco", "pcirco", "cl"]
    fichiers = annees(root)
    if annees_voulues:
        garder = {int(a) for a in annees_voulues.split(",")}
        fichiers = [(a, p) for a, p in fichiers if a in garder]

    largeurs = {c: Counter() for c in colonnes}
    zeros = {c: 0 for c in colonnes}
    non_num = {c: set() for c in colonnes}
    for _, path in fichiers:
        for row in lire(path):
            for c in colonnes:
                v = (row.get(c) or "").strip()
                if not v:
                    continue
                largeurs[c][len(v)] += 1
                if v[0] == "0":
                    zeros[c] += 1
                if not v.isdigit() and len(non_num[c]) < 5:
                    non_num[c].add(v)

    print(f"{'colonne':<12} {'largeurs':<22} {'commence par 0':>15} "
          f"{'padding':>9}  exemples non numériques")
    for c in colonnes:
        if not largeurs[c]:
            print(f"{c:<12} {'(absente)':<22}")
            continue
        détail = ", ".join(f"{l}:{n}" for l, n in sorted(largeurs[c].items()))
        fixe = len(largeurs[c]) == 1
        # Une largeur unique avec des zéros initiaux se reconstitue par zfill.
        # Une largeur variable sans zéro initial signifie un code non padé :
        # le zfill serait alors une invention.
        if fixe and zeros[c]:
            verdict = f"zfill({max(largeurs[c])})"
        elif fixe:
            verdict = "aucun"
        elif not zeros[c]:
            # Largeur variable sans zéro initial : numérotation séquentielle,
            # à comparer comme entier et non comme chaîne.
            verdict = "entier"
        else:
            verdict = "INDEVINABLE"
        ex = ", ".join(sorted(non_num[c])[:3])
        print(f"{c:<12} {détail:<22} {zeros[c]:>15} {verdict:>9}  {ex}")

    print("\nzfill(n) : largeur fixe avec zéros initiaux, restituable depuis",
          file=sys.stderr)
    print("l'entier du shapefile. entier : numérotation séquentielle, à",
          file=sys.stderr)
    print("joindre en comparant des entiers. INDEVINABLE : largeur variable",
          file=sys.stderr)
    print("ET zéros initiaux, le padding est perdu.", file=sys.stderr)
    print("Attention : une colonne non numérique (2A001) ne se reconstitue",
          file=sys.stderr)
    print("d'aucune façon depuis un champ numérique.", file=sys.stderr)


def cmd_pseudo(root_com, root_map, annees_voulues=None):
    """Vérifie le procédé des pseudo-cantons : un pseudo-canton de type 6
    rassemble les communes partagées entre les cantons réels qu'il recouvre
    — une seule le plus souvent, deux dans le cas de Roubaix et Wattrelos."""
    from collections import Counter

    maps = {}
    for dirpath, _, filenames in os.walk(root_map):
        for fn in filenames:
            m = MAPPING_RE.search(fn)
            if m:
                maps[int(m.group(1))] = os.path.join(dirpath, fn)

    fichiers = annees(root_com)
    if annees_voulues:
        garder = {int(a) for a in annees_voulues.split(",")}
        fichiers = [(a, p) for a, p in fichiers if a in garder]

    print(f"{'année':>6} {'type 6':>7} {'1 commune':>10} {'>1 commune':>11} "
          f"{'max':>4} {'mapping':>8} {'écart':>6} {'ct réels':>9}")
    for an, path in fichiers:
        membres = defaultdict(set)
        types = {}
        lignes_an = list(lire(path))
        if any((r.get("insee") or "").startswith(PREFIXE_ARR_PARIS)
               for r in lignes_an):
            lignes_an = [r for r in lignes_an
                         if (r.get("insee") or "") != DOUBLON_PARIS]
        for row in lignes_an:
            uid = row.get("deppct")
            if not uid:
                continue
            membres[uid].add(row.get(CLE))
            types.setdefault(uid, entier(row.get("pct_type")))

        type6 = {u for u, t in types.items() if t == 6}
        tailles = Counter(len(membres[u]) for u in type6)
        seuls = tailles.get(1, 0)
        plusieurs = sum(n for t, n in tailles.items() if t > 1)
        maxi = max(tailles) if tailles else 0

        m_pseudo, m_reels = set(), set()
        if an in maps:
            for r in lire_mapping(maps[an]):
                if r.get("deppct"):
                    m_pseudo.add(r["deppct"])
                if r.get("depct"):
                    m_reels.add(r["depct"])
        ecart = len(type6 ^ m_pseudo)

        print(f"{an:>6} {len(type6):>7} {seuls:>10} {plusieurs:>11} "
              f"{maxi:>4} {len(m_pseudo):>8} {ecart:>6} {len(m_reels):>9}")

        for u in sorted(u for u in type6 if len(membres[u]) > 1):
            coms = ", ".join(sorted(membres[u]))
            print(f"       type 6 à {len(membres[u])} communes : {u} -> {coms}",
                  file=sys.stderr)
        for u in sorted(type6 - m_pseudo)[:3]:
            print(f"       type 6 hors mapping : {u} "
                  f"({len(membres[u])} commune(s))", file=sys.stderr)
        for u in sorted(m_pseudo - type6)[:3]:
            print(f"       mapping hors type 6 : {u}", file=sys.stderr)

    print("\nUn 'écart' nul signifie que le mapping couvre tous les",
          file=sys.stderr)
    print("pseudo-cantons de type 6. La colonne '>1 commune' recense ceux qui",
          file=sys.stderr)
    print("regroupent plusieurs communes partagées : ce n'est pas une",
          file=sys.stderr)
    print("anomalie, chacune donnant lieu à ses propres atomes fraction.",
          file=sys.stderr)


def cmd_dump(root, an, dep, cols, motif=""):
    """Affiche les lignes brutes d'un département pour une année donnée."""
    fichiers = dict(annees(root))
    if an not in fichiers:
        sys.exit(f"Année {an} absente de {root!r}.")
    champs = [c.strip() for c in cols.split(",")]
    n = 0
    print("\t".join(champs))
    for row in lire(fichiers[an]):
        if dep and row.get("dep") != dep:
            continue
        vals = [(row.get(c) or "").strip() for c in champs]
        if motif and not any(motif in v for v in vals):
            continue
        print("\t".join(vals))
        n += 1
    print(f"\n{n} lignes.", file=sys.stderr)


def cmd_noms(root, annees_voulues=None):
    """Vérifie que le champ nom porte l'attribution aux unités réelles,
    le séparateur ' / ' marquant les communes fractionnées."""
    fichiers = annees(root)
    if annees_voulues:
        garder = {int(a) for a in annees_voulues.split(",")}
        fichiers = [(a, p) for a, p in fichiers if a in garder]
    if not fichiers:
        sys.exit("Aucune année à traiter.")

    for niv, (col_id, col_nom, col_type) in NIVEAUX.items():
        print(f"\n=== {niv} ===")
        print(f"{'année':>6} {'communes':>9} {'multiples':>10} {'flag type':>10} "
              f"{'concordance':>12} {'unités réelles':>15}")
        for an, path in fichiers:
            n = multi = flag = accord = 0
            reels = set()
            exemples = []
            for row in lire(path):
                nom = (row.get(col_nom) or "").strip()
                if not nom:
                    continue
                n += 1
                dep = (row.get("dep") or "")
                parts = [p.strip() for p in nom.split(SEP_MULTI)]
                for p in parts:
                    reels.add((dep, p))
                est_multi = len(parts) > 1
                t = entier(row.get(col_type))
                # circo : pcirco_type 1 = multiple. canton : pct_type 2 a 5.
                est_flag = (t == 1) if niv == "circo" else (t in PCT_FRACTION)
                multi += est_multi
                flag += est_flag
                accord += (est_multi == est_flag)
                if est_multi and len(exemples) < 2:
                    exemples.append(f"{row.get(CLE)} {nom}")
            pct = 100 * accord / n if n else 0
            print(f"{an:>6} {n:>9} {multi:>10} {flag:>10} {pct:>11.1f} % "
                  f"{len(reels):>15}")
            for e in exemples:
                print(f"       {e}", file=sys.stderr)

    print("\nSi 'multiples' et 'flag type' coincident, le champ nom porte bien",
          file=sys.stderr)
    print("l'attribution reelle et le separateur marque les fractions : les",
          file=sys.stderr)
    print("unites reelles se lisent alors directement, sans fichier de mapping.",
          file=sys.stderr)
    print("Attention : pour le canton, pct_type qualifie le pseudo-canton et",
          file=sys.stderr)
    print("non la commune, donc une discordance y est attendue.", file=sys.stderr)


def cmd_renames(out):
    """Distingue les renumérotations (les noms circulent entre codes d'un
    même département) des véritables renommages."""
    from collections import Counter, defaultdict

    path = os.path.join(out, "unit_renames.csv")
    if not os.path.exists(path):
        sys.exit(f"{path} introuvable : lancer build d'abord.")

    groupes = defaultdict(list)
    with open(path, newline="", encoding="utf-8") as fh:
        for r in csv.DictReader(fh):
            uid = r["unit_id"]
            # Les identifiants de circonscription portent un préfixe de régime.
            dep = uid[1:3] if r["niveau"] == "circo" else uid[:2]
            groupes[(r["niveau"], int(r["annee"]), dep)].append(
                (uid, r["nom_avant"], r["nom_apres"]))

    stats = defaultdict(lambda: {"total": 0, "permut": 0, "vrais": 0,
                                 "exemples": []})
    for (niv, an, dep), lignes in sorted(groupes.items()):
        avant = Counter(a for _, a, _ in lignes)
        apres = Counter(b for _, _, b in lignes)
        circulants = avant & apres          # intersection de multiensembles
        n_circ = sum(circulants.values())
        s = stats[niv]
        s["total"] += len(lignes)
        s["permut"] += n_circ
        s["vrais"] += len(lignes) - n_circ
        if n_circ >= 3 and len(s["exemples"]) < 3:
            détail = "; ".join(f"{u}: {a} -> {b}" for u, a, b in lignes[:4])
            s["exemples"].append(f"{an} dép. {dep} ({n_circ} circulants) {détail}")

    for niv, s in stats.items():
        t = s["total"]
        print(f"\n{niv} : {t} changements de nom")
        print(f"    renumérotations : {s['permut']:>6}  "
              f"({100 * s['permut'] / t:.0f} %)")
        print(f"    vrais renommages: {s['vrais']:>6}  "
              f"({100 * s['vrais'] / t:.0f} %)")
        for e in s["exemples"]:
            print(f"        {e}")

    print("\nUn taux élevé de renumérotation invalide l'identité par code :",
          file=sys.stderr)
    print("l'unité doit alors être identifiée par (département, nom, régime),",
          file=sys.stderr)
    print("le code n'étant qu'un rang de tri variable d'une année à l'autre.",
          file=sys.stderr)


def cmd_verify(out):
    """Contrôles sur les sorties de build, avant tout chargement en base."""
    from collections import Counter, defaultdict

    for niv in NIVEAUX:
        path = os.path.join(out, f"membership_{niv}.csv")
        if not os.path.exists(path):
            continue
        par_commune = defaultdict(list)
        with open(path, newline="", encoding="utf-8") as fh:
            for r in csv.DictReader(fh):
                # La clé est l'atome : une commune fractionnée relève
                # simultanément de plusieurs unités sans qu'il y ait conflit.
                cle = r.get("atom_id") or r["insee"]
                par_commune[cle].append(
                    (r["valid_from"], r["valid_to"], r["unit_id"]))

        chevauchements = trous = 0
        ex_chev, ex_trou = [], []
        for insee, ivs in par_commune.items():
            ivs.sort()
            for (d1, f1, u1), (d2, f2, u2) in zip(ivs, ivs[1:]):
                if d2 < f1:
                    chevauchements += 1
                    if len(ex_chev) < 3:
                        ex_chev.append(f"{insee} {u1}[{d1},{f1}) / {u2}[{d2},{f2})")
                elif d2 > f1:
                    trous += 1
                    if len(ex_trou) < 3:
                        ex_trou.append(f"{insee} {f1} -> {d2}")

        print(f"\n{niv} : {len(par_commune)} atomes, "
              f"{sum(len(v) for v in par_commune.values())} intervalles")
        print(f"    chevauchements : {chevauchements}"
              + ("  <- EXCLUDE refusera le chargement" if chevauchements else ""))
        for e in ex_chev:
            print(f"        {e}")
        print(f"    trous          : {trous}"
              + ("  (communes disparues puis rétablies)" if trous else ""))
        for e in ex_trou:
            print(f"        {e}")

    path = os.path.join(out, "unit_renames.csv")
    if os.path.exists(path):
        par_an = defaultdict(Counter)
        with open(path, newline="", encoding="utf-8") as fh:
            for r in csv.DictReader(fh):
                par_an[r["niveau"]][int(r["annee"])] += 1
        for niv, cnt in par_an.items():
            total = sum(cnt.values())
            print(f"\nrenommages {niv} : {total}")
            print("    années les plus chargées :")
            for an, n in cnt.most_common(8):
                part = 100 * n / total
                print(f"        {an}  {n:>5}  ({part:.0f} % du total)")
            print("    Une concentration sur une année de découpage signale",
                  "\n    une renumérotation, pas un renommage : l'identité de",
                  "\n    l'unité doit alors être coupée à cette date.")


def charger_mappings(root_map):
    """année -> {pseudo-canton: [cantons réels]}"""
    out = {}
    if not root_map:
        return out
    for dirpath, _, filenames in os.walk(root_map):
        for fn in filenames:
            m = MAPPING_RE.search(fn)
            if not m:
                continue
            table = defaultdict(list)
            for r in lire_mapping(os.path.join(dirpath, fn)):
                if r.get("deppct") and r.get("depct"):
                    nom = (r.get("ct_name_prop") or r.get("ct_name")
                           or "").strip()
                    table[r["deppct"]].append((r["depct"], nom))
            out[int(m.group(1))] = dict(table)
    return out


def cmd_build(root, out, root_map=None):
    fichiers = annees(root)
    if not fichiers:
        sys.exit(f"Aucun COG_COMMUNES_YYYY.txt sous {root!r}.")
    os.makedirs(out, exist_ok=True)
    mappings = charger_mappings(root_map)

    an_max = max(a for a, _ in fichiers)

    courant = {niv: {} for niv in NIVEAUX}
    noms = {niv: {} for niv in NIVEAUX}
    renames = []
    fractions = []
    regimes = []
    ambigus = []
    atomes = {}             # atom_id -> (cassini, fraction ?)
    geom_de = {}            # cassini -> code INSEE porteur de la géométrie
    multi_communes = []     # pseudo-cantons de type 6 à plusieurs communes
    doublons_ecartes = {}   # année -> nombre de lignes Paris écartées
    segment = {}            # (régime, département) -> année d'ouverture
    noms_circo_prec = {}    # code brut -> nom dominant de l'année précédente

    fh_memb = {
        niv: open(os.path.join(out, f"membership_{niv}.csv"), "w",
                  newline="", encoding="utf-8")
        for niv in NIVEAUX
    }
    wr_memb = {}
    for niv, fh in fh_memb.items():
        w = csv.writer(fh)
        w.writerow(["atom_id", "cassini", "insee", "unit_id",
                    "valid_from", "valid_to"])
        wr_memb[niv] = w

    def cloture(niv, cassini, cibles, debut, an_fin):
        insee = geom_de.get(cassini, "")
        for atom_id, unit_id in cibles:
            wr_memb[niv].writerow([atom_id, cassini, insee, unit_id,
                                   f"{debut}-01-01", f"{an_fin}-01-01"])

    for an, path in fichiers:
        # Une année tient en mémoire (~38 000 lignes) : on la lit une fois,
        # on en déduit le régime électoral, puis on traite.
        lignes = []
        deps, circos = set(), set()
        for row in lire(path):
            insee = row.get(CLE)
            if not insee:
                continue
            if row.get("dep"):
                deps.add(row["dep"])
            if row.get("deppcirco"):
                circos.add(row["deppcirco"])
            lignes.append(row)

        # Sous le scrutin de liste, la circonscription est le département
        # (parfois subdivisé pour les plus peuplés) : le rapport reste
        # proche de 1. Sous le scrutin uninominal il dépasse largement 2.
        ratio = len(circos) / max(len(deps), 1)
        regime = "liste" if ratio < 2 else "uninominal"
        regimes.append([an, len(deps), len(circos), round(ratio, 2), regime])
        mapping_an = mappings.get(an, {})
        if mapping_an:
            occupants = defaultdict(set)
            for row in lignes:
                if row.get("deppct") in mapping_an:
                    occupants[row["deppct"]].add(row[CLE])
            for code, coms in occupants.items():
                if len(coms) > 1:
                    multi_communes.append([an, code, ";".join(sorted(coms))])
        prefixe = "L" if regime == "liste" else "U"

        vus = {niv: set() for niv in NIVEAUX}
        # Le libellé varie d'une commune à l'autre au sein d'une même unité :
        # les communes dont le rattachement n'est pas déterminable portent la
        # liste des circonscriptions voisines ("Nantes-1 / Nantes-2"). On
        # retient le nom dominant hors libellés composés, et on met les
        # ambiguïtés de côté.
        noms_an = {niv: defaultdict(Counter) for niv in NIVEAUX}

        # Écarter le doublon Paris si les arrondissements sont présents.
        if any((r.get("insee") or "").startswith(PREFIXE_ARR_PARIS)
               for r in lignes):
            avant = len(lignes)
            lignes = [r for r in lignes
                      if (r.get("insee") or "") != DOUBLON_PARIS]
            doublons_ecartes[an] = avant - len(lignes)

        # --- passe A : libellés ------------------------------------------
        for row in lignes:
            if row.get(CLE_GEOM):
                geom_de[row[CLE]] = row[CLE_GEOM]
            insee = row[CLE]
            for niv, (col_id, col_nom, _) in NIVEAUX.items():
                code = row.get(col_id)
                if not code:
                    continue
                nom = (row.get(col_nom) or "").strip()
                if SEP_MULTI in nom:
                    ambigus.append([niv, insee, an, code, nom])
                elif nom:
                    noms_an[niv][code][nom] += 1

        dominant = {niv: {c: cnt.most_common(1)[0][0]
                          for c, cnt in noms_an[niv].items()}
                    for niv in NIVEAUX}

        # --- segmentation des circonscriptions ---------------------------
        # `deppcirco` est un rang de tri dans le département : quand une
        # circonscription est créée ou supprimée, tout le rang décale et les
        # codes changent de titulaire. On ouvre alors un nouveau segment
        # d'identité, mais seulement dans le département concerné.
        # La comparaison se fait à régime constant : au passage au scrutin de
        # liste, les codes départementaux changeraient de nom mécaniquement,
        # ce qui n'est pas une renumérotation. Le préfixe L/U sépare déjà ces
        # unités, on compare donc chaque régime à sa propre année précédente.
        for code, nom in dominant["circo"].items():
            dep, cle = code[:2], (prefixe, code)
            if nom != noms_circo_prec.get(cle):
                if cle in noms_circo_prec:
                    renames.append(["circo", f"{prefixe}{code}"
                                    f"@{segment.get((prefixe, dep), an)}",
                                    an, noms_circo_prec[cle], nom])
                    segment[(prefixe, dep)] = an
                else:
                    segment.setdefault((prefixe, dep), an)
        for code, nom in dominant["circo"].items():
            noms_circo_prec[(prefixe, code)] = nom

        def uid_de(niv, code):
            if niv != "circo":
                return code
            seg = segment.get((prefixe, code[:2]), an)
            return f"{prefixe}{code}@{seg}"

        for code, reels in mapping_an.items():
            for rc, nom_reel in reels:
                # Le libellé de la nomenclature communale fait foi quand il
                # existe ; celui du mapping ne sert que pour les cantons
                # entièrement composés de fractions, absents des communes.
                if nom_reel and rc not in dominant["canton"]:
                    noms["canton"].setdefault(rc, nom_reel)
            dominant["canton"].pop(code, None)   # le pseudo-canton s'efface

        for niv in NIVEAUX:
            for code, nom in dominant[niv].items():
                uid = uid_de(niv, code)
                anc = noms[niv].get(uid)
                if anc is None:
                    noms[niv][uid] = nom
                elif nom != anc:
                    if niv != "circo":
                        renames.append([niv, uid, an, anc, nom])
                    noms[niv][uid] = nom

        # --- passe B : rattachements -------------------------------------
        for row in lignes:
            insee = row[CLE]
            t = entier(row.get("pct_type"))
            if t in PCT_FRACTION:
                fractions.append([insee, an, t, row.get("deppct", ""),
                                  row.get("pct_name_prop", "")])

            for niv, (col_id, _, _) in NIVEAUX.items():
                code = row.get(col_id)
                if not code:
                    continue
                vus[niv].add(insee)

                # Un pseudo-canton du mapping recouvre plusieurs cantons
                # réels : la commune y est fractionnée, donc représentée par
                # autant d'atomes, chacun sans géométrie propre.
                reels = mapping_an.get(code) if niv == "canton" else None
                if reels:
                    cibles = tuple(sorted((f"{insee}#{rc}", rc)
                                          for rc, _ in reels))
                    for atom_id, _ in cibles:
                        atomes[atom_id] = (insee, True)
                else:
                    cibles = ((insee, uid_de(niv, code)),)
                    atomes.setdefault(insee, (insee, False))

                etat = courant[niv].get(insee)
                if etat is None:
                    courant[niv][insee] = (cibles, an)
                elif etat[0] != cibles:
                    cloture(niv, insee, etat[0], etat[1], an)
                    courant[niv][insee] = (cibles, an)

        for niv in NIVEAUX:
            for insee in [c for c in courant[niv] if c not in vus[niv]]:
                cibles, debut = courant[niv].pop(insee)
                cloture(niv, insee, cibles, debut, an)

    for niv in NIVEAUX:
        for insee, (cibles, debut) in courant[niv].items():
            cloture(niv, insee, cibles, debut, an_max + 1)
        fh_memb[niv].close()

    for niv in NIVEAUX:
        with open(os.path.join(out, f"unit_{niv}.csv"), "w", newline="",
                  encoding="utf-8") as fh:
            w = csv.writer(fh)
            if niv == "circo":
                w.writerow(["unit_id", "regime", "dep", "code",
                            "segment_depuis", "nom"])
                for uid, nom in sorted(noms[niv].items()):
                    reg = "liste" if uid[0] == "L" else "uninominal"
                    code, seg = uid[1:].split("@")
                    w.writerow([uid, reg, code[:2], code, seg, nom])
            else:
                w.writerow(["unit_id", "dep", "nom"])
                for uid, nom in sorted(noms[niv].items()):
                    w.writerow([uid, uid[:2], nom])

    with open(os.path.join(out, "atom.csv"), "w", newline="",
              encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["atom_id", "cassini", "insee", "fraction"])
        for atom_id, (cassini, frac) in sorted(atomes.items()):
            w.writerow([atom_id, cassini, geom_de.get(cassini, ""),
                        "true" if frac else "false"])

    with open(os.path.join(out, "pseudo_multi_communes.csv"), "w", newline="",
              encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["annee", "deppct", "communes"])
        w.writerows(multi_communes)

    with open(os.path.join(out, "circo_regime.csv"), "w", newline="",
              encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["annee", "n_dep", "n_circo", "ratio", "regime"])
        w.writerows(regimes)

    with open(os.path.join(out, "unit_renames.csv"), "w", newline="",
              encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["niveau", "unit_id", "annee", "nom_avant", "nom_apres"])
        w.writerows(renames)

    with open(os.path.join(out, "attribution_ambigue.csv"), "w", newline="",
              encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["niveau", "insee", "annee", "unit_id", "libelle"])
        w.writerows(ambigus)

    with open(os.path.join(out, "communes_fractionnees.csv"), "w", newline="",
              encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["insee", "annee", "pct_type", "deppct", "pct_name"])
        w.writerows(fractions)

    print(f"Années traitées : {fichiers[0][0]}-{an_max} "
          f"({len(fichiers)} fichiers)", file=sys.stderr)
    for niv in NIVEAUX:
        n = sum(1 for _ in open(os.path.join(out, f"membership_{niv}.csv"),
                                encoding="utf-8")) - 1
        print(f"  {niv:<7} {len(noms[niv]):>6} unités, {n:>8} intervalles",
              file=sys.stderr)
    n_liste = sum(1 for r in regimes if r[4] == "liste")
    print(f"  {n_liste} années au scrutin de liste, "
          f"{len(regimes) - n_liste} au scrutin uninominal", file=sys.stderr)
    if doublons_ecartes:
        print(f"  doublon Paris {DOUBLON_PARIS} écarté sur "
              f"{len(doublons_ecartes)} années", file=sys.stderr)
    n_frac = sum(1 for _, f in atomes.values() if f)
    print(f"  {len(atomes)} atomes dont {n_frac} fractions", file=sys.stderr)
    if multi_communes:
        print(f"  {len(multi_communes)} pseudo-cantons à plusieurs communes "
              f"(voir pseudo_multi_communes.csv)", file=sys.stderr)
    print(f"  {len(ambigus)} lignes commune-année à attribution ambiguë",
          file=sys.stderr)
    print(f"  {len(renames)} changements de nom, "
          f"{len(fractions)} lignes commune-année fractionnées", file=sys.stderr)
    print(f"\nSorties dans {out}/", file=sys.stderr)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("check", help="effectifs par année")
    p.add_argument("root")

    p = sub.add_parser("cantons", help="pseudo-cantons vers cantons réels")
    p.add_argument("root_communes")
    p.add_argument("root_mapping")

    p = sub.add_parser("geofla", help="appariement des atomes et des polygones")
    p.add_argument("out", nargs="?", default="./build")
    p.add_argument("--dbf", required=True, help="chemin de COMMUNE.DBF")
    p.add_argument("--colonne", default="INSEE_COM")

    p = sub.add_parser("codes", help="largeurs des codes et zéro-padding")
    p.add_argument("root")
    p.add_argument("--years", default="")

    p = sub.add_parser("pseudo", help="procédé des pseudo-cantons")
    p.add_argument("root_communes")
    p.add_argument("root_mapping")
    p.add_argument("--years", default="")

    p = sub.add_parser("dump", help="lignes brutes d'un département")
    p.add_argument("root")
    p.add_argument("--year", type=int, required=True)
    p.add_argument("--dep", default="")
    p.add_argument("--grep", default="", help="ne garder que les lignes contenant ce motif")
    p.add_argument("--cols",
                   default="insee,com_name_prop,deppcirco,pcirco_name_prop,"
                           "pcirco_type,deppct,pct_name_prop,pct_type")

    p = sub.add_parser("noms", help="structure des noms multiples")
    p.add_argument("root")
    p.add_argument("--years", default="")

    p = sub.add_parser("renames", help="renumérotation ou vrai renommage ?")
    p.add_argument("out", nargs="?", default="./build")

    p = sub.add_parser("verify", help="contrôles sur les sorties de build")
    p.add_argument("out", nargs="?", default="./build")

    p = sub.add_parser("build", help="compaction en intervalles")
    p.add_argument("root")
    p.add_argument("--out", default="./build")
    p.add_argument("--mapping", default="",
                   help="répertoire des COG_CANTONS_YYYY_MAPPING")
    p.add_argument("--geom-col", default=CLE_GEOM, dest="geom_col",
                   help="colonne de rattachement à la trame GEOFLA")

    a = ap.parse_args()

    # `... | head` ferme le tuyau : on rétablit la sémantique shell.
    try:
        signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    except (AttributeError, ValueError):
        pass

    if a.cmd == "check":
        cmd_check(a.root)
    elif a.cmd == "geofla":
        cmd_geofla(a.out, a.dbf, a.colonne)
    elif a.cmd == "codes":
        cmd_codes(a.root, a.years or None)
    elif a.cmd == "pseudo":
        cmd_pseudo(a.root_communes, a.root_mapping, a.years or None)
    elif a.cmd == "dump":
        cmd_dump(a.root, a.year, a.dep, a.cols, a.grep)
    elif a.cmd == "noms":
        cmd_noms(a.root, a.years or None)
    elif a.cmd == "renames":
        cmd_renames(a.out)
    elif a.cmd == "verify":
        cmd_verify(a.out)
    elif a.cmd == "cantons":
        cmd_cantons(a.root_communes, a.root_mapping)
    else:
        globals()["CLE_GEOM"] = a.geom_col
        cmd_build(a.root, a.out, a.mapping or None)


if __name__ == "__main__":
    main()
