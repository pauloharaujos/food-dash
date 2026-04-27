import { OrderDashboard } from './components/OrderDashboard'

function App() {
  return (
    <div className="min-h-screen bg-gray-50">
      <header className="border-b border-gray-200 bg-white">
        <div className="mx-auto max-w-4xl px-4 py-4 sm:px-6 lg:px-8">
          <h1 className="text-2xl font-bold text-gray-900">Order Dashboard</h1>
        </div>
      </header>
      <main className="mx-auto max-w-4xl px-4 py-6 sm:px-6 lg:px-8">
        <OrderDashboard />
      </main>
    </div>
  )
}

export default App
