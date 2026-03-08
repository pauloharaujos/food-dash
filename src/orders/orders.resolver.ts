import { Resolver, Args, Query, Subscription, Parent, ResolveField } from "@nestjs/graphql";
import { Inject } from '@nestjs/common';
import { Order } from './models/order.model';
import { OrderService } from './order.service';
import { AddressService } from './address.service';
import { PUB_SUB } from '../redis/redis.module';
import { RedisPubSub } from 'graphql-redis-subscriptions';

@Resolver(() => Order)
export class OrderResolver {

    constructor(
        private orderService: OrderService,
        private addressService: AddressService,
        @Inject(PUB_SUB) private pubSub: RedisPubSub,
    ) {}

    @Query(() => Order, { nullable: true })
    async order(@Args('id', { type: () => String }) id: string): Promise<Order | null>{
        const result = await this.orderService.getOrderById(id);
        if (!result) return null;
        return {
            ...result,
            id: String(result.id),
            address: result.address,
            orderItems: result.orderItems.map((item: { id: number }) => ({
                ...item,
                id: String(item.id)
            })),
            subTotal: result.subtotal
        } as unknown as Order;
    }

    @Query(() => [Order], { nullable: true })
    async getOrderHistory(): Promise<Order[] | null>{
        const result = await this.orderService.getOrderHistory();

        if (!result) return null;

        return result.map((order) => ({
            ...order,
            id: String(order.id),
            address: order.address,
            orderItems: order.orderItems.map((item: { id: number }) => ({
                ...item,
                id: String(item.id)
            })),
            subTotal: order.subtotal
        } as unknown as Order));
    }

    @ResolveField()
    async address(@Parent() order: { id: string }){
        const { id } = order;
        return await this.addressService.getByOrderById(id);
    }

    @Subscription(() => Order, {
        name: 'orderUpdates',
    })
    orderUpdates() {
        return this.pubSub.asyncIterator('orderUpdates');
    }
}