const express = require("express");
const app = express();
const port = process.env.PORT || 3000;

app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

app.get("/hello", (req, res) => {
  res.json({ message: "Hello from Dockerized Node backend behind Nginx and APIM!" });
});

app.listen(port, () => {
  console.log(`Backend listening on port ${port}`);
});