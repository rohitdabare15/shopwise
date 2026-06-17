import { useEffect, useState } from "react"
import axios from "axios"

const API = import.meta.env.VITE_API_URL || "/api"

export default function Products() {
  const [products, setProducts] = useState([])
  const [loading, setLoading]   = useState(true)
  const [error, setError]       = useState(null)

  useEffect(() => {
    axios.get(`${API}/products/`)
      .then(r => setProducts(r.data))
      .catch(() => setError("Could not load products"))
      .finally(() => setLoading(false))
  }, [])

  const addToCart = (product) => {
    const cart = JSON.parse(localStorage.getItem("cart") || "[]")
    const existing = cart.find(i => i.id === product.id)
    if (existing) existing.quantity += 1
    else cart.push({ ...product, quantity: 1 })
    localStorage.setItem("cart", JSON.stringify(cart))
    alert(`${product.name} added to cart`)
  }

  if (loading) return <p>Loading products...</p>
  if (error)   return <p style={{color:"red"}}>{error}</p>
  if (products.length === 0) return (
    <div>
      <p>No products yet.</p>
      <button onClick={() => axios.post(`${API}/products/seed`).then(() => window.location.reload())}>
        Seed demo products
      </button>
    </div>
  )

  return (
    <div>
      <h1>Products</h1>
      <div style={styles.grid}>
        {products.map(p => (
          <div key={p.id} style={styles.card}>
            <h3>{p.name}</h3>
            <p style={styles.category}>{p.category}</p>
            <p>{p.description}</p>
            <p style={styles.price}>${p.price}</p>
            <p style={styles.stock}>In stock: {p.stock}</p>
            <button style={styles.btn} onClick={() => addToCart(p)}>Add to Cart</button>
          </div>
        ))}
      </div>
    </div>
  )
}

const styles = {
  grid:     { display:"grid", gridTemplateColumns:"repeat(auto-fill, minmax(250px,1fr))", gap:"1.5rem" },
  card:     { border:"1px solid #ddd", borderRadius:"8px", padding:"1.5rem", background:"#fff" },
  category: { color:"#888", fontSize:"0.85rem", textTransform:"uppercase" },
  price:    { fontSize:"1.4rem", fontWeight:"bold", color:"#e94560" },
  stock:    { color:"#666", fontSize:"0.9rem" },
  btn:      { background:"#e94560", color:"#fff", border:"none", padding:"0.6rem 1.2rem", borderRadius:"4px", cursor:"pointer", width:"100%" },
}
