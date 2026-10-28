# Retenção de Clientes: Análise de Churn em um Aplicativo de Delivery

Projeto de análise de dados utilizando SQL, Excel e Power BI, com o objetivo de identificar fatores associados ao churn de clientes em um aplicativo fictício de delivery, compreender os perfis com maior risco de abandono e propor estratégias para aumentar a retenção e a satisfação dos clientes.

## Sobre o projeto

O ToComFome é um aplicativo fictício de delivery de alimentos, com atuação nos estados de São Paulo, Minas Gerais e Rio de Janeiro.

A equipe de CRM identificou a necessidade de compreender os fatores que levam os clientes a deixarem de realizar pedidos na plataforma. Para isso, foi desenvolvido um projeto de análise de dados com foco na identificação de padrões de comportamento, na segmentação de clientes e na elaboração de estratégias para reduzir o churn.

Neste projeto, o churn foi definido como a ausência de pedidos nos últimos 30 dias em relação à data de referência.

A principal pergunta de negócio foi:

**Quais fatores estão associados ao churn de clientes e quais ações podem ser implementadas para aumentar a retenção?**

## Objetivos

- Calcular a taxa de churn da base de clientes.
- Identificar características associadas ao abandono do aplicativo.
- Analisar o perfil dos clientes com maior taxa de churn.
- Identificar os fatores com maior poder discriminatório por meio do Information Value (IV).
- Investigar relações entre idade, estado, categorias de produtos e programa de fidelidade.
- Segmentar clientes com maior risco de churn nos próximos quatro meses.
- Propor ações para melhorar a retenção e a satisfação dos clientes.
- Desenvolver indicadores para monitoramento contínuo do churn.

## Ferramentas utilizadas

- **SQL (PostgreSQL):** consultas ao banco de dados, exploração das tabelas, criação de variáveis, cálculo da taxa de churn e análises agregadas.
- **Excel:** organização dos resultados, análises complementares, tabelas e exploração dos dados.
- **Power BI:** criação de dashboard interativo para visualização dos indicadores e acompanhamento do churn.

## Metodologia

O projeto utiliza como referência a metodologia CRISP-DM (*Cross-Industry Standard Process for Data Mining*), composta por seis etapas:

1. **Entendimento do negócio:** definição do problema, dos objetivos e dos critérios de sucesso.
2. **Entendimento dos dados:** exploração das tabelas, identificação das variáveis e compreensão da estrutura da base.
3. **Preparação dos dados:** validação dos dados e criação das variáveis necessárias para a análise.
4. **Modelagem:** aplicação de análises estatísticas e técnicas de avaliação da relevância das variáveis.
5. **Avaliação:** interpretação dos resultados e validação das conclusões em relação ao problema de negócio.
6. **Implantação:** elaboração de um plano de ação e acompanhamento dos indicadores.

## Base de dados

A base foi disponibilizada pela Escola Preditiva.ai e consultada por meio do PostgreSQL.

O banco de dados utilizado contém o schema `db_churn`, com as seguintes tabelas:

- `dim_clientes`: informações cadastrais e características dos clientes.
- `fato_churn`: informações relacionadas ao comportamento de compra e aos dados utilizados na análise.

As tabelas utilizam o campo `ClientId` como chave primária, conforme a estrutura apresentada no estudo original.

A base contém informações de 10.000 clientes e 14 variáveis, incluindo identificadores, datas, variáveis quantitativas, binárias e qualitativas.

Segundo a análise inicial, os dados disponibilizados já estavam tratados. Entretanto, foi necessário criar variáveis auxiliares e a variável-alvo `Churn` para atender aos objetivos do projeto.

<img width="720" height="454" alt="image" src="https://github.com/user-attachments/assets/558ceb61-18f8-4108-a3f5-2abc00b2ee0c" />


### Definição da variável Churn

Foram utilizadas as seguintes referências temporais:

