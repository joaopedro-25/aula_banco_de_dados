# Sprint 6 - Continuidade, Backup e MongoDB

Projeto de E-commerce do Grupo 4. Esta entrega preserva a solução PostgreSQL completa da Sprint 5 e acrescenta uma rotina automatizada de backup/restauração e uma implementação documental no MongoDB.

## Resumo da entrega

- 13 tabelas relacionais normalizadas, com 15 registros iniciais por tabela.
- PK, FK, NOT NULL, UNIQUE, CHECK, DEFAULT, índices, transações e controle de acesso.
- Backup lógico PostgreSQL em formato customizado, com nome por data, validação, log, tratamento de erro e retenção de 30 dias.
- Agendamento diário por cron às 02:00.
- Roteiro reproduzível de restauração e validação de volume e integridade referencial.
- 2 collections MongoDB com 10 documentos em cada uma.
- Embedding e Referencing aplicados conforme os padrões de acesso.
- 4 índices MongoDB, consultas com find, filtros, projeção, sort, aggregate e 2 análises explain.

## Domínio

A solução representa uma operação de E-commerce: catálogo, categorias, fornecedores, clientes, endereços, centros de distribuição, estoque, pedidos, itens, pagamentos, transportadoras, entregas e avaliações. O fluxo principal cadastra o cliente, cria o pedido, reserva estoque, registra pagamento e acompanha a entrega.

## Modelo lógico PostgreSQL

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

As associações N:N são resolvidas por estoque, item_pedido e avaliacao. O modelo está em 3FN: cada tabela representa uma entidade ou associação, grupos repetitivos foram removidos e os atributos não chave dependem somente da chave da tabela.

## Decisões físicas e integridade

- BIGSERIAL permite crescimento superior ao INTEGER.
- NUMERIC mantém precisão em valores monetários.
- TIMESTAMPTZ registra o instante com fuso horário.
- TEXT evita limites arbitrários.
- DATE representa datas sem horário.
- CHAR é reservado a CPF, CNPJ, UF e CEP.
- NOT NULL protege atributos obrigatórios.
- UNIQUE protege SKU, CPF, CNPJ, e-mail, transação e rastreio.
- CHECK valida preços, quantidades, notas, datas e formatos.
- DEFAULT padroniza status, datas, flags e estoques.
- ON DELETE CASCADE é usado somente nas dependências sem sentido fora do registro pai.

A estratégia de indexação prioriza chaves estrangeiras, filtros recorrentes, ordenações e pesquisa textual. Não se indexa toda coluna, pois cada índice aumenta o custo de INSERT, UPDATE e DELETE. Os scripts 03_indices.sql e 07_explain.sql documentam os índices e seus planos.

## Arquivos

| Ordem | Arquivo | Conteúdo |
|---|---|---|
| 1 | 01_ddl.sql | Schema, enums, 13 tabelas e restrições |
| 2 | 02_inserts.sql | 15 registros por tabela |
| 3 | 03_indices.sql | Índices PostgreSQL justificados |
| 4 | 04_consultas.sql | 13 consultas de negócio |
| 5 | 05_transacoes.sql | COMMIT, SAVEPOINT, ROLLBACK e RETURNING |
| 6 | 06_permissoes.sql | Roles, usuários, GRANT e REVOKE |
| 7 | 07_explain.sql | EXPLAIN ANALYZE PostgreSQL |
| 8 | 08_backup.sh | Backup customizado, validação, erros e retenção |
| 9 | 09_mongodb.js | Collections, documentos, consultas, índices e explain |
| 10 | 10_validacao_restauracao.sql | Contagens e integridade após restauração |
| - | crontab.example | Execução diária às 02:00 |
| - | README.md | Documentação técnica da Sprint 6 |

## Execução PostgreSQL

Crie um banco vazio e execute:

~~~bash
createdb -U postgres ecommerce_db
psql -U postgres -d ecommerce_db -f sprint6/01_ddl.sql
psql -U postgres -d ecommerce_db -f sprint6/02_inserts.sql
psql -U postgres -d ecommerce_db -f sprint6/03_indices.sql
psql -U postgres -d ecommerce_db -f sprint6/04_consultas.sql
psql -U postgres -d ecommerce_db -f sprint6/05_transacoes.sql
psql -U postgres -d ecommerce_db -f sprint6/07_explain.sql
psql -U postgres -d ecommerce_db -f sprint6/06_permissoes.sql
~~~

O arquivo 06_permissoes.sql deve ser executado por administrador e por último. As senhas demonstrativas precisam ser trocadas em qualquer ambiente real.

## Backup PostgreSQL

O script 08_backup.sh usa pg_dump no formato customizado com -Fc, equivalente a --format=custom. O nome inclui data e hora, no formato ecommerce_db_AAAAMMDD_HHMMSS.dump. A compressão reduz armazenamento e o formato permite restauração seletiva com pg_restore.

A rotina também:

1. encerra no primeiro erro com set -Eeuo pipefail;
2. aplica umask 077 e chmod 600;
3. remove um arquivo parcial se a execução falhar;
4. valida o catálogo do dump com pg_restore --list;
5. registra início, falha, limpeza e sucesso;
6. remove somente dumps do banco com mais de 30 dias;
7. não grava senha no repositório.

Configure a autenticação com o arquivo ~/.pgpass, permissão 600, ou outro cofre de segredos. As variáveis aceitas são DB_HOST, DB_PORT, DB_NAME, DB_USER, BACKUP_DIR e RETENTION_DAYS.

Execução manual:

~~~bash
chmod +x sprint6/08_backup.sh
DB_NAME=ecommerce_db DB_USER=postgres BACKUP_DIR=/var/backups/ecommerce ./sprint6/08_backup.sh
~~~

