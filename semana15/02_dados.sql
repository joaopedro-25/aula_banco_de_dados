SET search_path TO semana15;
INSERT INTO cliente(id,nome,email) VALUES(1,'Cliente Exemplo','cliente@example.com') ON CONFLICT DO NOTHING;
INSERT INTO produto(id,nome,sku,preco,estoque) VALUES(1,'Caderno','CAD-01',20,10) ON CONFLICT DO NOTHING;
INSERT INTO pedido(id,cliente_id,status) VALUES(1,1,'criado') ON CONFLICT DO NOTHING;
INSERT INTO item_pedido VALUES(1,1,2,20) ON CONFLICT DO NOTHING;
SELECT p.id,c.nome,SUM(i.quantidade*i.preco_unitario) AS total FROM pedido p JOIN cliente c ON c.id=p.cliente_id JOIN item_pedido i ON i.pedido_id=p.id GROUP BY p.id,c.nome;
SELECT setval(pg_get_serial_sequence('pedido','id'),(SELECT max(id) FROM pedido));
-- Bônus com exceção capturada e rollback automático do sub-bloco.
DO $$ BEGIN
 BEGIN
  INSERT INTO pedido(cliente_id,status) VALUES(99999,'criado');
  RAISE EXCEPTION 'Teste falhou: FK inválida foi aceita';
 EXCEPTION WHEN foreign_key_violation THEN RAISE NOTICE 'PASS: FK inexistente rejeitada';
 END;
END $$;
