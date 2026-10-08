-- Carga inicial: 15 registros por tabela (195 registros no total)
BEGIN;
SET search_path TO ecommerce, public;

INSERT INTO categoria (nome, descricao)
SELECT 'Categoria ' || LPAD(g::TEXT, 2, '0'), 'Linha de produtos ' || g
FROM generate_series(1, 15) AS g;

INSERT INTO fornecedor (razao_social, nome_fantasia, cnpj, email, telefone)
SELECT
    'Fornecedor ' || g || ' LTDA',
    'Parceiro ' || g,
    LPAD(g::TEXT, 14, '0'),
    'fornecedor' || g || '@exemplo.com',
    '(11) 4000-' || LPAD(g::TEXT, 4, '0')
FROM generate_series(1, 15) AS g;

INSERT INTO produto (id_categoria, id_fornecedor, sku, nome, descricao, preco, peso_kg)
SELECT
    g,
    g,
    'SKU-' || LPAD(g::TEXT, 5, '0'),
    'Produto ' || g,
    'Produto de demonstracao ' || g,
    ROUND((49.90 * g)::NUMERIC, 2),
    ROUND((0.25 * g)::NUMERIC, 3)
FROM generate_series(1, 15) AS g;

INSERT INTO cliente (nome, cpf, email, telefone, data_nascimento)
SELECT
    'Cliente ' || g,
    LPAD(g::TEXT, 11, '0'),
    'cliente' || g || '@exemplo.com',
    '(21) 90000-' || LPAD(g::TEXT, 4, '0'),
    DATE '1985-01-01' + (g * INTERVAL '180 days')
FROM generate_series(1, 15) AS g;

INSERT INTO endereco (
    id_cliente, tipo, logradouro, numero, bairro, cidade, uf, cep, principal
)
SELECT
    g,
    CASE WHEN g % 3 = 0 THEN 'cobranca' ELSE 'entrega' END,
    'Rua Exemplo ' || g,
    (100 + g)::TEXT,
    'Bairro ' || g,
    CASE WHEN g % 3 = 0 THEN 'Rio de Janeiro' WHEN g % 3 = 1 THEN 'Sao Paulo' ELSE 'Curitiba' END,
    CASE WHEN g % 3 = 0 THEN 'RJ' WHEN g % 3 = 1 THEN 'SP' ELSE 'PR' END,
    (10000000 + g)::TEXT,
    TRUE
FROM generate_series(1, 15) AS g;

INSERT INTO centro_distribuicao (nome, cidade, uf, capacidade)
SELECT
    'CD ' || LPAD(g::TEXT, 2, '0'),
    CASE WHEN g % 3 = 0 THEN 'Campinas' WHEN g % 3 = 1 THEN 'Barueri' ELSE 'Joinville' END,
    CASE WHEN g % 3 = 0 THEN 'SP' WHEN g % 3 = 1 THEN 'SP' ELSE 'SC' END,
    1000 + (g * 250)
FROM generate_series(1, 15) AS g;

INSERT INTO estoque (id_produto, id_centro, quantidade, estoque_minimo)
SELECT g, g, 20 + (g * 3), 10 + (g % 5)
FROM generate_series(1, 15) AS g;

INSERT INTO pedido (
    id_cliente, id_endereco, status, valor_produtos, valor_frete, desconto, criado_em, atualizado_em
)
SELECT
    g,
    g,
    (CASE
        WHEN g % 6 = 0 THEN 'cancelado'
        WHEN g % 5 = 0 THEN 'entregue'
        WHEN g % 4 = 0 THEN 'enviado'
        WHEN g % 3 = 0 THEN 'separacao'
        WHEN g % 2 = 0 THEN 'pago'
        ELSE 'criado'
    END)::status_pedido,
    ROUND((49.90 * g * ((g % 3) + 1))::NUMERIC, 2),
    ROUND((12 + g)::NUMERIC, 2),
    CASE WHEN g % 5 = 0 THEN 10.00 ELSE 0.00 END,
    CURRENT_TIMESTAMP - (g * INTERVAL '1 day'),
    CURRENT_TIMESTAMP - (g * INTERVAL '12 hours')