- **Ultima_data:** última data de compra registrada na base, correspondente a 30/10/2019.
- **Data_ref:** data de referência definida como 30 dias antes da última data de compra, correspondente a 30/09/2019.
- **Churn:** variável binária que identifica os clientes que não realizaram pedidos nos últimos 30 dias em relação à data de referência.

A variável `Churn` assume os seguintes valores:

- `1`: cliente classificado como churn.
- `0`: cliente que não foi classificado como churn.

## Análises realizadas

### 1. Consultas e exploração dos dados com SQL

Foram desenvolvidas consultas SQL para compreender a estrutura das tabelas, identificar as variáveis disponíveis, calcular indicadores e investigar o comportamento dos clientes.

As consultas permitiram criar a variável de churn, calcular sua taxa e analisar a distribuição dos resultados entre diferentes grupos de clientes.

### 2. Análise exploratória de dados (AED)

A análise exploratória foi realizada para compreender as características dos clientes e identificar padrões relevantes para o negócio.

Foram analisadas variáveis como:

- Idade dos clientes.
- Tempo de relacionamento com o aplicativo.
- Limite de crédito.
- Quantidade de categorias de produtos consumidas.
- Receita acumulada por cliente.
- Estado de atuação.
- Forma de pagamento.
- Gênero.
- Participação no programa de fidelidade.

As variáveis quantitativas foram agrupadas em faixas quando necessário, facilitando a comparação entre grupos e a interpretação das taxas de churn.

### 3. Análise bivariada

Foram investigadas as taxas de churn de acordo com diferentes características dos clientes, buscando identificar grupos com maior incidência de abandono.

A análise também permitiu observar possíveis relações entre as variáveis e levantar hipóteses sobre os fatores que poderiam contribuir para a perda de clientes.

### 4. Information Value (IV)

O Information Value foi utilizado para avaliar o poder discriminatório das variáveis em relação ao churn.

Essa técnica ajudou a priorizar os fatores com maior capacidade de distinguir clientes classificados como churn daqueles que permaneceram ativos.

Os resultados destacaram quatro variáveis prioritárias para investigação:

- Idade.
- Quantidade de categorias de produtos consumidas.
- Estado.
- Participação no programa de fidelidade.

### 5. Análise de receita e comportamento de compra

Foram realizadas análises complementares para investigar a relação entre churn, receita e comportamento de compra.

As análises consideraram a distribuição da receita por faixa etária, a quantidade de categorias consumidas e as diferenças observadas entre os estados de atuação.

O objetivo foi compreender quais grupos poderiam representar maior risco de perda de clientes e de receita para o aplicativo.

### 6. Visualização dos resultados no Power BI

Os resultados obtidos por meio das consultas SQL e das análises complementares foram organizados em um dashboard no Power BI.

A visualização facilita a exploração dos indicadores, a comparação entre grupos e o acompanhamento dos fatores associados ao churn.

## Principais resultados

A análise exploratória identificou os seguintes resultados:

| Indicador | Resultado |
|---|---:|
| Total de clientes | 10.000 |
| Clientes classificados como churn | 2.013 |
| Taxa de churn | 20,13% |
| Receita média por cliente | R$ 416,54 |
| Participação no programa de fidelidade | 51,51% |

A taxa de churn de 20,13% indica que aproximadamente um em cada cinco clientes da base não realizou pedidos durante o período de referência definido no estudo.

### Perfil dos clientes

- A idade dos clientes variou de 18 a 92 anos.
- Aproximadamente 71,06% dos clientes tinham até 42 anos.
- O tempo de relacionamento com o aplicativo variou de zero a dez meses.
- Cerca de 50,84% dos clientes compravam produtos de apenas uma categoria.
- Aproximadamente 96,74% dos clientes compravam produtos de até duas categorias.
- O cartão de crédito foi a forma de pagamento predominante, representando 70,55% das transações.
- Os clientes do sexo masculino representavam 54,57% da base.
- Aproximadamente 51,51% dos clientes participavam do programa de fidelidade.

