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


# Palier : seule la catégorie CBE (20 concepts prioritaires) est gratuite (ADR-008).
FREE_CATEGORIES = {"CBE"}

# Couleur de regroupement par catégorie (contraste d'au moins 3:1 sur blanc).
COLORS = {
    "CBE": "#C1502E", "ACT": "#2F7D4F", "ALI": "#B45F06", "EMO": "#B5486D",
    "SAN": "#2B6CB0", "PER": "#6B4FA0", "LIE": "#1F7A6C", "HYG": "#1C7C9A",
}

# Images de démonstration issues des échantillons de la charte. Non validées :
# le mot est écrit dans l'image et les styles sont mélangés. À retirer quand
# les pictogrammes définitifs (sans texte) seront livrés.
DEMO_IMAGES = {
    "CBE": {"Oui": "oui", "Non": "non", "Je ne veux pas": "je-ne-veux-pas", "Encore": "encore",
            "Aide-moi": "aide-moi", "S'il te plaît": "s-il-te-plait", "Merci": "merci",
            "Stop": "stop", "Donne-moi": "donne-moi", "Je ne sais pas": "je-ne-sais-pas",
            "Viens": "viens"},
    "ACT": {"Manger": "manger", "Boire": "boire", "Dormir": "dormir", "Regarder": "regarder",
            "S'habiller": "s-habiller", "Aller": "aller", "S'asseoir": "s-asseoir",
            "Se lever": "se-lever", "Ouvrir": "ouvrir", "Fermer": "fermer"},
    "ALI": {"Eau": "eau", "Riz": "riz", "Orange": "orange", "Ananas": "ananas"},
    "EMO": {"Content": "content", "Triste": "triste", "Fâché": "fache", "J'ai faim": "j-ai-faim"},
    "LIE": {"Toilettes": "toilettes"},
    "HYG": {"Toilettes": "toilettes", "Eau": "eau", "Se laver les mains": "laver-mains",
            "Se brosser les dents": "brosser-dents"},
}


# Phrases toutes faites (onglet « Dis-le maintenant »), issues de la maquette.
PHRASES = [
    ("Je dois aller aux toilettes", ["école", "maison"]),
    ("Maman, viens s'il te plaît", ["maison"]),
    ("Je peux avoir de l'eau ?", ["maison", "école"]),
    ("Doucement, je n'ai pas compris", ["école"]),
    ("C'est à mon tour", ["jouer"]),
    ("Je veux jouer avec toi", ["jouer"]),
    ("J'ai fini mon travail", ["école"]),
    ("Je suis fatigué, je veux dormir", ["maison"]),
]


# Libellés anglais (anglais britannique, proche de l'usage au Cameroun).
CATEGORY_EN = {
    "CBE": "My needs", "ACT": "Actions", "ALI": "Food", "EMO": "My feelings",
    "SAN": "Health", "PER": "People", "LIE": "Places", "HYG": "Hygiene",
}

CONCEPTS_EN = {
    "CBE": ["I want", "I don't want", "More", "Finished", "Help me", "Wait", "Yes", "No",
            "Please", "Thank you", "Stop", "Give me", "I want to go", "I want to stay",
            "I want to change", "I need", "I don't know", "I didn't understand",
            "Leave me alone", "Come"],
    "ACT": ["Eat", "Drink", "Sleep", "Play", "Walk", "Run", "Read", "Write", "Work", "Wash",
            "Get dressed", "Get undressed", "Wait", "Talk", "Sit down", "Stand up", "Open",
            "Close", "Look", "Listen", "Take", "Give", "Go", "Come", "Rest"],
    "ALI": ["Water", "Milk", "Juice", "Bread", "Rice", "Plantain", "Cassava", "Cocoyam", "Yam",
            "Corn", "Beans", "Groundnut", "Fish", "Chicken", "Meat", "Beignet", "Porridge",
            "Ndolé", "Eru", "Cassava stick", "Mango", "Papaya", "Pineapple", "Avocado", "Orange",
            "Watermelon", "Sweet", "Biscuit", "Ice cream", "Couscous", "Egg", "Banana"],
    "EMO": ["Happy", "Sad", "Angry", "Scared", "Tired", "Sick", "Calm", "Worried", "Surprised",
            "Bored", "Excited", "I'm hot", "I'm cold", "I'm hungry", "I'm thirsty"],
    "SAN": ["It hurts", "Head", "Eye", "Ear", "Mouth", "Tooth", "Throat", "Tummy", "Back", "Arm",
            "Hand", "Leg", "Foot", "Medicine", "Doctor", "Nurse", "Hospital", "Emergency",
            "Chest", "I can't breathe well"],
    "PER": ["Me", "Mum", "Dad", "Brother", "Sister", "Grandmother", "Grandfather", "Child",
            "Friend", "Classmate", "Teacher", "Teacher", "Doctor", "Nurse", "Support worker"],
    "LIE": ["Home", "School", "Classroom", "Toilet", "Kitchen", "Bedroom", "Yard", "Hospital",
            "Market", "Shop", "Road", "Playground", "Church", "Outside"],
    "HYG": ["Toilet", "Shower", "Soap", "Water", "Towel", "Wash hands", "Brush teeth", "Clean",
            "Dirty", "Toilet paper"],
}

