// Execute com: mongosh < sprint6/09_mongodb.js
const loja = db.getSiblingDB("ecommerce_nosql");

loja.produtos.drop();
loja.pedidos.drop();

// Collection independente: catálogo consultado e atualizado separadamente.
const resultadoProdutos = loja.produtos.insertMany([
  {
    sku: "EC-001",
    nome: "Notebook Pro 15",
    descricao: "Notebook para trabalho e estudo",
    categoria: "Eletrônicos",
    preco: 4599.90,
    estoque: 18,
    atributos: { marca: "TechOne", memoria_gb: 16, armazenamento: "512 GB SSD" },
    dimensoes_cm: { largura: 35.8, altura: 1.8, profundidade: 24.2 },
    tags: ["notebook", "trabalho"]
  },
  {
    sku: "EC-002",
    nome: "Mouse sem fio",
    descricao: "Mouse ergonômico com conexão Bluetooth",
    categoria: "Eletrônicos",
    preco: 129.90,
    estoque: 70,
    atributos: { marca: "Click", dpi: 3200, recarregavel: true },
    tags: ["mouse", "bluetooth"]
  },
  {
    sku: "EC-003",
    nome: "Teclado mecânico",
    descricao: "Teclado ABNT2 com iluminação RGB",
    categoria: "Eletrônicos",
    preco: 289.00,
    estoque: 42,
    atributos: { marca: "KeyMax", switch: "brown", layout: "ABNT2" },
    tags: ["teclado", "rgb"]
  },
  {
    sku: "CA-001",
    nome: "Camiseta básica",
    descricao: "Camiseta de algodão",
    categoria: "Vestuário",
    preco: 59.90,
    estoque: 120,
    variantes: [
      { tamanho: "P", cor: "preta" },
      { tamanho: "M", cor: "branca" },
      { tamanho: "G", cor: "azul" }
    ],
    material: { principal: "algodão", percentual: 100 }
  },
  {
    sku: "CA-002",
    nome: "Tênis urbano",
    descricao: "Tênis casual unissex",
    categoria: "Calçados",
    preco: 249.90,
    estoque: 55,
    variantes: [{ numero: 38 }, { numero: 39 }, { numero: 40 }, { numero: 41 }],
    atributos: { marca: "Move", impermeavel: false }
  },
  {
    sku: "LV-001",
    nome: "Banco de Dados na Prática",
    descricao: "Livro sobre PostgreSQL e MongoDB",
    categoria: "Livros",
    preco: 89.90,
    estoque: 34,
    autor: "Ana Silva",
    isbn: "9780000000001",
    paginas: 420
  },
  {
    sku: "CA-003",
    nome: "Mochila executiva",
    descricao: "Mochila com compartimento para notebook",
    categoria: "Acessórios",
    preco: 199.90,
    estoque: 27,
    atributos: { capacidade_litros: 24, resistente_agua: true },
    cores: ["preta", "cinza"]
  },
  {
    sku: "CS-001",
    nome: "Cafeteira programável",
    descricao: "Cafeteira elétrica de 1,2 litro",
    categoria: "Casa",
    preco: 329.90,
    estoque: 23,
    atributos: { voltagem: 220, timer: true, capacidade_litros: 1.2 },
    garantia_meses: 12
  },
  {
    sku: "ES-001",
    nome: "Kit de halteres",
    descricao: "Par de halteres revestidos",
    categoria: "Esportes",
    preco: 179.90,
    estoque: 31,
    atributos: { peso_por_unidade_kg: 5, quantidade: 2 },
    uso: ["musculação", "funcional"]
  },
  {
    sku: "PA-001",
    nome: "Ração premium",
    descricao: "Alimento para cães adultos",
    categoria: "Pet Shop",
    preco: 149.90,
    estoque: 46,
    atributos: { peso_kg: 10, especie: "cão", fase: "adulto" },
    composicao_resumida: ["proteína animal", "vegetais", "vitaminas"]
  }
]);

const produtoIds = resultadoProdutos.insertedIds;

