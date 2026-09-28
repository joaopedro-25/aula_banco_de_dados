# Sprint 5 - Projeto de Banco de Dados

Sistema de E-commerce desenvolvido para o Grupo 4. A entrega transforma a modelagem anterior em um projeto PostgreSQL completo, normalizado, indexado, transacional e protegido por controle de acesso.

## Resumo da entrega

- 13 tabelas relacionadas.
- 15 registros iniciais por tabela: 195 registros.
- 13 consultas de negócio.
- 13 índices planejados, além dos índices automáticos de PK e UNIQUE.
- 3 exemplos transacionais: dois COMMIT, um SAVEPOINT e um ROLLBACK total.
- 2 usuários e 2 roles de grupo com menor privilégio.
- 3 análises com EXPLAIN ANALYZE.

## Domínio

A solução cobre catálogo, fornecedores, clientes, endereços, centros de distribuição, estoque, pedidos, itens, pagamentos, transportadoras, entregas e avaliações. O fluxo principal começa no cadastro do cliente, cria o pedido, reserva estoque, registra pagamento e acompanha a entrega.

## Modelo lógico

| Tabela | Chave primária | Relacionamentos principais |
|---|---|---|
| categoria | id_categoria | 1:N produto |
| fornecedor | id_fornecedor | 1:N produto |
| produto | id_produto | N:1 categoria; N:1 fornecedor |
| cliente | id_cliente | 1:N endereco; 1:N pedido; 1:N avaliacao |
| endereco | id_endereco | N:1 cliente; 1:N pedido |
| centro_distribuicao | id_centro | N:N produto por estoque |
| estoque | id_estoque | N:1 produto; N:1 centro_distribuicao |
| pedido | id_pedido | N:1 cliente; N:1 endereco |
| item_pedido | id_item | N:1 pedido; N:1 produto |
| pagamento | id_pagamento | N:1 pedido |
| transportadora | id_transportadora | 1:N entrega |
| entrega | id_entrega | 1:1 pedido; N:1 transportadora |
| avaliacao | id_avaliacao | N:1 cliente; N:1 produto |

A associação produto-centro é resolvida por estoque. A associação pedido-produto é resolvida por item_pedido. A associação cliente-produto é resolvida por avaliacao.

## Normalização e integridade

O modelo está em terceira forma normal (3FN): cada tabela representa uma entidade ou associação, grupos repetitivos foram removidos e atributos não chave dependem apenas da chave da própria tabela.

A integridade usa:

- PK BIGSERIAL para identificadores.
- FK em todos os relacionamentos.
- NOT NULL para dados obrigatórios.
- UNIQUE em SKU, CPF, CNPJ, e-mail, código de transação e rastreio.
- CHECK para preços, quantidades, notas, datas e formatos básicos.
- DEFAULT para status, datas, flags e estoques.
- ON DELETE CASCADE somente em dependências que não fazem sentido sem o registro pai.
- Tipos ENUM para estados finitos do pedido, pagamento e entrega.

## Escolhas físicas

BIGSERIAL suporta crescimento superior ao INTEGER. NUMERIC evita imprecisão de ponto flutuante em valores monetários. TIMESTAMPTZ preserva instante e fuso horário. TEXT evita limites arbitrários. DATE representa datas sem horário. CHAR foi reservado aos códigos de tamanho fixo, como CPF, CNPJ, UF e CEP.

O subtotal do item é uma coluna gerada e armazenada. Assim, permanece consistente com quantidade, preço unitário e desconto.

## Estratégia de indexação

Não foram indexadas todas as colunas. Cada índice atende JOIN, filtro ou ordenação recorrente:

- produto por categoria ativa e por fornecedor;
- busca textual GIN no catálogo;
- endereço por cliente;
- estoque por centro/produto e índice parcial de reposição;
- histórico de pedido por cliente e data;
- índice parcial do painel de pedidos ativos;
- item por produto;
- pagamento por pedido e status;
- entrega por transportadora/status e fila parcial por previsão;
- avaliação por produto e data.

PK e UNIQUE já produzem índices B-tree automaticamente. Evitar duplicação reduz custo de INSERT, UPDATE e DELETE.

## Consultas implementadas

O arquivo 04_consultas.sql contém:

