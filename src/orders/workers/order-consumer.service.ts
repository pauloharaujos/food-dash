import { Injectable, OnModuleInit, OnModuleDestroy, Inject, Logger } from '@nestjs/common';
import { Consumer } from 'sqs-consumer';
import { SQSClient, Message } from '@aws-sdk/client-sqs';
import { OrderService } from '../order.service';
import { CreateOrderDto } from '../dto/create-order.dto';
import { UpdateOrderDto } from '../dto/update-order.dto';
import { PUB_SUB } from '../../redis/redis.module';
import { RedisPubSub } from 'graphql-redis-subscriptions';

@Injectable()
export class OrderConsumerService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(OrderConsumerService.name);
  private consumer: Consumer;

  constructor(
    private orderService: OrderService,
    @Inject(PUB_SUB) private pubSub: RedisPubSub,
  ) {}

  async onModuleInit() {
    this.initializeConsumer();
  }

  private initializeConsumer() {
    const queueUrl = process.env.AWS_SQS_QUEUE_URL;
    if (!queueUrl) {
      throw new Error('Missing required environment variable: AWS_SQS_QUEUE_URL');
    }
    const endpoint = process.env.AWS_ENDPOINT_URL;

    this.consumer = Consumer.create({
      queueUrl,
      handleMessage: async (message) => {
        await this.processOrderUpdate(message);
        return message;
      },
      sqs: new SQSClient({
        ...(endpoint ? { endpoint } : {}),
        region: process.env.AWS_REGION ?? 'us-east-1',
        ...(endpoint
          ? { credentials: { accessKeyId: 'test', secretAccessKey: 'test' } }
          : {}),
      }),
    });

    this.consumer.on('error', (err) => {
      this.logger.error(`Error in Consumer: ${err.message}`);
    });

    this.consumer.on('processing_error', (err) => {
      this.logger.error(`Error Processing the Message: ${err.message}`);
    });

    this.logger.log('SQS Worker initialized and listening for messages...');
    this.consumer.start();
  }

  private async processOrderUpdate(message: Message) {
    try {
      if (!message.Body) {
        throw new Error('Message has no Body');
      }

      const body = JSON.parse(message.Body);
      this.logger.log(`Processing Order: Type ${body.type} ${body.order.id} -> ${body.order.status}`);
      
      let order;
      if (body.type === "create") {
        const orderData: CreateOrderDto = Object.assign(new CreateOrderDto(), body);
        order = await this.orderService.saveOrder(orderData);
      } else {
        const orderData: UpdateOrderDto = Object.assign(new UpdateOrderDto(), body);
        order = await this.orderService.updateOrderStatus(orderData);
      }

      if (order) {
        const formattedOrder = this.formatOrderForGraphQL(order);
        await this.pubSub.publish('orderUpdates', { orderUpdates: formattedOrder });
        this.logger.log(`Sending Order Update to Redis: ${formattedOrder.id}`);
      }
      
    } catch (error) {
      this.logger.error(`Failed to process message: ${error.message}`);
      throw error; //This is important, so the message can stay in the queue to be reprocessed
    }
  }

  private formatOrderForGraphQL(order: {
    id: number;
    subtotal: unknown;
    address: unknown;
    orderItems: Array<{ id: number }>;
  }) {
    return {
      ...order,
      id: String(order.id),
      subTotal: order.subtotal,
      address: order.address,
      orderItems: order.orderItems.map((item) => ({
        ...item,
        id: String(item.id),
      })),
    };
  }

  onModuleDestroy() {
    this.consumer.stop();
  }
}