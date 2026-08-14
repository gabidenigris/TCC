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
saveRDS(dados_painel, "painel_nucleo.rds")
cat("Painel salvo |", nrow(dados_painel), "linhas |",
    n_distinct(dados_painel$sigla_uf), "UFs |",
    n_distinct(dados_painel$cnae_2), "classes CNAE\n")


file.exists("painel_nucleo.rds")   # deve retornar TRUE

painel <- readRDS("painel_nucleo.rds")
glimpse(painel)                            # estrutura: colunas e tipos
View(painel)                               # abre o visualizador do RStudio

library(readr)

# Para Excel em portugues (separador ; e decimal com virgula)
write_csv2(readRDS("painel_nucleo.rds"), "painel_nucleo.csv")






###################### FIGURA 3 #########################

# =============================================================
# 03_figura3_event_study.R
# Figura 3 (2 x T Event Study) do Baker et al., replicada com o
# painel da Taxa das Blusinhas.
# Fonte da estetica e das opcoes: psantanna.com/JEL-DiD (bloco "Figure 3")
#
# Desenho:
#   unidade i : celula UF x classe CNAE
#   tempo t   : ano (2019 a 2025)
#   grupo g   : 2024 para tratados, 0 para controle (never treated)
#   janela    : e = -5 ate e = +1
#   estimador : Callaway e Sant'Anna (2021), sem covariaveis
#   desfecho  : log dos vinculos ativos e log da massa salarial
# =============================================================

library(tidyverse)
library(did)
library(ggthemes)
library(fixest)
library(broom)

set.seed(20240924)  # mesma semente do apendice de replicacao
options(error = NULL)  # evita cair no depurador em caso de erro

# --- 0. Tema global, identico ao do apendice -------------------
theme_set(
  theme_clean() +
    theme(plot.background   = element_blank(),
          legend.background = element_rect(color = "white"),
          strip.background  = element_rect(color = "black"))
)

# =============================================================
# 1. Dados: painel construido em painel_rais.R
# =============================================================
painel <- readRDS("painel_nucleo.rds")

ANO_TRAT <- 2024  # vigencia da medida (double, NAO 2024L)
ANO_BASE <- 2023  # ultimo ano pre-tratamento integral (base do peso)

# --- 1.1 Restricao de amostra --------------------------------
# Zero ou NA em qualquer desfecho gera log nao finito. A restricao e
# conjunta (vinculos E massa) para que as duas figuras saiam da mesma
# amostra e sejam comparaveis entre si.
celulas_todas <- painel %>% distinct(sigla_uf, cnae_2) %>% nrow()

dados <- painel %>%
  group_by(sigla_uf, cnae_2) %>%
  filter(all(total_vinculos_ativos > 0),
         all(!is.na(massa_salarial)),
         all(massa_salarial > 0)) %>%
  ungroup()

celulas_mantidas <- dados %>% distinct(sigla_uf, cnae_2) %>% nrow()
cat("Celulas: ", celulas_mantidas, " de ", celulas_todas,
    " (", round(100 * celulas_mantidas / celulas_todas, 1), "%)\n", sep = "")

# --- 1.1a Diagnostico: exclusao por grupo (contagem de celulas) ---
cat("\n--- Exclusao por grupo: celulas ---\n")
painel %>%
  group_by(sigla_uf, cnae_2) %>%
  mutate(mantida = all(total_vinculos_ativos > 0) &
           all(!is.na(massa_salarial)) &
           all(massa_salarial > 0)) %>%
  ungroup() %>%
  distinct(sigla_uf, cnae_2, tratado, mantida) %>%
  count(tratado, mantida) %>%
  group_by(tratado) %>%
  mutate(share = round(100 * n / sum(n), 1)) %>%
  print()

# --- 1.1b Diagnostico: exclusao por grupo (emprego de 2023) -------
# Este e o numero que importa: contar celulas trata uma celula de 5
# vinculos igual a uma de 50 mil. E este share que vai para o TCC.
cat("\n--- Exclusao por grupo: emprego de 2023 ---\n")
painel %>%
  group_by(sigla_uf, cnae_2) %>%
  mutate(mantida = all(total_vinculos_ativos > 0) &
           all(!is.na(massa_salarial)) &
           all(massa_salarial > 0)) %>%
  ungroup() %>%
  filter(ano == ANO_BASE) %>%
  count(tratado, mantida, wt = total_vinculos_ativos) %>%
  group_by(tratado) %>%
  mutate(share = round(100 * n / sum(n), 2)) %>%
  print()

