const Cart = {
  key: "nd_cart",

  load() {
    try { return JSON.parse(localStorage.getItem(this.key)) || []; }
    catch (e) { return []; }
  },

  save(lines) {
    try { localStorage.setItem(this.key, JSON.stringify(lines)); } catch (e) {}
    updateBadge();
  },

  add(id, qty = 1) {
    const lines = this.load();
    const line = lines.find(l => l.id === id);
    if (line) line.qty += qty;
    else lines.push({ id, qty });
    this.save(lines);
  },

  remove(id) {
    this.save(this.load().filter(l => l.id !== id));
  },

  clear() { this.save([]); },

  items() {
    return this.load()
      .map(l => ({ p: getProduct(l.id), qty: l.qty }))
      .filter(l => l.p)
      .map(l => toItem(l.p, { quantity: l.qty }));
  },

  total() {
    return this.items().reduce((s, i) => s + i.price * i.quantity, 0);
  }
};

function updateBadge() {
  const el = document.getElementById("cart-count");
  if (el) el.textContent = Cart.load().reduce((s, l) => s + l.qty, 0);
}

function euro(n) {
  return "€" + n.toFixed(2);
}

document.addEventListener("DOMContentLoaded", updateBadge);
