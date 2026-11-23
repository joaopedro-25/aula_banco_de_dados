SET search_path TO semana16;
-- Bloqueio do pedido e atualização condicional do estoque evitam dupla confirmação.
CREATE OR REPLACE FUNCTION confirmar_pedido(alvo bigint) RETURNS void LANGUAGE plpgsql AS $$
DECLARE estado text; item record;
BEGIN
 SELECT status INTO estado FROM pedido WHERE id=alvo FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Pedido inexistente'; END IF;
 IF estado='pago' THEN RETURN; END IF;
 IF estado<>'criado' THEN RAISE EXCEPTION 'Estado inválido'; END IF;
 IF NOT EXISTS(SELECT FROM item_pedido WHERE pedido_id=alvo) THEN RAISE EXCEPTION 'Pedido vazio'; END IF;
 FOR item IN SELECT * FROM item_pedido WHERE pedido_id=alvo ORDER BY produto_id LOOP
  UPDATE produto SET estoque=estoque-item.quantidade WHERE id=item.produto_id AND estoque>=item.quantidade;
  IF NOT FOUND THEN RAISE EXCEPTION 'Estoque insuficiente'; END IF;
 END LOOP;
 UPDATE pedido SET status='pago' WHERE id=alvo;
END $$;
BEGIN;
SELECT confirmar_pedido(1);
COMMIT;
SELECT status FROM pedido WHERE id=1;
-- Falha real com tentativa de saldo negativo. O sub-bloco desfaz a alteração.
BEGIN;
DO $$ DECLARE antes integer; BEGIN
 SELECT estoque INTO antes FROM produto WHERE id=2;
 BEGIN
  UPDATE produto SET estoque=estoque-1 WHERE id=2;
  UPDATE produto SET estoque=-1 WHERE id=2;
 EXCEPTION WHEN check_violation THEN RAISE NOTICE 'Falha esperada e alterações revertidas';
 END;
 IF (SELECT estoque FROM produto WHERE id=2)<>antes THEN RAISE EXCEPTION 'Rollback falhou'; END IF;
END $$;
ROLLBACK;
SELECT id,estoque FROM produto ORDER BY id;
