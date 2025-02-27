install.packages(c("tidyverse", "igraph", "ggplot2", "ggraph", "reshape2"))
library(tidyverse)
library(igraph)
library(ggplot2)
library(ggraph)
library(reshape2)
library(dplyr)
library(plotly)
library(patchwork)
library(showtext)

font_add_google("Montserrat", "montserrat")
showtext_auto()

df <- read.csv("datasets/final_dataset_fixed.csv")

# 1. Heatmap of interactions
interaction_matrix <- df %>% 
  count(Character1, Character2) %>%
  spread(key = Character2, value = n, fill = 0)

interaction_matrix_melted <- interaction_matrix %>%
  gather(key = "Character2", value = "value", -Character1)

ggplot(interaction_matrix_melted, aes(x = Character1, y = Character2, fill = value)) +
  geom_tile(color = "white", size = 0.5) +
  scale_fill_gradient(low = "lightblue", high = "darkblue") +
  labs(
    title = "Interaction Heatmap", 
    x = "Character 1", 
    y = "Character 2"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5, family = "montserrat"),
    axis.title = element_text(size = 14, family = "montserrat"),
    axis.text.x = element_text(angle = 90, hjust = 1, size = 12, family = "montserrat"),
    axis.text.y = element_text(size = 12, family = "montserrat"),
    legend.title = element_text(size = 12, family = "montserrat"),
    legend.text = element_text(size = 10, family = "montserrat")
  )





# 2. Network Interactions
df <- df %>%
  mutate(
    Episode_Numeric = ifelse(grepl("\\(S\\)", Episode),
                             as.numeric(gsub(" \\(S\\)", "", Episode)),
                             as.numeric(Episode)),
    Season = ifelse(grepl("\\(S\\)", Episode), "Season 2", "Season 1")
  )

interactions_by_episode <- df %>%
  group_by(Episode_Numeric, Season) %>%
  summarise(interactions = n()) %>%
  ungroup()

ggplot(interactions_by_episode, aes(x = Episode_Numeric, y = interactions, color = Season)) +
  geom_line(size = 1.2) +
  geom_point(size = 2.5) +
  geom_vline(xintercept = max(interactions_by_episode$Episode_Numeric[interactions_by_episode$Season == "Season 1"]),
             linetype = "dashed", color = "#1B4F72") +
  annotate("text", x = max(interactions_by_episode$Episode_Numeric[interactions_by_episode$Season == "Season 1"]) - 10,
           y = max(interactions_by_episode$interactions), 
           label = "End of Season 1", color = "#1B4F72", angle = 90, vjust = -0.5, size = 4, family = "Montserrat") +
  labs(
    title = "Changes in Interaction Count per Episode",
    x = "Episode",
    y = "Number of Interactions",
    color = "Season"
  ) +
  scale_color_manual(values = c("Season 1" = "#85C1E9", "Season 2" = "#483199")) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 20, face = "bold", hjust = 0.5, family = "Montserrat"),
    axis.title = element_text(size = 18, family = "Montserrat"),
    axis.text = element_text(size = 16, family = "Montserrat"),
    legend.title = element_text(size = 16, family = "Montserrat"),
    legend.text = element_text(size = 14, family = "Montserrat")
  )




# 3. Network Interactions for Seasons
edges_season_1 <- df %>%
  filter(Season == "Season 1") %>%
  count(Character1, Character2) %>%
  rename(weight = n)

edges_season_2 <- df %>%
  filter(Season == "Season 2") %>%
  count(Character1, Character2) %>%
  rename(weight = n)

graph_season_1 <- graph_from_data_frame(edges_season_1, directed = FALSE)
graph_season_2 <- graph_from_data_frame(edges_season_2, directed = FALSE)

ggraph(graph_season_1, layout = "fr") +
  geom_edge_link(aes(edge_width = weight, edge_alpha = weight), color = "blue") +
  geom_node_point(aes(size = degree(graph_season_1)), color = "blue") +
  geom_node_text(aes(label = name), repel = TRUE, size = 5.2, family = "montserrat") + 
  labs(
    title = "Network Interactions: Season 1",
    subtitle = "Edge weight = number of interactions",
    size = "Node degree"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 20.8, face = "bold", hjust = 0.5, family = "montserrat"),
    plot.subtitle = element_text(size = 15.6, face = "italic", hjust = 0.5, family = "montserrat"),
    legend.title = element_text(size = 15.6, family = "montserrat"),
    legend.text = element_text(size = 13, family = "montserrat")
  )

