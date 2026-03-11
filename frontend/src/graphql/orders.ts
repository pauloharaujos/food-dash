import { gql } from '@apollo/client'

export const GET_ORDER_HISTORY = gql`
  query GetOrderHistory {
    getOrderHistory {
      id
      total
      status
      address {
      city
      country
      street
      zipcode 
      }
    }
  }
`
