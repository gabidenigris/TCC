# =============================================================
# 01_painel_did.R (definitivo: base microdados_vinculos)
# Painel UF x CNAE classe (2019-2025) para o DiD da Taxa das Blusinhas
# Motivo da migracao: em estabelecimentos, o ano-base 2025 veio sem
# classificacao setorial; em vinculos, a subclasse esta integra.
# Metricas: vinculos ativos em 31/12 e massa salarial (remuneracao media).
# Protecoes: janela parametrizada, bypass de cache, tipos integer64,
# trava de anos antes do complete(), plausibilidade do 2025 preliminar.
# =============================================================

library(basedosdados)
library(dplyr)
library(tidyr)

set_billing_id("taxa-das-blusinhas")

# --- 0. Parametros ---------------------------------------------
anos <- 2019:2025

# --- 1. Query --------------------------------------------------
# Notas tecnicas:
# (a) vinculo_ativo_3112 e STRING na base: comparar com '1'.
# (b) cnae_2 (classe) e derivada da subclasse: SUBSTR(subclasse, 1, 5),
#     compativel com o dicionario (classe de 4 digitos + verificador).
# (c) filtros de prefixo aplicados sobre a subclasse (7 digitos):
#     2 dig = divisao, 3 = grupo, 4 = classe.
# (d) tag de versao no comentario invalida o cache do BigQuery.
query_painel <- sprintf("
-- v3 vinculos 2025-07
SELECT
    dados.ano AS ano,
    dados.sigla_uf AS sigla_uf,
    SUBSTR(dados.cnae_2_subclasse, 1, 5) AS cnae_2,
    COUNT(*) AS total_vinculos_ativos,
    SUM(dados.valor_remuneracao_media) AS massa_salarial
FROM `basedosdados.br_me_rais.microdados_vinculos` AS dados
WHERE dados.ano BETWEEN %d AND %d
  AND dados.vinculo_ativo_3112 = '1'
  AND (
    -- tratado nucleo: div 14; grupos 13.5, 15.2, 15.3, 32.1, 32.3, 32.4
    dados.cnae_2_subclasse LIKE '14%%'
    OR REGEXP_CONTAINS(dados.cnae_2_subclasse, r'^(135|152|153|321|323|324)')
    -- tratado extensao: classes 27.40, 27.59, 26.52; grupo 26.4
    OR REGEXP_CONTAINS(dados.cnae_2_subclasse, r'^(2740|2759|2652|264)')
    -- controle: div 16, 17, 23, 28; 22 sem 22.29; 25 sem 25.50 e 25.93
    OR REGEXP_CONTAINS(dados.cnae_2_subclasse, r'^(16|17|23|28)')
    OR (dados.cnae_2_subclasse LIKE '22%%'
        AND dados.cnae_2_subclasse NOT LIKE '2229%%')
    OR (dados.cnae_2_subclasse LIKE '25%%'
        AND dados.cnae_2_subclasse NOT LIKE '2550%%'
        AND dados.cnae_2_subclasse NOT LIKE '2593%%')
    -- sensibilidade: div 10 e 24 (fora da estimacao principal)
    OR dados.cnae_2_subclasse LIKE '10%%'
    OR dados.cnae_2_subclasse LIKE '24%%'
  )
GROUP BY ano, sigla_uf, cnae_2
", min(anos), max(anos))

dados_painel <- read_sql(query_painel)

# --- 2. Tipos: integer64 -> nativos ----------------------------
dados_painel <- dados_painel %>%
  mutate(
    ano = as.integer(ano),
    across(c(total_vinculos_ativos, massa_salarial), as.numeric)
  )

# --- 3. Trava de anos: ANTES do complete() ---------------------
anos_ok <- sort(unique(dados_painel$ano))
if (!identical(anos_ok, anos)) {
  stop("Anos retornados: ", paste(anos_ok, collapse = ", "),
       "\nEsperados: ", paste(anos, collapse = ", "))
}

# --- 4. Dicionario CNAE ----------------------------------------
dicionario_cnae <- read_sql("
  SELECT DISTINCT
    classe AS cnae_2,
    descricao_classe AS descricao_cnae
  FROM `basedosdados.br_bd_diretorios_brasil.cnae_2`
")

dados_painel <- dados_painel %>%
  left_join(dicionario_cnae, by = "cnae_2")

# --- 5. Classificacao de grupos --------------------------------
dados_painel <- dados_painel %>%
  mutate(
    grupo = case_when(
      grepl("^14", cnae_2) |
        grepl("^(135|152|153|321|323|324)", cnae_2) ~ "tratado_nucleo",
      grepl("^(2740|2759|2652|264)", cnae_2)        ~ "tratado_extensao",
      grepl("^(10|24)", cnae_2)                     ~ "sensibilidade",
      TRUE                                          ~ "controle"
    ),
    tratado = grupo %in% c("tratado_nucleo", "tratado_extensao")
  )

# --- 6. Painel balanceado com zeros verdadeiros ----------------
# Massa salarial de celula sem vinculo e zero real; salario medio, NA.
dados_painel <- dados_painel %>%
  complete(
    ano = anos,
    nesting(sigla_uf, cnae_2, descricao_cnae, grupo, tratado),
    fill = list(total_vinculos_ativos = 0, massa_salarial = 0)
  ) %>%
  mutate(
    post          = ano >= 2024,  # vigencia ago/2024: 2024 = exposicao parcial
    salario_medio = if_else(total_vinculos_ativos > 0,
                            massa_salarial / total_vinculos_ativos,
                            NA_real_)
  )

# --- 7. Sanity checks ------------------------------------------
stopifnot(
  n_distinct(dados_painel$ano) == length(anos),
  dados_painel %>% count(sigla_uf, cnae_2) %>%
    pull(n) %>% unique() == length(anos)
)

# Vinculos por grupo e ano (teste de cheiro)
dados_painel %>%
  count(grupo, ano, wt = total_vinculos_ativos) %>%
  print(n = 4 * length(anos))

# Plausibilidade do ano-base 2025 (RAIS preliminar): var. % por grupo
dados_painel %>%
  filter(ano %in% c(2024, 2025)) %>%
  count(grupo, ano, wt = total_vinculos_ativos) %>%
  pivot_wider(names_from = ano, values_from = n, names_prefix = "a") %>%
  mutate(var_pct = round(100 * (a2025 / a2024 - 1), 1)) %>%
  print()

# --- 8. Salvar --------------------------------------------------
saveRDS(dados_painel, "painel_did_blusinhas.rds")
cat("Painel salvo |", nrow(dados_painel), "linhas |",
    n_distinct(dados_painel$sigla_uf), "UFs |",
    n_distinct(dados_painel$cnae_2), "classes CNAE\n")


dados_painel %>% distinct(sigla_uf) %>% print(n = 28)


file.exists("painel_did_blusinhas.rds")   # deve retornar TRUE

painel <- readRDS("painel_did_blusinhas.rds")
glimpse(painel)                            # estrutura: colunas e tipos
View(painel)                               # abre o visualizador do RStudio


library(readr)

# Para Excel em portugues (separador ; e decimal com virgula)
write_csv2(readRDS("painel_did_blusinhas.rds"), "painel_did_blusinhas.csv")

# Para ferramentas que esperam CSV padrao (separador , e decimal com ponto)
# write_csv(readRDS("painel_did_blusinhas.rds"), "painel_did_blusinhas.csv")