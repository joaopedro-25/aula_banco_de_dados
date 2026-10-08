-- Planos reais de execucao. Rode depois de 01, 02 e 03.
SET search_path TO ecommerce, public;

ANALYZE cliente;
ANALYZE pedido;
ANALYZE produto;
ANALYZE item_pedido;
ANALYZE entrega;

-- 1. Historico de pedidos de um cliente.
-- Indice candidato: idx_pedido_cliente_data.
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT pe.id_pedido, pe.status, pe.criado_em,
       pe.valor_produtos + pe.valor_frete - pe.desconto AS total
FROM pedido AS pe
WHERE pe.id_cliente = 5
ORDER BY pe.criado_em DESC;

-- 2. Vendas por categoria, usando indices de produto e item.
-- Indices candidatos: idx_produto_categoria_ativo e idx_item_pedido_produto.
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT pr.id_produto, pr.nome,
       SUM(ip.quantidade) AS unidades,
       SUM(ip.subtotal) AS receita
FROM produto AS pr
JOIN item_pedido AS ip ON ip.id_produto = pr.id_produto
WHERE pr.id_categoria = 5
  AND pr.ativo = TRUE
GROUP BY pr.id_produto, pr.nome
ORDER BY receita DESC;

-- 3. Fila de entregas abertas por prazo.
-- Indice candidato: idx_entrega_aberta_previsao.
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT en.id_entrega, en.codigo_rastreio, en.status, en.previsao_entrega
FROM entrega AS en
WHERE en.status <> 'entregue'
  AND en.previsao_entrega <= CURRENT_DATE + 7
ORDER BY en.previsao_entrega;

-- Como analisar:
-- Index Scan, Index Only Scan ou Bitmap Index Scan indica uso de indice.
-- Seq Scan pode ser correto nas tabelas pequenas da carga inicial (15 linhas).
-- Compare estimated rows com actual rows, execution time e Buffers.
-- Em volume real, execute ANALYZE novamente antes de comparar os planos.
