require('./tracing')
const express = require("express")
const client = require("prom-client")
client.collectDefaultMetrics()
const app = express()

app.use(express.json())

app.post("/notify",(req,res)=>{
  console.log("Notification sent to",req.body.user)
  res.send("Notification delivered")
})

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'UP',
    service: 'notification-service'
  });
});

app.get("/metrics", async (req,res)=>{
  res.set("Content-Type", client.register.contentType)
  res.end(await client.register.metrics())
})

app.listen(4003,()=>{
  console.log("Notification service running")
})
