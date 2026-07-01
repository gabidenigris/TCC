install.packages("basedosdados")

library(basedosdados)
library(dplyr)

set_billing_id("taxa-das-blusinhas")


query_agregada_total <- "
SELECT
    dados.ano AS ano,
    dados.sigla_uf AS sigla_uf,
    dados.cnae_2 AS cnae_2,
    SUM(dados.quantidade_vinculos_ativos) AS total_vinculos_ativos,
    SUM(dados.quantidade_vinculos_clt) AS total_vinculos_clt,
    COUNT(dados.cnae_2_subclasse) AS total_estabelecimentos
FROM `basedosdados.br_me_rais.microdados_estabelecimentos` AS dados
WHERE dados.ano IN (2023, 2024, 2025)
GROUP BY 
    dados.ano, 
    dados.sigla_uf, 
    dados.cnae_2
"

dados_painel <- read_sql(query_agregada_total)
head(dados_painel)


query_dicionario_cnae <- "
  SELECT DISTINCT 
    classe AS cnae_2, 
    descricao_classe AS descricao_cnae
  FROM `basedosdados.br_bd_diretorios_brasil.cnae_2`
"
dicionario_cnae <- read_sql(query_dicionario_cnae, billing_project_id = get_billing_id())

dados_painel_nomeado <- dados_painel %>%
  left_join(dicionario_cnae, by = "cnae_2")

head(dados_painel_nomeado)






