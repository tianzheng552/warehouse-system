import { useEffect, useState } from "react";

type Product = {
  id: number;
  sku: string;
  name: string;
  stock: number;
};

const API = "http://127.0.0.1:4000";

export default function App() {
  const [list, setList] = useState<Product[]>([]);
  const [sku, setSku] = useState("SKU-001");
  const [qty, setQty] = useState(1);

  async function load() {
    const res = await fetch(`${API}/inventory`);
    const data = await res.json();
    setList(data);
  }

  async function stockIn() {
    await fetch(`${API}/inventory/in`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ sku, qty: Number(qty) }),
    });
    await load();
  }

  async function stockOut() {
    await fetch(`${API}/inventory/out`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ sku, qty: Number(qty) }),
    });
    await load();
  }

  useEffect(() => {
    load();
  }, []);

  return (
    <div style={{ padding: 24, fontFamily: "sans-serif" }}>
      <h2>仓库管理（最小版）</h2>

      <div style={{ display: "flex", gap: 8, marginBottom: 16 }}>
        <input
          value={sku}
          onChange={(e) => setSku(e.target.value)}
          placeholder="SKU"
        />
        <input
          type="number"
          value={qty}
          onChange={(e) => setQty(Number(e.target.value))}
          placeholder="数量"
        />
        <button onClick={stockIn}>入库</button>
        <button onClick={stockOut}>出库</button>
        <button onClick={load}>刷新</button>
      </div>

      <table border={1} cellPadding={8}>
        <thead>
          <tr>
            <th>ID</th>
            <th>SKU</th>
            <th>名称</th>
            <th>库存</th>
          </tr>
        </thead>
        <tbody>
          {list.map((p) => (
            <tr key={p.id}>
              <td>{p.id}</td>
              <td>{p.sku}</td>
              <td>{p.name}</td>
              <td>{p.stock}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
