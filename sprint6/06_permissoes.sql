-- Execute como administrador do PostgreSQL.
-- Troque as senhas temporarias antes de usar em qualquer ambiente real.
SET search_path TO ecommerce, public;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ecommerce_leitura') THEN
        CREATE ROLE ecommerce_leitura NOLOGIN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ecommerce_operacao') THEN
        CREATE ROLE ecommerce_operacao NOLOGIN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ec_leitor') THEN
        CREATE ROLE ec_leitor LOGIN PASSWORD 'TROQUE_ESTA_SENHA_1';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ec_operador') THEN
        CREATE ROLE ec_operador LOGIN PASSWORD 'TROQUE_ESTA_SENHA_2';
    END IF;
END
$$;

-- Remove privilegios implicitos e aplica menor privilegio.
REVOKE ALL ON SCHEMA ecommerce FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA ecommerce FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA ecommerce FROM PUBLIC;

-- Perfil de consulta: somente leitura.
GRANT USAGE ON SCHEMA ecommerce TO ecommerce_leitura;
GRANT SELECT ON ALL TABLES IN SCHEMA ecommerce TO ecommerce_leitura;
ALTER DEFAULT PRIVILEGES IN SCHEMA ecommerce
    GRANT SELECT ON TABLES TO ecommerce_leitura;

-- Perfil operacional: le catalogo e movimenta pedido, pagamento e estoque.
GRANT USAGE ON SCHEMA ecommerce TO ecommerce_operacao;
GRANT SELECT ON ALL TABLES IN SCHEMA ecommerce TO ecommerce_operacao;
GRANT INSERT, UPDATE ON
    cliente, endereco, pedido, item_pedido, pagamento
TO ecommerce_operacao;
GRANT UPDATE (quantidade, atualizado_em) ON estoque TO ecommerce_operacao;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ecommerce TO ecommerce_operacao;

-- Bloqueios explicitos de operacoes destrutivas e estruturais.
REVOKE CREATE ON SCHEMA ecommerce FROM ecommerce_leitura, ecommerce_operacao;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE
    ON ALL TABLES IN SCHEMA ecommerce
FROM ecommerce_leitura;
REVOKE DELETE, TRUNCATE, REFERENCES, TRIGGER
    ON ALL TABLES IN SCHEMA ecommerce
FROM ecommerce_operacao;

-- Usuarios recebem as permissoes por roles de grupo.
GRANT ecommerce_leitura TO ec_leitor;
GRANT ecommerce_operacao TO ec_operador;

-- Garante que os usuarios nao herdem privilegios diretos indesejados.
REVOKE CREATE ON SCHEMA public FROM ec_leitor, ec_operador;
REVOKE ecommerce_operacao FROM ec_leitor;
REVOKE ecommerce_leitura FROM ec_operador;

-- Permite conexao ao banco atual sem fixar seu nome no script.
DO $$
BEGIN
    EXECUTE format(
        'GRANT CONNECT ON DATABASE %I TO ecommerce_leitura, ecommerce_operacao',
        current_database()
    );
END
$$;
