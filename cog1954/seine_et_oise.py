#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
seine_et_oise.py — récupérer les 576 lignes que le code `78O` avait perdues

    python3 cog1954/seine_et_oise.py              # à blanc
    python3 cog1954/seine_et_oise.py --appliquer

LE DÉFAUT, ET POURQUOI IL ÉTAIT SILENCIEUX
===========================================
`apparie_noms.py` cherche le nom **dans le département lu** :

    if not nom or dep not in ref:
        propositions.append((r, None, "aucun"))

La Seine-et-Oise porte dans le volume un code de TROIS caractères, `78O`. Aucun
référentiel ne le connaît — les communes du département portent aujourd'hui des
codes en 78, 91, 92, 93, 94 ou 95, le département ayant été éclaté en 1968. La
branche ci-dessus a donc classé ses **576 lignes en `aucun` sans même essayer**.

C'est **un tiers des 1 627 lignes sans piste** de tout le dépouillement, perdu
d'un seul tenant et sans un message d'erreur.

*Un code qui ne correspond à rien ne produit pas d'erreur, il produit un vide.*

LE PIÈGE : LE CODE DE 1954 N'EST PAS LE CODE D'AUJOURD'HUI
===========================================================
La première version de ce script appariait vers les codes MODERNES et en
trouvait 549 sur 576. **Aucun n'aurait produit de rattachement** :

    codes 78xxx vivants au 10 mai 1954 ......... 691
    codes 91, 92, 93, 94, 95 vivants en 1954 ..... 0

`cm_commune` modélise correctement l'éclatement de 1968 : en 1954 les communes
de Seine-et-Oise portent la numérotation d'époque. `c54_lien` aurait posé
`commune_vivante = false` sur les 549 lignes, et `68` n'aurait rien écrit.

Le vivier tiré de `build/membership_canton.csv` compte lui aussi 691 communes,
mais **TRF-GIS les code en moderne** quand `cm_commune` les code en 1954.
*Deux ensembles de même effectif décrits par deux numérotations différentes :
j'ai pris la coïncidence des comptes pour une identité des clés.*

LE PONT : L'ATOME
=================
`sql/69_pont_seine_et_oise.sql` produit
`cog1954/pont_departements_disparus.csv` — `code_1954 → atom_id → code_moderne`.
L'atome ne change pas quand l'INSEE renumérote ; c'est la raison d'être du
modèle, et la traduction ne suppose rien.

Elle règle en outre un problème qui n'a pas d'autre issue : sur les 691 codes
de 1954, **seuls 454 portent un nom** dans `noms_1954.csv`. Les 237 autres ne
sont jamais nommés par les mouvements INSEE — mais leur code moderne, lui, a un
nom dans la trame de 2011.

**La cible de l'appariement est donc le code de 1954**, atteint par tous les
noms connus de la commune : son nom d'époque quand il existe, celui de sa
descendance moderne sinon.

LE SECOND SIGNAL EXISTE AUSSI, ET IL EST MEILLEUR QU'AILLEURS
==============================================================
La même source donne le CANTON de 1940 de chaque commune du vivier. Le volume
de 1954 porte un numéro de canton sur chaque ligne. Les deux se comparent —
c'est le dispositif de `confirme_par_canton.py`, sans changement.

**Et il se contrôle gratuitement** : on peut l'appliquer aux appariements
EXACTS, dont on n'a pas besoin. S'il les confirme massivement, il est fiable
quand il tranche les flous. Mesuré : **450 accords sur 459 exacts jugeables**.
Un test qu'on ne peut pas vérifier ne vaut rien ; celui-ci se vérifie.

LA COLLISION ENTRE PASSES — le défaut corrigé ici
==================================================
`apparie_noms.py` juge l'unicité **parmi ses seuls appariements exacts**, et
`confirme_par_canton.py` pose ensuite les flous sans regarder si leur cible est
déjà prise. C'est ce qui a donné à `Magny-lès-Auxonne` le code de
`Flagey-lès-Auxonne` (cf. `68` § 3 bis).

Ici l'unicité est jugée **sur l'ensemble des propositions, exactes et floues
confondues**, et un flou qui vise une commune déjà atteinte en exact perd —
l'exact est le plus sûr des deux. Sans cela, `Mandres` (arr. 1, canton 4)
recevrait le code d'`Andrésy` (canton 31), déjà lu par ailleurs.

CE QUI EST ÉCRIT, ET CE QUI NE L'EST PAS
=========================================
    ferme             exact, unique — posé
    ferme_canton      flou, unique, CONFIRMÉ par le canton — posé
    canton_contredit  flou dont le canton dément — non posé
    flou_collision    flou visant une commune déjà prise — non posé
    aucun             rien trouvé

