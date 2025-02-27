import requests
from bs4 import BeautifulSoup
import csv

url = "https://naruto.fandom.com/wiki/List_of_Animated_Media"

response = requests.get(url)
soup = BeautifulSoup(response.content, 'html.parser')

table = soup.find('table', {'class': 'box table coloured bordered innerbordered style-basic fill-horiz'})

with open('datasets/naruto_episodes.csv', mode='w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)

    rows = table.find_all('tr')
    for row in rows:
        cells = row.find_all(['th', 'td'])
        if cells:
            cell_text = [cell.get_text(strip=True) for cell in cells]

            link = row.find('a')
            if link:
                episode_url = "https://naruto.fandom.com" + link['href']
                cell_text.append(episode_url)
            else:
                cell_text.append("URL")

            writer.writerow(cell_text)

print("Data successfully saved to 'naruto_episodes.csv'")