### Distribuição geográfica

São Paulo concentrou a maior participação nos pedidos e no faturamento, representando aproximadamente 50,14% dos pedidos e 50,04% da receita.

Apesar disso, Minas Gerais apresentou uma taxa de churn consideravelmente superior à observada nos outros estados, tornando-se uma região prioritária para investigação.

### Variáveis de maior relevância

#### Idade

A idade apresentou Information Value classificado como muito forte no estudo.

Os resultados indicaram taxas de churn mais elevadas entre clientes com 40 anos ou mais, com destaque para:

- Clientes entre 45 e 50 anos: taxa de churn de 43,65%.
- Clientes com 50 anos ou mais: taxa de churn de 44,25%.

Esses resultados sugerem a necessidade de investigar possíveis dificuldades de navegação, acessibilidade, experiência de uso e outros fatores relacionados ao comportamento de compra desse público.

#### Quantidade de categorias

A quantidade de categorias consumidas também apresentou elevado poder discriminatório.

Os clientes que realizavam pedidos em três ou quatro categorias apresentaram taxa de churn de 84,36%, em comparação com 17,97% entre aqueles que compravam em uma ou duas categorias.

Entretanto, os clientes que compravam em três ou quatro categorias representavam apenas 3,26% da base. Por isso, os resultados desse grupo devem ser interpretados com cautela e investigados com análises adicionais.

#### Estado

Minas Gerais apresentou taxa de churn de 32,04%, enquanto os demais estados apresentaram, em conjunto, uma média aproximada de 16,2%.

A análise também identificou diferenças no perfil de consumo e na participação de determinados grupos de clientes na receita estadual.

Esses resultados indicam a necessidade de investigar possíveis diferenças regionais relacionadas à disponibilidade de produtos, preços, descontos, concorrência, divulgação e experiência de uso do aplicativo.

#### Programa de fidelidade

Os clientes que não participavam do programa de fidelidade apresentaram taxa de churn de 26,52%, enquanto aqueles que participavam apresentaram taxa de 14,11%.

Essa diferença sugere que o programa de fidelidade pode estar associado à retenção dos clientes, embora não seja possível afirmar, apenas com esses dados, que a participação no programa seja a causa da redução do churn.

### Receita e risco de churn

A análise identificou diferenças relevantes na distribuição da receita entre os grupos de clientes.

- Aproximadamente 90% da receita era proveniente de clientes com até 52 anos.
- O ticket médio por cliente foi semelhante entre os estados:
  - São Paulo: R$ 415,74.
  - Rio de Janeiro: R$ 413,84.
  - Minas Gerais: R$ 420,81.
- A perda de receita associada ao churn representou 31,2% da receita em Minas Gerais, em comparação com uma média aproximada de 17% nos outros estados.

Os resultados reforçam a importância de investigar o comportamento dos clientes de Minas Gerais e os fatores associados à perda de receita nessa região.

## Plano de ação

Com base nos resultados, foram identificadas oportunidades de melhoria que podem ser organizadas e priorizadas com o apoio de um plano de ação estruturado.

As principais frentes recomendadas são:

- **Experiência do usuário:** investigar possíveis dificuldades de navegação e acessibilidade, especialmente entre clientes com maior idade.
- **Diversificação de compras:** compreender as barreiras que dificultam a compra em diferentes categorias de produtos.
- **Estratégia regional:** investigar as causas da maior taxa de churn em Minas Gerais, considerando preços, disponibilidade de produtos, concorrência, marketing e condições de entrega.
- **Programa de fidelidade:** avaliar a divulgação, os benefícios e a adesão ao programa, buscando ampliar sua efetividade na retenção.
- **Relacionamento com clientes:** desenvolver ações direcionadas a grupos com maior risco de abandono.
- **Monitoramento:** acompanhar mensalmente a taxa de churn e os indicadores relacionados durante 12 meses.

