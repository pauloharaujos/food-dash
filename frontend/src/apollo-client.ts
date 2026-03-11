import {
  ApolloClient,
  HttpLink,
  InMemoryCache,
  split,
} from '@apollo/client'
import { GraphQLWsLink } from '@apollo/client/link/subscriptions'
import { getMainDefinition } from '@apollo/client/utilities'
import { createClient } from 'graphql-ws'

const httpUrl =
  import.meta.env.VITE_GRAPHQL_HTTP_URL ?? 'http://localhost:4000/graphql'
const wsUrl =
  import.meta.env.VITE_GRAPHQL_WS_URL ?? 'ws://localhost:4000/graphql'

const httpLink = new HttpLink({
  uri: httpUrl,
})

const wsLink = new GraphQLWsLink(
  createClient({
    url: wsUrl,
  }),
)

const splitLink = split(
  ({ query }) => {
    const definition = getMainDefinition(query)
    return (
      definition.kind === 'OperationDefinition' &&
      definition.operation === 'subscription'
    )
  },
  wsLink,
  httpLink,
)

export const apolloClient = new ApolloClient({
  link: splitLink,
  cache: new InMemoryCache(),
})
