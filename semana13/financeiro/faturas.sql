CREATE SCHEMA IF NOT EXISTS erp_financeiro;
SET search_path TO erp_financeiro;
CREATE TABLE IF NOT EXISTS faturas (id bigint PRIMARY KEY, cliente_id bigint NOT NULL, valor numeric(12,2) NOT NULL CHECK(valor>0), status text NOT NULL);
INSERT INTO faturas VALUES (1,1,150.00,'paga'),(2,2,250.00,'paga') ON CONFLICT(id) DO NOTHING;
SELECT SUM(valor) AS total_faturado FROM faturas WHERE status='paga';
CREATE TABLE IF NOT EXISTS contas (id bigint PRIMARY KEY, saldo numeric(12,2) NOT NULL CHECK(saldo>=0));
INSERT INTO contas VALUES (1,100) ON CONFLICT(id) DO NOTHING;
BEGIN;
DO $$ BEGIN
 UPDATE contas SET saldo=saldo-40 WHERE id=1 AND saldo>=40;
 IF NOT FOUND THEN RAISE EXCEPTION 'Saldo insuficiente'; END IF;
END $$;
COMMIT;
BEGIN;
SAVEPOINT tentativa;
-- Falha intencional. Execute em psql sem ON_ERROR_STOP neste arquivo.
UPDATE contas SET saldo=saldo-100000 WHERE id=1;
ROLLBACK TO SAVEPOINT tentativa;
ROLLBACK;
SELECT * FROM contas;
