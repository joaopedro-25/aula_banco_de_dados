# Sprint 4 - Modelagem Física PostgreSQL

Implementação física do modelo lógico da loja on-line desenvolvido na Sprint 3. O arquivo `sprint4.sql` cria a estrutura no PostgreSQL, aplica índices, demonstra transações, executa análises de plano e configura controle de acesso.

## Entregáveis

- [`sprint4.sql`](sprint4.sql): DDL PostgreSQL, índices, dados base, transações, `EXPLAIN ANALYZE` e permissões.
- [`sprint4_README.md`](sprint4_README.md): justificativas técnicas e instruções de execução.

## Requisitos

- PostgreSQL 15 ou superior.
- Usuário com permissão para criar schema, tabelas, tipos, roles e usuários.
- Banco de dados de testes. O script remove e recria as tabelas do schema `loja`.

## Modelo físico

O modelo possui seis tabelas:

- `categoria`: classificação dos produtos.
- `cidade`: cadastro normalizado de cidade e UF.
- `cliente`: dados pessoais, endereço e cidade.
- `produto`: catálogo, preço, estoque e categoria.
- `pedido`: compra realizada por um cliente.
- `item_pedido`: associação entre pedidos e produtos.

Todas as tabelas usam PK. Relacionamentos usam FK com regras `ON UPDATE` e `ON DELETE`. Restrições `NOT NULL`, `UNIQUE`, `CHECK` e `DEFAULT` protegem a integridade dos dados.

## Escolha dos tipos PostgreSQL

- `BIGSERIAL`: IDs automáticos com capacidade maior que `INTEGER`.
- `NUMERIC(12,2)` e `NUMERIC(14,2)`: valores monetários sem erro de ponto flutuante.
- `TIMESTAMPTZ`: datas armazenadas com informação de fuso horário.
- `TEXT`: campos textuais sem limite artificial desnecessário.
- `CHAR(2)` e `CHAR(8)`: UF e CEP possuem tamanho fixo.
- `BOOLEAN`: situação ativa ou inativa.
- `ENUM loja.status_pedido`: impede status fora do fluxo definido.
- Coluna `subtotal` gerada e armazenada: mantém o cálculo consistente entre quantidade e preço unitário.

## Estratégia de indexação

Índices foram criados somente para unicidade, FKs e filtros frequentes:

- `uq_cliente_email_ci`: índice único em `LOWER(email)`. Evita e-mails duplicados com diferenças de maiúsculas e acelera login ou busca por e-mail.
- `idx_cliente_cidade`: acelera JOIN e filtro de clientes por cidade.
- `idx_produto_categoria`: acelera listagem e JOIN de produtos por categoria.
- `idx_pedido_cliente_data`: índice composto para histórico de pedidos do cliente ordenado por data.
- `idx_pedido_ativo_data`: índice parcial. Guarda somente pedidos não cancelados usados em relatórios.
- `idx_item_pedido_pedido`: acelera carregamento dos itens de um pedido.
- `idx_item_pedido_produto`: acelera relatórios de vendas por produto.

PKs e restrições `UNIQUE` já criam índices automaticamente. Por isso, não foram criados índices duplicados para IDs, SKU, nome de categoria ou combinação de pedido e produto. Menos índices reduzem custo de `INSERT`, `UPDATE` e `DELETE`.

## Transações

### Transação 1

Insere um cliente, um pedido e um item de pedido. CTEs encadeadas usam `RETURNING` para capturar `id_cliente` e `id_pedido` sem consultas adicionais. `COMMIT` confirma tudo como unidade atômica.

### Transação 2

Insere uma categoria e um produto, depois cria pedido e item. `SAVEPOINT antes_ajuste_preco` protege um ajuste experimental de preço. `ROLLBACK TO SAVEPOINT` desfaz somente esse ajuste; as inserções anteriores permanecem válidas. `COMMIT` confirma o restante.

Essas operações demonstram atomicidade, consistência, isolamento e durabilidade. O PostgreSQL usa MVCC: leituras normalmente não bloqueiam escritas.

## EXPLAIN ANALYZE

O script atualiza estatísticas com `ANALYZE` e executa duas consultas usando:

```sql
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
```

### Consulta 1: histórico por cliente

Filtra cliente por e-mail e ordena pedidos por data. Índices relevantes:

