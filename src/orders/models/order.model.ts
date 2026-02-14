import { Field, Int, Float, ObjectType } from '@nestjs/graphql';
import { Address } from './address.model';
import { OrderItem } from './order-item.model';

@ObjectType()
export class Order {

    @Field(type => String)
    id: string;

    @Field(type => Address)
    address: Address;

    @Field(type => [OrderItem])
    orderItems: OrderItem[];

    @Field(type => Float)
    subTotal: number;

    @Field(type => Float)
    total: number;

    @Field()
    status: string;
}