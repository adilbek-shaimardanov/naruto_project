import requests
from bs4 import BeautifulSoup
import pandas as pd
import re

def clean_html(html):
    soup = BeautifulSoup(html, "html.parser")
    text = soup.get_text(" ")
    return " ".join(text.split())

def remove_space_before_punctuation(text):
    return re.sub(r'\s([?.!,":;])', r'\1', text)

def get_episode_synopsis(url):
    response = requests.get(url)
    soup = BeautifulSoup(response.content, 'html.parser')

    synopsis_header = soup.find(lambda tag: tag.name in ["h2", "h3"] and ("Synopsis" in tag.get_text() or "Summary" in tag.get_text()))

    if synopsis_header:
        paragraphs = []
        current_element = synopsis_header.find_next_sibling()

        while current_element and ("Trivia" not in current_element.get_text()):
            if current_element.name == "p":
                text = clean_html(str(current_element))
                text = remove_space_before_punctuation(text)
                paragraphs.append(text)
            current_element = current_element.find_next_sibling()

        return "\n".join(paragraphs)

    return None

arc_mapping = {
    "Naruto": {
        "Prologue — Land of Waves": range(1, 20),
        "Chunin Exams": range(20, 68),
        "Konoha Crush": range(68, 81),
        "Search for Tsunade": range(81, 101),
        "Sasuke Recovery Mission": range(107, 136),
    },
    "Naruto Shippuden": {
        "Kazekage Rescue Mission": range(1, 33),
        "Tenchi Bridge Reconnaissance Mission": range(33, 54),
        "Akatsuki Suppression Mission": range(72, 89),
        "Itachi Pursuit Mission": list(range(113, 119)) + list(range(121, 127)),
        "Tale of Jiraiya the Gallant": range(127, 134),
        "Fated Battle Between Brothers": range(134, 144),
        "Pain's Assault": range(152, 176),
        "Five Kage Summit": range(197, 215),
        "Fourth Shinobi World War: Countdown": list(range(215, 223)) + list(range(243, 257)),
        "Fourth Shinobi World War: Confrontation": list(range(261, 290)) + list(range(296, 322)),
        "Fourth Shinobi World War: Climax": list(range(322, 349)) + list(range(362, 376)),
        "Birth of the Ten-Tails' Jinchūriki": list(range(378, 394)) + list(range(414, 432)),
        "Kaguya Ōtsutsuki Strikes": range(458, 480),
        "Konoha Hiden: The Perfect Day for a Wedding": range(494, 501),
    }
}

excluded_shippuden_episodes = {170, 171, 257, 258, 259, 260, 271, 311, 376, 377, 389, 390, 422, 423, 469}

input_csvs = ["datasets/naruto_episodes.csv", "datasets/naruto_shippuden_episodes.csv"]
season_keys = ["Naruto", "Naruto Shippuden"]

results = []

for i, input_csv in enumerate(input_csvs):
    df = pd.read_csv(input_csv)
    season_key = season_keys[i]

    for index, row in df.iterrows():
        episode_number = row["#"]
        episode_url = row["URL"]

        episode_arc = None
        for arc, episodes in arc_mapping[season_key].items():
            if episode_number in episodes:
                episode_arc = arc
                break

        if not episode_arc:
            print(f"Episode {episode_number} ({season_key}) skipped because it does not belong to any arc.")
            continue

        if season_key == "Naruto Shippuden" and episode_number in excluded_shippuden_episodes:
            print(f"Episode {episode_number} (S) removed because it is in the exclusion list.")
            continue

        synopsis = get_episode_synopsis(episode_url)

        if synopsis:
            episode_label = f"{episode_number} (S)" if season_key == "Naruto Shippuden" else str(episode_number)
            results.append({"Episode": episode_label, "Arc": episode_arc, "Synopsis": synopsis})
        else:
            print(f"Failed to retrieve synopsis for episode {episode_number} ({season_key})")

result_df = pd.DataFrame(results)
output_csv = "datasets/episodes_with_synopsis.csv"
result_df.to_csv(output_csv, index=False)

print(f"Results saved to {output_csv}")