- `uq_cliente_email_ci` para `LOWER(email)`.
- `idx_pedido_cliente_data` para JOIN, filtro e ordenação.

Em volume real, o plano esperado contém `Index Scan` ou `Bitmap Index Scan` nesses índices.

### Consulta 2: vendas por categoria

Relaciona categoria, produto e item de pedido, agregando quantidade e receita. Índices relevantes:

- índice automático de `categoria.nome`.
- `idx_produto_categoria`.
- `idx_item_pedido_produto`.

### Interpretação

Verifique no plano:

- `Index Scan`, `Index Only Scan` ou `Bitmap Index Scan`: índice utilizado.
- `Seq Scan`: varredura completa.
- `actual time`: tempo real gasto.
- `rows`: linhas estimadas e processadas.
- `Buffers`: páginas lidas do cache ou disco.

Com poucas linhas de exemplo, o PostgreSQL pode escolher `Seq Scan` porque ler a tabela inteira custa menos que acessar o índice. Isso é decisão correta do otimizador, não falha do índice. Após carregar volume representativo e executar `ANALYZE`, os índices seletivos devem aparecer nos planos.

Não foi usado `SET enable_seqscan = off`, pois isso forçaria um plano artificial e esconderia a decisão real do otimizador.

## Controle de acesso

O script cria:

- `loja_operacao`: ROLE de grupo sem login.
- `loja_leitor`: usuário somente leitura.
- `loja_operador`: usuário que herda `loja_operacao`.

Permissões:

- `loja_leitor`: `USAGE` no schema e `SELECT` nas tabelas.
- `loja_operacao`: leitura dos cadastros; `SELECT`, `INSERT` e `UPDATE` em cliente, pedido e item; acesso às sequências.
- `loja_operador`: recebe as permissões da ROLE `loja_operacao`.
- `PUBLIC`: perde criação no schema e acesso geral às tabelas.
- Leitor e operador não recebem `DELETE`, `TRUNCATE`, alteração de estrutura ou criação de objetos.

`GRANT`, `REVOKE` e `ALTER DEFAULT PRIVILEGES` aplicam o princípio do menor privilégio também a objetos futuros.

## Segurança

As senhas presentes no SQL são exemplos obrigatoriamente substituíveis. Em ambiente real:

1. Troque-as antes de executar a seção de acesso.
2. Use um gerenciador de segredos.
3. Não versione senhas reais.
4. Execute criação de usuários com conta administrativa separada da aplicação.

## Execução

1. Crie ou selecione um banco PostgreSQL de testes.
2. Abra `sprint4.sql` no pgAdmin, `psql` ou extensão PostgreSQL do VS Code.
3. Execute o script completo com usuário administrador.
4. Confira os resultados retornados pelas transações.
5. Analise os dois planos produzidos por `EXPLAIN ANALYZE`.
6. Teste permissões conectando como `loja_leitor` e `loja_operador`.

Exemplo com `psql`:

```bash
psql -U postgres -d nome_do_banco -f sprint4.sql
```

## Testes de permissão sugeridos

Como `loja_leitor`:

```sql
SELECT id_produto, nome, preco FROM loja.produto;
INSERT INTO loja.pedido (id_cliente) VALUES (1); -- deve falhar
```

Como `loja_operador`:

```sql
SELECT id_pedido, status FROM loja.pedido;
UPDATE loja.pedido SET status = 'PAGO' WHERE id_pedido = 1;
DELETE FROM loja.pedido WHERE id_pedido = 1; -- deve falhar
```

## Checklist atendido

- DDL PostgreSQL com PK, FK, `NOT NULL`, `UNIQUE`, `CHECK` e `DEFAULT`.
- Tipos `BIGSERIAL`, `NUMERIC`, `TIMESTAMPTZ`, `TEXT`, `BOOLEAN` e `ENUM`.
- Índices justificados, incluindo índice único, composto e parcial.
- Duas transações em múltiplas tabelas.
- Uso de `BEGIN`, `COMMIT`, `SAVEPOINT`, `ROLLBACK` e `RETURNING`.
- Duas análises com `EXPLAIN ANALYZE`.
- Dois usuários, uma ROLE, `GRANT` e `REVOKE`.
- Princípio do menor privilégio documentado.
