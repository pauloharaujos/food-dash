import { Resolver, Args, Query, Parent, ResolveField } from "@nestjs/graphql";
import { Order } from './models/order.model';
import { OrderService } from './order.service';
import { AddressService } from './address.service';

@Resolver(() => Order)
export class OrderResolver {

    constructor(
        private orderService: OrderService,
        private addressService: AddressService
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

    @ResolveField()
    async address(@Parent() order: { id: string }){
        const { id } = order;
        return await this.addressService.getByOrderById(id);
    }
}