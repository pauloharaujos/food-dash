#!/usr/bin/env npx ts-node
/**
 * Sends order create/update messages to the LocalStack SQS queue.
 *
 * Prerequisites: LocalStack running (docker compose up -d) and queue created.
 *
 * Usage:
 *   npm run script:send-order                # send create + update
 *   npm run script:send-order create         # send create only
 *   npm run script:send-order update         # send update for order id 1
 *   npm run script:send-order update 5       # send update for order id 5
 *
 * AWS CLI alternative (requires AWS CLI):
 *   aws --endpoint-url=http://localhost:4566 sqs send-message \
 *     --queue-url http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/food-dash-order-updates \
 *     --message-body '{"type":"create","order":{"subtotal":2999,"total":3299,"status":"PREPARING","address":{...},"items":[...]}}'
 */

import { SQSClient, SendMessageCommand } from '@aws-sdk/client-sqs';

const QUEUE_URL =
  'http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/food-dash-order-updates';
const ENDPOINT = 'http://localhost:4566';

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
  const client = new SQSClient({
    endpoint: ENDPOINT,
    region: 'us-east-1',
    credentials: { accessKeyId: 'test', secretAccessKey: 'test' },
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
