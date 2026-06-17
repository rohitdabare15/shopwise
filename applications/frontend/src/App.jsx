import { BrowserRouter, Routes, Route, Link } from "react-router-dom"
import Products from "./pages/Products"
import Cart     from "./pages/Cart"
import Orders   from "./pages/Orders"

export default function App() {
  return (
    <BrowserRouter>
      <nav style={styles.nav}>
        <span style={styles.brand}>Shopwise</span>
        <Link to="/"      style={styles.link}>Products</Link>
        <Link to="/cart"  style={styles.link}>Cart</Link>
        <Link to="/orders" style={styles.link}>Orders</Link>
      </nav>
      <main style={styles.main}>
        <Routes>
          <Route path="/"       element={<Products />} />
          <Route path="/cart"   element={<Cart />} />
          <Route path="/orders" element={<Orders />} />
        </Routes>
      </main>
    </BrowserRouter>
  )
}

const styles = {
  nav:   { background:"#1a1a2e", padding:"1rem 2rem", display:"flex", alignItems:"center", gap:"2rem" },
  brand: { color:"#e94560", fontWeight:"bold", fontSize:"1.4rem", marginRight:"auto" },
  link:  { color:"#fff", textDecoration:"none" },
  main:  { padding:"2rem", maxWidth:"1200px", margin:"0 auto" },
}
