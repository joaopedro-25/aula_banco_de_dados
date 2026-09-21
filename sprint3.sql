-- ============================================================
-- Sprint 3 - Modelo Logico Normalizado
-- Cenario: Loja Online (E-commerce)
-- Dialeto: MySQL / MariaDB
-- ============================================================

CREATE DATABASE IF NOT EXISTS loja_online;
USE loja_online;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS item_pedido;
DROP TABLE IF EXISTS pedido;
DROP TABLE IF EXISTS produto;
DROP TABLE IF EXISTS cliente;
DROP TABLE IF EXISTS cidade;
DROP TABLE IF EXISTS categoria;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE categoria (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    descricao VARCHAR(255)
);

CREATE TABLE cidade (
    id_cidade INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    uf CHAR(2) NOT NULL,
    CONSTRAINT uq_cidade_nome_uf UNIQUE (nome, uf),
    CONSTRAINT ck_cidade_uf
        CHECK (CHAR_LENGTH(uf) = 2 AND uf = UPPER(uf))
);

CREATE TABLE cliente (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    telefone VARCHAR(20),
    logradouro VARCHAR(150) NOT NULL,
    numero VARCHAR(15) NOT NULL,
    bairro VARCHAR(100) NOT NULL,
    cep CHAR(8) NOT NULL,
    id_cidade INT NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT ck_cliente_cep
        CHECK (cep REGEXP '^[0-9]{8}$'),
    CONSTRAINT fk_cliente_cidade
        FOREIGN KEY (id_cidade) REFERENCES cidade (id_cidade)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE produto (
    id_produto INT AUTO_INCREMENT PRIMARY KEY,
    sku VARCHAR(30) NOT NULL UNIQUE,
    nome VARCHAR(150) NOT NULL,
    descricao VARCHAR(255),
    preco DECIMAL(10, 2) NOT NULL,
    estoque INT NOT NULL DEFAULT 0,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    id_categoria INT NOT NULL,
    CONSTRAINT ck_produto_preco CHECK (preco >= 0),
    CONSTRAINT ck_produto_estoque CHECK (estoque >= 0),
    CONSTRAINT fk_produto_categoria
        FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE pedido (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    data_pedido DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(30) NOT NULL DEFAULT 'PENDENTE',
    id_cliente INT NOT NULL,
    CONSTRAINT ck_pedido_status
        CHECK (status IN (
            'PENDENTE', 'PAGO', 'ENVIADO', 'ENTREGUE', 'CANCELADO'
        )),
    CONSTRAINT fk_pedido_cliente
        FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE item_pedido (
    id_item INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL,
    id_produto INT NOT NULL,
    quantidade INT NOT NULL,
    preco_unitario DECIMAL(10, 2) NOT NULL,
    CONSTRAINT ck_item_quantidade CHECK (quantidade > 0),
    CONSTRAINT ck_item_preco CHECK (preco_unitario >= 0),
    CONSTRAINT uq_item_pedido_produto UNIQUE (id_pedido, id_produto),
    CONSTRAINT fk_item_pedido
        FOREIGN KEY (id_pedido) REFERENCES pedido (id_pedido)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_item_produto
        FOREIGN KEY (id_produto) REFERENCES produto (id_produto)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- 3 INSERTs na tabela categoria
INSERT INTO categoria (nome, descricao)
VALUES ('Eletronicos', 'Dispositivos eletronicos e acessorios');
INSERT INTO categoria (nome, descricao)
VALUES ('Livros', 'Livros fisicos e materiais de estudo');
INSERT INTO categoria (nome, descricao)
VALUES ('Casa', 'Produtos para o ambiente domestico');

-- 3 INSERTs na tabela cidade
INSERT INTO cidade (nome, uf) VALUES ('Sao Luis', 'MA');
INSERT INTO cidade (nome, uf) VALUES ('Teresina', 'PI');
INSERT INTO cidade (nome, uf) VALUES ('Fortaleza', 'CE');

-- 3 INSERTs na tabela cliente
INSERT INTO cliente
    (nome, email, telefone, logradouro, numero, bairro, cep, id_cidade)
VALUES
    ('Maria Silva', 'maria.silva@email.com', '98999990000',
     'Rua das Flores', '123', 'Centro', '65010000', 1);
INSERT INTO cliente
    (nome, email, telefone, logradouro, numero, bairro, cep, id_cidade)
VALUES
    ('Joao Souza', 'joao.souza@email.com', '86988887777',
     'Avenida Frei Serafim', '456', 'Centro', '64000020', 2);
INSERT INTO cliente
    (nome, email, telefone, logradouro, numero, bairro, cep, id_cidade)
VALUES
    ('Ana Costa', 'ana.costa@email.com', '85977776666',
     'Rua do Sol', '78', 'Aldeota', '60160120', 3);

-- 3 INSERTs na tabela produto
INSERT INTO produto
    (sku, nome, descricao, preco, estoque, id_categoria)
VALUES
    ('ELE-001', 'Fone Bluetooth',
     'Fone sem fio com cancelamento de ruido', 199.90, 50, 1);
INSERT INTO produto
    (sku, nome, descricao, preco, estoque, id_categoria)
VALUES
    ('LIV-001', 'Livro de SQL',
     'Guia pratico de banco de dados', 79.90, 30, 2);
INSERT INTO produto
    (sku, nome, descricao, preco, estoque, id_categoria)
VALUES
    ('CAS-001', 'Cafeteira Eletrica',
     'Cafeteira para 20 xicaras', 249.00, 15, 3);

-- 3 INSERTs na tabela pedido
INSERT INTO pedido (data_pedido, status, id_cliente)
VALUES ('2026-09-20 10:00:00', 'PAGO', 1);
INSERT INTO pedido (data_pedido, status, id_cliente)
VALUES ('2026-09-21 14:30:00', 'ENVIADO', 2);
INSERT INTO pedido (data_pedido, status, id_cliente)
VALUES ('2026-09-22 09:15:00', 'CANCELADO', 3);

-- 3 INSERTs na tabela item_pedido
INSERT INTO item_pedido
    (id_pedido, id_produto, quantidade, preco_unitario)
VALUES (1, 1, 1, 199.90);
INSERT INTO item_pedido
    (id_pedido, id_produto, quantidade, preco_unitario)
VALUES (2, 2, 2, 79.90);
INSERT INTO item_pedido
    (id_pedido, id_produto, quantidade, preco_unitario)
VALUES (3, 3, 1, 249.00);

-- Consulta 1: detalhes dos pedidos, clientes e produtos
SELECT
    pe.id_pedido,
    pe.data_pedido,
    pe.status,
    cl.nome AS cliente,
    ci.nome AS cidade,
    ci.uf,
    pr.nome AS produto,
    ca.nome AS categoria,
    ip.quantidade,
    ip.preco_unitario,
    ip.quantidade * ip.preco_unitario AS subtotal
FROM pedido AS pe
JOIN cliente AS cl ON cl.id_cliente = pe.id_cliente
JOIN cidade AS ci ON ci.id_cidade = cl.id_cidade
JOIN item_pedido AS ip ON ip.id_pedido = pe.id_pedido
JOIN produto AS pr ON pr.id_produto = ip.id_produto
JOIN categoria AS ca ON ca.id_categoria = pr.id_categoria
ORDER BY pe.data_pedido;

-- Consulta 2: pedidos e receita valida por categoria
SELECT
    ca.nome AS categoria,
    COUNT(DISTINCT CASE
        WHEN pe.status <> 'CANCELADO' THEN pe.id_pedido
    END) AS quantidade_pedidos,
    COALESCE(SUM(CASE
        WHEN pe.status <> 'CANCELADO'
        THEN ip.quantidade * ip.preco_unitario
        ELSE 0
    END), 0) AS receita_total
FROM categoria AS ca
LEFT JOIN produto AS pr ON pr.id_categoria = ca.id_categoria
LEFT JOIN item_pedido AS ip ON ip.id_produto = pr.id_produto
LEFT JOIN pedido AS pe ON pe.id_pedido = ip.id_pedido
GROUP BY ca.id_categoria, ca.nome
ORDER BY receita_total DESC;
