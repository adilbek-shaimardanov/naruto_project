import pandas as pd
import networkx as nx
import requests
import urllib3
import logging
import re
import time
import os
from itertools import combinations
from tenacity import retry, stop_after_attempt, wait_exponential
from dotenv import load_dotenv

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

load_dotenv()
API_KEY = os.getenv("QWEN_API_KEY")
BASE_URL = "https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions"

OUTPUT_FILE = "datasets/final_dataset_fixed.csv"

VALID_CHARACTERS = {"Naruto", "Sasuke", "Sakura", "Kakashi", "Hinata", "Jiraiya", "Itachi", "Pain", "Gaara"}

ALLOWED_CLANS = {"Uchiha", "Senju", "Hyuga", "Uzumaki", "Nara", "Akimichi", "Yamanaka", "Aburame", "Inuzuka", "Kaguya"}
ALLOWED_GROUPS = {"Team 7", "Team 8", "Team 10", "Team Guy", "Sannin", "Akatsuki", "Konoha 11", "Taka", "Hebi",
                  "The Five Kage", "Allied Shinobi Forces"}

PERMANENT_TAGS = {
    "friendship", "teammates", "allies", "teacher-student", "master-disciple", "rivals",
    "enemies", "ideological conflict", "trust", "betrayal", "love", "respect", "leader-subordinate",
    "former allies", "former enemies"
}
TEMPORARY_TAGS = {"opponents", "conflict"}


@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=4, max=10))
def send_request(data, description=""):
    headers = {"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"}
    response = requests.post(BASE_URL, headers=headers, json=data, verify=False, timeout=30)
    response.raise_for_status()
    return response.json()


def analyze_clan_or_group(character, allowed_set, category):
    prompt = (
        f"Identify the {category} of {character}. Choose only from this predefined list: {', '.join(allowed_set)}. "
        "Return only the name of the {category}, nothing else. If no {category} applies, return 'None'."
    )
    data = {"model": "qwen-max", "messages": [{"role": "user", "content": prompt}], "max_tokens": 10}
    try:
        result = send_request(data, f"Determining {category}")
        result_text = result["choices"][0]["message"]["content"].strip()
        return result_text if result_text in allowed_set else "None"
    except:
        logging.error(f"[{category.upper()}] Error determining {category} for {character}!")
        return "None"


def get_tag_type(tags):
    tag_set = set(tags.split(", "))
    if tag_set & TEMPORARY_TAGS:
        return "Temporary"
    elif tag_set & PERMANENT_TAGS:
        return "Permanent"
    return "Unknown"


def is_key_event(tags):
    key_tags = {"betrayal", "former allies", "death", "leader-subordinate"}
    tag_set = set(tags.split(", "))
    return "Yes" if tag_set & key_tags else "No"

def analyze_relationship(character1, character2, synopsis):
    prompt = (
        f'List only valid relationship tags for {character1} and {character2} '
        f'from this episode: "{synopsis}". '
        f'Return only a comma-separated list of predefined relationship tags: '
        f'{", ".join(PERMANENT_TAGS | TEMPORARY_TAGS)}. '
        f'Do not include any other words, descriptions, or additional information. '
        f'Only return tags relevant to the relationship between {character1} and {character2}.'
    )
    data = {"model": "qwen-max", "messages": [{"role": "user", "content": prompt}], "max_tokens": 20}
    try:
        result = send_request(data, "Relationship Analysis")
        relationship = result["choices"][0]["message"]["content"].strip()
        return relationship
    except:
        logging.error(f"[REL] Error analyzing relationship {character1}-{character2}!")
        return ""

def get_network_changes(prev_rel, current_rel):
    prev_set = set(prev_rel.split(", ")) if isinstance(prev_rel, str) else prev_rel
    curr_set = set(current_rel.split(", ")) if isinstance(current_rel, str) else current_rel

    removed = prev_set - curr_set
    added = curr_set - prev_set

    if not removed and not added:
        return "False"

    minus_part = " ".join(f"–{tag}" for tag in sorted(removed))
    plus_part = " ".join(f"+{tag}" for tag in sorted(added))
    return f"True -> {minus_part} {plus_part}".strip()


def process_episodes(data):
    logging.info("[START] Beginning episode processing...")
    processed_data = []
    global prev_relationships
    prev_relationships = {}
    G = nx.Graph()

    if "#" in data.columns:
        data = data.rename(columns={"#": "Episode"})

    for index, row in data.iterrows():
        episode_number = row["Episode"]
        synopsis = row["Synopsis"]
        arc = row["Arc"]

        logging.info(f"[EP] Processing episode {episode_number}...")

        for char1, char2 in combinations(VALID_CHARACTERS, 2):
            if char1 not in synopsis or char2 not in synopsis:
                continue

            prev_rel = prev_relationships.get((char1, char2), set())
            relationship = analyze_relationship(char1, char2, synopsis)
            if not relationship:
                continue

            tag_type = get_tag_type(relationship)
            key_event = is_key_event(relationship)
            network_changes = get_network_changes(prev_rel, relationship)
            G.add_edge(char1, char2)
            degree_centrality = round(nx.degree_centrality(G).get(char1, 0), 3)
            betweenness_centrality = round(nx.betweenness_centrality(G).get(char1, 0), 3)
            closeness_centrality = round(nx.closeness_centrality(G).get(char1, 0), 3)

            processed_data.append([
                episode_number, char1, char2, relationship, arc, tag_type, key_event, network_changes,
                degree_centrality, betweenness_centrality, closeness_centrality,
                analyze_clan_or_group(char1, ALLOWED_CLANS, "clan"),
                analyze_clan_or_group(char2, ALLOWED_CLANS, "clan"),
                analyze_clan_or_group(char1, ALLOWED_GROUPS, "group"),
                analyze_clan_or_group(char2, ALLOWED_GROUPS, "group")
            ])

    df = pd.DataFrame(processed_data, columns=[
        "Episode", "Character1", "Character2", "Relationship", "Arc", "Tag_Type", "Key_Event_Flag", "Network_Changes",
        "Degree_Centrality", "Betweenness_Centrality", "Closeness_Centrality",
        "Clan_Character1", "Clan_Character2", "Group_Character1", "Group_Character2"
    ])

    df.to_csv(OUTPUT_FILE, index=False)
    logging.info("[FINISHED] Processing complete!")


if __name__ == "__main__":
    data = pd.read_csv("datasets/episodes_with_synopsis.csv")
    process_episodes(data)
