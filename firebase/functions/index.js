const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");
admin.initializeApp();

exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
  let firestore = admin.firestore();
  let userRef = firestore.doc("users/" + user.uid);
});

function asString(value, fallback) {
  if (typeof value === "string" && value.trim().length > 0) {
    return value.trim();
  }
  return fallback;
}

function asInt(value, fallback) {
  if (typeof value === "number" && Number.isFinite(value)) {
    return Math.round(value);
  }
  if (typeof value === "string") {
    const parsed = parseInt(value.trim(), 10);
    if (!Number.isNaN(parsed)) {
      return parsed;
    }
  }
  return fallback;
}

function asStringList(value, fallback) {
  if (Array.isArray(value)) {
    const list = value
      .map((item) => (item == null ? "" : String(item).trim()))
      .filter((item) => item.length > 0);
    if (list.length > 0) {
      return list;
    }
  }
  return fallback;
}

function decodeJsonObject(raw) {
  const trimmed = String(raw || "").trim();
  try {
    return JSON.parse(trimmed);
  } catch (_) {
    const firstBrace = trimmed.indexOf("{");
    const lastBrace = trimmed.lastIndexOf("}");
    if (firstBrace !== -1 && lastBrace > firstBrace) {
      return JSON.parse(trimmed.slice(firstBrace, lastBrace + 1));
    }
    throw new Error("OpenAI response is not valid JSON content.");
  }
}

function buildPrompt(profile) {
  const goal = asString(profile?.weightGoal, "General Health");
  const diet = asString(profile?.dietType, "Regular");
  const allergies = asString(profile?.allergies, "None specified");
  const skin = asString(profile?.skinType, "Unknown");

  return `Analyze this product image (label/package). Return ONLY JSON with keys:
productName (string), brandName (string), healthScore (int 1-100), ingredients (array of strings), warnings (array of max 3 strings), benefits (array of max 3 strings), recommendation (short string), impactForUser (short string tailored to profile).
User profile context:
- Goal: ${goal}
- Diet type: ${diet}
- Allergies: ${allergies}
- Skin type: ${skin}
If label text is unclear, infer conservatively and mention uncertainty briefly in recommendation.`;
}

exports.analyzeProductScan = functions
  .region("us-central1")
  .runWith({
    timeoutSeconds: 60,
    memory: "1GB",
    secrets: ["OPENAI_API_KEY"],
  })
  .https.onRequest(async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");

    if (req.method === "OPTIONS") {
      return res.status(204).send("");
    }

    if (req.method !== "POST") {
      return res.status(405).json({ error: "Method Not Allowed" });
    }

    try {
      const authHeader = req.headers.authorization || "";
      if (!authHeader.startsWith("Bearer ")) {
        return res.status(401).json({ error: "Missing auth token" });
      }

      const idToken = authHeader.substring("Bearer ".length).trim();
      const decodedToken = await admin.auth().verifyIdToken(idToken);

      const imageDataUrl = asString(req.body?.imageDataUrl, "");
      if (!imageDataUrl.startsWith("data:image/")) {
        return res.status(400).json({ error: "Invalid or missing imageDataUrl" });
      }

      const openAiKey = process.env.OPENAI_API_KEY || "";
      if (!openAiKey) {
        return res.status(500).json({ error: "OpenAI key not configured" });
      }

      const prompt = buildPrompt(req.body?.profile || {});

      const openAiResponse = await axios.post(
        "https://api.openai.com/v1/chat/completions",
        {
          model: "gpt-4o-mini",
          temperature: 0.2,
          response_format: { type: "json_object" },
          messages: [
            {
              role: "user",
              content: [
                { type: "text", text: prompt },
                { type: "image_url", image_url: { url: imageDataUrl } },
              ],
            },
          ],
        },
        {
          headers: {
            Authorization: `Bearer ${openAiKey}`,
            "Content-Type": "application/json",
          },
          timeout: 45000,
        }
      );

      const content =
        openAiResponse?.data?.choices?.[0]?.message?.content || "";
      if (!content || String(content).trim().length === 0) {
        throw new Error("OpenAI returned empty content");
      }

      const parsed = decodeJsonObject(content);
      const analysis = {
        productName: asString(parsed.productName, "Scanned Product"),
        brandName: asString(parsed.brandName, "Unknown Brand"),
        healthScore: Math.max(1, Math.min(100, asInt(parsed.healthScore, 70))),
        ingredients: asStringList(parsed.ingredients, ["Ingredient data not found"]),
        warnings: asStringList(parsed.warnings, ["No major warning detected"]),
        benefits: asStringList(parsed.benefits, ["No specific benefit extracted"]),
        recommendation: asString(
          parsed.recommendation,
          "Consume in moderation and check ingredient details."
        ),
        impactForUser: asString(parsed.impactForUser, ""),
      };

      const now = admin.firestore.FieldValue.serverTimestamp();
      const scanDoc = await admin.firestore().collection("scans").add({
        owner: admin.firestore().doc(`users/${decodedToken.uid}`),
        product_image: imageDataUrl,
        product_name: analysis.productName,
        brand_name: analysis.brandName,
        ingredients: analysis.ingredients.join(", "),
        warnings: analysis.warnings,
        benefits: analysis.benefits,
        recommendation: analysis.recommendation,
        impact_for_user: analysis.impactForUser,
        health_score: String(analysis.healthScore),
        scan_date: now,
        created_time: now,
        user_id: decodedToken.uid,
        uid: decodedToken.uid,
        email: decodedToken.email || "",
        display_name: decodedToken.name || "",
        photo_url: decodedToken.picture || "",
        phone_number: decodedToken.phone_number || "",
      });

      return res.status(200).json({ analysis, scanId: scanDoc.id });
    } catch (error) {
      console.error("analyzeProductScan failed", error);
      const responseStatus = error?.response?.status;
      if (responseStatus && responseStatus >= 400) {
        return res.status(502).json({
          error: "OpenAI upstream failure",
          status: responseStatus,
        });
      }

      return res.status(500).json({
        error: "Scan analysis failed",
        message: error?.message || "Unknown error",
      });
    }
  });