ggraph(graph_season_2, layout = "fr") +
  geom_edge_link(aes(edge_width = weight, edge_alpha = weight), color = "red") +
  geom_node_point(aes(size = degree(graph_season_2)), color = "red") +
  geom_node_text(aes(label = name), repel = TRUE, size = 5.2, family = "montserrat") +
  labs(
    title = "Network Interactions: Season 2",
    subtitle = "Edge weight = number of interactions",
    size = "Node degree"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 20.8, face = "bold", hjust = 0.5, family = "montserrat"),
    plot.subtitle = element_text(size = 15.6, face = "italic", hjust = 0.5, family = "montserrat"),
    legend.title = element_text(size = 15.6, family = "montserrat"),
    legend.text = element_text(size = 13, family = "montserrat")
  )






# 4. Frequency of Tags
tags_split <- df %>%
  separate_rows(Relationship, sep = ",\\s*")

tags_count <- tags_split %>%
  group_by(Relationship) %>%
  summarise(count = n()) %>%
  arrange(desc(count))

ggplot(tags_count, aes(x = reorder(Relationship, count), y = count, fill = count)) +
  geom_col() +
  coord_flip() +
  scale_fill_gradient(low = "#85C1E9", high = "#2874A6") +
  labs(
    title = "Frequency of Individual Tags",
    x = "Tag",
    y = "Frequency"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 20.8, face = "bold", hjust = 0.5, family = "montserrat"),
    axis.title = element_text(size = 15.6, family = "montserrat"),
    axis.text.x = element_text(size = 13, family = "montserrat"),
    axis.text.y = element_text(size = 13, family = "montserrat"),
    legend.title = element_text(size = 15.6, family = "montserrat"),
    legend.text = element_text(size = 13, family = "montserrat")
  )








# 5. Conflicts
df <- df %>%
  mutate(
    Episode_Numeric = ifelse(grepl("\\(S\\)", Episode), 
                             as.numeric(gsub(" \\(S\\)", "", Episode)), 
                             as.numeric(Episode)),
    Season = ifelse(grepl("\\(S\\)", Episode), "Season 2", "Season 1"),
    pair = paste(Character1, "&", Character2, sep = " ")
  )

plot_data_season1 <- df %>%
  filter(Season == "Season 1", !is.na(Episode_Numeric)) %>%
  mutate(
    Tag_Type = ifelse(Tag_Type == "Temporary", "Conflict", "Stable")
  )

plot_data_season2 <- df %>%
  filter(Season == "Season 2", !is.na(Episode_Numeric)) %>%
  mutate(
    Tag_Type = ifelse(Tag_Type == "Temporary", "Conflict", "Stable")
  )

plot_season1 <- ggplot(plot_data_season1, aes(x = Episode_Numeric, y = pair)) +
  geom_point(aes(
    color = Tag_Type, 
    size = nchar(Network_Changes)
  ), alpha = 0.7) +
  scale_color_manual(values = c("Conflict" = "#2E86C1", "Stable" = "gray")) +
  labs(
    title = "Conflict Outbreaks",
    subtitle = "Character conflict dynamics",
    x = "Episode",
    y = "Character Pair",
    color = "Tag Type",
    size = "Change Length"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 20.8, face = "bold", hjust = 0.5, family = "montserrat"),
    plot.subtitle = element_text(size = 15.6, face = "italic", hjust = 0.5, family = "montserrat"),
    axis.title = element_text(size = 15.6, family = "montserrat"),
    axis.text.x = element_text(size = 13, family = "montserrat"),
    axis.text.y = element_text(size = 13, family = "montserrat"),
    legend.title = element_text(size = 15.6, family = "montserrat"),
    legend.text = element_text(size = 13, family = "montserrat")
  )

plot_season2 <- ggplot(plot_data_season2, aes(x = Episode_Numeric, y = pair)) +
  geom_point(aes(
    color = Tag_Type, 
    size = nchar(Network_Changes)
  ), alpha = 0.7) +
  scale_color_manual(values = c("Conflict" = "#2E86C1", "Stable" = "gray")) +
  labs(
    title = "Conflict Outbreaks",
    subtitle = "Character conflict dynamics",
    x = "Episode",
    y = "Character Pair",
    color = "Tag Type",
    size = "Change Length"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 20.8, face = "bold", hjust = 0.5, family = "montserrat"),
    plot.subtitle = element_text(size = 15.6, face = "italic", hjust = 0.5, family = "montserrat"),
    axis.title = element_text(size = 15.6, family = "montserrat"),
    axis.text.x = element_text(size = 13, family = "montserrat"),
    axis.text.y = element_text(size = 13, family = "montserrat"),
    legend.title = element_text(size = 15.6, family = "montserrat"),
    legend.text = element_text(size = 13, family = "montserrat")
  )

print(plot_season1)
print(plot_season2)

  
  
  
  
  
  
  
  
# 6. Interactions between clans and teams
season1_data <- df %>%
  filter(Season == "Season 1")

season2_data <- df %>%
  filter(Season == "Season 2")

