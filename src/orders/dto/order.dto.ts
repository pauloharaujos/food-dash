import { ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { AddressDto } from './address.dto';
import { OrderItemDto } from './order-item.dto';

export class OrderDto {
  subtotal: number;
  total: number;
  status: string;

  @ValidateNested()
  @Type(() => AddressDto)
  address: AddressDto;

  @ValidateNested({ each: true }) // 'each' is for arrays
  @Type(() => OrderItemDto)
  items: OrderItemDto[];
}