// Em pedido, endereço, pagamento e histórico são embutidos porque são limitados
// e normalmente lidos juntos. produto_id referencia o catálogo reutilizável.
loja.pedidos.insertMany([
  {
    numero: "PED-2026-001",
    cliente_id: 1001,
    criado_em: new Date("2026-09-01T12:00:00Z"),
    status: "entregue",
    entrega: { destinatario: "Maria Lima", cidade: "São Luís", uf: "MA", cep: "65000-001" },
    pagamento: { metodo: "pix", status: "aprovado", valor: 4729.80 },
    itens: [
      { produto_id: produtoIds[0], sku: "EC-001", nome_snapshot: "Notebook Pro 15", quantidade: 1, preco_unitario: 4599.90 },
      { produto_id: produtoIds[1], sku: "EC-002", nome_snapshot: "Mouse sem fio", quantidade: 1, preco_unitario: 129.90 }
    ],
    historico: [
      { status: "criado", em: new Date("2026-09-01T12:00:00Z") },
      { status: "entregue", em: new Date("2026-09-04T18:30:00Z") }
    ]
  },
  {
    numero: "PED-2026-002",
    cliente_id: 1002,
    criado_em: new Date("2026-09-02T14:10:00Z"),
    status: "pago",
    entrega: { destinatario: "João Costa", cidade: "Teresina", uf: "PI", cep: "64000-002" },
    pagamento: { metodo: "cartão", status: "aprovado", parcelas: 2, valor: 348.90 },
    itens: [
      { produto_id: produtoIds[2], sku: "EC-003", nome_snapshot: "Teclado mecânico", quantidade: 1, preco_unitario: 289.00 },
      { produto_id: produtoIds[3], sku: "CA-001", nome_snapshot: "Camiseta básica", quantidade: 1, preco_unitario: 59.90 }
    ],
    historico: [{ status: "pago", em: new Date("2026-09-02T14:12:00Z") }]
  },
  {
    numero: "PED-2026-003",
    cliente_id: 1001,
    criado_em: new Date("2026-09-03T09:30:00Z"),
    status: "enviado",
    entrega: { destinatario: "Maria Lima", cidade: "São Luís", uf: "MA", cep: "65000-001", complemento: "Apto 302" },
    pagamento: { metodo: "pix", status: "aprovado", valor: 339.80 },
    itens: [
      { produto_id: produtoIds[4], sku: "CA-002", nome_snapshot: "Tênis urbano", quantidade: 1, preco_unitario: 249.90 },
      { produto_id: produtoIds[5], sku: "LV-001", nome_snapshot: "Banco de Dados na Prática", quantidade: 1, preco_unitario: 89.90 }
    ],
    historico: [
      { status: "criado", em: new Date("2026-09-03T09:30:00Z") },
      { status: "enviado", em: new Date("2026-09-04T11:00:00Z") }
    ]
  },
  {
    numero: "PED-2026-004",
    cliente_id: 1003,
    criado_em: new Date("2026-09-04T17:20:00Z"),
    status: "separação",
    entrega: { destinatario: "Carla Reis", cidade: "Fortaleza", uf: "CE", cep: "60000-004" },
    pagamento: { metodo: "boleto", status: "aprovado", valor: 199.90 },
    itens: [{ produto_id: produtoIds[6], sku: "CA-003", nome_snapshot: "Mochila executiva", quantidade: 1, preco_unitario: 199.90 }],
    historico: [{ status: "separação", em: new Date("2026-09-05T10:00:00Z") }]
  },
  {
    numero: "PED-2026-005",
    cliente_id: 1004,
    criado_em: new Date("2026-09-05T08:45:00Z"),
    status: "entregue",
    entrega: { destinatario: "Pedro Alves", cidade: "Belém", uf: "PA", cep: "66000-005" },
    pagamento: { metodo: "cartão", status: "aprovado", parcelas: 3, valor: 329.90 },
    itens: [{ produto_id: produtoIds[7], sku: "CS-001", nome_snapshot: "Cafeteira programável", quantidade: 1, preco_unitario: 329.90 }],
    historico: [{ status: "entregue", em: new Date("2026-09-08T16:00:00Z") }]
  },
  {
    numero: "PED-2026-006",
    cliente_id: 1005,
    criado_em: new Date("2026-09-06T11:15:00Z"),
    status: "pago",
    entrega: { destinatario: "Rita Sousa", cidade: "Recife", uf: "PE", cep: "50000-006" },
    pagamento: { metodo: "pix", status: "aprovado", valor: 359.80 },
    itens: [{ produto_id: produtoIds[8], sku: "ES-001", nome_snapshot: "Kit de halteres", quantidade: 2, preco_unitario: 179.90 }],
    historico: [{ status: "pago", em: new Date("2026-09-06T11:16:00Z") }]
  },
  {
    numero: "PED-2026-007",
    cliente_id: 1006,
    criado_em: new Date("2026-09-07T15:40:00Z"),
    status: "enviado",
    entrega: { destinatario: "Luís Rocha", cidade: "Natal", uf: "RN", cep: "59000-007" },
    pagamento: { metodo: "cartão", status: "aprovado", valor: 149.90 },
    itens: [{ produto_id: produtoIds[9], sku: "PA-001", nome_snapshot: "Ração premium", quantidade: 1, preco_unitario: 149.90 }],
    historico: [{ status: "enviado", em: new Date("2026-09-08T09:00:00Z") }]
  },
  {
    numero: "PED-2026-008",
    cliente_id: 1007,
    criado_em: new Date("2026-09-08T19:00:00Z"),
    status: "cancelado",
    entrega: { destinatario: "Bia Melo", cidade: "Manaus", uf: "AM", cep: "69000-008" },
    pagamento: { metodo: "pix", status: "estornado", valor: 59.90 },
    itens: [{ produto_id: produtoIds[3], sku: "CA-001", nome_snapshot: "Camiseta básica", quantidade: 1, preco_unitario: 59.90 }],
    historico: [{ status: "cancelado", em: new Date("2026-09-08T19:10:00Z"), motivo: "Solicitação do cliente" }]
  },
  {
    numero: "PED-2026-009",
    cliente_id: 1008,
    criado_em: new Date("2026-09-09T10:25:00Z"),
    status: "pago",
    entrega: { destinatario: "Caio Nunes", cidade: "Palmas", uf: "TO", cep: "77000-009" },
    pagamento: { metodo: "boleto", status: "aprovado", valor: 179.80 },
    itens: [{ produto_id: produtoIds[5], sku: "LV-001", nome_snapshot: "Banco de Dados na Prática", quantidade: 2, preco_unitario: 89.90 }],
    historico: [{ status: "pago", em: new Date("2026-09-10T08:00:00Z") }]
  },
  {
    numero: "PED-2026-010",
    cliente_id: 1001,
    criado_em: new Date("2026-09-10T13:50:00Z"),
    status: "criado",
    entrega: { destinatario: "Maria Lima", cidade: "São Luís", uf: "MA", cep: "65000-001" },
    pagamento: { metodo: "pix", status: "pendente", valor: 129.90 },
    itens: [{ produto_id: produtoIds[1], sku: "EC-002", nome_snapshot: "Mouse sem fio", quantidade: 1, preco_unitario: 129.90 }],
    historico: [{ status: "criado", em: new Date("2026-09-10T13:50:00Z") }]
  }
]);

