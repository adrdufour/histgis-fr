# -*- coding: utf-8 -*-
"""
Communes coupées entre plusieurs cantons — décrets de 1973, 1982 et 1984.

Méthode : on ne découpe pas le JO par décret (l'OCR d'une page à deux colonnes lit
parfois le titre de la colonne 2 avant le corps de la colonne 1, ce qui permute des
décrets voisins). On découpe par segment « Canton de X, comprenant ... », qui est
auto-suffisant, et c'est le COG qui identifie la commune et donc son département.
Le décret est ensuite rattaché par le couple (date de signature, département).
"""
import re, glob, os, csv, unicodedata
from collections import Counter, defaultdict

def clean(t):
    t = t.replace("­","").replace("’","'").replace("‘","'")
    t = re.sub(r"-\n(?=[a-zà-ÿ])", "", t)
    return repair(re.sub(r"[ \t\n]+", " ", t))

VOCAB = ["portion","portions","territoire","territoires","partie","parties","fraction",
         "fractions","commune","communes","ville","comprenant","comportant","canton",
         "cantons","delimitee","delimite","delimitees","situee","situe","incluse","incluses",
         "departement","conseil","general","prefecture"]
def _rep(mot):
    return re.compile("|".join(re.escape(mot[:i])+r"\s+"+re.escape(mot[i:])
                               for i in range(2, len(mot)-1)), re.I)
REPARS = [(_rep(m), m) for m in VOCAB]

def repair(t):
    """L'OCR du JO coupe des mots en deux (« terri toire »). On les recolle."""
    for rx, mot in REPARS:
        t = rx.sub(lambda m: m.group(0)[0].upper()+mot[1:] if m.group(0)[0].isupper() else mot, t)
    return t

def norm(s):
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return re.sub(r"[^A-Z]", "", s.upper())

# ---------- référentiel communal --------------------------------------------
REF = defaultdict(dict)
with open("cog/1999/comsimp1999.txt", encoding="latin-1") as f:
    for row in csv.DictReader(f, delimiter="\t"):
        nom, art = (row.get("NCCENR") or "").strip(), (row.get("ARTMIN") or "").strip("() ")
        if not nom: continue
        plein = (art+" " if art else "")+nom
        REF[row["DEP"]][norm(nom)] = plein
        if art: REF[row["DEP"]][norm(art+nom)] = plein
try:
    with open("cog/1999/Corhistoriq1999.txt", encoding="latin-1") as f:
        for row in csv.DictReader(f, delimiter="\t"):
            for k in ("NCCOFF","NCCANC"):
                v = (row.get(k) or "").strip()
                if v and row.get("DEP"): REF[row["DEP"]].setdefault(norm(v), v)
except Exception: pass
# rang 0 = commune du COG 1999 ; rang 1 = nom ancien de Corhistoriq (plus incertain)
RANG = {}
with open("cog/1999/comsimp1999.txt", encoding="latin-1") as f:
    for row in csv.DictReader(f, delimiter="\t"):
        n=(row.get("NCCENR") or "").strip()
        if n: RANG[(row["DEP"], norm(n))] = 0
ALLREF = defaultdict(set)
for d, m in REF.items():
    for k in m:
        ALLREF[k].add(d); RANG.setdefault((d,k), 1)

# ---------- index des décrets ------------------------------------------------
PUB2SIG = {"19730717":"1973-07-13","19730725":"1973-07-23","19730804":"1973-08-02",
           "19730817":"1973-08-16","19820116":"1982-01-15","19820122":"1982-01-20",
           "19820126":"1982-01-25","19841230":"1984-12-24"}
index  = {r["decret"].replace("n° ",""): r
          for r in csv.DictReader(open("cantons/decrets_1973_1984.csv", encoding="utf-8"))}
bycode = {(r["date_signature"], r["dep_code"]): n for n,r in index.items()}

DE    = r"(?:d'|de\s+l'|de\s+la\s+|de\s+les\s+|des\s+|du\s+|de\s+)"
VILLE = r"(?:ville|commune|cit[ée])"
AMORCES = [
 ("portion de territoire", re.compile(r"portions?\s+de\s+territoire\s+"+DE+VILLE+r"\s+"+DE, re.I)),
 ("partie",                re.compile(r"parties?\s+"+DE+VILLE+r"\s+"+DE, re.I)),
 ("fraction",              re.compile(r"fractions?\s+"+DE+VILLE+r"\s+"+DE, re.I)),
]
MARQ     = re.compile(r"(axe\s+(?:de|des|du|d')|d[ée]limit[ée]e?s?\s+par|situ[ée]e?s?\s+(?:à|au|sur)\s|rive\s+(?:gauche|droite)|voie\s+ferr[ée]e|ligne\s+de\s+chemin\s+de\s+fer|boulevard|avenue|rue\s+[A-Z])", re.I)
COMMUNES = re.compile(r"(?:comprenant|comportant|compos[ée]e?s?\s+d)\w*\s+(?:les\s+communes|la\s+commune)", re.I)
CANTON   = re.compile(r"[Cc]anton\s+"+DE+r"([^\n,]{1,55}?)\s*,?\s+(?:comprenant|comportant|d[ée]limit[ée]|constitu[ée]|form[ée]|compos[ée])")
FINDEC   = re.compile(r"(Fait\s+à\s+Paris|est\s+charg[ée]\s+de\s+l'ex[ée]cution\s+du\s+pr[ée]sent\s+d[ée]cret)", re.I)
TOKEN    = re.compile(r"[A-ZÉÈÀÂÎÔÛÇ][\wÀ-ÿ']{2,}(?:-[A-ZÉÈÀÂÎÔÛÇa-zà-ÿ'][\wÀ-ÿ']*){0,5}")
SUFFIXE  = re.compile(r"[\s\-]*(I{1,3}V?|VI{0,3}|IX|X{1,2}I{0,3}|\d+|NORD|SUD|EST|OUEST|CENTRE|NORD-EST|NORD-OUEST|SUD-EST|SUD-OUEST|CAMPAGNE|VILLE)$")

