import { ThirdwebProvider } from "@thirdweb-dev/react";
import "../styles/globals.css";
import { useState } from "react";
import ChainContext from "../context/chain";
//import 'bootstrap/dist/css/bootstrap.css';

// This is the chain your dApp will work on.
// Change this to the chain your app is built for.
// You can also import additional chains from `@thirdweb-dev/chains` and pass them directly.
const activeChain = "ethereum";

function MyApp({ Component, pageProps }) {
  const [selectedChain, setSelectedChain] = useState(activeChain);
  return (
    <ChainContext.Provider value={{ selectedChain, setSelectedChain }}>
      <ThirdwebProvider activeChain={selectedChain}>
        <Component {...pageProps} />
      </ThirdwebProvider>
    </ChainContext.Provider>
  );
}

export default MyApp;
