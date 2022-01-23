import React from 'react';
import { ChainId, DAppProvider } from "@usedapp/core";
import { Header } from "./components/Header"
function App() {
  return (
    <DAppProvider config={{
      supportedChains: [ChainId.Kovan, ChainId.Rinkeby]
    }}>
      <div>
        Hello. I bet you're here to bet!
      </div>
      <Header />
    </DAppProvider>
  );
}

export default App;
