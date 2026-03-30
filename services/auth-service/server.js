// require('./tracing')
const express = require("express")
const mongoose = require("mongoose")
const jwt = require("jsonwebtoken")
const bcrypt = require("bcryptjs")
// const client = require("prom-client")
// client.collectDefaultMetrics()

const app = express()
app.use(express.json())

mongoose.connect("mongodb://finstack-mongodb-service:27017/auth")

const User = mongoose.model("User", {
  email: String,
  password: String
})

app.post("/register", async (req,res)=>{
  const hashed = await bcrypt.hash(req.body.password,10)

  const user = new User({
    email:req.body.email,
    password:hashed
  })

  await user.save()
  res.send(user)
})

app.post("/login", async (req,res)=>{

  const user = await User.findOne({email:req.body.email})

  if(!user) return res.status(401).send("Invalid")

  const valid = await bcrypt.compare(req.body.password,user.password)

  if(!valid) return res.status(401).send("Invalid")

  const token = jwt.sign({id:user._id},"SECRET")

  res.send({token})
})

app.get("/health", (req,res)=>{
  res.status(200).send({
    status: "UP",
    service: "auth-service"
  })
})

/*
app.get("/metrics", async (req, res) => {
  res.set("Content-Type", client.register.contentType)
  res.end(await client.register.metrics())
})
*/

app.listen(4000,()=>{
  console.log("Auth service running")
})
