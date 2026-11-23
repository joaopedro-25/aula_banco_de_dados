# Semana 16 — Implementação física
Autor — João Pedro Costa de Abreu. Projeto individual de e-commerce, continuação das semanas 14 e 15.

Crie uma base didática `createdb ceuma_semana16`. Execute os arquivos 01 a 05 na ordem, usando `psql -v ON_ERROR_STOP=1 -d ceuma_semana16 -f ARQUIVO`. O script 04 precisa de uma conta com CREATEROLE e capacidade de SET ROLE para os papéis criados. Os logins são criados sem senha no repositório. Defina as senhas interativamente com `\password` e configure autenticação no ambiente.

A carga possui cinco registros por tabela, inclusive a associativa. PKs, FKs, NOT NULL, UNIQUE e CHECK preservam integridade. Dois índices atendem cliente e status/data. A unicidade do email já cria seu próprio índice. Em uma carga de cinco linhas, o otimizador pode escolher Seq Scan corretamente.

O admin tem leitura, escrita e exclusão. O analista consegue SELECT e o script captura a tentativa de DELETE negada. A função de confirmação bloqueia o pedido, reduz estoque com condição e trata repetição de pedido pago como sucesso sem nova baixa. A demonstração confirma pedido 1, deixando estoque do produto 1 em 98. A segunda transação provoca falha e verifica restauração do saldo do produto 2.

## Reflexão
Índices consomem espaço e precisam ser atualizados em INSERT, UPDATE e DELETE. Índices redundantes aumentam custo de escrita, WAL e manutenção. Escolha deve partir das consultas reais e do EXPLAIN. Menor privilégio limita o impacto de um comando incorreto ou de uma credencial comprometida. Analistas precisam consultar dados, enquanto a aplicação recebe somente operações necessárias ao seu trabalho.

## Pitch de três minutos
Primeiro minuto — apresentar o problema de vendas com estoque consistente, as quatro entidades e o histórico de preços. Segundo minuto — demonstrar cinco registros por tabela, relacionamento, relatório e os dois índices. Terceiro minuto — executar a confirmação, a falha com rollback e o DELETE negado. Reservar dois minutos para perguntas sobre concorrência, índices e permissões.

## Validação realizada em 23/11/2026

PostgreSQL 16.2. Cinco registros em cada tabela, índices criados, DELETE do analista negado, confirmação executada e rollback validado.
