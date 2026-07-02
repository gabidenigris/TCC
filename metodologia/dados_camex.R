# =============================================================================
# TCC — Impacto da Taxa das Blusinhas sobre o Comércio Brasileiro
# Script: dados_camex.R
# Última atualização: maio/2026
# Fonte de dados: CAMEX/MDIC — Comex Stat (base bruta por NCM)
# =============================================================================

# 0. Pacotes ────────────────────────────────────────────────────────────────

install.packages(c("readxl", "tidyverse", "writexl", "here", "scales", "patchwork"))

library(readxl)
library(tidyverse)
library(writexl)
library(here)
library(scales)
library(patchwork)

# 1. Função de padronização de tipos ───────────────────────────────────────

padronizar <- function(df) {
  df %>%
    mutate(
      CO_ANO     = as.integer(CO_ANO),
      CO_MES     = as.integer(CO_MES),
      CO_NCM     = as.character(CO_NCM),
      CO_UNID    = as.integer(CO_UNID),
      CO_PAIS    = as.character(CO_PAIS),
      QT_ESTAT   = as.numeric(QT_ESTAT),
      KG_LIQUIDO = as.numeric(KG_LIQUIDO),
      VL_FOB     = as.numeric(VL_FOB),
      VL_FRETE   = as.numeric(VL_FRETE),
      VL_SEGURO  = as.numeric(VL_SEGURO)
    )
}

# 2. Importação dos dados brutos (CAMEX) ────────────────────────────────────

IMP_2022 <- read_delim(here("data", "IMP_2022.csv"), delim = ";", trim_ws = TRUE) %>% padronizar()
IMP_2023 <- read_delim(here("data", "IMP_2023.csv"), delim = ";", trim_ws = TRUE) %>% padronizar()
IMP_2024 <- read_delim(here("data", "IMP_2024.csv"), delim = ";", trim_ws = TRUE) %>% padronizar()
IMP_2025 <- read_delim(here("data", "IMP_2025.csv"), delim = ";", trim_ws = TRUE) %>% padronizar()

# 3. Consolidação e filtro do período (ago/2022 a ago/2025) ─────────────────

IMP_CONSOLIDADO <- bind_rows(IMP_2022, IMP_2023, IMP_2024, IMP_2025) %>%
  filter(
    (CO_ANO > 2022) | (CO_ANO == 2022 & CO_MES >= 8)
  ) %>%
  filter(
    (CO_ANO < 2025) | (CO_ANO == 2025 & CO_MES <= 8)
  ) %>%
  select(-CO_VIA, -CO_URF)

# Checagem do período coberto
IMP_CONSOLIDADO %>%
  summarise(
    ano_min      = min(CO_ANO),
    mes_min      = min(CO_MES[CO_ANO == min(CO_ANO)]),
    ano_max      = max(CO_ANO),
    mes_max      = max(CO_MES[CO_ANO == max(CO_ANO)]),
    total_linhas = n()
  )

# 4. Tabelas auxiliares (NCM e países) ──────────────────────────────────────
# Fonte: CAMEX — arquivo TABELAS_AUXILIARES.xlsx
# Aba 1  = SH (descrições NCM)
# Aba 10 = Países
# Aba 11 = Blocos de países

tab_ncm   <- read_excel(here("data", "TABELAS_AUXILIARES.xlsx"), sheet = "1")
tab_pais  <- read_excel(here("data", "TABELAS_AUXILIARES.xlsx"), sheet = "10")
tab_bloco <- read_excel(here("data", "TABELAS_AUXILIARES.xlsx"), sheet = "11")

# 5. Joins com tabelas auxiliares ──────────────────────────────────────────

IMP_CONSOLIDADO <- IMP_CONSOLIDADO %>%
  mutate(CO_PAIS = as.character(CO_PAIS)) %>%
  left_join(
    tab_ncm %>% select(CO_NCM, NO_NCM_POR, CO_SH2, NO_SH2_POR, NO_SEC_POR),
    by = "CO_NCM"
  ) %>%
  left_join(
    tab_pais %>% select(CO_PAIS, NO_PAIS),
    by = "CO_PAIS"
  )

# 6. Filtro de capítulos SH2 relevantes ────────────────────────────────────
# Capítulos selecionados por relevância para o comércio eletrônico
# (blusinhas, eletrônicos, calçados, acessórios, têxteis)

SH2_RELEVANTES <- c("39", "42", "61", "62", "63", "64", "85")

# 7. Agregação mensal por capítulo SH2 ──────────────────────

mensal_ncm <- IMP_CONSOLIDADO %>%
  filter(CO_SH2 %in% SH2_RELEVANTES) %>%
  mutate(data = as.Date(paste(CO_ANO, sprintf("%02d", CO_MES), "01", sep = "-"))) %>%
  group_by(data, CO_ANO, CO_MES, CO_SH2, NO_SH2_POR) %>%
  summarise(
    vl_fob_total       = sum(VL_FOB,     na.rm = TRUE),
    kg_total           = sum(KG_LIQUIDO, na.rm = TRUE),
    n_registros        = n(),
    .groups            = "drop"
  ) %>%
  mutate(
    # valor médio FOB por kg (proxy de preço implícito)
    valor_medio_fob_kg = ifelse(kg_total > 0, vl_fob_total / kg_total, NA_real_)
  ) %>%
  arrange(CO_SH2, data)

