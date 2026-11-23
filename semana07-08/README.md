# Semanas 7 e 8 — Catálogo MongoDB
Autor — João Pedro Costa de Abreu.

Execute `mongosh --file catalogo.js` em uma instância de desenvolvimento. O script cria implicitamente o banco ceuma_catalogo e insere três produtos com arrays, fabricante incorporado e variações. As consultas retornam, respectivamente, os produtos 101 e 103, 101 e 103, 102 e somente 101. O `$elemMatch` exige que tamanho e cor pertençam à mesma variação, evitando que as duas condições sejam satisfeitas por elementos diferentes.

O índice simples atende intervalos de preço. O índice textual reúne título e descrição. O explain com hint deve mostrar IXSCAN e totalKeysExamined maior que zero. O hint serve à demonstração, pois uma coleção minúscula pode ser mais barata de percorrer integralmente.

## Embedding e referencing
Embedding incorpora os dados lidos junto ao produto, como especificações e variações de tamanho limitado. A leitura requer um documento e a atualização desse documento é atômica. Referencing armazena identificadores de outras coleções e favorece dados compartilhados e alterados frequentemente, como fornecedores e categorias. Comentários de um blog que crescem continuamente devem ficar em outra coleção com post_id, evitando crescimento ilimitado e o limite de tamanho do documento. Duplicar o nome do fabricante pode ser aceitável como fotografia histórica, mas atualizações cadastrais exigem uma estratégia explícita de sincronização.

## Validação realizada em 23/11/2026

MongoDB 7.0.16 e mongosh 2.3.8. Os filtros retornaram os documentos esperados e o explain registrou uso do índice.
