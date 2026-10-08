\set ON_ERROR_STOP on
SET search_path TO ecommerce, public;

-- Evidência de volume após a restauração.
WITH contagens AS (
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
)
SELECT tabela, registros
FROM contagens
ORDER BY tabela;

-- Falha o teste se alguma tabela não recuperar os 15 registros mínimos da carga.
DO $$
DECLARE
  tabelas_incompletas INTEGER;
BEGIN
  WITH contagens AS (
    SELECT COUNT(*) AS registros FROM categoria
    UNION ALL SELECT COUNT(*) FROM fornecedor
    UNION ALL SELECT COUNT(*) FROM produto
    UNION ALL SELECT COUNT(*) FROM cliente
    UNION ALL SELECT COUNT(*) FROM endereco
    UNION ALL SELECT COUNT(*) FROM centro_distribuicao
    UNION ALL SELECT COUNT(*) FROM estoque
    UNION ALL SELECT COUNT(*) FROM pedido
    UNION ALL SELECT COUNT(*) FROM item_pedido
    UNION ALL SELECT COUNT(*) FROM pagamento
    UNION ALL SELECT COUNT(*) FROM transportadora
    UNION ALL SELECT COUNT(*) FROM entrega
    UNION ALL SELECT COUNT(*) FROM avaliacao
  )
  SELECT COUNT(*)
    INTO tabelas_incompletas
    FROM contagens
   WHERE registros < 15;

  IF tabelas_incompletas > 0 THEN
    RAISE EXCEPTION 'Restauração inválida: % tabela(s) com menos de 15 registros.',
      tabelas_incompletas;
  END IF;
END
$$;

-- Integridade referencial: todas as contagens devem ser zero.
SELECT 'item_sem_pedido' AS verificacao, COUNT(*) AS inconsistencias
FROM item_pedido i
LEFT JOIN pedido p ON p.id_pedido = i.id_pedido
WHERE p.id_pedido IS NULL
UNION ALL
SELECT 'item_sem_produto', COUNT(*)
FROM item_pedido i
LEFT JOIN produto p ON p.id_produto = i.id_produto
WHERE p.id_produto IS NULL
UNION ALL
SELECT 'pedido_sem_cliente', COUNT(*)
FROM pedido p
LEFT JOIN cliente c ON c.id_cliente = p.id_cliente
WHERE c.id_cliente IS NULL
UNION ALL
SELECT 'estoque_sem_produto', COUNT(*)
FROM estoque e
LEFT JOIN produto p ON p.id_produto = e.id_produto
WHERE p.id_produto IS NULL
UNION ALL
SELECT 'entrega_sem_pedido', COUNT(*)
FROM entrega e
LEFT JOIN pedido p ON p.id_pedido = e.id_pedido
WHERE p.id_pedido IS NULL
ORDER BY verificacao;

SELECT 'RESTAURACAO_VALIDADA' AS resultado;
