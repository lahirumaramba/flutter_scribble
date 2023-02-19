import { onRequest } from 'firebase-functions/v2/https';
import * as functions from 'firebase-functions';
import { getStorage } from 'firebase-admin/storage';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { randomUUID } from 'crypto';

initializeApp();

exports.replicatehook = onRequest(
  { timeoutSeconds: 20, cors: true },
  async (req, res) => {
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
      return;
    }

    const status = prediction.status;
    if (status in ['succeeded', 'failed'] === false) {
      if (status === 'succeeded') {
        const outputImageUrl = prediction?.output[1];
        console.log('outputImageUrl', outputImageUrl);
        try {
          await processOutputImage(outputImageUrl, prediction.id);
        } catch (err) {
          console.log(err);
          res.status(200).send('Ok');
          return;
        }
      }
      // if (status === 'failed') cleanup
    }

    res.status(200).send('Ok');
  }
);

async function processOutputImage(url: string, id: string): Promise<void> {
  const response = await fetch(url);
  const imageData = Buffer.from(await response.arrayBuffer());
  const imageUrl = await uploadImageBuffer(imageData);

  await getFirestore()
    .collection('results')
    .doc(id)
    .update({ output: imageUrl });
}

exports.createPrediction = functions
  .runWith({
    secrets: ['REPLICATE_API_TOKEN', 'REPLICATE_WEB_HOOK'],
    timeoutSeconds: 20,
  })
  .https.onCall(async (data: any, context: any) => {
    const imageData = data.image;
    const prompt = data.prompt;

    const apiKey = process.env.REPLICATE_API_TOKEN ?? '';
    const webhook = process.env.REPLICATE_WEB_HOOK ?? '';

    let prediction;

    try {
      const imageUrl = await uploadImage(imageData);
      prediction = await predict(prompt, imageUrl, apiKey, webhook);

      await getFirestore()
        .collection('predictions')
        .doc(prediction.id)
        .set(prediction);
      await getFirestore()
        .collection('results')
        .doc(prediction.id)
        .set({ input: imageUrl, output: null, prompt });
    } catch (error) {
      return { error };
    }

    return { data: prediction.id };
  });

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
      input: { prompt, image: imageUrl },
      webhook,
      webhook_events_filter: ['start', 'completed'],
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
  const imageBuffer = Buffer.from(imageBytes64Str, 'base64');
  const imageByteArray = new Uint8Array(imageBuffer);
  return await uploadImageBuffer(Buffer.from(imageByteArray));
}

async function uploadImageBuffer(buffer: Buffer): Promise<string> {
  const bucket = getStorage().bucket();
  const fileName = randomUUID();
  const file = bucket.file(`images/${fileName}.png`);
  const options = { resumable: false, metadata: { contentType: 'image/png' } };

  // options may not be necessary
  try {
    await file.save(buffer, options);
    const urls = await file.getSignedUrl({
      action: 'read',
      expires: '03-09-2500',
    });
    const url = urls[0];
    return url;
  } catch (err) {
    throw Error(`Unable to upload image ${err}`);
  }
}
