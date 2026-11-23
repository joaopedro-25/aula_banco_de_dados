# Semanas 9 a 12 — Recomendações e carrinho
Autor — João Pedro Costa de Abreu.

Execute `cypher-shell -f recomendacoes.cypher` na base didática Neo4j e `redis-cli < carrinho.redis` em Redis de desenvolvimento. O Cypher usa MERGE e restrições únicas, permitindo repetição da carga. Ana conhece Bia, que conhece Caio e Davi. A consulta de dois saltos deve retornar Caio, comprador do notebook. A filtragem colaborativa deve sugerir Mouse para Ana.

## Chaves e operações
`cart:user:{id}` identifica um cliente autenticado. Para visitantes, use `cart:session:{uuid}` gerado pelo servidor. Cada hash contém campos product:{id} com quantidade inteira positiva. MULTI/EXEC aplica carga e TTL juntos. O exemplo expira em 86400 segundos, lê HGETALL, incrementa uma quantidade e apaga após checkout. Preço e disponibilidade devem ser revalidados no banco durável durante checkout. DEL é idempotente, então a confirmação pode ser repetida.

## Reflexão
O grafo representa conexões explicitamente e facilita percursos de profundidade variável. Em SQL, o mesmo caminho costuma exigir autojoins ou consultas recursivas. A vantagem real depende de cardinalidade, índices e plano de execução, sendo necessário medir. Redis mantém dados em memória e reduz a latência e a carga no banco principal para carrinhos transitórios. Persistência, replicação e expiração têm custos e precisam de configuração. Pedidos confirmados ficam no armazenamento durável, pois expiração ou perda do cache deve afetar apenas a sessão recuperável.

## Validação realizada em 23/11/2026

Neo4j 5.26 retornou Caio/Notebook e a recomendação Mouse com afinidade 1. Redis 7.4.2 confirmou TTL 86400, incremento de quantidade e EXISTS 0 após DEL.