# 8. Janelas de 12 meses com início em agosto ──────────────
# Janela A: ago/2022–jul/2023 → pré-PRC
# Janela B: ago/2023–jul/2024 → PRC vigente, II = 0% até US$50
# Janela C: ago/2024–jul/2025 → PRC vigente, II = 20% (Lei nº 14.902/2024)

mensal_ncm <- mensal_ncm %>%
  mutate(
    janela = case_when(
      data >= as.Date("2022-08-01") & data <= as.Date("2023-07-01") ~ "A: ago/22–jul/23 (pré-PRC)",
      data >= as.Date("2023-08-01") & data <= as.Date("2024-07-01") ~ "B: ago/23–jul/24 (PRC sem II)",
      data >= as.Date("2024-08-01") & data <= as.Date("2025-07-01") ~ "C: ago/24–jul/25 (PRC com II 20%)",
      TRUE ~ NA_character_
    )
  )

# 9. Acumulado por janela  ───────────────────────

acumulado_janela <- mensal_ncm %>%
  filter(!is.na(janela)) %>%
  group_by(janela, CO_SH2, NO_SH2_POR) %>%
  summarise(
    vl_fob_acum      = sum(vl_fob_total, na.rm = TRUE),
    kg_acum          = sum(kg_total,     na.rm = TRUE),
    valor_medio_acum = vl_fob_acum / kg_acum,
    n_meses          = n(),
    .groups          = "drop"
  ) %>%
  arrange(CO_SH2, janela)

# 10. Variação % entre janelas ───────────────────────────────────

variacao <- acumulado_janela %>%
  mutate(janela_id = str_sub(janela, 1, 1)) %>%
  select(janela_id, CO_SH2, setor = NO_SH2_POR,
         vl_fob_acum, kg_acum, valor_medio_acum) %>%
  pivot_wider(
    names_from  = janela_id,
    values_from = c(vl_fob_acum, kg_acum, valor_medio_acum)
  ) %>%
  mutate(
    var_fob_AB = (vl_fob_acum_B - vl_fob_acum_A) / vl_fob_acum_A * 100,
    var_fob_BC = (vl_fob_acum_C - vl_fob_acum_B) / vl_fob_acum_B * 100,
    var_kg_AB  = (kg_acum_B - kg_acum_A) / kg_acum_A * 100,
    var_kg_BC  = (kg_acum_C - kg_acum_B) / kg_acum_B * 100,
    var_vm_AB  = (valor_medio_acum_B - valor_medio_acum_A) / valor_medio_acum_A * 100,
    var_vm_BC  = (valor_medio_acum_C - valor_medio_acum_B) / valor_medio_acum_B * 100
  ) %>%
  select(CO_SH2, setor, starts_with("var_")) %>%
  mutate(across(starts_with("var_"), ~ round(., 1)))

print(variacao)

# ── 11. Gráficos ───────────────────────────────────────────────────

# Paleta de cores consistente para os 4 capítulos principais
cores_sh2 <- c(
  "Vestuário Malha (61)"        = "#1f77b4",
  "Vestuário Exceto Malha (62)" = "#2ca02c",
  "Eletrônicos (85)"            = "#d62728",
  "Bolsas/Acessórios (42)"      = "#9467bd"
)

# Helper: adiciona as linhas de marco regulatório
marcos <- list(
  geom_vline(xintercept = as.Date("2023-08-01"),
             linetype = "dashed", color = "gray50", linewidth = 0.7),
  geom_vline(xintercept = as.Date("2024-08-01"),
             linetype = "dashed", color = "red", linewidth = 0.7),
  annotate("text", x = as.Date("2023-08-01"), y = Inf,
           label = "Início PRC\n(ago/2023)", hjust = -0.08, vjust = 1.4,
           size = 3, color = "gray40"),
  annotate("text", x = as.Date("2024-08-01"), y = Inf,
           label = "Taxa II 20%\n(ago/2024)", hjust = -0.08, vjust = 1.4,
           size = 3, color = "red")
)

