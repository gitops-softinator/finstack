require('./tracing')
const express = require("express")
const mongoose = require("mongoose")
const client = require("prom-client")
client.collectDefaultMetrics()
const app = express()
app.use(express.json())

mongoose.connect("mongodb://finstack-mongodb-service:27017/users", {
  useNewUrlParser: true,
  useUnifiedTopology: true
})

mongoose.connection.on("connected", () => {
  console.log("MongoDB connected - user-service")
})

mongoose.connection.on("error", (err) => {
  console.error("MongoDB connection error:", err)
})

const User = mongoose.model("User", {
  name: String,
  email: String,
  phone: String
})

app.post("/users", async (req, res) => {
  try {
    const user = new User({
      name: req.body.name,
      email: req.body.email,
      phone: req.body.phone
    })

    await user.save()
    res.status(201).send(user)

  } catch (error) {
    res.status(500).send({ error: "Failed to create user" })
  }
})

app.get("/users", async (req, res) => {
  try {
    const users = await User.find()
    res.send(users)

  } catch (error) {
    res.status(500).send({ error: "Failed to fetch users" })
  }
})

app.get("/users/:id", async (req, res) => {
  try {
    const user = await User.findById(req.params.id)

    if (!user) {
      return res.status(404).send({ error: "User not found" })
    }

    res.send(user)

  } catch (error) {
    res.status(500).send({ error: "Error retrieving user" })
  }
})

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'UP',
    service: 'user-service'
  });
});

app.get("/metrics", async (req,res)=>{
  res.set("Content-Type", client.register.contentType)
  res.end(await client.register.metrics())
})

app.listen(4001, () => {
  console.log("User service running on port 4001")
})
