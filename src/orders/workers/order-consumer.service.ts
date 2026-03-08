import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common';
import { Consumer } from 'sqs-consumer';
import { SQSClient, Message } from '@aws-sdk/client-sqs';
import { OrderService } from '../order.service';
import { CreateOrderDto } from '../dto/create-order.dto';
import { UpdateOrderDto } from '../dto/update-order.dto';
import { RedisService } from '../../redis/redis.service';

@Injectable()
export class OrderConsumerService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(OrderConsumerService.name);
  private consumer: Consumer;

  constructor(
    private orderService: OrderService,
    private redisService: RedisService,
  ) {}

  async onModuleInit() {
    this.initializeConsumer();
  }

  private initializeConsumer() {
    this.consumer = Consumer.create({
      queueUrl: 'http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/food-dash-order-updates',
      
      handleMessage: async (message) => {
        await this.processOrderUpdate(message);
        return message;
      },
      
      sqs: new SQSClient({
        endpoint: 'http://localhost:4566',
        region: 'us-east-1',
        credentials: {
          accessKeyId: 'test',
          secretAccessKey: 'test',
        },
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
        await this.redisService.publishOrderUpdate({ type: body.type, order });
      }
      
    } catch (error) {
      this.logger.error(`Failed to process message: ${error.message}`);
      throw error; //This is important, so the message can stay in the queue to be reprocessed
    }
  }

  onModuleDestroy() {
    this.consumer.stop();
  }
}