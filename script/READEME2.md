# Metodologia

Esta página documenta, passo a passo, o desenho da pesquisa do meu TCC. A ideia é que qualquer pessoa consiga acompanhar a lógica do início ao fim: o que aconteceu, o que quero medir, como vou medir e por quê.

## O que aconteceu (a política estudada)

Até 2024, compras internacionais de até US$ 50 (as "remessas de baixo valor", típicas de sites como Shein, Shopee e AliExpress) entravam no Brasil sem Imposto de Importação. Em 1º de agosto de 2024, entrou em vigor a chamada **Taxa das Blusinhas** (MP 1.236/2024): um Imposto de Importação de 20% sobre essas remessas. Na prática, o produto importado barato ficou mais caro da noite para o dia.

## A pergunta da pesquisa

**Qual o impacto causal da Taxa das Blusinhas sobre o emprego formal nas indústrias brasileiras que competem com essas importações?**

A intuição econômica: se a blusinha importada ficou 20% mais cara, parte dos consumidores pode migrar para o produto nacional. Se isso acontecer, as fábricas brasileiras de roupas, calçados, bijuterias e afins deveriam vender mais e, possivelmente, **contratar mais**. É esse efeito no emprego que quero medir.

A palavra "causal" é o ponto central. Não basta ver se o emprego na confecção subiu depois de agosto de 2024: ele poderia ter subido (ou caído) por outros motivos, como o ciclo econômico, os juros ou o câmbio. Preciso separar o efeito da taxa de tudo o que estava acontecendo ao mesmo tempo.

## Como separar o efeito da taxa: diferenças em diferenças (DiD)

A estratégia é comparar dois grupos de indústrias ao longo do tempo:

- **Grupo tratado**: indústrias cujos produtos competem diretamente com as remessas de baixo valor (roupas, calçados, bijuteria, brinquedos). A taxa é um "empurrão" a favor delas.
- **Grupo de controle**: indústrias parecidas (também manufatura, também sujeitas a câmbio, juros e ciclo econômico), mas cujos produtos **não** chegam ao consumidor por remessa internacional (madeira, papel, cimento, máquinas industriais). Para elas, a taxa é irrelevante.

O método de **diferenças em diferenças** compara a evolução do emprego nos dois grupos, antes e depois de agosto de 2024. O grupo de controle serve como "contrafactual": ele mostra o que teria acontecido com o emprego dos tratados se a taxa não existisse. O efeito da taxa é a diferença entre o que de fato aconteceu com os tratados e essa trajetória contrafactual.

Referencial metodológico: Baker, Callaway, Cunningham, Goodman-Bacon e Sant'Anna (2025), *Difference-in-Differences Designs: A Practitioner's Guide*. Referencial para identificar os setores expostos: Fajgelbaum e Khandelwal (2025), *The Value of de Minimis Imports*.

## Dados

