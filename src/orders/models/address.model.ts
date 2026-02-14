import { Field, Int, Float, ObjectType } from '@nestjs/graphql';

@ObjectType()
export class Address {

    @Field(type => Int)
    id: number;

    @Field()
    street: string;

    @Field()
    zipcode: string;

    @Field()
    state: string;

    @Field()
    city: string;

    @Field()
    country: string;

    @Field()
    phone: string;

    @Field()
    firstName: string;

    @Field()
    lastName: string;
}