prepare_clan_data <- function(data) {
  data %>%
    mutate(
      Clan_Pair = paste(Clan_Character1, "&", Clan_Character2),
      length_change = str_length(Network_Changes),
      Tag_Type = ifelse(Tag_Type == "Temporary", "Conflict", "Stable")
    ) %>%
    group_by(Clan_Pair, Episode_Numeric, Tag_Type) %>%
    summarise(
      interactions = n(),
      avg_length_change = mean(length_change, na.rm = TRUE)
    ) %>%
    ungroup()
}

prepare_group_data <- function(data) {
  data %>%
    mutate(
      Group_Pair = paste(Group_Character1, "&", Group_Character2),
      length_change = str_length(Network_Changes),
      Tag_Type = ifelse(Tag_Type == "Temporary", "Conflict", "Stable")
    ) %>%
    group_by(Group_Pair, Episode_Numeric, Tag_Type) %>%
    summarise(
      interactions = n(),
      avg_length_change = mean(length_change, na.rm = TRUE)
    ) %>%
    ungroup()
}

clan_data_season1 <- prepare_clan_data(season1_data)
clan_data_season2 <- prepare_clan_data(season2_data)

group_data_season1 <- prepare_group_data(season1_data)
group_data_season2 <- prepare_group_data(season2_data)

plot_interactions <- function(data, title, y_label) {
  ggplot(data, aes(x = Episode_Numeric, y = !!sym(y_label))) +
    geom_point(aes(
      size = avg_length_change,
      color = Tag_Type
    ), alpha = 0.8) +
    scale_color_manual(
      values = c("Stable" = "gray", "Conflict" = "#2E86C1"),
      name = "Tag Type"
    ) +
    labs(
      title = title,
      subtitle = "Types of tags and changes across episodes",
      x = "Episode",
      y = y_label,
      size = "Average change length"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 20.8, face = "bold", hjust = 0.5, family = "montserrat"),
      plot.subtitle = element_text(size = 15.6, face = "italic", hjust = 0.5, family = "montserrat"),
      axis.title = element_text(size = 15.6, family = "montserrat"),
      axis.text.x = element_text(size = 13, family = "montserrat"),
      axis.text.y = element_text(size = 13, family = "montserrat"),
      legend.title = element_text(size = 15.6, family = "montserrat"),
      legend.text = element_text(size = 13, family = "montserrat")
    )
}

plot_clan_season1 <- plot_interactions(clan_data_season1, "Clan Interactions: Season 1", "Clan_Pair")
plot_clan_season2 <- plot_interactions(clan_data_season2, "Clan Interactions: Season 2", "Clan_Pair")

plot_group_season1 <- plot_interactions(group_data_season1, "Team Interactions: Season 1", "Group_Pair")
plot_group_season2 <- plot_interactions(group_data_season2, "Team Interactions: Season 2", "Group_Pair")

print(plot_clan_season1)
print(plot_clan_season2)
print(plot_group_season1)
print(plot_group_season2)

  
  
  
  
  
  
# 7. Comparison of Degree and Betweenness Centrality
ggplot(df, aes(x = Degree_Centrality, y = Betweenness_Centrality, color = Clan_Character1)) +
  geom_point(size = 3, alpha = 0.8) +
  labs(
    title = "Comparison of Degree and Betweenness Centrality",
    x = "Degree Centrality",
    y = "Betweenness Centrality"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 20.8, face = "bold", hjust = 0.5, family = "montserrat"),
    axis.title = element_text(size = 15.6, family = "montserrat"),
    axis.text = element_text(size = 13, family = "montserrat"),
    legend.title = element_text(size = 15.6, family = "montserrat"),
    legend.text = element_text(size = 13, family = "montserrat")
  )

arc_data <- df %>%
  group_by(Arc, Character1) %>%
  summarise(avg_degree = mean(Degree_Centrality, na.rm = TRUE)) %>%
  ungroup()

arc_order <- c(
  "Prologue — Land of Waves", "Chunin Exams", "Konoha Crush", 
  "Search for Tsunade", "Sasuke Recovery Mission", 
  "Kazekage Rescue Mission", "Tenchi Bridge Reconnaissance Mission", 
  "Tale of Jiraiya the Gallant", "Itachi Pursuit Mission", 
  "Fated Battle Between Brothers", "Pain's Assault", 
  "Five Kage Summit", "Fourth Shinobi World War: Countdown", 
  "Fourth Shinobi World War: Confrontation", 
  "Fourth Shinobi World War: Climax", "Birth of the Ten-Tails Jinchuriki", 
  "Kaguya Ōtsutsuki Strikes", "Konoha Hiden: The Perfect Day for a Wedding"
)

arc_data <- arc_data %>%
  mutate(Arc = factor(Arc, levels = arc_order))

