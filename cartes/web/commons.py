#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
commons.py — dépôt des cartes de la page sur Wikimedia Commons.

Utilisé par `servir.py` ; rien à lancer à la main. Bibliothèque standard
seulement, comme `servir.py` : la page doit rester servie sans rien installer.

D'où vient le procédé
---------------------
Le schéma est celui de *parliamentdiagram* (github.com/slashme/parliamentdiagram,
`src/app.py`, route `commons_upload`) : la page fabrique l'image et le texte de
description, le serveur local détient le jeton, demande un jeton CSRF à l'API,
puis envoie `action=upload` en multipart. On en garde aussi la règle des
avertissements : `ignorewarnings` n'est accepté que pour un couple
(nom, contenu) qui vient de recevoir un avertissement `exists*` ou `duplicate`,
et pour rien d'autre — la page ne peut pas forcer un écrasement d'elle-même.

Ce qui change : parliamentdiagram est un service multi-utilisateurs, il lui faut
le flux OAuth 1.0a complet (mwoauth, URL de rappel, consommateur validé par les
administrateurs). Ici la page tourne sur 127.0.0.1 pour une seule personne : un
consommateur OAuth 2 « owner-only » suffit. Il est approuvé sur-le-champ, et
donne directement un jeton d'accès qu'on passe en `Authorization: Bearer`.

Configuration : `cartes/web/commons.toml` (ignoré par git), voir LISEZMOI.md.

    jeton   = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9…"   # jeton d'accès OAuth 2
    api     = "https://commons.wikimedia.org/w/api.php"  # facultatif
    contact = "https://commons.wikimedia.org/wiki/User:…"  # pour le User-Agent
