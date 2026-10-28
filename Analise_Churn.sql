-- =====================================================================
-- ANÁLISE EXPLORATÓRIA DA BASE DE DADOS
-- =====================================================================
-- 1. Mapeamento das tabelas disponíveis
-- =====================================================================

-- 1.1. Listar as tabelas disponíveis no schema db_churn
-- Objetivo: identificar as fontes de dados que poderão compor a análise.

SELECT
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'db_churn'
ORDER BY table_name;

-- =====================================================================
-- 1.2. Listar as colunas e os tipos de dados de cada tabela
-- Objetivo: identificar atributos cadastrais, datas, métricas e possíveis
-- variáveis explicativas do churn.

SELECT
    table_name,
    ordinal_position,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'db_churn'
ORDER BY table_name, ordinal_position;

-- =====================================================================
--2. Análise de volume e qualidade dos dados
-- =====================================================================
--2.1. Quantidade de registros e clientes distintos
-- =====================================================================
-- Objetivo: avaliar o tamanho da base fato e seu período de cobertura.
-- Atenção: a quantidade de registros pode ser maior que a de clientes
-- se houver várias transações ou registros por cliente.

SELECT
    COUNT(*) AS qtd_registros,
    COUNT(DISTINCT "ClientId") AS qtd_clientes_distintos,
    COUNT(*) FILTER (
        WHERE "ClientId" IS NULL
    ) AS qtd_clientes_nulos,
    COUNT(*) FILTER (
        WHERE "DataUltimaTransacao" IS NULL
    ) AS qtd_datas_nulas,
    MIN("DataUltimaTransacao") AS primeira_data,
    MAX("DataUltimaTransacao") AS ultima_data
FROM db_churn.fato_churn;

-- =====================================================================
--2.2. Verificação de registros duplicados
-- =====================================================================
-- Objetivo: identificar repetições da combinação cliente/data.
-- Atenção: duplicidade não significa necessariamente erro;
-- é preciso conhecer a granularidade da tabela fato.

SELECT
    "ClientId",
    "DataUltimaTransacao",
    COUNT(*) AS qtd_registros
FROM db_churn.fato_churn
GROUP BY
    "ClientId",
    "DataUltimaTransacao"
HAVING COUNT(*) > 1
ORDER BY qtd_registros DESC
LIMIT 100;

-- =====================================================================
--2.3. Verificar a existência de clientes sem transações
-- =====================================================================
-- Objetivo: identificar clientes cadastrados na dimensão sem registros
-- na fato. Esses clientes não devem ser classificados automaticamente
-- como churn sem validar a regra de negócio.

SELECT
    COUNT(*) AS qtd_clientes_sem_transacao
FROM db_churn.dim_clientes dc
LEFT JOIN db_churn.fato_churn fc
    ON dc."ClientId" = fc."ClientId"
WHERE fc."ClientId" IS NULL;

-- =====================================================================
--3. Análise da população de clientes
-- =====================================================================
--3.1. Comparação entre dimensão e fato
-- =====================================================================
-- Objetivo: comparar a quantidade de clientes cadastrados com a quantidade
-- de clientes que possuem registros na tabela fato.
-- Diferenças podem indicar clientes sem movimentação ou problemas de cobertura.

WITH dimensao AS (
    SELECT
        COUNT(*) AS registros_dimensao,
        COUNT(DISTINCT "ClientId") AS clientes_distintos_dimensao
    FROM db_churn.dim_clientes
),
fato AS (
    SELECT
        COUNT(DISTINCT "ClientId") AS clientes_distintos_fato
    FROM db_churn.fato_churn
)
SELECT
    d.registros_dimensao,
    d.clientes_distintos_dimensao,
    f.clientes_distintos_fato
FROM dimensao d
CROSS JOIN fato f;

-- =====================================================================
--3.2. Verificar duplicidade de clientes na dimensão
-- =====================================================================
-- Objetivo: verificar se cada ClientId aparece uma única vez na dimensão.
-- Duplicidades podem multiplicar registros em JOINs e distorcer métricas.

