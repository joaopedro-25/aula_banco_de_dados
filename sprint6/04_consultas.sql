-- 13 consultas de negocio: JOIN, GROUP BY, HAVING, subconsulta, CTE e janela.
SET search_path TO ecommerce, public;

-- 1. Detalhes dos pedidos com cliente e produtos.
SELECT pe.id_pedido, c.nome AS cliente, pe.status, pr.sku, pr.nome AS produto,
       ip.quantidade, ip.preco_unitario, ip.subtotal
FROM pedido AS pe
JOIN cliente AS c ON c.id_cliente = pe.id_cliente
JOIN item_pedido AS ip ON ip.id_pedido = pe.id_pedido
JOIN produto AS pr ON pr.id_produto = ip.id_produto
ORDER BY pe.criado_em DESC;

-- 2. Receita e unidades vendidas por categoria.
SELECT ca.nome AS categoria,
       SUM(ip.quantidade) AS unidades,
       SUM(ip.subtotal) AS receita
FROM categoria AS ca
JOIN produto AS pr ON pr.id_categoria = ca.id_categoria
JOIN item_pedido AS ip ON ip.id_produto = pr.id_produto
JOIN pedido AS pe ON pe.id_pedido = ip.id_pedido
WHERE pe.status <> 'cancelado'
GROUP BY ca.id_categoria, ca.nome
ORDER BY receita DESC;

-- 3. Clientes com gasto acima de R$ 500.
SELECT c.id_cliente, c.nome,
       SUM(pg.valor) FILTER (WHERE pg.status = 'aprovado') AS total_pago
FROM cliente AS c
JOIN pedido AS pe ON pe.id_cliente = c.id_cliente
JOIN pagamento AS pg ON pg.id_pedido = pe.id_pedido
GROUP BY c.id_cliente, c.nome
HAVING SUM(pg.valor) FILTER (WHERE pg.status = 'aprovado') > 500
ORDER BY total_pago DESC;

-- 4. Produtos com preco acima da media do catalogo.
SELECT id_produto, sku, nome, preco
FROM produto
WHERE preco > (SELECT AVG(preco) FROM produto WHERE ativo = TRUE)
ORDER BY preco DESC;

-- 5. Estoque abaixo ou igual ao minimo.
SELECT pr.sku, pr.nome, cd.nome AS centro,
       es.quantidade, es.estoque_minimo
FROM estoque AS es
JOIN produto AS pr ON pr.id_produto = es.id_produto
JOIN centro_distribuicao AS cd ON cd.id_centro = es.id_centro
WHERE es.quantidade <= es.estoque_minimo
ORDER BY es.quantidade;

-- 6. Acompanhamento de entregas abertas.
SELECT en.codigo_rastreio, pe.id_pedido, c.nome AS cliente,
       tr.nome AS transportadora, en.status, en.previsao_entrega
FROM entrega AS en
JOIN pedido AS pe ON pe.id_pedido = en.id_pedido
JOIN cliente AS c ON c.id_cliente = pe.id_cliente
JOIN transportadora AS tr ON tr.id_transportadora = en.id_transportadora
WHERE en.status <> 'entregue'
ORDER BY en.previsao_entrega;

-- 7. Resumo financeiro por metodo.
SELECT metodo, status, COUNT(*) AS pagamentos, SUM(valor) AS total
FROM pagamento
GROUP BY metodo, status
ORDER BY metodo, status;

-- 8. Nota media e quantidade de avaliacoes por produto.
SELECT pr.id_produto, pr.nome,
       ROUND(AVG(av.nota)::NUMERIC, 2) AS nota_media,
       COUNT(av.id_avaliacao) AS avaliacoes
FROM produto AS pr
LEFT JOIN avaliacao AS av
       ON av.id_produto = pr.id_produto AND av.aprovado = TRUE
GROUP BY pr.id_produto, pr.nome
ORDER BY nota_media DESC NULLS LAST, avaliacoes DESC;

-- 9. Fornecedores e quantidade de produtos ativos.
SELECT f.id_fornecedor, f.nome_fantasia,
       COUNT(pr.id_produto) AS produtos_ativos
FROM fornecedor AS f
LEFT JOIN produto AS pr
       ON pr.id_fornecedor = f.id_fornecedor AND pr.ativo = TRUE
GROUP BY f.id_fornecedor, f.nome_fantasia
ORDER BY produtos_ativos DESC, f.nome_fantasia;

-- 10. Clientes que ainda nao fizeram pedido.
SELECT c.id_cliente, c.nome, c.email
FROM cliente AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM pedido AS pe
    WHERE pe.id_cliente = c.id_cliente
)
ORDER BY c.nome;

-- 11. Pedido mais recente de cada cliente usando funcao de janela.
WITH pedidos_ordenados AS (
    SELECT pe.id_pedido, pe.id_cliente, pe.status, pe.criado_em,
           ROW_NUMBER() OVER (
               PARTITION BY pe.id_cliente
               ORDER BY pe.criado_em DESC
           ) AS posicao
    FROM pedido AS pe
)
SELECT c.nome AS cliente, po.id_pedido, po.status, po.criado_em
FROM pedidos_ordenados AS po
JOIN cliente AS c ON c.id_cliente = po.id_cliente
WHERE po.posicao = 1
ORDER BY c.nome;

-- 12. Capacidade e ocupacao por centro de distribuicao.
SELECT cd.id_centro, cd.nome, cd.capacidade,
       COALESCE(SUM(es.quantidade), 0) AS itens_armazenados,
       ROUND(
           100.0 * COALESCE(SUM(es.quantidade), 0) / cd.capacidade,
           2
       ) AS ocupacao_percentual
FROM centro_distribuicao AS cd
LEFT JOIN estoque AS es ON es.id_centro = cd.id_centro
GROUP BY cd.id_centro, cd.nome, cd.capacidade
ORDER BY ocupacao_percentual DESC;

-- 13. Pesquisa textual no nome e descricao do produto.
SELECT id_produto, sku, nome, preco
FROM produto
WHERE to_tsvector('portuguese', nome || ' ' || COALESCE(descricao, ''))
      @@ plainto_tsquery('portuguese', 'produto demonstracao')
ORDER BY nome;
