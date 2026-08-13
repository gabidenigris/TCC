# Andamento

Aqui estou desenvolvendo as etapas do processo. Quais perguntas devem ser respondidas e como será o desenho econométrico.

## Perguntas:

**1.** Qual o impacto causal do imposto de importação 'Taxa das Blusinhas' no emprego formal de estabelecimentos que competem com importações de baixo valor (até US$50)?

<br>
<br>

---

### **a. Definição de tratamento e controle**

→ Dados: [RAIS Estabelecimentos](https://basedosdados.org/dataset/3e7c4d58-96ba-448e-b053-d385a829ef00?table=86b69f96-0bfe-45da-833b-6edc9a0af213)      
→ CNAE 2.0: [consulta de grupos](https://concla.ibge.gov.br/busca-online-cnae.html)     

> **Nota de revisão (jul/2026):** o plano original usava a tabela RAIS Estabelecimentos. Na carga do ano-base 2025 dessa tabela, a CNAE veio 100% nula, inviabilizando o desenho setorial. A tabela de vínculos está íntegra em todos os anos (2019 a 2025) e passou a ser a base oficial do painel. Vantagem adicional: permite extrair massa salarial na mesma consulta.

### Seleção das CNAEs: tratado e controle

### - **Critério de seleção (tratado):** 
CNAE cujo produto final mapeia nos capítulos HS que dominam as remessas de minimis logo acima do limiar em Fajgelbaum e Khandelwal (50 a 63, 64 a 67, 41 a 43, 90 a 99 e o segmento de consumo de 84 a 85), sendo bem final de consumo, de baixo valor unitário e alta relação valor/peso (viável no canal de até US$ 50). Insumos intermediários são excluídos ainda que pertençam aos mesmos capítulos (13.1 a 13.4, 15.1), para não diluir a intensidade do tratamento nem introduzir contaminação via canal de custo.

<br>

| Grupo Tratado | CNAE | Descrição | Justificativa |
|---|---|---|---|
| Tratado (núcleo) | Divisão 14 (completa) | Confecção de artigos do vestuário e acessórios | É o setor mais atingido. Roupa é o principal item que chega por remessa internacional, e o paper mostra isso tanto pelos capítulos de têxteis e vestuário (HS 50 a 63) quanto pelas descrições das encomendas (vestidos, blusas, calças). Uma blusa nacional e uma blusa da Shein são substitutas quase perfeitas para o consumidor, então a taxa de 20% muda diretamente a escolha de compra. |
| Tratado (núcleo) | Grupo 13.5 | Fabricação de artefatos têxteis, exceto vestuário (cama, mesa, banho, decoração) | Produz itens de casa (toalha, jogo de cama, cortina, capa de almofada), que aparecem nas remessas na categoria "home goods". São produtos acabados, vendidos direto ao consumidor. Separei do resto da Divisão 13 porque os grupos 13.1 a 13.4 fabricam fio e tecido, que são vendidos para outras fábricas, não para o consumidor final. |
| Tratado (núcleo) | Grupos 15.2 e 15.3 | Fabricação de bolsas e semelhantes (15.2) e calçados (15.3) | Calçados, bolsas e mochilas são categorias grandes nas plataformas e aparecem entre os principais capítulos das remessas (HS 64 a 67 e 41 a 43). São compras típicas de baixo valor. O grupo 15.1 (curtimento de couro) fica fora porque vende couro para fábricas, não sapato para o consumidor. |
| Tratado (núcleo) | Grupos 32.1, 32.3 e 32.4 | Joalheria e bijuterias (32.1); artefatos para pesca e esporte (32.3); brinquedos e jogos recreativos (32.4) | Bijuteria, brinquedo e artigo esportivo barato são exatamente o tipo de item que enche o carrinho nessas plataformas: preço baixo, peso baixo, compra por impulso. O paper cita colares e acessórios entre os produtos mais frequentes, e as categorias de esporte e brinquedos são vitrines fixas da Shein e da Temu. |
| Tratado (extensão/robustez) | Classes 27.40 e 27.59 | Fabricação de lâmpadas e equipamentos de iluminação (27.40); eletrodomésticos portáteis e outros aparelhos de uso doméstico (27.59) | Eletrônicos aparecem bastante nas remessas, mas o capítulo HS que os contém (84 a 85) mistura ventilador de mesa com máquina industrial. Essas duas classes isolam a parte que o consumidor realmente compra online: luminária, lâmpada, secador de cabelo, liquidificador pequeno. Entram como extensão porque a exposição aqui é menos uniforme que em roupa e calçado. |
| Tratado (extensão/robustez) | Grupo 26.4 e classe 26.52 | Equipamentos de áudio/vídeo (26.4); cronômetros e relógios (26.52) | Fone de ouvido, caixinha de som e relógio são itens recorrentes nas encomendas. **Só uso este grupo excluindo os estabelecimentos da Zona Franca de Manaus.** Manaus tem incentivo fiscal próprio, então qualquer mudança no emprego de lá pode vir da política de incentivos, e não da taxa das blusinhas. Misturar as duas coisas quebraria a exigência do guia de DiD de que nenhum outro choque atinja o grupo tratado ao mesmo tempo. |

<br>

### - **Critério de seleção (controle):**
O grupo de controle serve para mostrar o que teria acontecido com o emprego dos setores tratados se a taxa não existisse. Para isso ele precisa de duas coisas ao mesmo tempo, e é comum lembrar só da primeira:

1. **Não ser afetado pela taxa.** O setor não pode fabricar nada que chegue por remessa internacional, seja porque o frete inviabiliza, seja porque a lei proíbe, seja porque vende para empresas e não para o consumidor.
2. **Subir e descer pelos mesmos motivos que os tratados.** Se o emprego em confecção cresce quando a renda das famílias cresce, o controle também precisa reagir à renda das famílias.

Por isso separei em dois blocos. O **controle principal** reúne setores que fabricam bem de consumo, como os tratados, e por isso acompanham o mesmo ciclo de renda e crédito. O **controle de extensão** reúne setores de insumo e de bens de capital, que atendem o critério 1 mas não o critério 2, e servem para testar se o resultado muda quando troco o grupo de comparação.

<br>

| Grupo Controle | CNAE | Descrição | Justificativa |
|---|---|---|---|
| Controle (principal) | Divisão 31 | Fabricação de móveis | É o melhor espelho disponível. Móvel é compra de consumidor, sobe e desce com a renda e o crédito das famílias, igual a roupa e calçado. Mas ninguém importa um sofá numa encomenda de US$ 50: o volume e o peso simplesmente não cabem no canal. Ou seja, sofre o mesmo ciclo econômico dos tratados sem sofrer a concorrência da remessa. |
| Controle (principal) | Divisão 21 | Fabricação de produtos farmoquímicos e farmacêuticos | Remédio também é compra de consumidor, mas está fora do canal por motivo de regra, não de frete: a Anvisa não permite que pessoa física receba medicamento por remessa postal desse jeito. Isso torna a exclusão mais segura que o argumento de peso, que sempre admite discussão. Ressalva: a demanda por remédio varia pouco com a renda, então o espelho é menos fiel nesse aspecto. |
| Controle (principal) | Divisões 10 e 11 | Fabricação de produtos alimentícios (10) e de bebidas (11) | Alimento e bebida são consumo das famílias e acompanham de perto a massa de salários, o mesmo motor dos setores tratados. Não chegam por remessa porque estragam e porque há barreira sanitária. Também são setores grandes no emprego formal, o que dá mais precisão à estimativa. Ressalva: têm ciclo próprio (safra e preço de commodities), então vale reportar o resultado com e sem essas divisões. |
| Controle (extensão/robustez) | Divisão 16 | Fabricação de produtos de madeira | Atende sobretudo construção e indústria moveleira. Madeira é pesada e volumosa, então não chega por encomenda internacional barata. O problema é que quem puxa esse setor é obra e juros, não consumo das famílias, então o paralelismo com confecção é mais frágil. Por isso fica na extensão. |
| Controle (extensão/robustez) | Divisão 17 | Fabricação de celulose, papel e produtos de papel | Vende principalmente para outras empresas (embalagem, papel para indústria) e tem valor baixo por quilo, o que inviabiliza a remessa. É um setor industrial com estrutura de emprego formal parecida, mas o ciclo de demanda dele é B2B e não de consumo. |
| Controle (extensão/robustez) | Divisão 23 | Fabricação de produtos de minerais não metálicos (cimento, vidro, cerâmica) | Cimento, vidro e cerâmica são pesados, frágeis ou vendidos a granel, e atendem o mercado interno de construção. Importar isso numa encomenda de US$ 50 é fisicamente impossível. Serve para mostrar como andou o emprego industrial em geral, com a ressalva de que depende do ritmo da construção civil. |
| Controle (extensão/robustez) | Divisão 28 | Fabricação de máquinas e equipamentos | São máquinas caras compradas por empresas, importadas pelo caminho formal de aduana quando importadas. É justamente a parte do capítulo HS 84 a 85 que o paper separa dos eletrônicos de consumo. Exposição zero à remessa. Atenção ao ponto de contaminação explicado na nota abaixo. |
| Controle (extensão/robustez) | Divisão 22 (exceto classe 22.29) | Fabricação de produtos de borracha e material plástico | Fabrica principalmente insumo e embalagem para outras empresas. Tirei a classe 22.29 porque ela inclui utilidades domésticas de plástico (potes, organizadores) que as pessoas de fato compram nas plataformas, e um controle que também é atingido pela taxa estragaria a comparação. Atenção ao ponto de contaminação explicado na nota abaixo. |
| Controle (extensão/robustez) | Divisão 25 (exceto classes 25.50 e 25.93) | Fabricação de produtos de metal, exceto máquinas | Estrutura metálica, caldeiraria e forjaria atendem construção e indústria. Tirei a 25.50 (armas), que tem regra própria, e a 25.93 (panelas, talheres, utensílios de metal), que se sobrepõe ao que vem nas remessas. Atenção ao ponto de contaminação explicado na nota abaixo. |

**Nota sobre contaminação nas divisões 22, 25 e 28:** essas divisões fornecem para os setores tratados (plástico e metal para brinquedo, bijuteria e eletroportátil; máquinas para as fábricas de roupa e calçado). Se a taxa elevou a produção nacional dos tratados, esses fornecedores também venderam e contrataram mais, ou seja, o efeito chegou ao controle pela cadeia. Como o controle deveria representar o cenário sem a taxa, isso encolhe a diferença entre os grupos e subestima o efeito.

<br>
<br>

---

### **b. Parâmetro-alvo e hipóteses de identificação**
 
#### Unidade e notação
A unidade de análise é a célula *UF × classe CNAE*, observada anualmente na RAIS (foto de 31/dez), para $t = 2019, \dots, 2025$. (vamos tomar cuidado com os anos da pandemia)
O tratamento é binário:
* $D_i = 1$ se a célula pertence aos setores tratados (produtores domésticos de bens substitutos das importações de baixo valor);
* $D_i = 0$ se pertence ao controle (setores fora do canal de remessas internacionais).
A vigência da taxa é *01/08/2024*; logo, a primeira observação pós-tratamento é a RAIS de dezembro/2024, ou seja, $g = 2024$ (adoção simultânea). O desfecho $Y_{i,t}$ é o logaritmo do emprego formal (vínculos ativos em 31/12) da célula.   
 
#### Parâmetro-alvo
O efeito médio do tratamento sobre os tratados em cada ano pós-vigência:
 
$$ATT(t) = E\left[\,Y_{i,t}(1) - Y_{i,t}(0) \mid D_i = 1\,\right], \quad t \geq 2024$$
 
Em palavras: quanto o emprego formal dos setores tratados difere, em média, do que teria sido sem a taxa. O desfecho potencial $Y_{i,t}(0)$ nunca é observado para os tratados após 2024: é isso que as hipóteses abaixo permitem reconstruir. Como a RAIS de dez/2024 captura apenas 5 meses de vigência, $ATT(2024)$ é interpretado como efeito de exposição parcial; $ATT(2025)$ é o coeficiente principal (primeiro ano cheio).

<br>
<br>

---

### **c. Painel construído (script [`painel_rais.R`](https://github.com/gabidenigris/TCC/blob/c11d83d37785f6cfbef466f41e9b0f94e6fa41ca/script/painel_rais.R))**
 
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

---
### **d. Teste de tendências paralelas (script tendencias_paralelas.R) — EM ANDAMENTO**

Amostra principal: núcleo tratado vs controle, células com emprego positivo em todos os anos (as cnaes classificadas como "extensiva" vão para robustez).       


<br>

Ideias de próximos passos

- Rodar o event study e avaliar os coeficientes pré (atenção esperada ao ruído de 2020, Covid).
- Documentação da queda das importações de remessas (Comex Stat) após agosto de 2024, já que podemos ver mês a mês, além do relatório de remessas de baixo valor da RFB sobre o PRC. 
- Variáveis adicionais: massa salarial real (deflacionada pelo IPCA) e salário médio.