Réversible : sauvegarde `.avant_seine_et_oise` avant toute écriture.
"""

import argparse
import collections
import csv
import difflib
import shutil
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RACINE / "cog1954"))
from normalise_nom import variantes, cle                     # noqa: E402

LU = RACINE / "cog1954" / "communes_1954_redecoupe.csv"
MEMB = RACINE / "build" / "membership_canton.csv"
NOMS = RACINE / "build" / "noms_geofla.csv"
N1954 = RACINE / "cog1954" / "noms_1954.csv"
PONT = RACINE / "cog1954" / "pont_departements_disparus.csv"

# Les deux départements disparus, et le préfixe de leurs cantons dans la base.
# `78O` est le code tel que le VOLUME l'imprime ; `78` celui de la base.
DEPS = {"78O": "78", "75": "75"}

DATE_1940 = "1940-06-01"
SEUIL_FLOU = 0.85

# Le vivier est CLOS et petit (691 communes) : une correspondance exacte de
# trois lettres y est sûre, là où elle serait risquée sur 36 000 communes.
# `variantes()` filtre à 4 par défaut, ce qui perdait « Buc ».
MINI_EXACT = 3


def pont():
    """{dep_1954 -> {code_1954 -> {codes modernes}}}, depuis `69`."""
    if not PONT.exists():
        sys.exit(f"{PONT} absent — jouer d'abord :\n"
                 f"   psql -d histgis -f sql/69_pont_seine_et_oise.sql")
    d = collections.defaultdict(lambda: collections.defaultdict(set))
    for r in csv.DictReader(PONT.open(encoding="utf-8")):
        d[r["dep_1954"]][r["code_1954"]].add(r["code_moderne"] or None)
    return d


def cantons_1940(modernes):
    """{code moderne -> {unit_id de canton}} au 1er juin 1940.

    TRF-GIS code les communes en MODERNE, y compris pour la Seine-et-Oise de
    1940 — d'où le passage par le pont pour retrouver le canton d'un code de
    1954.
    """
    if not MEMB.exists():
        sys.exit(f"{MEMB} absent.")
    d = collections.defaultdict(set)
    for r in csv.DictReader(MEMB.open(encoding="utf-8")):
        if r["valid_from"] <= DATE_1940 < r["valid_to"] and r["insee"] in modernes:
            d[r["insee"]].add(r["unit_id"])
    return d


def noms_du_vivier(vivier_1954):
    """{clé du nom -> [code_1954]} et {code_1954 -> libellé lisible}.

    Deux sources de noms, et il faut les DEUX :
      * `noms_1954.csv` donne le nom d'ÉPOQUE, sous le code de 1954 — c'est lui
        qui rattrape « Évry-Petit-Bourg », « Tremblay-lès-Gonesse »,
        « Auteuil-le-Roi », qu'aucune normalisation ne tirerait des noms
        d'aujourd'hui ;
      * `noms_geofla.csv` donne le nom MODERNE, sous le code moderne — c'est lui
        qui couvre les 237 communes que les mouvements INSEE ne nomment jamais.
    """
    par_cle = collections.defaultdict(list)
    libelle = {}

    def pose(code_1954, nom):
        if not nom or not nom.strip():
            return
        k = cle(nom)
        if code_1954 not in par_cle[k]:
            par_cle[k].append(code_1954)
        libelle.setdefault(code_1954, nom)

    if N1954.exists():
        for r in csv.DictReader(N1954.open(encoding="utf-8")):
            if r["code"].strip() in vivier_1954:
                pose(r["code"].strip(), r["nom"])
    else:
        print("cog1954/noms_1954.csv absent — jouer sql/65_noms_1954.sql.\n")

    inverse = collections.defaultdict(set)
    for c54, modernes in vivier_1954.items():
        for m in modernes:
            if m:
                inverse[m].add(c54)
    for r in csv.DictReader(NOMS.open(encoding="utf-8")):
        for c54 in inverse.get(r["insee"].strip(), ()):
            pose(c54, r["nom"])

    return par_cle, libelle


def traite_departement(dep_lu, prefixe, lignes, vivier_1954, par_cle, libelle,
                       cantons):
    """Apparie les lignes d'un département disparu. Rend [(ligne, code, statut)].

    N'apparie QUE les lignes sans code : pour la Seine, 67 lignes sur 79 ont
    déjà été résolues par `apparie_noms.py` — les codes des arrondissements de
    Paris n'ont pas changé en 1968 — et les écraser serait une régression.
    """
    cibles = [r for r in lignes if r["dep"] == dep_lu and not r["insee"]]
    print(f"\n{'='*62}\n {dep_lu} — {len(cibles)} lignes sans code, "
          f"vivier de {len(vivier_1954)} communes en 1954\n{'='*62}")
    if not cibles:
        return []

    def canton_de(code_1954):
        """Les cantons de 1940, atteints par les codes MODERNES de la commune."""
        out = set()
        for m in vivier_1954.get(code_1954, ()):
            if m:
                out |= cantons.get(m, set())
        return out

    def canton_lu(r):
        ct = (r.get("canton") or "").strip()
        return prefixe + ct.zfill(2) if ct.isdigit() else None

    # ---- PREMIÈRE PASSE : proposer, sans rien décider ----------------------
    prop = []
    for r in cibles:
        vs = variantes((r.get("commune") or "").strip(), mini=MINI_EXACT)
        hit = next((par_cle[v][0] for v in vs
                    if v in par_cle and len(par_cle[v]) == 1), None)
        if hit:
            prop.append((r, hit, "exact"))
            continue
        if any(v in par_cle and len(par_cle[v]) > 1 for v in vs):
            prop.append((r, None, "homonyme"))     # le nom ne suffit pas
            continue
        trouve = None
        for v in vs:
            c = difflib.get_close_matches(v, par_cle.keys(), n=1,
                                          cutoff=SEUIL_FLOU)
            if c and len(par_cle[c[0]]) == 1:
                trouve = par_cle[c[0]][0]
                break
        prop.append((r, trouve, "flou" if trouve else "aucun"))

    # ---- SECONDE PASSE : l'unicité, TOUTES VOIES CONFONDUES ----------------
    #
    # C'est ici que se corrige le défaut de `Magny-lès-Auxonne` (cf. `68`
    # § 3 bis) : un flou qui vise une commune déjà atteinte par un EXACT perd.
    # L'exact est le plus sûr des deux, et deux lignes ne peuvent pas être la
    # même commune. Sans cela, `Mandres` prendrait le code d'`Andrésy`.
    pris_exact = collections.Counter(h for _, h, v in prop if h and v == "exact")
    pris_flou = collections.Counter(h for _, h, v in prop if h and v == "flou")

    decision = []
    for r, h, v in prop:
        if v == "exact":
            decision.append((r, h,
                             "ferme" if pris_exact[h] == 1 else "exact_collision"))
        elif v == "flou":
            decision.append((r, h, "flou_collision"
                             if (pris_exact[h] or pris_flou[h] > 1) else "flou"))
        else:
            decision.append((r, None, "aucun" if v == "aucun" else "homonyme"))

    # ---- LE CANTON, sur les flous ET sur les exacts ------------------------
    #
    # UN SIGNAL ABSENT N'EST PAS UN SIGNAL CONTRAIRE. Certaines communes du
    # vivier n'ont AUCUN canton en 1940 — TRF-GIS ne les couvre pas toutes. Le
    # premier jet traitait l'ensemble vide comme un désaccord et rejetait
    # « Thionville-sur-Opion » -> `Thionville-sur-Opton`, un appariement que
    # rien ne dément. C'est la distinction que `confirme_par_canton.py` faisait
    # déjà — « commune absente de 1940 » y est indéterminé, pas contredit.
    finale, ctrl, contredits = [], collections.Counter(), []
    for r, h, st in decision:
        att = canton_lu(r)
        connus = canton_de(h) if h else set()
        muet = att is None or not connus
        accord = not muet and att in connus
        if st == "ferme":
            ctrl["exact, canton d'accord" if accord
                 else ("exact, canton muet" if muet
                       else "exact, canton en désaccord")] += 1
            finale.append((r, h, "ferme"))
        elif st == "flou":
            if muet:
                ctrl["flou, canton muet"] += 1
                finale.append((r, None, "canton_indetermine"))
            elif accord:
                ctrl["flou CONFIRMÉ"] += 1
                finale.append((r, h, "ferme_canton"))
            else:
                ctrl["flou contredit"] += 1
                contredits.append((r, h, att))
                finale.append((r, None, "canton_contredit"))
        else:
            finale.append((r, None, st))

    # ---- Ce que cela donne --------------------------------------------------
    classes = collections.Counter(st for _, _, st in finale)
    poses = classes["ferme"] + classes["ferme_canton"]
    for k in ("ferme", "ferme_canton", "canton_contredit", "flou_collision",
              "exact_collision", "canton_indetermine", "homonyme", "aucun"):
        if classes[k]:
            print(f"   {k:<20} {classes[k]:>5}")
    print(f"\n   AVEC UN CODE         {poses:>5}   "
          f"{poses/len(cibles):.1%} des {len(cibles)} lignes")

    ok = ctrl["exact, canton d'accord"]
    jugeables = ok + ctrl["exact, canton en désaccord"]
    if jugeables:
        print("\n   LE SECOND SIGNAL, CONTRÔLÉ SUR CE DONT ON N'AVAIT PAS BESOIN")
        for k in ("exact, canton d'accord", "exact, canton en désaccord",
                  "exact, canton muet", "flou CONFIRMÉ", "flou contredit",
                  "flou, canton muet"):
            if ctrl[k]:
                print(f"      {k:<28} {ctrl[k]:>5}")
        print(f"\n      Le canton confirme {ok/jugeables:.1%} des appariements "
              f"EXACTS, dont il\n      n'avait pas à décider. C'est la mesure "
              f"de sa fiabilité quand il\n      tranche les flous, et elle ne "
              f"lui doit rien.")

    if contredits:
        print("\n  les flous que le canton dément — non posés :")
        for r, h, att in contredits[:8]:
            print(f"     « {r['commune'][:26]:<26} » -> {h} "
                  f"{libelle.get(h, '?')[:22]:<22} canton lu {att}, "
                  f"réel {sorted(canton_de(h))}")

    reste = [r for r, h, st in finale if st in ("aucun", "homonyme")]
    if reste:
        print(f"\n  les {len(reste)} sans piste — arrondissement, canton, nom lu :")
        for r in reste:
            print(f"     arr {r['arr']:>2}  canton {r['canton']:>2}  "
                  f"« {r['commune']} »")

    jamais = set(vivier_1954) - {h for _, h, st in finale if h}
    print(f"\n  {len(jamais)} communes du vivier ne sont atteintes par aucune "
          f"ligne.\n  Le volume n'en a produit que {len(cibles)} sur "
          f"{len(vivier_1954)} : {len(vivier_1954) - len(cibles)} lignes\n"
          f"  manquent à la lecture elle-même, et ne sont pas un défaut "
          f"d'appariement.")

    # la proposition écartée est conservée : la perdre obligerait à tout
    # recalculer si une troisième source apparaissait
    ecarte = {id(r): h for r, h, st in decision
              if h and st in ("exact_collision", "flou_collision")}
    for r, h, att in contredits:
        ecarte[id(r)] = h
    return [(r, h, st, ecarte.get(id(r), "")) for r, h, st in finale]


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--appliquer", action="store_true")
    args = ap.parse_args()

    if not LU.exists():
        sys.exit(f"{LU} absent.")
    lignes = list(csv.DictReader(LU.open(encoding="utf-8")))

    p = pont()
    modernes = {m for v in p.values() for s in v.values() for m in s if m}
    cantons = cantons_1940(modernes)
    print(f"pont : {sum(len(v) for v in p.values())} communes de 1954 dans les "
          f"départements disparus,\n       {len(modernes)} codes modernes, "
          f"{len(cantons)} avec un canton en 1940")

    resultats = []
    for dep_lu, prefixe in DEPS.items():
        vivier_1954 = p.get(prefixe)
        if not vivier_1954:
            print(f"\n{dep_lu} : le pont ne connaît pas le préfixe {prefixe} "
                  f"— sauté.")
            continue
        par_cle, libelle = noms_du_vivier(vivier_1954)
        couverts = {i for v in par_cle.values() for i in v}
        if len(couverts) < len(vivier_1954):
            print(f"\n  ({len(vivier_1954) - len(couverts)} communes du vivier "
                  f"{prefixe} n'ont aucun nom connu — inatteignables)")
        resultats += traite_departement(dep_lu, prefixe, lignes, vivier_1954,
                                        par_cle, libelle, cantons)

    poses = sum(1 for _, h, st, _ in resultats
                if st in ("ferme", "ferme_canton"))
    print(f"\n{'='*62}\nTOTAL : {poses} codes retrouvés sur "
          f"{len(resultats)} lignes examinées\n{'='*62}")

    if not args.appliquer:
        print("\nÀ blanc. Relancer avec --appliquer.")
        return 0

    sauve = LU.with_suffix(".csv.avant_departements_disparus")
    if not sauve.exists():
        shutil.copy2(LU, sauve)
        print(f"\n  sauvegarde : {sauve.name}")
    else:
        print(f"\n  sauvegarde déjà présente, conservée : {sauve.name}")

    for r, h, st, propose in resultats:
        r["insee"] = h if st in ("ferme", "ferme_canton") else ""
        r["appariement"] = st
        r["insee_propose"] = propose

    with LU.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(lignes[0].keys()))
        w.writeheader()
        w.writerows(lignes)

    total = sum(1 for r in lignes if r["insee"])
    print(f"\nÉTAT FINAL : {total} lignes sur {len(lignes)} ont un code INSEE "
          f"— {total/len(lignes):.1%}")
    print("\nRejouer ensuite la chaîne SQL :")
    print("   psql -d histgis -f  sql/66_cog1954_stage.sql")
    print("   psql -d histgis -1 -f sql/67_cantons_1949_1951.sql")
    print("   psql -d histgis -1 -f sql/68_cog1954_membership.sql")
    return 0


if __name__ == "__main__":
    sys.exit(main())