# --- 1.2 Variaveis exigidas pelo did --------------------------
# ATENCAO: ano_tratamento e ano precisam ser DOUBLE, nao integer.
# O did substitui internamente o 0 dos nunca tratados por Inf, e Inf
# nao cabe em coluna integer: vira NA e o controle inteiro e descartado.
dados <- dados %>%
  mutate(id_celula      = as.numeric(factor(paste(sigla_uf, cnae_2, sep = "_"))),
         ano            = as.numeric(ano),
         ano_tratamento = as.numeric(if_else(tratado, ANO_TRAT, 0)),
         log_vinculos   = log(total_vinculos_ativos),
         log_massa      = log(massa_salarial)) %>%
  group_by(id_celula) %>%
  mutate(set_wt        = total_vinculos_ativos[which(ano == ANO_BASE)],
         time_to_treat = if_else(tratado, ano - ANO_TRAT, 0)) %>%
  ungroup()

stopifnot(
  is.double(dados$ano_tratamento),          # trava que impede o erro acima
  is.double(dados$ano),
  is.double(dados$id_celula),
  all(is.finite(dados$log_vinculos)),
  all(is.finite(dados$log_massa)),
  all(dados$set_wt > 0),
  length(unique(count(dados, id_celula)$n)) == 1   # painel balanceado
)

# Confirma que existem os dois grupos: 0 (nunca tratado) e 2024
cat("\n--- Grupos de tratamento (celulas) ---\n")
dados %>%
  distinct(id_celula, ano_tratamento) %>%
  count(ano_tratamento) %>%
  print()

cat("\nAmostra final: ", nrow(dados), " linhas | ",
    n_distinct(dados$id_celula), " celulas | ",
    n_distinct(dados$ano), " anos\n", sep = "")

# =============================================================
# 2. Funcao que estima e desenha a Figura 3 para um desfecho
# =============================================================
figura3 <- function(yname, rotulo_y, ponderado = TRUE, base = dados) {
  
  peso <- if (ponderado) "set_wt" else NULL
  
  # base_period = "universal": todo t comparado a g-1 (2023), que e a
  # definicao de tendencias paralelas do event study (PT-ES).
  # bstrap + cband: bandas simultaneas (sup-t) via bootstrap multiplicador.
  mod <- did::att_gt(
    yname         = yname,
    tname         = "ano",
    idname        = "id_celula",
    gname         = "ano_tratamento",
    xformla       = NULL,
    data          = base,
    panel         = TRUE,
    control_group = "nevertreated",
    bstrap        = TRUE,
    cband         = TRUE,
    est_method    = "reg",
    weightsname   = peso,
    base_period   = "universal",
    biters        = 25000
  )
  
  es  <- did::aggte(mod, type = "dynamic", na.rm = TRUE,
                    bstrap = TRUE, biters = 25000)
  agg <- did::aggte(mod, type = "dynamic", min_e = 0, max_e = 1,
                    bstrap = TRUE, biters = 25000)
  
  es_tidy <- broom::tidy(es, conf.int = TRUE)
  
  # rotulos do canto superior, como no artigo
  label1 <- paste0("Estimativa~(e %in% '{0, 1}')~'='~'",
                   scales::number(agg$overall.att, accuracy = 0.001), "'")
  label2 <- paste0("Erro Padrao = ", scales::number(agg$overall.se, 0.001), " \n",
                   "Int. Conf. = [",
                   scales::number(agg$overall.att - 1.96 * agg$overall.se, 0.001), ", ",
                   scales::number(agg$overall.att + 1.96 * agg$overall.se, 0.001), "]")
  
  # posicao dos rotulos calculada a partir da escala do desfecho
  y_max <- max(es_tidy$conf.high, na.rm = TRUE)
  y_min <- min(es_tidy$conf.low,  na.rm = TRUE)
  amp   <- y_max - y_min
  y1    <- y_max + 0.26 * amp
  y2    <- y_max + 0.13 * amp
  x_lab <- min(es_tidy$event.time) + 1.5
  
  p <- es_tidy %>%
    ggplot(aes(x = event.time, y = estimate)) +
    # vermelho: banda simultanea; preto: intervalo pontual
    geom_linerange(aes(ymin = conf.low, ymax = conf.high), color = "darkred") +
    geom_linerange(aes(ymin = point.conf.low, ymax = point.conf.high)) +
    geom_point() +
    geom_vline(xintercept = -1, linetype = "dashed") +
    geom_hline(yintercept = 0, linetype = "dashed") +
    scale_x_continuous(breaks = min(es_tidy$event.time):max(es_tidy$event.time)) +
    expand_limits(y = c(y_min, y1 + 0.05 * amp)) +
    annotate("text", x = x_lab, y = y1, label = label1, parse = TRUE, size = 3.5) +
    annotate("text", x = x_lab, y = y2, label = label2, size = 3.5) +
    labs(x = "Tempo do Evento", y = rotulo_y) +
    theme(axis.title.y = element_text(hjust = 0.5, vjust = 0.5, angle = 360),
          strip.text   = element_text(size = 14),
          panel.border = element_rect(color = "black", fill = NA, linewidth = 1),
          legend.title = element_blank(),
          axis.title   = element_text(size = 12),
          axis.text    = element_text(size = 10))
  
  list(mod = mod, es = es, agg = agg, tabela = es_tidy, grafico = p)
}

