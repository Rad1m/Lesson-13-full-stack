import React from 'react'
import { ChainId, DAppProvider } from "@usedapp/core"
import { Header } from "./components/Header"

function App() {
  return (
    <DAppProvider config={{
      supportedChains: [ChainId.Kovan, ChainId.Rinkeby],
    }}>
      <Header />
      <div>Hi!</div>
    </DAppProvider >
  )
}

export default App