1. Detalhes de pedidos com quatro tabelas.
2. Receita e unidades por categoria.
3. Clientes com gasto acima de R$ 500 usando HAVING.
4. Produtos acima do preço médio usando subconsulta.
5. Estoque abaixo do mínimo.
6. Entregas abertas com cliente e transportadora.
7. Resumo financeiro por método e status.
8. Média de avaliações por produto.
9. Fornecedores e quantidade de produtos ativos.
10. Clientes sem pedidos usando NOT EXISTS.
11. Pedido mais recente por cliente com ROW_NUMBER.
12. Ocupação dos centros de distribuição.
13. Pesquisa textual do catálogo com índice GIN.

Nenhuma consulta usa SELECT sem lista explícita de colunas.

## Transações

### Transação 1

Cadastra cliente, endereço, pedido, item e pagamento em uma única unidade atômica. CTEs com RETURNING transportam os IDs gerados para as tabelas filhas. COMMIT confirma tudo somente se todas as etapas funcionarem.

### Transação 2

Bloqueia a linha de estoque com FOR UPDATE, cria SAVEPOINT, testa uma alteração de preço e a desfaz com ROLLBACK TO SAVEPOINT. Depois cria pedido, item e pagamento, baixa o estoque de forma condicional e confirma com COMMIT.

### Transação 3

Cria categoria e produto temporários e executa ROLLBACK. Ela demonstra que nenhum registro parcial permanece após o cancelamento total.

Esses exemplos aplicam atomicidade, consistência, isolamento e durabilidade.

## Controle de acesso

O arquivo 06_permissoes.sql cria:

- ecommerce_leitura: role sem login, somente SELECT.
- ecommerce_operacao: role sem login, leitura e operações necessárias ao fluxo de venda.
- ec_leitor: usuário que herda ecommerce_leitura.
- ec_operador: usuário que herda ecommerce_operacao.

PUBLIC perde acesso às tabelas, sequências e ao schema. DELETE, TRUNCATE, criação de objetos e privilégios estruturais são revogados dos perfis. O script precisa ser executado por administrador. As senhas são marcadores e devem ser trocadas antes de uso real.

## EXPLAIN ANALYZE

O arquivo 07_explain.sql analisa:

1. Histórico de pedidos de um cliente.
2. Vendas por categoria.
3. Fila de entregas abertas por prazo.

Index Scan, Index Only Scan e Bitmap Index Scan indicam uso de índice. Seq Scan pode ser a melhor decisão com apenas 15 linhas, pois ler a tabela inteira custa menos do que acessar índice e heap. Por isso o script executa ANALYZE e não desativa enable_seqscan. Em volume real, as estatísticas devem ser atualizadas antes da comparação.

Os principais pontos de leitura são estimated rows contra actual rows, execution time e Buffers.

## Arquivos

| Ordem | Arquivo | Conteúdo |
|---|---|---|
| 1 | 01_ddl.sql | Schema, enums, 13 tabelas e restrições |
| 2 | 02_inserts.sql | 15 registros por tabela e conferência |
| 3 | 03_indices.sql | Índices e justificativas |
| 4 | 04_consultas.sql | 13 consultas de negócio |
| 5 | 05_transacoes.sql | COMMIT, SAVEPOINT, ROLLBACK e RETURNING |
| 6 | 06_permissoes.sql | Roles, usuários, GRANT e REVOKE |
| 7 | 07_explain.sql | EXPLAIN ANALYZE e roteiro de interpretação |

## Execução

Crie um banco vazio e execute na ordem:

    psql -U postgres -d nome_do_banco -f sprint5/01_ddl.sql
    psql -U postgres -d nome_do_banco -f sprint5/02_inserts.sql
    psql -U postgres -d nome_do_banco -f sprint5/03_indices.sql
    psql -U postgres -d nome_do_banco -f sprint5/04_consultas.sql
    psql -U postgres -d nome_do_banco -f sprint5/05_transacoes.sql
    psql -U postgres -d nome_do_banco -f sprint5/06_permissoes.sql
    psql -U postgres -d nome_do_banco -f sprint5/07_explain.sql

Recomendação: execute 06_permissoes.sql por último e com usuário administrador.