tema_base <- theme_minimal(base_size = 11) +
  theme(
    axis.text.x      = element_text(angle = 45, hjust = 1),
    legend.position  = "bottom",
    plot.title       = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

# Gráfico 1: Valor médio FOB/kg (4 capítulos principais) ------------------

mensal_ncm %>%
  filter(CO_SH2 %in% c("61", "62", "85", "42")) %>%
  mutate(setor = case_when(
    CO_SH2 == "61" ~ "Vestuário Malha (61)",
    CO_SH2 == "62" ~ "Vestuário Exceto Malha (62)",
    CO_SH2 == "85" ~ "Eletrônicos (85)",
    CO_SH2 == "42" ~ "Bolsas/Acessórios (42)"
  )) %>%
  ggplot(aes(x = data, y = valor_medio_fob_kg, color = setor)) +
  geom_line(linewidth = 0.9) +
  marcos +
  scale_x_date(date_labels = "%b/%Y", date_breaks = "3 months") +
  scale_y_continuous(labels = dollar_format(prefix = "US$ ", suffix = "/kg"),
                     limits = c(0, NA)) +
  scale_color_manual(values = cores_sh2) +
  labs(
    title   = "Valor Médio FOB por Kg — Importações Brasileiras Selecionadas",
    subtitle = "Capítulos relevantes para o comércio eletrônico transfronteiriço (ago/2022 – ago/2025)",
    x       = NULL, y = "Valor médio FOB (USD/kg)", color = "Capítulo SH2",
    caption = "Fonte: CAMEX/MDIC — Comex Stat."
  ) +
  tema_base

ggsave(here("output", "grafico_valor_medio_sem_calcados.png"),
       width = 10, height = 6, dpi = 300)

# Gráfico 2: Volume (kg) por capítulo —-------------

mensal_ncm %>%
  filter(CO_SH2 %in% c("61", "62", "85", "42")) %>%
  mutate(
    setor      = case_when(
      CO_SH2 == "61" ~ "Vestuário Malha (61)",
      CO_SH2 == "62" ~ "Vestuário Exceto Malha (62)",
      CO_SH2 == "85" ~ "Eletrônicos (85)",
      CO_SH2 == "42" ~ "Bolsas/Acessórios (42)"
    ),
    kg_milhoes = kg_total / 1e6
  ) %>%
  ggplot(aes(x = data, y = kg_milhoes, color = setor)) +
  geom_line(linewidth = 0.9) +
  geom_vline(xintercept = as.Date("2023-08-01"),
             linetype = "dashed", color = "gray50", linewidth = 0.6) +
  geom_vline(xintercept = as.Date("2024-08-01"),
             linetype = "dashed", color = "red", linewidth = 0.6) +
  scale_x_date(date_labels = "%b/%Y", date_breaks = "6 months") +
  scale_y_continuous(labels = label_number(suffix = " M kg")) +
  scale_color_manual(values = cores_sh2) +
  facet_wrap(~ setor, scales = "free_y", ncol = 2) +
  labs(
    title    = "Volume Importado (kg) por Capítulo SH2",
    subtitle = "Escala independente por painel — ago/2022 a ago/2025",
    x        = NULL, y = "Volume (milhões de kg)",
    caption  = "Fonte: CAMEX/MDIC — Comex Stat.\nLinhas tracejadas: Início do PRC (ago/2023) e Taxa II 20% (ago/2024)."
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position  = "none",
    axis.text.x      = element_text(angle = 45, hjust = 1, size = 8),
    plot.title       = element_text(face = "bold"),
    panel.grid.minor = element_blank(),
    strip.text       = element_text(face = "bold", size = 10)
  )

ggsave(here("output", "grafico_volume_facet.png"),
       width = 11, height = 7, dpi = 300)

# Gráfico 3: Calçados — duplo painel (valor médio + volume) ----------------

p_vm_calcados <- mensal_ncm %>%
  filter(CO_SH2 == "64") %>%
  ggplot(aes(x = data, y = valor_medio_fob_kg)) +
  geom_line(linewidth = 0.9, color = "#e6a817") +
  marcos +
  scale_x_date(date_labels = "%b/%Y", date_breaks = "3 months") +
  scale_y_continuous(labels = dollar_format(prefix = "US$ ", suffix = "/kg")) +
  labs(title = "Calçados (Cap. 64) — Valor Médio FOB/kg",
       subtitle = "ago/2022 – ago/2025",
       x = NULL, y = "Valor médio FOB (USD/kg)",
       caption = "Fonte: CAMEX/MDIC — Comex Stat. Elaboração própria.") +
  tema_base + theme(legend.position = "none")

p_kg_calcados <- mensal_ncm %>%
  filter(CO_SH2 == "64") %>%
  mutate(kg_milhoes = kg_total / 1e6) %>%
  ggplot(aes(x = data, y = kg_milhoes)) +
  geom_line(linewidth = 0.9, color = "#e6a817") +
  geom_vline(xintercept = as.Date("2023-08-01"),
             linetype = "dashed", color = "gray50", linewidth = 0.7) +
  geom_vline(xintercept = as.Date("2024-08-01"),
             linetype = "dashed", color = "red", linewidth = 0.7) +
  scale_x_date(date_labels = "%b/%Y", date_breaks = "3 months") +
  scale_y_continuous(labels = label_number(suffix = " M kg")) +
  labs(x = NULL, y = "Volume (milhões de kg)",
       caption = "Fonte: CAMEX/MDIC — Comex Stat. Elaboração própria.") +
  tema_base + theme(legend.position = "none")

p_vm_calcados / p_kg_calcados

ggsave(here("output", "grafico_calcados_duplo.png"),
       width = 10, height = 8, dpi = 300)