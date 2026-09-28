-- Indices escolhidos para JOIN, WHERE e ORDER BY frequentes.
-- PK e UNIQUE ja criam indices automaticamente; nao sao duplicados aqui.
SET search_path TO ecommerce, public;

-- Catalogo: filtra produtos ativos por categoria.
CREATE INDEX idx_produto_categoria_ativo
    ON produto (id_categoria, nome)
    WHERE ativo = TRUE;

-- JOIN entre produto e fornecedor.
CREATE INDEX idx_produto_fornecedor
    ON produto (id_fornecedor);

-- Busca textual no catalogo sem criar indice para todas as colunas.
CREATE INDEX idx_produto_busca_gin
    ON produto
    USING GIN (to_tsvector('portuguese', nome || ' ' || COALESCE(descricao, '')));

-- Recupera rapidamente os enderecos de um cliente.
CREATE INDEX idx_endereco_cliente
    ON endereco (id_cliente);

-- Consultas por produto e centro; complementa o UNIQUE na ordem inversa.
CREATE INDEX idx_estoque_centro_produto
    ON estoque (id_centro, id_produto);

-- Lista somente itens que exigem reposicao.
CREATE INDEX idx_estoque_reposicao
    ON estoque (id_produto)
    WHERE quantidade <= estoque_minimo;

-- Historico do cliente ja ordenado do pedido mais novo ao mais antigo.
CREATE INDEX idx_pedido_cliente_data
    ON pedido (id_cliente, criado_em DESC);

-- Painel operacional ignora pedidos concluidos ou cancelados.
CREATE INDEX idx_pedido_status_ativo
    ON pedido (status, criado_em)
    WHERE status NOT IN ('entregue', 'cancelado');

-- JOIN de produto com itens vendidos.
CREATE INDEX idx_item_pedido_produto
    ON item_pedido (id_produto);

-- Conciliacao de pagamentos por pedido e status.
CREATE INDEX idx_pagamento_pedido_status
    ON pagamento (id_pedido, status);

-- Acompanhamento das entregas por transportadora.
CREATE INDEX idx_entrega_transportadora_status
    ON entrega (id_transportadora, status);

-- Fila parcial de entregas ainda abertas.
CREATE INDEX idx_entrega_aberta_previsao
    ON entrega (previsao_entrega, status)
    WHERE status <> 'entregue';

-- Media e historico de avaliacoes por produto.
CREATE INDEX idx_avaliacao_produto_data
    ON avaliacao (id_produto, criado_em DESC);

ANALYZE;
