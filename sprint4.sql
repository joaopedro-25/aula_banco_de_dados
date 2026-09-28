-- Sprint 4 - Modelagem fisica PostgreSQL
-- Projeto: Loja Online
-- Execute com usuario administrador no PostgreSQL 15+.

CREATE SCHEMA IF NOT EXISTS loja;
SET search_path TO loja, public;

-- ============================================================
-- 1. MODELO FISICO
-- ============================================================

DROP TABLE IF EXISTS loja.item_pedido CASCADE;
DROP TABLE IF EXISTS loja.pedido CASCADE;
DROP TABLE IF EXISTS loja.produto CASCADE;
DROP TABLE IF EXISTS loja.cliente CASCADE;
DROP TABLE IF EXISTS loja.cidade CASCADE;
DROP TABLE IF EXISTS loja.categoria CASCADE;
DROP TYPE IF EXISTS loja.status_pedido;

CREATE TYPE loja.status_pedido AS ENUM (
    'PENDENTE',
    'PAGO',
    'ENVIADO',
    'ENTREGUE',
    'CANCELADO'
);

CREATE TABLE loja.categoria (
    id_categoria BIGSERIAL PRIMARY KEY,
    nome TEXT NOT NULL UNIQUE,
    descricao TEXT,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE loja.cidade (
    id_cidade BIGSERIAL PRIMARY KEY,
    nome TEXT NOT NULL,
    uf CHAR(2) NOT NULL,
    CONSTRAINT uq_cidade_nome_uf UNIQUE (nome, uf),
    CONSTRAINT ck_cidade_uf
        CHECK (uf = UPPER(uf) AND CHAR_LENGTH(uf) = 2)
);

CREATE TABLE loja.cliente (
    id_cliente BIGSERIAL PRIMARY KEY,
    nome TEXT NOT NULL,
    email TEXT NOT NULL,
    telefone TEXT,
    logradouro TEXT NOT NULL,
    numero TEXT NOT NULL,
    bairro TEXT NOT NULL,
    cep CHAR(8) NOT NULL,
    id_cidade BIGINT NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_cliente_cep CHECK (cep ~ '^[0-9]{8}$'),
    CONSTRAINT fk_cliente_cidade
        FOREIGN KEY (id_cidade)
        REFERENCES loja.cidade (id_cidade)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE loja.produto (
    id_produto BIGSERIAL PRIMARY KEY,
    sku TEXT NOT NULL UNIQUE,
    nome TEXT NOT NULL,
    descricao TEXT,
    preco NUMERIC(12, 2) NOT NULL,
    estoque INTEGER NOT NULL DEFAULT 0,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    id_categoria BIGINT NOT NULL,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_produto_preco CHECK (preco >= 0),
    CONSTRAINT ck_produto_estoque CHECK (estoque >= 0),
    CONSTRAINT fk_produto_categoria
        FOREIGN KEY (id_categoria)
        REFERENCES loja.categoria (id_categoria)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE loja.pedido (
    id_pedido BIGSERIAL PRIMARY KEY,
    data_pedido TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status loja.status_pedido NOT NULL DEFAULT 'PENDENTE',
    id_cliente BIGINT NOT NULL,
    valor_total NUMERIC(14, 2) NOT NULL DEFAULT 0,
    observacao TEXT,
    CONSTRAINT ck_pedido_valor CHECK (valor_total >= 0),
    CONSTRAINT fk_pedido_cliente
        FOREIGN KEY (id_cliente)
        REFERENCES loja.cliente (id_cliente)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE loja.item_pedido (
    id_item BIGSERIAL PRIMARY KEY,
    id_pedido BIGINT NOT NULL,
    id_produto BIGINT NOT NULL,
    quantidade INTEGER NOT NULL,
    preco_unitario NUMERIC(12, 2) NOT NULL,
    subtotal NUMERIC(14, 2)
        GENERATED ALWAYS AS (quantidade * preco_unitario) STORED,
    CONSTRAINT uq_item_pedido_produto UNIQUE (id_pedido, id_produto),
    CONSTRAINT ck_item_quantidade CHECK (quantidade > 0),
    CONSTRAINT ck_item_preco CHECK (preco_unitario >= 0),
    CONSTRAINT fk_item_pedido
        FOREIGN KEY (id_pedido)
        REFERENCES loja.pedido (id_pedido)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_item_produto
        FOREIGN KEY (id_produto)
        REFERENCES loja.produto (id_produto)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- ============================================================
-- 2. INDICES
-- ============================================================

-- Garante email sem duplicidade, ignorando maiusculas/minusculas.
CREATE UNIQUE INDEX uq_cliente_email_ci
    ON loja.cliente (LOWER(email));

-- Acelera JOIN e filtro de clientes por cidade.
CREATE INDEX idx_cliente_cidade
    ON loja.cliente (id_cidade);

-- Acelera JOIN e filtro de produtos por categoria.
CREATE INDEX idx_produto_categoria
    ON loja.produto (id_categoria);

-- Acelera historico de pedidos de um cliente em ordem cronologica.
CREATE INDEX idx_pedido_cliente_data
    ON loja.pedido (id_cliente, data_pedido DESC);

-- Indice parcial: somente pedidos ativos usados em relatorios.
CREATE INDEX idx_pedido_ativo_data
    ON loja.pedido (data_pedido DESC)
    WHERE status <> 'CANCELADO';

-- Acelera JOIN dos itens com pedido e produto.
CREATE INDEX idx_item_pedido_pedido
    ON loja.item_pedido (id_pedido);

CREATE INDEX idx_item_pedido_produto
    ON loja.item_pedido (id_produto);

-- ============================================================
-- 3. DADOS BASE
-- ============================================================

INSERT INTO loja.categoria (nome, descricao) VALUES
    ('Eletronicos', 'Dispositivos e acessorios'),
    ('Livros', 'Livros e materiais de estudo'),
    ('Casa', 'Produtos para ambiente domestico');

INSERT INTO loja.cidade (nome, uf) VALUES
    ('Sao Luis', 'MA'),
    ('Teresina', 'PI'),
    ('Fortaleza', 'CE');

INSERT INTO loja.produto
    (sku, nome, descricao, preco, estoque, id_categoria)
SELECT
    dados.sku,
    dados.nome,
    dados.descricao,
    dados.preco,
    dados.estoque,
    categoria.id_categoria
FROM (VALUES
    ('ELE-001', 'Fone Bluetooth', 'Fone sem fio', 199.90, 50, 'Eletronicos'),
    ('LIV-001', 'Livro de SQL', 'Guia de banco de dados', 79.90, 30, 'Livros'),
    ('CAS-001', 'Cafeteira Eletrica', 'Cafeteira para 20 xicaras', 249.00, 15, 'Casa')
) AS dados (sku, nome, descricao, preco, estoque, categoria_nome)
JOIN loja.categoria
    ON categoria.nome = dados.categoria_nome;

-- ============================================================
-- 4. TRANSACAO 1
-- Insere cliente, pedido e item. IDs capturados com RETURNING.
-- ============================================================

BEGIN;

WITH novo_cliente AS (
    INSERT INTO loja.cliente (
        nome, email, telefone, logradouro, numero, bairro, cep, id_cidade
    )
    SELECT
        'Maria Silva',
        'maria.silva@email.com',
        '98999990000',
        'Rua das Flores',
        '123',
        'Centro',
        '65010000',
        cidade.id_cidade
    FROM loja.cidade AS cidade
    WHERE cidade.nome = 'Sao Luis' AND cidade.uf = 'MA'
    RETURNING id_cliente
),
novo_pedido AS (
    INSERT INTO loja.pedido (id_cliente, status, valor_total, observacao)
    SELECT
        novo_cliente.id_cliente,
        'PAGO',
        199.90,
        'Compra criada pela transacao 1'
    FROM novo_cliente
    RETURNING id_pedido
)
INSERT INTO loja.item_pedido (
    id_pedido, id_produto, quantidade, preco_unitario
)
SELECT
    novo_pedido.id_pedido,
    produto.id_produto,
    1,
    produto.preco
FROM novo_pedido
JOIN loja.produto AS produto ON produto.sku = 'ELE-001'
RETURNING id_item, id_pedido, id_produto, subtotal;

COMMIT;

-- ============================================================
-- 5. TRANSACAO 2
-- Insere categoria, produto, pedido e item; usa SAVEPOINT.
-- ============================================================

BEGIN;

WITH nova_categoria AS (
    INSERT INTO loja.categoria (nome, descricao)
    VALUES ('Games', 'Jogos e perifericos')
    RETURNING id_categoria
),
novo_produto AS (
    INSERT INTO loja.produto (
        sku, nome, descricao, preco, estoque, id_categoria
    )
    SELECT
        'GAM-001',
        'Teclado Mecanico',
        'Teclado para jogos',
        349.90,
        20,
        nova_categoria.id_categoria
    FROM nova_categoria
    RETURNING id_produto, sku
)
SELECT id_produto, sku FROM novo_produto;

SAVEPOINT antes_ajuste_preco;

-- Ajuste experimental descartado.
UPDATE loja.produto
SET preco = preco * 0.50,
    atualizado_em = CURRENT_TIMESTAMP
WHERE sku = 'GAM-001'
RETURNING id_produto, preco;

ROLLBACK TO SAVEPOINT antes_ajuste_preco;
RELEASE SAVEPOINT antes_ajuste_preco;

WITH novo_pedido AS (
    INSERT INTO loja.pedido (id_cliente, status, valor_total, observacao)
    SELECT
        cliente.id_cliente,
        'PENDENTE',
        produto.preco * 2,
        'Compra criada pela transacao 2'
    FROM loja.cliente AS cliente
    CROSS JOIN loja.produto AS produto
    WHERE LOWER(cliente.email) = LOWER('maria.silva@email.com')
      AND produto.sku = 'GAM-001'
    RETURNING id_pedido
)
INSERT INTO loja.item_pedido (
    id_pedido, id_produto, quantidade, preco_unitario
)
SELECT
    novo_pedido.id_pedido,
    produto.id_produto,
    2,
    produto.preco
FROM novo_pedido
JOIN loja.produto AS produto ON produto.sku = 'GAM-001'
RETURNING id_item, id_pedido, id_produto, subtotal;

COMMIT;

-- Atualiza estatisticas antes da analise de planos.
ANALYZE loja.cliente;
ANALYZE loja.produto;
ANALYZE loja.pedido;
ANALYZE loja.item_pedido;

-- ============================================================
-- 6. EXPLAIN ANALYZE
-- ============================================================

-- Consulta 1: indice uq_cliente_email_ci e idx_pedido_cliente_data.
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
    pedido.id_pedido,
    pedido.data_pedido,
    pedido.status,
    pedido.valor_total
FROM loja.cliente AS cliente
JOIN loja.pedido AS pedido
    ON pedido.id_cliente = cliente.id_cliente
WHERE LOWER(cliente.email) = LOWER('maria.silva@email.com')
ORDER BY pedido.data_pedido DESC;

-- Consulta 2: indices de categoria, produto e item.
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
    categoria.nome AS categoria,
    produto.nome AS produto,
    SUM(item.quantidade) AS unidades_vendidas,
    SUM(item.subtotal) AS receita
FROM loja.categoria AS categoria
JOIN loja.produto AS produto
    ON produto.id_categoria = categoria.id_categoria
JOIN loja.item_pedido AS item
    ON item.id_produto = produto.id_produto
WHERE categoria.nome = 'Eletronicos'
  AND produto.ativo = TRUE
GROUP BY categoria.nome, produto.id_produto, produto.nome
ORDER BY receita DESC;

-- ============================================================
-- 7. CONTROLE DE ACESSO
-- Execute esta secao com usuario autorizado a criar roles.
-- Troque as senhas de exemplo antes de ambiente real.
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'loja_operacao') THEN
        CREATE ROLE loja_operacao NOLOGIN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'loja_leitor') THEN
        CREATE USER loja_leitor
            WITH PASSWORD 'Troque_Esta_Senha_Leitor_2026!';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'loja_operador') THEN
        CREATE USER loja_operador
            WITH PASSWORD 'Troque_Esta_Senha_Operador_2026!';
    END IF;
END
$$;

REVOKE CREATE ON SCHEMA loja FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA loja FROM PUBLIC;

GRANT USAGE ON SCHEMA loja TO loja_leitor, loja_operacao;
GRANT SELECT ON ALL TABLES IN SCHEMA loja TO loja_leitor;

GRANT SELECT, INSERT, UPDATE
    ON loja.cliente, loja.pedido, loja.item_pedido
    TO loja_operacao;

GRANT SELECT
    ON loja.cidade, loja.categoria, loja.produto
    TO loja_operacao;

GRANT USAGE, SELECT
    ON ALL SEQUENCES IN SCHEMA loja
    TO loja_operacao;

GRANT loja_operacao TO loja_operador;

-- Menor privilegio: nenhum usuario da aplicacao pode apagar dados.
REVOKE DELETE ON ALL TABLES IN SCHEMA loja
    FROM loja_leitor, loja_operacao;

ALTER DEFAULT PRIVILEGES IN SCHEMA loja
    GRANT SELECT ON TABLES TO loja_leitor;

ALTER DEFAULT PRIVILEGES IN SCHEMA loja
    GRANT SELECT, INSERT, UPDATE ON TABLES TO loja_operacao;

ALTER DEFAULT PRIVILEGES IN SCHEMA loja
    GRANT USAGE, SELECT ON SEQUENCES TO loja_operacao;
