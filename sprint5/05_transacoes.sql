-- Transacao 1: cadastro completo de cliente e primeira compra.
BEGIN;
SET LOCAL search_path TO ecommerce, public;

WITH novo_cliente AS (
    INSERT INTO cliente (nome, cpf, email, telefone)
    VALUES ('Cliente Transacao A', '99999999991', 'transacao.a@exemplo.com', '(11) 99999-0001')
    RETURNING id_cliente
),
novo_endereco AS (
    INSERT INTO endereco (
        id_cliente, tipo, logradouro, numero, bairro, cidade, uf, cep, principal
    )
    SELECT id_cliente, 'entrega', 'Rua ACID', '100', 'Centro', 'Sao Paulo', 'SP', '01001000', TRUE
    FROM novo_cliente
    RETURNING id_cliente, id_endereco
),
novo_pedido AS (
    INSERT INTO pedido (
        id_cliente, id_endereco, status, valor_produtos, valor_frete, desconto
    )
    SELECT id_cliente, id_endereco, 'pago', 99.80, 15.00, 0
    FROM novo_endereco
    RETURNING id_pedido
),
novo_item AS (
    INSERT INTO item_pedido (
        id_pedido, id_produto, quantidade, preco_unitario, desconto
    )
    SELECT id_pedido, 1, 2, 49.90, 0
    FROM novo_pedido
    RETURNING id_pedido
)
INSERT INTO pagamento (
    id_pedido, metodo, status, valor, codigo_transacao, pago_em
)
SELECT id_pedido, 'pix', 'aprovado', 114.80, 'TX-TRANSACAO-A', CURRENT_TIMESTAMP
FROM novo_item
RETURNING id_pagamento, id_pedido;

COMMIT;

-- Transacao 2: compra com bloqueio de estoque e SAVEPOINT.
BEGIN;
SET LOCAL search_path TO ecommerce, public;

SELECT id_estoque, quantidade
FROM estoque
WHERE id_produto = 2 AND id_centro = 2
FOR UPDATE;

SAVEPOINT antes_do_teste_preco;

-- Alteracao experimental desfeita sem cancelar toda a transacao.
UPDATE produto
SET preco = preco * 1.10
WHERE id_produto = 2;

ROLLBACK TO SAVEPOINT antes_do_teste_preco;

WITH novo_pedido AS (
    INSERT INTO pedido (
        id_cliente, id_endereco, status, valor_produtos, valor_frete, desconto
    )
    VALUES (2, 2, 'pago', 99.80, 20.00, 0)
    RETURNING id_pedido
),
novo_item AS (
    INSERT INTO item_pedido (
        id_pedido, id_produto, quantidade, preco_unitario, desconto
    )
    SELECT id_pedido, 2, 1, 99.80, 0
    FROM novo_pedido
    RETURNING id_pedido
),
baixa_estoque AS (
    UPDATE estoque
    SET quantidade = quantidade - 1,
        atualizado_em = CURRENT_TIMESTAMP
    WHERE id_produto = 2
      AND id_centro = 2
      AND quantidade >= 1
    RETURNING id_produto
)
INSERT INTO pagamento (
    id_pedido, metodo, status, valor, codigo_transacao, pago_em
)
SELECT ni.id_pedido, 'cartao_credito', 'aprovado', 119.80,
       'TX-TRANSACAO-B', CURRENT_TIMESTAMP
FROM novo_item AS ni
CROSS JOIN baixa_estoque AS be
RETURNING id_pagamento, id_pedido;

COMMIT;

-- Transacao 3: demonstracao de ROLLBACK total.
-- Nenhum dos registros de teste permanece no banco.
BEGIN;
SET LOCAL search_path TO ecommerce, public;

WITH categoria_teste AS (
    INSERT INTO categoria (nome, descricao)
    VALUES ('Categoria temporaria', 'Registro para testar rollback')
    RETURNING id_categoria
)
INSERT INTO produto (
    id_categoria, id_fornecedor, sku, nome, descricao, preco, peso_kg
)
SELECT id_categoria, 1, 'SKU-ROLLBACK', 'Produto temporario',
       'Este produto sera desfeito', 10.00, 0.100
FROM categoria_teste
RETURNING id_produto, id_categoria;

ROLLBACK;