# =============================================================
# 3. Estimacao para os dois desfechos
# =============================================================
fig3_vinculos <- figura3("log_vinculos",
                         "Efeito do Tratamento \n log(Vinculos Ativos)")
fig3_massa    <- figura3("log_massa",
                         "Efeito do Tratamento \n log(Massa Salarial)")

print(fig3_vinculos$grafico)
print(fig3_massa$grafico)

print(fig3_vinculos$es);  print(fig3_vinculos$agg)
print(fig3_massa$es);     print(fig3_massa$agg)

# =============================================================
# 4. Checagem em TWFE (o apendice faz o mesmo)
# Os pontos devem bater com o CS; so os erros padrao diferem,
# porque o did usa bootstrap multiplicador.
# =============================================================
ols_vinculos <- feols(
  log_vinculos ~ i(time_to_treat, tratado, ref = -1) | id_celula + ano,
  data = dados, weights = ~set_wt, cluster = ~id_celula
)
etable(ols_vinculos)

ols_massa <- feols(
  log_massa ~ i(time_to_treat, tratado, ref = -1) | id_celula + ano,
  data = dados, weights = ~set_wt, cluster = ~id_celula
)
etable(ols_massa)

# =============================================================
# 5. Exportar (proporcao do artigo: 10 x 5)
# =============================================================
ggsave("figura3_event_study_vinculos.png", fig3_vinculos$grafico,
       width = 10, height = 5, dpi = 300)
ggsave("figura3_event_study_massa.png", fig3_massa$grafico,
       width = 10, height = 5, dpi = 300)

# =============================================================
# 6. Variantes para discutir com o orientador (rodar depois)
# =============================================================
# 6.1 Sem ponderacao pelo emprego de 2023:
# fig3_np <- figura3("log_vinculos",
#                    "Efeito do Tratamento \n log(Vinculos Ativos)",
#                    ponderado = FALSE)

# 6.2 Antecipacao (medida anunciada meses antes de vigorar):
# mod_ant <- did::att_gt(yname = "log_vinculos", tname = "ano",
#                        idname = "id_celula", gname = "ano_tratamento",
#                        xformla = NULL, data = dados, panel = TRUE,
#                        control_group = "nevertreated", bstrap = TRUE,
#                        cband = TRUE, est_method = "reg",
#                        weightsname = "set_wt", base_period = "universal",
#                        anticipation = 1, biters = 25000)

# 6.3 Sem alimentos e bebidas no controle (divisoes 10 e 11):
# fig3_sem_alim <- figura3("log_vinculos",
#                          "Efeito do Tratamento \n log(Vinculos Ativos)",
#                          base = filter(dados, grupo != "controle_alimentos"))




########### FIGURA 3 V2 ############


# =============================================================
# 7. ROBUSTEZ: janela a partir de 2022
# Motivo: 2020 e 2021 estao no periodo pre e carregam o choque de
# pandemia, que atingiu confeccao e calcados de forma muito mais
# intensa que farmaceutica, moveis e alimentos. Cortar a janela testa
# se o pre-trend positivo e Covid ou divergencia estrutural.
#
# LIMITE DESTA ESPECIFICACAO: com anos 2022-2025 e g = 2024, sobra um
# unico pre-periodo testavel (e = -2, ou seja, 2022). O pre-trend nao
# desaparece, ele fica sem teste. Por isso esta especificacao vai para
# o apendice como robustez, e nao substitui a principal.
# =============================================================