SELECT
    "ClientId",
    COUNT(*) AS qtd_registros
FROM db_churn.dim_clientes
GROUP BY "ClientId"
HAVING COUNT(*) > 1
ORDER BY qtd_registros DESC
LIMIT 100;

-- =====================================================================
--4. Construção da base de churn
-- =====================================================================
-- Objetivo: criar uma base analítica com uma linha por cliente,
-- última transação, data de referência, dias de inatividade e indicador de churn.
--
-- Regra adotada:
--   0 = cliente com última transação dentro da janela de 30 dias;
--   1 = cliente cuja última transação ocorreu antes da data de referência;
-- NULL = cliente sem transação registrada.
--
-- A data de referência é calculada a partir da data máxima da fato menos 30 dias.
-- A classificação é relativa à data de corte da base, não à data atual.

WITH parametros AS (
    SELECT
        MAX("DataUltimaTransacao")::date AS data_ultima,
        (
            MAX("DataUltimaTransacao")::date
            - INTERVAL '30 days'
        )::date AS data_ref
    FROM db_churn.fato_churn
),
-- Consolida o histórico para obter apenas a última transação de cada cliente.
ultima_transacao AS (
    SELECT
        "ClientId",
        MAX("DataUltimaTransacao")::date AS ultima_transacao
    FROM db_churn.fato_churn
    GROUP BY "ClientId"
),
-- Parte da dimensão para incluir também clientes sem histórico na fato.
base_clientes AS (
    SELECT
        dc."ClientId",
        ut.ultima_transacao,
        p.data_ultima,
        p.data_ref,
        -- Calcula os dias desde a última transação até a data de corte.
        CASE
            WHEN ut.ultima_transacao IS NOT NULL
            THEN p.data_ultima - ut.ultima_transacao
            ELSE NULL
        END AS dias_inatividade,
        -- Classifica clientes com histórico conforme a regra de 30 dias.
        CASE
            WHEN ut.ultima_transacao IS NULL THEN NULL
            WHEN ut.ultima_transacao < p.data_ref THEN 1
            ELSE 0
        END AS churn
    FROM db_churn.dim_clientes dc
    LEFT JOIN ultima_transacao ut
        ON dc."ClientId" = ut."ClientId"
    CROSS JOIN parametros p
)
-- Retorna a base analítica para inspeção.
SELECT *
FROM base_clientes
ORDER BY dias_inatividade DESC NULLS FIRST;

-- =====================================================================
--4.1. Tabela com a base analítica de clientes para o estudo de churn,
-- =====================================================================
-- Define as datas de referência para classificação do churn.
WITH base_datas AS (
    SELECT
        fc."ClientId",
        fc."DataUltimaTransacao",
        -- Data máxima de transação registrada na base.
        (SELECT DATE(MAX("DataUltimaTransacao"))
         FROM db_churn.fato_churn fc) AS "Ultima_data",
        -- Data de referência: 30 dias antes da última data da base.
        (SELECT DATE(MAX("DataUltimaTransacao") - INTERVAL '30 days')
         FROM db_churn.fato_churn fc) AS "Data_ref"
    FROM db_churn.fato_churn fc
    GROUP BY
        fc."ClientId",
        fc."DataUltimaTransacao"
),
-- Classifica os registros conforme a data de referência.
churn AS (
    SELECT
        b."ClientId",
        b."DataUltimaTransacao",
        b."Ultima_data",
        b."Data_ref",
        -- "Sim": última transação anterior à referência.
        -- "Não": transação dentro da janela de 30 dias.
        CASE
            WHEN "DataUltimaTransacao" >= "Data_ref" THEN 'Não'
            ELSE 'Sim'
        END AS "Churn"
    FROM base_datas b
)
-- Combina a classificação com os atributos cadastrais dos clientes.
SELECT
    dc."ClientId",
    dc."DataExtracao",
    dc."Score_Credito",
    dc."Estado",
    dc."Gênero",
    dc."Idade",
    dc."Tempo_Cliente",
    dc."Limite_Credito_Mercado",
    dc."Qte_Categorias",
    dc."Usa_Cartao_Credito",
    dc."Programa_Fidelidade",
    dc."Sum_Pedidos_Acumulados",
    ch."Ultima_data",
    ch."Data_ref",
    ch."DataUltimaTransacao",
    ch."Churn"