- **Emprego**: [RAIS Estabelecimentos](https://basedosdados.org/dataset/3e7c4d58-96ba-448e-b053-d385a829ef00?table=86b69f96-0bfe-45da-833b-6edc9a0af213), registro administrativo de todos os vínculos formais de trabalho no Brasil, por estabelecimento e por ano (foto de 31 de dezembro).
- **Classificação setorial**: [CNAE 2.0](https://cnae.ibge.gov.br/documentacao/documentacao-cnae-2-0.html), o código que identifica a atividade de cada estabelecimento.

## Seleção das CNAEs: quem é tratado e quem é controle

Como saber quais setores competem com a remessa? Fajgelbaum e Khandelwal (2025) analisaram milhões de remessas de baixo valor que entram nos EUA e mostraram que a cesta é concentrada em poucas categorias de produto: roupas, calçados, bolsas e couros, bijuterias, brinquedos e eletrônicos pequenos. Traduzi essas categorias para os códigos CNAE da indústria brasileira.

Uma decisão importante: a classificação é feita em nível fino (grupos de 3 dígitos e classes de 4 dígitos da CNAE), não em divisões inteiras de 2 dígitos. O motivo é que uma mesma divisão mistura fábricas de produto final (que competem com a remessa) e fábricas de insumos ou de bens industriais (que não competem). Por exemplo, a divisão de têxteis inclui tanto quem faz toalhas e roupas de cama (compete com a remessa) quanto quem fia algodão para vender às confecções (não compete). Classificar tudo junto diluiria o efeito.

Setores ambíguos não entram em nenhum dos grupos: ficam em uma **zona de exclusão**, prática recomendada por Baker et al. (2025). É melhor descartar um setor de classificação duvidosa do que colocá-lo no grupo errado.

### Tratado (núcleo)

| CNAE | Descrição | Justificativa |
|---|---|---|
| 14 (divisão) | Confecção de artigos do vestuário e acessórios | A "blusinha" literal. Bem final de consumo, competição direta com a remessa |
| 13.5 | Artefatos têxteis, exceto vestuário (cama, mesa, banho, tapeçaria) | Itens têxteis para casa, típicos da cesta de remessa. Único grupo da divisão 13 que produz bem final |
| 15.2 | Artigos para viagem, bolsas e artefatos de couro | Bolsas e acessórios |
| 15.3 | Calçados (couro, tênis, sintéticos) | Competição direta com calçado importado de baixo valor |
| 32.1 | Joalheria e bijuteria | Bijuteria é item central da cesta de remessa |
| 32.3 | Artefatos para pesca e esporte | Artigos esportivos de baixo valor unitário |
| 32.4 | Brinquedos e jogos recreativos | Item típico de marketplace internacional |

### Tratado (extensão, usado apenas em testes de robustez)

| CNAE | Descrição | Justificativa |
|---|---|---|
| 27.40 | Lâmpadas e equipamentos de iluminação | Luminárias e LED de marketplace |
| 27.59 | Eletrodomésticos não especificados (eletroportáteis) | Pequenos eletro entram por remessa; linha branca (geladeira, fogão) não |
| 26.4 | Aparelhos de áudio e vídeo | Eletrônico de consumo, mas produção concentrada na Zona Franca de Manaus. Usar excluindo estabelecimentos da ZFM |
| 26.52 | Cronômetros e relógios | Relógios entram por remessa. Mesma ressalva da ZFM |

### Controle

| CNAE | Descrição | Justificativa |
|---|---|---|
| 16 (divisão) | Produtos de madeira | Manufatura, mas peso e volume incompatíveis com remessa |
| 17 (divisão) | Celulose, papel e produtos de papel | Fora do canal de remessa |
| 23 (divisão) | Minerais não metálicos (vidro, cimento, cerâmica) | Fora do canal. Atenção: ligado ao ciclo da construção, verificar nas pré-tendências |
| 28 (divisão) | Máquinas e equipamentos | Bens de capital vendidos a empresas, fora do canal |
| 22 (exceto 22.29) | Borracha e plástico | Fora do canal. Exclui-se 22.29 (artefatos de plástico) por conter utilidades domésticas que entram por remessa |
| 25 (exceto 25.50 e 25.93) | Produtos de metal | Vendas majoritariamente entre empresas. Exclui-se 25.93 (uso doméstico e pessoal, cesta de remessa) e 25.50 (bélico, regulado) |

### Sensibilidade (entram apenas em testes de robustez do controle)

| CNAE | Descrição | Justificativa |
|---|---|---|
| 10 (divisão) | Alimentos | Não entra por remessa, mas é um setor enorme e ligado ao ciclo de commodities. Testar resultados com e sem |
| 24 (divisão) | Metalurgia | Recebeu política comercial própria no mesmo período (medidas contra o aço chinês em 2024), o que contaminaria a comparação |

### Zona de exclusão (nem tratado, nem controle)

| CNAE | Descrição | Motivo da exclusão |
|---|---|---|
| 13.1 a 13.4 | Fiação, tecelagem, acabamentos têxteis | Vendem insumos para a própria confecção. Se a taxa ajuda a confecção, esses setores também podem ser beneficiados indiretamente, o que torna a classificação ambígua |
| 15.1 | Curtimento de couro | Insumo intermediário, fortemente exportador |
| 15.4 | Partes para calçados | Insumo da cadeia calçadista |
| 32.5 | Instrumentos médicos e odontológicos | Vendido a empresas e regulado pela Anvisa, não entra por remessa. Peso grande de emprego na divisão 32 |
| 26 (demais grupos) | Componentes, informática, comunicação, instrumentos de medida | Vendas entre empresas ou produção dominada pela ZFM e pela Lei de Informática, que mudaram no período |
| 27 (demais grupos) | Geradores, baterias, distribuição de energia, linha branca | Vendas entre empresas ou produto pesado demais para remessa |
| 22.29, 25.50, 25.93 | Ver acima | Retirados dos controles por contaminação ou regulação |

## Decisões de desenho (fechadas com o orientador)

| Decisão | Escolha | Observação |
|---|---|---|
| Variável de tratamento | Binária (tratado vs. controle) | Uma medida contínua de exposição (quanto cada setor importa via remessa, com dados do Comex Stat) fica como teste de robustez |
| Evento | Taxa de 20% em 1/ago/2024 (MP 1.236/2024) | O Programa Remessa Conforme (ago/2023, com ICMS) não é o evento estudado; será discutido como possível antecipação parcial. A zeragem da taxa em mai/2026 delimita o fim da janela de análise |
| Janela do painel | 2021 a 2025 | Três anos antes do evento para verificar se os grupos evoluíam de forma parecida. O ano de 2021 será interpretado com cautela (recuperação pós-pandemia) |
| Desfecho | Emprego formal (RAIS) | Principal: vínculos ativos. Secundários: número de estabelecimentos e salário médio. Limitação: a RAIS só enxerga o emprego formal, e a confecção tem alta informalidade |

Como a RAIS é uma foto de 31 de dezembro, o ano de 2024 já conta como tratado (a taxa vigorou de agosto a dezembro). Anos pré: 2021, 2022, 2023. Anos pós: 2024 e 2025 (este último condicional à publicação da RAIS).

## Estratégia de identificação (como o efeito é estimado)

Todos os setores tratados recebem a taxa ao mesmo tempo (agosto de 2024). Isso simplifica o desenho: é um DiD clássico de dois grupos e dois períodos, estendido para vários anos no formato de **estudo de eventos** (event study). Em vez de estimar um único efeito médio, estimo um coeficiente para cada ano, medindo a diferença entre tratados e controles em relação a 2023 (o último ano antes da taxa).

Isso produz dois resultados em um só gráfico:

1. **Coeficientes dos anos pré (2021 e 2022)**: se forem próximos de zero, os dois grupos evoluíam de forma parecida antes da taxa. É a evidência de plausibilidade da hipótese central do método, chamada de **tendências paralelas**: a suposição de que, sem a taxa, os tratados teriam seguido a mesma trajetória dos controles.
2. **Coeficientes dos anos pós (2024 e 2025)**: o efeito estimado da taxa sobre o emprego formal.

Detalhes técnicos da estimação: modelo com efeitos fixos de setor x UF (controla características fixas de cada setor em cada estado) e de ano (controla choques nacionais comuns, como juros e câmbio). Erros-padrão agrupados por setor, com correção de wild cluster bootstrap, adequada quando o número de setores é pequeno. Como não há adoção escalonada (ninguém é tratado antes ou depois dos demais), os problemas recentes apontados na literatura de DiD com TWFE não se aplicam aqui.

**Primeiro estágio**: antes de olhar o emprego, vou documentar com dados do Comex Stat (MDIC) que as importações da cesta afetada de fato caíram após agosto de 2024. Esse passo é essencial: se as importações não caíram, não há razão para esperar efeito no emprego, e um resultado nulo não seria interpretável.

## Roteiro

- [x] 1. Definição da pergunta, tratado, controle e decisões de desenho
- [ ] 2. Montagem do painel RAIS 2021-2025 (ano x UF x setor), com os filtros de CNAE da tabela acima
- [ ] 3. Primeiro estágio no Comex Stat (importações da cesta afetada antes e depois da taxa)
- [ ] 4. Estatísticas descritivas e gráfico de pré-tendências (2021-2023)
- [ ] 5. Estimação principal: event study, wild cluster bootstrap
- [ ] 6. Robustez: tratados de extensão, controle com e sem divisões 10 e 24, exclusão da ZFM, dose-resposta com medida contínua de exposição
- [ ] 7. Redação dos resultados e limitações