ANO_INICIO_CURTO <- 2022

dados_2022 <- dados %>%
  filter(ano >= ANO_INICIO_CURTO)

# O painel continua balanceado (o corte e o mesmo para todas as celulas)
stopifnot(
  length(unique(count(dados_2022, id_celula)$n)) == 1,
  n_distinct(dados_2022$id_celula) == n_distinct(dados$id_celula)
)

cat("\nJanela curta: ", nrow(dados_2022), " linhas | ",
    n_distinct(dados_2022$id_celula), " celulas | ",
    min(dados_2022$ano), " a ", max(dados_2022$ano), "\n", sep = "")

# --- 7.1 Estimacao -------------------------------------------
fig3_vinculos_2022 <- figura3(
  "log_vinculos",
  "Efeito do Tratamento \n log(Vinculos Ativos)",
  base = dados_2022
)

fig3_massa_2022 <- figura3(
  "log_massa",
  "Efeito do Tratamento \n log(Massa Salarial)",
  base = dados_2022
)

print(fig3_vinculos_2022$grafico)
print(fig3_massa_2022$grafico)

print(fig3_vinculos_2022$es); print(fig3_vinculos_2022$agg)
print(fig3_massa_2022$es);    print(fig3_massa_2022$agg)

# --- 7.2 Comparacao direta das duas janelas -------------------
# E este quadro que vai para o texto: se o ATT muda pouco, o pre-trend
# de 2019-2021 era ruido de pandemia; se muda muito, era estrutural.
comparacao <- bind_rows(
  tibble(desfecho = "log_vinculos", janela = "2019-2025",
         att = fig3_vinculos$agg$overall.att,
         se  = fig3_vinculos$agg$overall.se),
  tibble(desfecho = "log_vinculos", janela = "2022-2025",
         att = fig3_vinculos_2022$agg$overall.att,
         se  = fig3_vinculos_2022$agg$overall.se),
  tibble(desfecho = "log_massa",    janela = "2019-2025",
         att = fig3_massa$agg$overall.att,
         se  = fig3_massa$agg$overall.se),
  tibble(desfecho = "log_massa",    janela = "2022-2025",
         att = fig3_massa_2022$agg$overall.att,
         se  = fig3_massa_2022$agg$overall.se)
) %>%
  mutate(ic_inf = att - 1.96 * se,
         ic_sup = att + 1.96 * se,
         across(att:ic_sup, ~ round(.x, 4)))

cat("\n--- ATT medio (e em {0, 1}) por janela ---\n")
print(comparacao)

# --- 7.3 Pre-trend remanescente ------------------------------
# Com uma janela curta so ha e = -2. Reporte-o explicitamente.
cat("\n--- Pre-trend na janela curta (e = -2) ---\n")
bind_rows(
  fig3_vinculos_2022$tabela %>% mutate(desfecho = "log_vinculos"),
  fig3_massa_2022$tabela    %>% mutate(desfecho = "log_massa")
) %>%
  filter(event.time < -1) %>%
  select(desfecho, event.time, estimate, std.error, conf.low, conf.high) %>%
  mutate(across(estimate:conf.high, ~ round(.x, 4))) %>%
  print()

# --- 7.4 Checagem em TWFE na janela curta ---------------------
ols_vinculos_2022 <- feols(
  log_vinculos ~ i(time_to_treat, tratado, ref = -1) | id_celula + ano,
  data = dados_2022, weights = ~set_wt, cluster = ~id_celula
)
etable(ols_vinculos_2022)

ols_massa_2022 <- feols(
  log_massa ~ i(time_to_treat, tratado, ref = -1) | id_celula + ano,
  data = dados_2022, weights = ~set_wt, cluster = ~id_celula
)
etable(ols_massa_2022)

# --- 7.5 Exportar --------------------------------------------
ggsave("figura3_event_study_vinculos_2022.png", fig3_vinculos_2022$grafico,
       width = 10, height = 5, dpi = 300)
ggsave("figura3_event_study_massa_2022.png", fig3_massa_2022$grafico,
       width = 10, height = 5, dpi = 300)



















# =============================================================
# 8. DIAGNOSTICO DO PRE-TREND
# =============================================================

# --- 8.1 Teste conjunto de pre-tendencias --------------------
# H0: todos os ATT(g,t) pre-tratamento sao iguais a zero.
# O did reporta a estatistica de Wald e seu p-valor no objeto att_gt.
cat("\n--- Teste conjunto de pre-tendencias (janela 2019-2025) ---\n")

