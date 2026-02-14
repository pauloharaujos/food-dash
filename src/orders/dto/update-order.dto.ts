export class UpdateOrderDto {
    type: string;
    order: {
        id: string,
        status: string
    }
}