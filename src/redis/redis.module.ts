import { Global, Module } from '@nestjs/common';
import { RedisPubSub } from 'graphql-redis-subscriptions';
import { RedisService } from './redis.service';

const redisOptions = {
  host: process.env.REDIS_HOST ?? 'localhost',
  port: parseInt(process.env.REDIS_PORT ?? '6379', 10),
};

export const PUB_SUB = 'PUB_SUB';

@Global()
@Module({
  providers: [
    RedisService,
    {
      provide: PUB_SUB,
      useFactory: () =>
        new RedisPubSub({
          connection: redisOptions,
        }),
    },
  ],
  exports: [RedisService, PUB_SUB],
})
export class RedisModule {}
