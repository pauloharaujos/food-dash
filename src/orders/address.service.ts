import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { Address } from './models/address.model';

@Injectable()
export class AddressService {

    async getByOrderById(orderId: string): Promise<Address | null> {
        //throw new HttpException('Forbidden', HttpStatus.FORBIDDEN);
        //return `Address for Order ID ${orderId} Found in the system!`;
        let address = new Address();
        address.city = 'Boca Raton';
        address.country = "US";
        address.id = 103231;
        address.street = "1515 S Federal Hwy";
        address.zipcode = "33432";
        
        return address;
    }
}