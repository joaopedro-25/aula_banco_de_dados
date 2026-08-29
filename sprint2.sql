-- ============================================================
-- Sprint 2 - Mapa do Domínio
-- Cenário: Loja Online (E-commerce)
-- Modelo Conceitual -> Implementação Física (DDL)
-- ============================================================

CREATE DATABASE IF NOT EXISTS loja_online;
USE loja_online;

-- ------------------------------------------------------------
-- Tabela: Categoria
-- Entidade independente. Classifica os produtos.
-- ------------------------------------------------------------
CREATE TABLE categoria (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nome         VARCHAR(100) NOT NULL,
    descricao    VARCHAR(255)
);

-- ------------------------------------------------------------
-- Tabela: Cliente
-- Entidade independente. Representa quem realiza os pedidos.
-- ------------------------------------------------------------
CREATE TABLE cliente (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nome       VARCHAR(150) NOT NULL,
    email      VARCHAR(150) NOT NULL UNIQUE,
    telefone   VARCHAR(20),
    endereco   VARCHAR(255)
);

-- ------------------------------------------------------------
-- Tabela: Produto
-- Depende de Categoria (N:1). Um produto pertence a uma categoria,
-- uma categoria pode ter muitos produtos.
-- ------------------------------------------------------------
CREATE TABLE produto (
    id_produto   INT AUTO_INCREMENT PRIMARY KEY,
    nome         VARCHAR(150) NOT NULL,
    descricao    VARCHAR(255),
    preco        DECIMAL(10,2) NOT NULL CHECK (preco >= 0),
    estoque      INT NOT NULL DEFAULT 0 CHECK (estoque >= 0),
    id_categoria INT NOT NULL,
    CONSTRAINT fk_produto_categoria
        FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- ------------------------------------------------------------
-- Tabela: Pedido
-- Depende de Cliente (N:1). Um cliente pode fazer muitos pedidos,
-- cada pedido pertence a um único cliente.
-- ------------------------------------------------------------
CREATE TABLE pedido (
    id_pedido    INT AUTO_INCREMENT PRIMARY KEY,
    data_pedido  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status       VARCHAR(30) NOT NULL DEFAULT 'PENDENTE'
                 CHECK (status IN ('PENDENTE','PAGO','ENVIADO','ENTREGUE','CANCELADO')),
    id_cliente   INT NOT NULL,
    CONSTRAINT fk_pedido_cliente
        FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- ------------------------------------------------------------
-- Tabela: Item_Pedido (entidade associativa)
-- Resolve o relacionamento N:N entre Pedido e Produto,
-- guardando quantidade e preço praticado no momento da venda.
-- ------------------------------------------------------------
CREATE TABLE item_pedido (
    id_item        INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido      INT NOT NULL,
    id_produto     INT NOT NULL,
    quantidade     INT NOT NULL CHECK (quantidade > 0),
    preco_unitario DECIMAL(10,2) NOT NULL CHECK (preco_unitario >= 0),
    CONSTRAINT fk_item_pedido
        FOREIGN KEY (id_pedido) REFERENCES pedido (id_pedido)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_item_produto
        FOREIGN KEY (id_produto) REFERENCES produto (id_produto)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT uq_item_pedido_produto UNIQUE (id_pedido, id_produto)
);

-- ------------------------------------------------------------
-- Índices auxiliares para consultas frequentes
-- ------------------------------------------------------------
CREATE INDEX idx_produto_categoria ON produto (id_categoria);
CREATE INDEX idx_pedido_cliente    ON pedido (id_cliente);
CREATE INDEX idx_item_pedido       ON item_pedido (id_pedido);
CREATE INDEX idx_item_produto      ON item_pedido (id_produto);

-- ------------------------------------------------------------
-- Dados de exemplo (opcional, para testes)
-- ------------------------------------------------------------
INSERT INTO categoria (nome, descricao) VALUES
    ('Eletrônicos', 'Dispositivos eletrônicos em geral'),
    ('Livros', 'Livros físicos e digitais');

INSERT INTO cliente (nome, email, telefone, endereco) VALUES
    ('Maria Silva', 'maria.silva@email.com', '98999990000', 'Rua A, 123 - São Luís/MA'),
    ('João Souza', 'joao.souza@email.com', '98988887777', 'Av. B, 456 - São Luís/MA');

INSERT INTO produto (nome, descricao, preco, estoque, id_categoria) VALUES
    ('Fone Bluetooth', 'Fone sem fio com cancelamento de ruído', 199.90, 50, 1),
    ('Livro de SQL', 'Guia prático de banco de dados', 79.90, 30, 2);

INSERT INTO pedido (id_cliente, status) VALUES
    (1, 'PENDENTE');

INSERT INTO item_pedido (id_pedido, id_produto, quantidade, preco_unitario) VALUES
    (1, 1, 1, 199.90),
    (1, 2, 2, 79.90);