PHRASES_EN = [
    "I need to go to the toilet", "Mum, please come", "Can I have some water?",
    "Slowly, I didn't understand", "It's my turn", "I want to play with you",
    "I've finished my work", "I'm tired, I want to sleep",
]


TAGS_EN = {"école": "school", "maison": "home", "jouer": "play"}


def spoken_en(label):
    """Texte prononcé : minuscule initiale, sauf le pronom « I »."""
    if label.startswith("I ") or label.startswith("I'"):
        return label
    return label[0].lower() + label[1:]


def level(cat, rank):
    if cat == "CBE":
        return 0
    return 0 if rank < 3 else 1 if rank < 10 else 2


categories, pictograms = [], []
for order, (code, label, icon, concepts, nums) in enumerate(CATALOGUE, 1):
    categories.append({"code": code, "sortOrder": order, "icon": icon, "color": COLORS[code],
                       "labels": {"fr": label, "en": CATEGORY_EN[code]}})
    nums = nums or list(range(1, len(concepts) + 1))
    assert len(CONCEPTS_EN[code]) == len(concepts), code
    for rank, (concept, n) in enumerate(zip(concepts, nums)):
        en = CONCEPTS_EN[code][rank]
        demo = DEMO_IMAGES.get(code, {}).get(concept)
        pictograms.append({
            "code": f"CAA-CR-{code}-{n:03d}", "category": code, "level": level(code, rank),
            "audience": "all", "sortOrder": rank + 1,
            "tier": "free" if code in FREE_CATEGORIES else "premium",
            "image": f"assets/content/images/demo/{demo}.png" if demo else None,
            "labelInImage": bool(demo),
            "labels": {
                "fr": {"label": concept, "spoken": concept.lower()},
                "en": {"label": en, "spoken": spoken_en(en)},
            },
        })

phrases = [
    {"code": f"PH-{i:03d}", "sortOrder": i, "texts": {"fr": {"text": t, "tags": tags},
                                                        "en": {"text": PHRASES_EN[i - 1],
                                                               "tags": [TAGS_EN[x] for x in tags]}}}
    for i, (t, tags) in enumerate(PHRASES, 1)
]

root = pathlib.Path(__file__).resolve().parent.parent


def write(path, pack):
    path.write_text(json.dumps(pack, ensure_ascii=False, indent=2), encoding="utf-8")
    print(len(pack["pictograms"]), "pictogrammes écrits dans", path)


free = [p for p in pictograms if p["tier"] == "free"]
premium = [p for p in pictograms if p["tier"] == "premium"]
premium_cats = {p["category"] for p in premium}

# Paquet embarqué : contenu gratuit et phrases. Paquet payant : servi par la
# fonction premium-pack aux seuls abonnés (ADR-008, couche 1). Les deux ont la
# même version, incrémentée à chaque changement de contenu.
VERSION = 5
write(root / "apps/memo_app/assets/content/pack.json",
      {"version": VERSION, "categories": [c for c in categories if c["code"] not in premium_cats],
       "pictograms": free, "phrases": phrases})
write(root / "backend/supabase/functions/premium-pack/pack.json",
      {"version": VERSION, "categories": [c for c in categories if c["code"] in premium_cats],
       "pictograms": premium, "phrases": []})
