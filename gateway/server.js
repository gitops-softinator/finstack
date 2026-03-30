const express = require("express")
const axios = require("axios")
// const client = require("prom-client")
// client.collectDefaultMetrics()
const app = express()

app.use(express.json())

const AUTH_SERVICE_URL = process.env.AUTH_SERVICE_URL || "http://finstack-auth-service:4000"
const USER_SERVICE_URL = process.env.USER_SERVICE_URL || "http://finstack-user-service:4001"
const PAYMENT_SERVICE_URL = process.env.PAYMENT_SERVICE_URL || "http://finstack-payment-service:4002"

app.post("/auth/login", async (req,res)=>{
  const response = await axios.post(`${AUTH_SERVICE_URL}/login`,req.body)
  res.send(response.data)
})

app.post("/auth/register", async (req,res)=>{
  const response = await axios.post(`${AUTH_SERVICE_URL}/register`, req.body)
  res.send(response.data)
})

app.post("/users", async (req,res)=>{
  const response = await axios.post(`${USER_SERVICE_URL}/users`,req.body)
  res.send(response.data)
})

app.post("/pay", async (req,res)=>{
  const response = await axios.post(`${PAYMENT_SERVICE_URL}/pay`,req.body)
  res.send(response.data)
})

/*
const httpRequestsTotal = new client.Counter({
  name: "http_requests_total",
  help: "Total number of HTTP requests",
  labelNames: ["method", "route", "status"]
})

const httpRequestDuration = new client.Histogram({
  name: "http_request_duration_seconds",
  help: "HTTP request latency",
  labelNames: ["method", "route", "status"],
  buckets: [0.05, 0.1, 0.2, 0.5, 1, 2, 5]
})

app.use((req, res, next) => {

  const start = Date.now()

  res.on("finish", () => {

    const duration = (Date.now() - start) / 1000

    httpRequestsTotal.inc({
      method: req.method,
      route: req.route ? req.route.path : req.path,
      status: res.statusCode
    })

    httpRequestDuration.observe({
      method: req.method,
      route: req.route ? req.route.path : req.path,
      status: res.statusCode
    }, duration)

  })

  next()

})
*/

app.get("/health", async (req, res) => {
  try {
    await axios.get(`${AUTH_SERVICE_URL}/health`);
    res.status(200).json({
      status: "UP",
      service: "finstack-gateway"
    });
  } catch (err) {
    res.status(500).json({
      status: "DOWN",
      dependency: "finstack-auth-service"
    });
  }
});

app.get("/healthz", (req, res) => {
  res.status(200).send("OK");
});


/*
app.get("/metrics", async (req,res)=>{
  res.set("Content-Type", client.register.contentType)
  res.end(await client.register.metrics())
})
*/

app.listen(3000,()=>{
  console.log("API Gateway running")
})
