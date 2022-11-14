const Fastify = require('fastify')
const app = Fastify({
    logger: true
})
const path = require('path')


const port = 3000

let buffer = ""

app.register(require('@fastify/static'), {
  root: path.join(__dirname, 'public'),
  prefix: '/public/', // optional: default '/'
})


app.addContentTypeParser(
    "text/html",
    { parseAs: "string" },
    function (req, body, done) {
      try {
        var newBody = {
          raw: body,
          //parsed: JSON.parse(body),
        };
        done(null, newBody);
      } catch (error) {
        error.statusCode = 400;
        done(error, undefined);
      }
    }
  );

app.get('/', (req, res) => {
  res.type("text/html")
  res.send(buffer)
})

app.get("/stream.css",(req,res) => {
  res.sendFile("stream.css")
})

app.get("/minecraftia.ttf",(req,res) => {
  res.sendFile("minecraftia.ttf")
})

app.post('/', (req, res) => {
    console.log("got post")
    console.log(req.body.raw)
    if(req.body) {
        buffer = req.body.raw
    }
})



app.listen(port, () => {
  console.log(`Example app listening on port ${port}`)
})
