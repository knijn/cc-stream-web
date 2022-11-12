const express = require('express')
const bodyParser = require('body-parser')
const app = express()
const port = 3000

let buffer = ""
app.use(bodyParser.raw({ inflate: true, limit: '100kb', type: 'text/xml' })); // stackoverflow my beloved

app.get('/', (req, res) => {
  res.send(buffer)
})

app.post('/', (req, res) => {
    console.log("got post")
    console.log(req.body)
    if(req.body) {
        buffer = req.body
    }
})

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`)
})
