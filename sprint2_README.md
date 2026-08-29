# Sprint 2 — Mapa do Domínio: Loja Online (E-commerce)

## Objetivo

Modelar o domínio de uma **loja online**, cobrindo o cadastro de clientes,
produtos organizados por categoria, e o processo de pedido de compra com
seus itens.

## Entidades, Atributos e Chaves Primárias

### 1. Categoria
Classifica os produtos disponíveis na loja.
- **PK** `id_categoria`
- `nome`
- `descricao`

### 2. Produto
Item vendido na loja, sempre associado a uma categoria.
- **PK** `id_produto`
- `nome`
- `descricao`
- `preco`
- `estoque`
- **FK** `id_categoria` → Categoria

### 3. Cliente
Pessoa que realiza compras na loja.
- **PK** `id_cliente`
- `nome`
- `email`
- `telefone`
- `endereco`

### 4. Pedido
Representa uma compra feita por um cliente.
- **PK** `id_pedido`
- `data_pedido`
- `status` (PENDENTE, PAGO, ENVIADO, ENTREGUE, CANCELADO)
- **FK** `id_cliente` → Cliente

### 5. Item_Pedido (entidade associativa)
Detalha quais produtos, em qual quantidade e a qual preço, compõem cada
pedido. Existe para resolver o relacionamento N:N entre Pedido e Produto.
- **PK** `id_item`
- **FK** `id_pedido` → Pedido
- **FK** `id_produto` → Produto
- `quantidade`
- `preco_unitario`

## Relacionamentos

| Relacionamento | Cardinalidade | Descrição |
|---|---|---|
| Categoria → Produto | 1:N | Uma categoria agrupa vários produtos; um produto pertence a uma única categoria. |
| Cliente → Pedido | 1:N | Um cliente pode fazer vários pedidos; um pedido pertence a um único cliente. |
| Pedido → Item_Pedido | 1:N | Um pedido pode ter vários itens. |
| Produto → Item_Pedido | 1:N | Um produto pode aparecer em vários itens de pedidos diferentes. |
| Pedido ↔ Produto (via Item_Pedido) | N:N | Um pedido pode conter vários produtos, e um produto pode estar em vários pedidos — resolvido pela entidade associativa `Item_Pedido`. |

## Diagrama ER

O diagrama completo está no arquivo **`sprint2_diagrama_er.svg`**, mostrando
as 5 entidades, seus atributos (com PK em amarelo e FK em azul) e as
conexões de cardinalidade 1:N entre elas (notação "pé de galinha").

```
Categoria ──1:N── Produto ──1:N── Item_Pedido ──N:1── Pedido ──N:1── Cliente
```

## Implementação Física

O arquivo **`sprint2.sql`** contém:
- `CREATE TABLE` para as 5 tabelas, com tipos de dados, `PRIMARY KEY`,
  `FOREIGN KEY`, `CHECK` constraints e `UNIQUE`.
- Índices auxiliares para otimizar buscas por chave estrangeira.
- Inserts de exemplo para testar o modelo.

## Como testar

1. Rode o script `sprint2.sql` em um SGBD compatível (MySQL/MariaDB).
2. Verifique as tabelas criadas com `SHOW TABLES;`.
3. Consulte os dados de exemplo, por exemplo:
   ```sql
   SELECT p.id_pedido, c.nome AS cliente, pr.nome AS produto,
          ip.quantidade, ip.preco_unitario
   FROM pedido p
   JOIN cliente c ON c.id_cliente = p.id_cliente
   JOIN item_pedido ip ON ip.id_pedido = p.id_pedido
   JOIN produto pr ON pr.id_produto = ip.id_produto;
   ```

## Arquivos entregues

| Arquivo | Conteúdo |
|---|---|
| `sprint2_README.md` | Este documento (entidades, atributos, relacionamentos) |
| `sprint2_diagrama_er.svg` | Diagrama ER visual do modelo conceitual |
| `sprint2.sql` | Script SQL completo para criação do banco |