tibble(
  desfecho  = c("log_vinculos", "log_massa"),
  wald_stat = c(fig3_vinculos$mod$Wpval, fig3_massa$mod$Wpval)
) %>%
  print()

cat("\nVinculos: W =", round(fig3_vinculos$mod$W, 3),
    "| p-valor =", round(fig3_vinculos$mod$Wpval, 5), "\n")
cat("Massa   : W =", round(fig3_massa$mod$W, 3),
    "| p-valor =", round(fig3_massa$mod$Wpval, 5), "\n")
cat("p-valor abaixo de 0.05 rejeita a hipotese de pre-tendencias nulas.\n")

# =============================================================
# 8.2 CONTROLE SEM ALIMENTOS E BEBIDAS (divisoes 10 e 11)
# Motivo: alimentos e bebidas respondem a safra e a preco de
# commodities, ciclo que nao atinge confeccao, calcados e joias.
# Se o pre-trend cair ao remover esse bloco, o problema era
# composicao do controle, nao a identificacao em si.
# =============================================================

dados_sem_alim <- dados %>%
  filter(grupo != "controle_alimentos")

cat("\n--- Tamanho do controle apos exclusao ---\n")
dados_sem_alim %>%
  filter(ano == ANO_BASE) %>%
  count(grupo, wt = total_vinculos_ativos) %>%
  mutate(share = round(100 * n / sum(n), 1)) %>%
  print()

cat("\nCelulas: ", n_distinct(dados_sem_alim$id_celula),
    " (antes: ", n_distinct(dados$id_celula), ")\n", sep = "")

# Painel segue balanceado
stopifnot(length(unique(count(dados_sem_alim, id_celula)$n)) == 1)

fig3_vinculos_sa <- figura3(
  "log_vinculos",
  "Efeito do Tratamento \n log(Vinculos Ativos)",
  base = dados_sem_alim
)

fig3_massa_sa <- figura3(
  "log_massa",
  "Efeito do Tratamento \n log(Massa Salarial)",
  base = dados_sem_alim
)

print(fig3_vinculos_sa$grafico)
print(fig3_massa_sa$grafico)
print(fig3_vinculos_sa$es)
print(fig3_massa_sa$es)

# --- 8.3 Quadro comparativo: pre-trend e ATT ------------------
resumo_pre <- bind_rows(
  fig3_vinculos$tabela    %>% mutate(spec = "Completo",      desfecho = "vinculos"),
  fig3_vinculos_sa$tabela %>% mutate(spec = "Sem alimentos", desfecho = "vinculos"),
  fig3_massa$tabela       %>% mutate(spec = "Completo",      desfecho = "massa"),
  fig3_massa_sa$tabela    %>% mutate(spec = "Sem alimentos", desfecho = "massa")
) %>%
  as_tibble() %>%                       # <- correcao
  filter(event.time < -1) %>%
  select(desfecho, spec, event.time, estimate, conf.low, conf.high) %>%
  mutate(across(estimate:conf.high, ~ round(.x, 4))) %>%
  arrange(desfecho, event.time, spec)

cat("\n--- Pre-tendencias: com e sem alimentos ---\n")
print(resumo_pre, n = 20)

resumo_att <- bind_rows(
  tibble(desfecho = "vinculos", spec = "Completo",
         att = fig3_vinculos$agg$overall.att,    se = fig3_vinculos$agg$overall.se,
         wald_p = fig3_vinculos$mod$Wpval),
  tibble(desfecho = "vinculos", spec = "Sem alimentos",
         att = fig3_vinculos_sa$agg$overall.att, se = fig3_vinculos_sa$agg$overall.se,
         wald_p = fig3_vinculos_sa$mod$Wpval),
  tibble(desfecho = "massa", spec = "Completo",
         att = fig3_massa$agg$overall.att,       se = fig3_massa$agg$overall.se,
         wald_p = fig3_massa$mod$Wpval),
  tibble(desfecho = "massa", spec = "Sem alimentos",
         att = fig3_massa_sa$agg$overall.att,    se = fig3_massa_sa$agg$overall.se,
         wald_p = fig3_massa_sa$mod$Wpval)
) %>%
  mutate(across(att:wald_p, ~ round(.x, 4)))

cat("\n--- ATT e teste conjunto por especificacao ---\n")
print(resumo_att)
