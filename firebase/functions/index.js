const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");
const {defineSecret} = require("firebase-functions/params");

admin.initializeApp();

const anthropicApiKey = defineSecret("ANTHROPIC_API_KEY");

exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
  let firestore = admin.firestore();
  await firestore.collection("users").doc(user.uid).delete();
});

exports.claudeProxy = functions
    .runWith({secrets: [anthropicApiKey]})
    .https.onRequest(async (req, res) => {
  // Basic CORS handling for browser clients.
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set(
    "Access-Control-Allow-Headers",
    "Content-Type, X-API-Key, x-api-key, anthropic-version",
  );

  if (req.method === "OPTIONS") {
    return res.status(204).send("");
  }

  if (req.method !== "POST") {
    return res.status(405).send({error: "Method not allowed"});
  }

  const apiKey = anthropicApiKey.value();
  if (!apiKey) {
    return res.status(500).send({
      error: "Missing Anthropic API key secret.",
    });
  }

  try {
    const payload = {
      model: req.body?.model || "claude-3-5-sonnet-20241022",
      max_tokens: req.body?.max_tokens || 1024,
      temperature: req.body?.temperature ?? 0.7,
      system: req.body?.system,
      messages: Array.isArray(req.body?.messages) ? req.body.messages : [],
    };

    const response = await axios.post(
      "https://api.anthropic.com/v1/messages",
      payload,
      {
        headers: {
          "Content-Type": "application/json",
          "x-api-key": apiKey,
          "anthropic-version": "2023-06-01",
        },
      },
    );

    return res.status(response.status).send(response.data);
  } catch (err) {
    const status = err.response?.status || 500;
    const data = err.response?.data || {error: err.message};
    return res.status(status).send(data);
  }
    });
