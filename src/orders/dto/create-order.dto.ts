import { ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { OrderDto } from './order.dto';

export class CreateOrderDto {
    type: string;
  
    @ValidateNested()
    @Type(() => OrderDto)
    order: OrderDto;
}