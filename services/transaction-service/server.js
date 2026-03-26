require('./tracing')
const express = require("express")
const mongoose = require("mongoose")
const client = require("prom-client")
client.collectDefaultMetrics()
const app = express()
app.use(express.json())

mongoose.connect("mongodb://finstack-mongodb-service:27017/transactions")

const Transaction = mongoose.model("Transaction", {
  userId: String,
  amount: Number,
  type: String,
  status: String,
  createdAt: {
    type: Date,
    default: Date.now
  }
})

app.post("/transactions", async (req, res) => {
  const transaction = new Transaction(req.body)
  await transaction.save()
  res.send(transaction)
})

app.get("/transactions", async (req, res) => {
  const transactions = await Transaction.find()
  res.send(transactions)
})

app.get("/transactions/:id", async (req, res) => {
  const transaction = await Transaction.findById(req.params.id)
  res.send(transaction)
})

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'UP',
    service: 'transaction-service'
  });
});

app.get("/metrics", async (req,res)=>{
  res.set("Content-Type", client.register.contentType)
  res.end(await client.register.metrics())
})

app.listen(4004, () => {
  console.log("Transaction service running on port 4004")
})
