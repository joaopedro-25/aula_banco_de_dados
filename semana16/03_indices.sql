SET search_path TO semana16;
CREATE INDEX IF NOT EXISTS idx_pedido_cliente ON pedido(cliente_id);
CREATE INDEX IF NOT EXISTS idx_pedido_status_data ON pedido(status,criado_em);
ANALYZE;
EXPLAIN ANALYZE SELECT * FROM pedido WHERE cliente_id=1;
EXPLAIN ANALYZE SELECT * FROM pedido WHERE status='criado' ORDER BY criado_em;
-- Cinco linhas podem justificar Seq Scan. Compare novamente com carga maior.