## Agendamento cron

O arquivo crontab.example contém a expressão abaixo. Ela executa diariamente às 02:00 no fuso horário do servidor:

~~~cron
0 2 * * * /usr/bin/env bash /opt/ecommerce/08_backup.sh >> /var/log/ecommerce-backup-cron.log 2>&1
~~~

Antes de instalar, ajuste os caminhos e garanta permissão de escrita no diretório de backup e no log. Para instalar:

~~~bash
crontab sprint6/crontab.example
crontab -l
~~~

## Regra 3-2-1

A retenção local de 30 dias é apenas uma camada. A estratégia recomendada é:

- 3 cópias dos dados: banco em produção, backup local e cópia externa;
- 2 mídias ou destinos diferentes: disco do servidor e armazenamento de objetos;
- 1 cópia fora do local principal, preferencialmente em outra região e com criptografia.

O envio para armazenamento externo deve ocorrer após pg_restore --list validar o dump. Políticas de imutabilidade e testes periódicos reduzem o risco de corrupção e ransomware.

## Teste de restauração

Nunca restaure sobre produção durante o teste. Use um banco descartável:

~~~bash
createdb -U postgres ecommerce_restore_test
pg_restore -U postgres --dbname=ecommerce_restore_test --clean --if-exists --no-owner /var/backups/ecommerce/ecommerce_db_AAAAMMDD_HHMMSS.dump
psql -U postgres -d ecommerce_restore_test -f sprint6/10_validacao_restauracao.sql
~~~

O script de validação mostra a contagem das 13 tabelas, falha se alguma possuir menos de 15 registros e verifica referências órfãs. O teste é aprovado quando:

- todas as tabelas possuem ao menos 15 registros;
- todas as contagens de inconsistências são zero;
- a saída final apresenta RESTAURACAO_VALIDADA.

Depois do teste, o banco descartável pode ser removido pelo administrador:

~~~bash
dropdb -U postgres ecommerce_restore_test
~~~

## MongoDB

Execute em uma instância MongoDB de desenvolvimento:

~~~bash
mongosh < sprint6/09_mongodb.js
~~~

O script recria o banco ecommerce_nosql e as collections produtos e pedidos. Cada collection recebe 10 documentos. Produtos possuem campos diferentes conforme a categoria: eletrônicos têm memória e armazenamento, vestuário tem variantes, livro tem ISBN e autor, e produto pet possui composição. Essa diversidade demonstra flexibilidade de esquema.

### Embedding versus Referencing

| Decisão | Aplicação | Justificativa |
|---|---|---|
| Embedding | entrega, pagamento, itens resumidos e histórico dentro de pedido | São dados limitados, pertencem ao pedido e normalmente são lidos juntos; uma consulta recupera o agregado completo |
| Embedding | atributos, dimensões e variantes dentro de produto | São pequenos, dependem do produto e variam por categoria |
| Referencing | itens.produto_id apontando para produtos._id | O catálogo é reutilizado em muitos pedidos, possui ciclo de vida próprio e pode ser consultado ou atualizado separadamente |
| Snapshot embutido | SKU, nome e preço no item | Preserva o valor histórico da compra mesmo se o catálogo mudar |

Assim, a estrutura segue o padrão de acesso. Dados coesos e limitados ficam embutidos; entidades reutilizáveis e independentes ficam referenciadas. O exemplo com $lookup resolve a referência quando o nome atual do catálogo é necessário.

### Consultas MongoDB

O arquivo 09_mongodb.js inclui:

1. find com filtro por categoria e faixa de preço;
2. projeção de SKU, nome e preço;
3. sort por preço;
4. histórico de pedidos de um cliente, ordenado por data;
5. busca textual no catálogo;
6. aggregate com unwind, lookup e project.

### Índices e explain

| Índice | Motivo |
|---|---|
| uq_produtos_sku | busca exata e unicidade do SKU |
| idx_produtos_texto | pesquisa textual em nome e descrição |
| idx_pedidos_cliente_data | histórico de cliente já ordenado do mais recente |
| idx_pedidos_produto | localização de pedidos que contêm um produto |

Dois explain com executionStats analisam busca por SKU e histórico por cliente/data. O estágio IXSCAN demonstra uso do índice. Examine também totalKeysExamined, totalDocsExamined, nReturned e executionTimeMillis. Como a carga é pequena, o otimizador pode considerar COLLSCAN barato em outras consultas; por isso a análise usa predicados alinhados aos índices.

## PostgreSQL versus MongoDB no E-commerce

| Cenário | PostgreSQL | MongoDB |
|---|---|---|
| Pedido, pagamento e estoque com consistência forte | Melhor escolha: transações ACID, FK e CHECK | Possível, mas exige desenho cuidadoso entre documentos |
| Relatórios financeiros e JOINs complexos | Melhor escolha: SQL, agregações e relacionamentos explícitos | Aggregation Pipeline atende, porém pode ser menos natural |
| Catálogo com atributos diferentes por categoria | Exige tabelas auxiliares ou JSONB | Melhor escolha: documentos flexíveis |
| Leitura do pedido completo em uma operação | Requer JOIN entre tabelas | Embedding reduz consultas |
| Evolução rápida do esquema | Migrações controladas garantem consistência | Novos campos podem ser adicionados gradualmente |
| Integridade referencial automática | FK e restrições nativas | Referências são validadas pela aplicação |

Neste domínio, PostgreSQL permanece como fonte transacional para pedidos, pagamentos e estoque. MongoDB se sobressai no catálogo variável e em visões de leitura agregadas. Em uma arquitetura híbrida, eventos do PostgreSQL poderiam alimentar documentos de leitura no MongoDB sem remover a autoridade relacional.