FROM generate_series(1, 15) AS g;

INSERT INTO item_pedido (id_pedido, id_produto, quantidade, preco_unitario, desconto)
SELECT
    g,
    g,
    (g % 3) + 1,
    p.preco,
    0
FROM generate_series(1, 15) AS g
JOIN produto AS p ON p.id_produto = g;

INSERT INTO pagamento (id_pedido, metodo, status, valor, codigo_transacao, pago_em, criado_em)
SELECT
    g,
    (CASE
        WHEN g % 4 = 0 THEN 'boleto'
        WHEN g % 4 = 1 THEN 'pix'
        WHEN g % 4 = 2 THEN 'cartao_credito'
        ELSE 'cartao_debito'
    END)::metodo_pagamento,
    (CASE WHEN g % 4 = 0 THEN 'pendente' ELSE 'aprovado' END)::status_pagamento,
    ROUND((49.90 * g * ((g % 3) + 1) + 12 + g - CASE WHEN g % 5 = 0 THEN 10 ELSE 0 END)::NUMERIC, 2),
    'TX-' || LPAD(g::TEXT, 8, '0'),
    CASE WHEN g % 4 = 0 THEN NULL ELSE CURRENT_TIMESTAMP - (g * INTERVAL '1 day') + INTERVAL '1 hour' END,
    CURRENT_TIMESTAMP - (g * INTERVAL '1 day')
FROM generate_series(1, 15) AS g;

INSERT INTO transportadora (nome, cnpj, email, telefone)
SELECT
    'Transportadora ' || g,
    (90000000000000 + g)::TEXT,
    'transportadora' || g || '@exemplo.com',
    '(31) 3000-' || LPAD(g::TEXT, 4, '0')
FROM generate_series(1, 15) AS g;

INSERT INTO entrega (
    id_pedido, id_transportadora, codigo_rastreio, status, previsao_entrega, entregue_em
)
SELECT
    g,
    g,
    'BR' || LPAD(g::TEXT, 10, '0'),
    (CASE
        WHEN g % 5 = 0 THEN 'entregue'
        WHEN g % 3 = 0 THEN 'em_transito'
        WHEN g % 2 = 0 THEN 'coletado'
        ELSE 'aguardando'
    END)::status_entrega,
    CURRENT_DATE + (g % 7),
    CASE WHEN g % 5 = 0 THEN CURRENT_TIMESTAMP - (g * INTERVAL '1 hour') ELSE NULL END
FROM generate_series(1, 15) AS g;

INSERT INTO avaliacao (id_cliente, id_produto, nota, comentario, aprovado, criado_em)
SELECT
    g,
    g,
    ((g - 1) % 5) + 1,
    'Avaliacao de demonstracao do produto ' || g,
    g % 3 <> 0,
    CURRENT_TIMESTAMP - (g * INTERVAL '2 hours')
FROM generate_series(1, 15) AS g;

COMMIT;

-- Conferencia: cada resultado deve ser 15.
SELECT 'categoria' AS tabela, COUNT(*) AS registros FROM categoria
UNION ALL SELECT 'fornecedor', COUNT(*) FROM fornecedor
UNION ALL SELECT 'produto', COUNT(*) FROM produto
UNION ALL SELECT 'cliente', COUNT(*) FROM cliente
UNION ALL SELECT 'endereco', COUNT(*) FROM endereco
UNION ALL SELECT 'centro_distribuicao', COUNT(*) FROM centro_distribuicao
UNION ALL SELECT 'estoque', COUNT(*) FROM estoque
UNION ALL SELECT 'pedido', COUNT(*) FROM pedido
UNION ALL SELECT 'item_pedido', COUNT(*) FROM item_pedido
UNION ALL SELECT 'pagamento', COUNT(*) FROM pagamento
UNION ALL SELECT 'transportadora', COUNT(*) FROM transportadora
UNION ALL SELECT 'entrega', COUNT(*) FROM entrega
UNION ALL SELECT 'avaliacao', COUNT(*) FROM avaliacao
ORDER BY tabela;
