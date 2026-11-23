CREATE CONSTRAINT usuario_id IF NOT EXISTS FOR (u:Usuario) REQUIRE u.id IS UNIQUE;
CREATE CONSTRAINT produto_id IF NOT EXISTS FOR (p:Produto) REQUIRE p.id IS UNIQUE;
UNWIND [{id:1,nome:'Ana'},{id:2,nome:'Bia'},{id:3,nome:'Caio'},{id:4,nome:'Davi'}] AS dado
MERGE (u:Usuario {id:dado.id}) SET u.nome=dado.nome;
UNWIND [{id:101,nome:'Notebook'},{id:102,nome:'Mouse'},{id:103,nome:'Teclado'}] AS dado
MERGE (p:Produto {id:dado.id}) SET p.nome=dado.nome;
UNWIND [[1,2],[2,3],[2,4]] AS par
MATCH (a:Usuario {id:par[0]}),(b:Usuario {id:par[1]}) MERGE (a)-[:AMIGO_DE]->(b);
UNWIND [[1,101],[3,101],[3,102],[4,103]] AS par
MATCH (u:Usuario {id:par[0]}),(p:Produto {id:par[1]}) MERGE (u)-[:COMPROU]->(p);
// Amizade tratada como simétrica. Exclui o próprio usuário e amigos diretos.
MATCH (eu:Usuario {id:1})-[:AMIGO_DE]-(:Usuario)-[:AMIGO_DE]-(amigo:Usuario)-[:COMPROU]->(p:Produto {id:101})
WHERE amigo <> eu AND NOT (eu)-[:AMIGO_DE]-(amigo)
RETURN DISTINCT amigo.nome AS amigo_de_amigo, p.nome AS produto;
// Filtragem colaborativa por compra em comum, excluindo produtos já adquiridos.
MATCH (eu:Usuario {id:1})-[:COMPROU]->(:Produto)<-[:COMPROU]-(outro:Usuario)-[:COMPROU]->(sugestao:Produto)
WHERE outro <> eu AND NOT (eu)-[:COMPROU]->(sugestao)
RETURN sugestao.id, sugestao.nome, count(DISTINCT outro) AS afinidade ORDER BY afinidade DESC, sugestao.id;