FROM churn ch
LEFT JOIN db_churn.dim_clientes dc
    ON ch."ClientId" = dc."ClientId";

-- =====================================================================
--5. Análise da distribuição do churn
-- =====================================================================
--5.1. Quantidade de clientes por situação
-- =====================================================================
-- Objetivo: quantificar clientes em churn, sem churn e sem histórico.
-- O percentual é calculado sobre todos os clientes da dimensão.
-- Assim, as três categorias compõem 100% da população cadastrada.

WITH parametros AS (
    SELECT
        (
            MAX("DataUltimaTransacao")::date
            - INTERVAL '30 days'
        )::date AS data_ref
    FROM db_churn.fato_churn
),
ultima_transacao AS (
    SELECT
        "ClientId",
        MAX("DataUltimaTransacao")::date AS ultima_transacao
    FROM db_churn.fato_churn
    GROUP BY "ClientId"
),
classificacao AS (
    SELECT
        dc."ClientId",
        CASE
            WHEN ut.ultima_transacao IS NULL THEN 'Sem histórico'
            WHEN ut.ultima_transacao < p.data_ref THEN 'Churn'
            ELSE 'Não Churn'
        END AS situacao
    FROM db_churn.dim_clientes dc
    LEFT JOIN ultima_transacao ut
        ON dc."ClientId" = ut."ClientId"
    CROSS JOIN parametros p
)
SELECT
    situacao,
    COUNT(*) AS qtd_clientes,
    ROUND(
        100.0 * COUNT(*)
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS percentual
FROM classificacao
GROUP BY situacao
ORDER BY qtd_clientes DESC;

-- =====================================================================
--5.2. Quantidade de clientes por situação com função de janela
-- =====================================================================
-- Calcula a última transação por cliente e a última data global da base.
WITH base AS (
    SELECT
        fc."ClientId",
        -- Última transação de cada cliente.
        MAX(fc."DataUltimaTransacao"::date)
            OVER (PARTITION BY fc."ClientId") AS last_purchase,
        -- Data mais recente de transação em toda a base.
        MAX(fc."DataUltimaTransacao"::date)
            OVER () AS last_global
    FROM db_churn.fato_churn fc
),
-- Classifica cada cliente conforme a regra de inatividade de 30 dias.
churn AS (
    SELECT DISTINCT
        "ClientId",
        last_purchase,
        last_global,
        -- 0 = Não Churn; 1 = Churn.
        CASE
            WHEN last_purchase >= last_global - INTERVAL '30 days'
                THEN 0
            ELSE 1
        END AS churn
    FROM base
)
-- Consolida os indicadores gerais de churn.
SELECT
    COUNT(*) AS qtd_clientes,
    SUM(churn) AS qtd_churn,
    COUNT(*) - SUM(churn) AS qtd_nao_churn,
    -- Percentual de clientes classificados como churn.
    ROUND(100.0 * SUM(churn) / NULLIF(COUNT(*), 0), 2) AS taxa_churn
FROM churn;

-- =====================================================================
--5.3. Taxa de churn entre clientes classificáveis
-- =====================================================================
-- Objetivo: calcular a taxa de churn apenas entre clientes com histórico.
-- Clientes sem transações não entram no denominador.
-- Essa taxa pode diferir do percentual de churn sobre toda a dimensão.

WITH parametros AS (
    SELECT
        (
            MAX("DataUltimaTransacao")::date
            - INTERVAL '30 days'
        )::date AS data_ref
    FROM db_churn.fato_churn
),
ultima_transacao AS (
    SELECT
        "ClientId",
        MAX("DataUltimaTransacao")::date AS ultima_transacao
    FROM db_churn.fato_churn
    GROUP BY "ClientId"
),
base AS (
    SELECT
        dc."ClientId",
        CASE
            WHEN ut.ultima_transacao IS NULL THEN NULL
            WHEN ut.ultima_transacao < p.data_ref THEN 1
            ELSE 0
        END AS churn
    FROM db_churn.dim_clientes dc
    LEFT JOIN ultima_transacao ut
        ON dc."ClientId" = ut."ClientId"
    CROSS JOIN parametros p
)
SELECT
    COUNT(*) FILTER (
        WHERE churn IS NOT NULL
    ) AS clientes_classificados,
    COUNT(*) FILTER (
        WHERE churn = 1
    ) AS qtd_churn,
    COUNT(*) FILTER (
        WHERE churn = 0
    ) AS qtd_nao_churn,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE churn = 1)
        / NULLIF(
            COUNT(*) FILTER (WHERE churn IS NOT NULL),
            0
        ),
        2
    ) AS taxa_churn_pct
