# Metodologia

Aqui estou desenvolvendo as etapas do processo. Quais perguntas devem ser respondidas e como será o desenho econométrico.

## Perguntas:

**1.** Qual o impacto causal do imposto de importação 'Taxa das Blusinhas' no emprego formal de estabelecimentos que competem com importações de baixo valor (até US$50)?

Referencial metodológico: Baker, Callaway, Cunningham, Goodman-Bacon e Sant'Anna (2025), "Difference-in-Differences Designs: A Practitioner's Guide". Referencial para seleção de setores expostos: Fajgelbaum e Khandelwal (2025), "The Value of de Minimis Imports".

### **a.** Definição de tratamento e controle

→ Dados: [RAIS Estabelecimentos](https://basedosdados.org/dataset/3e7c4d58-96ba-448e-b053-d385a829ef00?table=86b69f96-0bfe-45da-833b-6edc9a0af213)

→ CNAE 2.0: [consulta de subclasses](https://cnae.ibge.gov.br/documentacao/documentacao-cnae-2-0.html)

### Seleção das CNAEs: tratado e controle

Critério: setores da indústria de transformação cujo produto final compete com a cesta de remessas de baixo valor (HS 50-63, 64-67, 41-43, 84-85, 90-99, conforme Fajgelbaum e Khandelwal, 2025) entram como tratados. Setores manufatureiros comercializáveis, sujeitos aos mesmos choques macro, mas fora do canal de remessa, entram como controle. Setores de insumos intermediários ou com confundidores próprios ficam em zona de exclusão (nem tratado, nem controle), conforme boa prática de Baker et al. (2025).

#### Tratado (núcleo)

| CNAE | Descrição | Justificativa |
|---|---|---|
| 14 (divisão) | Confecção de artigos do vestuário e acessórios | A "blusinha" literal. Núcleo do HS 50-63. Bem final de consumo, competição direta com a remessa |
| 13.5 | Artefatos têxteis, exceto vestuário (cama, mesa, banho, tapeçaria) | Home goods têxtil, item típico da cesta de remessa. Único grupo da divisão 13 que produz bem final |
| 15.2 | Artigos para viagem, bolsas e artefatos de couro | Bolsas e acessórios, HS 41-43 |
| 15.3 | Calçados (couro, tênis, sintéticos) | HS 64-67, competição direta com calçado importado de baixo valor |
| 32.1 | Joalheria e bijuteria | Bijuteria é item central da cesta de remessa (HS 90-99) |
| 32.3 | Artefatos para pesca e esporte | Artigos esportivos de baixo valor unitário |
| 32.4 | Brinquedos e jogos recreativos | Item típico de marketplace internacional |

#### Tratado (extensão, robustez)

| CNAE | Descrição | Justificativa |
|---|---|---|
| 27.40 | Lâmpadas e equipamentos de iluminação | Luminárias e LED de marketplace. Overlap parcial com HS 84-85 |
| 27.59 | Eletrodomésticos não especificados (eletroportáteis) | Pequenos eletro entram por remessa; linha branca (27.51) não |
| 26.4 | Aparelhos de áudio e vídeo | Eletrônico de consumo, mas produção concentrada na ZFM. Usar excluindo estabelecimentos da ZFM |
| 26.52 | Cronômetros e relógios | Relógios são cesta de remessa. Mesma ressalva de ZFM |

#### Controle

| CNAE | Descrição | Justificativa |
|---|---|---|
| 16 (divisão) | Produtos de madeira | Manufatura comercializável, peso e volume incompatíveis com remessa |
| 17 (divisão) | Celulose, papel e produtos de papel | Idem, fora do canal de minimis |
| 23 (divisão) | Minerais não metálicos (vidro, cimento, cerâmica) | Fora do canal. Atenção: ligado ao ciclo da construção, testar pré-tendências |
| 28 (divisão) | Máquinas e equipamentos | Bens de capital, B2B, fora do canal |
| 22 (exceto 22.29) | Borracha e plástico | Fora do canal. Exclui-se 22.29 (artefatos de plástico) por conter utilidades domésticas que entram por remessa |
| 25 (exceto 25.50 e 25.93) | Produtos de metal | B2B em sua maioria. Exclui-se 25.93 (uso doméstico e pessoal, cesta de remessa) e 25.50 (bélico, regulado) |

#### Sensibilidade (usar apenas em testes de robustez do controle)

| CNAE | Descrição | Justificativa |
|---|---|---|
| 10 (divisão) | Alimentos | Não entra por remessa, mas setor enorme e ligado a ciclo de commodities. Testar resultados com e sem |
| 24 (divisão) | Metalurgia | Contaminado por política comercial própria no mesmo período (medidas contra o aço chinês em 2024) |

#### Zona de exclusão (nem tratado, nem controle)

| CNAE | Descrição | Motivo da exclusão |
|---|---|---|
| 13.1 a 13.4 | Fiação, tecelagem, acabamentos têxteis | Insumos intermediários da própria confecção. Tratamento ambíguo: podem ser beneficiados se a taxa ajuda a confecção doméstica |
| 15.1 | Curtimento de couro | Insumo intermediário, fortemente exportador |
| 15.4 | Partes para calçados | Insumo B2B da cadeia calçadista |
| 32.5 | Instrumentos médicos e odontológicos | B2B, regulado (Anvisa), não entra por remessa. Peso grande de emprego na divisão 32 |
| 26 (demais grupos) | Componentes, informática, comunicação, medida | B2B ou dominado por ZFM e Lei de Informática (confundidor no período) |
| 27 (demais grupos) | Geradores, baterias, distribuição de energia, linha branca | B2B ou produto pesado, fora do canal de remessa |
| 22.29, 25.50, 25.93 | Ver acima | Retirados dos controles por contaminação ou regulação |

### **b.** Decisões de desenho (fechadas com o orientador)

| Decisão | Escolha | Observação |
|---|---|---|
| Variável de tratamento | Binária (tratado vs. controle) | Medida contínua de exposição (participação de remessas via Comex Stat) fica como robustez dose-resposta |
| Evento | Taxa de 20% em 1/ago/2024 (MP 1.236/2024) | PRC/ICMS (ago/2023) não é o evento; será discutido como possível antecipação parcial. Zeragem em mai/2026 delimita a janela pós |
| Janela do painel | 2021 a 2025 | Extensão do pré para permitir teste de pré-tendências, buscando reduzir contaminação da pandemia. 2021 interpretado com cautela (recuperação pós-covid) |
| Desfecho | Emprego formal (RAIS) | Principal: vínculos ativos. Secundários: número de estabelecimentos (margem extensiva) e salário médio. Limitação: alta informalidade na confecção; efeito estimado é sobre o emprego formal |

Como a RAIS é foto de 31 de dezembro, 2024 já é ano tratado (5 meses de vigência). Anos pré: 2021, 2022, 2023. Anos pós: 2024, 2025 (condicional à disponibilidade da RAIS 2025).

### **c.** Estratégia de identificação

Com evento único e adoção simultânea (todos os tratados em ago/2024), o desenho é um DiD 2x2 com estudo de eventos. Não há adoção escalonada, então os problemas de TWFE apontados por Goodman-Bacon não se aplicam. Especificação: TWFE com leads e lags (event study), efeitos fixos de setor x UF e de ano, erros-padrão clusterizados no nível do setor, com wild cluster bootstrap dada a quantidade reduzida de clusters.

Hipótese de identificação: tendências paralelas entre tratados e controles na ausência da taxa. Evidência de plausibilidade: coeficientes dos leads (2021-2023) próximos de zero.

Primeiro estágio: documentar, com dados do Comex Stat (MDIC), que as importações da cesta afetada caíram após ago/2024. Sem primeiro estágio, um efeito nulo no emprego não é interpretável.

## Roteiro

- [x] 1. Definição da pergunta, tratado, controle e decisões de desenho
- [ ] 2. Montagem do painel RAIS 2021-2025 (ano x UF x setor), com filtros de CNAE da tabela acima
- [ ] 3. Primeiro estágio no Comex Stat (importações da cesta afetada antes e depois da taxa)
- [ ] 4. Estatísticas descritivas e gráfico de pré-tendências (2021-2023)
- [ ] 5. Estimação principal: event study TWFE, wild cluster bootstrap
- [ ] 6. Robustez: tratados de extensão, controle com e sem divisões 10 e 24, exclusão da ZFM, dose-resposta com medida contínua de exposição
- [ ] 7. Redação dos resultados e limitações
