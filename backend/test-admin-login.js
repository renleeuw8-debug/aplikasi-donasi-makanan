const http = require("http");

const postData = JSON.stringify({
  email: "admin@gmail.com",
  password: "Rhifaldy26",
});

const options = {
  hostname: "localhost",
  port: 3000,
  path: "/api/auth/login",
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "Content-Length": postData.length,
  },
};

const req = http.request(options, (res) => {
  console.log(`STATUS: ${res.statusCode}`);
  console.log(`HEADERS:`, JSON.stringify(res.headers));

  let data = "";
  res.on("data", (chunk) => {
    data += chunk;
  });

  res.on("end", () => {
    console.log(`RESPONSE BODY:`);
    console.log(data);

    try {
      const parsed = JSON.parse(data);
      console.log("\nPARSED JSON:");
      console.log(JSON.stringify(parsed, null, 2));
    } catch (e) {
      console.log("Not valid JSON");
    }
  });
});

req.on("error", (e) => {
  console.error(`problem with request: ${e.message}`);
});

req.write(postData);
req.end();
