import { useEffect, useState } from 'react'
import { useQuery, useSubscription } from '@apollo/client/react'
import { GET_ORDER_HISTORY, ORDER_UPDATES } from '../graphql/orders'

interface Address {
  firstName: string
  lastName: string
  street: string
  city: string
  state: string
  zipcode: string
  country: string
  phone: string
}

interface Order {
  id: string
  status: string
  total: number
  address: Address
}

interface GetOrderHistoryData {
  getOrderHistory: Order[] | null
}

export function OrderDashboard() {
  const { data, loading, error } =
    useQuery<GetOrderHistoryData>(GET_ORDER_HISTORY)
  const { data: subscriptionData } = useSubscription<{
    orderUpdates: Order | null
  }>(ORDER_UPDATES)

  const [orders, setOrders] = useState<Order[]>([])

  useEffect(() => {
    if (data?.getOrderHistory) {
      setOrders(data.getOrderHistory)
    }
  }, [data])

  useEffect(() => {
    if (!subscriptionData?.orderUpdates) return

    const updatedOrder = subscriptionData.orderUpdates

    setOrders((prev) => {
      const index = prev.findIndex((order) => order.id === updatedOrder.id)

      if (index === -1) {
        return [updatedOrder, ...prev]
      }

      const next = [...prev]
      next[index] = { ...next[index], ...updatedOrder }
      return next
    })
  }, [subscriptionData])

  if (loading) {
    return (
      <div className="flex justify-center items-center min-h-[200px]">
        <p className="text-gray-500">Loading orders...</p>
      </div>
    )
  }

  if (error) {
    return (
      <div className="rounded-lg bg-red-50 p-4 text-red-700">
        <p className="font-medium">Error loading orders</p>
        <p className="text-sm mt-1">{error.message}</p>
      </div>
    )
  }

  if (orders.length === 0) {
    return (
      <div className="rounded-lg border border-gray-200 bg-white p-8 text-center text-gray-500">
        No orders yet
      </div>
    )
  }

  return (
    <ul className="divide-y divide-gray-200 rounded-lg border border-gray-200 bg-white shadow-sm">
      {orders.map((order) => (
        <li key={order.id} className="p-4">
          <div className="flex items-start justify-between gap-4">
            <div>
              <p className="font-medium text-gray-900">
                Order #{order.id.slice(0, 8)}
              </p>
              <p className="text-sm text-gray-500">
                {order.address.street}, {order.address.city}, {order.address.zipcode}
              </p>
            </div>
            <div className="text-right shrink-0">
              <span
                className={`inline-flex rounded-full px-2.5 py-1 text-xs font-medium ${
                  order.status === 'OUT_FOR_DELIVERED'
                    ? 'bg-green-100 text-green-800'
                    : order.status === 'PENDING'
                      ? 'bg-amber-100 text-amber-800'
                      : 'bg-gray-100 text-gray-800'
                }`}
              >
                {order.status}
              </span>
              <p className="mt-1 font-semibold text-gray-900">
                ${order.total.toFixed(2)}
              </p>
            </div>
          </div>
        </li>
      ))}
    </ul>
  )
}
