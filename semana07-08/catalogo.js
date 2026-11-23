// Executar com mongosh --file catalogo.js. Banco exclusivo do exercício.
const loja = db.getSiblingDB("ceuma_catalogo");
// IDs reservados tornam a carga repetível sem apagar dados de outros produtos.
loja.produtos.deleteMany({_id: {$in: [101, 102, 103]}});
loja.produtos.insertMany([
 {_id:101, titulo:"Camiseta azul", descricao:"Camiseta algodão", preco:59.90, tags:["roupas","promoção"], fabricante:{nome:"Tecido MA",pais:"Brasil"}, variacoes:[{tamanho:"M",cor:"Azul"},{tamanho:"G",cor:"Preto"}]},
 {_id:102, titulo:"Notebook estudo", descricao:"Notebook portátil para estudo", preco:2500, tags:["eletrônicos"], fabricante:{nome:"Computa",pais:"Brasil"}, variacoes:[{memoria:8,cor:"Cinza"}]},
 {_id:103, titulo:"Tênis corrida", descricao:"Tênis leve para caminhada", preco:199.90, tags:["esporte","promoção"], fabricante:{nome:"Passo",pais:"Brasil"}, variacoes:[{tamanho:"M",cor:"Verde"},{tamanho:"G",cor:"Azul"}]}
]);
loja.produtos.createIndex({preco:1},{name:"idx_preco"});
loja.produtos.createIndex({titulo:"text",descricao:"text"},{default_language:"portuguese",name:"idx_texto"});
printjson(loja.produtos.find({preco:{$gt:50,$lt:500}}).toArray());
printjson(loja.produtos.find({tags:"promoção"}).toArray());
printjson(loja.produtos.find({$text:{$search:"notebook"}}).toArray());
printjson(loja.produtos.find({variacoes:{$elemMatch:{tamanho:"M",cor:"Azul"}}}).toArray());
// hint evidencia o acesso pelo índice mesmo com apenas três documentos.
printjson(loja.produtos.find({preco:{$lt:500}}).hint("idx_preco").explain("executionStats"));
