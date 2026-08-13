# =============================================================
# painel_rais.R (definitivo: base microdados_vinculos)
# Painel UF x CNAE classe (2019-2025) para o DiD da Taxa das Blusinhas
# Motivo da migracao: em estabelecimentos, o ano-base 2025 veio sem
# classificacao setorial; em vinculos, a subclasse esta integra.
# Metricas: vinculos ativos em 31/12 e massa salarial (remuneracao media).
#
# ATUALIZACAO (v4): especificacao restrita aos grupos NUCLEO.
#   Tratado : div 14; grupos 13.5, 15.2, 15.3, 32.1, 32.3, 32.4
#   Controle: div 31 (moveis), div 21 (farma), div 10 e 11 (alimentos/bebidas)
# Saem da extracao os grupos de extensao (26.4, 26.52, 27.40, 27.59 no
# tratado; div 16, 17, 22, 23, 25, 28 no controle) e a div 24.
# Consequencia: a Zona Franca de Manaus deixa de ser ameaca ativa, pois
# nenhum CNAE de eletroeletronico permanece no tratado.
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
-- v4 nucleos 2026-08
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
    -- controle nucleo: div 31 (moveis), 21 (farma), 10 (alimentos), 11 (bebidas)
    OR REGEXP_CONTAINS(dados.cnae_2_subclasse, r'^(31|21|10|11)')
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
# Sem categoria residual: todo CNAE extraido tem regra explicita.
# alimentos_bebidas fica marcado a parte porque as divisoes 10 e 11 tem
# ciclo proprio (safra e preco de commodities), e o resultado deve ser
# reportado com e sem elas.
dados_painel <- dados_painel %>%
  mutate(
    grupo = case_when(
      grepl("^14", cnae_2)                          ~ "tratado_nucleo",
      grepl("^(135|152|153|321|323|324)", cnae_2)   ~ "tratado_nucleo",
      grepl("^31", cnae_2)                          ~ "controle_moveis",
      grepl("^21", cnae_2)                          ~ "controle_farma",
      grepl("^(10|11)", cnae_2)                     ~ "controle_alimentos",
      TRUE                                          ~ NA_character_
    ),
    tratado = grupo == "tratado_nucleo"
  )

# Trava: nenhum CNAE pode escapar da classificacao
if (any(is.na(dados_painel$grupo))) {
  stop("CNAEs sem grupo definido: ",
       paste(unique(dados_painel$cnae_2[is.na(dados_painel$grupo)]),
             collapse = ", "))
}

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
  print(n = n_distinct(dados_painel$grupo) * length(anos))

# Tamanho relativo dos grupos: tratado vs controle no ano pre-tratamento
dados_painel %>%
  filter(ano == 2023) %>%
  count(tratado, wt = total_vinculos_ativos) %>%
  mutate(share = round(100 * n / sum(n), 1)) %>%
  print()

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


file.exists("painel_did_blusinhas.rds")   # deve retornar TRUE

painel <- readRDS("painel_did_blusinhas.rds")
glimpse(painel)                            # estrutura: colunas e tipos
View(painel)                               # abre o visualizador do RStudio

library(readr)

# Para Excel em portugues (separador ; e decimal com virgula)
write_csv2(readRDS("painel_did_blusinhas.rds"), "painel_did_blusinhas.csv")
