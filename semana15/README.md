# Semana 15 — Modelagem e normalização
Autor — João Pedro Costa de Abreu. Recorte definido na semana 14.

Execute em ordem `psql -v ON_ERROR_STOP=1 -f 01_ddl.sql` e `psql -v ON_ERROR_STOP=1 -f 02_dados.sql`. O primeiro usa schema semana15. O segundo insere quatro registros relacionados, calcula total 40 e testa uma FK inválida em subtransação, emitindo PASS somente após a violação esperada.

## MER e modelo lógico
O [MER conceitual](docs/mer.svg) mostra as entidades, atributos e cardinalidades. O [DER lógico](docs/der.svg) mostra PKs e FKs. Cliente 1:N Pedido e Pedido N:N Produto, resolvido por ItemPedido no modelo lógico. Pedido em montagem admite zero itens, enquanto confirmação exige pelo menos um.

| Tabela | PK | FKs | Dependências |
|---|---|---|---|
| cliente | id | — | id determina nome e email |
| produto | id | — | id determina nome, SKU, preço e estoque |
| pedido | id | cliente_id → cliente.id | id determina cliente, data e status |
| item_pedido | pedido_id + produto_id | pedido_id → pedido.id, produto_id → produto.id | o par determina quantidade e preço histórico |

## Normalização até 3FN
Uma tabela original PedidoBruto(id_pedido, cliente_id, nome_cliente, email_cliente, produtos) repetia clientes e incluía uma lista de produtos. Em 1FN, cada item ocupa uma linha e cada campo tem um valor atômico. Em 2FN, nome do produto e dados do pedido saem da tabela de itens, pois dependem de partes da chave composta. Em 3FN, nome e email do cliente ficam em Cliente, removendo a dependência transitiva id_pedido → cliente_id → email_cliente. O preço em Produto representa o valor atual. O preço em ItemPedido é o valor negociado naquele pedido e depende do par completo. O total é calculado por SUM, evitando redundância.

## Reflexão
A separação permite cadastrar produto antes de vender, atualizar email em um lugar e excluir um item sem perder o cadastro do cliente. PK garante identificação única, e FK impede referências órfãs. Constraints protegem a base mesmo quando diferentes clientes acessam o banco. Regras envolvendo várias tabelas, como confirmação com itens e estoque suficiente, precisam de transação.

## Validação realizada em 23/11/2026

PostgreSQL 16.2. DDL e DML executados, uma linha por entidade e rejeição da FK inexistente confirmada.
