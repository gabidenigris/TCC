# =============================================================
# painel_rais.R (definitivo: base microdados_vinculos)
# Painel UF x CNAE classe (2019-2025) para o DiD da Taxa das Blusinhas
# Motivo da migracao: em estabelecimentos, o ano-base 2025 veio sem
# classificacao setorial; em vinculos, a subclasse esta integra.
# Metricas: vinculos ativos em 31/12 e massa salarial (remuneracao media).
#
# ATUALIZACAO (v5): nucleo + extensao nos dois lados.
#   Tratado nucleo   : div 14; grupos 13.5, 15.2, 15.3, 32.1, 32.3, 32.4
#   Tratado extensao : grupo 26.4; classes 26.52, 27.40, 27.59
#   Controle nucleo  : div 31 (moveis), 21 (farma), 10 e 11 (alim./bebidas)
#   Controle extensao: div 16, 17, 23, 28; div 22 exceto 22.29;
#                      div 25 exceto 25.50 e 25.93
# A coluna 'bloco' permite rodar a especificacao principal com
# filter(bloco == "nucleo") e usar a extensao so na robustez.
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
# (d) a tag de versao no comentario evita cache de resultado antigo.
query_painel <- sprintf("
-- v5 nucleo+extensao 2026-08
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
    -- tratado extensao: grupo 26.4; classes 26.52, 27.40, 27.59
    OR REGEXP_CONTAINS(dados.cnae_2_subclasse, r'^(264|2652|2740|2759)')
    -- controle nucleo: div 31, 21, 10, 11
    OR REGEXP_CONTAINS(dados.cnae_2_subclasse, r'^(31|21|10|11)')
    -- controle extensao: div 16, 17, 23, 28
    OR REGEXP_CONTAINS(dados.cnae_2_subclasse, r'^(16|17|23|28)')
    -- controle extensao: div 22 sem 22.29 (utilidades domesticas de plastico)
    OR (dados.cnae_2_subclasse LIKE '22%%'
        AND dados.cnae_2_subclasse NOT LIKE '2229%%')
    -- controle extensao: div 25 sem 25.50 (armas) e 25.93 (utensilios)
    OR (dados.cnae_2_subclasse LIKE '25%%'
        AND dados.cnae_2_subclasse NOT LIKE '2550%%'
        AND dados.cnae_2_subclasse NOT LIKE '2593%%')
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
# Ordem importa: as regras de tratado vem antes, e as classes 26.52,
# 27.40 e 27.59 sao testadas antes de qualquer regra de divisao.
# Sem categoria residual: o case_when espelha exatamente o filtro do SQL.
dados_painel <- dados_painel %>%
  mutate(
    grupo = case_when(
      grepl("^14", cnae_2)                          ~ "tratado_nucleo",
      grepl("^(135|152|153|321|323|324)", cnae_2)   ~ "tratado_nucleo",
      grepl("^(264|2652|2740|2759)", cnae_2)        ~ "tratado_extensao",
      grepl("^31", cnae_2)                          ~ "controle_moveis",
      grepl("^21", cnae_2)                          ~ "controle_farma",
      grepl("^(10|11)", cnae_2)                     ~ "controle_alimentos",
      grepl("^(16|17|22|23|25|28)", cnae_2)         ~ "controle_extensao",
      TRUE                                          ~ NA_character_
    ),
    bloco = case_when(
      grupo %in% c("tratado_extensao", "controle_extensao") ~ "extensao",
      TRUE                                                  ~ "nucleo"
    ),
    tratado = grupo %in% c("tratado_nucleo", "tratado_extensao")
  )

# Trava: nenhum CNAE pode escapar da classificacao
if (any(is.na(dados_painel$grupo))) {
  stop("CNAEs sem grupo definido: ",
       paste(unique(dados_painel$cnae_2[is.na(dados_painel$grupo)]),
             collapse = ", "))
}

# Zona Franca de Manaus: o incentivo fiscal proprio e choque concomitante
# sobre os CNAEs de eletroeletronico do tratado de extensao. Como o painel
# e UF x CNAE, a exclusao operacional e por celula (AM), nao por
# estabelecimento. Flag agora, filtro na estimacao.
dados_painel <- dados_painel %>%
  mutate(risco_zfm = sigla_uf == "AM" &
           grepl("^(264|2652|2740|2759)", cnae_2))

# --- 6. Painel balanceado com zeros verdadeiros ----------------
# Massa salarial de celula sem vinculo e zero real; salario medio, NA.
dados_painel <- dados_painel %>%
  complete(
    ano = anos,
    nesting(sigla_uf, cnae_2, descricao_cnae, grupo, bloco, tratado, risco_zfm),
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

# Confirma que as classes excluidas nao entraram
stopifnot(
  !any(grepl("^(2229|2550|2593)", dados_painel$cnae_2))
)

# Vinculos por grupo e ano (teste de cheiro)
dados_painel %>%
  count(grupo, ano, wt = total_vinculos_ativos) %>%
  print(n = n_distinct(dados_painel$grupo) * length(anos))

# Tamanho relativo dos grupos no ano pre-tratamento, por bloco
dados_painel %>%
  filter(ano == 2023) %>%
  count(bloco, tratado, wt = total_vinculos_ativos) %>%
  group_by(bloco) %>%
  mutate(share = round(100 * n / sum(n), 1)) %>%
  ungroup() %>%
  print()

# Plausibilidade do ano-base 2025 (RAIS preliminar): var. % por grupo
dados_painel %>%
  filter(ano %in% c(2024, 2025)) %>%
  count(grupo, ano, wt = total_vinculos_ativos) %>%
  pivot_wider(names_from = ano, values_from = n, names_prefix = "a") %>%
  mutate(var_pct = round(100 * (a2025 / a2024 - 1), 1)) %>%
  print()

# --- 8. Salvar --------------------------------------------------
saveRDS(dados_painel, "painel_nucleo_extensao.rds")
cat("Painel salvo |", nrow(dados_painel), "linhas |",
    n_distinct(dados_painel$sigla_uf), "UFs |",
    n_distinct(dados_painel$cnae_2), "classes CNAE\n")


file.exists("painel_nucleo_extensao.rds")   # deve retornar TRUE

painel <- readRDS("painel_extensao.rds")
glimpse(painel)                            # estrutura: colunas e tipos
View(painel)                               # abre o visualizador do RStudio

library(readr)

# Para Excel em portugues (separador ; e decimal com virgula)
write_csv2(readRDS("painel_nucleo_extensao.rds"), "painel_nucleo_extensao.csv")
