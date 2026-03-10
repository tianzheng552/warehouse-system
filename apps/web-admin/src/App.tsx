import { useEffect, useState } from "react";

type Product = {
  id: number;
  sku: string;
  name: string;
  stock: number;
};

type Movement = {
  id: number;
  created_at: string;
  movement_type: string;
  direction: number;
  qty: number;
  before_qty: number | null;
  after_qty: number | null;
  sku: string;
  product_name: string;
  warehouse_name: string;
  location_code: string;
};

const API = "http://127.0.0.1:4000";

export default function App() {
  const [activeTab, setActiveTab] = useState<
    "inventory" | "products" | "movements"
  >("inventory");

  const [list, setList] = useState<Product[]>([]);
  const [movements, setMovements] = useState<Movement[]>([]);

  const [sku, setSku] = useState("SKU-001");
  const [qty, setQty] = useState(1);

  const [productSku, setProductSku] = useState("SKU-001");
  const [productName, setProductName] = useState("示例商品");
  const [productStock, setProductStock] = useState(0);

  async function loadInventory() {
    const res = await fetch(`${API}/inventory`);
    const data = await res.json();
    setList(data);
  }

  async function loadProducts() {
    const res = await fetch(`${API}/products`);
    const data = await res.json();
    setList(data);
  }

  async function loadMovements() {
    const res = await fetch(`${API}/inventory/movements`);
    const data = await res.json();
    setMovements(data);
  }

  async function stockIn() {
    await fetch(`${API}/inventory/in`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ sku, qty: Number(qty) }),
    });
    await loadInventory();
    await loadMovements();
  }

  async function stockOut() {
    await fetch(`${API}/inventory/out`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ sku, qty: Number(qty) }),
    });
    await loadInventory();
    await loadMovements();
  }

  async function createProduct() {
    await fetch(`${API}/products`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        sku: productSku,
        name: productName,
        stock: Number(productStock),
      }),
    });
    await loadProducts();
  }

  async function deleteProduct(id: number) {
    await fetch(`${API}/products/${id}`, {
      method: "DELETE",
    });
    await loadProducts();
  }

  useEffect(() => {
    if (activeTab === "inventory") {
      loadInventory();
      loadMovements();
    } else if (activeTab === "products") {
      loadProducts();
    } else if (activeTab === "movements") {
      loadMovements();
    }
  }, [activeTab]);

  return (
    <div style={{ padding: 24, fontFamily: "sans-serif" }}>
      <h2>仓库管理（最小版）</h2>

      <div style={{ display: "flex", gap: 8, marginBottom: 16 }}>
        <button
          onClick={() => setActiveTab("inventory")}
          style={{
            padding: "4px 12px",
            background: activeTab === "inventory" ? "#1890ff" : "#f0f0f0",
            color: activeTab === "inventory" ? "#fff" : "#000",
            border: "1px solid #d9d9d9",
            borderRadius: 4,
          }}
        >
          库存操作
        </button>
        <button
          onClick={() => setActiveTab("products")}
          style={{
            padding: "4px 12px",
            background: activeTab === "products" ? "#1890ff" : "#f0f0f0",
            color: activeTab === "products" ? "#fff" : "#000",
            border: "1px solid #d9d9d9",
            borderRadius: 4,
          }}
        >
          产品管理
        </button>
        <button
          onClick={() => setActiveTab("movements")}
          style={{
            padding: "4px 12px",
            background: activeTab === "movements" ? "#1890ff" : "#f0f0f0",
            color: activeTab === "movements" ? "#fff" : "#000",
            border: "1px solid #d9d9d9",
            borderRadius: 4,
          }}
        >
          库存流水
        </button>
      </div>

      {activeTab === "inventory" && (
        <>
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
            <button onClick={loadInventory}>刷新</button>
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
        </>
      )}

      {activeTab === "products" && (
        <>
          <div
            style={{
              display: "flex",
              gap: 8,
              marginBottom: 16,
              alignItems: "center",
            }}
          >
            <input
              value={productSku}
              onChange={(e) => setProductSku(e.target.value)}
              placeholder="SKU"
            />
            <input
              value={productName}
              onChange={(e) => setProductName(e.target.value)}
              placeholder="名称"
            />
            <input
              type="number"
              value={productStock}
              onChange={(e) => setProductStock(Number(e.target.value))}
              placeholder="初始库存"
            />
            <button onClick={createProduct}>新增产品</button>
            <button onClick={loadProducts}>刷新</button>
          </div>

          <table border={1} cellPadding={8}>
            <thead>
              <tr>
                <th>ID</th>
                <th>SKU</th>
                <th>名称</th>
                <th>库存</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              {list.map((p) => (
                <tr key={p.id}>
                  <td>{p.id}</td>
                  <td>{p.sku}</td>
                  <td>{p.name}</td>
                  <td>{p.stock}</td>
                  <td>
                    <button onClick={() => deleteProduct(p.id)}>删除</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </>
      )}

      {activeTab === "movements" && (
        <>
          <table border={1} cellPadding={8}>
            <thead>
              <tr>
                <th>ID</th>
                <th>时间</th>
                <th>类型</th>
                <th>SKU</th>
                <th>名称</th>
                <th>仓库</th>
                <th>库位</th>
                <th>数量</th>
                <th>变更前</th>
                <th>变更后</th>
              </tr>
            </thead>
            <tbody>
              {movements.map((m) => (
                <tr key={m.id}>
                  <td>{m.id}</td>
                  <td>{new Date(m.created_at).toLocaleString()}</td>
                  <td>{m.movement_type}</td>
                  <td>{m.sku}</td>
                  <td>{m.product_name}</td>
                  <td>{m.warehouse_name}</td>
                  <td>{m.location_code}</td>
                  <td style={{ color: m.direction > 0 ? "green" : "red" }}>
                    {m.direction > 0 ? "+" : "-"}
                    {m.qty}
                  </td>
                  <td>{m.before_qty ?? "-"}</td>
                  <td>{m.after_qty ?? "-"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </>
      )}
    </div>
  );
}
