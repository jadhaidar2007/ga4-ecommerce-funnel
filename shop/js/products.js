const PRODUCTS = [
  { item_id: "NDS-001", item_name: "Canvas Tote", item_category: "Bags", price: 24.0, img: "tote" },
  { item_id: "NDS-002", item_name: "Roll-top Backpack", item_category: "Bags", price: 89.0, img: "backpack" },
  { item_id: "NDS-003", item_name: "Enamel Mug", item_category: "Kitchen", price: 14.5, img: "mug" },
  { item_id: "NDS-004", item_name: "Pour-over Set", item_category: "Kitchen", price: 39.0, img: "pourover" },
  { item_id: "NDS-005", item_name: "Dot Grid Notebook", item_category: "Stationery", price: 12.0, img: "notebook" },
  { item_id: "NDS-006", item_name: "Brass Pen", item_category: "Stationery", price: 32.0, img: "pen" },
  { item_id: "NDS-007", item_name: "Wool Beanie", item_category: "Apparel", price: 22.0, img: "beanie" },
  { item_id: "NDS-008", item_name: "Heavy Hoodie", item_category: "Apparel", price: 64.0, img: "hoodie" }
];

const COLORS = {
  Bags: "#c8b79e", Kitchen: "#9fb4a6", Stationery: "#b7a6c4", Apparel: "#d3a89a"
};

function getProduct(id) {
  return PRODUCTS.find(p => p.item_id === id);
}

// GA4 wants this exact shape for items[]
function toItem(p, extra = {}) {
  return {
    item_id: p.item_id,
    item_name: p.item_name,
    item_category: p.item_category,
    item_brand: "Northdock",
    price: p.price,
    ...extra
  };
}
