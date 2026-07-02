# Trabalho de Conclusão de Curso (in progress)

Bacharelado em Economia — Instituto Brasileiro de Mercado de Capitais (Ibmec Brasília)
Autora: **Gabriela De Nigris**
Orientador: **Prof. Raphael Rocha Gouvea, PhD**
2026

## Resumo
 
Este trabalho investiga o impacto econômico da "Taxa das Blusinhas" (tarifa de importação de 20% sobre remessas de e-commerce de baixo valor abaixo de US$ 50), sobre o emprego formal de estabelecimentos afetados pela concorrencia internacional. A análise utiliza dados em painel da RAIS via BigQuery e um desenho de diferenças em diferenças (difference-in-differences) para estimar o efeito causal da política sobre os estabelecimentos afetados.

**Principais referências metodológicas:**
- Baker, Callaway, Cunningham, Goodman-Bacon & Sant'Anna (2025). *Difference-in-Differences Designs: A Practitioner's Guide*.
- Fajgelbaum, Khandelwal, et al. (2025). *The Value of de Minimis Imports*.

## Estrutura do repositório

```
TCC/
├── README.md
│
├── redação
│    └── overleaf (in process)
│  
├── referencial
│    ├── Baker, et al. (2025) "Difference-in-Differences Designs: A Practitioner’s Guide".pdf
│    └── Fajgelbaum, et al. (2025) "The Value of de Minimis Imports".pdf
│
├── script
│    ├── README.md
|    ├── rais_estabeleciemntos.R
|    ├── camex.R
│    └── did_2x2.R
│ 
├── output/
│    ├── grafico_1.png
│    ├── grafico_2.png
│    ├── tabela_1.png
│    └── tabela_2.png
│
└── data/
     ├── rais.xlsx
     ├── camex.xlsx
     └── PRC.xlsx
            
```


