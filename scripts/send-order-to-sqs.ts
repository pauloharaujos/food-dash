#!/usr/bin/env npx ts-node
/**
 * Sends order create/update messages to an SQS queue.
 *
 * Works against both LocalStack (local dev) and real AWS (production).
 *
 * Usage:
 *   npm run script:send-order                # send create + update
 *   npm run script:send-order create         # send create only
 *   npm run script:send-order update         # send update for order id 1
 *   npm run script:send-order update 5       # send update for order id 5
 *
 * Environment variables (can be set in .env or inline):
 *   AWS_SQS_QUEUE_URL   — required; queue URL (set in .env for local dev, or pass inline for real AWS)
 *   AWS_REGION          — defaults to us-east-1
 */

import { SQSClient, SendMessageCommand } from '@aws-sdk/client-sqs';
import { config } from 'dotenv';

config(); // load .env

const QUEUE_URL = process.env.AWS_SQS_QUEUE_URL;

const ENDPOINT = process.env.AWS_ENDPOINT_URL;

const createOrderMessage = {
  type: 'create',
  order: {
    subtotal: 2999,
    total: 3299,
    status: 'PREPARING',
    address: {
      firstName: 'John',
      lastName: 'Doe',
      street: '123 Main St',
      city: 'Austin',
      state: 'TX',
      zipcode: '78701',
      country: 'USA',
      phone: '+15551234567',
    },
    items: [
      { name: 'Margherita Pizza', sku: 'PIZZA-001', quantity: 1, price: 1299 },
      { name: 'Caesar Salad', sku: 'SALAD-002', quantity: 1, price: 899 },
    ],
  },
};

const updateOrderMessage = (orderId: string) => ({
  type: 'update',
  order: { id: orderId, status: 'OUT_FOR_DELIVERY' },
});

async function sendMessage(body: object) {
  if (!QUEUE_URL) throw new Error('AWS_SQS_QUEUE_URL is not set in environment or .env');

  const client = new SQSClient({
    ...(ENDPOINT ? { endpoint: ENDPOINT } : {}),
    region: process.env.AWS_REGION ?? 'us-east-1',
    ...(ENDPOINT ? { credentials: { accessKeyId: 'test', secretAccessKey: 'test' } } : {}),
  });

  const result = await client.send(
    new SendMessageCommand({
      QueueUrl: QUEUE_URL,
      MessageBody: JSON.stringify(body),
    }),
  );

  console.log(`Sent: ${JSON.stringify(body).slice(0, 80)}... → MessageId: ${result.MessageId}`);
}

async function main() {
  const arg = process.argv[2]?.toLowerCase();

  if (arg === 'create') {
    await sendMessage(createOrderMessage);
  } else if (arg === 'update') {
    const orderId = process.argv[3] ?? '1';
    await sendMessage(updateOrderMessage(orderId));
  } else {
    await sendMessage(createOrderMessage);
    await sendMessage(updateOrderMessage('1'));
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
