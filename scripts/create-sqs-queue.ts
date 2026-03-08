#!/usr/bin/env npx ts-node
/**
 * Creates the food-dash-order-updates SQS queue in LocalStack.
 *
 * Prerequisites: LocalStack running (docker compose up -d)
 *
 * Usage:
 *   npm run script:create-queue
 */

import { SQSClient, CreateQueueCommand } from '@aws-sdk/client-sqs';

const QUEUE_NAME = 'food-dash-order-updates';
const ENDPOINT = 'http://localhost:4566';

async function main() {
  const client = new SQSClient({
    endpoint: ENDPOINT,
    region: 'us-east-1',
    credentials: { accessKeyId: 'test', secretAccessKey: 'test' },
  });

  await client.send(
    new CreateQueueCommand({ QueueName: QUEUE_NAME })
  );

  console.log(`Queue "${QUEUE_NAME}" created successfully.`);
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
