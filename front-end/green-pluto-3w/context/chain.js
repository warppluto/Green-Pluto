import { createContext } from "react";

const ChainContext = createContext({
  selectedChain: "goerli",
  setSelectedChain: (chain) => {},
});

export default ChainContext;