FROM base;

-- =====================================================================
--6. Análise do tempo de inatividade
-- =====================================================================
--6.1. Distribuição dos clientes por faixa de inatividade
-- =====================================================================
-- Objetivo: entender há quanto tempo os clientes não transacionam.
-- A data de corte é a data máxima da fato.
-- As faixas permitem avaliar a concentração de clientes próximos ou
-- além do limite de 30 dias utilizado na definição inicial de churn.

WITH data_corte AS (
    SELECT
        MAX("DataUltimaTransacao")::date AS data_ultima
    FROM db_churn.fato_churn
),
ultima_transacao AS (
    SELECT
        "ClientId",
        MAX("DataUltimaTransacao")::date AS ultima_transacao
    FROM db_churn.fato_churn
    GROUP BY "ClientId"
),
inatividade AS (
    SELECT
        ut."ClientId",
        dc.data_ultima - ut.ultima_transacao AS dias_inatividade
    FROM ultima_transacao ut
    CROSS JOIN data_corte dc
),
faixas AS (
    SELECT
        CASE
            WHEN dias_inatividade <= 7 THEN '0 a 7 dias'
            WHEN dias_inatividade <= 30 THEN '8 a 30 dias'
            WHEN dias_inatividade <= 60 THEN '31 a 60 dias'
            WHEN dias_inatividade <= 90 THEN '61 a 90 dias'
            ELSE 'Mais de 90 dias'
        END AS faixa_inatividade,
        CASE
            WHEN dias_inatividade <= 7 THEN 1
            WHEN dias_inatividade <= 30 THEN 2
            WHEN dias_inatividade <= 60 THEN 3
            WHEN dias_inatividade <= 90 THEN 4
            ELSE 5
        END AS ordem_faixa
    FROM inatividade
    WHERE dias_inatividade >= 0
)
SELECT
    faixa_inatividade,
    COUNT(*) AS qtd_clientes
FROM faixas
GROUP BY
    faixa_inatividade,
    ordem_faixa
ORDER BY ordem_faixa;

-- =====================================================================
--6.2. Estatísticas descritivas dos dias de inatividade
-- =====================================================================
-- Objetivo: obter medidas de tendência central e dispersão do tempo
-- de inatividade dos clientes com histórico.
-- O percentil 50 representa a mediana, menos sensível a valores extremos
-- do que a média.

