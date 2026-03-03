/**
 * Firebase Cloud Functions for Vertex AI Integration
 * Using REST API directly instead of heavy SDK
 */

import {setGlobalOptions} from "firebase-functions";
import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import {GoogleAuth} from "google-auth-library";

// Configuration
const PROJECT_ID = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || "";
const LOCATION = "us-central1";
// Use Vertex AI model names (different from generativelanguage API)
const TEXT_MODEL = "gemini-2.0-flash-001";
// Imagen model for image generation
const IMAGE_MODEL = "imagen-3.0-generate-001";

// Global options for all functions
setGlobalOptions({
  maxInstances: 10,
  region: LOCATION,
});

// Auth client for getting access tokens
const auth = new GoogleAuth({
  scopes: ["https://www.googleapis.com/auth/cloud-platform"],
});

/**
 * Generate meal recipe text using Gemini via Vertex AI REST API
 */
export const generateMealText = onRequest(
  {
    cors: true,
    invoker: "public", // Allow unauthenticated access
  },
  async (request, response) => {
    logger.info("generateMealText called", {method: request.method});

    if (request.method !== "POST") {
      response.status(405).json({
        success: false,
        error: "Method not allowed. Use POST.",
      });
      return;
    }

    try {
      const {prompt, maxTokens = 1024} = request.body;

      if (!prompt || typeof prompt !== "string" ||
          prompt.trim().length === 0) {
        response.status(400).json({
          success: false,
          error: "Missing or invalid 'prompt' field.",
        });
        return;
      }

      logger.info("Generating text", {promptLength: prompt.length});

      // Get access token
      const client = await auth.getClient();
      const accessToken = await client.getAccessToken();

      const systemPrompt = `You are a professional nutritionist and chef.
Generate a healthy meal recipe based on the user's request.
Return ONLY valid JSON in this format:
{
  "name": "Meal Name",
  "description": "Brief description",
  "calories": 450,
  "protein": 35,
  "carbs": 25,
  "fats": 18,
  "ingredients": ["ingredient 1", "ingredient 2"],
  "instructions": ["step 1", "step 2"],
  "image_prompt": "Professional food photography description"
}
Do NOT include markdown or explanations.`;

      // Call Vertex AI REST API
      const url = `https://${LOCATION}-aiplatform.googleapis.com/v1/projects/` +
        `${PROJECT_ID}/locations/${LOCATION}/publishers/google/models/` +
        `${TEXT_MODEL}:generateContent`;

      const apiResponse = await fetch(url, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken.token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          contents: [
            {role: "user", parts: [{text: systemPrompt}]},
            {role: "user", parts: [{text: prompt}]},
          ],
          generationConfig: {
            maxOutputTokens: maxTokens,
            temperature: 0.8,
            topP: 0.9,
          },
        }),
      });

      if (!apiResponse.ok) {
        const errorText = await apiResponse.text();
        throw new Error(`Vertex AI error: ${apiResponse.status} ${errorText}`);
      }

      const data = await apiResponse.json();
      const generatedText =
        data.candidates?.[0]?.content?.parts?.[0]?.text || "";

      if (!generatedText) {
        throw new Error("Empty response from Gemini");
      }

      logger.info("Text generated successfully", {
        responseLength: generatedText.length,
      });

      response.status(200).json({
        success: true,
        text: generatedText,
        model: TEXT_MODEL,
      });
    } catch (error) {
      const msg = error instanceof Error ? error.message : "Unknown error";
      logger.error("generateMealText error", {error: msg});

      response.status(500).json({
        success: false,
        error: `Failed to generate text: ${msg}`,
      });
    }
  }
);

/**
 * Generate meal image using Imagen via Vertex AI REST API
 */
export const generateMealImage = onRequest(
  {
    cors: true,
    invoker: "public", // Allow unauthenticated access
  },
  async (req, res) => {
    logger.info("generateMealImage called", {method: req.method});

    if (req.method !== "POST") {
      res.status(405).json({
        success: false,
        error: "Method not allowed. Use POST.",
      });
      return;
    }

    try {
      const {prompt} = req.body as {prompt?: string};

      if (!prompt || typeof prompt !== "string" ||
          prompt.trim().length === 0) {
        res.status(400).json({
          success: false,
          error: "Missing or invalid 'prompt' field.",
        });
        return;
      }

      logger.info("Generating image", {promptLength: prompt.length});

      // Get access token
      const client = await auth.getClient();
      const accessToken = await client.getAccessToken();

      const enhancedPrompt =
        `Professional food photography of ${prompt}. ` +
        "Style: high-quality, well-lit, appetizing, shallow depth of field, " +
        "natural lighting, restaurant quality presentation.";

      // Try multiple model endpoints
      const modelEndpoints = [
        `https://${LOCATION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${LOCATION}/publishers/google/models/imagegeneration@006:predict`,
        `https://${LOCATION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${LOCATION}/publishers/google/models/imagen-3.0-generate-001:predict`,
        `https://${LOCATION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${LOCATION}/publishers/google/models/imagen-3.0-fast-generate-001:predict`,
      ];

      let imageBase64: string | null = null;
      let lastError = "";

      for (const url of modelEndpoints) {
        logger.info("Trying endpoint", {url: url.split("/models/")[1]});

        try {
          const apiResponse = await fetch(url, {
            method: "POST",
            headers: {
              "Authorization": `Bearer ${accessToken.token}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              instances: [{prompt: enhancedPrompt}],
              parameters: {
                sampleCount: 1,
                aspectRatio: "4:3",
                negativePrompt: "blurry, low quality, distorted, ugly",
              },
            }),
          });

          if (apiResponse.ok) {
            const data = await apiResponse.json();
            logger.info("API Response structure", {
              keys: Object.keys(data),
              hasPredictions: !!data.predictions,
            });

            // Try different response formats
            imageBase64 = data.predictions?.[0]?.bytesBase64Encoded ||
                          data.predictions?.[0]?.image?.bytesBase64Encoded ||
                          data.predictions?.[0]?.output;

            if (imageBase64) {
              logger.info("Image generated successfully", {
                imageSize: imageBase64.length,
                model: url.split("/models/")[1],
              });
              break;
            }
          } else {
            const errorText = await apiResponse.text();
            lastError = `${apiResponse.status}: ${errorText}`;
            logger.warn("Model failed", {
              model: url.split("/models/")[1],
              status: apiResponse.status,
              error: errorText.substring(0, 200),
            });
          }
        } catch (e) {
          lastError = e instanceof Error ? e.message : "Unknown error";
          logger.warn("Model exception", {error: lastError});
        }
      }

      if (!imageBase64) {
        throw new Error(`All image models failed. Last error: ${lastError}`);
      }

      res.status(200).json({
        success: true,
        image: imageBase64,
        mimeType: "image/png",
        model: IMAGE_MODEL,
      });
    } catch (error) {
      const msg = error instanceof Error ? error.message : "Unknown error";
      logger.error("generateMealImage error", {error: msg});

      res.status(500).json({
        success: false,
        error: `Failed to generate image: ${msg}`,
      });
    }
  }
);

/**
 * Health check endpoint
 */
export const healthCheck = onRequest(
  {
    cors: true,
    invoker: "public", // Allow unauthenticated access
  },
  async (request, response) => {
    response.status(200).json({
      status: "ok",
      timestamp: new Date().toISOString(),
      project: PROJECT_ID,
      region: LOCATION,
      models: {
        text: TEXT_MODEL,
        image: IMAGE_MODEL,
      },
    });
  }
);

