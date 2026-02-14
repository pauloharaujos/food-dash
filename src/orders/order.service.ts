import { Injectable } from '@nestjs/common';
import { Prisma } from '@/prisma/generated';
import { CreateOrderDto } from './dto/create-order.dto';
import prisma from '@/prisma/prismaClient';

export type OrderWithDetails = Prisma.OrderGetPayload<{
  include: {
    address: true;
    orderItems: true;
  };
}>;

@Injectable()
export class OrderService {

    async getOrderById(orderId: string): Promise<OrderWithDetails | null> {
        const order = await prisma.order.findFirst({
            where: {
                id: parseInt(orderId, 10)
            },
            include: {
                address: true,
                orderItems: true
            }
        });
        
        return order;
    }

    async saveOrder(orderPayload: CreateOrderDto): Promise<OrderWithDetails | null> {
        const { order } = orderPayload;

        const newOrder = await prisma.order.create({
            data: {
                subtotal: order.subtotal,
                total: order.total,
                status: order.status,
                address: {
                    create: { ...order.address }
                },
                orderItems: {
                    create: order.items.map(item => ({
                      name: item.name,
                      sku: item.sku,
                      price: item.price,
                      quantity: item.quantity
                    }))
                }
            },
            include: {
                address: true,
                orderItems: true
            }
        });

        return newOrder;
    }
}