WITH data_corte AS (
    SELECT
        MAX("DataUltimaTransacao")::date AS data_ultima
    FROM db_churn.fato_churn
),
ultima_transacao AS (
    SELECT
        "ClientId",
        MAX("DataUltimaTransacao")::date AS ultima_transacao
    FROM db_churn.fato_churn
    GROUP BY "ClientId"
),
inatividade AS (
    SELECT
        dc.data_ultima - ut.ultima_transacao AS dias_inatividade
    FROM ultima_transacao ut
    CROSS JOIN data_corte dc
)
SELECT
    COUNT(*) AS qtd_clientes,
    ROUND(AVG(dias_inatividade), 2) AS media_dias,
    MIN(dias_inatividade) AS minimo_dias,
    MAX(dias_inatividade) AS maximo_dias,
    PERCENTILE_CONT(0.25)
        WITHIN GROUP (ORDER BY dias_inatividade) AS percentil_25,
    PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY dias_inatividade) AS mediana,
    PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY dias_inatividade) AS percentil_75
FROM inatividade
WHERE dias_inatividade >= 0;

-- =====================================================================
--7. Análise temporal da base
-- =====================================================================
--7.1. Volume de registros e clientes por mês
-- =====================================================================
-- Objetivo: acompanhar a evolução mensal do volume de registros e
-- da quantidade de clientes com movimentação.
-- COUNT(*) conta registros, enquanto COUNT(DISTINCT) conta clientes únicos.
-- A interpretação depende da granularidade da tabela fato.

SELECT
    DATE_TRUNC(
        'month',
        "DataUltimaTransacao"
    )::date AS mes,
    COUNT(*) AS qtd_registros,
    COUNT(DISTINCT "ClientId") AS qtd_clientes
FROM db_churn.fato_churn
WHERE "DataUltimaTransacao" IS NOT NULL
GROUP BY 1
ORDER BY 1;

-- =====================================================================
--7.2. Distribuição dos clientes por mês da última transação
-- =====================================================================
-- Objetivo: identificar em que período ocorreu a última transação
-- de cada cliente. Diferentemente da consulta anterior, cada cliente
-- é contado uma única vez no mês correspondente à sua última transação.

WITH ultima_transacao AS (
    SELECT
        "ClientId",
        MAX("DataUltimaTransacao") AS ultima_transacao
    FROM db_churn.fato_churn
    GROUP BY "ClientId"
)
SELECT
    DATE_TRUNC(
        'month',
        ultima_transacao
    )::date AS mes_ultima_transacao,
    COUNT(*) AS qtd_clientes
FROM ultima_transacao
GROUP BY 1
ORDER BY 1;

-- =====================================================================
--8. Análise de variáveis explicativas do churn
-- =====================================================================
-- Objetivo: comparar a taxa de churn entre segmentos de clientes.
-- O denominador considera somente clientes com histórico e classificação.
-- Uma taxa maior indica associação descritiva com churn, não causalidade.

-- =====================================================================
--8.1 Churn por Estado
-- =====================================================================
WITH parametros AS (
    SELECT
        (
            MAX("DataUltimaTransacao")::date
            - INTERVAL '30 days'
        )::date AS data_ref
    FROM db_churn.fato_churn
),
ultima_transacao AS (
    SELECT
        "ClientId",
        MAX("DataUltimaTransacao")::date AS ultima_transacao
    FROM db_churn.fato_churn
    GROUP BY "ClientId"
),
base AS (
    SELECT
        dc."ClientId",
        dc."Estado",
        CASE
            WHEN ut.ultima_transacao IS NULL THEN NULL
            WHEN ut.ultima_transacao < p.data_ref THEN 1
            ELSE 0
        END AS churn
    FROM db_churn.dim_clientes dc
    LEFT JOIN ultima_transacao ut
        ON dc."ClientId" = ut."ClientId"
    CROSS JOIN parametros p
)
SELECT
    "Estado",
    COUNT(*) FILTER (
        WHERE churn IS NOT NULL
    ) AS clientes_classificados,
    COUNT(*) FILTER (
        WHERE churn = 1
    ) AS qtd_churn,
    COUNT(*) FILTER (
        WHERE churn = 0
    ) AS qtd_nao_churn,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE churn = 1)
        / NULLIF(
            COUNT(*) FILTER (WHERE churn IS NOT NULL),
            0
        ),
        2
    ) AS taxa_churn_pct
