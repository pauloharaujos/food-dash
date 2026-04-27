import { Field, Int, Float, ObjectType } from '@nestjs/graphql';

@ObjectType()
export class OrderItem {

    @Field(type => String)
    id: string;

    @Field(type => Int)
    orderId: number;

    @Field(type => Int)
    quantity: number;

    @Field(type => Float)
    price: number;

    @Field()
    name: string;

    @Field()
    sku: string;
}