# Andamento

Aqui estou desenvolvendo as etapas do processo. Quais perguntas devem ser respondidas e como será o desenho econométrico.

## Perguntas:

**1.** Qual o impacto causal do imposto de importação 'Taxa das Blusinhas' no emprego formal de estabelecimentos que competem com importações de baixo valor (até US$50)?

<br>

### **a. Definição de tratamento e controle**

→ Dados: [RAIS Estabelecimentos](https://basedosdados.org/dataset/3e7c4d58-96ba-448e-b053-d385a829ef00?table=86b69f96-0bfe-45da-833b-6edc9a0af213)      
→ CNAE 2.0: [consulta de grupos](https://concla.ibge.gov.br/busca-online-cnae.html)     

> **Nota de revisão (jul/2026):** o plano original usava a tabela RAIS Estabelecimentos. Na carga do ano-base 2025 dessa tabela, a CNAE veio 100% nula, inviabilizando o desenho setorial. A tabela de vínculos está íntegra em todos os anos (2019 a 2025) e passou a ser a base oficial do painel. Vantagem adicional: permite extrair massa salarial na mesma consulta.

### Seleção das CNAEs: tratado e controle

| Grupo (Tratado/Controle) | CNAE | Descrição | Justificativa |
|---|---|---|---|
| Tratado (núcleo) | Divisão 14 (completa) | Confecção de artigos do vestuário e acessórios | Corresponde diretamente aos capítulos HS 50–63 (têxteis e vestuário), que concentram a maior parte das remessas de minimis logo acima do limiar identificadas por Fajgelbaum e Khandelwal, e às descrições de itens do artigo — roupas femininas (vestidos, blusas), roupas masculinas e acessórios. É o setor com concorrência mais direta do canal Shein/Temu; a taxa de 20% eleva o preço relativo do importado e, via mecanismo de pass-through, protege a demanda pelo produto doméstico e o emprego formal associado. |
| Tratado (núcleo) | Grupo 13.5 | Fabricação de artefatos têxteis, exceto vestuário (cama, mesa, banho, decoração) | Produz bens têxteis finais de consumo (HS 50–63, itens "home goods" citados no paper), vendidos diretamente ao consumidor e substitutos próximos das remessas. Isolado do restante da Divisão 13, cujos grupos 13.1–13.4 são majoritariamente insumos B2B para a própria Divisão 14 — incluí-los diluiria o tratamento e criaria contaminação via canal de custo do insumo. |
| Tratado (núcleo) | Grupos 15.2 e 15.3 | Fabricação de artigos de viagem, bolsas e semelhantes (15.2); calçados (15.3) | Mapeiam os capítulos HS 64–67 (calçados e chapéus) e 41–43 (couros e peles), listados no paper entre os capítulos dominantes das remessas de minimis. São bens finais de consumo comprados em plataformas; a concorrência importada de baixo valor é direta. O grupo 15.1 (curtimento de couro) fica fora por ser insumo intermediário. |
| Tratado (núcleo) | Grupos 32.1, 32.3 e 32.4 | Joalheria e bijuterias (32.1); artefatos para pesca e esporte (32.3); brinquedos e jogos recreativos (32.4) | Correspondem ao capítulo HS 90–99 (miscelânea) e às descrições de itens do paper (colares, acessórios, decoração), além das categorias "sports and outdoors" e brinquedos típicas dessas plataformas. Bens finais de baixo valor unitário, alto grau de substituição com o importado de remessa. |
| Tratado (extensão/robustez) | Classes 27.40 e 27.59 | Fabricação de lâmpadas e equipamentos de iluminação (27.40); eletrodomésticos portáteis e outros aparelhos de uso doméstico (27.59) | Capítulos HS 84–85 aparecem entre os principais nas remessas, mas conflacionam eletrônicos de consumo com bens de capital industriais. Essas classes isolam o segmento efetivamente exposto (pequenos eletroportáteis, iluminação de consumo). Entram como extensão porque a exposição é mais heterogênea que no núcleo têxtil-vestuário. |
| Tratado (extensão/robustez) | Grupo 26.4 e classe 26.52 | Equipamentos de áudio/vídeo (26.4); cronômetros e relógios (26.52) | Eletrônicos de consumo e relógios são itens recorrentes nas remessas (HS 84–85 e 91). Uso condicionado à exclusão de estabelecimentos da Zona Franca de Manaus, cujo regime tributário próprio (e a Lei de Informática) constitui confundidor de política simultânea — violação potencial da hipótese de "no other shocks" enfatizada no guia de DiD. |
| Controle | Divisão 16 | Fabricação de produtos de madeira | Atende majoritariamente construção civil e indústria moveleira doméstica; bens volumosos/pesados com custo de frete proibitivo para remessas de até US$ 50. Exposição ao canal de minimis praticamente nula, mas sujeito aos mesmos ciclos macro industriais — favorece a plausibilidade de tendências paralelas. |
| Controle | Divisão 17 | Fabricação de celulose, papel e produtos de papel | Insumo intermediário e bens de baixa relação valor/peso, inviáveis no canal de remessa internacional. Setor industrial de transformação comparável em estrutura de emprego formal. |
| Controle | Divisão 23 | Fabricação de produtos de minerais não metálicos (cimento, vidro, cerâmica) | Bens pesados, frágeis ou a granel, atendendo mercado interno (construção). Concorrência via remessa postal é fisicamente inviável; serve de contrafactual para a evolução do emprego industrial formal na ausência do choque. |
| Controle | Divisão 28 | Fabricação de máquinas e equipamentos | Bens de capital B2B de alto valor unitário, importados (quando importados) pelo canal formal com despacho aduaneiro convencional — exatamente o segmento de HS 84–85 que o paper distingue dos eletrônicos de consumo. Exposição nula ao limiar de US$ 50. |
| Controle | Divisão 22 (exceto classe 22.29) | Fabricação de produtos de borracha e material plástico | Predominantemente insumos e embalagens B2B. A classe 22.29 (artefatos plásticos diversos) é excluída por conter utilidades domésticas de plástico potencialmente compradas em plataformas — evita controle contaminado, que viesaria o estimador. |
| Controle | Divisão 25 (exceto classes 25.50 e 25.93) | Fabricação de produtos de metal, exceto máquinas | Estruturas metálicas, caldeiraria e forjaria atendem construção e indústria doméstica. Excluem-se 25.50 (armas) por regime regulatório próprio e 25.93 (artefatos de metal para uso doméstico e pessoal — cutelaria, panelas) por sobreposição parcial com o basket de remessas. |
| Excluído (zona de contaminação) | Grupos 13.1–13.4; 15.1; 15.4; 32.5; demais de 26 e 27 | Fiação, tecelagem e acabamento têxtil; curtimento; partes de calçados; instrumentos médico-odontológicos; demais eletrônicos e elétricos | Setores com exposição ambígua: ou são fornecedores upstream dos tratados (efeito indireto via demanda derivada, violando SUTVA/no-spillover entre grupos), ou misturam consumo e B2B sem separação limpa no CNAE. O guia de DiD recomenda excluir unidades de status ambíguo em vez de forçar sua classificação, preservando a interpretação do parâmetro causal (ATT). |

<br>

### **b. Parâmetro-alvo e hipóteses de identificação**
 
#### Unidade e notação
A unidade de análise é a célula *UF × classe CNAE* (indústria de transformação, 4 dígitos), observada anualmente na RAIS (foto de 31/dez), para $t = 2019, \dots, 2025$.
O tratamento é binário:
* $D_i = 1$ se a célula pertence aos setores tratados (produtores domésticos de bens substitutos das importações de baixo valor);
* $D_i = 0$ se pertence ao controle (setores fora do canal de remessas internacionais).
A vigência da taxa é *01/08/2024*; logo, a primeira observação pós-tratamento é a RAIS de dezembro/2024, ou seja, $g = 2024$ (coorte única, adoção simultânea). O desfecho $Y_{i,t}$ é o logaritmo do emprego formal (vínculos ativos em 31/12) da célula.
 
#### Parâmetro-alvo
O efeito médio do tratamento sobre os tratados em cada ano pós-vigência:
 
$$ATT(t) = E\left[\,Y_{i,t}(1) - Y_{i,t}(0) \mid D_i = 1\,\right], \quad t \geq 2024$$
 
Em palavras: quanto o emprego formal dos setores tratados difere, em média, do que teria sido sem a taxa. O desfecho potencial $Y_{i,t}(0)$ nunca é observado para os tratados após 2024: é isso que as hipóteses abaixo permitem reconstruir. Como a RAIS de dez/2024 captura apenas 5 meses de vigência, $ATT(2024)$ é interpretado como efeito de exposição parcial; $ATT(2025)$ é o coeficiente principal (primeiro ano cheio).

<br>


### **c. Painel construído (script `01_painel_did.R`)**
 
Painel balanceado UF × classe CNAE × ano, agregado em SQL no BigQuery a partir de `microdados_vinculos`. Dimensões: 21.777 linhas, 141 classes CNAE, 27 UFs válidas, 2019 a 2025.
 
Estrutura (exemplo de uma célula tratada e uma de controle):
 
| ano | sigla_uf | cnae_2 | descricao_cnae | grupo | tratado | post | total_vinculos_ativos | massa_salarial | salario_medio |
|-----|----------|--------|----------------|-------|---------|------|----------------------|----------------|---------------|
| 2023 | SC | 14126 | Confecção de peças do vestuário | tratado_nucleo | TRUE | FALSE | 48.312 | 112.480.500 | 2.328,10 |
| 2024 | SC | 14126 | Confecção de peças do vestuário | tratado_nucleo | TRUE | TRUE | 47.905 | 115.210.300 | 2.404,97 |
| 2023 | SC | 16226 | Fabricação de esquadrias de madeira | controle | FALSE | FALSE | 9.104 | 21.870.400 | 2.402,29 |
| 2024 | SC | 16226 | Fabricação de esquadrias de madeira | controle | FALSE | TRUE | 9.377 | 22.905.100 | 2.442,69 |
 
<br>

<br>


## **d. Teste de tendências paralelas (script 02_tendencias_paralelas.R) — EM ANDAMENTO**

Próximos passos

- Rodar o event study e avaliar os coeficientes pré (atenção esperada ao ruído de 2020, Covid).
- Análise de sensibilidade de Rambachan e Roth calibrada pelo maior pré-trend estimado.
- Robustez: grupo de extensão como tratados, divisões 10 e 24 como controle alternativo, exclusão da Zona Franca de Manaus, placebos em setores não afetados e em datas falsas, margem extensiva via asinh.
- Primeiro estágio: documentação da queda das importações de remessas (Comex Stat) após agosto de 2024.
- Variáveis adicionais: massa salarial real (deflacionada pelo IPCA) e salário médio.
