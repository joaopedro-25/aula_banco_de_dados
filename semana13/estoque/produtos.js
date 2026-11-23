const estoque=db.getSiblingDB("ceuma_erp_estoque");
estoque.produtos.updateOne({_id:101},{$set:{nome:"Celular",saldo:10,especificacoes:{tela:6.5,bateriaMah:5000}}},{upsert:true});
estoque.produtos.updateOne({_id:102},{$set:{nome:"Camiseta",saldo:30,especificacoes:{tamanho:"M",cor:"Azul"}}},{upsert:true});
printjson(estoque.produtos.find().toArray());
// Reserva atômica condicional evita estoque negativo sob concorrência.
printjson(estoque.produtos.updateOne({_id:101,saldo:{$gte:1}},{$inc:{saldo:-1}}));
