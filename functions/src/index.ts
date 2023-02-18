import { onCall, onRequest } from 'firebase-functions/v2/https';
import { getStorage } from 'firebase-admin/storage';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { randomUUID } from 'crypto';
import { defineSecret } from 'firebase-functions/params';

const replicateAPIKey = defineSecret('REPLICATE_API_TOKEN');
const webHookUrl = defineSecret('REPLICATE_WEB_HOOK');

initializeApp();

exports.replicatehook = onRequest(
  { timeoutSeconds: 20, cors: true },
  async (req, res) => {
    console.log('webhook', req.body);
    if (req.method !== 'POST') {
      res.status(403).send('Forbidden!');
      return;
    }

    const prediction = req.body;
    if (
      prediction?.id === null ||
      typeof prediction?.id === 'undefined' ||
      prediction?.id === ''
    ) {
      res.status(400).send('Bad Request!');
      return;
    }

    try {
      await getFirestore()
        .collection('predictions')
        .doc(prediction.id)
        .update(prediction);
    } catch (err) {
      res.status(500).send(err);
    }

    const status = prediction.status;
    if (status in ['succeeded', 'failed'] === false) {
      if (status === 'succeeded') {
        try {
          await getFirestore()
            .collection('results')
            .doc(prediction.id)
            .update({ output: prediction.output });
        } catch (err) {
          res.status(200).send('Ok');
        }
      }
      // if (status === 'failed') cleanup
    }

    res.status(200).send('Ok');
  }
);

exports.createprediction = onCall(
  {
    timeoutSeconds: 20,
    secrets: [replicateAPIKey, webHookUrl],
    cors: ['localhost'],
  },
  async (request: any) => {
    const imageData = request.data.image;
    const prompt = request.data.prompt;

    const apiKey = replicateAPIKey.value();
    const webhook = webHookUrl.value();

    let prediction;

    try {
      const imageUrl = await uploadImage(imageData);
      console.log('imageUrl', imageUrl);
      prediction = await predict(prompt, imageUrl, apiKey, webhook);
      console.log('prediction', prediction.id);

      await getFirestore()
        .collection('predictions')
        .doc(prediction.id)
        .set(prediction);
      await getFirestore()
        .collection('results')
        .doc(prediction.id)
        .set({ input: imageUrl, output: null });
    } catch (error) {
      console.log(error);
      return { error };
    }

    return { data: prediction.id };
  }
);

/**
 * Create a replicate prediction
 * @param {string} prompt Text prompt
 * @param {string} imageUrl Input image url
 * @param {string} apiKey Replicate apikey
 * @param {string} webhook Webhook for prediction updates
 * @return {Promise<any>} Prediction JSON data
 */
async function predict(
  prompt: string,
  imageUrl: string,
  apiKey: string,
  webhook: string
): Promise<any> {
  const response = await fetch('https://api.replicate.com/v1/predictions', {
    method: 'POST',
    headers: {
      Authorization: `Token ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      version:
        '435061a1b5a4c1e26740464bf786efdfa9cb3a3ac488595a2de23e143fdb0117',
      input: { prompt, imageUrl },
      webhook,
    }),
  });

  if (response.status !== 201) {
    const error = await response.json();
    throw Error(`${error.detail}`);
  }

  return response.json();
}

/**
 * Upload 64bitEncoded Image to Storage
 * @param {string} imageBytes64Str Image data
 * @return {Promise<string>} Image URL
 */
async function uploadImage(imageBytes64Str: string): Promise<string> {
  const bucket = getStorage().bucket();
  const imageBuffer = Buffer.from(imageBytes64Str, 'base64');
  const imageByteArray = new Uint8Array(imageBuffer);
  const fileName = randomUUID();
  const file = bucket.file(`images/${fileName}.png`);
  const options = { resumable: false, metadata: { contentType: 'image/png' } };

  // options may not be necessary
  try {
    await file.save(Buffer.from(imageByteArray), options);
    const urls = await file.getSignedUrl({
      action: 'read',
      expires: '03-09-2500',
    });
    const url = urls[0];
    console.log(`Image url = ${url}`);
    return url;
  } catch (err) {
    throw Error(`Unable to upload image ${err}`);
  }
}
