import { Injectable, OnModuleDestroy, Logger } from '@nestjs/common';
import Redis from 'ioredis';

export const ORDER_UPDATES_CHANNEL = 'order-updates';

@Injectable()
export class RedisService implements OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  private client: Redis;

  constructor() {
    const host = process.env.REDIS_HOST ?? 'localhost';
    const port = parseInt(process.env.REDIS_PORT ?? '6379', 10);

    this.client = new Redis({ host, port });

    this.client.on('error', (err) => {
      this.logger.error(`Redis connection error: ${err.message}`);
    });

    this.client.on('connect', () => {
      this.logger.log('Redis connected');
    });
  }

  async publish(channel: string, message: string): Promise<number> {
    return this.client.publish(channel, message);
  }

  async publishOrderUpdate(payload: unknown): Promise<number> {
    const message = JSON.stringify(payload);
    return this.publish(ORDER_UPDATES_CHANNEL, message);
  }

  onModuleDestroy() {
    this.client.disconnect();
  }
}
