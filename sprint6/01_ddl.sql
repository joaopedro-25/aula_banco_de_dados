-- Sprint 5 - Sistema de E-commerce
-- PostgreSQL 14+
DROP SCHEMA IF EXISTS ecommerce CASCADE;
CREATE SCHEMA ecommerce;
SET search_path TO ecommerce, public;

CREATE TYPE status_pedido AS ENUM ('criado', 'pago', 'separacao', 'enviado', 'entregue', 'cancelado');
CREATE TYPE metodo_pagamento AS ENUM ('pix', 'cartao_credito', 'cartao_debito', 'boleto');
CREATE TYPE status_pagamento AS ENUM ('pendente', 'aprovado', 'recusado', 'estornado');
CREATE TYPE status_entrega AS ENUM ('aguardando', 'coletado', 'em_transito', 'entregue', 'extraviado');

CREATE TABLE categoria (
    id_categoria BIGSERIAL PRIMARY KEY,
    nome TEXT NOT NULL UNIQUE,
    descricao TEXT,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE fornecedor (
    id_fornecedor BIGSERIAL PRIMARY KEY,
    razao_social TEXT NOT NULL,
    nome_fantasia TEXT NOT NULL,
    cnpj CHAR(14) NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    telefone TEXT,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_fornecedor_cnpj CHECK (cnpj ~ '^[0-9]{14}$')
);

CREATE TABLE produto (
    id_produto BIGSERIAL PRIMARY KEY,
    id_categoria BIGINT NOT NULL REFERENCES categoria(id_categoria),
    id_fornecedor BIGINT NOT NULL REFERENCES fornecedor(id_fornecedor),
    sku TEXT NOT NULL UNIQUE,
    nome TEXT NOT NULL,
    descricao TEXT,
    preco NUMERIC(12,2) NOT NULL,
    peso_kg NUMERIC(8,3),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_produto_preco CHECK (preco >= 0),
    CONSTRAINT ck_produto_peso CHECK (peso_kg IS NULL OR peso_kg > 0)
);

CREATE TABLE cliente (
    id_cliente BIGSERIAL PRIMARY KEY,
    nome TEXT NOT NULL,
    cpf CHAR(11) NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    telefone TEXT,
    data_nascimento DATE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_cliente_cpf CHECK (cpf ~ '^[0-9]{11}$'),
    CONSTRAINT ck_cliente_nascimento CHECK (data_nascimento IS NULL OR data_nascimento <= CURRENT_DATE)
);

CREATE TABLE endereco (
    id_endereco BIGSERIAL PRIMARY KEY,
    id_cliente BIGINT NOT NULL REFERENCES cliente(id_cliente) ON DELETE CASCADE,
    tipo TEXT NOT NULL DEFAULT 'entrega',
    logradouro TEXT NOT NULL,
    numero TEXT NOT NULL,
    complemento TEXT,
    bairro TEXT NOT NULL,
    cidade TEXT NOT NULL,
    uf CHAR(2) NOT NULL,
    cep CHAR(8) NOT NULL,
    principal BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT ck_endereco_tipo CHECK (tipo IN ('entrega', 'cobranca')),
    CONSTRAINT ck_endereco_uf CHECK (uf ~ '^[A-Z]{2}$'),
    CONSTRAINT ck_endereco_cep CHECK (cep ~ '^[0-9]{8}$')
);

CREATE TABLE centro_distribuicao (
    id_centro BIGSERIAL PRIMARY KEY,
    nome TEXT NOT NULL UNIQUE,
    cidade TEXT NOT NULL,
    uf CHAR(2) NOT NULL,
    capacidade INTEGER NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT ck_centro_uf CHECK (uf ~ '^[A-Z]{2}$'),
    CONSTRAINT ck_centro_capacidade CHECK (capacidade > 0)
);

CREATE TABLE estoque (
    id_estoque BIGSERIAL PRIMARY KEY,
    id_produto BIGINT NOT NULL REFERENCES produto(id_produto),
    id_centro BIGINT NOT NULL REFERENCES centro_distribuicao(id_centro),
    quantidade INTEGER NOT NULL DEFAULT 0,
    estoque_minimo INTEGER NOT NULL DEFAULT 5,
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_estoque_produto_centro UNIQUE (id_produto, id_centro),
    CONSTRAINT ck_estoque_quantidade CHECK (quantidade >= 0),
    CONSTRAINT ck_estoque_minimo CHECK (estoque_minimo >= 0)
);

CREATE TABLE pedido (
    id_pedido BIGSERIAL PRIMARY KEY,
    id_cliente BIGINT NOT NULL REFERENCES cliente(id_cliente),
    id_endereco BIGINT NOT NULL REFERENCES endereco(id_endereco),
    status status_pedido NOT NULL DEFAULT 'criado',
    valor_produtos NUMERIC(12,2) NOT NULL DEFAULT 0,
    valor_frete NUMERIC(12,2) NOT NULL DEFAULT 0,
    desconto NUMERIC(12,2) NOT NULL DEFAULT 0,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_pedido_valores CHECK (
        valor_produtos >= 0 AND valor_frete >= 0 AND desconto >= 0
        AND desconto <= valor_produtos + valor_frete
    )
);

CREATE TABLE item_pedido (
    id_item BIGSERIAL PRIMARY KEY,
    id_pedido BIGINT NOT NULL REFERENCES pedido(id_pedido) ON DELETE CASCADE,
    id_produto BIGINT NOT NULL REFERENCES produto(id_produto),
    quantidade INTEGER NOT NULL,
    preco_unitario NUMERIC(12,2) NOT NULL,
    desconto NUMERIC(12,2) NOT NULL DEFAULT 0,
    subtotal NUMERIC(14,2) GENERATED ALWAYS AS ((quantidade * preco_unitario) - desconto) STORED,
    CONSTRAINT uq_item_pedido_produto UNIQUE (id_pedido, id_produto),
    CONSTRAINT ck_item_quantidade CHECK (quantidade > 0),
    CONSTRAINT ck_item_preco CHECK (preco_unitario >= 0),
    CONSTRAINT ck_item_desconto CHECK (desconto >= 0 AND desconto <= quantidade * preco_unitario)
);

CREATE TABLE pagamento (
    id_pagamento BIGSERIAL PRIMARY KEY,
    id_pedido BIGINT NOT NULL REFERENCES pedido(id_pedido) ON DELETE CASCADE,
    metodo metodo_pagamento NOT NULL,
    status status_pagamento NOT NULL DEFAULT 'pendente',
    valor NUMERIC(12,2) NOT NULL,
    codigo_transacao TEXT UNIQUE,
    pago_em TIMESTAMPTZ,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_pagamento_valor CHECK (valor > 0),
    CONSTRAINT ck_pagamento_data CHECK (pago_em IS NULL OR pago_em >= criado_em)
);

CREATE TABLE transportadora (
    id_transportadora BIGSERIAL PRIMARY KEY,
    nome TEXT NOT NULL UNIQUE,
    cnpj CHAR(14) NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    telefone TEXT,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT ck_transportadora_cnpj CHECK (cnpj ~ '^[0-9]{14}$')
);

CREATE TABLE entrega (
    id_entrega BIGSERIAL PRIMARY KEY,
    id_pedido BIGINT NOT NULL UNIQUE REFERENCES pedido(id_pedido) ON DELETE CASCADE,
    id_transportadora BIGINT NOT NULL REFERENCES transportadora(id_transportadora),
    codigo_rastreio TEXT NOT NULL UNIQUE,
    status status_entrega NOT NULL DEFAULT 'aguardando',
    previsao_entrega DATE NOT NULL,
    entregue_em TIMESTAMPTZ,
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_entrega_data CHECK (entregue_em IS NULL OR entregue_em::DATE <= CURRENT_DATE)
);

CREATE TABLE avaliacao (
    id_avaliacao BIGSERIAL PRIMARY KEY,
    id_cliente BIGINT NOT NULL REFERENCES cliente(id_cliente) ON DELETE CASCADE,
    id_produto BIGINT NOT NULL REFERENCES produto(id_produto) ON DELETE CASCADE,
    nota SMALLINT NOT NULL,
    comentario TEXT,
    aprovado BOOLEAN NOT NULL DEFAULT FALSE,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_avaliacao_cliente_produto UNIQUE (id_cliente, id_produto),
    CONSTRAINT ck_avaliacao_nota CHECK (nota BETWEEN 1 AND 5)
);

COMMENT ON SCHEMA ecommerce IS 'Modelo fisico da Sprint 5 para um sistema de e-commerce';
