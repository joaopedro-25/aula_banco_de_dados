SET search_path TO semana16;
INSERT INTO cliente(id,nome,email) SELECT n,'Cliente '||n,'cliente'||n||'@example.com' FROM generate_series(1,5) n ON CONFLICT DO NOTHING;
INSERT INTO produto(id,nome,sku,preco,estoque) SELECT n,'Produto '||n,'SKU-'||n,10*n,100 FROM generate_series(1,5) n ON CONFLICT DO NOTHING;
INSERT INTO pedido(id,cliente_id,status) SELECT n,n,'criado' FROM generate_series(1,5) n ON CONFLICT DO NOTHING;
INSERT INTO item_pedido SELECT n,n,2,10*n FROM generate_series(1,5) n ON CONFLICT DO NOTHING;
SELECT setval(pg_get_serial_sequence('cliente','id'),(SELECT max(id) FROM cliente));
SELECT setval(pg_get_serial_sequence('produto','id'),(SELECT max(id) FROM produto));
SELECT setval(pg_get_serial_sequence('pedido','id'),(SELECT max(id) FROM pedido));