As iniciativas devem ser validadas pela área de negócio, considerando a viabilidade operacional, os custos e o impacto esperado.

## Segmentação e acompanhamento

Uma das propostas do projeto é identificar clientes com maior probabilidade de churn nos quatro meses seguintes à data de referência.

Essa segmentação pode apoiar ações preventivas de CRM, como campanhas personalizadas, ofertas, incentivos ao uso do aplicativo e comunicações direcionadas.

A classificação de risco deve ser tratada como uma estimativa, e não como uma certeza de que o cliente abandonará o serviço. Sua qualidade deverá ser avaliada com dados adequados e validação posterior.

Para acompanhar a efetividade das ações, recomenda-se monitorar:

- Taxa mensal de churn.
- Quantidade de clientes recuperados.
- Receita associada aos clientes retidos.
- Taxa de adesão ao programa de fidelidade.
- Frequência de compra.
- Quantidade de categorias consumidas por cliente.
- Taxa de churn por estado e faixa etária.
- Evolução dos indicadores antes e depois das iniciativas.

## Conclusão

O projeto demonstra como SQL, Excel e Power BI podem ser utilizados de forma complementar para investigar o comportamento dos clientes e apoiar decisões estratégicas de CRM.

A análise identificou uma taxa de churn de 20,13% e destacou idade, quantidade de categorias consumidas, estado e participação no programa de fidelidade como variáveis prioritárias para investigação.

Os resultados podem apoiar iniciativas de melhoria da experiência do usuário, aprimoramento do programa de fidelidade, personalização de campanhas e desenvolvimento de estratégias regionais de retenção.

É importante ressaltar que associações estatísticas não comprovam causalidade. Além disso, a identificação de fatores associados ao churn não equivale, por si só, à construção e validação de um modelo preditivo. A eficácia das ações deverá ser avaliada por meio de monitoramento contínuo, validação estatística e acompanhamento dos resultados no contexto real do negócio.

## Tecnologias

- SQL
- PostgreSQL
- DBeaver
- Excel
- Power BI
- CRISP-DM
- Análise Exploratória de Dados (AED)
- Análise Bivariada
- Information Value (IV)
- Segmentação de Clientes
- Indicadores de CRM

## Referências

- Escola Preditiva.ai. Materiais sobre a metodologia CRISP-DM e preparação de dados.
- Thebilab. *Information Value (IV): O que é, Como Calcular e sua Importância para a Análise de Dados*.
- SEBRAE. Material de referência sobre a ferramenta 5W2H.
- Ekyte. *O que é Churn e como aplicar essa métrica no marketing*.

## Artigo completo

Para conferir a análise completa, as consultas SQL, os gráficos, os resultados detalhados e o plano de ação, acesse o artigo original no Medium:

**Artigo:** [Retenção de clientes: como SQL, Excel e Power BI podem auxiliar a diminuir o Churn em um aplicativo de delivery?](https://medium.com/@maironhenrique/reten%C3%A7%C3%A3o-de-clientes-como-sql-excel-e-power-bi-podem-auxiliar-a-diminuir-o-churn-em-um-aplicativo-6cc583d433eb)

**Autor:** Mairon Henrique de Oliveira

## Autor

**Mairon Henrique de Oliveira**

- **LinkedIn:** [linkedin.com/in/maironhenriquedeoliveira](https://www.linkedin.com/in/maironhenriquedeoliveira)
- **E-mail**: maironhenrique@hotmail.com
- 📊 [Portfólio com análises no Medium](https://medium.com/@maironhenrique)
- 📈 [Portfólio com Dashboards](https://app.xperiun.com/in/maironhenrique)

---

**Objetivo do projeto:** transformar dados em informações úteis para compreender o churn, identificar clientes com maior risco de abandono e apoiar estratégias de retenção e crescimento sustentável.
