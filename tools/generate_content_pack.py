#!/usr/bin/env python3
"""Génère apps/memo_app/assets/content/pack.json depuis le catalogue de la charte CREYATIV.

Le catalogue est volontairement dupliqué ici pour que l'outil soit autonome.
Niveaux provisoires, à valider avec un professionnel de la CAA.
"""
import json
import pathlib

CATALOGUE = [
    ("CBE", "Mes besoins", "bubble",
     ["Je veux", "Je ne veux pas", "Encore", "Fini", "Aide-moi", "Attends", "Oui", "Non",
      "S'il te plaît", "Merci", "Stop", "Donne-moi", "Je veux aller", "Je veux rester",
      "Je veux changer", "J'ai besoin", "Je ne sais pas", "Je n'ai pas compris", "Laisse-moi",
      "Viens"],
     list(range(1, 16)) + list(range(17, 22))),
    ("ACT", "Actions", "hand",
     ["Manger", "Boire", "Dormir", "Jouer", "Marcher", "Courir", "Lire", "Écrire", "Travailler",
      "Laver", "S'habiller", "Se déshabiller", "Attendre", "Parler", "S'asseoir", "Se lever",
      "Ouvrir", "Fermer", "Regarder", "Écouter", "Prendre", "Donner", "Aller", "Venir",
      "Se reposer"], None),
    ("ALI", "Alimentation", "plate",
     ["Eau", "Lait", "Jus", "Pain", "Riz", "Plantain", "Manioc", "Macabo", "Igname", "Maïs",
      "Haricot", "Arachide", "Poisson", "Poulet", "Viande", "Beignet", "Bouillie", "Ndolé", "Eru",
      "Bâton de manioc", "Mangue", "Papaye", "Ananas", "Avocat", "Orange", "Pastèque", "Bonbon",
      "Biscuit", "Glace", "Couscous", "Œuf", "Banane"], None),
    ("EMO", "Mes émotions", "face",
     ["Content", "Triste", "Fâché", "Peur", "Fatigué", "Malade", "Calme", "Inquiet", "Surpris",
      "Ennuyé", "Excité", "J'ai chaud", "J'ai froid", "J'ai faim", "J'ai soif"], None),
    ("SAN", "Santé", "cross",
     ["J'ai mal", "Tête", "Œil", "Oreille", "Bouche", "Dent", "Gorge", "Ventre", "Dos", "Bras",
      "Main", "Jambe", "Pied", "Médicament", "Médecin", "Infirmier ou infirmière", "Hôpital",
      "Urgence", "Poitrine", "Je respire mal"], None),
    ("PER", "Personnes", "person",
     ["Moi", "Maman", "Papa", "Frère", "Sœur", "Grand-mère", "Grand-père", "Enfant", "Ami",
      "Camarade", "Maîtresse", "Maître", "Médecin", "Infirmière", "Éducateur"], None),
    ("LIE", "Lieux", "house",
     ["Maison", "École", "Classe", "Toilettes", "Cuisine", "Chambre", "Cour", "Hôpital", "Marché",
      "Boutique", "Route", "Terrain de jeu", "Église", "Dehors"], None),
    ("HYG", "Hygiène", "drop",
     ["Toilettes", "Douche", "Savon", "Eau", "Serviette", "Se laver les mains",
      "Se brosser les dents", "Propre", "Sale", "Papier toilette"], None),
]


def level(cat, rank):
    if cat == "CBE":
        return 0
    return 0 if rank < 3 else 1 if rank < 10 else 2


categories, pictograms = [], []
for order, (code, label, icon, concepts, nums) in enumerate(CATALOGUE, 1):
    categories.append({"code": code, "sortOrder": order, "icon": icon, "labels": {"fr": label}})
    nums = nums or list(range(1, len(concepts) + 1))
    for rank, (concept, n) in enumerate(zip(concepts, nums)):
        pictograms.append({
            "code": f"CAA-CR-{code}-{n:03d}", "category": code, "level": level(code, rank),
            "audience": "all", "sortOrder": rank + 1, "image": None,
            "labels": {"fr": {"label": concept, "spoken": concept.lower()}},
        })

out = pathlib.Path(__file__).resolve().parent.parent / "apps/memo_app/assets/content/pack.json"
out.write_text(json.dumps({"version": 1, "categories": categories, "pictograms": pictograms},
                          ensure_ascii=False, indent=2), encoding="utf-8")
print(len(pictograms), "pictogrammes écrits dans", out)
