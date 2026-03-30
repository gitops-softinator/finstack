// require('./tracing')
const express = require("express")
// const client = require("prom-client")
// client.collectDefaultMetrics()
const app = express()
app.use(express.json())

let payments = []

app.post("/pay",(req,res)=>{
  const payment = {
    id:Date.now(),
    amount:req.body.amount,
    user:req.body.user
  }

  payments.push(payment)

  res.send(payment)
})

app.get("/payments",(req,res)=>{
  res.send(payments)
})

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'UP',
    service: 'payment-service'
  });
});

/*
app.get("/metrics", async (req,res)=>{
  res.set("Content-Type", client.register.contentType)
  res.end(await client.register.metrics())
})
*/

app.listen(4002,()=>{
  console.log("Payment service running")
})
