import { ConnectWallet } from "@thirdweb-dev/react";
import styles from "../styles/Home.module.css";
import ChainContext from "../context/chain";
import { useContext } from "react";

export default function Home() {

  const { selectedChain, setSelectedChain } = useContext(ChainContext);
  return (
    <div className={styles.container}>
      <main className={styles.main}>
        <h1 className={styles.title}>
          Welcome to <span>Green Pluto AI algo trading game</span>!
        </h1>

        <p className={styles.description}>
          Get started by configuring your desired network in{" "}
          <code className={styles.code}>pages/_app.js</code>, then modify the{" "}
          <code className={styles.code}>pages/index.js</code> file!
        </p>
        {/*
        <select
          value={String(selectedChain)}
          onChange={(e) => setSelectedChain(e.target.value)}
        >
          <option value="ethereum">Mainnet</option>
          <option value="goerli">Goerli</option>
        </select>*/}

        <div className={styles.connect}>
          <ConnectWallet />
        </div>

        <div className={styles.grid}>
          <a href="https://portal.thirdweb.com/" className={styles.card}>
            <h2>Portal &rarr;</h2>
            <p>
              Guides, references and resources that will help you build with
              thirdweb.
            </p>
          </a>

          <a href="https://thirdweb.com/dashboard" className={styles.card}>
            <h2>Dashboard &rarr;</h2>
            <p>
              Deploy, configure and manage your smart contracts from the
              dashboard.
            </p>
          </a>

          <a
            href="https://portal.thirdweb.com/templates"
            className={styles.card}
          >
            <h2>Templates &rarr;</h2>
            <p>
              Discover and clone template projects showcasing thirdweb features.
            </p>
          </a>
        </div>
      </main>
    </div>
  );
}