FROM base
GROUP BY "Estado"
ORDER BY taxa_churn_pct DESC NULLS LAST;

-- =====================================================================
--8.2 Churn por gênero
-- =====================================================================
-- Objetivo: comparar a taxa de churn entre gêneros.

WITH parametros AS (
    SELECT
        (MAX("DataUltimaTransacao")::date - INTERVAL '30 days')::date AS data_ref
    FROM db_churn.fato_churn
),
ultima_transacao AS (
    -- Obtém a última transação de cada cliente.
    SELECT
        "ClientId",
        MAX("DataUltimaTransacao")::date AS ultima_transacao
    FROM db_churn.fato_churn
    GROUP BY "ClientId"
),
base AS (
    -- Classifica clientes com histórico de transações.
    SELECT
        dc."ClientId",
        dc."Gênero",
        CASE
            WHEN ut.ultima_transacao IS NULL THEN NULL
            WHEN ut.ultima_transacao < p.data_ref THEN 1
            ELSE 0
        END AS churn
    FROM db_churn.dim_clientes dc
    LEFT JOIN ultima_transacao ut
        ON dc."ClientId" = ut."ClientId"
    CROSS JOIN parametros p
)
SELECT
    "Gênero",
    COUNT(*) FILTER (WHERE churn IS NOT NULL) AS clientes_classificados,
    COUNT(*) FILTER (WHERE churn = 1) AS qtd_churn,
    COUNT(*) FILTER (WHERE churn = 0) AS qtd_nao_churn,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE churn = 1)
        / NULLIF(COUNT(*) FILTER (WHERE churn IS NOT NULL), 0),
        2
    ) AS taxa_churn_pct
FROM base
GROUP BY "Gênero"
ORDER BY taxa_churn_pct DESC NULLS LAST;

-- =====================================================================
--8.3 Churn por faixa etária
-- =====================================================================
-- Objetivo: identificar as faixas etárias com maior taxa de churn.
-- As faixas facilitam a comparação entre grupos de idade.

WITH parametros AS (
    SELECT
        (MAX("DataUltimaTransacao")::date - INTERVAL '30 days')::date AS data_ref
    FROM db_churn.fato_churn
),
ultima_transacao AS (
    SELECT
        "ClientId",
        MAX("DataUltimaTransacao")::date AS ultima_transacao
    FROM db_churn.fato_churn
    GROUP BY "ClientId"
),
base AS (
    SELECT
        dc."ClientId",
        CASE
            WHEN dc."Idade" IS NULL THEN 'Não informado'
            WHEN dc."Idade" < 25 THEN 'Até 24 anos'
            WHEN dc."Idade" < 35 THEN '25 a 34 anos'
            WHEN dc."Idade" < 45 THEN '35 a 44 anos'
            WHEN dc."Idade" < 55 THEN '45 a 54 anos'
            ELSE '55 anos ou mais'
        END AS faixa_etaria,
        CASE
            WHEN ut.ultima_transacao IS NULL THEN NULL
            WHEN ut.ultima_transacao < p.data_ref THEN 1
            ELSE 0
        END AS churn
    FROM db_churn.dim_clientes dc
    LEFT JOIN ultima_transacao ut
        ON dc."ClientId" = ut."ClientId"
    CROSS JOIN parametros p
)
SELECT
    faixa_etaria,
    COUNT(*) FILTER (WHERE churn IS NOT NULL) AS clientes_classificados,
    COUNT(*) FILTER (WHERE churn = 1) AS qtd_churn,
    COUNT(*) FILTER (WHERE churn = 0) AS qtd_nao_churn,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE churn = 1)
        / NULLIF(COUNT(*) FILTER (WHERE churn IS NOT NULL), 0),
        2
    ) AS taxa_churn_pct
FROM base
GROUP BY faixa_etaria
ORDER BY taxa_churn_pct DESC NULLS LAST;