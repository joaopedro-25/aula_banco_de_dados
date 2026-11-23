# Semana 14 — Escopo do e-commerce
Autor e integrante — João Pedro Costa de Abreu. Desenvolvimento individual.

O projeto dá continuidade ao tema de loja das entregas anteriores, com um recorte de vendas e estoque de quatro entidades. O MVP permite cadastrar clientes, cadastrar produtos com preço e saldo, criar pedidos, adicionar itens com quantidade, confirmar uma compra com baixa de estoque e consultar o histórico do cliente.

## Requisitos
RF01 cadastrar clientes com email único. RF02 cadastrar produtos com SKU único. RF03 abrir pedido para cliente existente. RF04 incluir itens com quantidade positiva. RF05 confirmar venda somente com estoque suficiente. RF06 consultar pedidos e totais calculados.

RNF01 a confirmação deve preservar atomicidade e impedir saldo negativo mesmo com compradores concorrentes. RNF02 relatórios devem responder em até 500 ms no percentil 95 para 100 mil pedidos em ambiente de teste definido. Essa é uma meta a medir. RNF03 o perfil de análise possui somente leitura.

## Entidades e decisão
Cliente possui nome e email. Produto possui SKU, preço e estoque. Pedido pertence a um cliente e guarda data e status. ItemPedido associa um pedido a um produto e registra quantidade e preço histórico. Um cliente tem zero ou muitos pedidos. Um pedido tem zero ou muitos itens durante montagem e pelo menos um para confirmação. Um produto aparece em zero ou muitos itens.

PostgreSQL atende ao recorte porque a venda altera pedido e estoque como unidade, com FKs, constraints e transações. Os atributos centrais são estáveis e os relatórios cruzam clientes, pedidos e produtos. O projeto conceitual está em [DER](docs/der.svg). Execute `psql -f database/init.sql` para criar a base e a primeira tabela. A semana 15 completa as tabelas. O CHECK de preço não negativo aparece no DDL completo.

## Reflexão
A escolha deve seguir consultas, invariantes, volume e operação. Escolher pelo gosto da equipe pode exigir duplicação difícil de sincronizar, joins artificiais ou infraestrutura desnecessária. Neste recorte, integridade referencial e transações têm prioridade. Um catálogo com atributos muito variáveis poderia motivar documentos em outra etapa.
