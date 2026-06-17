import { useState } from "react"
import axios from "axios"

const API = import.meta.env.VITE_API_URL || "/api"

export default function Cart() {
  const [cart, setCart]       = useState(JSON.parse(localStorage.getItem("cart") || "[]"))
  const [customer, setCustomer] = useState("")
  const [email, setEmail]     = useState("")
  const [placed, setPlaced]   = useState(false)

  const total = cart.reduce((s, i) => s + i.price * i.quantity, 0)

  const placeOrder = async () => {
    if (!customer || !email) return alert("Please enter your name and email")
    await axios.post(`${API}/orders/`, {
      customer, email,
      items: cart.map(i => ({ product_id: i.id, name: i.name, price: i.price, quantity: i.quantity }))
    })
    localStorage.removeItem("cart")
    setCart([])
    setPlaced(true)
  }

  if (placed) return <h2>Order placed! Thank you, {customer}.</h2>
  if (cart.length === 0) return <p>Your cart is empty.</p>

  return (
    <div>
      <h1>Cart</h1>
      {cart.map(i => (
        <div key={i.id} style={styles.item}>
          <span>{i.name}</span>
          <span>x{i.quantity}</span>
          <span>${(i.price * i.quantity).toFixed(2)}</span>
        </div>
      ))}
      <h3>Total: ${total.toFixed(2)}</h3>
      <input placeholder="Your name"  value={customer} onChange={e => setCustomer(e.target.value)} style={styles.input} />
      <input placeholder="Your email" value={email}    onChange={e => setEmail(e.target.value)}    style={styles.input} />
      <button style={styles.btn} onClick={placeOrder}>Place Order</button>
    </div>
  )
}

const styles = {
  item:  { display:"flex", justifyContent:"space-between", padding:"0.5rem 0", borderBottom:"1px solid #eee" },
  input: { display:"block", margin:"0.5rem 0", padding:"0.5rem", width:"300px", border:"1px solid #ddd", borderRadius:"4px" },
  btn:   { background:"#e94560", color:"#fff", border:"none", padding:"0.8rem 2rem", borderRadius:"4px", cursor:"pointer", marginTop:"1rem" },
}