"""

import hashlib
import json
import tomllib
import urllib.error
import urllib.parse
import urllib.request
import uuid
from pathlib import Path

API_DEFAUT = "https://commons.wikimedia.org/w/api.php"
# Lecture seule, sans jeton : la vérification des liens du paragraphe pour
# Wikipédia (voir `verifie_wikipedia`).
API_WP = "https://fr.wikipedia.org/w/api.php"
COMMENTAIRE = "Carte exportée de la page histgis (projet_carte)"

# Wikimedia refuse les requêtes sans User-Agent descriptif, et demande un moyen
# de contact. On ne met PAS d'adresse par défaut : c'est `contact` dans la
# configuration, ou à défaut la page utilisateur du compte connecté.
UA = "histgis-carte/1.0 (projet_carte; {contact}) python-urllib"


class ErreurCommons(Exception):
    pass


class Commons:
    def __init__(self, chemin_config: Path):
        self.chemin = chemin_config
        self.cfg = {}
        self._csrf = None
        self._utilisateur = None
        # Couples (nom de fichier, sha1) autorisés à repasser avec
        # ignorewarnings : ceux qui viennent de recevoir un avertissement
        # d'existence ou de doublon. Consommés au premier usage.
        self.tickets = set()
        self.recharge()

    # ------------------------------------------------------------------ config
    def recharge(self):
        self.cfg = {}
        if self.chemin.exists():
            with open(self.chemin, "rb") as f:
                self.cfg = tomllib.load(f)
        self._csrf = None
        self._utilisateur = None

    @property
    def api(self):
        return self.cfg.get("api") or API_DEFAUT

    @property
    def configure(self):
        return bool(self.cfg.get("jeton"))

    def _entetes(self, avec_jeton=True):
        contact = self.cfg.get("contact") or (
            f"User:{self._utilisateur}" if self._utilisateur else "sans contact")
        h = {"User-Agent": UA.format(contact=contact)}
        if avec_jeton and self.configure:
            h["Authorization"] = "Bearer " + self.cfg["jeton"].strip()
        return h

    # ------------------------------------------------------------------ HTTP
    def _get(self, params, avec_jeton=True):
        params = dict(params, format="json", formatversion="2")
        url = self.api + "?" + urllib.parse.urlencode(params)
        req = urllib.request.Request(url, headers=self._entetes(avec_jeton))
        return self._lit(req)

    def _post_multipart(self, champs, fichier):
        borne = "----histgis" + uuid.uuid4().hex
        corps = bytearray()
        for k, v in champs.items():
            corps += (f"--{borne}\r\nContent-Disposition: form-data; "
                      f'name="{k}"\r\n\r\n').encode()
            corps += str(v).encode("utf-8") + b"\r\n"
        nom, contenu, type_mime = fichier
        corps += (f"--{borne}\r\nContent-Disposition: form-data; name=\"file\"; "
                  f'filename="{urllib.parse.quote(nom)}"\r\n'
                  f"Content-Type: {type_mime}\r\n\r\n").encode()
        corps += contenu + b"\r\n"
        corps += f"--{borne}--\r\n".encode()
        h = self._entetes()
        h["Content-Type"] = f"multipart/form-data; boundary={borne}"
        req = urllib.request.Request(self.api, data=bytes(corps), headers=h,
                                     method="POST")
        return self._lit(req, delai=180)

    @staticmethod
    def _lit(req, delai=30):
        try:
            with urllib.request.urlopen(req, timeout=delai) as r:
                return json.loads(r.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            corps = e.read().decode("utf-8", "replace")[:500]
            try:
                return json.loads(corps)
            except ValueError:
                raise ErreurCommons(f"HTTP {e.code} : {corps}") from None
        except urllib.error.URLError as e:
            raise ErreurCommons(f"Commons injoignable : {e.reason}") from None

    # ------------------------------------------------------------------ API
    def etat(self):
        """Ce que la page affiche à l'ouverture du dialogue."""
        r = {"configure": self.configure, "api": self.api, "utilisateur": None,
             # catégories ajoutées à tous les fichiers (catégorie de projet…)
             "categories": list(self.cfg.get("categories", []))}
        if not self.configure:
            r["message"] = ("aucun jeton : créer cartes/web/commons.toml "
                            "(voir LISEZMOI.md)")
            return r
        try:
            d = self._get({"action": "query", "meta": "userinfo",
                           "uiprop": "rights"})
        except ErreurCommons as e:
            r["message"] = str(e)
            return r
        if "error" in d:
            r["message"] = f"{d['error'].get('code')} : {d['error'].get('info')}"
            return r
        ui = d.get("query", {}).get("userinfo", {})
        if ui.get("anon") or not ui.get("name"):
            r["message"] = "jeton refusé : Commons répond en anonyme"
            return r
        self._utilisateur = ui["name"]
        r["utilisateur"] = ui["name"]
        r["peut_deposer"] = "upload" in ui.get("rights", [])
        return r

    def verifie(self, fichier, categories):
        """Existence du nom de fichier et des catégories, redirections de
        catégorie signalées, suggestions pour celles qui manquent."""
        titres = []
        if fichier:
            titres.append("File:" + fichier)
        titres += ["Category:" + c for c in categories if c]
        r = {"fichier": None, "categories": {}}
        if not titres:
            return r
        d = self._get({
            "action": "query", "titles": "|".join(titres[:50]),
            "prop": "imageinfo|templates", "iiprop": "url|sha1",
            "tltemplates": "Template:Category redirect", "tllimit": "max",
        }, avec_jeton=False)
        if "error" in d:
            raise ErreurCommons(d["error"].get("info", "erreur API"))
        q = d.get("query", {})
        # Titre demandé -> titre normalisé (« Category:maps of X » devient
        # « Category:Maps of X »), pour retrouver chaque réponse.
        norm = {n["from"]: n["to"] for n in q.get("normalized", [])}
        pages = {p["title"]: p for p in q.get("pages", [])}
        if fichier:
            p = pages.get(norm.get("File:" + fichier, "File:" + fichier), {})
            ii = (p.get("imageinfo") or [{}])[0]
            r["fichier"] = {
                "existe": not p.get("missing", False) and "pageid" in p,
                "url": ii.get("descriptionurl"),
                "sha1": ii.get("sha1"),
                "invalide": bool(p.get("invalid")),
            }
        for c in categories:
            if not c:
                continue
            t = norm.get("Category:" + c, "Category:" + c)
            p = pages.get(t, {})
            existe = "pageid" in p and not p.get("missing", False)
            info = {"existe": existe,
                    "redirection": bool(p.get("templates")),
                    "invalide": bool(p.get("invalid"))}
            if not existe and not info["invalide"]:
                info["suggestions"] = self._suggere(c)
            r["categories"][c] = info
        return r

    def verifie_wikipedia(self, titres):
        """Existence de titres d'articles sur fr.wikipedia, pour le paragraphe
        que la page propose. Redirections suivies (`cible` : le titre d'arrivée,
        que la page lie directement), pages d'homonymie signalées — un lien vers
        une homonymie est un lien bleu qui ne mène nulle part. Lecture publique :
        le jeton Commons n'est pas envoyé. Par lots de 50, la limite de l'API."""
        titres = [t for t in dict.fromkeys(titres) if isinstance(t, str) and t][:3000]
        r = {}
        for i in range(0, len(titres), 50):
            lot = titres[i:i + 50]
            params = {"action": "query", "titles": "|".join(lot),
                      "redirects": "1", "prop": "pageprops",
                      "ppprop": "disambiguation",
                      "format": "json", "formatversion": "2"}
            req = urllib.request.Request(
                API_WP + "?" + urllib.parse.urlencode(params),
                headers=self._entetes(avec_jeton=False))
            try:
                d = self._lit(req)
            except ErreurCommons as e:
                raise ErreurCommons(str(e).replace("Commons injoignable",
                                                   "fr.wikipedia injoignable")) from None
            if "error" in d:
                raise ErreurCommons(d["error"].get("info", "erreur API"))
            q = d.get("query", {})
            norm = {n["from"]: n["to"] for n in q.get("normalized", [])}
            redir = {n["from"]: n["to"] for n in q.get("redirects", [])}
            pages = {p["title"]: p for p in q.get("pages", [])}
            for t in lot:
                n = norm.get(t, t)
                c = redir.get(n, n)
                p = pages.get(c, {})
                existe = "pageid" in p and not p.get("missing", False)
                r[t] = {"existe": existe,
                        "cible": c if existe and c != t else None,
                        "homonymie": "disambiguation" in (p.get("pageprops") or {}),
                        "invalide": bool(p.get("invalid"))}
        return r

    def _suggere(self, categorie):
        try:
            d = self._get({"action": "query", "list": "search",
                           "srnamespace": "14", "srlimit": "4",
                           "srsearch": categorie}, avec_jeton=False)
        except ErreurCommons:
            return []
        return [s["title"].split(":", 1)[1]
                for s in d.get("query", {}).get("search", [])]

    def _jeton_csrf(self):
        if not self._csrf:
            d = self._get({"action": "query", "meta": "tokens", "type": "csrf"})
            if "error" in d:
                raise ErreurCommons(
                    f"{d['error'].get('code')} : {d['error'].get('info')}")
            self._csrf = d["query"]["tokens"]["csrftoken"]
        return self._csrf

    def depose(self, nom, contenu: bytes, texte, ignorer=False):
        """Envoie le fichier. Rend la réponse de l'API telle quelle (la page
        l'interprète), avec un champ `histgis` pour ce que le serveur a décidé."""
        if not self.configure:
            raise ErreurCommons("aucun jeton configuré")
        sha1 = hashlib.sha1(contenu).hexdigest()
        ticket = (nom, sha1)
        if ignorer and ticket not in self.tickets:
            # Même règle que parliamentdiagram : on n'écrase que ce qu'on vient
            # de se voir signaler, jamais sur simple demande de la page.
            raise ErreurCommons("ignorewarnings refusé : aucun avertissement "
                                "préalable pour ce fichier et ce contenu")
        self.tickets.discard(ticket)

        champs = {
            "action": "upload", "format": "json", "formatversion": "2",
            "filename": nom, "comment": COMMENTAIRE, "text": texte,
            "ignorewarnings": "1" if ignorer else "0",
            "token": self._jeton_csrf(),
        }
        if not ignorer:
            champs.pop("ignorewarnings")
        d = self._post_multipart(champs, (nom, contenu, "image/svg+xml"))

        # Jeton CSRF périmé : on en redemande un, une fois.
        if d.get("error", {}).get("code") == "badtoken":
            self._csrf = None
            champs["token"] = self._jeton_csrf()
            d = self._post_multipart(champs, (nom, contenu, "image/svg+xml"))

        up = d.get("upload", {})
        if up.get("result") == "Warning":
            av = up.get("warnings", {})
            if av and all(k == "duplicate" or k.startswith("exists")
                          for k in av):
                self.tickets.add(ticket)
                d["histgis"] = {"peut_forcer": True}
        return d
