# Desafio Sprint 1 — Radar de Dados

## Cenário

O cenário escolhido foi uma loja. O banco de dados vai guardar as informações dos clientes, produtos e pedidos realizados.

## Entidades

### Cliente

Dados básicos de quem realiza os pedidos.

- `id_cliente` — identifica o cliente (PK)
- `nome`
- `email`
- `telefone`

### Produto

Informações dos produtos disponíveis na loja.

- `id_produto` — identifica o produto (PK)
- `nome`
- `preco`
- `estoque`

### Pedido

Registra as compras feitas pelos clientes.

- `id_pedido` — identifica o pedido (PK)
- `id_cliente` — identifica quem fez o pedido (FK)
- `data`
- `valor_total`
- `status`

### ItemPedido

Mostra quais produtos fazem parte de cada pedido.

- `id_item` — identifica o item (PK)
- `id_pedido` — identifica o pedido (FK)
- `id_produto` — identifica o produto (FK)
- `quantidade`
- `preco`

## Relacionamentos

**Cliente → Pedido**

Um cliente pode fazer vários pedidos, mas cada pedido pertence a um único cliente.

**1:N**

```text
Cliente 1 -------- N Pedido
```

**Pedido → ItemPedido**

Um pedido pode ter vários itens.

**1:N**

```text
Pedido 1 -------- N ItemPedido
```

**Produto → ItemPedido**

Um mesmo produto pode aparecer em vários pedidos.

**1:N**

```text
Produto 1 -------- N ItemPedido
```

Dessa forma, o relacionamento entre Pedido e Produto fica como **N:N**, usando o ItemPedido para fazer essa ligação.

## Exemplo

Um cliente faz um pedido com:

- 2 camisetas
- 1 tênis

O pedido fica ligado ao cliente e, dentro dele, ficam registrados os produtos e suas quantidades.

```text
Cliente
  ↓
Pedido
  ↓
ItemPedido
  ↓
Produto
```

## Modelo geral

```text
┌──────────────┐
│   CLIENTE    │
├──────────────┤
│ PK id_cliente│
│ nome         │
│ email        │
│ telefone     │
└──────┬───────┘
       │
       │ 1:N
       ▼
┌──────────────┐
│    PEDIDO    │
├──────────────┤
│ PK id_pedido │
│ FK id_cliente│
│ data         │
│ valor_total  │
│ status       │
└──────┬───────┘
       │
       │ 1:N
       ▼
┌──────────────┐
│ ITEM_PEDIDO  │
├──────────────┤
│ PK id_item   │
│ FK id_pedido │
│ FK id_produto│
│ quantidade   │
│ preco        │
└──────┬───────┘
       │
       │ N:1
       ▼
┌──────────────┐
│   PRODUTO    │
├──────────────┤
│ PK id_produto│
│ nome         │
│ preco        │
│ estoque      │
└──────────────┘
```

## Conceitos usados

- Entidades
- Atributos
- Chave primária (PK)
- Chave estrangeira (FK)
- Relacionamento
- Cardinalidade 1:N
- Cardinalidade N:N