// Índices orientados aos padrões de acesso.
loja.produtos.createIndex({ sku: 1 }, { unique: true, name: "uq_produtos_sku" });
loja.produtos.createIndex({ nome: "text", descricao: "text" }, { name: "idx_produtos_texto" });
loja.pedidos.createIndex({ cliente_id: 1, criado_em: -1 }, { name: "idx_pedidos_cliente_data" });
loja.pedidos.createIndex({ "itens.produto_id": 1 }, { name: "idx_pedidos_produto" });

// Filtro, projeção e ordenação.
print("\nProdutos eletrônicos por preço:");
loja.produtos
  .find(
    { categoria: "Eletrônicos", preco: { $lte: 1000 } },
    { _id: 0, sku: 1, nome: 1, preco: 1 }
  )
  .sort({ preco: -1 })
  .forEach(printjson);

print("\nPedidos recentes do cliente 1001:");
loja.pedidos
  .find(
    { cliente_id: 1001, status: { $ne: "cancelado" } },
    { _id: 0, numero: 1, criado_em: 1, status: 1, "pagamento.valor": 1 }
  )
  .sort({ criado_em: -1 })
  .forEach(printjson);

print("\nBusca textual no catálogo:");
loja.produtos
  .find(
    { $text: { $search: "trabalho notebook" } },
    { _id: 0, nome: 1, score: { $meta: "textScore" } }
  )
  .sort({ score: { $meta: "textScore" } })
  .forEach(printjson);

// Relacionamento por referência resolvido com $lookup.
print("\nItens com dados atuais do catálogo:");
loja.pedidos.aggregate([
  { $match: { numero: "PED-2026-001" } },
  { $unwind: "$itens" },
  {
    $lookup: {
      from: "produtos",
      localField: "itens.produto_id",
      foreignField: "_id",
      as: "produto_atual"
    }
  },
  { $project: { _id: 0, numero: 1, item: "$itens.nome_snapshot", produto_atual: { $first: "$produto_atual.nome" } } }
]).forEach(printjson);

// Análise dos índices. Em executionStats, procure IXSCAN e examine totalDocsExamined.
print("\nEXPLAIN por SKU:");
printjson(loja.produtos.find({ sku: "EC-001" }).explain("executionStats"));

print("\nEXPLAIN por cliente e data:");
printjson(
  loja.pedidos
    .find({ cliente_id: 1001 })
    .sort({ criado_em: -1 })
    .explain("executionStats")
);

const totalProdutos = loja.produtos.countDocuments({});
const totalPedidos = loja.pedidos.countDocuments({});
if (totalProdutos < 10 || totalPedidos < 10) {
  throw new Error("Carga incompleta: cada collection deve ter ao menos 10 documentos.");
}
print("\nValidação concluída: " + totalProdutos + " produtos e " + totalPedidos + " pedidos.");
