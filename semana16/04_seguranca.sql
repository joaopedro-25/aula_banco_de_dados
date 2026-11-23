-- Executar como administrador da base de laboratório.
DO $$ BEGIN
 IF NOT EXISTS(SELECT FROM pg_roles WHERE rolname='ceuma_admin') THEN CREATE ROLE ceuma_admin LOGIN; END IF;
 IF NOT EXISTS(SELECT FROM pg_roles WHERE rolname='ceuma_analista') THEN CREATE ROLE ceuma_analista LOGIN; END IF;
END $$;
GRANT USAGE ON SCHEMA semana16 TO ceuma_admin,ceuma_analista;
GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA semana16 TO ceuma_admin;
GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA semana16 TO ceuma_admin;
GRANT SELECT ON ALL TABLES IN SCHEMA semana16 TO ceuma_analista;
SET ROLE ceuma_analista;
SELECT count(*) FROM semana16.cliente;
DO $$ BEGIN
 BEGIN
  DELETE FROM semana16.cliente WHERE id=-1;
  RAISE EXCEPTION 'Teste falhou: DELETE autorizado';
 EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS: DELETE negado ao analista';
 END;
END $$;
RESET ROLE;
-- Defina credenciais fora do script, com o comando interativo \password no psql.