def candidats(txt, sig):
    """toutes les (dep, nom) possibles pour un début de chaîne, restreint aux dép. légiférant ce jour-là"""
    c = norm(txt)[:40]
    out = []
    for L in range(min(38, len(c)), 3, -1):
        pre = c[:L]
        if pre in ALLREF:
            for d in ALLREF[pre]:
                out.append((d, REF[d][pre], L, RANG.get((d,pre),1)))
            if out: break
    return out

rows = []
for path in sorted(glob.glob("build_txt/*_raw.txt")):
    jo  = os.path.basename(path).replace("_raw.txt","")
    sig = PUB2SIG[re.search(r"(\d{8})", jo).group(1)]
    txt = clean(open(path, encoding="utf-8", errors="replace").read())
    marks = [(m.start(), m.group(1).strip(" .,-")) for m in CANTON.finditer(txt)]
    for i,(p,name) in enumerate(marks):
        seg = txt[p: marks[i+1][0] if i+1 < len(marks) else len(txt)]
        fin = FINDEC.search(seg)
        if fin: seg = seg[:fin.end()]
        if len(seg) > 4000: seg = seg[:4000]
        # contexte départemental du segment : vote des communes citées
        votes = Counter()
        for m in TOKEN.finditer(seg):
            for d in ALLREF.get(norm(m.group(0)), ()):
                if (sig, d) in bycode: votes[d] += 1
        trouve = []
        for kind, rx in AMORCES:
            for m in rx.finditer(seg):
                cs = [c for c in candidats(seg[m.end():m.end()+60], sig) if (sig, c[0]) in bycode]
                if not cs: continue
                cs.sort(key=lambda c:(c[3], 0 if norm(c[1]) in norm(name) else 1, -c[2], -votes.get(c[0],0)))
                trouve.append((kind,)+cs[0][:2])
        mode = "explicite"
        if not trouve and MARQ.search(seg) and not COMMUNES.search(seg):
            base = SUFFIXE.sub("", name.upper()).replace("-","")
            cs = [c for c in candidats(base, sig) if (sig, c[0]) in bycode]
            if cs:
                cs.sort(key=lambda c:(c[3], -c[2], -votes.get(c[0],0)))
                trouve = [("délimitation sans nom de commune",)+cs[0][:2]]
                mode = "déduite du nom du canton"
        if not trouve: continue
        seen, vv = set(), []
        for k,d,v in trouve:
            if (d,v) not in seen: seen.add((d,v)); vv.append((k,d,v))
        dep = Counter(d for _,d,_ in vv).most_common(1)[0][0]
        num = bycode[(sig, dep)]
        rows.append({
            "date_signature": sig, "decret": num,
            "dep_code": dep, "dep_nom": index[num]["dep_nom_epoque"],
            "canton": name,
            "commune_coupee": " ; ".join(v for _,_,v in vv),
            "reperage": mode,
            "formulation": " ; ".join(sorted({k for k,_,_ in vv})),
            "limite_decrite": "oui" if MARQ.search(seg) else "non (renvoi au canton voisin)",
            "texte": seg.strip()[:2000],
            "jo": jo, "legifrance_url": index[num]["legifrance_url"],
        })

# dédoublonnage (un décret peut figurer dans le JO ordinaire ET son numéro complémentaire)
uniq = {}
for r in rows:
    k = (r["decret"], norm(r["canton"]), norm(r["commune_coupee"]))
    if k not in uniq or len(r["texte"]) > len(uniq[k]["texte"]): uniq[k] = r
rows = sorted(uniq.values(), key=lambda r:(r["date_signature"], r["dep_code"], r["canton"]))

with open("cantons/communes_coupees_1973_1984.csv","w",newline="",encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)

comm = defaultdict(set)
for r in rows:
    for v in r["commune_coupee"].split(" ; "): comm[(r["dep_code"],v)].add(r["canton"])
print("lignes (canton × commune coupée) :", len(rows))
print("décrets concernés :", len({r["decret"] for r in rows}), "/", len(index))
print("communes coupées distinctes :", len(comm))
print("repérage explicite :", sum(1 for r in rows if r["reperage"]=="explicite"),
      "| déduit du nom du canton :", sum(1 for r in rows if r["reperage"]!="explicite"))
print("limite décrite dans le texte :", sum(1 for r in rows if r["limite_decrite"]=="oui"))
print()
for d,n in sorted(Counter(r["date_signature"] for r in rows).items()):
    print(" ", d, "→", n, "lignes,", len({r["decret"] for r in rows if r["date_signature"]==d}), "décrets,",
          len({(r["dep_code"],v) for r in rows if r["date_signature"]==d for v in r["commune_coupee"].split(" ; ")}), "communes")
print("\ncommunes les plus morcelées :")
for (d,v),c in sorted(comm.items(), key=lambda kv:(-len(kv[1]), kv[0]))[:20]:
    print(f"   {d} {v}: {len(c)} cantons")
