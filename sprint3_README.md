# Sprint 3 - Modelo Lógico: Loja Online

Continuação do modelo conceitual da Sprint 2. O domínio de e-commerce foi transformado em um modelo lógico para MySQL/MariaDB, normalizado até a Terceira Forma Normal (3FN).

## Entregáveis

- [sprint3_modelo_logico.md](sprint3_modelo_logico.md): diagrama lógico em Mermaid, atributos, PKs, FKs e cardinalidades.
- [sprint3.sql](sprint3.sql): DDL, restrições, 3 INSERTs por tabela e 2 consultas com JOIN.
- [sprint3_README.md](sprint3_README.md): decisões de modelagem e dependências eliminadas na normalização.

## Modelo desenvolvido

O modelo mantém o domínio da Sprint 2 e possui seis tabelas:

- `categoria`: classificação dos produtos.
- `cidade`: cadastro único de cidade e UF.
- `cliente`: cadastro, endereço em campos atômicos e referência à cidade.
- `produto`: item vendido, estoque, preço e referência à categoria.
- `pedido`: compra realizada por um cliente.
- `item_pedido`: entidade associativa entre pedido e produto.

Relacionamentos:

- `categoria 1:N produto`
- `cidade 1:N cliente`
- `cliente 1:N pedido`
- `pedido 1:N item_pedido`
- `produto 1:N item_pedido`

`item_pedido` resolve o relacionamento N:N entre `pedido` e `produto`.

## Normalização

### Primeira Forma Normal (1FN)

Todos os atributos possuem valores atômicos e não existem grupos repetidos.

Alterações realizadas:

- O endereço textual da Sprint 2 foi dividido em `logradouro`, `numero`, `bairro` e `cep`.
- Cada telefone, e-mail, SKU, preço e quantidade ocupa uma única coluna.
- Cada produto de um pedido é armazenado em uma linha própria de `item_pedido`.
- Todas as tabelas possuem chave primária.

### Segunda Forma Normal (2FN)

Cada atributo não-chave depende da chave primária completa de sua tabela. As tabelas usam chaves primárias simples; em `item_pedido`, a combinação `id_pedido` e `id_produto` também é única.

Exemplos:

- Em `produto`, nome, descrição, preço, estoque e categoria dependem de `id_produto`.
- Em `pedido`, data, status e cliente dependem de `id_pedido`.
- Em `item_pedido`, quantidade e preço praticado dependem do item identificado por `id_item`.

`preco_unitario` permanece em `item_pedido` para registrar o valor praticado no momento da compra, mesmo que o preço atual do produto seja alterado.

### Terceira Forma Normal (3FN)

Foram eliminadas dependências transitivas entre atributos não-chave:

- Nome e UF da cidade não ficam repetidos em `cliente`; pertencem a `cidade`, referenciada por `id_cidade`.
- Nome e descrição da categoria não ficam em `produto`; pertencem a `categoria`, referenciada por `id_categoria`.
- Dados do cliente não ficam em `pedido`; o pedido guarda somente `id_cliente`.
- Dados do produto não ficam em `item_pedido`; o item guarda somente `id_produto`, quantidade e preço histórico.

O resultado reduz redundância e evita anomalias de inserção, atualização e exclusão.

## Restrições aplicadas

- `PRIMARY KEY` em todas as tabelas.
- `FOREIGN KEY` em todos os relacionamentos.
- `NOT NULL` nos campos obrigatórios.
- `UNIQUE` para e-mail, SKU, nome da categoria, cidade/UF e produto por pedido.
- `CHECK` para UF, CEP, preço, estoque, quantidade e status.
- `DEFAULT` para cliente/produto ativos, estoque, data e status do pedido.
- Regras `ON UPDATE` e `ON DELETE` para preservar a integridade referencial.

## Dados e consultas

O script contém 3 comandos `INSERT` em cada uma das 6 tabelas, totalizando 18 registros.

As duas consultas exigidas são:

1. Detalhes de pedidos com cliente, cidade, itens, produtos e categorias.
2. Quantidade de pedidos válidos e receita por categoria, ignorando pedidos cancelados.

## Execução

1. Abra um servidor MySQL ou MariaDB.
2. Execute todo o arquivo `sprint3.sql`.
3. Confira o resultado das duas consultas ao final do script.

O script cria o banco `loja_online`, remove as tabelas antigas em ordem segura e recria toda a estrutura para permitir novos testes.