ggplot(arc_data, aes(x = Arc, y = avg_degree, group = Character1, color = Character1)) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  labs(
    title = "Dynamics of Degree Centrality Across Arcs",
    x = "Arc",
    y = "Average Degree Centrality",
    color = "Character"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, family = "montserrat", size = 13),
    plot.title = element_text(size = 20.8, face = "bold", hjust = 0.5, family = "montserrat"),
    axis.title = element_text(size = 15.6, family = "montserrat"),
    legend.title = element_text(size = 15.6, family = "montserrat"),
    legend.text = element_text(size = 13, family = "montserrat")
  )

plot_degree_betweenness <- ggplot(df, aes(x = Degree_Centrality, y = Betweenness_Centrality)) +
  geom_point(color = "blue", alpha = 0.6) +
  geom_smooth(method = "lm", color = "red", se = FALSE) +
  labs(
    title = "Degree vs Betweenness Centrality",
    x = "Degree Centrality",
    y = "Betweenness Centrality"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 20.8, face = "bold", hjust = 0.5, family = "montserrat"),
    axis.title = element_text(size = 15.6, family = "montserrat"),
    axis.text = element_text(size = 13, family = "montserrat")
  )

plot_degree_closeness <- ggplot(df, aes(x = Degree_Centrality, y = Closeness_Centrality)) +
  geom_point(color = "green", alpha = 0.6) +
  geom_smooth(method = "lm", color = "red", se = FALSE) +
  labs(
    title = "Degree vs Closeness Centrality",
    x = "Degree Centrality",
    y = "Closeness Centrality"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 20.8, face = "bold", hjust = 0.5, family = "montserrat"),
    axis.title = element_text(size = 15.6, family = "montserrat"),
    axis.text = element_text(size = 13, family = "montserrat")
  )

plot_betweenness_closeness <- ggplot(df, aes(x = Betweenness_Centrality, y = Closeness_Centrality)) +
  geom_point(color = "purple", alpha = 0.6) +
  geom_smooth(method = "lm", color = "red", se = FALSE) +
  labs(
    title = "Betweenness vs Closeness Centrality",
    x = "Betweenness Centrality",
    y = "Closeness Centrality"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 20.8, face = "bold", hjust = 0.5, family = "montserrat"),
    axis.title = element_text(size = 15.6, family = "montserrat"),
    axis.text = element_text(size = 13, family = "montserrat")
  )

plot_combined <- plot_degree_betweenness + plot_degree_closeness + plot_betweenness_closeness +
  plot_layout(ncol = 1, guides = "collect") &
  theme(
    plot.title = element_text(hjust = 0.5, size = 20.8, face = "bold", family = "montserrat")
  )

print(plot_combined)

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
# 8. Key Events Log Analysis of Interactions
plot_data <- df %>%
  mutate(
    pair = paste(Character1, "&", Character2, sep = " "), 
    Key_Event_Flag = ifelse(Key_Event_Flag == "Yes", TRUE, FALSE)
  )

plot <- ggplot(plot_data, aes(x = as.numeric(Episode), y = pair)) +
  geom_point(aes(
    color = Key_Event_Flag, 
    text = paste(
      "Character Pair: ", pair, "<br>",
      "Episode: ", Episode, "<br>",
      "Changes: ", Network_Changes, "<br>",
      "Key Event: ", Key_Event_Flag
    )  
  ), size = 3, alpha = 0.8) +
  scale_color_manual(
    values = c("FALSE" = "gray", "TRUE" = "red"),
    name = "Key Event"
  ) +
  labs(
    title = "Interactive Character Interaction Dynamics",
    x = "Episode",
    y = "Character Pair"
  ) +
  theme_minimal()

ggplotly(plot, tooltip = "text")

plot_data_season2 <- df %>%
  filter(grepl("\\(S\\)", Episode)) %>% 
  mutate(
    Episode = as.numeric(gsub(" \\(S\\)", "", Episode)),
    pair = paste(Character1, "&", Character2, sep = " "),
    Key_Event_Flag = ifelse(Key_Event_Flag == "Yes", TRUE, FALSE)
  )

plot_season2 <- ggplot(plot_data_season2, aes(x = Episode, y = pair)) +
  geom_point(aes(
    color = Key_Event_Flag, 
    text = paste(
      "Character Pair: ", pair, "<br>",
      "Episode: ", Episode, "<br>",
      "Changes: ", Network_Changes, "<br>",
      "Key Event: ", ifelse(Key_Event_Flag, "TRUE", "FALSE")
    )
  ), size = 3, alpha = 0.8) +
  scale_color_manual(
    values = c("FALSE" = "gray", "TRUE" = "red"),
    name = "Key Event"
  ) +
  labs(
    title = "Interactive Character Interaction Dynamics (Season 2)",
    x = "Episode",
    y = "Character Pair"
  ) +
  theme_minimal()

ggplotly(plot_season2, tooltip = "text")
