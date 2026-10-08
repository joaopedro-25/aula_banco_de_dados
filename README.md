# Projeto de Banco de Dados - E-commerce

Projeto desenvolvido para o Grupo 4, organizado por entregas incrementais de modelagem e implementação.

## Entrega atual: Sprint 6

A Sprint 6 mantém toda a estrutura PostgreSQL da Sprint 5 e adiciona:

- backup lógico automatizado com pg_dump em formato customizado;
- retenção de 30 dias, log, validação e tratamento de erros;
- agendamento cron diário;
- procedimento testável de restauração;
- duas collections MongoDB com Embedding e Referencing;
- 20 documentos, consultas, índices e explain no MongoDB;
- comparação técnica entre PostgreSQL e MongoDB.

Documentação completa: [sprint6/README.md](sprint6/README.md)

## Arquivos principais da Sprint 6

- [01_ddl.sql](sprint6/01_ddl.sql)
- [02_inserts.sql](sprint6/02_inserts.sql)
- [03_indices.sql](sprint6/03_indices.sql)
- [04_consultas.sql](sprint6/04_consultas.sql)
- [05_transacoes.sql](sprint6/05_transacoes.sql)
- [06_permissoes.sql](sprint6/06_permissoes.sql)
- [07_explain.sql](sprint6/07_explain.sql)
- [08_backup.sh](sprint6/08_backup.sh)
- [09_mongodb.js](sprint6/09_mongodb.js)
- [10_validacao_restauracao.sql](sprint6/10_validacao_restauracao.sql)
- [crontab.example](sprint6/crontab.example)

## Entregas anteriores

- Sprint 2: diagrama e modelo inicial.
- Sprint 3: modelo lógico e script SQL.
- Sprint 4: modelagem física, índices, transações, segurança e EXPLAIN.
- Sprint 5: projeto PostgreSQL completo com 13 tabelas e dados de teste.
