import { Module } from '@nestjs/common';
import { OrderService } from './order.service';
import { AddressService } from './address.service';
import { OrderResolver } from './orders.resolver';
import { OrderConsumerService } from './workers/order-consumer.service';

@Module({
    providers: [
        OrderService,
        AddressService,
        OrderResolver,
        OrderConsumerService
    ],
    exports: [OrderService]
})

export class OrdersModule {}